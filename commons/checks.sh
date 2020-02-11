#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/colors.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/log.sh"

function operation_result {
  local -r message="$1"

	if ! [[ `echo $?` == 0 ]] ; then
    log_error "${nocolor}${red}Found problem with ${green}${message}${nocolor}, exiting with error ${?}\n${nocolor}" && exit 1
	else
    log_info "${nocolor}${yellow}Everything went well with ${green}${message}${nocolor}\n${nocolor}"
	fi
}

# Returns a zero exit code if the given $username exists
function os_user_exists {
  local -r username="$1"
  id "$username" >/dev/null 2>&1
}

# Create an OS user whose name is $username
function os_create_user {
  local -r username="$1"

  if os_user_exists "$username"; then
    log_info "User $username already exists. Will not create again."
  else
    log_info "Creating user named $username"
    useradd "$username"
  fi
}

# Change the owner of $dir to $username
function os_change_dir_owner {
  local -r dir="$1"
  local -r username="$2"

  log_info "Changing ownership of $dir to $username"
  chown -R "$username:$username" "$dir"
}

# Returns true (0) if the current user is root or sudo and false (1) otherwise.
function os_user_is_root_or_sudo {
  [[ "$EUID" == 0 ]]
}

# Check that this script is running as root or sudo and exit with an error if it's not
function assert_uid_is_root_or_sudo {
  if ! os_user_is_root_or_sudo; then
    log_error "This script should be run using sudo or as the root user"
    exit 1
  fi
}

# Returns true (0) if this the given command/app is installed and on the PATH or false (1) otherwise.
function os_command_is_installed {
  local -r name="$1"
  command -v "$name" > /dev/null
}

# Get the username of the current OS user
function os_get_current_users_name {
  id -u -n
}

# Returns true (0) if the given file exists and is a file and false (1) otherwise
function file_exists {
  local -r file="$1"
  [[ -f "$file" ]]
}

# Returns true (0) if the given file exists contains the given text and false (1) otherwise. The given text is a
# regular expression.
function file_contains_text {
  local -r text="$1"
  local -r file="$2"
  grep -q "$text" "$file"
}

# Append the given text to the given file. The reason this method exists, as opposed to using bash's built-in append
# operator, is that this method uses sudo, which doesn't work natively with the built-in operator.
function file_append_text {
  local -r text="$1"
  local -r file="$2"

  echo -e "$text" | sudo tee -a "$file" > /dev/null
}


# Replace a line of text that matches the given regular expression in a file with the given replacement. Only works for
# single-line replacements. Note that this method uses sudo!
function file_replace_text {
  local -r original_text_regex="$1"
  local -r replacement_text="$2"
  local -r file="$3"

  local args=()
  args+=("-i")

  args+=("s|$original_text_regex|$replacement_text|")
  args+=("$file")

  sudo sed "${args[@]}" > /dev/null
}
