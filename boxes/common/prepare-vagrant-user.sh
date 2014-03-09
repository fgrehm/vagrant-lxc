#!/bin/bash
set -e

source common/ui.sh

info "Preparing vagrant user..."

# Create vagrant user
if $(grep -q 'vagrant' ${ROOTFS}/etc/shadow); then
  log 'Skipping vagrant user creation'
else
  debug 'vagrant user does not exist, renaming ubuntu user...'
  mv ${ROOTFS}/home/{ubuntu,vagrant}
  chroot ${ROOTFS} usermod -l vagrant -d /home/vagrant ubuntu
  chroot ${ROOTFS} groupmod -n vagrant ubuntu
  echo -n 'vagrant:vagrant' | chroot ${ROOTFS} chpasswd
  log 'Renamed ubuntu user to vagrant and changed password.'
fi

# Configure SSH access
if [ -d ${ROOTFS}/home/vagrant/.ssh ]; then
  log 'Skipping vagrant SSH credentials configuration'
else
  debug 'SSH key has not been set'
  mkdir -p ${ROOTFS}/home/vagrant/.ssh
  echo $VAGRANT_KEY > ${ROOTFS}/home/vagrant/.ssh/authorized_keys
  chroot ${ROOTFS} chown -R vagrant: /home/vagrant/.ssh
  log 'SSH credentials configured for the vagrant user.'
fi

# Enable passwordless sudo for the vagrant user
if [ -f ${ROOTFS}/etc/sudoers.d/vagrant ]; then
  log 'Skipping sudoers file creation.'
else
  debug 'Sudoers file was not found'
  echo "vagrant ALL=(ALL) NOPASSWD:ALL" > ${ROOTFS}/etc/sudoers.d/vagrant
  chmod 0440 ${ROOTFS}/etc/sudoers.d/vagrant
  log 'Sudoers file created.'
fi
