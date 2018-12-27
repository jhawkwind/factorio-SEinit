#!/bin/bash

USERNAME="${1}"
TOKEN="${2}"
SERVER_NAME="${3}"
SERVER_DESCRIPTION="${4}"
INIT_DIR="/opt/factorio-init"
FACTORIO_DIR="/opt/factorio"
GLIBC_DIR="/opt/glibc-2.18"

# Presume it is done, since this file is on the system.
# yum -y install git
# git clone --recurse-submodules -b experimental https://github.com/jhawkwind/factorio-SEinit ${INIT_DIR}
# chmod 755 ${INIT_DIR}/unattended-centos-build.sh
# chcon -u unconfined_u -r unconfined_r -t unconfined_t ${INIT_DIR}/unattended-centos-build.sh

# Pull sources
umask 0022
yum -y install git wget python-requests glibc-devel glibc gcc make gcc-c++ autoconf texinfo libselinux-devel audit-libs-devel libcap-devel policycoreutils-python policycoreutils-devel setools-console rpm-build

# Build GLIBC
cd ${INIT_DIR}/glibc
git apply ../patches/test-installation.pl.patch
mkdir ./glibc-build
cd ./glibc-build
../configure --prefix="${GLIBC_DIR}" --with-selinux
useradd -c "Factorio Server account" -d ${FACTORIO_DIR} -M -s /usr/sbin/nologin -r factorio
make
make install

cp /opt/factorio-init/config.example ${INIT_DIR}/config
sed -i -e 's/SELINUX=0/SELINUX=1/g' ${INIT_DIR}/config
sed -i -e 's/WAIT_PINGPONG=0/WAIT_PINGPONG=1/g' ${INIT_DIR}/config
sed -i -e "s/FACTORIO_PATH=.*/FACTORIO_PATH=${FACTORIO_DIR}/g" ${INIT_DIR}/config
sed -i -e "s/ALT_GLIBC_DIR=.*/ALT_GLIBC_DIR=${GLIBC_DIR}/g" ${INIT_DIR}/config
sed -i -e 's/ALT_GLIBC=0/ALT_GLIBC=1/g' ${INIT_DIR}/config
sed -i -e "s/UPDATE_USERNAME=you/UPDATE_USERNAME=${USERNAME}/g" ${INIT_DIR}/config
sed -i -e "s/UPDATE_TOKEN=yourtoken/UPDATE_TOKEN=${TOKEN}/g" ${INIT_DIR}/config

chmod 640 ${INIT_DIR}/config
chown root:factorio ${INIT_DIR}/config

find ${INIT_DIR} -type d -exec chmod 755 {} \;
find ${INIT_DIR} -type f -file chmod 644 {} \;
chmod 755 ${INIT_DIR}/factorio
chmod 755 ${INIT_DIR}/selinux/compile.sh
chmod 755 ${INIT_DIR}/selinux/factorio/factorio.sh
chmod 755 ${INIT_DIR}/selinux/factorio-init/factorio-init.sh

/opt/factorio-init/selinux/compile.sh
semodule --disable_dontaudit --build

restorecon -R -F -v /opt/factorio-init
/opt/factorio-init/factorio install

cp /opt/factorio/data/server-settings.example.json /opt/factorio/data/server-settings.json
chown factorio:factorio /opt/factorio/data/server-settings.json
restorecon -F -v /opt/factorio/data/server-settings.json
sed -i -e 's/"public": true/"public": false/g' /opt/factorio/data/server-settings.json
sed -i -e "s/\"username\": \"\"/\"username\": \"${USERNAME}\"/g" /opt/factorio/data/server-settings.json
sed -i -e "s/\"token\": \"\"/\"token\": \"${TOKEN}\"/g" /opt/factorio/data/server-settings.json
sed -i -e "s/\"admins\": \[\]/\"admins\": [ \"${USERNAME}\" ]/g" /opt/factorio/data/server-settings.json
sed -i -e "s/\"name\": \"[^\\\"]*\"/\"name\": \"${SERVER_NAME}\"/g" /opt/factorio/data/server-settings.json
sed -i -e "s/\"description\": \"[^\\\"]*\"/\"description\": \"${SERVER_DESCRIPTION}\"/g" /opt/factorio/data/server-settings.json

cp ${INIT_DIR}/factorio.service.example /etc/systemd/system/factorio.service
systemctl daemon-reload
