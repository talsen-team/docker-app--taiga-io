#!/bin/bash

set -euo pipefail

source bash-util/functions.sh

prepare_local_environment ${@}

echo -E "Creating and starting containers and networks ..."

export HOST_SERVICE_SERVER_TAIGA_IO_COMMAND=generate
export HOST_SERVICE_SERVER_TAIGA_IO_RESTART=no

docker-compose --file ${HOST_PATH_TO_DOCKER_COMPOSE_FILE} \
               up

echo -e "Creating and starting containers and networks ... $( __done )"
