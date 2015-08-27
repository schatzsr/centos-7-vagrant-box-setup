#!/bin/bash
# Usage: source dev_setup.sh
#   We need to use "source" so that the everything will run in the executing terminal.
#   This is necessary for the Python virtual environment steps.
# Performs necessary installations to develop Python/Django web applications
#   that run on Apache HTTPd and connect to Microsoft SQL Server backends.

# Set SELinux to permissive, so it doesn't block any of our actions
sed -i -e 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config

# Install the Extra Packages for Enterprise Linux repo (EPEL)
cd /tmp
yum -y install wget
wget http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
yum -y install epel-release-7-5.noarch.rpm

# This installs Apache 2.4.6 and ‘-devel’ packages that are
#  needed to compile or develop modules for Apache, such as mod_wsgi.
yum -y install httpd httpd-devel apr-devel apr-util-devel

yum -y groupinstall "Development tools"
yum -y install zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gdbm-devel db4-devel libpcap-devel xz-devel # Libs to have a properly functioning Python interpreter
cd /opt/
mkdir python-3.3  # Where the new Python will go
cd python-3.3
# We need to make the lib directory explicitly so the LDFLAGS parameter in the configure step will work
mkdir lib
wget http://python.org/ftp/python/3.3.5/Python-3.3.5.tar.xz # Download Python 3.3.5
tar xf Python-3.3.5.tar.xz # unzip
cd Python-3.3.5

# Causes Python to be compiled as a shared library, and how to find it.
./configure --prefix=/opt/python-3.3 --enable-shared LDFLAGS="-Wl,-rpath /opt/python-3.3/lib"

make # Performs build operation

# Note: If there are any module warnings when attempting to "make", then you will need to find the appropriate '-devel' packages to install.

# Use altinstall so the default Python is not overwritten, because some system tools rely on it.
make altinstall

# Add the folder containing the Python 3 executable so we can call the Python 3.3.5 interpreter anywhere by entering "python3.3"
export PATH=$PATH:/opt/python-3.3/bin # THIS IS WRONG - IS NOT PERMANENT. NEED TO CORRECT.
 
# Install the FreeTDS library/driver that allows connections between Linux machines and Microsoft SQL Server backends.
yum -y install freetds
yum -y install unixODBC-devel # This will be used by the PYODBC Python package (installed later)
yum -y install libpqxx-devel # Needed for the psycopg2 Python package installed later.

# Install PostgreSQL, start server, create database
yum -y install postgresql-server
service postgresql initdb # initialize database environment
chkconfig postgresql on # configure to start at boot up
service postgresql start # start postgresql server

# Mod_WSGI Install
cd /opt
# Download mod_wsgi source (or use whatever release is most recent, found here: https://github.com/GrahamDumpleton/mod_wsgi/releases
wget https://github.com/GrahamDumpleton/mod_wsgi/archive/4.4.5.tar.gz
tar xvfz 4.4.5.tar.gz
cd mod_wsgi-4.4.5
./configure --with-python=/opt/python-3.3/bin/python3.3
LD_RUN_PATH=/opt/python-3.3/lib make # Builds Mod_wsgi by explicitly stating where to find the shared Python library
make install
 
# Python Virtual Environment Setup
cd /opt
mkdir apps
cd apps
mkdir pyvirtualenvs
cd pyvirtualenvs
# Create the virtual environment. "pyvenv-3.3" resides in /opt/python-3.3/bin/, which we added to the PATH, so we can call it anywhere
pyvenv-3.3 django1.7dev # Or whatever name you would like to call the venv, instead of django1.7dev
source /opt/apps/pyvirtualenvs/django1.7dev/bin/activate
cd django1.7dev
mkdir pip
cd pip
# Pip is the package installer for Python
wget https://bootstrap.pypa.io/get-pip.py
# When the Python virtual environment is activated, we can simply type "python" instead of "python3.3" because the venv was made using Python 3.3
python get-pip.py
 
# Install Python packages required for Django development
pip install https://pyodbc.googlecode.com/files/pyodbc-3.0.7.zip # unixODBC-devel must be installed for this to work
pip install Django==1.7
pip install django-pyodbc-azure==1.2.0
pip install djangorestframework==3.1.1
pip install ipython # A good python interpreter with useful features such as autocomplete. To use, type ipython while the venv is activated.
pip install psycopg2 # Allows Django to use Postgres
deactivate

# EVERYTHING BELOW WAS BASED ON THIS: http://thornelabs.net/2013/11/11/create-a-centos-6-vagrant-base-box-from-scratch-using-virtualbox.html

# Make sure ntp is installed
yum -y install ntp
# Enable the ntpd service to start on boot
chkconfig ntpd on
# Set the time
service ntpd stop
ntpdate time.nist.gov
service ntpd start

# Enable the ssh service to start on boot
chkconfig sshd on

# Disable the iptables and ip6tables services from starting on boot. These may not be present.
chkconfig iptables off
chkconfig ip6tables off

# Create vagrant user's .ssh folder
mkdir -m 0700 -p /home/vagrant/.ssh

# Vagrant's public key used for ssh
curl https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub >> /home/vagrant/.ssh/authorized_keys

# Change permissions on the key to be more restrictive
chmod 600 /home/vagrant/.ssh/authorized_keys

# Comment out requiretty in /etc/sudoers. This allows ssh to send remote commands using sudo. Without this change vagrant will be unable to apply changes (such as configuring additional NICs) at startup.
sed -i 's/^\(Defaults.*requiretty\)/#\1/' /etc/sudoers

# Allow user vagrant to use sudo without entering a password.
echo "vagrant ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Allow ports through the firewall so we can access them on our host machine.
firewall-cmd --permanent --zone=dmz --zone=public --add-port=80/tcp
firewall-cmd --permanent --zone=dmz --zone=public --add-port=8080/tcp
firewall-cmd --permanent --zone=dmz --zone=public --add-port=8008/tcp
firewall-cmd --permanent --zone=dmz --zone=public --add-port=443/tcp
firewall-cmd --permanent --zone=dmz --zone=public --add-port=5432/tcp
firewall-cmd --reload


# AFTER THIS SCRIPT RUNS YOU WILL NEED TO DO THE FOLLOWING:
# Change /etc/sysconfig/network-scripts/ifcfg-enp0s3 to contain:
#  DEVICE=enp0s3
#  TYPE=Ethernet
#  ONBOOT=yes
#  NM_CONTROLLED=no
#  BOOTPROTO=dhcp

# IF EVERYTHING IS SUCCESSFUL, RUN THE FOLLOWING:
# yum clean all
# rm -rf /tmp/*
# rm -f /var/log/wtmp /var/log/btmp
# history -c
# shutdown -h now
# In the Virtualbox Manager, go to the vm’s Settings >> Storage >> Select Controller: IDE >> Click the green square with red minus icon in the lower right hand corner >> Click OK to close the Settings menu.
# The vagrant box can now be created.
