#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commons/bootstrap.sh" && set +e
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commons/log.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commons/colors.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commons/checks.sh"

function main {

  local -r snap_packages=$(snap list --all | egrep "disabled" | awk {'print $1'})
  local -r snap_revision=$(snap list --all | egrep "disabled" | awk {'print $3'})

  if [[ -z "$snap_revision" ]] ; then
    log_warn "${red}Could not find any disabled/outdated packages${nocolor}"
    exit 1
  else
    set $snap_revision
  fi

  for package in $snap_packages
  do
    log_info "${yellow}Snap package ${package} has outdated revision ${1} ${nocolor}"
    read -p "Do you want to remove this package? [yes|no|yes-all] " answer
    if [[ "$answer" =~ ^y(es)?$ ]] ; then
      sudo snap remove ${package} --revision=${1}
      log_info "${green}Revision ${package}:${1} has been purged${nocolor}"
      sleep 1
    elif [[ "$answer" =~ ^yes\-all$ ]] ; then
      log_warn "${yellow}Removing all disabled packages${nocolor}"
      sudo snap list --all | awk '$6~"disabled"{print $1" --revision "$3}' | xargs -rn3 sudo snap remove
      log_info "${yellow}List of remaining packages: ${snap_packages} ${nocolor}\n"
      return 0
    else
      log_error "${red}Aborting operation, choose correct answer${nocolor}"
      return 1
    fi
    shift
  done
}

main "$@"
operation_result "removing snap packages"
