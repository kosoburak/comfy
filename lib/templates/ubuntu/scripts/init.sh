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
DEBIAN_FRONTEND=noninteractive apt-get --assume-yes install -q -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" heimdal-clients libpam-heimdal
apt-get --assume-yes install vim git fail2ban ntp

mv /root/ntp.conf /etc/ntf.conf
mv /root/cloud.cfg /etc/cloud/cloud.cfg
mv /root/krb5.conf /etc/krb5.conf
mv /root/sshd_config /etc/ssh/sshd_config
mv /root/interfaces /etc/network/interfaces
mv /root/10-ipv6.conf /etc/sysctl.d/10-ipv6.conf
mv /root/ttyS0.conf /etc/init/ttyS0.conf
mv /root/grub /etc/default/grub

update-grub
start ttyS0

# fail2ban
mv /root/iptables-multiport.local /etc/fail2ban/action.d/iptables-multiport.local
mv /root/jail.local /etc/fail2ban/jail.local
mv /root/fail2ban.local /ect/fail2ban/fail2ban.local

# pakiti-2-client
dpkg -i pakiti_2.1.5-2_all.deb

ln -s /dev/null /etc/udev/rules.d/75-persistent-net-generator.rules

passwd -d root

rm -f ~/.bash_history
rm -f /var/log/cloud-init*
