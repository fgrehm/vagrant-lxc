#!/bin/bash

export NO_COLOR='\033[0m'
export OK_COLOR='\033[32;01m'
export ERROR_COLOR='\033[31;01m'
export WARN_COLOR='\033[33;01m'

log() {
  echo "    [${RELEASE}] ${1}" >>${LOG}
  echo "    [${RELEASE}] ${1}" >&2
}

warn() {
  echo "==> [${RELEASE}] [WARN] ${1}" >>${LOG}
  echo -e "${WARN_COLOR}==> [${RELEASE}] ${1}${NO_COLOR}"
}

info() {
  echo "==> [${RELEASE}] [INFO] ${1}" >>${LOG}
  echo -e "${OK_COLOR}==> [${RELEASE}] ${1}${NO_COLOR}"
}

confirm() {
  question=${1}
  default=${2}
  default_prompt=

  if [ $default = 'n' ]; then
    default_prompt="y/N"
    default='No'
  else
    default_prompt="Y/n"
    default='Yes'
  fi

  echo -e -n "${WARN_COLOR}==> [${RELEASE}] ${question} [${default_prompt}] ${NO_COLOR}" >&2
  read answer

  if [ -z $answer ]; then
    debug "Answer not provided, assuming '${default}'"
    answer=${default}
  fi

  if $(echo ${answer} | grep -q -i '^y'); then
    return 0
  else
    return 1
  fi
}

debug() {
  [ ! $DEBUG ] || echo "    [${RELEASE}] [DEBUG] ${1}" >&2
}
