#!/bin/bash

for d in /var/lib/lxd/containers/*
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

