#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commons/bootstrap.sh" && set +e
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commons/log.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commons/colors.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commons/assert.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commons/checks.sh"

function usage {
  log_info "${magenta}Usage:${yellow} ./${0##*/} \$1(ssh user) \$2(host address||server ip) \$3(region) ${nocolor}\n"
}

function verify_args {
   ssh_user="${1:-default}"
   address="${2:-default}"
   region="${3:-default}"

  if [[ "$#" == 3 ]] && [[ "$ssh_user" != "default"  ]] && [[ "$address" != "default" ]] && [[ "$region" != "default" ]]; then
		return 0
	else
		log_error "${red}Arguments have not been set, check usage${nocolor}\n" && usage
    return 1
	fi
}

function is_address_valid {
  local -r host=$address
  if [[ "$host" =~ ^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$ ]] || [[ "$host" =~ ^(.*)\.amazonaws\.com$ ]]; then
    return 0
  else
    log_error "${red}Invalid IP address or hostname, please enter EC2 IPv4 Public IP or EC2 Public DNS\n${nocolor}"
    return 1
  fi
}

function assert_ssh_user {
	for user in $ssh_user
	do
		case "$user" in
			u|ubuntu|ub )
				ssh_user=ubuntu
				;;
			d|debian|deb )
				ssh_user=admin
				;;
			c|centos|cent )
				ssh_user=centos
				;;
			a|amazon|ec2 )
				ssh_user=ec2-user
				;;
			*)
      log_warn "${nocolor}${red}Invalid operating system input, please choose between:
- for Ubuntu: u|ubuntu|ub
- for Centos: c|centos|cent
- for Debian: d|debian|deb
- for Amazon Linux: a|amazon|ec2 \n${nocolor}"
				return 1
				;;
		esac
	done
}

function assert_region_key {
  local -r key_us_east="~/path/to/key"
  local -r key_us_west="~/path/to/key"
  local -r key_europe="~/path/to/key"

	for key in $region
	do
		case "$key" in
		  v|virg|virginia|us-east|useast|us-east-1|us-east-2|east|o|oh|ohio )
			  region_key=$key_us_east
			  aws_region=us-east
			  ;;
		  w|west|ore|oregon|us-west|uswest|us-west-1|us-west-2|cali|california )
		    region_key=$key_us_west
			  aws_region=us-west
			  ;;
		  e|eur|europe|germany|frankfurt|fra|eucentral|eu-central-1 )
			  region_key=$key_europe
			  aws_region=eu-central
			  ;;
		  *)
        log_warn "${nocolor}${red}Invalid region input, please choose:
- for Us-East: v|virg|virginia|us-east|useast|us-east-1|us-east-2|east|o|oh|ohio
- for Us-West: w|west|ore|oregon|us-west|uswest|us-west-1|us-west-2|cali|california
- for Eu-Central: e|eur|europe|germany|frankfurt|fra|eucentral|eu-central-1 \n${nocolor}"
        return 1
			  ;;
	  esac
	done
}

function connect_ssh {
  local -r option="StrictHostKeyChecking=no"
	log_info "${yellow}Connecting to EC2 instance${nocolor} ${blue}'"$address"'${nocolor} in ${magenta}'"$aws_region"'${nocolor} with user ${green}'"$ssh_user"'${nocolor}\n"
	ssh -i ${region_key} -o "${option}" ${ssh_user}@${address}
}

function main {

  echo -e "${magenta}"
  echo -e "========================================="
  echo -e "|Checking arguments & validating address|"
  echo -e "========================================="
  echo -e "${nocolor}\n"

  verify_args "$@"
  operation_result "checking provided arguments"

  is_address_valid
  operation_result "validating provided host's server IP or hostname"

  echo -e "${magenta}"
  echo -e "======================="
  echo -e "|Verifying OS & region|"
  echo -e "======================="
  echo -e "${nocolor}\n"

  assert_ssh_user
  operation_result "defining default ssh_user of OS"

  assert_region_key
  operation_result "determining key pair for region"

  echo -e "${magenta}"
  echo -e "==================="
  echo -e "|Connecting via SSH|"
  echo -e "==================="
  echo -e "${nocolor}\n"

  connect_ssh
}

main "$@"
