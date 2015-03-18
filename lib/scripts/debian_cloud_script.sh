#!/bin/bash
###########################################################
#############INITIALIZATION SCRIPT FOR DEBIAN##############
######################CESNET CLOUD#########################
###########################################################

# What OS it is? 
OS=$(lsb_release -si)

case $OS in

  'Debian')

    # Download and install cloud-init and dependencies
#    apt-get --assume-yes install python
#    apt-get --assume-yes install build-essential
#    apt-get --assume-yes install -f

    wget apt.cerit-sc.cz/cloud-init/pool/main/p/python-json-patch/python-jsonpatch_1.3-4_all.deb
    wget apt.cerit-sc.cz/cloud-init/pool/main/p/python-json-pointer/python-json-pointer_1.0-2_all.deb
    wget apt.cerit-sc.cz/cloud-init/pool/main/c/cloud-init/cloud-init_0.7.5~bzr934-1_all.deb

    dpkg -i python-json-pointer_1.0-2_all.deb
    apt-get --assume-yes install -f 
    dpkg -i python-jsonpatch_1.3-4_all.deb
    apt-get --assume-yes install -f
    dpkg -i cloud-init_0.7.5~bzr934-1_all.deb
    apt-get --assume-yes install -f

    # Enable services
    insserv cloud-init-local
    insserv cloud-init
    insserv cloud-config
    insserv cloud-final

    # Download cloud config file for deb
    wget aisa.fi.muni.cz/~xkosaris/cesnet/debian/cloud.cfg
    mv cloud.cfg /etc/cloud
    ;;

esac

exit 0
