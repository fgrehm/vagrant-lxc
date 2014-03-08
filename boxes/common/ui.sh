#!/bin/bash

log() {
  echo "    ${1}" >&2
}

debug() {
  [ ! $DEBUG ] || echo "    [DEBUG] ${1}" >&2
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

  echo -n "    ${question} [${default_prompt}] " >&2
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
