#!/bin/bash

OS="unknown"
if [ -f /etc/os-release ]; then
  . /etc/os-release
  OS=$NAME
fi

# create a key pair for ssh into the container as root
if [ ! -f /root/.ssh/id_rsa ]
then
  ssh-keygen -t rsa -C "root@localhost"
fi

# create a new, unique Diffie-Hellman group, to fight the Logjam attack: https://weakdh.org/sysadmin.html
if [ ! -f /var/lib/certs/dhparams.pem ]
then
  mkdir -p /var/lib/certs
  openssl dhparam -out /var/lib/certs/dhparams.pem 2048
fi

# install a cronjob that checks the expiry date of ssl certificates and installs a new letsencrypt certificate
if [ ! -f /etc/cron.d/letsencrypt ]
then
  echo "5 8 * * 6 root PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin cd /usr/share/lxd-scripts && ./letsencrypt.sh all" > /etc/cron.d/letsencrypt
fi

if [ ! -f /usr/bin/lc -a -f /usr/share/lxd-scripts/listcontainers.sh ]
then
  ln -s /usr/share/lxd-scripts/listcontainers.sh /usr/bin/lc
fi

# see https://documentation.ubuntu.com/lxd/en/latest/howto/network_create/
# see https://documentation.ubuntu.com/lxd/en/latest/reference/network_bridge/#network-bridge
lxc network create lxdbr0 ipv6.address=none ipv4.address=10.0.4.1/24 ipv4.nat=true
lxd init --auto

if [[ "$OS" == "CentOS" || "$OS" == "Fedora" ]]
then
  dnf install -y crontabs
  systemctl enable crond || exit -1
  systemctl start crond || exit -1
  firewall-cmd --permanent --zone=trusted --change-interface=lxdbr0
  # allow DNS
  firewall-cmd --permanent --zone=trusted --add-port=53/tcp
  firewall-cmd --reload
elif [[ "$OS" == "Debian" || "$OS" == "Ubuntu" ]]
then
  systemctl enable cron || exit -1
  systemctl start cron || exit -1
fi
