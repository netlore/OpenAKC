Name:           openakc
Version:        0.98
Release:        6%{?dist}
Summary:	This OpenAKC "client" package contains the client ssh plugin which queries the API for authentication information.
Group:          Applications/System
License:        GPLv2.0
URL:            https://github.com/netlore/OpenAKC
Source0:	https://github.com/netlore/OpenAKC/archive/master.zip
BuildRoot:      %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
Requires:	openssh-clients, openssh-server >= 7.0, openssl >= 0.9.8, bash, coreutils, hostname, which, e2fsprogs, libcap >= 2.0
BuildRequires:  gcc, gcc-c++, bash, libcap-devel, openssl-devel, patch, unzip, tar
#, shc < 3.9


%package tools
Summary:       This OpenAKC "tools" package contains tools for registering with the server and for managing OpenAKC via the API.
Requires:      openssl >= 0.9.8, bash, coreutils, hostname, sudo, which

%package server
Summary:	This OpenAKC "server" package contains the API server which answers client authentication requests.
Requires:       xinetd, openakc-tools, openssh-clients >= 7.0, openssl >= 0.9.8, bash, coreutils

%description
OpenAKC is a set of tools for managing SSH Keys and user access to role users
on Linux hosts based on a server which has access to a directory such as
AD/LDAP or even local users.  Only the server, which could be shared with a
bastion requires directory access.  It provides privalage escalation,
authorization, authentication and connection all rolled into one.  With
optional management of statically deployed keys and session recording for
security/review.  

%description tools
OpenAKC is a set of tools for managing SSH Keys and user access to role users
on Linux hosts based on a server which has access to a directory such as
AD/LDAP or even local users.  Only the server, which could be shared with a
bastion requires directory access.  It provides privalage escalation,
authorization, authentication and connection all rolled into one.  With
optional management of statically deployed keys and session recording for
security/review.  

%description server
OpenAKC is a set of tools for managing SSH Keys and user access to role users
on Linux hosts based on a server which has access to a directory such as
AD/LDAP or even local users.  Only the server, which could be shared with a
bastion requires directory access.  It provides privalage escalation,
authorization, authentication and connection all rolled into one.  With
optional management of statically deployed keys and session recording for
security/review.  

%prep
%setup -q -c

%install
#
cd OpenAKC*

#
mkdir -p %{buildroot}/etc/openakc
mkdir -p %{buildroot}/usr/sbin
mkdir -p %{buildroot}/usr/bin
mkdir -p %{buildroot}/var/lib/openakc
mkdir -p %{buildroot}/etc/sudoers.d
mkdir -p %{buildroot}/etc/xinetd.d
#mkdir -p %{buildroot}/etc/cron.daily
#mkdir -p %{buildroot}/tmp

echo "Building OpenAKC Capability Tool"
cd tools/openakc-cap
gcc -fPIC -O2 -Dlinux -Wall -Wwrite-strings -Wpointer-arith -Wcast-qual -Wcast-align -Wstrict-prototypes -Wmissing-prototypes -Wnested-externs -Winline -Wshadow -g  -c openakc-cap.c -o openakc-cap.o
gcc -O2 -Dlinux -Wall -Wwrite-strings -Wpointer-arith -Wcast-qual -Wcast-align -Wstrict-prototypes -Wmissing-prototypes -Wnested-externs -Winline -Wshadow -g  -o openakc-cap openakc-cap.o -lcap
cp openakc-cap -p %{buildroot}/usr/bin
cd ../..

echo "Unpacking Tools"
cd tools
unzip -q hpenc-3.0.zip
unzip -q libsodium-1.0.18-RELEASE.zip
cd ..

echo "Building Sodium Security Library"
cd tools/libsodium-1.0.18-RELEASE
./configure
make
cd ../..

echo "Building HPEnc stream encryption tool"
cd tools/hpenc-3.0/src
cp ../../libsodium-1.0.18-RELEASE/src/libsodium/include/sodium.h .
cp ../../libsodium-1.0.18-RELEASE/src/libsodium/.libs/libsodium.a .
cp -dpR ../../libsodium-1.0.18-RELEASE/src/libsodium/include/sodium .
patch -p0 < ../../../resources/hpenc30.src.Makefile.patch
cd ..
make
cd ../..



echo "Compiling Shell Scripts"
cd bin
#
cp ../tools/hpenc-3.0/src/hpenc ./openakc-hpenc
#
sed -i "s,^RELEASE=.*,RELEASE=\"%{version}-%{release}\",g" openakc
##shc -v -r -T -f openakc
cp openakc openakc.x
#
sed -i "s,^RELEASE=.*,RELEASE=\"%{version}-%{release}\",g" openakc-server
##shc -v -r -T -f openakc-server
cp openakc-server openakc-server.x
#
sed -i "s,^RELEASE=.*,RELEASE=\"%{version}-%{release}\",g" openakc-plugin
##shc -v -r -T -f openakc-plugin
cp openakc-plugin openakc-plugin.x
#
sed -i "s,^RELEASE=.*,RELEASE=\"%{version}-%{release}\",g" openakc-session
##shc -v -r -T -f openakc-session
cp openakc-session openakc-session.x



echo "Building RPM Package Tree"
cd ..
cp bin/openakc-hpenc %{buildroot}/usr/bin/openakc-hpenc
cp bin/openakc.x %{buildroot}/usr/bin/openakc
cp bin/openakc-plugin.x %{buildroot}/usr/sbin/openakc-plugin
cp bin/openakc-session.x %{buildroot}/usr/bin/openakc-session
cp bin/openakc-server.x %{buildroot}/usr/sbin/openakc-server
cp resources/openakc-sudoers %{buildroot}/etc/sudoers.d/openakc
cp resources/openakc-xinetd %{buildroot}/etc/xinetd.d/openakc
cp resources/openakc.conf %{buildroot}/etc/openakc/openakc.conf


%clean
rm -rf %{buildroot}

%pre
if ! getent group openakc >/dev/null ; then
  if ! getent group 889 >/dev/null ; then
    groupadd -r -g 889 openakc
  else
    groupadd -r openakc
  fi
fi
#
if ! getent passwd openakc >/dev/null ; then
    if ! getent passwd 889 >/dev/null ; then
      useradd -r -u 889 -g openakc -d /var/lib/openakc -s /bin/bash -c "OpenAKC" openakc
    else
      useradd -r -g openakc -d /var/lib/openakc -s /bin/bash -c "OpenAKC" openakc
    fi
fi
chage -I -1 -m 0 -M 99999 -E -1 openakc 2> /dev/null 1> /dev/null
chsh -s /bin/nologin openakc 2> /dev/null 1> /dev/null
passwd -u openakc 2> /dev/null 1> /dev/null
exit 0



%post
setcap CAP_SETPCAP+ep /usr/bin/openakc-cap
chown -R root:openakc /etc/openakc
sed -i "s,^#AuthorizedKeysCommand .*$,AuthorizedKeysCommand /usr/sbin/openakc-plugin %u %h %f,g" /etc/ssh/sshd_config
sed -i "s,^#AuthorizedKeysCommandUser .*$,AuthorizedKeysCommandUser openakc,g" /etc/ssh/sshd_config
/sbin/service sshd restart > /dev/null 2>&1 || :
exit 0

#%post tools

%post server
if [ ! -n "`grep \"^#includedir /etc/sudoers.d\" /etc/sudoers`" ]; then
  echo "#includedir /etc/sudoers.d" >> /etc/sudoers
fi
sed -i '/^openakc/ d' /etc/services
echo "openakc              889/tcp      # OpenAKC Authentication Protocol" >> /etc/services
/sbin/service xinetd restart > /dev/null 2>&1 || :
exit 0



%postun
case "$*" in
 0) # This is a yum remove.
  chsh -s /bin/nologin openakc 2> /dev/null 1> /dev/null
  passwd -l openakc 2> /dev/null 1> /dev/null
  sed -i "s,^AuthorizedKeysCommand,#AuthorizedKeysCommand,g" /etc/ssh/sshd_config
  ;;
 1) # This is a yum update.
    # do nothing
  ;;
 *)
  echo "Warning: RPM says there is more than one version of openakc installed!"
  echo "Please refer to your system administrator, this should never happen."
esac
exit 0

%postun server
case "$*" in
 0) # This is a yum remove.
  sed -i '/^openakc/ d' /etc/services
  /sbin/service xinetd restart > /dev/null 2>&1 || :
  ;;
 1) # This is a yum update.
    # do nothing
  ;;
 *)
  echo "Warning: RPM says there is more than one version of openakc-server installed!"
  echo "Please refer to your system administrator, this should never happen."
esac
exit 0



%files
%defattr(-,root,root,-)
%attr(755, root, root) /usr/bin/openakc-cap
%attr(755, root, root) /usr/bin/openakc-hpenc
%attr(755, root, root) /usr/sbin/openakc-plugin
%attr(755, root, root) /usr/bin/openakc-session
%dir %attr(750, root, root) /etc/openakc
%dir %attr(750, openakc, root) /var/lib/openakc
%attr(640, root, openakc) %config /etc/openakc/openakc.conf
%doc OpenAKC*/LICENSE
%doc OpenAKC*/LICENSE-hpenc
%doc OpenAKC*/LICENSE-libsodium
%doc OpenAKC*/README


%files tools
%defattr(-,root,root,-)
%attr(755, root, root) /usr/bin/openakc
%doc OpenAKC*/LICENSE
%doc OpenAKC*/README
#%doc OpenAKC*/docs/OpenAKC_Instructions-Tools.pdf

%files server
%defattr(-,root,root,-)
%attr(755, root, root) /usr/bin/openakc-hpenc
%attr(755, root, root) /usr/sbin/openakc-server
%attr(440, root, root) %config(missingok) /etc/sudoers.d/openakc
%attr(644, root, root) %config(missingok) /etc/xinetd.d/openakc
%doc OpenAKC*/LICENSE
%doc OpenAKC*/LICENSE-hpenc
%doc OpenAKC*/LICENSE-libsodium
%doc OpenAKC*/README


%changelog
* Wed Feb 19 2020 James Lewis <james@fsck.co.uk>
- Added a bunch of documentation to the package

* Wed Dec 04 2019 James Lewis <james@fsck.co.uk>
- Many and various packaging fixes, and testing.

* Tue Nov 26 2019 James Lewis <james@fsck.co.uk>
- Initial Packaging
