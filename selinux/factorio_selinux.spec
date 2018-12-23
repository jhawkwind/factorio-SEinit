# vim: sw=4:ts=4:et


%define relabel_files() \
restorecon -R /data/factorio-init/factorio; \

%define selinux_policyver 3.13.1-229

Name:   Factorio-SEinit
Version:	1.1
Release:	0%{?dist}
Summary:	SELinux policy module for Factorio and Factorio-init for CentOS/RHEL 7

Group:	System Environment/Base		
License:	MIT
URL:		https://github.com/jhawkwind/factorio-init
Source0:	factorio.pp
Source1:	factorio.if
Source2:	factorio_selinux.8


Requires: policycoreutils, libselinux-utils
Requires(post): selinux-policy-base >= %{selinux_policyver}, policycoreutils
Requires(postun): policycoreutils
BuildArch: x86_64

%description
This package installs and sets up the SELinux policy security module for factorio.
You will need to have Factorio headless server, glibc-2.18, and Factorio-init in their own folder
under either /opt or /data.
Example: /opt/factorio/ and /opt/factorio-init/ and /opt/glibc-2.18/

%install
install -d %{buildroot}%{_datadir}/selinux/packages
install -m 644 %{SOURCE0} %{buildroot}%{_datadir}/selinux/packages
install -d %{buildroot}%{_datadir}/selinux/devel/include/contrib
install -m 644 %{SOURCE1} %{buildroot}%{_datadir}/selinux/devel/include/contrib/
install -d %{buildroot}%{_mandir}/man8/
install -m 644 %{SOURCE2} %{buildroot}%{_mandir}/man8/factorio_selinux.8
install -d %{buildroot}/etc/selinux/targeted/contexts/users/


%post
semodule -n -i %{_datadir}/selinux/packages/factorio.pp
if /usr/sbin/selinuxenabled ; then
    /usr/sbin/load_policy
    %relabel_files

fi;
exit 0

%postun
if [ $1 -eq 0 ]; then
    semodule -n -r factorio
    if /usr/sbin/selinuxenabled ; then
       /usr/sbin/load_policy
       %relabel_files

    fi;
fi;
exit 0

%files
%attr(0600,root,root) %{_datadir}/selinux/packages/factorio.pp
%{_datadir}/selinux/devel/include/contrib/factorio.if
%{_mandir}/man8/factorio_selinux.8.*


%changelog
* Fri Dec 21 2018 Kelvin Mok <admin@outlawstar.net> 1.1-0
- Working version that assumes you have installed Factorio, Factorio-init, and GLIBC 2.18 at /opt or /data.
- WARNING: This will NOT work at any other locations. Please report any issues to me via GitHub at
  https://github.com/jhawkwind/factorio-init

* Thu Dec 20 2018 Kelvin Mok <admin@outlawstar.net> 1.0-1
- Initial version

