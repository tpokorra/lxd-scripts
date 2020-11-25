Purpose
-------

These scripts are useful to manage your own server, with several Linux containers.

Installation
------------

* Either clone this code repository: `cd ~; git clone https://github.com/tpokorra/lxd-scripts.git scripts`
* You need to install these dependencies:

    # For Ubuntu:
    apt-get install lxd lxd-client lxc-utils cgroup-lite python3-lxc bsdmainutils cron patch debootstrap

    # For Fedora:
    dnf install lxd lxd-client lxc-utils gpg libvirt tar rsync net-tools debootstrap crontabs

* Or install a package from LBS: https://lbs.solidcharity.com/package/tpokorra/lbs/lxd-scripts
 * There is a lxd-scripts package for Ubuntu 18.04 (Bionic) and Ubuntu 20.04 (Focal), and latest Fedora, with instructions how to install the package
 * To make things easier, I usually create a symbolic link: `cd ~; ln -s /usr/share/lxd-scripts scripts`

After installing the package, run these scripts for initializing the firewall and LXD:

    /usr/share/lxd-scripts/initLXD.sh
    /usr/share/lxd-scripts/initIPTables.sh

CheatSheet for my LXD scripts
---------------------------------

* Initialise the host IPTables so that they will be survive a reboot: `~/scripts/initIPTables.sh`
* Setup of LXD, and create ssh keys: `~/scripts/initLXD.sh`
* Create a container (with networking etc): `~/scripts/initFedora.sh $name $id`
 * Call the script without parameters to see additional parameters, eg to specify the version of the OS etc: `~/scripts/initFedora.sh`
 * There are scripts for creating Fedora, CentOS, Debian, and Ubuntu containers
* Containers are created in `/var/lib/lxd/containers/$name`, see the directory `rootfs`
* or with the LXD snap, see `/var/snap/lxd/common/lxd/storage-pools/default/containers/`
* Start a container: `lxc start $name`
* Start a container with console: `lxc console $name`
* Attach to the container: `lxc exec $name -- /bin/bash`
* Stop a container: `lxc stop $name`
* Destroy a container: `lxc delete $name`
* Enable Auto-start for a container: `lxc config set $name boot.autostart true`
* List all containers, with running state and IP address: `lxc list`
 * alternatively, there is this script: `~/scripts/listcontainers.sh`
 * this also shows the OS of the container
 * ~/scripts/listcontainers.sh running: shows only running containers
 * ~/scripts/listcontainers.sh stopped: shows only stopped containers
* Stop all containers: `~/scripts/stopall.sh`
