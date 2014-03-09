#!/bin/bash
set -e

source common/ui.sh

if [ "$(id -u)" != "0" ]; then
  echo "You should run this script as root (sudo)."
  exit 1
fi

export DISTRIBUTION="ubuntu"
export RELEASE=$1
export ARCH=$2
export CONTAINER=$3
export PACKAGE=$4
export ROOTFS="/var/lib/lxc/${CONTAINER}/rootfs"
export WORKING_DIR="/tmp/${CONTAINER}"
export NOW=$(date -u)
export LOG=$(readlink -f .)/log/${CONTAINER}.log

if [ -f ${PACKAGE} ]; then
  warn "The box '${PACKAGE}' already exists, skipping..."
  echo
  exit
fi

debug "Creating ${WORKING_DIR}"
mkdir -p ${WORKING_DIR}

info "Building box to '${PACKAGE}'..."

./common/download.sh ubuntu ${RELEASE} ${ARCH} ${CONTAINER}
./common/prepare-vagrant-user.sh ${CONTAINER}
./debian/install-extras.sh ${CONTAINER}
./debian/clean.sh ${CONTAINER}
./common/package.sh ${CONTAINER} ${PACKAGE}

info "Finished building '${PACKAGE}'!"
log "Run \`sudo lxc-destroy -n ${CONTAINER}\` to remove the container that was created along the way"
echo
