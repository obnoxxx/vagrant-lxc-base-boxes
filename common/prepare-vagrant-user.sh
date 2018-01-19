#!/bin/bash
set -e

source common/ui.sh

USERNAME=${VAGRANT_USER:-vagrant}

export VAGRANT_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== $USERNAME insecure public key"

info "Preparing vagrant machine user $USERNAME..."

# Create vagrant user
if $(grep -q ${USERNAME} ${ROOTFS}/etc/shadow); then
  log 'Skipping vagrant user creation'
elif [ $(grep -q 'ubuntu' ${ROOTFS}/etc/shadow) ] && [ ${USERNAME} != 'ubuntu' ]; then
  debug "$USERNAME user does not exist, renaming ubuntu user..."
  mv ${ROOTFS}/home/{ubuntu,${USERNAME}}
  chroot ${ROOTFS} usermod -l ${USERNAME} -d /home/${USERNAME} ubuntu &>> ${LOG}
  chroot ${ROOTFS} groupmod -n ${USERNAME} ubuntu &>> ${LOG}
  echo -n "$USERNAME:$USERNAME" | chroot ${ROOTFS} chpasswd
  log "Renamed ubuntu user to $USERNAME and changed password."
elif [ ${DISTRIBUTION} = 'centos' -o ${DISTRIBUTION} = 'fedora' ]; then
  debug "Creating $USERNAME user..."
  chroot ${ROOTFS} useradd --create-home -s /bin/bash -u 1000 ${USERNAME} &>> ${LOG}
  echo -n "$USERNAME:$USERNAME" | chroot ${ROOTFS} chpasswd
  sed -i 's/^Defaults\s\+requiretty/# Defaults requiretty/' $ROOTFS/etc/sudoers
  if [ ${RELEASE} -eq 6 ]; then
    info 'Disabling password aging for root...'
    # disable password aging (required on Centos 6)
    # pretend that password was changed today (won't fail during provisioning)
    chroot ${ROOTFS} chage -I -1 -m 0 -M 99999 -E -1 -d `date +%Y-%m-%d` root
  fi
else
  debug "Creating $USERNAME user..."
  chroot ${ROOTFS} useradd --create-home -s /bin/bash ${USERNAME} &>> ${LOG}
  chroot ${ROOTFS} adduser ${USERNAME} sudo &>> ${LOG}
  echo -n "$USERNAME:$USERNAME" | chroot ${ROOTFS} chpasswd
fi

# Configure SSH access
if [ -d ${ROOTFS}/home/${USERNAME}/.ssh ]; then
  log "Skipping ${USERNAME} SSH credentials configuration"
else
  debug 'SSH key has not been set'
  mkdir -p ${ROOTFS}/home/${USERNAME}/.ssh
  echo $VAGRANT_KEY > ${ROOTFS}/home/${USERNAME}/.ssh/authorized_keys
  chroot ${ROOTFS} chown -R ${USERNAME}: /home/${USERNAME}/.ssh
  log "SSH credentials configured for the ${USERNAME} user."
fi

# Enable passwordless sudo for the ${USERNAME} user
if [ -f ${ROOTFS}/etc/sudoers.d/${USERNAME} ]; then
  log 'Skipping sudoers file creation.'
else
  debug 'Sudoers file was not found'
  echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > ${ROOTFS}/etc/sudoers.d/${USERNAME}
  chmod 0440 ${ROOTFS}/etc/sudoers.d/${USERNAME}
  log 'Sudoers file created.'
fi
