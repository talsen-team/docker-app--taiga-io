#!/bin/bash

set -euo pipefail

VAR_HOST_PATH_TO_VOLUMES_ROOT="./volumes/"
VAR_HOST_PATH_TO_VOLUMES_ROOT_BAK="./volumes.bak/"
VAR_HOST_PATH_TO_VOLUMES_ROOT_OLD="./delete.volumes/"

function ensure_running_as_root() {
    if [[ ${EUID} -ne 0 ]];
    then
        echo " * This script must be run as root." 
        exit 1
    fi
}

function ensure_existent_volumes_to_backup() {
    echo -E " * Checking host path to volumes root ..."

    if [ ! -d "${VAR_HOST_PATH_TO_VOLUMES_ROOT}" ];
    then
        echo "  * Host path to volumes root \"$( realpath ${VAR_HOST_PATH_TO_VOLUMES_ROOT} )\" does not exist."
        echo -e " * Checking host path to volumes root ... \033[0;31mfailed\033[0m"
        exit 0
    fi

    echo -e " * Checking host path to volumes root ... \033[0;32mdone\033[0m"
}

function delete_old_backup() {
    echo -E " * Deleting old backup \"$( realpath ${VAR_HOST_PATH_TO_VOLUMES_ROOT_OLD} )\" ..."

    if [ ! -d "${VAR_HOST_PATH_TO_VOLUMES_ROOT_OLD}" ];
    then
        echo -e " * Deleting old backup \"$( realpath ${VAR_HOST_PATH_TO_VOLUMES_ROOT_OLD} )\" ... \033[0;33mskipped\033[0m"
    else
        rm --force                                \
           --recursive                            \
           "${VAR_HOST_PATH_TO_VOLUMES_ROOT_OLD}"
        echo -e " * Deleting old backup \"$( realpath ${VAR_HOST_PATH_TO_VOLUMES_ROOT_OLD} )\" ... \033[0;32mdone\033[0m"
    fi
}

function degrade_last_backup_to_old_backup() {
    echo -E " * Degrading last backup \"$( realpath ${VAR_HOST_PATH_TO_VOLUMES_ROOT_BAK} )\" to old backup ..."

    if [ ! -d "${VAR_HOST_PATH_TO_VOLUMES_ROOT_BAK}" ];
    then
        echo -e " * Degrading last backup \"$( realpath ${VAR_HOST_PATH_TO_VOLUMES_ROOT_BAK} )\" to old backup ... \033[0;33mskipped\033[0m"
    else
        mv ${VAR_HOST_PATH_TO_VOLUMES_ROOT_BAK} \
           ${VAR_HOST_PATH_TO_VOLUMES_ROOT_OLD}
        echo -e " * Degrading last backup \"$( realpath ${VAR_HOST_PATH_TO_VOLUMES_ROOT_BAK} )\" to old backup ... \033[0;32mdone\033[0m"
    fi
}

function create_backup() {
    echo -E " * Creating backup ..."

    rsync --archive                              \
          --info=progress2                       \
          --stats                                \
          "${VAR_HOST_PATH_TO_VOLUMES_ROOT}"     \
          "${VAR_HOST_PATH_TO_VOLUMES_ROOT_BAK}"

    echo -e " * Creating backup ... \033[0;32mdone\033[0m"
}

function checkout_latest_repository_state() {
    echo -E " * Checking out latest repository state ..."

    git pull --rebase \
             origin   \
             master

    git submodule update --init      \
                         --recursive \
                         --remote

    git submodule update --recursive

    echo -e " * Checking out latest repository state ... \033[0;32mdone\033[0m"
}

function deploy_docker_services() {
    echo -E " * Deploying docker services ..."

    /bin/bash bash-ci/command-deploy.sh

    echo -e " * Deploying docker services ... \033[0;32mdone\033[0m"
}

function purge_docker_services() {
    echo -E " * Purging docker services ..."

    /bin/bash bash-ci/command-purge.sh

    echo -e " * Purging docker services ... \033[0;32mdone\033[0m"
}

function pull_docker_images() {
    echo -E " * Pulling docker images ..."

    /bin/bash bash-ci/command-pull-images.sh

    echo -e " * Pulling docker images ... \033[0;32mdone\033[0m"
}

echo -E "Performing upgrade ..."

ensure_running_as_root

ensure_existent_volumes_to_backup

purge_docker_services

delete_old_backup

degrade_last_backup_to_old_backup

create_backup

checkout_latest_repository_state

pull_docker_images

deploy_docker_services

echo -e "Performing upgrade ... \033[0;32mdone\033[0m"
