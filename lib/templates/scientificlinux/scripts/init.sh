#!/usr/bin/env bash

# add EPEL repository
yum -y install http://ftp.astral.ro/mirrors/fedora/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
# update already installed packages
yum -y update
# install new packages
yum -y install cloud-init
yum -y install fail2ban ntp
yum -y install qemu-guest-agent
yum -y install krb5-libs krb5-workstation pam_krb5
yum -y install vim git
yum -y remove chrony

# set cloud-init to start after boot
systemctl enable cloud-init-local
systemctl enable cloud-init
systemctl enable cloud-config
systemctl enable cloud-final

# NTPd start after boot
systemctl enable ntpd.service

# move configuration file to their right place
mv /root/cloud.cfg /etc/cloud/cloud.cfg
mv /root/krb5.conf /etc/krb5.conf
mv /root/sshd_config /etc/ssh/sshd_config
mv /root/10-ipv6.conf /etc/sysctl.d/10-ipv6.conf
mv /root/grub /etc/default/grub
mv /root/getty\@ttyS0.service /etc/systemd/system/getty\@ttyS0.service
grub2-mkconfig -o /boot/grub2/grub.cfg
ln -s /etc/systemd/system/getty\@ttyS0.service /etc/systemd/system/getty.target.wants/getty@ttyS0.service
mv /root/ntp.conf /etc/ntp.conf
mv /root/xen-domU.conf /etc/dracut.conf.d/xen-domU.conf

# fail2ban
mv /root/iptables-multiport.local /etc/fail2ban/action.d/iptables-multiport.local
mv /root/jail.local /etc/fail2ban/jail.local
mv /root/fail2ban.local /etc/fail2ban/fail2ban.local

# pakiti-2-client
rpm -i pakiti-2.1.5-1.noarch.rpm
rm -f pakiti-2.1.5-1.noarch.rpm

# check-mk-agent
yum -y install check-mk-agent
rpm -i check-mk-agent-meta-key-1.0-1.noarch.rpm
rpm -i check-mk-agent-meta-checks-2.0-1.noarch.rpm

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

#remove chrony to enable NTP service
rpm -e chrony

# allow to use sudo via ssh
chmod u+w /etc/sudoers
sed -i s/'Defaults    requiretty'/'#Defaults    requiretty'/g /etc/sudoers
chmod -w /etc/sudoers

#regenerate initrd files
dracut -f

# disable root login with password
passwd -d root

rm -f ~/.bash_history
rm -f /var/log/cloud-init*

