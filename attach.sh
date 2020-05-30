#!/bin/bash

name=$1

lxc exec $1 -- /bin/bash
