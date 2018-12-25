#!/bin/bash
set -x
/bin/bash ./factorio/factorio.sh ${1}
/bin/bash ./factorio_init/factorio_init.sh ${1}

pwd=$(pwd)
#rpmbuild --define "_sourcedir ${pwd}/build" --define "_specdir ${pwd}/build" --define "_builddir ${pwd}/build" --define "_srcrpmdir ${pwd}/build" --define "_rpmdir ${pwd}/build" --define "_buildrootdir ${pwd}/build/.build"  -ba ${pwd}/build/factorio_selinux.spec