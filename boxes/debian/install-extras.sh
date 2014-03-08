#!/bin/bash
set -e

source common/ui.sh

info 'Installing extra packages and upgrading'

debug 'Bringing container up'
lxc-start -d -n ${CONTAINER} &>/dev/null || true

# TODO: Support for setting this from outside
PACKAGES=(vim curl wget man-db bash-completion python-software-properties software-properties-common)

lxc-attach -n ${CONTAINER} -- apt-get update
lxc-attach -n ${CONTAINER} -- apt-get install ${PACKAGES[*]} -y --force-yes
lxc-attach -n ${CONTAINER} -- apt-get upgrade -y --force-yes
