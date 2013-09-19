#!/bin/bash

# Script used to build Ubuntu base vagrant-lxc containers
# USAGE:
#   $ sudo ./build-ubuntu-box.sh UBUNTU_RELEASE BOX_ARCH

# TODO: * Add support for flushing cache and specifying a custom base Ubuntu lxc
#         template instead of system's built in
#       * Embed vagrant public key
#       * Add date to metadata.json
#       * Ensure it is in sync with master

##################################################################################
# 1 - Create the base container

RELEASE=${1:-"raring"}
ARCH=${2:-"amd64"}

lxc-create -n ${RELEASE}-base -t ubuntu -- --release ${RELEASE} --arch ${ARCH}


##################################################################################
# 2 - Prepare vagrant user

ROOTFS=/var/lib/lxc/${RELEASE}-base/rootfs
chroot ${ROOTFS} usermod -l vagrant -d /home/vagrant ubuntu

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
# 4 - Add some goodies

PACKAGES=(vim curl wget manpages bash-completion)
chroot ${ROOTFS} apt-get install ${PACKAGES[*]} -y --force-yes


##################################################################################
# 5 - Configuration management tools


# TODO


##################################################################################
# 6 - Free up some disk space

rm -rf ${ROOTFS}/tmp/*
chroot ${ROOTFS} apt-get clean


##################################################################################
# 7 - Build box package

# Set up a working dir
mkdir -p /tmp/vagrant-lxc-${RELEASE}

# Compress container's rootfs
cd /var/lib/lxc/${RELEASE}-base
tar --numeric-owner -czf /tmp/vagrant-lxc-${RELEASE}/rootfs.tar.gz ./rootfs/*

# Prepare package contents
cd /tmp/vagrant-lxc-${RELEASE}
wget https://raw.github.com/fgrehm/vagrant-lxc/master/boxes/common/lxc-template
wget https://raw.github.com/fgrehm/vagrant-lxc/master/boxes/common/lxc.conf
wget https://raw.github.com/fgrehm/vagrant-lxc/master/boxes/common/metadata.json
chmod +x lxc-template

# Vagrant box!
PKG=vagrant-lxc-${RELEASE}-${ARCH}.box
tar -czf $PKG ./*

echo "The base box was built successfully to ${PKG}"
