#!/bin/bash
set -e

source common/ui.sh

info "Packaging '${CONTAINER}' to '${PACKAGE}'..."

debug 'Stopping container'
lxc-stop -n ${CONTAINER} &>/dev/null || true

debug "Removing previous rootfs tarbal"
rm -f ${WORKING_DIR}/rootfs.tar.gz

log "Compressing container's rootfs"
cd $(dirname ${ROOTFS})
tar --numeric-owner -czf ${WORKING_DIR}/rootfs.tar.gz ./rootfs/*

# Prepare package contents
cd ${WORKING_DIR}

warn 'TODO: Package!'
