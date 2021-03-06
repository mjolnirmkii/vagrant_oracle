# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi

# User specific environment and startup programs

PATH=$PATH:$HOME/.local/bin:$HOME/bin

export TMP=/tmp
export TMPDIR=$TMP

export ORACLE_BASE=/opt/oracle
export ORACLE_HOME=$ORACLE_BASE/product/12.2.0.1/db_1
export ORACLE_SID=ORACLEDB
export ORACLE_PDB=ORACLEPDB1
export ORACLE_CHARACTERSET=AL32UTF8

export PATH=$PATH:$ORACLE_HOME/bin

#. /home/oracle/scripts/setEnv.sh