<p>
<img width="400" align='center'src="https://habrastorage.org/files/803/892/bfe/803892bfe548499aa763df324d40fd01.png" width="100px">
</p>

A collection of various bash scripts for certain occasions:

&#9881; **atom-ide-clean-cache.sh** - clears all tmp data and allows Atom to start fresh; for me it helps to fix the post-update issues when Atom stops saving tabs and each time opens with empty screen

&#9881; **cpu-memory-checks.sh** - basic linux memory/cpu usage checks against defined threshold

&#9881; **logrotate-webservers-daily.sh** - install linux daily logrotation on nginx/phpfpm webserver (debian/redhat) with ability to send logs to s3

&#9881; **proxmox-change-vmid.sh** - script changing VM ID's on Proxmox VE

&#9881; **send-logs-on-termination-to-s3.sh** - archive all existing logs before instance shutdown/termination and send them to s3

&#9881; **snap-remove-old-packages.sh** - script removing disabled/outdated snap packages: either one by one or all at once

&#9881; **ssh-login-aws.sh** - script facilitating ssh connections to EC2 servers in certain regions and with selected AMI/OS

&#9881; **sudo-as-root-without-pass.sh + root.exp** - script automatically performing `sudo su` command with password inserted by `expect` command

&#9881; **tf-create-module-structure-getopts.sh** - script creating or deleting directory for Terraform module with basic files (main, outputs, variables)

&#9881; **tf-create-module-structure.sh** - the same script as below but without additional getopts functionality

# Notes:

**`/commons`** folder contains useful predefined functions which I've borrowed from the following repo: https://github.com/gruntwork-io/bash-commons

When writing bash scripts I tend to comply with the following style guides/cheatsheets:
* https://google.github.io/styleguide/shell.xml
* https://devhints.io/bash
