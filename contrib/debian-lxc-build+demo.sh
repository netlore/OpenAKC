#!/bin/bash

# Filename      : debian-lxc-build+demo.sh
# Function      : Set up basic OpenAKC test platform using LXC.
#
# Copyright (C) 2020  A. James Lewis
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

#
# User Config
#
SUBID="100000" # Update by adding 100000 if range in use.
CONTAINEROPTS="-r focal -a amd64" # Set null to be asked.
#

#
# Functions
#
checkpackage () {
 for i in $@
 do
  echo -n "Checking for installed package, $i - "
  if dpkg -l "$i" 1> /dev/null 2> /dev/null; then
   echo "Found!"
  else
   echo "Not Found."
   echo 
   echo "Attempting install. If you do not want to install the package"
   echo "listed above, or do not have root permission, press ^C"
   echo
   sudo apt install $i
   if [ $? -ne 0 ]; then
    echo "Error Installing, Aborted!"
    return 1
   fi
  fi
 done
echo 
return 0   
}

#
# Setup & Arguments
#
REQUIRED="lxc uidmap bridge-utils debootstrap dnsmasq-base gnupg iproute2 iptables lxc-templates lxcfs openssl rsync"
SCRIPT=$(basename "$0")
SCRIPTPATH=$(dirname "$0")
SUBIDS="${SUBID}-$((${SUBID}+65536))"
REBUILD=1
YES=0
COMPILE=1
INSTALL=1
#
while true; do
 if [ ! $1 ]; then
  break
 fi
 case "$1" in
  --norebuild)
   REBUILD=0
   ;;
  --yes)
   YES=1
   ;;
  --nocompile)
   COMPILE=0
   ;;
  --noinstall) 
   INSTALL=0
   ;;
  *)
   echo "Usage: $0 [--norebuild] [--yes]"
   exit 1
   ;;
 esac  
 shift
done
#
if [ ! -f /etc/debian_version ]; then
 echo "Sorry, this script requires a debian/ubuntu based distribution. Aborted!"
 exit 1
fi
#
if checkpackage ${REQUIRED}; then
 echo "All Components found, continueing."
 echo
else
 echo "Components missing, cannot continue."
 echo
 exit 1
fi
#
if [ ! -d "${HOME}" ]; then
 echo "\$HOME appears to be invalid, Aborting!"
 echo
 exit 1
fi
#

#
# Proceed with Configuring unprivilaged LXC containers
#
if [ ! -d "${HOME}/.config/lxc" ]; then
 echo "Can't find unprivileged container setup"
 echo "this will add subuid/gids ${SUBIDS} to your account"
 echo "if these id's are in use, please update SUBIDS in script config"
 echo "in this case, also check ${HOME}/.config/lxc/default.conf"
 echo
 if [ ${YES} -eq 0 ]; then
  echo "Press ENTER to configure, or ^C to abort"
  read i
  echo
 fi
 echo "Setting up unprivileged LXC containers"
 echo
 sudo usermod --add-subuids ${SUBIDS} $(whoami)
 sudo usermod --add-subuids ${SUBIDS} $(whoami)
 #
 mkdir -p "${HOME}/.config"
 mkdir -p "${HOME}/.local/share/lxc"
 mkdir -p "${HOME}/.cache/lxc" 
 setfacl -m u:${SUBID}:x "${HOME}/.local"
 setfacl -m u:${SUBID}:x "${HOME}/.local/share"
 setfacl -m u:${SUBID}:x "${HOME}/.local/share/lxc"
 cp -dpR /etc/lxc/ "${HOME}/.config"
 echo "lxc.idmap = u 0 ${SUBID} 65536" >> "${HOME}/.config/lxc/default.conf"
 echo "lxc.idmap = g 0 ${SUBID} 65536" >> "${HOME}/.config/lxc/default.conf"
 echo -n "Updating /etc/lxc/lxc-usernet, adding - "
 echo "$(whoami) veth lxcbr0 10" | sudo tee /etc/lxc/lxc-usernet
 echo
else
 echo "Looks like unprivileged LXC containers are set up, assuming it works!"
 echo
fi

#
# Lets build some containers
#
echo "Containers will be \"openakc-combined\" & \"openakc-client\"."
echo
echo "\"openakc-combined\" will contain the OpenAKC server, and user"
echo "access host (and be used to build the packages)"
echo
echo "\"openakc-client\" will be the demo client system for OpenAKC"
echo "to grant access"
echo
if [ ${REBUILD} -eq 1 ]; then
 if [ ${YES} -eq 0 ]; then
  echo "The next step will destroy your test containers and rebuild!"
  echo
  echo "Press ENTER to rebuild test containers, or ^C to abort"
  read i
  echo
 fi
#
 echo "Destroying old containers..."
 echo
 lxc-stop -n openakc-combined 2> /dev/null
 lxc-destroy -n openakc-combined 2> /dev/null
 lxc-stop -n openakc-client 2> /dev/null
 lxc-destroy -n openakc-client 2> /dev/null
 echo "Installing, please wait..."
 lxc-create -t download -n openakc-combined -- -d ubuntu ${CONTAINEROPTS} > /dev/null
 lxc-create -t download -n openakc-client -- -d ubuntu ${CONTAINEROPTS} > /dev/null
 echo
 lxc-start -n openakc-combined
 lxc-start -n openakc-client
fi
lxc-ls --fancy
echo
#
STATE=$(($(lxc-info -n openakc-combined | grep -c RUNNING)+$(lxc-info -n openakc-client | grep -c RUNNING)))
if [ ${STATE} -ne 2 ]; then
 echo "Containers don't seem to be running properly, please debug.  Exiting!"
 echo
 exit 1
fi
#
if [ ${REBUILD} -eq 1 ]; then
 echo "Waiting for new containers to settle"
 sleep 10
fi 

#
# OK, lets get our containers ready to use, and build our packages
#
echo "Setting up containers."
echo
lxc-attach -n openakc-combined -- apt update
lxc-attach -n openakc-combined -- apt -q -y dist-upgrade
lxc-attach -n openakc-combined -- apt -q -y install build-essential unzip libcap-dev libssl-dev
lxc-attach -n openakc-combined -- apt -q -y install xinetd
#
lxc-attach -n openakc-client -- apt update
lxc-attach -n openakc-client -- apt -q -y dist-upgrade
lxc-attach -n openakc-client -- apt -q -y install openssh-server
#
if [ ! -f "${SCRIPTPATH}/../openakc.spec" ]; then
 echo "Can't find source code, exiting."
 echo
 exit 1
fi
#
OUTPUT=0
if [ ${COMPILE} -eq 1 ]; then
 lxc-attach -n openakc-combined -- mkdir -p /tmp/OpenAKC
 rm -fr "${HOME}/.local/share/lxc/openakc-combined/rootfs/tmp/OpenAKC/"*
 lxc-attach -n openakc-combined -- rmdir /tmp/OpenAKC
 lxc-attach -n openakc-combined -- mkdir -p /tmp/OpenAKC
 lxc-attach -n openakc-combined -- chmod 777 /tmp/OpenAKC
 lxc-attach -n openakc-client -- mkdir -p /tmp/OpenAKC
 rm -fr "${HOME}/.local/share/lxc/openakc-client/rootfs/tmp/OpenAKC/"*
 lxc-attach -n openakc-client -- rmdir /tmp/OpenAKC
 lxc-attach -n openakc-client -- mkdir -p /tmp/OpenAKC
 lxc-attach -n openakc-client -- chmod 777 /tmp/OpenAKC
 cp -dpR "${SCRIPTPATH}/../"* "${HOME}/.local/share/lxc/openakc-combined/rootfs/tmp/OpenAKC/"
 lxc-attach -n openakc-combined -- /tmp/OpenAKC/makedeb.sh
fi
#
if [ -f "${HOME}/.local/share/lxc/openakc-combined/rootfs/tmp/OpenAKC/openakc-server"*.deb ]; then
 OUTPUT=1
 echo "Output packages copied to your home folder - ${HOME}"
 echo
 ls "${HOME}/.local/share/lxc/openakc-combined/rootfs/tmp/OpenAKC/"*.deb
 echo
 cp "${HOME}/.local/share/lxc/openakc-combined/rootfs/tmp/OpenAKC/"*.deb "${HOME}"
 cp "${HOME}/.local/share/lxc/openakc-combined/rootfs/tmp/OpenAKC/"*.deb "${HOME}/.local/share/lxc/openakc-client/rootfs/tmp/OpenAKC/"
fi
#
if [ ${OUTPUT} -eq 0 ]; then
 echo "Looks like we failed to create any output, please debug!"
 echo
 exit 1
fi

#
# Install OpenAKC packages in our containers
#
if [ ${INSTALL} -eq 1 ]; then
 COMBINED=$(lxc-attach -n openakc-client -- find /tmp/OpenAKC | grep "deb$" | grep "openakc-")
 CLIENT=$(lxc-attach -n openakc-client -- find /tmp/OpenAKC | grep "deb$" | grep "openakc_")
 echo "Installing packages in container \"openakc-combined\"."
 echo
 lxc-attach -n openakc-combined -- dpkg -P openakc-tools openakc-server 2> /dev/null
 lxc-attach -n openakc-combined -- dpkg -i ${COMBINED}
 echo
 echo
 echo "Installing packages in container \"openakc-client\"."
 echo
 lxc-attach -n openakc-client -- dpkg -P openakc 2> /dev/null
 lxc-attach -n openakc-client -- dpkg -i ${CLIENT}
 echo
 echo
fi

#
# Do basic config, and create users ssh keys for testing.
#
SERVERIP=$(lxc-attach -n openakc-combined -- ip a show eth0 | grep "inet " | sed -e "s,/, ,g" | awk '{print $2}')
CLIENTIP=$(lxc-attach -n openakc-client -- ip a show eth0 | grep "inet " | sed -e "s,/, ,g" | awk '{print $2}')
echo "${CLIENTIP}%openakc-client" | tr '%' '\t' > "${HOME}/.local/share/lxc/openakc-combined/rootfs/tmp/hosts"
echo ${SERVERIP}%openakc-combined openakc01 openakc02 | tr '%' '\t' >> "${HOME}/.local/share/lxc/openakc-combined/rootfs/tmp/hosts"
cat "${HOME}/.local/share/lxc/openakc-combined/rootfs/etc/hosts" | grep -v openakc >> "${HOME}/.local/share/lxc/openakc-combined/rootfs/tmp/hosts"
cp "${HOME}/.local/share/lxc/openakc-combined/rootfs/tmp/hosts" "${HOME}/.local/share/lxc/openakc-client/rootfs/tmp/hosts"
lxc-attach -n openakc-combined -- cp /tmp/hosts /etc/hosts
lxc-attach -n openakc-client -- cp /tmp/hosts /etc/hosts
echo "Creating users on OpenAKC combined container (openakc-combined)- admin-user & normal-user"
echo "Use these for testing!"
lxc-attach -n openakc-combined -- useradd -c "OpenAKC Admin" -k /etc/skel -s /bin/bash -m admin-user
lxc-attach -n openakc-combined -- useradd -c "Standard User" -k /etc/skel -s /bin/bash -m normal-user
echo
echo "Creating users on OpenAKC client container (openakc-client) - app-user"
echo "Use this & root for testing!"
lxc-attach -n openakc-client -- useradd -c "Application User" -k /etc/skel -s /bin/bash -m app-user
echo
echo "Please enter a pass phrase for the ssh private key used by \"admin-user\""
echo "OpenAKC will not accept a key with no pass phrase!"
lxc-attach -n openakc-combined -- su - admin-user -c ssh-keygen
lxc-attach -n openakc-combined -- su - admin-user openakc register
echo
echo "Please enter a pass phrase for the ssh private key used by \"normal-user\""
echo "OpenAKC will not accept a key with no pass phrase!"
lxc-attach -n openakc-combined -- su - normal-user -c ssh-keygen
lxc-attach -n openakc-combined -- su - normal-user openakc register
echo
echo "If you need another attempt to add pass phrases and register for demo users,"
echo "you can re-run the build+demo script with the following options"
echo "\"--norebuild --nocompile --noinstall\""
echo

#
# More to come.
#
