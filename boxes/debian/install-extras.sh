#!/bin/bash
set -e

source common/ui.sh

info 'Installing extra packages and upgrading'

debug 'Bringing container up'
lxc-start -d -n ${CONTAINER} &>/dev/null || true

# TODO: Support for setting this from outside
UBUNTU_PACKAGES=(vim curl wget man-db bash-completion python-software-properties software-properties-common)

lxc-attach -n ${CONTAINER} -- apt-get update
lxc-attach -n ${CONTAINER} -- apt-get install ${UBUNTU_PACKAGES[*]} -y --force-yes
lxc-attach -n ${CONTAINER} -- apt-get upgrade -y --force-yes

CHEF=${CHEF:-0}
PUPPET=${PUPPET:-0}
SALT=${SALT:-0}
BABUSHKA=${BABUSHKA:-0}

if [ $CHEF = 1 ]; then
  if $(lxc-attach -n ${CONTAINER} -- which chef-solo &>/dev/null); then
    log "Chef has been installed on container, skipping"
  else
    log "Installing Chef"
    cat > ${ROOTFS}/tmp/install-chef.sh << EOF
#!/bin/sh
curl -L https://www.opscode.com/chef/install.sh -k | sudo bash
EOF
    chmod +x ${ROOTFS}/tmp/install-chef.sh
    lxc-attach -n ${CONTAINER} -- /tmp/install-chef.sh
  fi
else
  log "Skipping Chef installation"
fi

if [ $PUPPET = 1 ]; then
  if $(lxc-attach -n ${CONTAINER} -- which puppet &>/dev/null); then
    log "Puppet has been installed on container, skipping"
  elif [ ${RELEASE} = 'trusty' ]; then
    warn "Puppet can't be installed on Ubuntu Trusty 14.04, skipping"
  else
    log "Installing Puppet"
    wget http://apt.puppetlabs.com/puppetlabs-release-stable.deb -O "${ROOTFS}/tmp/puppetlabs-release-stable.deb"
    lxc-attach -n ${CONTAINER} -- dpkg -i "/tmp/puppetlabs-release-stable.deb"
    lxc-attach -n ${CONTAINER} -- apt-get update
    lxc-attach -n ${CONTAINER} -- apt-get install puppet -y --force-yes
  fi
else
  log "Skipping Puppet installation"
fi

if [ $SALT = 1 ]; then
  lxc-attach -n ${CONTAINER} -- apt-add-repository -y ppa:saltstack/salt
  lxc-attach -n ${CONTAINER} -- apt-get update
  lxc-attach -n ${CONTAINER} -- apt-get install salt-minion -y --force-yes
else
  log "Skipping Salt installation"
fi

if [ $BABUSHKA = 1 ]; then
  log "Installing Babushka"
  cat > $ROOTFS/tmp/install-babushka.sh << EOF
#!/bin/sh
curl https://babushka.me/up | sudo bash
EOF
  chmod +x $ROOTFS/tmp/install-babushka.sh
  lxc-attach -n ${CONTAINER} -- /tmp/install-babushka.sh
else
  log "Skipping Babushka installation"
fi
