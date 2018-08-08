#!/usr/bin/env python3

from os import remove
import csv
import paramiko
import pandas as pd
import subprocess

SVC = ['192.168.1.40', '192.168.1.130', '192.168.1.140', '192.168.1.150', '192.168.0.8']

with open('/tmp/exports1.csv', 'w'): pass
with open('/tmp/exports2.csv', 'w'): pass


for i in SVC:
	try:
		client = paramiko.SSHClient()
		client.load_system_host_keys()
		client.set_missing_host_key_policy(paramiko.WarningPolicy)

		client.connect(i, 22, 'stor2rrd')

		stdin, stdout, stderr = client.exec_command('lshostvdiskmap -delim ","')
		with open('/tmp/exports1.csv', 'a') as f:
			f.write(stdout.read().decode('utf-8'))
		f.close()

		stdin, stdout, stderr = client.exec_command('lsvdisk -delim , -bytes')
		with open('/tmp/exports2.csv', 'a') as f:
			f.write(stdout.read().decode('utf-8'))
		f.close()

	finally:
		client.close()

file1 = pd.read_csv('/tmp/exports1.csv')
file2 = pd.read_csv('/tmp/exports2.csv')

file1 = file1.dropna(axis=1)
file2 = file2.dropna(axis=1)

merged = file1.merge(file2, on='vdisk_UID')
merged.to_csv('/tmp/output.csv', index=False)

with open('/tmp/output.csv', 'r') as csvfile:
	reader = csv.DictReader(csvfile)
	with open('/tmp/luns.csv', 'w') as outcsv:
		writer = csv.writer(outcsv)
		for row in reader:
#		print(row['name_x'], row['vdisk_name'], row['vdisk_UID'], row['IO_group_name_x'], row['capacity'], row['volume_id'], row['volume_name'])
			fieldnames = ['name_x', 'vdisk_name', 'vdisk_UID', 'IO_group_name_x', 'capacity', 'volume_id', 'volume_name']
			writer.writerow(('DEFAULT', row['name_x'], row['vdisk_name'], row['vdisk_UID'], row['IO_group_name'], row['capacity'], row['vdisk_id'])) 
	outcsv.close()
csvfile.close()

subprocess.call(["sed -i '/name/d' /tmp/luns.csv"], shell=True)
subprocess.call(["mysql -uroot -ppassword sap -e 'truncate table storage'"], shell=True)
subprocess.call(["mysql -uroot -ppassword sap --local-infile -e \"LOAD DATA LOCAL INFILE '/tmp/luns.csv' INTO TABLE storage FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n'\""], shell = True)

remove('/tmp/exports1.csv')
remove('/tmp/exports2.csv')
remove('/tmp/output.csv')
