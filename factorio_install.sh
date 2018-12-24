install_glibc(){
  if ! git submodule update --init "${SCRIPT_DIR}/glibc"; then
    echo "Aborting install, ALT_GLIBC is specified to be built by glibc repository cannot be obtained."
    exit 1
  fi
	
  cd "${SCRIPT_DIR}/glibc"
	
  if ! git apply "${SCRIPT_DIR}/patches/test-installation.pl.patch"; then
    echo "Aborting install, cannot apply scripts/test-installation.pl patch."
    exit 1
  fi

  if ! mkdir "${SCRIPT_DIR}/glibc/glibc-build"; then
  	echo "Aborting install, cannot create glibc build directory."
  	exit 1
  fi
 
  cd "${SCRIPT_DIR}/glibc/glibc-build"
  
  configure_glibc="../configure --prefix=\""${ALT_GLIBC_DIR}"\""
  if [[ "${SELINUX}" -eq 1 ]]; then
  	configure_glibc="${configure_glibc} --with-selinux"
  fi
 
  if [ "$(id -u)" == "0" ]; then # Are we root?
  	if [[ "${SELINUX}" -eq 1 ]]; then # Is SELINUX turned on?
  	  if ! [[ "$(id -Z)" =~ "^unconfined_u:unconfined_r:unconfined_t:" ]]; then # Are we running unconfined?
        echo "Aborting install, SELINUX is enabled, but not running in unconfined domain, cannot build or install glibc."
        exit 1
  	  fi
  	fi
  	echo "Updating build area permissions ..."
  	if ! chown -R ${USERNAME}:${USERGROUP} "${SCRIPT_DIR}/glibc"; then
  	  echo "Aborting install, cannot update build permissions."
  	  exit 1
    fi
    
    if ! su ${USERNAME} -s /bin/bash -c ${configure_glibc}; then
  	  echo "Aborting install, cannot configure glibc."
  	  exit 1
    fi
    
    if ! su ${USERNAME} -s /bin/bash -c make; then # Do not build as root, so not to pollute the environment.
      echo "Aborting install, cannot build glibc."
      exit 1
    fi
    
  else
  	if ! ${configure_glibc}; then
  	  echo "Aborting install, cannot configure glibc."
  	  exit 1
    fi
  	
  	if ! make; then
  	echo "Aboring install, cannot build glibc."
  	exit 1
    fi
  fi
 
}
