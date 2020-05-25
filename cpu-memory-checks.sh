#!/bin/bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commons/bootstrap.sh" && set +e
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commons/log.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commons/colors.sh"

function memory_check {
    local -r avail_ram=$(awk -v low=$(grep low /proc/zoneinfo | awk '{k+=$2}END{print k}') '{a[$1]=$2}END{print a["MemFree:"]+a["Active(file):"]+a["Inactive(file):"]+a["SReclaimable:"]-(12*low);}' /proc/meminfo)
    local -r total_ram=$(cat /proc/meminfo | grep 'MemTotal' | awk '{print $2}')
    local -r mem_percent_available=$(( $avail_ram * 100 / $total_ram ))
    local -r mem_percent_used=$(( ($avail_ram * 100 / $total_ram - 100) * -1 ))
    local -r threshold=70

    if [ $mem_percent -gt $threshold ]; then
        log_error "${red}Memory_usage: ${mem_percent_used}% exceeds ${threshold}%; Available memory is only ${mem_percent_available}%; performing restart${nocolor}"
        #some action here
    else
        log_info "${green}Memory usage: ${mem_percent_used}% is below threshold ${threshold}%; Available memory: ${mem_percent_available}%${nocolor}"
    fi
}

function cpu_check {
    local -r cores=$(lscpu | egrep -w -m1 "CPU\(s\)" | awk {'print$2'})
    local -r load_avg=$(cat /proc/loadavg | awk '{print$1}')

    for i in {1..2}
    do
      for load in ${load_avg}; do bc <<< "scale=2; $load/$cores * 100" | cut -d . -f 1 >> /tmp/outputfile ; done
      sleep 60
    done

    local -r load_first=$(cat /tmp/outputfile | awk NR==1)
    local -r load_second=$(cat /tmp/outputfile | awk NR==2)
    local -r cpu_percent=$load_second

    if [ "$(($load_first))" -gt 90 ] && [ "$(($load_second))" -gt 90 ] ; then
        log_error "${red}CPU usage: ${cpu_percent}%  exceeds 90% for already two minutes, restarting service${nocolor}"
        #some action here
        cat /dev/null > /tmp/outputfile
    else
        log_info "${green}CPU usage: ${cpu_percent}% is less than 90%, seems to be stable${nocolor}"
        cat /dev/null > /tmp/outputfile
    fi
}

function main {
    memory_check
    cpu_check
}

main