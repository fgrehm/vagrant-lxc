#!/bin/bash
set -e

source common/ui.sh

# TODO: Create file with build date / time on container

info "Packaging '${CONTAINER}' to '${PACKAGE}'..."

debug 'Stopping container'
lxc-stop -n ${CONTAINER} &>/dev/null || true

if [ -f ${WORKING_DIR}/rootfs.tar.gz ]; then
  log "Removing previous rootfs tarbal"
  rm -f ${WORKING_DIR}/rootfs.tar.gz
fi

log "Compressing container's rootfs"
pushd  $(dirname ${ROOTFS}) &>/dev/null
  tar --numeric-owner --anchored --exclude=./rootfs/dev/log -czf \
      ${WORKING_DIR}/rootfs.tar.gz ./rootfs/*
popd &>/dev/null

# Prepare package contents
pushd  ${WORKING_DIR} &>/dev/null
  warn "TODO: Package on `pwd`"
  warn "TODO: Add creation date"
  warn "TODO: Fix hostname (its too big!)"
popd &>/dev/null

# cp $LXC_TEMPLATE .
# cp $LXC_CONF .
# cp $METATADA_JSON .
# chmod +x lxc-template
# sed -i "s/<TODAY>/${NOW}/" metadata.json
#
# # Vagrant box!
# tar -czf $PKG ./*
#
# chmod +rw ${WORKING_DIR}/${PKG}
# mkdir -p ${CWD}/output
# mv ${WORKING_DIR}/${PKG} ${CWD}/output
#
# # Clean up after ourselves
# rm -rf ${WORKING_DIR}
# lxc-destroy -n ${RELEASE}-base
#
# echo "The base box was built successfully to ${CWD}/output/${PKG}"
