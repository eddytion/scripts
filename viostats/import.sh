# Add DEFAULT and NULL

cat /srv/scripts/viostats/output.raw | sed 's/^/DEFAULT,/g' | sed 's/$/,NULL/g' > /srv/scripts/viostats/output.csv

# Generate SQL file to import the CSV file

echo "LOAD DATA LOCAL INFILE '/srv/scripts/viostats/output.csv'" > /srv/scripts/viostats/load_data.sql
cat >> /srv/scripts/viostats/load_data.sql << '_EOF_'
INTO TABLE sap.vios_fcstat 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
_EOF_

# Load data

mysql -u root -p sap < /srv/scripts/viostats/load_data.sql --local-infile=1
