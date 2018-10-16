#!/bin/bash

#Oracle install triples the amount of time the vagrant boot scripts take to complete all configurations.
ORACLE_BASE=/opt/oracle
ORACLE_HOME=$ORACLE_BASE/product/12.2.0.1/db_1
ORACLE_PRI_SID=ORACLEPRI
ORACLE_PRI_PDB=ORACLEPRIPDB1
ORACLE_BUS_SID=ORACLEDB
ORACLE__BUS_PDB=ORACLEPDB1
ORACLE_CHARACTERSET=AL32UTF8

echo "VAGRANT_INSTALLER: Installing Oracle 12c R2 database for Linux..."
cd /vagrant/

#Oracle installer present?
oracleFile=$(ls linuxx64_122*.zip)
if [ -f $oracleFile ];then
  chmod 777 $oracleFile
else
  echo -e "VAGRANT_INSTALLER: No Oracle installation zip file present... Exiting..."
  exit 1
fi

echo "VAGRANT_INSTALLER: Upgrading YUM Repositories and Dependencies to Oracle Linux..."
curl -O https://linux.oracle.com/switch/centos2ol.sh 
sudo sh centos2ol.sh
sudo yum upgrade -y

#Pre-install package installs software packages, dependencies, modifies Kernel parameters, and creates Oracle system users
echo "VAGRANT_INSTALLER: Install required dependencies for Oracle DB and Configure OS users and groups..."
sudo yum install oracle-database-server-12cR2-preinstall -y

echo "VAGRANT_INSTALLER: Configure additional OS Users and Groups..."
#sudo adduser oracle
#sudo groupadd -g 54324 oinstall
#sudo groupadd -g 54325 dba
sudo groupadd -g 54323 oper
sudo usermod -aG oinstall,dba,oper oracle
sudo echo "oracle" | sudo passwd --stdin oracle 

echo "VAGRANT_INSTALLER: Create directories for Oracle Installation..."
sudo mkdir $ORACLE_BASE
sudo chown -R oracle:oinstall $ORACLE_BASE

echo "VAGRANT_INSTALLER: Configure ENV VARs and PATHs for Oracle 12c..."
sudo -u oracle cp /vagrant/oracle/oracle.bash_profile /home/oracle/.bash_profile
sudo -u oracle cp /vagrant/oracle/oracle.bashrc /home/oracle/.bashrc

sudo chmod u+x /vagrant/oracle/profile_d_oracle.sh
sudo cp /vagrant/oracle/profile_d_oracle.sh /etc/profile.d/

# set bashrc environment variables
#sudo -u oracle echo "export ORACLE_BASE=$ORACLE_BASE" >> /home/oracle/.bashrc && \
#sudo -u oracle echo "export ORACLE_HOME=$ORACLE_HOME" >> /home/oracle/.bashrc && \
#sudo -u oracle echo "export ORACLE_SID=$ORACLE_SID" >> /home/oracle/.bashrc   && \
#sudo -u oracle echo "export PATH=\$PATH:\$ORACLE_HOME/bin" >> /home/oracle/.bashrc

# install Oracle
echo "VAGRANT_INSTALLER: Unzip Oracle Installation and Install Oracle..."
unzip /vagrant/linux*122*.zip -d /vagrant
cp /vagrant/oracle/ora-response/db_install.rsp.tmpl /vagrant/oracle/ora-response/db_install.rsp
sed -i -e "s|###ORACLE_BASE###|$ORACLE_BASE|g" /vagrant/oracle/ora-response/db_install.rsp && \
sed -i -e "s|###ORACLE_HOME###|$ORACLE_HOME|g" /vagrant/oracle/ora-response/db_install.rsp && \
sudo su -l oracle -c "yes | /vagrant/database/runInstaller -silent -showProgress -ignorePrereq -waitforcompletion -responseFile /vagrant/oracle/ora-response/db_install.rsp"
sudo $ORACLE_BASE/oraInventory/orainstRoot.sh
sudo $ORACLE_HOME/root.sh
rm -rf /vagrant/database
rm /vagrant/oracle/ora-response/db_install.rsp

# create listener via netca
#sudo su -l oracle -c "$ORACLE_HOME/bin/netca -silent -responseFile /vagrant/oracle/ora-response/netca.rsp"
#echo 'INSTALLER: Listener created'

# create business database
echo "VAGRANT_INSTALLER: Create an Oracle business database for use..."
cp /vagrant/oracle/ora-response/dbca.rsp.tmpl /vagrant/oracle/ora-response/dbca_bus.rsp
sed -i -e "s|###ORACLE_SID###|$ORACLE_BUS_SID|g" /vagrant/oracle/ora-response/dbca_bus.rsp && \
sed -i -e "s|###ORACLE_PDB###|$ORACLE_BUS_PDB|g" /vagrant/oracle/ora-response/dbca_bus.rsp && \
sed -i -e "s|###ORACLE_CHARACTERSET###|$ORACLE_CHARACTERSET|g" /vagrant/oracle/ora-response/dbca_bus.rsp
sudo su -l oracle -c "$ORACLE_HOME/bin/dbca -silent -createDatabase -responseFile /vagrant/oracle/ora-response/dbca_bus.rsp"
sudo su -l oracle -c "$ORACLE_HOME/bin/sqlplus / as sysdba <<EOF
   ALTER PLUGGABLE DATABASE $ORACLE_BUS_PDB SAVE STATE;
   exit;
EOF"
rm /vagrant/oracle/ora-response/dbca_bus.rsp

# create prmiary database
echo "VAGRANT_INSTALLER: Create an Oracle primary database for use..."
cp /vagrant/oracle/ora-response/dbca.rsp.tmpl /vagrant/oracle/ora-response/dbca.rsp
sed -i -e "s|###ORACLE_SID###|$ORACLE_PRI_SID|g" /vagrant/oracle/ora-response/dbca.rsp && \
sed -i -e "s|###ORACLE_PDB###|$ORACLE_PRI_PDB|g" /vagrant/oracle/ora-response/dbca.rsp && \
sed -i -e "s|###ORACLE_CHARACTERSET###|$ORACLE_CHARACTERSET|g" /vagrant/oracle/ora-response/dbca.rsp
sudo su -l oracle -c "$ORACLE_HOME/bin/dbca -silent -createDatabase -responseFile /vagrant/oracle/ora-response/dbca.rsp"
sudo su -l oracle -c "$ORACLE_HOME/bin/sqlplus / as sysdba <<EOF
   ALTER PLUGGABLE DATABASE $ORACLE_PRI_PDB SAVE STATE;
   exit;
EOF"
rm /vagrant/oracle/ora-response/dbca.rsp

echo "VAGRANT_INSTALLER: Configure Oratab..."
sudo sed '$s/N/Y/' /etc/oratab | sudo tee /etc/oratab > /dev/null

# configure systemd to start oracle instance on startup
echo "VAGRANT_INSTALLER: Configure Oracle as an OS service for startups and shutdowns..."
sudo cp /vagrant/oracle/oracle-rdbms.service /etc/systemd/system/
sudo sed -i -e "s|###ORACLE_HOME###|$ORACLE_HOME|g" /etc/systemd/system/oracle-rdbms.service
sudo systemctl daemon-reload
sudo systemctl enable oracle-rdbms
sudo systemctl start oracle-rdbms

echo "VAGRANT_INSTALLER: Oracle 12c R2 installation... Done..."
#sqlplus /nolog
