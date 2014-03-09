#!/bin/bash
set -e

source common/ui.sh

export RELEASE=$1
export CONTAINER=$2
export PACKAGE=$3
export LOG=$(readlink -f .)/log/${CONTAINER}.log

info "Cleaning ${RELEASE} artifacts..."

# If container exists, check if want to continue
if $(lxc-ls | grep -q ${CONTAINER}); then
  log "Removing '${CONTAINER}' container"
  lxc-stop -n ${CONTAINER} &>/dev/null || true
  lxc-destroy -n ${CONTAINER}
else
  log "The container '${CONTAINER}' does not exist"
fi

if [ -e ${PACKAGE} ]; then
  log "Removing '${PACKAGE}'"
  rm -f ${PACKAGE}
else
  log "The package '${PACKAGE}' does not exist"
fi
