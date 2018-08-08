#!/bin/sh

#set -xv

# Set timestamp for filenames

CURR_DATE=`date +%Y-%m-%d`

function get_ms ()
{

for hmc in ishmc30 ishmc31 ishmc40
do
ssh -q -l unix $hmc << '_ENDSSH_'
 HMC=`uname -n | cut -f 1 -d .`
 for sys in $(lssyscfg -r sys -F name,state  | grep Operating | cut -f 1 -d ,);do echo ",$sys,$HMC"; done
_ENDSSH_
done
}


# Remove current entries from phys_sys_weblpar table from DB

mysql -u root -pnXEzT0Ae0k9RJTM -e "TRUNCATE TABLE phys_sys_weblpar" websles

rm -f /tmp/ms_msinst_${CURR_DATE}.csv
get_ms | tee -a /tmp/ms_msinst_${CURR_DATE}.csv

# Generate SQL file to import the CSV file
echo "LOAD DATA LOCAL INFILE '/tmp/ms_msinst_${CURR_DATE}.csv'" > /tmp/load_ms_msinst.sql
cat >> /tmp/load_ms_msinst.sql << '_EOF_'
INTO TABLE websles.phys_sys_weblpar
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
_EOF_

# Load the CSV file into DB
mysql -u root -pnXEzT0Ae0k9RJTM websles < /tmp/load_ms_msinst.sql --local-infile=1
