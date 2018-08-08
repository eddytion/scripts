LOAD DATA LOCAL INFILE '/srv/scripts/viostats/output.csv'
INTO TABLE sap.vios_fcstat 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
