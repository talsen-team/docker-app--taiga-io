#!/bin/bash

set -euo pipefail

source bash-util/functions.sh

prepare_local_environment ${@}

echo -E "Generating taiga-io configuration ..."

export HOST_SERVICE_SERVER_TAIGA_IO_COMMAND=generate
export HOST_SERVICE_SERVER_TAIGA_IO_RESTART=no

docker-compose --compatibility --file ${HOST_PATH_TO_DOCKER_COMPOSE_FILE} \
               up

echo -e "Generating taiga-io configuration ... $( __done )"
