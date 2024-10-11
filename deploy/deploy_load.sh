#!/usr/bin/env bash

IPM_ADMIN=ip8value_test@ip8value.com
IPM_ADMIN_PASS=123

set +e

curr_dir="$(dirname "$(realpath "$0")")"
source "${curr_dir}/env.sh"

# Step 1 (only once): create private network and start mysql, mongodb, elasticsearch server.
docker network create "${IPM_NET}"

# start mysql docker
mkdir -p "${MYSQL_DIR}"

# By SC2086, double quote to avoid word split.
# wait until mysql start (otherwise it may fail the following queries)
docker run -d --restart always --name "${IPM_MYSQL}" \
  --network "${IPM_NET}" \
  -v "${MYSQL_DIR}":/var/lib/mysql \
  -e MYSQL_ROOT_PASSWORD=IPM2022 \
  --health-cmd='mysql -u root -pIPM2022 --protocol=tcp -e "SELECT version();"' \
  --health-interval=10s \
  --health-timeout=3s \
  --health-retries=3 \
  mysql:8.0.33

echo -n "Waiting for RDBMS to be ready "
while [ "$(docker inspect --format "{{json .State.Health.Status }}" "${IPM_MYSQL}")" != "\"healthy\"" ]; do
  printf "."
  sleep 1
done
echo "OK"

echo "Setting up RDBMS ..."
# set mysql
docker exec -it "${IPM_MYSQL}" mysql -u root -pIPM2022 --protocol=tcp -e \
  "CREATE DATABASE IPM_Internal;"
docker exec -it "${IPM_MYSQL}" mysql -u root -pIPM2022 --protocol=tcp -e \
  "SET GLOBAL sql_mode=(SELECT REPLACE(@@sql_mode,'NO_ZERO_DATE',''));"
docker exec -it "${IPM_MYSQL}" mysql -u root -pIPM2022 --protocol=tcp -e \
  "SET GLOBAL sql_mode=(SELECT REPLACE(@@sql_mode,'NO_ZERO_IN_DATE',''));"
echo "OK"

# start mongodb server
mkdir -p "${MONGO_DIR}"
docker run -d --restart=always --name "${IPM_MONGO}" \
  --network "${IPM_NET}" \
  -v "${MONGO_DIR}":/data \
  -e LANG=C.UTF-8 \
  mongo:6.0.2

# start elasticsearch server
mkdir -p "${ES_DIR}"

## By SC2181, avoid using $?.
### elasticsearch image uses UID 1000, which causes permission issue
### so we test the current UID, and use chown if it is not 1000
# if [ "$EUID" -ne 1000 ]; then
#   echo "The current UID is not 1000. We need root permission to alter directory owner"
#   echo "Calling sudo ..."
#   if sudo chown -R 1000:1000 "${ES_DIR}"; then
#     echo "Directory ownership successfully changed."
#   else
#     echo "Failed to set directory ownership. Exiting."
#     exit 1
#   fi
#   echo "OK"
# fi

docker run -d --restart always --name "${IPM_ES}" \
  --network "${IPM_NET}" \
  -v "${ES_DIR}":/var/lib/elasticsearch/data  \
  -e discovery.type=single-node \
  elasticsearch:7.5.2

docker exec "${IPM_ES}" elasticsearch-plugin install analysis-icu
docker restart "${IPM_ES}"

docker run -d --restart always --name "${IPM_BACKEND}" \
    --network "${IPM_NET}" \
    -p "${IPM_PORT}":8088 ipm-dev-img \
    --mysql_host "${IPM_MYSQL}" \
    --mongodb_host "${IPM_MONGO}" \
    --es_host "${IPM_ES}"

docker exec -i ipm-load-mysql mysql -u root -pIPM2022 IPM_Internal < load_full.sql

# Login to get admin token.
res=$(eval "curl -s -L -X POST \"http://${IP}:${IPM_PORT}/auth/login\" \
                             --form "\'account_name=\"${IPM_ADMIN}\"\'" \
                             --form "\'password=\"${IPM_ADMIN_PASS}\"\'"")
echo "Response from server for admin login: $res"
token=$(echo "$res" | grep -oP '"token":"\K[^"]+')

(eval "curl -s -L -X POST \"http://${IP}:${IPM_PORT}/api/v1/dev/refresh_es\" \
                       --header 'Authorization: Bearer ${token}'")

# FIN: check if current backend service is running appropriately.
docker logs -f "${IPM_BACKEND}"
