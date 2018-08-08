#!/bin/sh

set -xv

# Set timestamp for filenames

CURR_DATE=`date +%Y-%m-%d`

function get_lpar_ms ()
{

for hmc in ishmc30 ishmc31 ishmc40 ishmc10 ishmc11
do
ssh -q -l unix $hmc << '_ENDSSH_'
 HMC=`uname -n | cut -f 1 -d .`
 for sys in $(lssyscfg -r sys -F name,state  | grep Operating | cut -f 1 -d ,); do for lpar in $(lssyscfg -r lpar -m $sys -F name); do echo ",$sys,$HMC,$lpar"; done; done
_ENDSSH_
done
}


# Remove current entries from phys_sys table from DB

mysql -u root -pnXEzT0Ae0k9RJTM -e "TRUNCATE TABLE phys_sys" websles

rm -f /tmp/lpar_msinst_${CURR_DATE}.csv
echo "<p align=\"center\"><img src=\"images/ajax-loader.gif\" /></p>"
echo "<p align=\"center\"><b>This window will close automatically when finished</b></p>"
get_lpar_ms > /tmp/lpar_msinst_${CURR_DATE}.csv


# Generate SQL file to import the CSV file
echo "LOAD DATA LOCAL INFILE '/tmp/lpar_msinst_${CURR_DATE}.csv'" > /tmp/load_lpar_msinst.sql
cat >> /tmp/load_lpar_msinst.sql << '_EOF_'
INTO TABLE websles.phys_sys
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
_EOF_

# Load the CSV file into DB
mysql -u root -pnXEzT0Ae0k9RJTM websles < /tmp/load_lpar_msinst.sql --local-infile=1
echo "<script type=\"text/javascript\" charset=\"utf-8\">window.self.close()</script>";
