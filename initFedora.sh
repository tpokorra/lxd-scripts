#!/bin/bash

SCRIPTSPATH=`dirname ${BASH_SOURCE[0]}`
source $SCRIPTSPATH/lib.sh

distro="fedora"
release="31"

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

# dnf: keep the cache
sed -i 's/^keepcache=0/keepcache=1/g' $rootfs_path/etc/dnf/dnf.conf

# use default locale
echo "export LANG=C" >> $rootfs_path/etc/profile

# install openssh-server
lxc start $name
sleep 10
lxc exec $name -- /bin/bash -c "dnf -y install openssh-server"
lxc exec $name -- /bin/bash -c "dnf -y install glibc-locale-source glibc-all-langpacks"

# drop root password completely
lxc exec $name -- passwd -d root
# disallow auth with null password
lxc exec $name -- /bin/bash -c "sed -i 's/nullok//g' /etc/pam.d/system-auth"

install_public_keys $rootfs_path $name

configure_autostart $autostart $name

info $cid $name $IPv4

lxc stop $name
