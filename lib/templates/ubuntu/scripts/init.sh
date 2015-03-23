#!/usr/bin/env bash

if [ "x$(lsb_release -rs)" == "x12.04" ]; then
  add-apt-repository ppa:iweb-openstack/cloud-init
fi

apt-get update
apt-get --assume-yes upgrade
apt-get --assume-yes install cloud-init
DEBIAN_FRONTEND=noninteractive apt-get --assume-yes install -q -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" heimdal-clients heimdal-servers libpam-heimdal

mv /root/cloud.cfg /etc/cloud/cloud.cfg
mv /root/krb5.conf /etc/krb5.conf
mv /root/sshd_config /etc/ssh/sshd_config

passwd -d root

rm -f ~/.bash_history
rm -f /var/log/cloud-init*