#!/bin/bash

set -euo pipefail

echo -e "Performing deployment ..."

if [ ! -d "volumes/server--taiga-io" ] ;
then
    /bin/bash bash-commands--specific/setup--generate-configuration.sh "." "default.docker-compose"
fi

/bin/bash bash-commands/docker-compose--compose--up.sh "." "default.docker-compose"

echo -e "Performing deployment ... \033[0;32mdone\033[0m"
