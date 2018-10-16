#!/usr/bin/env bash
user=$(who | awk -F' ' '{print $1}' | uniq)

uncleanExitMessage="Please run 'vagrant destroy' to delete your current VM that is in an inconsistent state before running 'vagrant up' again.\n"

#Wait 10 seconds to begin installations
echo -e "VAGRANT_INSTALLER: Beginning setup....\n"
sleep 10s
cd /vagrant

#Pre-installation steps
echo -e "VAGRANT_INSTALLER: Set hostname and hosts file...\n"
sudo hostname vagrantserver.local.dev
sudo sed -i '1s/^/127.0.0.1    vagrantserver\n/' /etc/hosts
sudo sed -i '1s/^/127.0.0.1    vagrantserver.local.dev\n/' /etc/hosts

#Disable SELinux
sudo sed -i "s/=enforcing/=disabled/g" /etc/sysconfig/selinux
sudo sed -i "s/=permissive/=disabled/g" /etc/sysconfig/selinux
sudo setenforce 0

#Setup Sudoers file
sudo cp -f /vagrant/local.sudoers /etc/sudoers.d/vagrant

#Install Oracle 12c
sudo chmod u+x install_oracle.sh
if [ -f /vagrant/oracle.dodeploy ];then
  ./install_oracle.sh
fi

echo "VAGRANT_INSTALLER: Complete..."
echo "VAGRANT_INSTALLER: If the script hangs at this point, it's safe to Ctrl+C out. You may then need to manually kill any Ruby processes in Windows Task Manager before you can run 'vagrant halt'"
exit
