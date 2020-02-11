#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commons/bootstrap.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commons/log.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commons/colors.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commons/assert.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commons/checks.sh"

function check_args {
   user="${1:-default}"
   address="${2:-default}"
   key="${3:-default}"

  if [[ "$#" == 3 ]] && [[ "$user" != "default"  ]] && [[ "$address" != "default" ]] && [[ "$key" != "default" ]]; then
		return 0
	else
		log_error "${red}Arguments have not been set, exiting\n${nocolor}"
    return 1
	fi
}

function check_validity {
  local -r host=$address
  if [[ "$host" =~ ^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$ ]] || [[ "$host" =~ ^(.*)\.amazonaws\.com$ ]]; then
    return 0
  else
    log_error "${red}Invalid IP address or hostname, please enter EC2 IPv4 Public IP or EC2 Public DNS\n${nocolor}"
    return 1
  fi
}

function user_aws {
	for x in $user
	do
		case "$x" in
			u|ubuntu|ub )
				user=ubuntu
				;;
			d|debian|deb )
				user=admin
				;;
			c|centos|cent )
				user=centos
				;;
			a|amazon|ec2 )
				user=ec2-user
				;;
			*)
				log_warn "${red}Invalid operating system input, please choose between:
- for Ubuntu: u|ubuntu
- for Centos: c|centos
- for Debian: d|debian
- for Amazon Linux: a|amazon|ec2\n${nocolor}"
				return 1
				;;
		esac
	done
}

function key_aws {
  local -r key_us_east="~/path/to/key"
  local -r key_us_west="~/path/to/key"
  local -r key_europe="~/path/to/key"

	for k in $key
	do
		case "$k" in
		  v|V|virg|Virg|useast|use|ohio|o|O )
			  key=$key_us_east
			  region=us-east
			  ;;
		  w|W|oregon|uswest|usw|cali )
		    key=$key_us_west
			  region=us-west
			  ;;
		  e|E|fra|europe|eur )
			  key=$key_europe
			  region=eu-central
			  ;;
		  *)
			  log_warn "${red}Invalid region input, please choose:
- for Us-East: [vV][virgVirg][useast][use][ohio][oO]
- for Us-West: [wW][oregon][uswest][usw][cali]
- for Eu-Central: [eE][fra][europe][eur]\n${nocolor}"
				return 1
			  ;;
	  esac
	done
}

function ssh_aws {
  local -r option="StrictHostKeyChecking=no"
	log_info "${yellow}Connecting to EC2 instance${nocolor} ${blue}'"$address"'${nocolor} in ${magenta}'"$region"'${nocolor} with user ${green}'"$user"'${nocolor}\n"
	ssh -i ${key} -o "${option}" ${user}@${address}
}

function main {

  echo -e "${magenta}======================="
  echo -e "|Checking Dependencies|"
  echo -e "=======================\n${nocolor}"

  check_args "$@"
  operation_result "checking dependencies"

  check_validity
  operation_result "checking validity of host's IP address or hostname"

  echo -e "${magenta}================================"
  echo -e "|Verifying user and key location|"
  echo -e "================================\n${nocolor}"

  user_aws
  operation_result "defining operating system"

  key_aws
  operation_result "choosing region"

  echo -e "${magenta}============"
  echo -e "|Logging in|"
  echo -e "============\n${nocolor}"

  ssh_aws
}

main "$@"
