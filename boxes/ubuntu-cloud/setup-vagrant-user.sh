#!/bin/bash
# Argument = -r <path/to/rootfs> -i <container-ip> -k <vagrant-private-key-path>

CONTAINER_ROOTFS=
CONTAINER_IP=
VAGRANT_PRIVATE_KEY_PATH=

options=$(getopt -o r:i:k: -- "$@")
eval set -- "$options"

declare r CONTAINER_ROOTFS \
        i CONTAINER_IP \
        k VAGRANT_PRIVATE_KEY_PATH

while true
do
  case "$1" in
    -r)        CONTAINER_ROOTFS=$2; shift 2;;
    -i)        CONTAINER_IP=$2; shift 2;;
    -k)        VAGRANT_PRIVATE_KEY_PATH=$2; shift 2;;
    *)              break ;;
  esac
done

if [[ -z $CONTAINER_ROOTFS ]] || [[ -z $CONTAINER_IP ]] || [[ -z $VAGRANT_PRIVATE_KEY_PATH ]]
then
  echo 'You forgot an argument!'
  exit 1
fi

remote_setup_script() {
  cat << EOF
useradd -d /home/vagrant -m vagrant -r -s /bin/bash
usermod -a -G admin vagrant
cp /etc/sudoers /etc/sudoers.orig
sed -i -e '/Defaults\s\+env_reset/a Defaults\texempt_group=admin' /etc/sudoers
sed -i -e 's/%admin\s\+ALL=(ALL)\s\+ALL/%admin ALL=NOPASSWD:ALL/g' /etc/sudoers
service sudo restart
sudo su vagrant -c "mkdir -p /home/vagrant/.ssh"
sudo su vagrant -c "curl -s -o /home/vagrant/.ssh/authorized_keys https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub"
sudo apt-get install -y puppet
EOF
}

REMOTE_SETUP_SCRIPT_PATH="/tmp/setup-vagrant-user"

# Ensures the private key has the right permissions
# Might not be needed after: https://github.com/mitchellh/vagrant/commit/d304cca35d19c5bd370330c74f003b6ac46e7f4a
chmod 0600 $VAGRANT_PRIVATE_KEY_PATH

remote_setup_script > "${CONTAINER_ROOTFS}${REMOTE_SETUP_SCRIPT_PATH}"
chmod +x "${CONTAINER_ROOTFS}${REMOTE_SETUP_SCRIPT_PATH}"

ssh ubuntu@"$CONTAINER_IP" \
		-o 'StrictHostKeyChecking no' \
		-o 'UserKnownHostsFile /dev/null' \
		-i $VAGRANT_PRIVATE_KEY_PATH \
		-- \
    sudo $REMOTE_SETUP_SCRIPT_PATH
