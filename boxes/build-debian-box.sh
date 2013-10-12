#!/bin/bash

# set -x
set -e

# Script used to build Debian base vagrant-lxc containers, currently limited to
# host's arch
#
# USAGE:
#   $ cd boxes && sudo ./build-debian-box.sh DEBIAN_RELEASE
#
# To enable Chef or any other configuration management tool pass '1' to the
# corresponding env var:
#   $ CHEF=1 sudo -E ./build-debian-box.sh DEBIAN_RELEASE
#   $ PUPPET=1 sudo -E ./build-debian-box.sh DEBIAN_RELEASE
#   $ SALT=1 sudo -E ./build-debian-box.sh DEBIAN_RELEASE
#   $ BABUSHKA=1 sudo -E ./build-debian-box.sh DEBIAN_RELEASE

##################################################################################
# 0 - Initial setup and sanity checks

TODAY=$(date -u +"%Y-%m-%d")
NOW=$(date -u)
RELEASE=${1:-"wheezy"}
ARCH=$(dpkg --print-architecture) # This is what the Debian template will use under the hood
PKG=vagrant-lxc-${RELEASE}-${ARCH}-${TODAY}.box
WORKING_DIR=/tmp/vagrant-lxc-${RELEASE}
VAGRANT_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key"
ROOTFS=/var/lib/lxc/${RELEASE}-base/rootfs

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
  export SUITE=$RELEASE
  lxc-create -n ${RELEASE}-base -t debian
fi


######################################
# 2 - Fix some known issues

# Fixes some networking issues
# See https://github.com/fgrehm/vagrant-lxc/issues/91 for more info
sed -i -e "s/\(127.0.0.1\s\+localhost\)/\1\n127.0.1.1\t${RELEASE}-base\n/g" ${ROOTFS}/etc/hosts

# Ensures that `/tmp` does not get cleared on halt
# See https://github.com/fgrehm/vagrant-lxc/issues/68 for more info
chroot $ROOTFS /usr/sbin/update-rc.d -f checkroot-bootclean.sh remove
chroot $ROOTFS /usr/sbin/update-rc.d -f mountall-bootclean.sh remove
chroot $ROOTFS /usr/sbin/update-rc.d -f mountnfs-bootclean.sh remove

# Ensure locales are properly set, based on http://linux.livejournal.com/1880366.html
sed -i "s/^# en_US/en_US/" ${ROOTFS}/etc/locale.gen
chroot $ROOTFS /usr/sbin/locale-gen
chroot $ROOTFS update-locale LANG=en_US.UTF-8


##################################################################################
# 3 - Prepare vagrant user
sudo chroot ${ROOTFS} useradd --create-home -s /bin/bash vagrant

echo -n 'vagrant:vagrant' | chroot ${ROOTFS} chpasswd


##################################################################################
# 4 - Setup SSH access and passwordless sudo

# Configure SSH access
mkdir -p ${ROOTFS}/home/vagrant/.ssh
echo $VAGRANT_KEY > ${ROOTFS}/home/vagrant/.ssh/authorized_keys
chroot ${ROOTFS} chown -R vagrant: /home/vagrant/.ssh

chroot ${ROOTFS} apt-get install sudo -y --force-yes
chroot ${ROOTFS} adduser vagrant sudo

# Enable passwordless sudo for users under the "sudo" group
cp ${ROOTFS}/etc/sudoers{,.orig}
sed -i -e \
      's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' \
      ${ROOTFS}/etc/sudoers


##################################################################################
# 5 - Add some goodies and update packages

PACKAGES=(vim curl wget man-db bash-completion ca-certificates)
chroot ${ROOTFS} apt-get install ${PACKAGES[*]} -y --force-yes
chroot ${ROOTFS} apt-get upgrade -y --force-yes


##################################################################################
# 6 - Configuration management tools

if [ $CHEF = 1 ]; then
  ./common/install-chef $ROOTFS
fi

if [ $PUPPET = 1 ]; then
  ./common/install-puppet $ROOTFS
fi

if [ $SALT = 1 ]; then
  ./common/install-salt-debian $ROOTFS
fi

if [ $BABUSHKA = 1 ]; then
  ./common/install-babushka $ROOTFS
fi


##################################################################################
# 7 - Free up some disk space

rm -rf ${ROOTFS}/tmp/*
chroot ${ROOTFS} apt-get clean


##################################################################################
# 8 - Build box package

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

chmod +rw ${WORKING_DIR}/${PKG}
mkdir -p ${CWD}/output
mv ${WORKING_DIR}/${PKG} ${CWD}/output

# Clean up after ourselves
rm -rf ${WORKING_DIR}

echo "The base box was built successfully to ${CWD}/output/${PKG}"
