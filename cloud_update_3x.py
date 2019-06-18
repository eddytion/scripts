#!/bin/python3.6

import paramiko
import sys
import datetime
import multiprocessing
import logging
import mysql.connector
import time

DBUSER = "root"
DBPASS = "mariadbpwd"
DBHOST = "localhost"
DBNAME = "sap"
DBPORT = 3306

current_date = datetime.date.today()
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
threads = []

sys.tracebacklimit = 0
if len(sys.argv) < 1:
    logging.error("Not enough arguments")
    sys.exit(1)

logging.basicConfig(filename='/tmp/cloud_logfile.log', level=logging.INFO)
mydb = mysql.connector.connect(
    host=DBHOST,
    user=DBUSER,
    passwd=DBPASS,
    database=DBNAME
)

mycursor = mydb.cursor()


class CloudUpdate(object):
    def __init__(self, hmc):
        self.hmc = hmc
        self.csvfile_lpar_ms = "/tmp/lpar_ms_" + str(hmc) + "_" + str(current_date) + ".csv"
        self.csvfile_mem_cpu_lpars = "/tmp/mem_cpu_lpars_" + str(hmc) + "_" + str(current_date) + ".csv"
        self.csvfile_ms_fw = "/tmp/ms_fw_" + str(hmc) + "_" + str(current_date) + ".csv"
        self.csvfile_ms_mem = "/tmp/ms_mem_" + str(hmc) + "_" + str(current_date) + ".csv"
        self.csvfile_ms_cpu = "/tmp/ms_cpu_" + str(hmc) + "_" + str(current_date) + ".csv"
        self.csvfile_ms_io = "/tmp/ms_io_" + str(hmc) + "_" + str(current_date) + ".csv"
        self.csvfile_lpar_fc = "/tmp/ms_lpar_fc_" + str(hmc) + "_" + str(current_date) + ".csv"
        self.csvfile_lpar_scsi = "/tmp/ms_lpar_scsi_" + str(hmc) + "_" + str(current_date) + ".csv"
        self.csvfile_lpar_eth = "/tmp/ms_lpar_eth_" + str(hmc) + "_" + str(current_date) + ".csv"
        self.csvfile_phys_mac = "/tmp/ms_phys_mac_" + str(hmc) + "_" + str(current_date) + ".csv"
        self.csvfile_vios_wwpn = "/tmp/ms_vios_wwpn_" + str(hmc) + "_" + str(current_date) + ".csv"
        self.csvfile_vios_disks = "/tmp/ms_vios_disks_" + str(hmc) + "_" + str(current_date) + ".csv"
        self.csvfile_hmc_details = "/tmp/hmc_details_" + str(hmc) + "_" + str(current_date) + ".sql"
        self.lpar_ms_results = []
        self.mem_cpu_lpars = []
        self.ms_fw = []
        self.ms_mem = []
        self.ms_cpu = []
        self.ms_io = []
        self.lpar_fc = []
        self.lpar_scsi = []
        self.lpar_eth = []
        self.phys_mac = []
        self.vios_wwpn = []
        self.hmc_queries = []
        self.vios_disks = []

    def get_hmc_details(self, hmc):
        hmc_last_update = time.strftime('%Y-%m-%d %H:%M:%S')
        hmc_release = ""
        hmc_servicepack = ""
        hmc_model = ""
        hmc_serial = ""
        ssh.connect(hostname=hmc, username='hscroot', password='abc1234', timeout=120)
        ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command('lshmc -V')
        output_1 = ssh_stdout.readlines()
        ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command('lshmc -v')
        output_2 = ssh_stdout.readlines()
        for i in output_1:
            if i:
                if "Release:" in i:
                    hmc_release = (i.split(':')[-1].rstrip('\n'))
                if "Service Pack:" in i:
                    hmc_servicepack = (i.split(':')[-1].rstrip('\n'))

        for i in output_2:
            if i:
                if "*TM" in i:
                    hmc_model = (i.split(' ')[-1].rstrip('\n'))
                if "*SE" in i:
                    hmc_serial = (i.split(' ')[-1].rstrip('\n'))

        query = "UPDATE hmc SET version='" + hmc_release + "', servicepack='" + hmc_servicepack + "', model='" + hmc_model + "', serialnr='" + hmc_serial + "', last_update='" + hmc_last_update + "' WHERE name='" + hmc + "';"
        self.hmc_queries.append(query)
        with open(self.csvfile_hmc_details, 'a') as f:
            for line in self.hmc_queries:
                f.write(line)

    def update_database_hmc_details(self):
        with open(self.csvfile_hmc_details, 'r') as f:
            for qr in f.readlines():
                mycursor.execute(qr)
                mydb.commit()

    def get_lpar_ms(self, hmc):
        ssh.connect(hostname=hmc, username='hscroot', password='abc1234', timeout=120)
        ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(
            'for ms in `lssyscfg -r sys -F name,state,type_model,serial_num | grep Operating | egrep -v "Authentication|No Connection|Mismatch|Power|HSCL"`;do MSNAME=`echo $ms | cut -f 1 -d ,`;MSMODEL=`echo $ms | cut -f 3 -d ,`;MSSERIAL=`echo $ms | cut -f 4 -d ,`; for lpar in `lssyscfg -r lpar -m $MSNAME -F name,lpar_env,os_version,state,rmc_ipaddr,rmc_state,curr_lpar_proc_compat_mode,lpar_id | sed \'s/ /-/g\'`;do HMCNAME=`uname -n | cut -f 1 -d .`;  LPARNAME=`echo $lpar | cut -f 1 -d ,`;  LPARENV=`echo $lpar | cut -f 2 -d ,`;  LPAROS=`echo $lpar | cut -f 3 -d ,`;  LPARSTATE=`echo $lpar | cut -f 4 -d ,`;  LPARIP=`echo $lpar | cut -f 5 -d ,`;  RMCSTATE=`echo $lpar | cut -f 6 -d ,`; PROC_COMPAT=`echo $lpar | cut -f 7 -d ,`; LPARID=`echo $lpar | cut -f 8 -d ,`; echo "DEFAULT,$HMCNAME,$MSNAME,$MSMODEL,$MSSERIAL,$LPARNAME,$LPARENV,$LPAROS,$LPARSTATE,$LPARIP,$RMCSTATE,$PROC_COMPAT,$LPARID";done;done')
        output = ssh_stdout.readlines()
        for i in output:
            if len(i) > 0 and "No results were found." not in i:
                self.lpar_ms_results.append([i])
        with open(self.csvfile_lpar_ms, 'a') as f:
            for line in self.lpar_ms_results:
                f.write(line[0])

    def update_database_lpar_ms(self):
        query = "LOAD DATA LOCAL INFILE '" + self.csvfile_lpar_ms + "' IGNORE INTO TABLE sap.lpar_ms FIELDS TERMINATED BY ',' ENCLOSED BY '\"' LINES TERMINATED BY '\n'"
        mycursor.execute(query)
        mydb.commit()

    def get_mem_cpu_lpars(self, hmc):
        ssh.connect(hostname=hmc, username='hscroot', password='abc1234', timeout=120)
        ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(
            'for ms in `lssyscfg -r sys -F name,state | grep Operating | egrep -v "Authentication|No Connection|Mismatch|Power|HSCL" | cut -f 1 -d ,`;do lssyscfg -r prof -m $ms -F name,lpar_name,min_mem,desired_mem,max_mem,mem_mode,proc_mode,min_proc_units,desired_proc_units,max_proc_units,min_procs,desired_procs,max_procs,sharing_mode,uncap_weight;done | sed \'s/^/DEFAULT,/g\'')
        output = ssh_stdout.readlines()
        for i in output:
            if len(i) > 0 and "No results were found." not in i:
                self.mem_cpu_lpars.append([i])
        with open(self.csvfile_mem_cpu_lpars, 'a') as f:
            for line in self.mem_cpu_lpars:
                f.write(line[0])

    def update_database_mem_cpu_lpars(self):
        query = "LOAD DATA LOCAL INFILE '" + self.csvfile_mem_cpu_lpars + "' IGNORE INTO TABLE sap.mem_cpu_lpars FIELDS TERMINATED BY ',' ENCLOSED BY '\"' LINES TERMINATED BY '\n'"
        mycursor.execute(query)
        mydb.commit()

    def get_ms_fw(self, hmc):
        ssh.connect(hostname=hmc, username='hscroot', password='abc1234', timeout=120)
        ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(
            'for ms in `lssyscfg -r sys -F name,state | grep Operating | egrep -v "Authentication|No Connection|Mismatch|Power|HSCL" | cut -f 1 -d ,`;do echo -n "$ms,";lslic -m $ms -t sys -Fcurr_ecnumber_primary:activated_level;done')
        output = ssh_stdout.readlines()
        for i in output:
            if len(i) > 0 and "No results were found." not in i:
                self.ms_fw.append([i])
        with open(self.csvfile_ms_fw, 'a') as f:
            for line in self.ms_fw:
                f.write('DEFAULT,' + str(line[0]))

    def update_database_ms_fw(self):
        query = "LOAD DATA LOCAL INFILE '" + self.csvfile_ms_fw + "' IGNORE INTO TABLE sap.ms_fw FIELDS TERMINATED BY ',' ENCLOSED BY '\"' LINES TERMINATED BY '\n'"
        mycursor.execute(query)
        mydb.commit()

    def get_ms_mem(self, hmc):
        ssh.connect(hostname=hmc, username='hscroot', password='abc1234', timeout=120)
        ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(
            'for ms in `lssyscfg -r sys -F name,state | grep Operating | egrep -v "Authentication|No Connection|Mismatch|Power|HSCL" | cut -f 1 -d ,`; do for line in `lshwres -m $ms -r mem --level sys -F configurable_sys_mem,curr_avail_sys_mem,deconfig_sys_mem,sys_firmware_mem,mem_region_size`;do echo "$ms,"$line"";done;done')
        output = ssh_stdout.readlines()
        for i in output:
            if len(i) > 0 and "No results were found." not in i:
                self.ms_mem.append([i])
        with open(self.csvfile_ms_mem, 'a') as f:
            for line in self.ms_mem:
                f.write('DEFAULT,' + str(line[0]))

    def update_database_ms_mem(self):
        query = "LOAD DATA LOCAL INFILE '" + self.csvfile_ms_mem + "' IGNORE INTO TABLE sap.ms_mem FIELDS TERMINATED BY ',' ENCLOSED BY '\"' LINES TERMINATED BY '\n'"
        mycursor.execute(query)
        mydb.commit()

    def get_ms_cpu(self, hmc):
        ssh.connect(hostname=hmc, username='hscroot', password='abc1234', timeout=120)
        ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(
            'for ms in `lssyscfg -r sys -F name,state | grep Operating | egrep -v "Authentication|No Connection|Mismatch|Power|HSCL" | cut -f 1 -d ,`; do for line in `lshwres -m $ms -r proc --level sys -F configurable_sys_proc_units,curr_avail_sys_proc_units,deconfig_sys_proc_units`;do echo "$ms,"$line"";done; done')
        output = ssh_stdout.readlines()
        for i in output:
            if len(i) > 0 and "No results were found." not in i:
                self.ms_cpu.append([i])
        with open(self.csvfile_ms_cpu, 'a') as f:
            for line in self.ms_cpu:
                f.write('DEFAULT,' + str(line[0]))

    def update_database_ms_cpu(self):
        query = "LOAD DATA LOCAL INFILE '" + self.csvfile_ms_cpu + "' IGNORE INTO TABLE sap.ms_cpu FIELDS TERMINATED BY ',' ENCLOSED BY '\"' LINES TERMINATED BY '\n'"
        mycursor.execute(query)
        mydb.commit()

    def get_ms_io(self, hmc):
        ssh.connect(hostname=hmc, username='hscroot', password='abc1234', timeout=120)
        ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(
            'for ms in `lssyscfg -r sys -F name,state | grep Operating | egrep -v "Authentication|No Connection|Mismatch|Power|HSCL" | cut -f 1 -d ,`; do for line in `lshwres -r io --rsubtype slot -m $ms -F unit_phys_loc,phys_loc,description,lpar_name,drc_name | sed \'s/ /_/g\'`;do echo "$ms,"$line"";done;done')
        output = ssh_stdout.readlines()
        for i in output:
            if len(i) > 0 and "No results were found." not in i:
                self.ms_io.append([i])
        with open(self.csvfile_ms_io, 'a') as f:
            for line in self.ms_io:
                f.write('DEFAULT,' + str(line[0]))

    def update_database_ms_io(self):
        query = "LOAD DATA LOCAL INFILE '" + self.csvfile_ms_io + "' IGNORE INTO TABLE sap.ms_io FIELDS TERMINATED BY ',' ENCLOSED BY '\"' LINES TERMINATED BY '\n'"
        mycursor.execute(query)
        mydb.commit()

    def get_lpar_fc(self, hmc):
        ssh.connect(hostname=hmc, username='hscroot', password='abc1234', timeout=120)
        ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(
            'for ms in `lssyscfg -r sys -F name,state | grep Operating | egrep -v "Authentication|No Connection|Mismatch|Power|HSCL" | cut -f 1 -d ,`;do lshwres -r virtualio -m $ms --rsubtype fc --level lpar -F lpar_name,adapter_type,state,remote_lpar_name,remote_slot_num,wwpns | sort ; done')
        output = ssh_stdout.readlines()
        for i in output:
            if len(i) > 0 and "No results were found." not in i:
                self.lpar_fc.append([i])
        with open(self.csvfile_lpar_fc, 'a') as f:
            for line in self.lpar_fc:
                f.write('DEFAULT,' + str(line[0]))

    def update_database_lpar_fc(self):
        query = "LOAD DATA LOCAL INFILE '" + self.csvfile_lpar_fc + "' IGNORE INTO TABLE sap.lpar_fc FIELDS TERMINATED BY ',' ENCLOSED BY '\"' LINES TERMINATED BY '\n'"
        mycursor.execute(query)
        mydb.commit()

    def get_lpar_scsi(self, hmc):
        ssh.connect(hostname=hmc, username='hscroot', password='abc1234', timeout=120)
        ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(
            'for ms in `lssyscfg -r sys -F name,state | grep Operating | egrep -v "Authentication|No Connection|Mismatch|Power|HSCL" | cut -f 1 -d ,`; do lshwres -r virtualio -m $ms --rsubtype scsi -F lpar_name,slot_num,state,is_required,adapter_type,remote_lpar_name,remote_slot_num | sort; done')
        output = ssh_stdout.readlines()
        for i in output:
            if len(i) > 0 and "No results were found." not in i:
                self.lpar_scsi.append([i])
        with open(self.csvfile_lpar_scsi, 'a') as f:
            for line in self.lpar_scsi:
                f.write('DEFAULT,' + str(line[0]))

    def update_database_lpar_scsi(self):
        query = "LOAD DATA LOCAL INFILE '" + self.csvfile_lpar_scsi + "' IGNORE INTO TABLE sap.lpar_scsi FIELDS TERMINATED BY ',' ENCLOSED BY '\"' LINES TERMINATED BY '\n'"
        mycursor.execute(query)
        mydb.commit()

    def get_lpar_eth(self, hmc):
        ssh.connect(hostname=hmc, username='hscroot', password='abc1234', timeout=120)
        ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(
            'for ms in `lssyscfg -r sys -F name,state | grep Operating | egrep -v "Authentication|No Connection|Mismatch|Power|HSCL" | cut -f 1 -d ,`; do lshwres -r virtualio -m $ms --rsubtype eth --level lpar -F lpar_name,slot_num,is_trunk,port_vlan_id,vswitch,mac_addr | sort; done')
        output = ssh_stdout.readlines()
        for i in output:
            if len(i) > 0 and "No results were found." not in i:
                self.lpar_eth.append([i])
        with open(self.csvfile_lpar_eth, 'a') as f:
            for line in self.lpar_eth:
                f.write('DEFAULT,' + str(line[0]))

    def update_database_lpar_eth(self):
        query = "LOAD DATA LOCAL INFILE '" + self.csvfile_lpar_eth + "' IGNORE INTO TABLE sap.lpar_eth FIELDS TERMINATED BY ',' ENCLOSED BY '\"' LINES TERMINATED BY '\n'"
        mycursor.execute(query)
        mydb.commit()

    def get_vios_wwpn(self, hmc):
        ssh.connect(hostname=hmc, username='hscroot', password='abc1234', timeout=120)
        ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(
            'for ms in `lssyscfg -r sys -F name,state | grep Operating | egrep -v "Authentication|No Connection|Mismatch|Power|HSCL" | cut -f 1 -d ,`;do for vios in `lssyscfg -r lpar -m $ms -F name,state,lpar_env | grep -w vioserver | cut -f 1 -d ,`;do for fcs in `viosvrcmd -p $vios -m $ms -c "lsdev -type adapter" | grep fcs | grep -v FCoE | cut -f 1 -d \' \'`;do wwpn=`viosvrcmd -p $vios -m $ms -c "lsdev -dev $fcs -vpd" | grep -w "Network Address" | sed \'s/\.//g;s/Network Address//g;s/ //g\'`; echo "$ms,$vios,$fcs,$wwpn";done;done;done')
        output = ssh_stdout.readlines()
        for i in output:
            if len(i) > 0:
                self.vios_wwpn.append([i])
        with open(self.csvfile_vios_wwpn, 'a') as f:
            for line in self.vios_wwpn:
                f.write('DEFAULT,' + str(line[0]))

    def update_database_vios_wwpn(self):
        query = "LOAD DATA LOCAL INFILE '" + self.csvfile_vios_wwpn + "' IGNORE INTO TABLE sap.vios_fc_wwpn FIELDS TERMINATED BY ',' ENCLOSED BY '\"' LINES TERMINATED BY '\n'"
        mycursor.execute(query)
        mydb.commit()

    def get_phys_mac(self, hmc):
        ssh.connect(hostname=hmc, username='hscroot', password='abc1234', timeout=120)
        ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(
            'for ms in `lssyscfg -r sys -F name,state | grep Operating | egrep -v "Authentication|No Connection|Mismatch|Power|HSCL" | cut -f 1 -d ,`; do for line in `lshwres -m $ms -r io --rsubtype slotchildren -F lpar_name,phys_loc,mac_address | grep -v null | grep -v "No results were"`; do echo "$ms,$line"; done; done')
        output = ssh_stdout.readlines()
        for i in output:
            if len(i) > 0:
                self.phys_mac.append([i])
        with open(self.csvfile_phys_mac, 'a') as f:
            for line in self.phys_mac:
                f.write('DEFAULT,' + str(line[0]))

    def update_database_phys_mac(self):
        query = "LOAD DATA LOCAL INFILE '" + self.csvfile_phys_mac + "' IGNORE INTO TABLE sap.phys_mac FIELDS TERMINATED BY ',' ENCLOSED BY '\"' LINES TERMINATED BY '\n'"
        mycursor.execute(query)
        mydb.commit()

    def get_hmc_data(self, hmc):
        self.get_hmc_details(hmc)
        self.get_lpar_ms(hmc)
        self.get_lpar_eth(hmc)
        self.get_phys_mac(hmc)
        self.get_mem_cpu_lpars(hmc)
        self.get_lpar_scsi(hmc)
        self.get_lpar_fc(hmc)
        self.get_ms_io(hmc)
        self.get_ms_cpu(hmc)
        self.get_ms_mem(hmc)
        self.get_ms_fw(hmc)
        self.get_vios_wwpn(hmc)

    def mysql_update(self):
        try:
            self.update_database_hmc_details()
            self.update_database_lpar_ms()
            self.update_database_mem_cpu_lpars()
            self.update_database_ms_fw()
            self.update_database_ms_mem()
            self.update_database_ms_cpu()
            self.update_database_ms_io()
            self.update_database_lpar_fc()
            self.update_database_lpar_scsi()
            self.update_database_lpar_eth()
            self.update_database_vios_wwpn()
            self.update_database_phys_mac()
        except:
            print("Some error has occured while trying to update database for " + str(self.hmc))
            pass


pool = multiprocessing.Pool(processes=6)
for i in sys.argv[1:]:
    updater = CloudUpdate(i)
    pool.apply_async(updater.get_hmc_data, args=(i,))
pool.close()
pool.join()

for i in sys.argv[1:]:
    updater = CloudUpdate(i)
    updater.mysql_update()
