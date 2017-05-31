#!/bin/bash
set -e

source common/ui.sh
source common/utils.sh

info 'Installing extra packages and upgrading'

debug 'Bringing container up'
utils.lxc.start

# Sleep for a bit so that the container can get an IP
SECS=20
log "Sleeping for $SECS seconds..."
sleep $SECS

# TODO: Support for appending to this list from outside
PACKAGES=(vim-enhanced curl wget man-db bash-completion ca-certificates sudo openssh-server strace python-dnf dnf-plugins-core e2fsprogs net-tools bind-utils ethtool)

export LANG=C
utils.lxc.attach yum update -y
utils.lxc.attach yum install ${PACKAGES[*]} -y


MASK_TMP=${MASK_TMP:-0}

if [ $MASK_TMP -eq 1 ]; then
	# don't overmount /tmp with tmpfs: important for lxc-cachier
	utils.lxc.attach systemctl mask tmp.mount
fi
