#!/bin/bash

nocolor='\033[0m'
red='\033[0;31m'
green='\033[0;32m'
orange='\033[0;33m'
magenta="\033[0;35m"


read -p "Enter current VM ID: " ORIGINAL_ID
read -p "Enter new VM ID: " NEW_ID

err() {
  echo -e "[$(date +'%Y-%m-%d--%H:%M:%S')]: $@" >&2
  exit 1
}

status()
{
  if [[ $1 -eq 0 ]]; then
    echo -e "${magenta}---All went well with ${2}---${nocolor}\n"
  else
    err "${red}---Error executing script---${nocolor}\n"
  fi
}

vm_status()
{
local STATUS=$(qm status ${ORIGINAL_ID} | grep "stopped" | wc -l)

echo -e "${magenta}---Checking VM status---${nocolor}"
if [[ ! -f /etc/pve/nodes/proxmox/qemu-server/${ORIGINAL_ID}.conf ]] ; then
   err "${red}VM does not exist${nocolor}"
elif [[ "$STATUS" -eq 1 ]] ; then
  echo -e "${green}VM exists and it is stopped, proceeding${nocolor}"
else
  echo -e "${orange}VM is running, stopping it${nocolor}"
  qm stop ${ORIGINAL_ID} ; sleep 6
fi

if [[ -f /etc/pve/nodes/proxmox/qemu-server/${NEW_ID}.conf ]] ; then
  err "${red}It looks that new ID is already in use, please choose another one${nocolor}"
else :
fi
}

main()
{
if ! [[ -z ${ORIGINAL_ID} ]] && ! [[ -z ${NEW_ID} ]] ; then
  cd /dev/pve && \
  echo -e "${magenta}---Moving disk ID---${nocolor}"
  mv -v {vm-${ORIGINAL_ID}-disk-1,vm-${NEW_ID}-disk-1}
    if [[ ! -z /dev/pve/vm-${NEW_ID}-disk-1 ]] ; then
      echo -e "${green}OK, disk ID has been changed${nocolor}\n"
    else
      err "${red}Disk ID has not been changed, please recheck${nocolor}\n"
    fi
  cd /etc/pve/nodes/proxmox/qemu-server && \
  echo -e "${magenta}---Moving .conf file---${nocolor}"
  mv -v {${ORIGINAL_ID}.conf,${NEW_ID}.conf}
    if [[ -f /etc/pve/nodes/proxmox/qemu-server/${NEW_ID}.conf ]] ; then
      echo -e "${green}OK, conf file has been changed, changing virtio device id:${nocolor}"
      sed -i 's/vm-'$ORIGINAL_ID'/vm-'$NEW_ID'/' ${NEW_ID}.conf
      cat ${NEW_ID}.conf | grep "vm-$NEW_ID"  && echo -e "${green}OK${nocolor}"
    else
      err "${red}Not OK, conf file hasn't been changed${nocolor}"
    fi
  if [[ $(qm status ${NEW_ID} | grep "status" | wc -l) -eq 1 ]]
  then
    echo -e "${magenta}\n---Seems like everything is good---${nocolor}\n"
  else
    err "${red}\n---Something went wrong, cannot check VM status---${nocolor}"\n
  fi

fi
}

post_action()
{
  read -p "Would you like to start VM? [yes|no] " start
  for answer in $start
  do
    case "$answer" in
      y|yes|Yes )
        qm start ${NEW_ID}
        echo -e "\n"
        return 0
        ;;
      no|n|No )
        echo -e "${orange}got it, later then!${nocolor}\n"
        return 0
        ;;
      * )
        echo -e "${red}please answer yes or no${nocolor}"
        post_action
        ;;
    esac
  done
}

script()
{
  vm_status
  status $? "reviewing VM status"
  main
  post_action
  status $? "making necessary changes"
}

script "$@"
