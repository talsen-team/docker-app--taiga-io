#!/bin/bash

VAR_NAME_DB_USER="taiga"
VAR_NAME_DB_NAME="taiga"

VAR_NEED_TO_WAIT=1
while [ ${VAR_NEED_TO_WAIT} -ne 0 ];
do
  echo "Waiting for database ${VAR_NAME_DB_NAME}..."
  sleep 1
  pg_isready --host=127.0.0.1 --port=5432 --user=${VAR_NAME_DB_USER} --dbname=${VAR_NAME_DB_NAME} --timeout 1
  VAR_NEED_TO_WAIT=${?}
done