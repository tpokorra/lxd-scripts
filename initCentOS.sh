#!/bin/bash

SCRIPTSPATH=`dirname ${BASH_SOURCE[0]}`
source $SCRIPTSPATH/lib.sh

distro="centos"
release="7"

if [ -z $2 ]
then
  echo "please call $0 <name of new container> <cid> <release, default is $release> <arch, default is amd64> <autostart, default is 1>"
  echo "   eg. $0 l050-$distro-mymachine 50"
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

rootfs_path=/var/lib/lxd/containers/$name/rootfs
bridgeInterface=$(getBridgeInterface) || die "cannot find the bridge interface"
bridgeAddress=$(getIPOfInterface $bridgeInterface) || die "cannot find the address for the bridge $bridgeInterface"
networkAddress=$(echo $bridgeAddress | cut -f1,2,3 -d".")
IPv4=$networkAddress.$cid

lxc init images:$distro/$release/$arch $name
sed -i "s/,/,$IPv4,/g" /var/lib/lxd/networks/lxdbr0/dnsmasq.hosts/$name
sudo killall -SIGHUP dnsmasq

ssh-keygen -f "/root/.ssh/known_hosts" -R $IPv4

# mount yum cache repo, to avoid redownloading stuff when reinstalling the machine
hostpath="/var/lib/repocache/$cid/$distro/$release/$arch/var/cache/yum"
$SCRIPTSPATH/initMount.sh $hostpath $name "/var/cache/yum"

# configure timezone
cd $rootfs_path/etc; rm -f localtime; ln -s ../usr/share/zoneinfo/Europe/Berlin localtime; cd -

# yum: keep the cache
sed -i 's/^keepcache=0/keepcache=1/g' $rootfs_path/etc/yum.conf

# install openssh-server
lxc start $name
sleep 5
lxc exec $name -- /bin/bash -c "yum -y install openssh-server && systemctl enable sshd && systemctl start sshd"

# drop root password completely
lxc exec $name -- passwd -d root
# disallow auth with null password
lxc exec $name -- sed -i 's/nullok//g' /etc/pam.d/system-auth

lxc stop $name

install_public_keys $rootfs_path

configure_autostart $autostart $rootfs_path

info $cid $name $IPv4

