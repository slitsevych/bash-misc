#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commons/log.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commons/colors.sh"

function status {
  if [[ `echo $?` == 0 ]]; then
    log_info "${green}${1}${nocolor}"
  else
    log_error "${red}Error executing operation${nocolor}"
    exit 1
  fi
}

function main {

  module_name="${1}"
  pwd="${PWD}"

  if ! [[ -z $module_name ]] ; then
      log_info "${nocolor}${green}Values are set: creating empty `echo ${module_name}|tr a-z A-Z` module${nocolor}\n"
    if ! [[ -d $module_name ]] ; then
      mkdir $module_name && cd "$_"
      log_info "${nocolor}${green}Created folder for module ${module_name} in \"${pwd}/${module_name}${nocolor}\"\n" && sleep 1
    else
      log_error "${red}Cannot create folder${nocolor}"
      exit 1
    fi

  log_info "${nocolor}${green}Creating empty files (main, output, variables) for module ${module_name}${nocolor}\n"
  touch {main,output,variables}.tf
  status "Created necessary files"

 else
   log_error "${nocolor}${red}Please indicate module name (e.g: vpc)${nocolor}\n"
   exit 1
 fi
}

main "$@"
