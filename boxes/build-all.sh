#!/bin/bash

# set -x
set -e

# Convenience script used for building all of the base boxes available

# Ubuntu boxes
sudo -E ./build-ubuntu-box.sh precise
sudo -E ./build-ubuntu-box.sh quantal
sudo -E ./build-ubuntu-box.sh raring
sudo -E ./build-ubuntu-box.sh saucy

# Debian boxes
sudo -E ./build-debian-box.sh squeeze
sudo -E ./build-debian-box.sh wheezy
sudo -E ./build-debian-box.sh sid

for box in precise raring quantal saucy squeeze wheezy sid; do
  box="vagrant-lxc-${box}-amd64-`date +%Y-%m-%d`.box"
  ~/bin/dropbox_uploader.sh upload output/${box} Public/
done
