#!/bin/bash

AUTOLOGIN="${AUTOLOGIN:-false}"
SELINUX="${SELINUX:-false}"
RTAPPEND=""

if [ "$SELINUX" = "false" ]; then
  RTAPPEND="${RTAPPEND} selinux=0"
fi

if [ "$AUTOLOGIN" = "true" ]; then
  RTAPPEND="${RTAPPEND} flatcar.autologin=tty1"
fi

cat <<-EOF | sudo tee -a /usr/share/oem/grub.cfg
	set linux_append="\$linux_append${RTAPPEND}"
EOF
