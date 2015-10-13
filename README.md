Centos 7 Vagrant Box Setup
================

This is the setup I used to create a CentOS 7 Vagrant VM using Virtualbox, for a previous job and undergrad school-work.
The Vagrant box will enable development using Python 3.3, Django 1.7, Apache HTTPd 2.4, and connections to PostgreSQL or SQL Server backends (using FreeTDS).

###dev_setup.sh usage
```
chmod +x /opt/Centos7_DevSetup/dev_setup.sh
source /opt/Centos7_DevSetup/dev_setup.sh
```

#### After the script runs you will need to do the following:
Change `/etc/sysconfig/network-scripts/ifcfg-enp0s3` to contain:
```
DEVICE=enp0s3
TYPE=Ethernet
ONBOOT=yes
NM_CONTROLLED=no
BOOTPROTO=dhcp
```

#### If everything is successful, run the following:
```
yum clean all
rm -rf /tmp/*
rm -f /var/log/wtmp /var/log/btmp
history -c
shutdown -h now
```
In the Virtualbox Manager, go to the vm’s Settings >> Storage >> Select Controller: IDE >> Click the green square with red minus icon in the lower right hand corner >> Click OK to close the Settings menu.

The vagrant box can now be created using `vagrant package --output centos7.box --base centos7` *replace "centos7" with your vm's name*