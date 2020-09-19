#!/bin/bash

export container_path=/var/snap/lxd/common/lxd/storage-pools/default/containers
if [ ! -d $container_path ]; then
  export container_path=/var/lib/lxd/containers
fi
if [ ! -d $container_path ]; then
  export container_path=/var/snap/lxd/common/lxd/containers/
fi

export lxdbr0_path=/var/lib/lxd/networks/lxdbr0
if [ ! -d $lxdbr0_path ]; then
  export lxdbr0_path=/var/snap/lxd/common/lxd/networks/lxdbr0
fi

function install_public_keys {
rootfs_path=$1
name=$2

  # install the public keys for the host machine to the container as well
  if [ -f /root/.ssh/authorized_keys ]
  then
    lxc exec $name -- /bin/bash -c "mkdir -p /root/.ssh && touch /root/.ssh/authorized_keys"
    cat /root/.ssh/authorized_keys >> $rootfs_path/root/.ssh/authorized_keys
    lxc exec $name -- /bin/bash -c "chmod -R 600 /root/.ssh/authorized_keys"
  fi

  # install the public key for local root login
  if [ -f /root/.ssh/id_rsa.pub ]
  then
    lxc exec $name -- /bin/bash -c "mkdir -p /root/.ssh && touch /root/.ssh/authorized_keys"
    # add a newline
    echo >> $rootfs_path/root/.ssh/authorized_keys
    cat /root/.ssh/id_rsa.pub >> $rootfs_path/root/.ssh/authorized_keys
    lxc exec $name -- /bin/bash -c "chmod -R 600 /root/.ssh/authorized_keys"
  fi
}

function configure_autostart {
autostart=$1
name=$2

  if [ $autostart -eq 1 ]
  then
    lxc config set $name boot.autostart true
  else
    lxc config set $name boot.autostart false
  fi
}

die() {
msg=$1
   echo "$msg"
   exit -1
}

function info {
cid=$1
name=$2
IPv4=$3

  echo To setup port forwarding from outside, please run:
  echo ./tunnelport.sh $cid 22
  echo ./initWebproxy.sh $cid www.$name.de
  echo
  echo To start the container, run: lxc start $name
  echo
  echo "To connect to the container locally, run: eval \`ssh-agent\`; ssh-add; ssh root@$IPv4"

}

function getOutwardInterface {
  local interface=eth0
  # interface can be eth0, or p10p1, etc
  if [ -f /etc/network/interfaces ]
  then
    interface=`cat /etc/network/interfaces | grep "auto" | grep -v "auto lo" | awk '{ print $2 }'`
  fi
  if [ -z $interface ]
  then
    interface=`ip route|grep default | head -n 1 | awk '{print $8}'`
  fi
  bionic=`cat /etc/lsb-release  | grep bionic`
  if [ ! -z $bionic ]
  then
    # Ubuntu Bionic
    interface=`ip route|grep default | head -n 1 | awk '{print $5}'`
  fi
  echo $interface
}

function getBridgeInterface {
  echo "lxdbr0"
}

function getIPOfInterface {
interface=$1
  # works on Ubuntu 18.04
  local HostIP=`ip a show ${interface} | grep "inet " | awk '{ print $2 }' | awk -F '/' '{ print $1 }'`
  echo "$HostIP"
}

function getOSOfContainer {
rootfs=$1
  if [ -f $rootfs/etc/redhat-release ]
  then
    # CentOS
    version="`cat $rootfs/etc/redhat-release`"
  elif [ -f $rootfs/etc/lsb-release ]
  then
    # Ubuntu
    . $rootfs/etc/lsb-release
    version="$DISTRIB_DESCRIPTION"
  elif [ -f $rootfs/etc/debian_version ]
  then
    # Debian
    version="Debian `cat $rootfs/etc/debian_version`"
  fi

  # remove release and Linux
  tmp="${version/Linux/}"
  tmp="${tmp/release/}"
  OS=`echo $tmp | awk '{print $1}'`
  OSRelease=`echo $tmp | awk '{print $2}'`
  if [[ "$OS" == "Ubuntu" ]]
  then
    OSRelease=`echo $OSRelease | awk -F. '{print $1 "." $2}'`
  else
    OSRelease=`echo $OSRelease | awk -F. '{print $1}'`
  fi
}

function createContainerName {
name=$1
cid=$2

  # cannot have dots in the name, replace with hyphen
  name="${name//\./-}"

  # we let the name start with the digit, to make it easier to look at the list
  if [[ ! $name = l$cid* && ! $name = $cid* && ! $name = l`printf "%03d" $cid`* ]]
  then
    name='l'`printf "%03d" $cid`-$name
  fi

  # must not start with a digit
  if [[ ! $name = l* ]]
  then
    name='l'$name
  fi

  echo $name
}

function createHostName {
name=$1
cid=$2

  # we let the name start with the digit, to make it easier to look at the list
  if [[ ! $name = l$cid* && ! $name = $cid* && ! $name = l`printf "%03d" $cid`* ]]
  then
    name='l'`printf "%03d" $cid`-$name
  fi

  echo $name
}
