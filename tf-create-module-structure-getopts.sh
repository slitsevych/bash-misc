#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commons/log.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commons/colors.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commons/checks.sh"

function create_module {
  module_name="${1}"
  pwd="${PWD}"

  if ! [[ -z $module_name ]] ; then
      log_info "${green}Values are set: creating empty `echo ${module_name}|tr a-z A-Z` module${nocolor}\n"
    if ! [[ -d $module_name ]] ; then
      mkdir $module_name && cd "$_"
      log_info "${green}Created folder for module ${module_name} in \"${pwd}/${module_name}${nocolor}\"\n" && sleep 1
      log_info "${green}Creating empty files (main, output, variables) for module ${module_name}${nocolor}\n"
      touch {main,output,variables}.tf
      operation_result "creating necessary files"
    else
      log_error "${red}Cannot create folder and files${nocolor}"
      exit 1
    fi
 else
   log_error "${red}Please indicate module name (e.g: vpc)${nocolor}\n"
   exit 1
 fi
}

function delete_module {
  module_name="${1}"
  pwd="${PWD}"

  if [[ -d "$pwd/$module_name" ]] ; then
    rm -rfv "$pwd/$module_name"
    operation_result "${green}deleting module ${module_name} in \"${pwd}/${module_name}${nocolor}\"\n"
  else
    log_warn "${yellow}There is no such module${nocolor}"
    exit 1
  fi
}

function usage {
  log_info "${magenta}Usage:${yellow} $0 [ -c|--create MODULE_NAME ] || [ -d|--delete MODULE_NAME ] || [ -h|--help ]${nocolor}"
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
