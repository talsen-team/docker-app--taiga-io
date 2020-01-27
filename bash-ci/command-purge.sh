#!/bin/bash

set -euo pipefail

echo -e "Performing purge ..."

/bin/bash bash-commands/docker-compose--compose--down.sh "." "default.docker-compose"

echo -e "Performing purge ... \033[0;32mdone\033[0m"
