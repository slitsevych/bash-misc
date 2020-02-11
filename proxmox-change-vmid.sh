#!/usr/bin/env bash

set -o errtrace
set -o functrace
set -o errexit
set -o nounset
set -o pipefail

export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

nocolor="\033[0m"
red="\033[0;31m"
green="\033[0;32m"
yellow="\033[0;33m"
blue="\033[0;34m"
magenta="\033[0;35m"

function log {
  local -r level="$1"
  local -r message="$2"
  local -r timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  local -r script_name="$(basename "$0")"
  >&2 echo -e "${timestamp} [${level}] [$script_name] ${message}"
}

function log_info {
  local -r message="$1"
  log "${green}INFO${nocolor}" "$message"
}

function log_warn {
  local -r message="$1"
  log "${yellow}WARN${nocolor}" "$message"
}

function log_error {
  local -r message="$1"
  log "${red}ERROR${nocolor}" "$message"
}

function status {
  if [[ `echo $?` == 0 ]] ; then
    log_info "${magenta}All went well with ${1}${nocolor}\n"
  else
    log_error "${red}Error executing script${nocolor}\n"
  fi
}

read -p "Enter current VM ID: " ORIGINAL_ID
read -p "Enter new VM ID: " NEW_ID

function vm_status {

  local -r STATUS=$(qm status ${ORIGINAL_ID} | grep "stopped" | wc -l 2>/dev/null)

  log_info "${magenta}Checking VM status${nocolor}"
  if [[ ! -f /etc/pve/nodes/proxmox/qemu-server/${ORIGINAL_ID}.conf ]] ; then
    log_error "${red}VM does not exist${nocolor}"
    exit 1
  elif [[ "$STATUS" == 1 ]] ; then
    log_info "${green}VM exists and it is stopped, proceeding${nocolor}"
  else
    log_warn "${yellow}VM is running, stopping it${nocolor}"
    qm stop ${ORIGINAL_ID} ; sleep 5
  fi

  if [[ -f /etc/pve/nodes/proxmox/qemu-server/${NEW_ID}.conf ]] ; then
    log_error "${red}It looks that new ID is already in use, please choose another one${nocolor}"
    exit 1
  fi
}

function main {
  if ! [[ -z ${ORIGINAL_ID} ]] && ! [[ -z ${NEW_ID} ]] ; then
    cd /dev/pve && \
    log_info "${magenta}Changing disk ID${nocolor}"
    log_info "`mv -v {vm-${ORIGINAL_ID}-disk-1,vm-${NEW_ID}-disk-1}`"
      if [[ ! -z /dev/pve/vm-${NEW_ID}-disk-1 ]] ; then
        log_info "${green}OK, disk ID has been changed${nocolor}\n"
      else
        log_error "${red}Disk ID has not been changed, please recheck${nocolor}\n" && exit 0
      fi
    cd /etc/pve/nodes/proxmox/qemu-server && \
    log_info "${magenta}Changing .conf file${nocolor}"
    log_info "`mv -v {${ORIGINAL_ID}.conf,${NEW_ID}.conf}`"
      if [[ -f /etc/pve/nodes/proxmox/qemu-server/${NEW_ID}.conf ]] ; then
        log_info "${green}OK, conf file has been changed, changing virtio device id:${nocolor}"
        sed -i 's/vm-'$ORIGINAL_ID'/vm-'$NEW_ID'/' ${NEW_ID}.conf
        log_info "`cat ${NEW_ID}.conf | grep "vm-$NEW_ID"` --> `echo -e "${green}OK${nocolor}"`"
      else
        log_error "${red}Not OK, conf file hasn't been changed${nocolor}" && exit 0
      fi

    if [[ $(qm status ${NEW_ID} | grep "status" | wc -l) -eq 1 ]] ; then
      log_info "${magenta}Seems like everything is good${nocolor}\n"
    else
      log_error "${red}Something went wrong, cannot check VM status${nocolor}\n" && exit 1
    fi
  fi
}

function post_action {
  read -p "Would you like to start VM? [yes|no] " start
  for answer in $start
  do
    case "$answer" in
      y|yes|Yes )
        qm start ${NEW_ID}
        log_info "${green}Ok, starting VM${nocolor} `sleep 5` --> `qm status ${NEW_ID}`"
        return 0
        ;;
      no|n|No )
        log_info "${yellow}Alright, got it, later then!${nocolor}\n"
        return 0
        ;;
      * )
        log_warn "${red}Please answer yes or no!${nocolor}"
        post_action
        ;;
    esac
  done
}

function script {
  vm_status
  status "reviewing VM status"
  main
  post_action
  status "making necessary changes"
}

script "$@"
