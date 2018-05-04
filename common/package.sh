#!/bin/bash
set -e

source common/ui.sh

# TODO: Create file with build date / time on container

info "Packaging '${CONTAINER}' to '${PACKAGE}'..."

debug 'Stopping container'
lxc-stop -n ${CONTAINER} &>/dev/null || true

if [ -f ${WORKING_DIR}/rootfs.tar.gz ]; then
  log "Removing previous rootfs tarball"
  rm -f ${WORKING_DIR}/rootfs.tar.gz
fi

log "Compressing container's rootfs"
pushd  $(dirname ${ROOTFS}) &>>${LOG}
  tar --numeric-owner --anchored --exclude=./rootfs/dev/log -czf \
      ${WORKING_DIR}/rootfs.tar.gz ./rootfs/*
popd &>>${LOG}

# Prepare package contents
log 'Preparing box package contents'
LXCVERSION=$(lxc --version | cut -c1-1)
if [ -f conf/${DISTRIBUTION}-${RELEASE}-${LXCVERSION} ]; then
  log "Using conf/${DISTRIBUTION}-${RELEASE}-${LXCVERSION} configuration file"
  cp conf/${DISTRIBUTION}-${RELEASE}-${LXCVERSION} ${WORKING_DIR}/lxc-config
elif [ -f conf/${DISTRIBUTION}-${RELEASE} ]; then
  log "Using conf/${DISTRIBUTION}-${RELEASE} configuration file"
  cp conf/${DISTRIBUTION}-${RELEASE} ${WORKING_DIR}/lxc-config
else
  log "Using conf/${DISTRIBUTION} configuration file"
  cp conf/${DISTRIBUTION} ${WORKING_DIR}/lxc-config
fi
cp conf/metadata.json ${WORKING_DIR}
sed -i "s/<TODAY>/${NOW}/" ${WORKING_DIR}/metadata.json

# Vagrant box!
log 'Packaging box'
TARBALL=$(readlink -f ${PACKAGE})
(cd ${WORKING_DIR} && tar -czf $TARBALL ./*)
