#!/bin/bash
set -e

source common/ui.sh

# If container exists, check if want to continue
if $(lxc-ls | grep -q ${CONTAINER}); then
  if ! $(confirm "The '${CONTAINER}' container already exists, do you want to continue building the box?" 'y'); then
    log 'Aborting...'
    exit 1
  fi
fi

# If container exists and wants to continue building the box
if $(lxc-ls | grep -q ${CONTAINER}); then
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

# TODO: Nicely handle boxes that don't have an image associated

log "Container created!"
