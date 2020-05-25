#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commons/bootstrap.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commons/log.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commons/colors.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commons/checks.sh"

function main {
  local -r STORAGE="$HOME/.atom/storage"
  local -r CACHE="$HOME/.atom/compile-cache"
  local -r INDEXDB="$HOME/.config/Atom/IndexedDB"

  if [[ -d ${STORAGE} ]] && [[ -d ${CACHE} ]] && [[ -d ${INDEXDB} ]] &&  os_get_current_users_name == "username" > /dev/null  ; then
    log_info "${magenta}Folders are present and ready to be purged${nocolor}\n"
    read -p "Would you like to purge [yes or no]: " answer
    for x in $answer
    do
      case "$x" in
        y|yes|Yes )
          rm -rfv ${STORAGE} ${CACHE} ${INDEXDB}
          if [[ `echo $?` == 0 ]]; then log_info "${green} Removal has been completed ${nocolor}\n"; else log_error "${red}Something went wrong${nocolor}\n" && exit 1; fi
          ;;
        no|n|No )
          log_warn "${yellow}Alright, you can remove them later ${nocolor}\n"
          exit 0
          ;;
        * )
          log_info "${red}Sorry, but please choose yes or no${nocolor}"
          main
          ;;
      esac
    done
  else
    log_warn "${yellow}Cannot find folders (maybe you have already purged them?) or you are not under `echo 'username'|tr a-z A-Z` user:
    - \$HOME folder is `echo $HOME`
    - username is $(os_get_current_users_name) ${nocolor}"
    exit 0
  fi
}

main
