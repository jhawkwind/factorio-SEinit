#!/bin/bash

# This unattended script is to make it quick using as many "defaults" as possible.

USERNAME="${1}"
TOKEN="${2}"
SERVER_NAME="${3}"
SERVER_DESCRIPTION="${4}"
INIT_DIR="/opt/factorio-init"
FACTORIO_DIR="/opt/factorio"
GLIBC_DIR="/opt/glibc-2.18"

# Presume it is done, since this file is on the system.
# umask 0022;
# yum -y install git; git clone --recurse-submodules -b experimental https://github.com/jhawkwind/factorio-SEinit ${INIT_DIR}; chown -R root:root ${INIT_DIR}
# semanage permissive -a unconfined_t; # This is safer.
# chcon -R -u unconfined_u -r unconfined_r -t home_t -v ${INIT_DIR}; chcon -R -u unconfined_u -r unconfined_r -t home_bin_t -v ${INIT_DIR}/unattended-centos-build.sh;
# chown -R root:root ${INIT_DIR}/
# chmod 755 ${INIT_DIR}/
# chmod 755 ${INIT_DIR}/unattended-centos-build.sh
# semanage permissive -d unconfined_t; # Return configuration.


# Pull prerequsities
umask 0022
yum history > yum-history.before
yum -y install git wget python-requests glibc-devel glibc gcc make gcc-c++ autoconf texinfo libselinux-devel audit-libs-devel libcap-devel policycoreutils-python policycoreutils-devel setools-console rpm-build
yum history > yum-history.after
diff yum-history.before yum-history.after | tail -n 1 | sed -n -E 's/^[^\|0-9]*([0-9]+).*/\1/p' > yum-history.id
transaction_id="$(cat yum-history.id)";
rollback_id="$(( transaction_id - 1 ))";

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

# These permissions matter.
chown -R root:root  ${INIT_DIR}; # Make sure expected defaults.
find ${INIT_DIR} -type d -exec chmod 755 {} \; # Make sure expected defaults.
find ${INIT_DIR} -type f -file chmod 644 {} \; # Make sure expected defaults.
# Now change owners where access needs to be shared with the factorio user.
chown root:factorio ${INIT_DIR};
chown root:factorio ${INIT_DIR}/config;
chown root:factorio ${INIT_DIR}/factorio;
chown root:factorio ${INIT_DIR}/factorio-updater;
# Now change the permissions to protect custom areas.
chmod 755 ${INIT_DIR}/factorio;
chmod 755 ${INIT_DIR}/factorio/factorio-updater/update_factorio.py;
chmod 755 ${INIT_DIR}/selinux/compile.sh;
chmod 755 ${INIT_DIR}/selinux/factorio/factorio.sh;
chmod 755 ${INIT_DIR}/selinux/factorio-init/factorio-init.sh;
chmod 640 ${INIT_DIR}/config;
chmod 750 ${INIT_DIR}/selinux;
chmod 750 ${INIT_DIR}/patches;
chmod 750 ${INIT_DIR}/glibc;

${INIT_DIR}/selinux/compile.sh

# The compile script is dumb with the restorecon, make sure it did it to the correct place.
restorecon -R -F -v ${INIT_DIR}
restorecon -R -F -v ${GLIBC_DIR}
restorecon -R -F -v ${FACTORIO_DIR}

semodule --disable_dontaudit --build # Debugging only, noisy.
${INIT_DIR}/factorio install

cp ${FACTORIO_DIR}/data/server-settings.example.json ${FACTORIO_DIR}/data/server-settings.json
chown factorio:factorio ${FACTORIO_DIR}/data/server-settings.json
restorecon -F -v ${FACTORIO_DIR}/data/server-settings.json
sed -i -e 's/"public": true/"public": false/g' ${FACTORIO_DIR}/data/server-settings.json
sed -i -e "s/\"username\": \"\"/\"username\": \"${USERNAME}\"/g" ${FACTORIO_DIR}/data/server-settings.json
sed -i -e "s/\"token\": \"\"/\"token\": \"${TOKEN}\"/g" ${FACTORIO_DIR}/data/server-settings.json
sed -i -e "s/\"admins\": \[\]/\"admins\": [ \"${USERNAME}\" ]/g" ${FACTORIO_DIR}/data/server-settings.json
sed -i -e "s/\"name\": \"[^\\\"]*\"/\"name\": \"${SERVER_NAME}\"/g" ${FACTORIO_DIR}/data/server-settings.json
sed -i -e "s/\"description\": \"[^\\\"]*\"/\"description\": \"${SERVER_DESCRIPTION}\"/g" ${FACTORIO_DIR}/data/server-settings.json

cp ${INIT_DIR}/factorio.service.example /etc/systemd/system/factorio.service
systemctl daemon-reload

echo "Installation script has completed. If you wish to remove the extra build tools committed at the beginning, press ENTER."
echo "Otherwise, press CTRL+C to exit."
read -p "Press enter to continue . . ."

if [[ "${rollback_id}" -gt 0 ]]; then
	yum -y history rollback ${rollback_id}
fi