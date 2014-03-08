#!/bin/bash
set -e

if [ "$(id -u)" != "0" ]; then
  echo "You should run this script as root (sudo)."
  exit 1
fi

export NO_COLOR='\033[0m'
export OK_COLOR='\033[32;01m'
export ERROR_COLOR='\033[31;01m'
export WARN_COLOR='\033[33;01m'

export DISTRIBUTION="ubuntu"
export RELEASE=$1
export ARCH=$2
export CONTAINER=$3
export PACKAGE=$4

if [ -f ${PACKAGE} ]; then
  echo -e "${WARN_COLOR}==> The box '${PACKAGE}' already exists, skipping...${NO_COLOR}"
  echo
  exit
fi

echo -e "${OK_COLOR}==> Building '${RELEASE} (${ARCH})' to '${PACKAGE}'...${NO_COLOR}"

./common/download.sh ubuntu ${RELEASE} ${ARCH} ${CONTAINER}
./common/prepare-vagrant-user.sh ${CONTAINER}
./debian/install-extras.sh ${CONTAINER}
./debian/clean.sh ${CONTAINER}
./common/package.sh ${CONTAINER} ${PACKAGE}
touch $PACKAGE

echo -e "${OK_COLOR}==> Finished building '${RELEASE} (${ARCH})' to '${PACKAGE}'...${NO_COLOR}"
echo
