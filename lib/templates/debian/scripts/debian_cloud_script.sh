#!/bin/bash
###########################################################
#############INITIALIZATION SCRIPT FOR DEBIAN##############
######################CESNET CLOUD#########################
###########################################################

mv /root/cerit-cloudinit.list /etc/apt/sources.list.d/cerit-cloudinit.list
apt-key add /root/RPM-GPG-KEY-CERIT-SC.cfg
rm -f /root/RPM-GPG-KEY-CERIT-SC.cfg

apt-get update
apt-get --assume-yes upgrade
apt-get --assume-yes install sudo
apt-get --assume-yes install mingetty
apt-get --assume-yes install cloud-init
apt-get --assume-yes install qemu-guest-agent
apt-get --assume-yes install fail2ban ntp
DEBIAN_FRONTEND=noninteractive apt-get --assume-yes install -q -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" heimdal-clients libpam-heimdal
apt-get --assume-yes install vim git


# Enable services
if [ "x$(lsb_release -rs)" == "x7.8" ]; then
  insserv cloud-init-local
  insserv cloud-init
  insserv cloud-config
  insserv cloud-final
  rm /root/getty\@ttyS0.service
else
  systemctl enable ntp
  systemctl enable cloud-init-local
  systemctl enable cloud-init
  systemctl enable cloud-config
  systemctl enable cloud-final
  rm /etc/cloud/cloud.cfg.d/90_dpkg.cfg
  mv /root/getty\@ttyS0.service /etc/systemd/system/getty.target.wants/getty@ttyS0.service
  ln -s /etc/systemd/system/getty\@ttyS0.service /etc/systemd/system/getty.target.wants/getty@ttyS0.service
fi

mv /root/ntp.conf /etc/ntp.conf
mv /root/cloud.cfg /etc/cloud/cloud.cfg
mv /root/krb5.conf /etc/krb5.conf
mv /root/sshd_config /etc/ssh/sshd_config
mv /root/interfaces /etc/network/interfaces
mv /root/10-ipv6.conf /etc/sysctl.d/10-ipv6.conf
mv /root/grub /etc/default/grub
mv /root/inittab /etc/inittab

# fail2ban
mv /root/iptables-multiport.local /etc/fail2ban/action.d/iptables-multiport.local
mv /root/jail.local /etc/fail2ban/jail.local
mv /root/fail2ban.local /ect/fail2ban/fail2ban.local

# pakiti-2-client
dpkg -i pakiti_2.1.5-2_all.deb

update-grub

ln -s /dev/null /etc/udev/rules.d/75-persistent-net-generator.rules

passwd -d root

rm -f ~/.bash_history
rm -f /var/log/cloud-init*
