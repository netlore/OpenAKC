#!/bin/bash

#
# Constants
#
source /etc/os-release
VERSION="1.0.0~alpha1"
BUILD="1"

#
# Package requirements for build
#
if [ "x$(whoami)" != "xroot" ]; then
 echo "Sorry, this currently needs to be run as root. Quitting."
 echo
 exit 1
fi
#
if [ "x${ID}" == "xdebian" ]||[ "x${ID}" == "xubuntu" ]; then
 OS="${ID}${VERSION_ID}"
else
 echo "Warning: This OS is not recognised. Attempting to continue"
 echo
 OS="unknown"
fi
RELEASE="${VERSION}~${OS}-${BUILD}"
echo "Release: ${RELEASE}"
# 
apt install build-essential unzip libcap-dev libssl-dev
if [ ${?} -ne 0 ]; then
 echo
 echo "Sorry, could not verify required packages for build. Quitting."
 echo
 exit 1
fi

#
# Locate our script
#
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
 DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
 SOURCE="$( readlink "$SOURCE" )"
 [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SDIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
cd $SDIR || exit 1

ODIR=$(pwd)
BDIR="/tmp/openakc_${RELEASE}_build.$$"
mkdir -p ${BDIR}
cp -dpR ${SDIR}/* ${BDIR}
cd $BDIR || exit 1


echo "Building OpenAKC Capability Tool"
cd tools/openakc-cap
gcc -fPIC -O2 -Dlinux -Wall -Wwrite-strings -Wpointer-arith -Wcast-qual -Wcast-align -Wstrict-prototypes -Wmissing-prototypes -Wnested-externs -Winline -Wshadow -g  -c openakc-cap.c -o openakc-cap.o
gcc -O2 -Dlinux -Wall -Wwrite-strings -Wpointer-arith -Wcast-qual -Wcast-align -Wstrict-prototypes -Wmissing-prototypes -Wnested-externs -Winline -Wshadow -g  -o openakc-cap openakc-cap.o -lcap
cp openakc-cap -p ${BDIR}/bin
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
cd ${BDIR}/bin
#
cp ../tools/hpenc-3.0/src/hpenc ./openakc-hpenc
strip ./openakc-hpenc
strip ./openakc-cap
#
sed -i "s,^RELEASE=.*,RELEASE=\"${RELEASE}\",g" openakc
##shc -v -r -T -f openakc
cp openakc openakc.x
#
sed -i "s,^RELEASE=.*,RELEASE=\"${RELEASE}\",g" openakc-server
##shc -v -r -T -f openakc-server
cp openakc-server openakc-server.x
#
sed -i "s,^RELEASE=.*,RELEASE=\"${RELEASE}\",g" openakc-plugin
##shc -v -r -T -f openakc-plugin
cp openakc-plugin openakc-plugin.x
#
sed -i "s,^RELEASE=.*,RELEASE=\"${RELEASE}\",g" openakc-session
##shc -v -r -T -f openakc-session
cp openakc-session openakc-session.x


#
# Build Client Package
# 
cd $BDIR || exit 1
PDIR="openakc_${RELEASE}_amd64"
#
mkdir -p "${PDIR}/DEBIAN"
mkdir -p "${PDIR}/etc/openakc"
mkdir -p "${PDIR}/var/lib/openakc"
mkdir -p "${PDIR}/usr/sbin"
mkdir -p "${PDIR}/usr/bin"
mkdir -p "${PDIR}/usr/share/doc/openakc"
#
cp resources/openakc.conf "${PDIR}/etc/openakc/"
cp bin/openakc-cap "${PDIR}/usr/bin/openakc-cap"
cp bin/openakc-hpenc "${PDIR}/usr/bin/openakc-hpenc"
cp bin/openakc-session.x "${PDIR}/usr/bin/openakc-session"
cp resources/deb_preinst "${PDIR}/DEBIAN/preinst"
cp resources/deb_postinst "${PDIR}/DEBIAN/postinst"
cp resources/deb_postrm "${PDIR}/DEBIAN/postrm"
cp bin/openakc-plugin.x "${PDIR}/usr/sbin/openakc-plugin"
cp LICENSE "${PDIR}/usr/share/doc/openakc/"
cp LICENSE-hpenc "${PDIR}/usr/share/doc/openakc/"
cp LICENSE-libsodium "${PDIR}/usr/share/doc/openakc/"
cp QUICKSTART.txt "${PDIR}/usr/share/doc/openakc/"
#
chmod 755 "${PDIR}/var/lib/openakc"
chmod 755 "${PDIR}/etc/openakc"
chmod 644 "${PDIR}/etc/openakc/openakc.conf"

#
echo "Package: openakc" > "${PDIR}/DEBIAN/control"
echo "Version: ${VERSION}-${BUILD}" >> "${PDIR}/DEBIAN/control"
echo "Maintainer: A. James Lewis <james@fsck.co.uk>" >> "${PDIR}/DEBIAN/control"
echo "Depends: openssh-server (>= 7.0), openssh-client (>= 7.0), bash (>= 3.2), openssl (>= 0.9.8), coreutils, hostname, debianutils, e2fsprogs, libcap2" >> "${PDIR}/DEBIAN/control"
echo "Homepage: http://www.fsck.co/uk/openakc/" >> "${PDIR}/DEBIAN/control"
echo "Architecture: amd64" >> "${PDIR}/DEBIAN/control"
echo "Description: OpenAKC Agent" >> "${PDIR}/DEBIAN/control"
#
dpkg-deb --build "${PDIR}"

rm -fr "${PDIR}"

#
# Build Tools Package
#
cd $BDIR || exit 1
PDIR="openakc-tools_${RELEASE}_amd64"
#
mkdir -p "${PDIR}/DEBIAN"
mkdir -p "${PDIR}/usr/bin"
mkdir -p "${PDIR}/usr/share/doc/openakc-tools"
#
cp bin/openakc "${PDIR}/usr/bin/openakc"
cp LICENSE "${PDIR}/usr/share/doc/openakc-tools/"
cp QUICKSTART.txt "${PDIR}/usr/share/doc/openakc-tools/"
#
chmod 755 "${PDIR}/usr/bin/openakc"

#
echo "Package: openakc-tools" > "${PDIR}/DEBIAN/control"
echo "Version: ${VERSION}-${BUILD}" >> "${PDIR}/DEBIAN/control"
echo "Maintainer: A. James Lewis <james@fsck.co.uk>" >> "${PDIR}/DEBIAN/control"
echo "Depends: bash (>= 3.2), openssl (>= 0.9.8), coreutils, hostname, sudo, debianutils" >> "${PDIR}/DEBIAN/control"
echo "Homepage: http://www.fsck.co.uk/openakc/" >> "${PDIR}/DEBIAN/control"
echo "Architecture: amd64" >> "${PDIR}/DEBIAN/control"
echo "Description: OpenAKC API Tools" >> "${PDIR}/DEBIAN/control"
#
dpkg-deb --build "${PDIR}"

rm -fr "${PDIR}"

#
# Build Server Package
#
cd $BDIR || exit 1
PDIR="openakc-server_${RELEASE}_amd64"
#
mkdir -p "${PDIR}/DEBIAN"
#mkdir -p "${PDIR}/etc/openakc"
#mkdir -p "${PDIR}/var/lib/openakc"
mkdir -p "${PDIR}/usr/sbin"
mkdir -p "${PDIR}/usr/bin"
mkdir -p "${PDIR}/etc/sudoers.d"
mkdir -p "${PDIR}/etc/xinetd.d"
mkdir -p "${PDIR}/usr/share/doc/openakc-server"
#
cp bin/openakc-hpenc "${PDIR}/usr/bin/openakc-hpenc"
cp bin/openakc-server.x "${PDIR}/usr/sbin/openakc-server"
cp resources/deb_postinst-server "${PDIR}/DEBIAN/postinst"
cp resources/deb_postrm-server "${PDIR}/DEBIAN/postrm"
cp resources/openakc-sudoers "${PDIR}/etc/sudoers.d/openakc"
cp resources/openakc-xinetd "${PDIR}/etc/xinetd.d/openakc"
#cp docs/OpenAKC.pdf "${PDIR}/usr/share/doc/openakc/"
cp LICENSE "${PDIR}/usr/share/doc/openakc-server/"
cp LICENSE-hpenc "${PDIR}/usr/share/doc/openakc-server/"
cp LICENSE-libsodium "${PDIR}/usr/share/doc/openakc-server/"
cp QUICKSTART.txt "${PDIR}/usr/share/doc/openakc-server/"

#
chmod 640 "${PDIR}/etc/sudoers.d/openakc"
chmod 640 "${PDIR}/etc/xinetd.d/openakc"

#
echo "Package: openakc-server" > "${PDIR}/DEBIAN/control"
echo "Version: ${VERSION}-${BUILD}" >> "${PDIR}/DEBIAN/control"
echo "Maintainer: A. James Lewis <james@fsck.co.uk>" >> "${PDIR}/DEBIAN/control"
echo "Depends: openssh-client (>= 7.0), bash (>= 3.2), openssl (>= 0.9.8), coreutils, xinetd, openakc-tools" >> "${PDIR}/DEBIAN/control"
echo "Homepage: http://www.fsck.co/uk/openakc/" >> "${PDIR}/DEBIAN/control"
echo "Architecture: amd64" >> "${PDIR}/DEBIAN/control"
echo "Description: OpenAKC API Server" >> "${PDIR}/DEBIAN/control"
#
dpkg-deb --build "${PDIR}"

rm -fr "${PDIR}"



#
# Cleanup
#

cp *.deb "${ODIR}"
cd "${ODIR}" || exit 1
rm -fr "${BDIR}"
