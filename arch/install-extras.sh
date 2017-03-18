#!/bin/bash
set -e

source common/ui.sh
source common/utils.sh

info 'Installing extra packages and upgrading'

debug 'Bringing container up'
utils.lxc.start

# Sleep for a bit so that the container can get an IP
SECS=15
log "Sleeping for $SECS seconds..."
sleep $SECS

ANSIBLE=${ANSIBLE:-0}
CHEF=${CHEF:-0}
PUPPET=${PUPPET:-0}
SALT=${SALT:-0}
BABUSHKA=${BABUSHKA:-0}

PACKAGES=(vim openssh bash-completion ca-certificates sudo nfs-utils)

log "Installing additional packages: ${ADDPACKAGES}"
PACKAGES+=" ${ADDPACKAGES}"

[ $ANSIBLE = 1 ] && PACKAGES+=' ansible'
[ $PUPPET = 1 ] && PACKAGES+=' puppet'
[ $SALT = 1 ] && PACKAGES+=' salt'

utils.lxc.attach pacman --noconfirm -Sy
utils.lxc.attach pacman --noconfirm -S ${PACKAGES[*]}
utils.lxc.attach systemctl set-default -f multi-user.target
utils.lxc.attach systemctl enable sshd.service
utils.lxc.attach systemctl disable getty@lxc-tty5.service
utils.lxc.attach systemctl disable getty@lxc-tty6.service

[ $ANSIBLE = 0 ] && log "Skipping Ansible installation"
[ $PUPPET = 0 ] && log "Skipping Puppet installation"
[ $SALT = 0 ] && log "Skipping Salt installation"
if [ $CHEF = 1 ]; then
  warn "Chef can't be installed on Arch Linux, skipping"
else
  log "Skipping Chef installation"
fi

if [ $BABUSHKA = 1 ]; then
  if $(lxc-attach -n ${CONTAINER} -- which babushka &>/dev/null); then
    log "Babushka has been installed on container, skipping"
  else
    log "Installing Babushka"
    utils.lxc.attach sh -c "`curl https://babushka.me/up`"
  fi
else
  log "Skipping Babushka installation"
fi
