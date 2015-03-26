#!/usr/bin/env bash

apt-get update

if [ "x$(lsb_release -rs)" == "x12.04" ]; then
  apt-get --assume-yes install python-software-properties
  add-apt-repository -y ppa:iweb-openstack/cloud-init
else
  apt-get --assume-yes install qemu-guest-agent
fi

apt-get update
apt-get --assume-yes upgrade
apt-get --assume-yes install cloud-init
DEBIAN_FRONTEND=noninteractive apt-get --assume-yes install -q -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" heimdal-clients heimdal-servers libpam-heimdal

mv /root/cloud.cfg /etc/cloud/cloud.cfg
mv /root/krb5.conf /etc/krb5.conf
mv /root/sshd_config /etc/ssh/sshd_config

ln -s /dev/null /etc/udev/rules.d/75-persistent-net-generator.rules

passwd -d root

rm -f ~/.bash_history
rm -f /var/log/cloud-init*