#!/bin/bash
###########################################################
#############INITIALIZATION SCRIPT FOR DEBIAN##############
######################CESNET CLOUD#########################
###########################################################

# make sure lsb_release is installed
apt-get update
apt-get --assume-yes upgrade
apt-get --assume-yes install lsb-release

#DEB8 doesn't need cerit and jessie repo
if [[ $(lsb_release -rs) == 7.* ]]; then
  mv /root/cerit-cloudinit.list /etc/apt/sources.list.d/cerit-cloudinit.list
  mv /root/jessie.list /etc/apt/sources.list.d/jessie.list
  mv /root/jessie_cloud_init.pref /etc/apt/preferences.d/jessie_cloud_init.pref
  mv /root/depot_wheezy.list /etc/apt/sources.list.d/depot.list
  rm /root/depot_jessie.list
  mv /root/meta-misc_wheezy.list /etc/apt/sources.list.d/meta-misc.list
  rm /root/meta-misc_jessie.list
else
  rm /root/jessie.list
  rm /root/jessie_cloud_init.pref
  rm /root/cerit-cloudinit.list
  mv /root/depot_jessie.list /etc/apt/sources.list.d/depot.list
  rm /root/depot_wheezy.list
  mv /root/meta-misc_jessie.list /etc/apt/sources.list.d/meta-misc.list
  rm /root/meta-misc_wheezy.list
fi

apt-key add /root/RPM-GPG-KEY-CERIT-SC.cfg
rm -f /root/RPM-GPG-KEY-CERIT-SC.cfg
apt-key add /root/DEPOT-GPG-KEY.cfg
rm -f /root/DEPOT-GPG-KEY.cfg
mv /root/backports.list /etc/apt/sources.list.d/backports.list
mv /root/depot_all.pref /etc/apt/preferences.d/depot_all.pref
mv /root/depot_check_mk.pref /etc/apt/preferences.d/depot_check_mk.pref

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
if [[ $(lsb_release -rs) == 7.* ]]; then
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
  rm /etc/apt/sources.list.d/backports.list
  mv /root/getty\@ttyS0.service /etc/systemd/system/getty.target.wants/getty@ttyS0.service
  ln -s /etc/systemd/system/getty\@ttyS0.service /etc/systemd/system/getty.target.wants/getty@ttyS0.service
fi

rm /etc/cloud/cloud.cfg.d/90_dpkg.cfg
mv /root/ntp.conf /etc/ntp.conf
mv /root/cloud.cfg /etc/cloud/cloud.cfg
mv /root/krb5.conf /etc/krb5.conf
mv /root/sshd_config /etc/ssh/sshd_config
mv /root/interfaces /etc/network/interfaces
mv /root/10-ipv6.conf /etc/sysctl.d/10-ipv6.conf
mv /root/grub /etc/default/grub
mv /root/inittab /etc/inittab
mv /root/modules /etc/initramfs-tools/modules

# fail2ban
mv /root/iptables-multiport.local /etc/fail2ban/action.d/iptables-multiport.local
mv /root/jail.local /etc/fail2ban/jail.local
mv /root/fail2ban.local /etc/fail2ban/fail2ban.local

# pakiti-2-client
dpkg -i pakiti_2.1.5-2_all.deb
rm -f pakiti_2.1.5-2_all.deb

# check-mk-agent
apt-get --assume-yes install check-mk-agent check-mk-agent-meta-key
apt-get --assume-yes install check-mk-agent-meta-checks

update-grub

ln -s /dev/null /etc/udev/rules.d/75-persistent-net-generator.rules

update-initramfs -v -u -k `uname -r`

passwd -d root

rm -f ~/.bash_history
rm -f /var/log/cloud-init*
