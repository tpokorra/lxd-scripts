#!/bin/bash

SCRIPTSPATH=`dirname ${BASH_SOURCE[0]}`
source $SCRIPTSPATH/lib.sh

# see https://jenkins.linuxcontainers.org/job/image-rockylinux/
distro="rockylinux"
release="8"

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
bridgeInterface=$(getBridgeInterface) || die "cannot find the bridge interface"
bridgeAddress=$(getIPOfInterface $bridgeInterface) || die "cannot find the address for the bridge $bridgeInterface"
networkAddress=$(echo $bridgeAddress | cut -f1,2,3 -d".")
IPv4=$networkAddress.$cid

lxc init images:$distro/$release/$arch $name
lxc network attach lxdbr0 $name eth0 eth0
lxc config device set $name eth0 ipv4.address $IPv4

ssh-keygen -f "/root/.ssh/known_hosts" -R $IPv4

# mount yum cache repo, to avoid redownloading stuff when reinstalling the machine
#hostpath="/var/lib/repocache/$cid/$distro/$release/$arch/var/cache/yum"
#$SCRIPTSPATH/initMount.sh $hostpath $name "/var/cache/yum"

# configure timezone
cd $rootfs_path/etc && rm -f localtime && ln -s ../usr/share/zoneinfo/Europe/Berlin localtime && cd -

# yum: keep the cache
sed -i 's/^keepcache=0/keepcache=1/g' $rootfs_path/etc/yum.conf

# install openssh-server
lxc start $name
sleep 5
lxc exec $name -- dhclient
lxc exec $name -- /bin/bash -c "yum -y install openssh-server && systemctl enable sshd && systemctl start sshd"
lxc exec $name -- /bin/bash -c "hostnamectl set-hostname $hostname"

# drop root password completely
lxc exec $name -- passwd -d root
# disallow auth with null password
lxc exec $name -- sed -i 's/nullok//g' /etc/pam.d/system-auth

install_public_keys $rootfs_path $name

configure_autostart $autostart $name

info $cid $name $IPv4

lxc stop $name

