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
 Among others:
 - cURL

## SELINUX Dependencies
   - **REQUIRED**
     - SELINUX installed and enabled.
     - `setenforce 1` - If you do not know what this command does, **STOP!** DO NOT PROCEED! Please read up on SELINUX Administration.
     - _coreutils_ package - Required in all cases.
     - _policycoreutils_ package - Required in all cases.
   - **REQUIRED if small changes or recompiling only**
     - _policycoreutils-python_ package - Optional if using RPM. Required if compiling yourself.
     - gcc - Required to recompile. 
     - make - Required to recompile.
     - _policycoreutils-devel_ package - Optional if using RPM or just making small adjustments. Required if debugging.
     - _setools-console_ package - Required if debugging, optional in other cases.


# Debugging
 If you find yourself wondering why stuff is not working the way you expect:
 - Check the logs, I suggest you `tail -f /opt/factorio/factorio-current.log` in a separate session
 - Enable debugging in the config and/or:
 - Try running the same commands as the factorio user (`/opt/factorio-init/factorio invocation` will tell you what the factorio user tries to run at start)

 ```bash
 $ /opt/factorio-init/factorio invocation
 #  Run this as the factorio user, example:
 $ sudo -u factorio 'whatever invocation gave you'
 # You should see some output in your terminal here, hopefully giving
 # you a hint of what is going wrong
 ```

# Install
- Create a directory where you want to store this script along with configuration. (either copy-paste the files or clone from github):

 ```bash
 $ cd '/opt'
 $ git clone https://github.com/jhawkwind/factorio-SEinit
 ```
- Rename config.example to config and modify the values within according to your setup.

## SELINUX Enablement
- You must set `SELINUX=1` in the **config** file to have the init script change context into the **factorio_t** domain.
- The policy expects you to have the INIT script, Factorio, and GLIBC-2.18 in either **/opt** or **/data**. If you put them
  anywhere else, you will need to modify **selinux/factorio.fc** and (of course) the **config** to tell it the new locations,
  and manually compilie and install the SELINUX policy modules.
- File location format:
  * /opt (or /data)
    * /factorio/
    * /factorio-init/
    * /glibc-2.18/
      * lib/
        * ld-2.18.so
- Via the RPM, just run `rpm -Uvh Factorio-SEinit-1.1-0.el7.src.rpm`
- Compiling the module by hand:
  ```bash
  [root@localhost]$ checkmodule -M -m -o factorio.mod factorio.te
  [root@localhost]$ semodule_package -o factorio.pp -m factorio.mod -f factorio.fc
  [root@localhost]$ semodule -i factorio.pp
  [root@localhost]$ restorecon -R -v /opt/factorio
  [root@localhost]$ restorecon -R -v /opt/factorio-init
  [root@localhost]$ restorecon -R -v /opt/glibc-2.18
  ```

## Notes for users with CentOS 7 that has a older glibc version:

- The config has options for declaring a alternate glibc root. The user millisa over on the factorio forums has created a wonderful guide to follow on creating this alternate glibc root ( side by side ) here:
https://forums.factorio.com/viewtopic.php?t=54654#p324493

```bash
yum install glibc-devel glibc
cd /tmp
git clone git://sourceware.org/git/glibc.git
cd glibc
git checkout release/2.18/master
mkdir glibc-build
cd glibc-build
../configure --prefix='/opt/glibc-2.18'
```
Fix the test script
fix line 179 of the test install script:
```
vi ../scripts/test-installation.pl
```
change from
```perl
if (/$ld_so_name/) {
```
change to
```
if (/\Q$ld_so_name\E/) { 
```
save the changes, then run the command to build and install
```
make
make install
```


## First-run
- If you don't have Factorio installed already, use the `install` command:

 ```bash
 $ /opt/factorio-init/factorio install  # see help for options
 ```

- The installation routine creates Factorio's `config.ini` automatically.

- If you previously ran Factorio without this script, the existing `config.ini` should work fine.

## Autocompletion
- Copy/Symlink or source the bash_autocompletion file

 ```bash
 $ ln -s /opt/factorio-init/bash_autocomplete /etc/bash_completion.d/factorio
 # OR:
 $ echo "source /opt/factorio-init/bash_autocomplete" >> ~/.bashrc
 # restart your shell to verify that it worked
 ```

## Systemd
- Copy the example service, adjust & reload

 ```bash
 $ cp /opt/factorio-init/factorio.service.example /etc/systemd/system/factorio.service
 # Edit the service file to suit your environment then reload systemd
 $ systemctl daemon-reload
 ```

- Verify that the server starts

 ```bash
 $ systemctl start factorio
 $ systemctl status -l factorio
 # Remember to enable the service at startup if you want that:
 $ systemctl enable factorio
 ```

# Thank You
- To all who find this script useful in one way or the other
- A big thank you to [Wube](https://www.factorio.com/team) for making [Factorio](https://www.factorio.com/)
- A special thanks to NoPantsMcDance, Oxyd, HanziQ, TheFactorioCube and all other frequent users of the [#factorio](irc://irc.esper.net/#factorio) channel @ esper.net
- Thank you to Salzig for pointing me in the right direction when it comes to input redirection
- At last, but not least; Thank you to all [contributors](https://github.com/Bisa/factorio-init/graphs/contributors) and users posting [issues](https://github.com/Bisa/factorio-init/issues) in my [github](https://github.com/Bisa/factorio-init/) project or on the [factorio forums](https://forums.factorio.com/viewtopic.php?f=133&t=13874)

You are all a great source of motivation, thank you.

# License
This code is realeased with the MIT license, see the LICENSE file.
