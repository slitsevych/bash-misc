# bash-misc
A collection of miscellaneous bash scripts created by me for certain occasions:
* atom-clean.sh - clears all tmp data and allows Atom to start fresh; for me it helps to fix the post-update issues when Atom stops saving tabs and each time opens with empty screen
* login_aws.sh - script facilitating ssh connections to EC2 servers in certain regions and with selected AMI/OS
* proxmox-change-vmid.sh - script changing VM ID's on Proxmox VE
* root.sh + root.exp - script automatically performing `sudo su` command with password inserted by `expect` command
* snap-remove.sh - script removing disabled/outdated snap packages: either one by one or all at once
* tfmodule-getopts.sh - script creating or deleting directory for Terraform module with basic files (main, outputs, variables)
* tfmodule.sh - the same script as below but without additional getopts functionality

`/commons` folder contains useful predefined functions which I've borrowed from the following repo: https://github.com/gruntwork-io/bash-commons

When writing bash scripts I tend to comply with the following style guides/cheatsheets:
* https://google.github.io/styleguide/shell.xml
* https://devhints.io/bash
