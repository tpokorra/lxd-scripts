#!/bin/bash

if [ -z $3 ]
then
  echo "please call $0 <hostpath> <containername> <localpath>"
  exit 1
fi

hostpath=$1
containername=$2
localpath=$3
relativepath=${localpath:1}
containerpath=/var/lib/lxd/containers/$containername/rootfs/$relativepath
mountname="${relativepath//\//_}"

mkdir -p $hostpath
chmod -R a+rwx $hostpath
rm -Rf $containerpath
mkdir -p $containerpath

lxc config device add $containername $mountname disk source=$hostpath/ path=$localpath
