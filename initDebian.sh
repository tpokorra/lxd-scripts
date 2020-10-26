#!/bin/bash
SCRIPTSPATH=`dirname ${BASH_SOURCE[0]}`
source $SCRIPTSPATH/lib.sh

distro="debian"
release="buster"

if [ -z $2 ]
then
  echo "please call $0 <name of new container> <cid> <release, default is $release> <arch, default is amd64> <autostart, default is 1>"
  echo "   eg. $0 mymachine.example.org 50"
  exit 1
fi
name=$1
cid=$2
if [ ! -z $3 ]
then
  release=$3
fi
arch="amd64"
if [ ! -z $4 ]
then
  arch=$4
fi
autostart=1
if [ ! -z $5 ]
then
  autostart=$5
fi

origname=$name
name=$(createContainerName $name $cid)
hostname=$(createHostName $origname $cid)

rootfs_path=$container_path/$name/rootfs
bridgeInterface=$(getBridgeInterface)
bridgeAddress=$(getIPOfInterface $bridgeInterface)
networkAddress=$(echo $bridgeAddress | awk -F '.' '{ print $1"."$2"."$3 }')
IPv4=$networkAddress.$cid

lxc init images:$distro/$release/$arch $name
lxc network attach lxdbr0 $name eth0 eth0
lxc config device set $name eth0 ipv4.address $IPv4

# fix issue with mariadb on Debian Buster
# mariadb.service: Failed to set up mount namespacing: Permission denied
lxc config set $name security.nesting true

ssh-keygen -f "/root/.ssh/known_hosts" -R $IPv4

# mount apt cache repo, to avoid redownloading stuff when reinstalling the machine
#hostpath="/var/lib/repocache/$cid/$distro/$release/$arch/var/cache/apt"
#$SCRIPTSPATH/initMount.sh $hostpath $name "/var/cache/apt"

# configure timezone
cd $rootfs_path/etc && rm -f localtime && ln -s ../usr/share/zoneinfo/Europe/Berlin localtime && cd -

lxc start $name
sleep 5

# install openssh-server
lxc exec $name -- /bin/bash -c "apt-get update && apt-get install -y openssh-server"
lxc exec $name -- /bin/bash -c "hostnamectl set-hostname $hostname"

# drop root password completely
chroot $rootfs_path passwd -d root

install_public_keys $rootfs_path $name

configure_autostart $autostart $name

info $cid $name $IPv4

lxc stop $name
