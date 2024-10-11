1PManagement@2022


## Create a new load mysql container

mkdir -p /home/patmgt/ipm_internal_data/mysql_load

docker rm -f ipm-load-mysql

docker run -d --name ipm-load-mysql \
  --memory="3g" --memory-swap="3g" --cpus="1" \
  --network ipm-dev-net \
  -v /home/patmgt/ipm_internal_data/mysql_load:/var/lib/mysql \
  -e MYSQL_ROOT_PASSWORD=IPM2022 \
  --health-cmd='mysql -u root -pIPM2022 --protocol=tcp -e "SELECT version();"' \
  --health-interval=10s \
  --health-timeout=3s \
  --health-retries=3 \
  mysql:8.0.33


docker exec -it ipm-load-mysql mysql -u root -pIPM2022 --protocol=tcp -e \
  "CREATE DATABASE IPM_Internal;"
docker exec -it ipm-load-mysql mysql -u root -pIPM2022 --protocol=tcp -e \
  "SET GLOBAL sql_mode=(SELECT REPLACE(@@sql_mode,'NO_ZERO_DATE',''));"
docker exec -it ipm-load-mysql mysql -u root -pIPM2022 --protocol=tcp -e \
  "SET GLOBAL sql_mode=(SELECT REPLACE(@@sql_mode,'NO_ZERO_IN_DATE',''));"
echo "OK"

## dump database
!LOCAL: mysqldump -u root -pIPM2022 IPM_Internal > load_full.sql

## copy to sbip

## restore the database
docker exec -i ipm-load-mysql mysql -u root -pIPM2022 IPM_Internal < load_full.sql

## check db
docker exec -it ipm-load-mysql mysql -u root -pIPM2022 IPM_Internal

# http://137.132.92.226:4088

docker rm -f ipm-load

docker run -d --name ipm-load --network ipm-dev-net \
  --memory="1g" --memory-swap="1g" --cpus="1" \
  -p 4088:8088 ipm-dev-img \
  --mysql_host ipm-load-mysql --mongodb_host ipm-dev-mongo --es_host ipm-dev-es