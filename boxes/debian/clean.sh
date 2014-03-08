#!/bin/bash
set -e

source common/ui.sh

debug 'Bringing container up'
lxc-start -d -n ${CONTAINER} &>/dev/null || true

info "Cleaning up '${CONTAINER}'..."

log 'Removing temporary files...'
lxc-attach -n ${CONTAINER} -- rm -rf /tmp/*

log 'Removing downloaded packages...'
lxc-attach -n ${CONTAINER} -- apt-get clean
