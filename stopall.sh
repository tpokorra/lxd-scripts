#!/bin/bash

SCRIPTSPATH=/usr/share/lxd-scripts
if [[ "$0" == "./listcontainers.sh" ]]
then
  SCRIPTSPATH=`dirname ${BASH_SOURCE[0]}`
fi
source $SCRIPTSPATH/lib.sh

for d in $container_path/*
do
  rootfs=$d/rootfs

  if [ ! -d $rootfs ]
  then
    continue
  fi

  name=`basename $d`

  if [[ -z "`lxc list $name | grep RUNNING`" ]]
  then
    state="stopped"
  else
    state="running"
  fi

  if [[ "$state" == "running" ]]
  then
    echo "stopping $name ..."
    lxc exec $name -- poweroff
  fi
done

