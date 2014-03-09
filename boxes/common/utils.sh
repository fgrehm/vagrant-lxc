#!/bin/bash

mkdir -p $(dirname $LOG)
rm -f ${LOG}
touch ${LOG}
chmod +rw ${LOG}

utils.lxc.attach() {
  cmd="$@"
  log "Running [${cmd}] inside '${CONTAINER}' container..."
  (lxc-attach -n ${CONTAINER} -- $cmd) &> ${LOG}
}

utils.lxc.start() {
  lxc-start -d -n ${CONTAINER} &>${LOG} || true
}

utils.lxc.stop() {
  lxc-stop -n ${CONTAINER} &>${LOG} || true
}

utils.lxc.destroy() {
  lxc-destroy -n ${CONTAINER} &>${LOG}
}

utils.lxc.create() {
  lxc-create -n ${CONTAINER} "$@" &>${LOG}
}
