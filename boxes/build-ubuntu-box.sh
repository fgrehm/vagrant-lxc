#!/bin/bash

# set -x
set -e

# Script used to build Ubuntu base vagrant-lxc containers
#
# USAGE:
#   $ cd boxes && sudo ./build-ubuntu-box.sh UBUNTU_RELEASE BOX_ARCH
#
# To enable Chef or any other configuration management tool pass '1' to the
# corresponding env var:
#   $ CHEF=1 sudo -E ./build-ubuntu-box.sh UBUNTU_RELEASE BOX_ARCH
#   $ PUPPET=1 sudo -E ./build-ubuntu-box.sh UBUNTU_RELEASE BOX_ARCH
#   $ SALT=1 sudo -E ./build-ubuntu-box.sh UBUNTU_RELEASE BOX_ARCH
#   $ BABUSHKA=1 sudo -E ./build-ubuntu-box.sh UBUNTU_RELEASE BOX_ARCH

# TODO: * Add support for flushing cache and specifying a custom base Ubuntu lxc
#         template instead of system's built in
#       * Embed vagrant public key
#       * Stuff from locales (rcarmo and discourse stuff)
#       * Clean up when finished
#       * Add vagrant-lxc version to base box manifest and create an wiki page
#         for describing it

##################################################################################
# 0 - Initial setup and sanity checks

TODAY=$(date -u +"%Y-%m-%d")
NOW="${TODAY} $(date -u +'%H:%M:%S') UTC"
RELEASE=${1:-"raring"}
ARCH=${2:-"amd64"}
PKG=vagrant-lxc-${RELEASE}-${ARCH}-${TODAY}.box
WORKING_DIR=/tmp/vagrant-lxc-${RELEASE}

# Providing '1' will enable these tools
CHEF=${CHEF:-0}
PUPPET=${PUPPET:-0}
SALT=${SALT:-0}
BABUSHKA=${BABUSHKA:-0}

# Path to files bundled with the box
CWD=`readlink -f .`
LXC_TEMPLATE=${CWD}/common/lxc-template
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
  lxc-create -n ${RELEASE}-base -t ubuntu -- --release ${RELEASE} --arch ${ARCH}
fi


##################################################################################
# 2 - Prepare vagrant user

ROOTFS=/var/lib/lxc/${RELEASE}-base/rootfs
mv ${ROOTFS}/home/{ubuntu,vagrant}
chroot ${ROOTFS} usermod -l vagrant -d /home/vagrant ubuntu
chroot ${ROOTFS} groupmod -n vagrant ubuntu

echo -n 'vagrant:vagrant' | chroot ${ROOTFS} chpasswd


##################################################################################
# 3 - Setup SSH access and passwordless sudo

# Configure SSH access
mkdir -p ${ROOTFS}/home/vagrant/.ssh
wget https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub -O ${ROOTFS}/home/vagrant/.ssh/authorized_keys
chroot ${ROOTFS} chown -R vagrant: /home/vagrant/.ssh

# Enable passwordless sudo for users under the "sudo" group
cp ${ROOTFS}/etc/sudoers{,.orig}
sed -i -e \
      's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' \
      ${ROOTFS}/etc/sudoers


##################################################################################
# 4 - Add some goodies and update packages

PACKAGES=(vim curl wget man-db bash-completion)
chroot ${ROOTFS} apt-get install ${PACKAGES[*]} -y --force-yes
chroot ${ROOTFS} apt-get upgrade -y --force-yes


##################################################################################
# 5 - Configuration management tools

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
# 6 - Free up some disk space

rm -rf ${ROOTFS}/tmp/*
chroot ${ROOTFS} apt-get clean


##################################################################################
# 7 - Build box package

# Compress container's rootfs
cd $(dirname $ROOTFS)
tar --numeric-owner -czf /tmp/vagrant-lxc-${RELEASE}/rootfs.tar.gz ./rootfs/*

# Prepare package contents
cd $WORKING_DIR
cp $LXC_TEMPLATE .
cp $LXC_CONF .
cp $METATADA_JSON .
chmod +x lxc-template
sed -i "s/<TODAY>/${NOW}/" metadata.json

# Vagrant box!
tar -czf $PKG ./*

echo "The base box was built successfully to ${WORKING_DIR}/${PKG}"
