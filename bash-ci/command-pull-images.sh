#!/bin/bash

set -euo pipefail

echo -e "Performing pull ..."

/bin/bash bash-commands/docker-compose--image--pull.sh "." "default.docker-compose"

echo -e "Performing pull ... \033[0;32mdone\033[0m"
