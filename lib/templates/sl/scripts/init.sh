#!/usr/bin/env bash

# add EPEL repository
yum -y install http://ftp.astral.ro/mirrors/fedora/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
# update already installed packages
yum -y update
# install new packages
yum -y install cloud-init
yum -y install qemu-guest-agent
yum -y install krb5-libs krb5-workstation pam_krb5
yum -y install vim git

# set cloud-init to start after boot
systemctl enable cloud-init-local
systemctl enable cloud-init
systemctl enable cloud-config
systemctl enable cloud-final

# move configuration file to their right place
mv /root/cloud.cfg /etc/cloud/cloud.cfg
mv /root/krb5.conf /etc/krb5.conf
mv /root/sshd_config /etc/ssh/sshd_config

# remove hardware address (MAC) and UUID from NIC configuration files
sed -i '/^HWADDR/d' /etc/sysconfig/network-scripts/ifcfg-eth*
sed -i '/^UUID/d' /etc/sysconfig/network-scripts/ifcfg-eth*

# make sure nothing is messing with NICs' MAC adresses
unlink /etc/udev/rules.d/70-persistent-net.rules
ln -s /dev/null /etc/udev/rules.d/70-persistent-net.rules
unlink /etc/udev/rules.d/70-persistent-cd.rules
ln -s /dev/null /etc/udev/rules.d/70-persistent-cd.rules

# create configuration for second NIC if it's missing
if [ ! -f /etc/sysconfig/network-scripts/ifcfg-eth1 ]; then
  sed 's/eth0/eth1/g' /etc/sysconfig/network-scripts/ifcfg-eth0 > /etc/sysconfig/network-scripts/ifcfg-eth1
fi

# enable built-in networking
# using both commands because of unfinished systemd support in system
systemctl enable network
chkconfig network on

# disable NetworkManager
systemctl disable NetworkManager

# allow to use sudo via ssh
chmod u+w /etc/sudoers
sed -i s/'Defaults    requiretty'/'#Defaults    requiretty'/g /etc/sudoers
chmod -w /etc/sudoers

# disable root login with password
passwd -d root

rm -f ~/.bash_history
rm -f /var/log/cloud-init*

