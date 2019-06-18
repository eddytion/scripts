#!/usr/bin/env /usr/bin/python3

import paramiko
import sys
import time
import multiprocessing
from scp import SCPClient
import logging
import argparse
import mysql.connector

DBUSER = "root"
DBPASS = "mariadbpwd"
DBHOST = "localhost"
DBNAME = "cloud"
DBPORT = 3306

parser = argparse.ArgumentParser(description="Scan systems for disk path status")
parser.add_argument("nim", help="Name of the infra NIM server from the site", type=str)
parser.add_argument("--location", help="For INFA + POD omit this parameter", type=str, default="ALL",
                    choices=['INFRA', 'POD', 'POD1', 'POD2'])
args = parser.parse_args()

current_date = time.strftime('%Y-%m-%d-%H_%M')
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
sys.tracebacklimit = 0
mysql_date = time.strftime('%Y-%m-%d %H:%M:%S')
vioses = []
tsms = []
errors = []
okinfo = []
warninfo = []

mydb = mysql.connector.connect(
    host=DBHOST,
    user=DBUSER,
    passwd=DBPASS,
    database=DBNAME
)

mycursor = mydb.cursor()

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(message)s",
    handlers=[
        logging.FileHandler("{0}/{1}.log".format('/tmp', 'path_check_' + str(current_date))),
        logging.StreamHandler()
    ])

log = logging.getLogger()
logging.getLogger("paramiko").setLevel(logging.WARNING)


class TermColors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
    CYAN = '\033[96m'


class GetSystemList(object):
    def __init__(self):
        self.nim = args.nim
        self.user = "ibmadmin"
        self.vios_list = []
        self.tsm_list = []

    def get_vios_list(self):
        try:
            print(TermColors.BOLD + TermColors.CYAN + "Connecting to " + str(self.nim) + " to download hostdb file")
            ssh.connect(hostname=str(self.nim), username=str(self.user), port=22, timeout=10)
            scp = SCPClient(ssh.get_transport())
            scp.get('/usr/local/etc/dsadm.hostdb', '/tmp/')
            scp.close()
            ssh.close()
            print(TermColors.BOLD + TermColors.CYAN + "Done")
            if args.location == "ALL":
                with open('/tmp/dsadm.hostdb', mode='rt', encoding='latin-1') as fstream:
                    for i in fstream.readlines():
                        if "SAN" in i and "VIO" in i:
                            self.vios_list.append(str(i).split(':')[0])
            elif args.location == "POD":
                with open('/tmp/dsadm.hostdb', mode='rt', encoding='latin-1') as fstream:
                    for i in fstream.readlines():
                        if "SAN" in i and "VIO_POD" in i:
                            self.vios_list.append(str(i).split(':')[0])
            elif args.location == "POD1":
                with open('/tmp/dsadm.hostdb', mode='rt', encoding='latin-1') as fstream:
                    for i in fstream.readlines():
                        if "SAN" in i and "VIO_POD" in i and "ccpx1" in i:
                            self.vios_list.append(str(i).split(':')[0])
            elif args.location == "POD2":
                with open('/tmp/dsadm.hostdb', mode='rt', encoding='latin-1') as fstream:
                    for i in fstream.readlines():
                        if "SAN" in i and "VIO_POD" in i and "ccpx2" in i:
                            self.vios_list.append(str(i).split(':')[0])
            elif args.location == "INFRA":
                with open('/tmp/dsadm.hostdb', mode='rt', encoding='latin-1') as fstream:
                    for i in fstream.readlines():
                        if "SAN" in i and "VIO_INFRA" in i:
                            self.vios_list.append(str(i).split(':')[0])
        except Exception as e:
            log.info("Some error occurred while downloading / reading hostdb file: " + str(e))
            sys.exit(1)


def update_database_path_check():
    try:
        query = "LOAD DATA LOCAL INFILE '/tmp/path_check_dashboard_" + args.nim + ".csv' IGNORE INTO TABLE cloud.path_check FIELDS TERMINATED BY ',' ENCLOSED BY '\"' LINES TERMINATED BY '\n'"
        mycursor.execute(query)
        mydb.commit()
    except Exception as e:
        print("Exception: " + str(e))
        pass


class PathCheck(object):
    def __init__(self, vios):
        self.vios = vios
        self.hbaports = []
        self.paths = []
        self.disks = []
        self.uuids = []
        self.wwpns = []
        self.luns = []
        self.failed_paths = []
        self.missing_paths = []
        self.defined_paths = []
        self.disabled_paths = []

    def get_paths(self, vios):
        try:
            ssh.connect(hostname=vios, username='padmin', port=22, timeout=5)
            ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command('ioscli lspath -fmt , | grep fscsi')
            output = ssh_stdout.readlines()
            with open('/tmp/path_check_dashboard_' + args.nim + '.csv', mode='at', encoding='latin-1') as f:
                for line in output:
                    print(line)
                    f.write('DEFAULT,' + str(vios) + ',' + str(line).rstrip('\n') + ',' + str(mysql_date) + '\n')
        except:
            try:
                ssh.connect(hostname=args.nim, username='ibmadmin', timeout=10)
                ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command('nslookup ' + str(
                    vios) + '.ssm.sdc.gts.ibm.com|grep Address | grep -v "#53" | sed \'s/Address://g;s/ //g\'')
                output = ssh_stdout.readlines()
                if len(output) > 0:
                    for i in output:
                        if len(i) > 0:
                            ip = str(i).rstrip('\n')
                            ssh.connect(hostname=ip, username='padmin', port=22, timeout=5)
                            ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command('ioscli lspath -fmt , | grep fscsi')
                            output = ssh_stdout.readlines()
                            with open('/tmp/path_check_dashboard_' + args.nim + '.csv', mode='at',
                                      encoding='latin-1') as f:
                                for line in output:
                                    print(line)
                                    f.write('DEFAULT,' + str(vios) + ',' + str(line).rstrip('\n') + ',' + str(
                                        mysql_date) + '\n')
            except Exception as e:
                log.info(TermColors.FAIL + "[!] Unable to get data from: " + str(vios) + " " + str(e))
                pass


get_list = GetSystemList()
get_list.get_vios_list()

pool = multiprocessing.Pool(processes=multiprocessing.cpu_count() - 1)
for i in get_list.vios_list:
    updater = PathCheck(i)
    pool.apply_async(updater.get_paths, args=(i,))
pool.close()
pool.join()

update_database_path_check()
