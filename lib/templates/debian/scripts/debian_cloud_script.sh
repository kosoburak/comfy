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
apt-get --assume-yes install cloud-init
apt-get --assume-yes install qemu-utils
DEBIAN_FRONTEND=noninteractive apt-get --assume-yes install -q -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" heimdal-clients heimdal-servers libpam-heimdal

# Enable services
insserv cloud-init-local
insserv cloud-init
insserv cloud-config
insserv cloud-final

mv /root/cloud.cfg /etc/cloud/cloud.cfg
mv /root/krb5.conf /etc/krb5.conf
mv /root/sshd_config /etc/ssh/sshd_config

passwd -d root

rm -f ~/.bash_history
rm -f /var/log/cloud-init*