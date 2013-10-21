#!/bin/bash

# set -x
set -e

# Script used to build OpenMandriva base vagrant-lxc containers, currently limited to
# host's arch
#
# USAGE:
#   $ cd boxes && sudo ./build-openmandriva-box.sh OPENMANDRIVA_RELEASE BOX_ARCH
#
# TODO: scripts for install CHEF, PUPPET, SALT, BABUSHKA
# To enable Chef or any other configuration management tool pass '1' to the
# corresponding env var:
#   $ CHEF=1 sudo -E ./build-openmandriva-box.sh OPENMANDRIVA_RELEASE BOX_ARCH
#   $ PUPPET=1 sudo -E ./build-openmandriva-box.sh OPENMANDRIVA_RELEASE BOX_ARCH
#   $ SALT=1 sudo -E ./build-openmandriva-box.sh OPENMANDRIVA_RELEASE BOX_ARCH
#   $ BABUSHKA=1 sudo -E ./build-openmandriva-box.sh OPENMANDRIVA_RELEASE BOX_ARCH

##################################################################################
# 0 - Initial setup and sanity checks

TODAY=$(date -u +"%Y-%m-%d")
NOW=$(date -u)
RELEASE=${1:-"openmandriva2013.0"}
ARCH=${2:-"x86_64"}
PKG=vagrant-lxc-${RELEASE}-${ARCH}-${TODAY}.box
WORKING_DIR=/tmp/vagrant-lxc-${RELEASE}
VAGRANT_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key"
ROOTFS=/var/lib/lxc/${RELEASE}-base/${RELEASE}-base/rootfs

# Providing '1' will enable these tools
CHEF=${CHEF:-0}
PUPPET=${PUPPET:-0}
SALT=${SALT:-0}
BABUSHKA=${BABUSHKA:-0}

# Path to files bundled with the box
CWD=`readlink -f .`
LXC_TEMPLATE=${CWD}/common/lxc-template-openmandriva
LXC_CONF=${CWD}/common/lxc.conf
METATADA_JSON=${CWD}/common/metadata.json

# Set up a working dir
mkdir -p $WORKING_DIR

if [ -f "${WORKING_DIR}/${PKG}" ]; then
  echo "Found a box on ${WORKING_DIR}/${PKG} already!"
  exit 1
fi

##################################################################################
# 1 - Create the base container

if $(lxc-ls | grep -q "${RELEASE}-base"); then
  echo "Base container already exists, please remove it with \`lxc-destroy -n ${RELEASE}-base\`!"
  exit 1
else
  export SUITE=$RELEASE
  lxc-create -n ${RELEASE}-base -t openmandriva -- -R ${RELEASE} --arch ${ARCH}
fi


######################################
# 2 - Fix some known issues

# Fixes some networking issues
cat /etc/resolv.conf > ${ROOTFS}/etc/resolv.conf

##################################################################################
# 3 - Prepare vagrant user
chroot ${ROOTFS} su -c 'useradd --create-home -s /bin/bash vagrant'

# echo -n 'vagrant:vagrant' | chroot ${ROOTFS} chpasswd
chroot ${ROOTFS} su -c "echo -n 'vagrant:vagrant' | chpasswd"


##################################################################################
# 4 - Setup SSH access and passwordless sudo

# Configure SSH access
mkdir -p ${ROOTFS}/home/vagrant/.ssh
echo $VAGRANT_KEY > ${ROOTFS}/home/vagrant/.ssh/authorized_keys
chroot ${ROOTFS} chown -R vagrant: /home/vagrant/.ssh

chroot ${ROOTFS} urpmi sudo --auto
chroot ${ROOTFS} usermod -a -G wheel vagrant

# Enable passwordless sudo for users under the "sudo" group
cp ${ROOTFS}/etc/sudoers{,.orig}
sed -i 's/Defaults    requiretty/\# Defaults requiretty/' ${ROOTFS}/etc/sudoers
sed -i 's/\#%wheel/\%wheel/'  ${ROOTFS}/etc/sudoers
sed -i 's/\# %wheel/\%wheel/' ${ROOTFS}/etc/sudoers
# sed -i -e \
#       's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' \
#       ${ROOTFS}/etc/sudoers


##################################################################################
# 5 - Add some goodies and update packages

PACKAGES=(vim curl wget man bash-completion openssh-server openssh-clients tar)
chroot ${ROOTFS} urpmi ${PACKAGES[*]} --auto
chroot ${ROOTFS} urpmi.update -a


##################################################################################
# 6 - Configuration management tools

if [ $CHEF = 1 ]; then
  ./common/install-chef $ROOTFS
fi

if [ $PUPPET = 1 ]; then
  ./common/install-puppet $ROOTFS
fi

if [ $SALT = 1 ]; then
  ./common/install-salt $ROOTFS
fi

if [ $BABUSHKA = 1 ]; then
  ./common/install-babushka $ROOTFS
fi


##################################################################################
# 7 - Free up some disk space

rm -rf ${ROOTFS}/tmp/*
# chroot ${ROOTFS} urpmi clean metadata


##################################################################################
# 8 - Build box package

# Compress container's rootfs
cd $(dirname $ROOTFS)
tar --numeric-owner -czf /tmp/vagrant-lxc-${RELEASE}/rootfs.tar.gz ./rootfs/*

# Prepare package contents
cd $WORKING_DIR
cp $LXC_TEMPLATE lxc-template
cp $LXC_CONF .
cp $METATADA_JSON .
chmod +x lxc-template
sed -i "s/<TODAY>/${NOW}/" metadata.json

# Vagrant box!
tar -czf $PKG ./*

chmod +rw ${WORKING_DIR}/${PKG}
mkdir -p ${CWD}/output
mv ${WORKING_DIR}/${PKG} ${CWD}/output

# Clean up after ourselves
rm -rf ${WORKING_DIR}

echo "The base box was built successfully to ${CWD}/output/${PKG}"
