#!/bin/bash
set -e

source common/ui.sh
source common/utils.sh

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
    utils.lxc.stop
    utils.lxc.destroy
  else
    log "Reusing existing container..."
    exit 0
  fi
fi

# If we got to this point, we need to create the container
log "Creating container..."
if [ $RELEASE = 'raring' ]; then
  utils.lxc.create -t ubuntu -- \
                   --release ${RELEASE} \
                   --arch ${ARCH}
else
  utils.lxc.create -t download -- \
                   --dist ${DISTRIBUTION} \
                   --release ${RELEASE} \
                   --arch ${ARCH}
fi
log "Container created!"


# Fixes some networking issues
# See https://github.com/fgrehm/vagrant-lxc/issues/91 for more info
if ! $(grep -q 'ip6-allhosts' ${ROOTFS}/etc/hosts); then
  log "Adding ipv6 allhosts entry to container's /etc/hosts"
  echo 'ff02::3 ip6-allhosts' >> ${ROOTFS}/etc/hosts
fi
