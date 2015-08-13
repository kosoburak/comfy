#!/usr/bin/env bash

apt-get update

apt-get --assume-yes install qemu-guest-agent
apt-key add /root/RPM-GPG-KEY-CERIT-SC.cfg
rm -f /root/RPM-GPG-KEY-CERIT-SC.cfg
mv /root/meta-misc.list /etc/apt/sources.list.d/meta-misc.list
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
mv /root/modules /etc/initramfs-tools/modules

update-grub
start ttyS0

# fail2ban
mv /root/iptables-multiport.local /etc/fail2ban/action.d/iptables-multiport.local
mv /root/jail.local /etc/fail2ban/jail.local
mv /root/fail2ban.local /etc/fail2ban/fail2ban.local

# check-mk-agent
# mkdir /etc/check_mk
# touch /etc/check_mk/fileinfo.cfg

apt-get --assume-yes install check-mk-agent check-mk-agent-meta-key
apt-get --assume-yes install check-mk-agent-meta-checks

# pakiti-2-client
dpkg -i pakiti_2.1.5-2_all.deb
rm -f pakiti_2.1.5-2_all.deb

ln -s /dev/null /etc/udev/rules.d/75-persistent-net-generator.rules

update-initramfs -v -u -k `uname -r`

passwd -d root

rm -f ~/.bash_history
rm -f /var/log/cloud-init*
