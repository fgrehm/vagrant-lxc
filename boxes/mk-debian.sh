#!/bin/bash
set -e

source common/ui.sh

if [ "$(id -u)" != "0" ]; then
  echo "You should run this script as root (sudo)."
  exit 1
fi

export DISTRIBUTION=$1
export RELEASE=$2
export ARCH=$3
export CONTAINER=$4
export PACKAGE=$5
export ROOTFS="/var/lib/lxc/${CONTAINER}/rootfs"
export WORKING_DIR="/tmp/${CONTAINER}"
export NOW=$(date -u)
export LOG=$(readlink -f .)/log/${CONTAINER}.log

mkdir -p $(dirname $LOG)
echo '############################################' > ${LOG}
echo "# Beginning build at $(date)" >> ${LOG}
touch ${LOG}
chmod +rw ${LOG}

if [ -f ${PACKAGE} ]; then
  warn "The box '${PACKAGE}' already exists, skipping..."
  echo
  exit
fi

debug "Creating ${WORKING_DIR}"
mkdir -p ${WORKING_DIR}

info "Building box to '${PACKAGE}'..."

./common/download.sh ${DISTRIBUTION} ${RELEASE} ${ARCH} ${CONTAINER}
./debian/vagrant-lxc-fixes.sh ${DISTRIBUTION} ${RELEASE} ${ARCH} ${CONTAINER}
./debian/install-extras.sh ${CONTAINER}
./common/prepare-vagrant-user.sh ${CONTAINER}
./debian/clean.sh ${CONTAINER}
./common/package.sh ${CONTAINER} ${PACKAGE}

info "Finished building '${PACKAGE}'!"
log "Run \`sudo lxc-destroy -n ${CONTAINER}\` or \`make clean\` to remove the container that was created along the way"
echo
