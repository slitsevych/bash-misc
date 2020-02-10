#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commons/bootstrap.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commons/log.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commons/colors.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commons/checks.sh"

function expect_to_root {
  local expect="/home/aim/root.exp"
  if [[ -r ${expect} ]]; then
    /usr/bin/expect -f ${expect}
  else
    log_error "${red}File ${expect} is either absent or does not have correct permissions${nocolor}"
  fi
}

function main {
  if os_user_is_root_or_sudo ; then
    log_warn "${red}Error: you are root, no need to take further actions${nocolor}"
    exit 1
  else expect_to_root
  fi
}

main
