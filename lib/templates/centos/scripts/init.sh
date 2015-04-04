#!/usr/bin/env bash

yum -y install http://ftp.astral.ro/mirrors/fedora/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
yum -y update
yum -y install cloud-init
yum -y install qemu-guest-agent
yum -y install krb5-libs krb5-workstation pam_krb5
yum -y install vim git

systemctl enable cloud-init-local
systemctl enable cloud-init
systemctl enable cloud-config
systemctl enable cloud-final

mv /root/cloud.cfg /etc/cloud/cloud.cfg
mv /root/krb5.conf /etc/krb5.conf
mv /root/sshd_config /etc/ssh/sshd_config
mv /root/10-ipv6.conf /etc/sysctl.d/10-ipv6.conf

passwd -d root

rm -f ~/.bash_history
rm -f /var/log/cloud-init*
