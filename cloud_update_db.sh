#!/bin/sh

set -xv

if [[ "$#" -lt 1 ]]
then
  echo "ERROR: specify at least 1 hmc name"
  exit 1
fi

# Set timestamp for filenames

CURR_DATE=`date +%Y-%m-%d`
DBUSER=root
DBPASS=mariadbpwd
DBHOST=localhost
PASSWD=`echo c3RhcnQxMjM0Cg== | base64 -d`
HMCLIST=$@

# Create backup of current DB content

mysqldump -h ${DBHOST} -u ${DBUSER} -p${DBPASS} sap > /srv/www/htdocs/scripts/sap_db_backup_${CURR_DATE}.sql

########################################################################
# Get lpar details for lpar_ms table
########################################################################

function get_lpar_ms_table()
{
for HMC in `echo ${HMCLIST}`
do
  sshpass -p ${PASSWD} ssh -q -T hscroot@${HMC} << '_ENDSSH_'
  for ms in `lssyscfg -r sys -F name,state,type_model,serial_num | grep Operating | egrep -v "No Connection|Mismatch|Power|HSCL"`
  do
  MSNAME=`echo $ms | cut -f 1 -d ,`
  MSMODEL=`echo $ms | cut -f 3 -d ,`
  MSSERIAL=`echo $ms | cut -f 4 -d ,`
    for lpar in `lssyscfg -r lpar -m $MSNAME -F name,lpar_env,os_version,state,rmc_ipaddr | sed 's/ /-/g'`
      do
        HMCNAME=`uname -n | cut -f 1 -d .`
        LPARNAME=`echo $lpar | cut -f 1 -d ,`
        LPARENV=`echo $lpar | cut -f 2 -d ,`
        LPAROS=`echo $lpar | cut -f 3 -d ,`
        LPARSTATE=`echo $lpar | cut -f 4 -d ,`
        LPARIP=`echo $lpar | cut -f 5 -d ,`
        echo ",$HMCNAME,$MSNAME,$MSMODEL,$MSSERIAL,$LPARNAME,$LPARENV,$LPAROS,$LPARSTATE,$LPARIP"
      done
  done
_ENDSSH_
done
}

rm -f /tmp/lpar_ms_${CURR_DATE}.csv
get_lpar_ms_table | tee -a /tmp/lpar_ms_${CURR_DATE}.csv

# Replace HMC names with index ID from DB to match the future SQL queries and update HMC data

for HMC in `echo ${HMCLIST}`
do
  HMCVER=`sshpass -p ${PASSWD} ssh -q -T hscroot@${HMC} "lshmc -V | grep Release | cut -f 2 -d : | sed 's/ //g'"`
  HMCSP=`sshpass -p ${PASSWD} ssh -q -T hscroot@${HMC} "lshmc -V | grep Pack | cut -f 2 -d : | sed 's/ //g'"`
  HMCMODEL=`sshpass -p ${PASSWD} ssh -q -T hscroot@${HMC} "lshmc -v | grep -w TM | sed 's/*TM //g'"`
  HMCSERIAL=`sshpass -p ${PASSWD} ssh -q -T hscroot@${HMC} "lshmc -v | grep -w SE | sed 's/*SE //g'"`
  HMCIP=`grep -w ${HMC} /etc/hosts | awk {'print $1'}`
  mysql -u ${DBUSER} -p${DBPASS} sap -e "UPDATE hmc SET version='${HMCVER}', servicepack='${HMCSP}',model='${HMCMODEL}',serialnr='${HMCSERIAL}',ipaddr='${HMCIP}' WHERE name='${HMC}'"
  HMCID=`mysql -sN -u root -pmariadbpwd sap -e "select id from hmc where name='${HMC}'"`
  sed -i "s/${HMC}/${HMCID}/g" /tmp/lpar_ms_${CURR_DATE}.csv
done

# Remove current entries from lpar_ms table from DB

#mysql -h ${DBHOST} -u ${DBUSER} -p${DBPASS} -e "TRUNCATE TABLE lpar_ms" sap

# Generate SQL file to import the CSV file
echo "LOAD DATA LOCAL INFILE '/tmp/lpar_ms_${CURR_DATE}.csv'" > /tmp/load_lpar_ms.sql
cat >> /tmp/load_lpar_ms.sql << '_EOF_'
IGNORE INTO TABLE sap.lpar_ms 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
_EOF_

# Load the CSV file into DB
mysql -h ${DBHOST} -u ${DBUSER} -p${DBPASS} sap < /tmp/load_lpar_ms.sql --local-infile=1

########################################################################
# Get details for mem_cpu_lpars TABLE
########################################################################

function get_mem_cpu_lpars_table()
{
for HMC in `echo ${HMCLIST}`
do
sshpass -p ${PASSWD} ssh -q -T hscroot@${HMC} << '_ENDSSH_'
  for ms in `lssyscfg -r sys -F name,state | grep Operating | egrep -v "No Connection|Mismatch|Power|HSCL" | cut -f 1 -d ,`
  do 
    lssyscfg -r prof -m $ms -F name,lpar_name,min_mem,desired_mem,max_mem,mem_mode,proc_mode,min_proc_units,desired_proc_units,max_proc_units,min_procs,desired_procs,max_procs,sharing_mode,uncap_weight
  done
_ENDSSH_
done
}

rm -f /tmp/mem_cpu_lpars_${CURR_DATE}.csv
get_mem_cpu_lpars_table | tee -a /tmp/mem_cpu_lpars_${CURR_DATE}.csv

# Add one comma at the beginning of each line

sed -i "s/^/,/g" /tmp/mem_cpu_lpars_${CURR_DATE}.csv
sed -i "s/,,/,/g" /tmp/mem_cpu_lpars_${CURR_DATE}.csv

# Remove current entries from mem_cpu_lpars table from DB

#mysql -h ${DBHOST} -u ${DBUSER} -p${DBPASS} -e "TRUNCATE TABLE mem_cpu_lpars" sap

# Generate SQL file to import the CSV file
echo "LOAD DATA LOCAL INFILE '/tmp/mem_cpu_lpars_${CURR_DATE}.csv'" > /tmp/load_mem_cpu_lpars.sql
cat >> /tmp/load_mem_cpu_lpars.sql << '_EOF_'
IGNORE INTO TABLE sap.mem_cpu_lpars
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
_EOF_

# Load the CSV file into DB
mysql -h ${DBHOST} -u ${DBUSER} -p${DBPASS} sap < /tmp/load_mem_cpu_lpars.sql --local-infile=1

####################################
# Get data for ms_fw TABLE
####################################

function get_ms_fw_table()
{
for HMC in `echo ${HMCLIST}`
do
sshpass -p ${PASSWD} ssh -q -T hscroot@${HMC} << '_ENDSSH_'
  for ms in `lssyscfg -r sys -F name,state | grep Operating | egrep -v "No Connection|Mismatch|Power|HSCL" | cut -f 1 -d ,`
  do
    echo -n "$ms,";lslic -m $ms -t sys -Fcurr_ecnumber_primary:activated_level
  done
_ENDSSH_
done
}

rm -f /tmp/ms_fw_${CURR_DATE}.csv
get_ms_fw_table | tee -a /tmp/ms_fw_${CURR_DATE}.csv

# Add one comma at the beginning of each line

sed -i "s/^/,/g" /tmp/ms_fw_${CURR_DATE}.csv
sed -i "s/,,/,/g" /tmp/ms_fw_${CURR_DATE}.csv

# Remove current entries from mem_cpu_lpars table from DB

#mysql -h ${DBHOST} -u ${DBUSER} -p${DBPASS} -e "TRUNCATE TABLE ms_fw" sap

# Generate SQL file to import the CSV file
echo "LOAD DATA LOCAL INFILE '/tmp/ms_fw_${CURR_DATE}.csv'" > /tmp/load_ms_fw.sql
cat >> /tmp/load_ms_fw.sql << '_EOF_'
IGNORE INTO TABLE sap.ms_fw
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
_EOF_

# Load the CSV file into DB
mysql -h ${DBHOST} -u ${DBUSER} -p${DBPASS} sap < /tmp/load_ms_fw.sql --local-infile=1

####################################
# Get data for ms_mem TABLE
####################################

function get_ms_mem_table()
{
for HMC in `echo ${HMCLIST}`
do
sshpass -p ${PASSWD} ssh -q -T hscroot@${HMC} << '_ENDSSH_'
for ms in `lssyscfg -r sys -F name,state | grep Operating | egrep -v "No Connection|Mismatch|Power|HSCL" | cut -f 1 -d ,`
do
  for line in `lshwres -m $ms -r mem --level sys -F configurable_sys_mem,curr_avail_sys_mem,deconfig_sys_mem,sys_firmware_mem,mem_region_size`
    do 
      echo "$ms,"$line""
    done
done
_ENDSSH_
done
}

rm -f /tmp/ms_mem_${CURR_DATE}.csv
get_ms_mem_table | tee -a /tmp/ms_mem_${CURR_DATE}.csv

# Add one comma at the beginning of each line

sed -i "s/^/,/g" /tmp/ms_mem_${CURR_DATE}.csv
sed -i "s/,,/,/g" /tmp/ms_mem_${CURR_DATE}.csv

# Remove current entries from ms_mem table from DB

#mysql -h ${DBHOST} -u ${DBUSER} -p${DBPASS} -e "TRUNCATE TABLE ms_mem" sap

# Generate SQL file to import the CSV file
echo "LOAD DATA LOCAL INFILE '/tmp/ms_mem_${CURR_DATE}.csv'" > /tmp/load_ms_mem.sql
cat >> /tmp/load_ms_mem.sql << '_EOF_'
IGNORE INTO TABLE sap.ms_mem
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
_EOF_

# Load the CSV file into DB
mysql -h ${DBHOST} -u ${DBUSER} -p${DBPASS} sap < /tmp/load_ms_mem.sql --local-infile=1


####################################
# Get data for ms_cpu TABLE
####################################

function get_ms_cpu_table()
{
for HMC in `echo ${HMCLIST}`
do
sshpass -p ${PASSWD} ssh -q -T hscroot@${HMC} << '_ENDSSH_'
for ms in `lssyscfg -r sys -F name,state | grep Operating | egrep -v "No Connection|Mismatch|Power|HSCL" | cut -f 1 -d ,`
do
  for line in `lshwres -m $ms -r proc --level sys -F configurable_sys_proc_units,curr_avail_sys_proc_units,deconfig_sys_proc_units`
    do
      echo "$ms,"$line""
    done
done
_ENDSSH_
done
}

rm -f /tmp/ms_cpu_${CURR_DATE}.csv
get_ms_cpu_table | tee -a /tmp/ms_cpu_${CURR_DATE}.csv

# Add one comma at the beginning of each line

sed -i "s/^/,/g" /tmp/ms_cpu_${CURR_DATE}.csv
sed -i "s/,,/,/g" /tmp/ms_cpu_${CURR_DATE}.csv

# Remove current entries from ms_cpu table from DB

#mysql -h ${DBHOST} -u ${DBUSER} -p${DBPASS} -e "TRUNCATE TABLE ms_cpu" sap

# Generate SQL file to import the CSV file
echo "LOAD DATA LOCAL INFILE '/tmp/ms_cpu_${CURR_DATE}.csv'" > /tmp/load_ms_cpu.sql
cat >> /tmp/load_ms_cpu.sql << '_EOF_'
IGNORE INTO TABLE sap.ms_cpu
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
_EOF_

# Load the CSV file into DB
mysql -h ${DBHOST} -u ${DBUSER} -p${DBPASS} sap < /tmp/load_ms_cpu.sql --local-infile=1

####################################
# Get data for ms_io TABLE
####################################

function get_ms_io_table()
{
for HMC in `echo ${HMCLIST}`
do
sshpass -p ${PASSWD} ssh -q -T hscroot@${HMC} << '_ENDSSH_'
for ms in `lssyscfg -r sys -F name,state | grep Operating | egrep -v "No Connection|Mismatch|Power|HSCL" | cut -f 1 -d ,`
do
  for line in `lshwres -r io --rsubtype slot -m $ms -F unit_phys_loc,phys_loc,description,lpar_name | sed 's/ /_/g'`
    do 
      echo "$ms,"$line""
  done
done
_ENDSSH_
done
}

rm -f /tmp/ms_io_${CURR_DATE}.csv
get_ms_io_table | tee -a /tmp/ms_io_${CURR_DATE}.csv

# Add one comma at the beginning of each line

sed -i "s/^/,/g" /tmp/ms_io_${CURR_DATE}.csv
sed -i "s/,,/,/g" /tmp/ms_io_${CURR_DATE}.csv

# Remove current entries from ms_io table from DB

#mysql -h ${DBHOST} -u ${DBUSER} -p${DBPASS} -e "TRUNCATE TABLE ms_io" sap

# Generate SQL file to import the CSV file
echo "LOAD DATA LOCAL INFILE '/tmp/ms_io_${CURR_DATE}.csv'" > /tmp/load_ms_io.sql
cat >> /tmp/load_ms_io.sql << '_EOF_'
IGNORE INTO TABLE sap.ms_io
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
_EOF_

# Load the CSV file into DB
mysql -h ${DBHOST} -u ${DBUSER} -p${DBPASS} sap < /tmp/load_ms_io.sql --local-infile=1

####################################
# Get data for lpar_fc TABLE
####################################

function get_lpar_fc_table()
{
for HMC in `echo ${HMCLIST}`
do
sshpass -p ${PASSWD} ssh -q -T hscroot@${HMC} << '_ENDSSH_'
for ms in `lssyscfg -r sys -F name,state | grep Operating | egrep -v "No Connection|Mismatch|Power|HSCL" | cut -f 1 -d ,`
do 
  lshwres -r virtualio -m $ms --rsubtype fc --level lpar -F lpar_name,adapter_type,state,remote_lpar_name,remote_slot_num,wwpns | sort 
done
_ENDSSH_
done
}

rm -f /tmp/lpar_fc_${CURR_DATE}.csv
get_lpar_fc_table | tee -a /tmp/lpar_fc_${CURR_DATE}.csv

# Add one comma at the beginning of each line

sed -i "s/^/DEFAULT,/g" /tmp/lpar_fc_${CURR_DATE}.csv
cat /tmp/lpar_fc_${CURR_DATE}.csv | sort | egrep -v "No results|null"  | grep -v ^$ | sort | uniq > /tmp/lpar_fc_${CURR_DATE}_2.csv

# Remove current entries from ms_io table from DB

#mysql -h ${DBHOST} -u ${DBUSER} -p${DBPASS} -e "TRUNCATE TABLE lpar_fc" sap

# Generate SQL file to import the CSV file
echo "LOAD DATA LOCAL INFILE '/tmp/lpar_fc_${CURR_DATE}_2.csv'" > /tmp/load_lpar_fc.sql
cat >> /tmp/load_lpar_fc.sql << '_EOF_'
IGNORE INTO TABLE sap.lpar_fc
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
_EOF_

# Load the CSV file into DB
mysql -h ${DBHOST} -u ${DBUSER} -p${DBPASS} sap < /tmp/load_lpar_fc.sql --local-infile=1


####################################
# Get data for lpar_scsi TABLE
####################################

function get_lpar_scsi_table()
{
for HMC in `echo ${HMCLIST}`
do
sshpass -p ${PASSWD} ssh -q -T hscroot@${HMC} << '_ENDSSH_'
for ms in `lssyscfg -r sys -F name,state | grep Operating | egrep -v "No Connection|Mismatch|Power|HSCL" | cut -f 1 -d ,`
do 
  lshwres -r virtualio -m $ms --rsubtype scsi -F lpar_name,slot_num,state,is_required,adapter_type,remote_lpar_name,remote_slot_num | sort
done
_ENDSSH_
done
}

rm -f /tmp/lpar_scsi_${CURR_DATE}.csv
get_lpar_scsi_table | tee -a /tmp/lpar_scsi_${CURR_DATE}.csv

# Add one comma at the beginning of each line

sed -i "s/^/,/g" /tmp/lpar_scsi_${CURR_DATE}.csv
sed -i "s/,,/,/g" /tmp/lpar_scsi_${CURR_DATE}.csv
cat /tmp/lpar_scsi_${CURR_DATE}.csv | sort | grep -v "No results"  | grep -v ^$ | sort | uniq > /tmp/lpar_scsi_${CURR_DATE}_2.csv

# Remove current entries from ms_io table from DB

#mysql -h ${DBHOST} -u ${DBUSER} -p${DBPASS} -e "TRUNCATE TABLE lpar_scsi" sap

# Generate SQL file to import the CSV file
echo "LOAD DATA LOCAL INFILE '/tmp/lpar_scsi_${CURR_DATE}_2.csv'" > /tmp/load_lpar_scsi.sql
cat >> /tmp/load_lpar_scsi.sql << '_EOF_'
IGNORE INTO TABLE sap.lpar_scsi
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
_EOF_

# Load the CSV file into DB
mysql -h ${DBHOST} -u ${DBUSER} -p${DBPASS} sap < /tmp/load_lpar_scsi.sql --local-infile=1

##################################
# Get data for lpar_eth TABLE
##################################

function get_lpar_eth_table()
{
for HMC in `echo ${HMCLIST}`
do
sshpass -p ${PASSWD} ssh -q -T hscroot@${HMC} << '_ENDSSH_'
for ms in `lssyscfg -r sys -F name,state | grep Operating | egrep -v "No Connection|Mismatch|Power|HSCL" | cut -f 1 -d ,`
do
  lshwres -r virtualio -m $ms --rsubtype eth --level lpar -F lpar_name,slot_num,is_trunk,port_vlan_id,vswitch,mac_addr | sort
done
_ENDSSH_
done
}

rm -f /tmp/lpar_eth_${CURR_DATE}.csv
get_lpar_eth_table | tee -a /tmp/lpar_eth_${CURR_DATE}.csv

# Add one comma at the beginning of each line

sed -i "s/^/DEFAULT,/g" /tmp/lpar_eth_${CURR_DATE}.csv
#sed -i "s/,,/,/g" /tmp/lpar_eth_${CURR_DATE}.csv
cat /tmp/lpar_eth_${CURR_DATE}.csv | sort | grep -v "No results"  | grep -v ^$ | sort | uniq > /tmp/lpar_eth_${CURR_DATE}_2.csv

# Remove current entries from lpar_eth table from DB

#mysql -h ${DBHOST} -u ${DBUSER} -p${DBPASS} -e "TRUNCATE TABLE lpar_eth" sap

# Generate SQL file to import the CSV file
echo "LOAD DATA LOCAL INFILE '/tmp/lpar_eth_${CURR_DATE}_2.csv'" > /tmp/load_lpar_eth.sql
cat >> /tmp/load_lpar_eth.sql << '_EOF_'
IGNORE INTO TABLE sap.lpar_eth
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
_EOF_

# Load the CSV file into DB
mysql -h ${DBHOST} -u ${DBUSER} -p${DBPASS} sap < /tmp/load_lpar_eth.sql --local-infile=1


##################################
# Get data for vios_wwpn TABLE
##################################

function get_vios_wwpn_table()
{
for HMC in `echo ${HMCLIST}`
do
sshpass -p ${PASSWD} ssh -q -T hscroot@${HMC} << '_ENDSSH_'
for ms in `lssyscfg -r sys -F name,state | grep Operating | egrep -v "No Connection|Mismatch|Power|HSCL" | cut -f 1 -d ,`
do
  for vios in `lssyscfg -r lpar -m $ms -F name,state,lpar_env | grep -w vioserver | cut -f 1 -d ,`
  do
    for fcs in `viosvrcmd -p $vios -m $ms -c "lsdev -type adapter" | grep fcs | grep -v FCoE | cut -f 1 -d ' '`
    do
      wwpn=`viosvrcmd -p $vios -m $ms -c "lsdev -dev $fcs -vpd" | grep -w "Network Address" | sed 's/\.//g;s/Network Address//g;s/ //g'`
      echo "$ms,$vios,$fcs,$wwpn"
    done
  done
done
_ENDSSH_
done
}

rm -f /tmp/wwpn_fc_${CURR_DATE}.csv
get_vios_wwpn_table | tee -a /tmp/wwpn_fc_${CURR_DATE}.csv

# Add one comma at the beginning of each line

sed -i "s/^/DEFAULT,/g" /tmp/wwpn_fc_${CURR_DATE}.csv
#sed -i "s/,,/,/g" /tmp/lpar_eth_${CURR_DATE}.csv
cat /tmp/wwpn_fc_${CURR_DATE}.csv | sort | grep -v "No results"  | grep -v ^$ | sort | uniq > /tmp/wwpn_fc_${CURR_DATE}_2.csv

# Remove current entries from lpar_eth table from DB

#mysql -h ${DBHOST} -u ${DBUSER} -p${DBPASS} -e "TRUNCATE TABLE lpar_eth" sap

# Generate SQL file to import the CSV file
echo "LOAD DATA LOCAL INFILE '/tmp/wwpn_fc_${CURR_DATE}_2.csv'" > /tmp/load_wwpn_fc.sql
cat >> /tmp/load_wwpn_fc.sql << '_EOF_'
IGNORE INTO TABLE sap.vios_fc_wwpn
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
_EOF_

# Load the CSV file into DB
mysql -h ${DBHOST} -u ${DBUSER} -p${DBPASS} sap < /tmp/load_wwpn_fc.sql --local-infile=1
