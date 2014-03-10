#!/bin/bash
set -e

source common/ui.sh
source common/utils.sh

# Fixes some networking issues
# See https://github.com/fgrehm/vagrant-lxc/issues/91 for more info
if ! $(grep -q 'ip6-allhosts' ${ROOTFS}/etc/hosts); then
  log "Adding ipv6 allhosts entry to container's /etc/hosts"
  echo 'ff02::3 ip6-allhosts' >> ${ROOTFS}/etc/hosts
fi

utils.lxc.start

if [ ${DISTRIBUTION} = 'debian' ]; then
  # Ensure locales are properly set, based on http://askubuntu.com/a/238063
  LANG=${LANG:-en_US.UTF-8}
  sed -i "s/^# ${LANG}/${LANG}/" ${ROOTFS}/etc/locale.gen
  utils.lxc.attach /usr/sbin/locale-gen
  utils.lxc.attach update-locale LANG=${LANG}

  # Fixes some networking issues
  # See https://github.com/fgrehm/vagrant-lxc/issues/91 for more info
  sed -i -e "s/\(127.0.0.1\s\+localhost\)/\1\n127.0.1.1\t${RELEASE}-base\n/g" ${ROOTFS}/etc/hosts

  # Ensures that `/tmp` does not get cleared on halt
  # See https://github.com/fgrehm/vagrant-lxc/issues/68 for more info
  utils.lxc.attach /usr/sbin/update-rc.d -f checkroot-bootclean.sh remove
  utils.lxc.attach /usr/sbin/update-rc.d -f mountall-bootclean.sh remove
  utils.lxc.attach /usr/sbin/update-rc.d -f mountnfs-bootclean.sh remove
fi
