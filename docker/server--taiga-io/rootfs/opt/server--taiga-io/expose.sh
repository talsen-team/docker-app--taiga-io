#!/bin/bash

set -euo pipefail

VAR_OPERATION="${1}"
VAR_PATH_TO_EXPOSE="${2}"

if [ "${VAR_OPERATION}" != "export" ] &&
   [ "${VAR_OPERATION}" != "import" ]; then
  echo "Invalid expose operation '${VAR_OPERATION}'..."
  echo "Must be either 'export' or 'import'..."
  exit 1
fi

if [ "${VAR_PATH_TO_EXPOSE}" = "" ]; then
  echo "Can not expose an empty path..."
  exit 1
fi

if   [ "${VAR_OPERATION}" = "export" ]; then
  mkdir -p "/expose${VAR_PATH_TO_EXPOSE}"    \
   && sudo cp -Rp "${VAR_PATH_TO_EXPOSE}/."  \
           "/expose${VAR_PATH_TO_EXPOSE}/"   \
   && sudo rm -rf "${VAR_PATH_TO_EXPOSE}"
elif [ "${VAR_OPERATION}" = "import" ]; then
  if [ -z "$(sudo ls -A ${VAR_PATH_TO_EXPOSE}/)" ]; then
    sudo mkdir -p      "${VAR_PATH_TO_EXPOSE}"
    sudo cp -Rp "/expose${VAR_PATH_TO_EXPOSE}/." \
                       "${VAR_PATH_TO_EXPOSE}/"
  fi
fi
