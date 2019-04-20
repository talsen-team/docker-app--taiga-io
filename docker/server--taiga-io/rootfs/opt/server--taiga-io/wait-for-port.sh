#!/bin/bash

VAR_PORT="${1}"
if [ "${VAR_PORT}" = "" ]; then
  echo "No port to listen to specified..."
  exit 1
fi

VAR_NEED_TO_WAIT=1
while [ ${VAR_NEED_TO_WAIT} -ne 0 ];
do
  echo "Waiting for port ${VAR_PORT}..."
  sleep 1
  nc -z 127.0.0.1 ${VAR_PORT}
  VAR_NEED_TO_WAIT=${?}
done