#!/bin/bash

# Make sure the script is CD'ed to a PWD that is valid and not symlinked. (ie. where the script actually is at)
SOURCE="${BASH_SOURCE[0]}"
while [ -h "${SOURCE}" ]; do # resolve ${SOURCE} until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "${SOURCE}" )" && pwd )"
  SOURCE="$(readlink "${SOURCE}")"
  [[ ${SOURCE} != /* ]] && SOURCE="${DIR}/${SOURCE}" # if ${SOURCE} was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
cd "${SCRIPT_DIR}"

set -x
/bin/bash ./factorio/factorio.sh ${1}
sleep 3; # Need to wait for the disk process to catch up on slower systems to complete installation of the files to avoid contention/deadlock.
cp ./factorio_init/factorio_init.if ./factorio_init/factorio_init.if.backup
cat ./factorio_init/factorio.if >> ./factorio_init/factorio_init.if
/bin/bash ./factorio_init/factorio_init.sh ${1}
cat ./factorio_init/factorio_init.if.backup > ./factorio_init/factorio_init.if

pwd=$(pwd)
#rpmbuild --define "_sourcedir ${pwd}/build" --define "_specdir ${pwd}/build" --define "_builddir ${pwd}/build" --define "_srcrpmdir ${pwd}/build" --define "_rpmdir ${pwd}/build" --define "_buildrootdir ${pwd}/build/.build"  -ba ${pwd}/build/factorio_selinux.spec