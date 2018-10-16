# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
ORACLE_BASE=/opt/oracle
ORACLE_HOME=$ORACLE_BASE/product/12.2.0.1/db_1
ORACLE_SID=ORACLEDB
ORACLE_PDB=ORACLEPDB1
ORACLE_CHARACTERSET=AL32UTF8
PATH=$PATH:$ORACLE_HOME/bin
