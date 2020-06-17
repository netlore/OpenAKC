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
CONTAINEROPTS="-d $(lsb_release -si | tr 'A-Z' 'a-z') -r $(lsb_release -sc | tr 'A-Z' 'a-z') -a amd64"
#CONTAINEROPTS="-d ubuntu -r bionic -a amd64" # Set null to be asked.
#

#
# Functions
#
checkpackage () {
 UPDATE=0
 LXCINS=0
 for i in $@
 do
  printf "${CYAN}"
  echo -n "Checking for installed package, $i - "
  if dpkg -l "$i" | grep -q "^ii" 1> /dev/null 2> /dev/null; then
   echo "Found!"
  else
   echo "Not Found."
   echo 
   echo "Attempting install using sudo"
   echo
   printf "${WHITE}"
   if [ ${UPDATE} -eq 0 ]; then
    sudo apt update
    UPDATE=1
   fi
   [ "x${i}" == "xlxc" ]&&LXCINS=1
   sudo apt -y install $i
   if [ $? -ne 0 ]; then
    printf "${CYAN}"
    echo "Error Installing, Aborted!"
    return 1
   fi
  fi
 done
echo 
printf "${CYAN}"
if [ ${LXCINS} -eq 1 ]; then
 echo "We installed some components which likely require that you log out"
 echo -n "and back in before continueing. "
 if [ -f /var/run/reboot-required ]; then
  echo "Please also consider rebooting before continueing."
 else
  echo
 fi
 echo
 echo "Aborting, please re-un this script once you are ready."
 echo
 printf "${WHITE}"
 exit 1
fi
return 0   
}

#
# Setup & Arguments
#
REQUIRED="lxc uidmap bridge-utils debootstrap dnsmasq-base gnupg iproute2 iptables lxc-templates lxcfs openssl rsync acl"
SCRIPT=$(basename "$0")
SCRIPTPATH=$(dirname "$0")
SUBIDS="${SUBID}-$((${SUBID}+65536))"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
TITLE='\033[0;37;1m'
WHITE='\033[0;m'
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
printf "${TITLE}Setting up OpenAKC demo environment, using unprivilaged LXC containers.${CYAN}\n"
echo
if [ ! -f /etc/debian_version ]; then
 echo "Sorry, this script requires a debian/ubuntu based distribution. Aborted!"
 echo
 printf "${WHITE}"
 exit 1
fi
#
if [ "x$(id -u)" == "x0" ]; then
 echo "Sorry, this script must be run as a non-root user. Aborted!"
 echo
 printf "${WHITE}"
 exit 1
fi
#
if checkpackage ${REQUIRED}; then
 echo "All Components found, continueing."
 echo
else
 echo "Components missing, cannot continue."
 echo
 printf "${WHITE}"
 exit 1
fi
#
if [ ! -d "${HOME}" ]; then
 echo "\$HOME appears to be invalid, Aborting!"
 echo
 printf "${WHITE}"
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
 printf "${WHITE}"
 sudo usermod --add-subuids ${SUBIDS} $(whoami)
 sudo usermod --add-subgids ${SUBIDS} $(whoami)
 #
 mkdir -p "${HOME}/.config"
 mkdir -p "${HOME}/.local/share/lxc"
 mkdir -p "${HOME}/.cache/lxc" 
 setfacl -m u:${SUBID}:x "${HOME}/.local"
 setfacl -m u:${SUBID}:x "${HOME}/.local/share"
 setfacl -m u:${SUBID}:x "${HOME}/.local/share/lxc"
 cp -dpR /etc/lxc/ "${HOME}/.config"
 printf "${CYAN}"
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
  echo "The next step will destroy the test containers and rebuild!"
  echo
  echo "Press ENTER to rebuild test containers, or ^C to abort"
  read i
  echo
 fi
#
 echo "Destroying old containers..."
 echo
 printf "${WHITE}"
 lxc-stop -n openakc-combined 2> /dev/null
 lxc-destroy -n openakc-combined 2> /dev/null
 lxc-stop -n openakc-client 2> /dev/null
 lxc-destroy -n openakc-client 2> /dev/null
 printf "${CYAN}Installing with options \"${CONTAINEROPTS}\", please wait...${WHITE}\n"
 lxc-create -t download -n openakc-combined -- ${CONTAINEROPTS} > /dev/null
 lxc-create -t download -n openakc-client -- ${CONTAINEROPTS} > /dev/null
 echo
 printf "${CYAN}Almost done!...${WHITE}\n"
 echo
 sleep 3
 lxc-start -n openakc-combined
 lxc-start -n openakc-client
fi
lxc-ls --fancy
echo
#
STATE=$(($(lxc-info -n openakc-combined | grep -c RUNNING)+$(lxc-info -n openakc-client | grep -c RUNNING)))
if [ ${STATE} -ne 2 ]; then
 printf "${CYAN}Containers don't seem to be running properly, please debug.  Exiting!${WHITE}\n"
 echo
 exit 1
fi
#
if [ ${REBUILD} -eq 1 ]; then
 printf "${CYAN}Waiting for new containers to settle${WHITE}\n"
 sleep 10
fi 

#
# OK, lets get our containers ready to use, and build our packages
#
printf "${CYAN}Setting up containers${WHITE}\n"
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
 printf "${CYAN}Can't find source code, exiting.${WHITE}\n"
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
 printf "${CYAN}Output packages copied to your home folder - ${HOME}${WHITE}\n"
 echo
 ls "${HOME}/.local/share/lxc/openakc-combined/rootfs/tmp/OpenAKC/"*.deb
 echo
 cp "${HOME}/.local/share/lxc/openakc-combined/rootfs/tmp/OpenAKC/"*.deb "${HOME}"
 cp "${HOME}/.local/share/lxc/openakc-combined/rootfs/tmp/OpenAKC/"*.deb "${HOME}/.local/share/lxc/openakc-client/rootfs/tmp/OpenAKC/"
fi
#
if [ ${OUTPUT} -eq 0 ]; then
 printf "${CYAN}Looks like we failed to create any output, please debug!${WHITE}\n"
 echo
 exit 1
fi

#
# Install OpenAKC packages in our containers
#
if [ ${INSTALL} -eq 1 ]; then
 COMBINED=$(lxc-attach -n openakc-client -- find /tmp/OpenAKC | grep "deb$" | grep "openakc-")
 CLIENT=$(lxc-attach -n openakc-client -- find /tmp/OpenAKC | grep "deb$" | grep "openakc_")
 printf "${CYAN}Installing packages in container \"openakc-combined\"${WHITE}\n"
 echo
 lxc-attach -n openakc-combined -- dpkg -P openakc-tools openakc-server 2> /dev/null
 lxc-attach -n openakc-combined -- dpkg -i ${COMBINED}
 echo
 echo
 printf "${CYAN}Installing packages in container \"openakc-client\"${WHITE}\n"
 echo
 lxc-attach -n openakc-client -- dpkg -P openakc 2> /dev/null
 lxc-attach -n openakc-client -- dpkg -i ${CLIENT}
 echo
 echo
fi

#
# Do basic config, and create users ssh keys for testing.
#
printf "${CYAN}"
SERVERIP=$(lxc-attach -n openakc-combined -- ip a show eth0 | grep "inet " | sed -e "s,/, ,g" | awk '{print $2}')
CLIENTIP=$(lxc-attach -n openakc-client -- ip a show eth0 | grep "inet " | sed -e "s,/, ,g" | awk '{print $2}')
echo "${CLIENTIP}%openakc-client" | tr '%' '\t' > "${HOME}/.local/share/lxc/openakc-combined/rootfs/tmp/hosts"
echo ${SERVERIP}%openakc-combined openakc01 openakc02 | tr '%' '\t' >> "${HOME}/.local/share/lxc/openakc-combined/rootfs/tmp/hosts"
printf "${WHITE}"
cat "${HOME}/.local/share/lxc/openakc-combined/rootfs/etc/hosts" | grep -v openakc >> "${HOME}/.local/share/lxc/openakc-combined/rootfs/tmp/hosts"
cp "${HOME}/.local/share/lxc/openakc-combined/rootfs/tmp/hosts" "${HOME}/.local/share/lxc/openakc-client/rootfs/tmp/hosts"
lxc-attach -n openakc-combined -- cp /tmp/hosts /etc/hosts
lxc-attach -n openakc-client -- cp /tmp/hosts /etc/hosts
printf "${CYAN}"
echo "Creating users on OpenAKC combined container (openakc-combined)- admin-user & normal-user"
echo "Use these for testing!"
printf "${WHITE}"
lxc-attach -n openakc-combined -- useradd -c "OpenAKC Admin" -k /etc/skel -s /bin/bash -m admin-user
lxc-attach -n openakc-combined -- useradd -c "Standard User" -k /etc/skel -s /bin/bash -m normal-user
printf "${CYAN}"
echo
echo "Creating users on OpenAKC client container (openakc-client) - app-user"
echo "Use this & root for testing!"
printf "${WHITE}"
lxc-attach -n openakc-client -- useradd -c "Application User" -k /etc/skel -s /bin/bash -m app-user
printf "${CYAN}"
echo
printf "Creating ssh private key used by \"admin-user\". ${RED}NOTE: ENTER PASSPHRASE - ${TITLE}\"adminkey\"${CYAN}\n"
echo "OpenAKC will not accept a key with no pass phrase!"
echo
printf "${WHITE}"
lxc-attach -n openakc-combined -- su - admin-user -c "ssh-keygen -q -N 'adminkey' -f '/home/admin-user/.ssh/id_rsa'"
printf "${CYAN}"
echo
echo "Running \"openakc register\" as user \"admin-user\", please enter the passphrase"
echo
printf "${YELLOW}"
lxc-attach -n openakc-combined -- su - admin-user openakc register
printf "${CYAN}"
echo
printf "Creating ssh private key used by \"normal-user\". ${RED}NOTE: ENTER PASSPHRASE - ${TITLE}\"userkey\"${CYAN}\n"
echo "OpenAKC will not accept a key with no pass phrase!"
echo
printf "${WHITE}"
lxc-attach -n openakc-combined -- su - normal-user -c "ssh-keygen -q -N 'userkey' -f '/home/normal-user/.ssh/id_rsa'"
printf "${CYAN}"
echo
echo "Running \"openakc register\" as user \"normal-user\", please enter the passphrase"
echo
printf "${YELLOW}"
lxc-attach -n openakc-combined -- su - normal-user openakc register
printf "${CYAN}"
echo
echo "If you need another attempt to register keys for demo users,"
echo "you can re-run the build+demo script with the following options"
echo "\"--norebuild --nocompile --noinstall\""
echo
echo "Press ^C now if if you need to try again, or ENTER to continue"
read i
echo
echo "About to copy \"admin-user\"'s openakc public key to the system keys folder, to grant admin privilages"
echo "Eg: cp /home/admin-user/.openakc/openakc-user-client-admin-user-pubkey.pem /var/lib/openakc/keys/"
echo
printf "${WHITE}"
lxc-attach -n openakc-combined -- cp /home/admin-user/.openakc/openakc-user-client-admin-user-pubkey.pem /var/lib/openakc/keys/
printf "${CYAN}"
echo "Done!"
echo
echo "Attempting to ssh to \"app-user@openakc-client\", this SHOULD FAIL as no access has been configured yet"
echo
printf "${WHITE}"
echo "ssh -o Batchmode=true -o StrictHostKeyChecking=no app-user@openakc-client"
lxc-attach -n openakc-combined -- su - normal-user -c "ssh -o Batchmode=true -o StrictHostKeyChecking=no app-user@openakc-client"
printf "${CYAN}"
echo
echo "Done!"
echo
echo "Using openakc setrole (as admin-user) to upload the example role configuration"
echo "openakc setrole app-user@openakc-client /tmp/examplerole"
echo "NB: use \"openakc editrole app-user@openakc-client\" for interactive configuation"
echo
printf "${WHITE}"
cp -dpR "${SCRIPTPATH}/debian-lxc-build+demo.role_example" "${HOME}/.local/share/lxc/openakc-combined/rootfs/tmp/examplerole"
printf "${YELLOW}"
lxc-attach -n openakc-combined -- su - admin-user openakc setrole app-user@openakc-client /tmp/examplerole
printf "${CYAN}"
echo "Done!"
echo
echo "You should now connect to the \"openakc-combined\" container,"
echo "Then verify that the \"normal-user\" account can successfully connect"
echo "using \"ssh app-user@openakc-client\""
echo
echo "You should now have a working demo/sample install in the containers!"
echo
echo "To access the container, type \"lxc-attach -n openakc-combined\""
echo "then, \"su - normal-user\""
echo "then, \"ssh app-user@openakc-client\""
echo
echo "If everything above worked, you should be able to connect using the \"normal-user\" key (Passphrase: userkey)"
echo
printf "${WHITE}"
