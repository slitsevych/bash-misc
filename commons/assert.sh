#!/usr/bin/env bash

# Check that the given binary is available on the PATH. If it's not, exit with an error.
function assert_is_installed {
  local -r name="$1"

  if ! os_command_is_installed "$name"; then
    log_error "The command '$name' is required by this script but is not installed or in the system's PATH."
    exit 1
  fi
}

# Check that the value of the given arg is not empty. If it is, exit with an error.
function assert_not_empty {
  local -r arg_name="$1"
  local -r arg_value="$2"
  local -r reason="$3"

  if [[ -z "$arg_value" ]]; then
    log_error "The value for '$arg_name' cannot be empty. $reason"
    exit 1
  fi
}

# Check that the value of the given arg is empty. If it isn't, exit with an error.
function assert_empty {
  local -r arg_name="$1"
  local -r arg_value="$2"
  local -r reason="$3"

  if [[ ! -z "$arg_value" ]]; then
    log_error "The value for '$arg_name' must be empty. $reason"
    exit 1
  fi
}
