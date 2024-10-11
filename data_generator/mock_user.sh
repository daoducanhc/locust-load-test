#!/bin/bash
for i in $(seq 1 10000); do 
    ./bin/createAccount --db=IPM_Internal --port=3306 -e="${i}@gmail.com" -u=Load -l=1 -p="${i}"
done