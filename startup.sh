#!/bin/sh
# generate host SSH keys if they don't exist
if [ ! -f "/etc/ssh/ssh_host_rsa_key" ]; then
    ssh-keygen -A
fi

# start SSH server
/usr/sbin/sshd -D