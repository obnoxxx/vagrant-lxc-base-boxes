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

PACKAGES=(vim curl wget man-db openssh-server bash-completion ca-certificates sudo)

log "Installing additional packages: ${ADDPACKAGES}"
PACKAGES+=" ${ADDPACKAGES}"

if [ $DISTRIBUTION = 'ubuntu' ]; then
  PACKAGES+=' software-properties-common'
fi
if [ $RELEASE != 'raring' ] && [ $RELEASE != 'saucy' ] && [ $RELEASE != 'trusty' ] && [ $RELEASE != 'wily' ] && [ $RELEASE != 'bionic' ] ; then
  PACKAGES+=' nfs-common'
fi
if [ $RELEASE != 'stretch' ] && [ $RELEASE != 'bionic' ]; then
  PACKAGES+=' python-software-properties'
fi
utils.lxc.attach apt-get update
utils.lxc.attach apt-get install ${PACKAGES[*]} -y --force-yes
utils.lxc.attach apt-get upgrade -y --force-yes

ANSIBLE=${ANSIBLE:-0}
CHEF=${CHEF:-0}
PUPPET=${PUPPET:-0}
SALT=${SALT:-0}
BABUSHKA=${BABUSHKA:-0}

if [ $DISTRIBUTION = 'debian' ]; then
  # Enable bash-completion
  sed -e '/^#if ! shopt -oq posix; then/,/^#fi/ s/^#\(.*\)/\1/g' \
    -i ${ROOTFS}/etc/bash.bashrc
fi

if [ $ANSIBLE = 1 ]; then
  if $(lxc-attach -n ${CONTAINER} -- which ansible &>/dev/null); then
    log "Ansible has been installed on container, skipping"
  else
    info "Installing Ansible"
    cp debian/install-ansible.sh ${ROOTFS}/tmp/ && chmod +x ${ROOTFS}/tmp/install-ansible.sh
    utils.lxc.attach /tmp/install-ansible.sh &>>${LOG}
  fi
else
  log "Skipping Ansible installation"
fi

if [ $CHEF = 1 ]; then
  if $(lxc-attach -n ${CONTAINER} -- which chef-solo &>/dev/null); then
    log "Chef has been installed on container, skipping"
  else
    log "Installing Chef"
    cat > ${ROOTFS}/tmp/install-chef.sh << EOF
#!/bin/sh
curl -L https://www.opscode.com/chef/install.sh -k | sudo bash
EOF
    chmod +x ${ROOTFS}/tmp/install-chef.sh
    utils.lxc.attach /tmp/install-chef.sh
  fi
else
  log "Skipping Chef installation"
fi

if [ $PUPPET = 1 ]; then
  if $(lxc-attach -n ${CONTAINER} -- which puppet &>/dev/null); then
    log "Puppet has been installed on container, skipping"
  elif [ ${RELEASE} = 'sid' ]; then
    warn "Puppet can't be installed on Debian sid, skipping"
  else
    log "Installing Puppet"
    wget http://apt.puppetlabs.com/puppetlabs-release-${RELEASE}.deb -O "${ROOTFS}/tmp/puppetlabs-release-stable.deb" &>>${LOG}
    utils.lxc.attach dpkg -i "/tmp/puppetlabs-release-stable.deb"
    utils.lxc.attach apt-get update
    utils.lxc.attach apt-get install puppet -y --force-yes
  fi
else
  log "Skipping Puppet installation"
fi

if [ $SALT = 1 ]; then
  if $(lxc-attach -n ${CONTAINER} -- which salt-minion &>/dev/null); then
    log "Salt has been installed on container, skipping"
  elif [ ${RELEASE} = 'raring' ]; then
    warn "Salt can't be installed on Ubuntu Raring 13.04, skipping"
  else
    if [ $DISTRIBUTION = 'ubuntu' ]; then
      if [ $RELEASE = 'precise' ] || [ $RELEASE = 'trusty' ] || [ $RELEASE = 'xenial' ] || [ $RELEASE = 'bionic' ] ; then
        # For LTS releases we use packages from repo.saltstack.com
        if [ $RELEASE = 'precise' ]; then
          SALT_SOURCE_1="deb http://repo.saltstack.com/apt/ubuntu/12.04/amd64/latest precise main"
          SALT_GPG_KEY="https://repo.saltstack.com/apt/ubuntu/12.04/amd64/latest/SALTSTACK-GPG-KEY.pub"
        elif [ $RELEASE = 'trusty' ]; then
          SALT_SOURCE_1="deb http://repo.saltstack.com/apt/ubuntu/14.04/amd64/latest trusty main"
          SALT_GPG_KEY="https://repo.saltstack.com/apt/ubuntu/14.04/amd64/latest/SALTSTACK-GPG-KEY.pub"
        elif [ $RELEASE = 'xenial' ]; then
          SALT_SOURCE_1="deb http://repo.saltstack.com/apt/ubuntu/16.04/amd64/latest xenial main"
          SALT_GPG_KEY="https://repo.saltstack.com/apt/ubuntu/16.04/amd64/latest/SALTSTACK-GPG-KEY.pub"
        elif [ $RELEASE = 'bionic' ]; then
          SALT_SOURCE_1="http://ru.archive.ubuntu.com/ubuntu/ bionic main"
          SALT_GPG_KEY="http://ru.archive.ubuntu.com/ubuntu/dists/bionic/Release.gpg"
        fi
        echo $SALT_SOURCE_1 > ${ROOTFS}/etc/apt/sources.list.d/saltstack.list

        utils.lxc.attach wget -q -O /tmp/salt.key $SALT_GPG_KEY
        utils.lxc.attach apt-key add /tmp/salt.key
      elif [ $RELEASE = 'quantal' ] || [ $RELEASE = 'saucy' ] ; then
        utils.lxc.attach add-apt-repository -y ppa:saltstack/salt
      fi
      # For Utopic, Vivid and Wily releases use system packages
    else # DEBIAN
      if [ $RELEASE == "squeeze" ]; then
        SALT_SOURCE_1="deb http://debian.saltstack.com/debian squeeze-saltstack main"
        SALT_SOURCE_2="deb http://backports.debian.org/debian-backports squeeze-backports main contrib non-free"
      elif [ $RELEASE == "wheezy" ]; then
        SALT_SOURCE_1="deb http://repo.saltstack.com/apt/debian/7/amd64/latest wheezy main"
      elif [ $RELEASE == "jessie" ]; then
        SALT_SOURCE_1="deb http://repo.saltstack.com/apt/debian/8/amd64/latest jessie main"
      else
        SALT_SOURCE_1="deb http://debian.saltstack.com/debian unstable main"
      fi
      echo $SALT_SOURCE_1 > ${ROOTFS}/etc/apt/sources.list.d/saltstack.list
      echo $SALT_SOURCE_2 >> ${ROOTFS}/etc/apt/sources.list.d/saltstack.list

      utils.lxc.attach wget -q -O /tmp/salt.key "https://repo.saltstack.com/apt/debian/8/amd64/latest/SALTSTACK-GPG-KEY.pub"
      utils.lxc.attach apt-key add /tmp/salt.key
    fi
    utils.lxc.attach apt-get update
    utils.lxc.attach apt-get install salt-minion -y --force-yes
  fi
else
  log "Skipping Salt installation"
fi

if [ $BABUSHKA = 1 ]; then
  if $(lxc-attach -n ${CONTAINER} -- which babushka &>/dev/null); then
    log "Babushka has been installed on container, skipping"
  elif [ ${RELEASE} = 'trusty' ]; then
    warn "Babushka can't be installed on Ubuntu Trusty 14.04, skipping"
  else
    log "Installing Babushka"
    cat > $ROOTFS/tmp/install-babushka.sh << EOF
#!/bin/sh
curl https://babushka.me/up | sudo bash
EOF
    chmod +x $ROOTFS/tmp/install-babushka.sh
    utils.lxc.attach /tmp/install-babushka.sh
  fi
else
  log "Skipping Babushka installation"
fi
