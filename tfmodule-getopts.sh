#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commons/log.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commons/colors.sh"

function status {
  if [[ `echo $?` == 0 ]]; then
    log_info "${green}${1}${nocolor}"
    exit 0
  else
    log_error "${red}Error executing operation${nocolor}"
    exit 1
  fi
}

function create_module {

  module_name="${1}"
  pwd="${PWD}"

  if ! [[ -z $module_name ]] ; then
      log_info "${nocolor}${green}Values are set: creating empty `echo ${module_name}|tr a-z A-Z` module${nocolor}\n"
    if ! [[ -d $module_name ]] ; then
      mkdir $module_name && cd "$_"
      log_info "${nocolor}${green}Created folder for module ${module_name} in \"${pwd}/${module_name}${nocolor}\"\n" && sleep 1
      log_info "${nocolor}${green}Creating empty files (main, output, variables) for module ${module_name}${nocolor}\n"
      touch {main,output,variables}.tf
      status "Created necessary files"
    else
      log_error "${red}Cannot create folder and files${nocolor}"
      exit 1
    fi
 else
   log_error "${nocolor}${red}Please indicate module name (e.g: vpc)${nocolor}\n"
   exit 1
 fi
}

function delete_module {

  module_name="${1}"
  pwd="${PWD}"

  if [[ -d "$pwd/$module_name" ]] ; then
    rm -rfv "$pwd/$module_name"
    status "${nocolor}${green}Deleted module ${module_name} in \"${pwd}/${module_name}${nocolor}\"\n"
  else
    log_warn "${yellow}There is no such module${nocolor}"
    exit 1
  fi
}

function usage {
  log_info "${magenta}Usage:${nocolor}${yellow} $0 [ -c|--create MODULE_NAME ] || [ -d|--delete MODULE_NAME ] || [ -h|--help ]${nocolor}"
  exit 1;
}

function main {

  if [[ -z $* ]] ; then
	   log_error "${red}No options found!${nocolor}"
	   exit 1
  fi

  # Option strings
  SHORT=c:d:h
  LONG=create:,delete:,help

  # read the options
  OPTS=$(getopt --options $SHORT --long $LONG --name "$0" -- "$@")

  if [ $? != 0 ] ; then
    log_error "${red}Incorrect options or argument is not set${nocolor}"
    usage
  fi

  eval set -- "$OPTS"

  # extract options and their arguments into variables.
  while true ; do
    case "$1" in
      -c | --create )
        shift
        create_module "$1"
        ;;
      -d | --delete )
        shift
        delete_module "$1"
        ;;
      -h | --help )
        shift
        usage
        ;;
      * )
        exit 1
        ;;
    esac
  done
}

main "$@"
