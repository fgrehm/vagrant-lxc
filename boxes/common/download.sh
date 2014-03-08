#!/bin/bash
set -e

source common/ui.sh

container_exists=$(lxc-ls | grep -q ${CONTAINER})
# If container exists, check if want to continue
if $container_exists; then
  if ! $(confirm "The '${CONTAINER}' container already exists, do you want to continue building the box?" 'n'); then
    log 'Aborting...'
    exit 1
  fi
fi

# If container exists and wants to continue building the box
if $container_exists; then
  if $(confirm "Do you want to rebuild the '${CONTAINER}' container?" 'n'); then
    log "Destroying container ${CONTAINER}..."
    lxc-stop -n ${CONTAINER} &>/dev/null || true
    lxc-destroy -n ${CONTAINER}
  else
    log "Reusing existing container..."
    exit 0
  fi
fi

# If we got to this point, we need to create the container
log "Creating container..."
lxc-create -n ${CONTAINER} -t download -- \
           --dist ${DISTRIBUTION} \
           --release ${RELEASE} \
           --arch ${ARCH}
