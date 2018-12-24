# Factorio (SE)Init Script
A factorio init script for linux with an optional SELINUX policy add-on.
This is a fork of https://github.com/Bisa/factorio-init

## TODO
 * TCP/UDP port controls (netfilter).
 * firewall-cmd commands.
 * SELINUX Boolean values for certain functions such as network, sockets, user home reads, etc.
 * SELINUX_u user and roles.
 * Proper transition points from init-script.
 * Tighten up policy rules to explicits.

# Dependencies
 
 ## Runtime dependencies
 - _wget_ package - If you are planning to use the installer.
 - _python-requests_ package - If you are planning to use the updater script. It will likely install the following dependencies:
    - python-backports
    - python-backports-ssl_match_hostname
    - python-ipaddress
    - python-six
    - python-urllib3
    
 ## Build dependencies
 - git
 - glibc-devel
 - glibc
 - make
 - gcc-c++ - C++ component for glibc (optional)
 - texinfo - documentation output for glibc
 - libselinux-devel - SELINUX aware glibc
 - audit-libs-devel - SELINUX auditing aware
 - libcap-devel - root privileges partitioning for glibc

## SELINUX specific dependencies
   ### Runtime dependencies
     - SELINUX installed and enabled.
     - `setenforce 1` - If you do not know what this command does, **STOP!** DO NOT PROCEED! Please read up on SELINUX Administration.
     - _coreutils_ package - Required in all cases.
     - _policycoreutils_ package - Required in all cases.
   ### Build dependencies
   You will not need this if you use the RPM.
     - _policycoreutils-python_ package - Optional if using RPM. Required if compiling yourself.
     - _policycoreutils-devel_ package - Optional if using RPM or just making small adjustments. Required if debugging.
     - _setools-console_ package - Required if debugging, optional in other cases.


# Debugging
 If you find yourself wondering why stuff is not working the way you expect:
 - Check the logs, I suggest you `tail -f /opt/factorio/factorio-current.log` in a separate session
 - Enable debugging in the config and/or:
 - Try running the same commands as the factorio user (`/opt/factorio-init/factorio invocation` will tell you what the factorio user tries to run at start)

 ```bash
 /opt/factorio-init/factorio invocation
 #  Run this as the factorio user, example:
 sudo -u factorio 'whatever invocation gave you'
 # You should see some output in your terminal here, hopefully giving
 # you a hint of what is going wrong
 ```

- You may need to study the audit logs at `/var/log/audit/audit.log` and see what is being blocked.
- You may need to disable the `dontaudit` flag and force auditing to get the output to the audit log with more answers: `semodule --disable_dontaudit --build`
- If you followed hardening guides, you may need to adjust the *umask* temporarily back to `umask 022` which was the default, or run:
 ```bash
 find /opt/glibc-2.18 -type d -exec chmod 755 {} \;
 find /opt/factorio-init -type d -exec chmod 755 {} \;
 find /opt/factorio -type d -exec chmod 755 {} \;
 ```

# Install
- Create a directory where you want to store this script along with configuration. Cloning from github assuming **/opt/factorio-init** as the directory:

 ```bash
 yum install git wget python-requests
 cd '/opt'
 git clone --recurse-submodules https://github.com/jhawkwind/factorio-SEinit /opt/factorio-init
 ```
 
- Rename **/opt/factorio-init/config.example** to **/opt/factorio-init/config** and modify the values within according to your setup.

## Install appropriate glibc version as required for CentOS 7

- The config has options for declaring an alternate glibc root, don't forget to configure it.
- Compile the required GLIBC 2.18 and install it side-by-side with the OS version.
```bash
yum install glibc-devel glibc gcc make gcc-c++ autoconf texinfo libselinux-devel audit-libs-devel libcap-devel
cd /opt/factorio-init/glibc
git apply ../patches/test-installation.pl.patch
mkdir glibc-build
cd glibc-build
../configure --prefix='/opt/glibc-2.18' --with-selinux
make
make install
```

## SELINUX Enablement
- You must set `SELINUX=1` in the **config** file to have the init script change context into the **factorio_t** domain.
- The policy expects you to have the INIT script, Factorio, and GLIBC-2.18 in either **/opt** or **/data**. If you put them
  anywhere else, you will need to modify **selinux/factorio.fc** and (of course) the **config** to tell it the new locations,
  and manually compile and install the SELINUX policy modules.
- File location format:
  * /opt (or /data)
    * /factorio/
    * /factorio-init/
    * /glibc-2.18/
      * lib/
        * ld-2.18.so
- Via the RPM, just run:
  ```bash
  rpm -Uvh /opt/factorio-init/selinux/Factorio-SEinit-1.1-0.el7.src.rpm
  restorecon -R -v /opt/factorio-init
  restorecon -R -v /opt/glibc-2.18
  ```
- Compiling the module manually:
  ```bash
  yum install policycoreutils-python policycoreutils-devel setools-console
  cd /opt/factorio-init/selinux
  make -f /usr/share/selinux/devel/Makefile factorio.pp
  semodule -i factorio.pp
  restorecon -R -v /opt/factorio-init
  restorecon -R -v /opt/glibc-2.18
  ```

## First-run
- If you don't have Factorio installed already, use the `install` command:

 ```bash
 useradd -c "Factorio Server account" -d /opt/factorio -M -s /usr/sbin/nologin -r factorio
 /opt/factorio-init/factorio install  # see help for options
 ```

- The installation routine creates Factorio's `config.ini` automatically.

- If you previously ran Factorio without this script, the existing `config.ini` should work fine, just apply the security contexts:
  ```bash
  restorecon -R -v /opt/factorio
  ```

## Autocompletion
- Copy/Symlink or source the bash_autocompletion file

 ```bash
 ln -s /opt/factorio-init/bash_autocomplete /etc/bash_completion.d/factorio
 ```
 OR:
 ```bash
 echo "source /opt/factorio-init/bash_autocomplete" >> ~/.bashrc
 # restart your shell to verify that it worked
 ```

## Systemd
- Copy the example service, adjust & reload

 ```bash
 cp /opt/factorio-init/factorio.service.example /etc/systemd/system/factorio.service
 # Edit the service file to suit your environment then reload systemd
 systemctl daemon-reload
 ```

- Verify that the server starts

 ```bash
 systemctl start factorio
 systemctl status -l factorio
 # Remember to enable the service at startup if you want that:
 systemctl enable factorio
 ```
 
 ## Clean up
 - You know we just installed a bunch of stuff earlier? This yum command should remove everything we no longer need:
 ```bash
 yum remove glibc-devel gcc gcc-c++ autoconf texinfo libselinux-devel audit-libs-devel libcap-devel libsepol-devel pcre-devel libstdc++-devel git setools-console policycoreutils-devel perl-Git mpfr libmpc kernel-headers glibc-headers cpp m4 selinux-policy-devel
 ```
 - You can resecure the _umask_ with `umask 0077`
 
 ## Firewall
 - The following firewalld rules will come in handy. As a "TODO" is to automate this as part of the installation process.
 ```bash
 firewall-cmd --new-service=factorio-multiplayer --permanent
 firewall-cmd --service=factorio-multiplayer --description="Factorio multi-player lock step sychronization replication protocol" --permanent
 firewall-cmd --service=factorio-multiplayer --add-port=34197/udp --permanent
 firewall-cmd --add-service=factorio-multiplayer --permanent
 firewall-cmd --reload
 ```

# Thank You
- To all who find this script useful in one way or the other
- A big thank you to [Wube](https://www.factorio.com/team) for making [Factorio](https://www.factorio.com/)
- A special thanks to NoPantsMcDance, Oxyd, HanziQ, TheFactorioCube and all other frequent users of the [**#factorio**](irc://irc.esper.net/#factorio) channel @ esper.net
- Thank you to Salzig for pointing Bisa in the right direction when it comes to input redirection
- The user _millisa_ over on the [factorio forums](https://forums.factorio.com/viewtopic.php?t=54654#p324493) for creating a wonderful guide to follow on making an alternate glibc root.
- Please report any [(SE)init issues](https://github.com/jhawkwind/factorio-SEinit/issues) you find.
- At last, but not least; Thank you to all [(SE)init contributors](https://github.com/jhawkwind/factorio-SEinit/graphs/contributors) and users posting [mainline issues](https://github.com/Bisa/factorio-init/issues) in Bisa's original [github](https://github.com/Bisa/factorio-init/) project or on the [factorio forums](https://forums.factorio.com/viewtopic.php?f=133&t=13874)

You are all a great source of motivation, thank you.

# License
This code is realeased with the MIT license, see the LICENSE file.
