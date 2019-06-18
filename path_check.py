#!/usr/bin/env /usr/bin/python3

import paramiko
import sys
import time
import multiprocessing
from scp import SCPClient
import logging
import argparse
import os
from email.mime.text import MIMEText
from subprocess import Popen, PIPE
import socket

# Global vars

current_hostname = socket.gethostname()
site_name = current_hostname[:4].upper()
current_date = time.strftime('%Y-%m-%d-%H_%M_%S')
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
sys.tracebacklimit = 0
vioses = []
tsms = []
errors = []
okinfo = []
warninfo = []
failed_vioses = []
email_body = []

# Parser definition

parser = argparse.ArgumentParser(description="Scan systems for disk path status")
parser.add_argument("nim", help="Name of the infra NIM server from the site", type=str)
parser.add_argument("type", help="Perform pre or post check", type=str, choices=['PRE', 'POST', 'DAILY'])
parser.add_argument("--location", help="For INFRA + POD omit this parameter", type=str, default="ALL",
                    choices=['INFRA', 'POD', 'POD1', 'POD2'])
parser.add_argument("--fix", help="Attempt to recover paths", default=False, action="store_true")
parser.add_argument("--cfgdev", help="Send cfgdev command", default=False, action="store_true")
parser.add_argument("--email", help="Send results by mail", default=False)
args = parser.parse_args()
print(args)
logfile = '/tmp/path_check_' + args.type + "_" + str(current_date) + ".log"
mailfile = '/tmp/path_check_mailbody' + args.type + "_" + str(current_date) + ".log"

# Logging definition and formmating. Also, configure paramiko to show only warnings on screen during execution

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(message)s",
    handlers=[
        logging.FileHandler(logfile),
        logging.StreamHandler()
    ])

log = logging.getLogger()
logging.getLogger("paramiko").setLevel(logging.WARNING)


# Function to get failed vio servers after an initial scan. If any vio server are found with issues, they will be added
# to this file in /tmp/

def get_failed_vioses():
    try:
        if os.path.isfile('/tmp/.failed_vioses_list_' + args.nim + "_" + args.location):
            with open('/tmp/.failed_vioses_list_' + args.nim + "_" + args.location, mode='rt',
                      encoding='latin-1') as fh:
                for i in fh.readlines():
                    failed_vioses.append(i.rstrip('\n'))
        else:
            print("No failed vios list found, you need to run a pre-check first")
            sys.exit(1)
    except Exception as e:
        print("Exception occurred: " + str(e))
        sys.exit(1)


# Function to send cfgdev command to vioses


def run_cfgdev(vios):
    try:
        ssh.connect(hostname=vios, username='padmin', port=22, timeout=5)
        ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command("ioscli cfgdev", timeout=60)
        output = ssh_stdout.readlines()
        for i in output:
            if i and len(i) > 0:
                print(i)
    except Exception as e:
        print("Exception occurred for " + str(vios).rstrip('\n') + " :" + str(e))


# Function which attempts to recover paths. First step is to set all failed paths to defined state
# 2nd step is to set all disabled paths to defined state
# 3rd step is to attempt to enable any other disabled paths
# 4th step is to configure paths back by running mkpath command


def run_fix(vios):
    try:
        ssh.connect(hostname=vios, username='padmin', port=22, timeout=5)
        ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(
            "ioscli lspath -status failed | grep -i failed | while read status disk parent connection;do ioscli rmpath -dev $disk -pdev $parent -conn $connection;done",
            timeout=60)
        output = ssh_stdout.readlines()
        for i in output:
            if i and len(i) > 0:
                print(i)
    except Exception as e:
        print("Exception occurred for " + str(vios).rstrip('\n') + " :" + str(e))

    try:
        ssh.connect(hostname=vios, username='padmin', port=22, timeout=5)
        ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(
            "ioscli lspath -status disabled | grep -i disabled | while read status disk parent connection;do ioscli rmpath -dev $disk -pdev $parent -conn $connection;done",
            timeout=60)
        output = ssh_stdout.readlines()
        for i in output:
            if i and len(i) > 0:
                print(i)
    except Exception as e:
        print("Exception occurred for " + str(vios).rstrip('\n') + " :" + str(e))

    try:
        ssh.connect(hostname=vios, username='padmin', port=22, timeout=5)
        ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(
            "echo \"failed_paths=\$(lspath -s dis -F 'status name path_id parent connection';lspath -s fai -F 'status name path_id parent connection'); set -- \$failed_paths; while [[ \$# != 0 ]];do chpath -s ena -l \$2 -p \$4 -w \$5; shift;shift;shift;shift;shift; done\" | oem_setup_env",
            timeout=60)
        output = ssh_stdout.readlines()
        for i in output:
            if i and len(i) > 0:
                print(i)
    except Exception as e:
        print("Exception occurred for " + str(vios).rstrip('\n') + " :" + str(e))

    try:
        ssh.connect(hostname=vios, username='padmin', port=22, timeout=5)
        ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(
            "echo \"def_paths=\$(lspath -s def -F 'name parent connection'); set -- \$def_paths; while [[ \$# != 0 ]];do mkpath -l \$1 -p \$2 -w \$3;shift;shift;shift; done\" | oem_setup_env",
            timeout=60)
        output = ssh_stdout.readlines()
        for i in output:
            if i and len(i) > 0:
                print(i)
    except Exception as e:
        print("Exception occurred for " + str(vios).rstrip('\n') + " :" + str(e))


# Function which will be invoked if --fix param is passed to the script. This one will run the run_fix function in
# paralled on multiple VIO servers


def FixPaths():
    try:
        get_failed_vioses()
        if len(set(failed_vioses)) > 0:
            vpool = multiprocessing.Pool(processes=multiprocessing.cpu_count() - 1)
            for i in set(failed_vioses):
                vpool.apply_async(run_fix, args=(i,))
            vpool.close()
            vpool.join()
            os.remove('/tmp/.failed_vioses_list_' + args.nim + "_" + args.location)
        else:
            print("No failed paths found, no fixing to be done")
    except Exception as ex_fp:
        print("Exception occurred while fixing paths: " + str(ex_fp))
        pass


# Function to send results by email. This will be invoked if --email param is mentioned


def send_email(EmailMessage):
    try:
        msg = MIMEText(EmailMessage)
        msg["From"] = "IBMADMIN@" + current_hostname
        msg["To"] = str(args.email)
        msg["Subject"] = "PATH Check Status for site: " + site_name
        p = Popen(["/usr/sbin/sendmail", "-t", "-oi"], stdin=PIPE, universal_newlines=True)
        p.communicate(msg.as_string())
    except Exception as e:
        print("Exception occurred while sending e-mail: " + str(e))
        pass


# Check if --fix param is passed to the script

if args.fix is True:
    try:
        FixPaths()
        sys.exit(0)
    except Exception as e:
        print("Exception occurred " + str(e))
        pass


# Define color codes for terminal. Text will be colored with green for OK messages, red for FAIL and so on

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


# Class definition to get VIO list from dsadm.hostdb file from the nim server passed as parameter to the script

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
            scp.get('/usr/local/etc/dsadm.viostsm.db', '/tmp/')
            scp.close()
            ssh.close()
            print(TermColors.BOLD + TermColors.CYAN + "Done")
            if args.location == "ALL":
                with open('/tmp/dsadm.viostsm.db', mode='rt', encoding='latin-1') as fstream:
                    for i in fstream.readlines():
                        if "#" in i:
                            continue
                        if "SAN" in i and "VIO" in i:
                            self.vios_list.append(str(i).split(':')[1].split('.')[0])
                        if "TSM" in i and "Phys" in i:
                            self.tsm_list.append(str(i).split(':')[1].split('.')[0])
            elif args.location == "POD":
                with open('/tmp/dsadm.viostsm.db', mode='rt', encoding='latin-1') as fstream:
                    for i in fstream.readlines():
                        if "#" in i:
                            continue
                        if "SAN" in i and "VIO_POD" in i:
                            self.vios_list.append(str(i).split(':')[1].split('.')[0])
                        if "TSM_POD" in i and "Phys" in i:
                            self.tsm_list.append(str(i).split(':')[1].split('.')[0])
            elif args.location == "POD1":
                with open('/tmp/dsadm.viostsm.db', mode='rt', encoding='latin-1') as fstream:
                    for i in fstream.readlines():
                        if "#" in i:
                            continue
                        if "SAN" in i and "VIO_POD" in i and "ccpx1" in i:
                            self.vios_list.append(str(i).split(':')[1].split('.')[0])
                        if "TSM_POD1" in i and "Phys" in i:
                            self.tsm_list.append(str(i).split(':')[1].split('.')[0])
            elif args.location == "POD2":
                with open('/tmp/dsadm.viostsm.db', mode='rt', encoding='latin-1') as fstream:
                    for i in fstream.readlines():
                        if "#" in i:
                            continue
                        if "SAN" in i and "VIO_POD" in i and "ccpx2" in i:
                            self.vios_list.append(str(i).split(':')[1].split('.')[0])
                        if "TSM_POD2" in i and "Phys" in i:
                            self.tsm_list.append(str(i).split(':')[1].split('.')[0])
            elif args.location == "INFRA":
                with open('/tmp/dsadm.viostsm.db', mode='rt', encoding='latin-1') as fstream:
                    for i in fstream.readlines():
                        if "#" in i:
                            continue
                        if "SAN" in i and "VIO_INFRA" in i:
                            self.vios_list.append(str(i).split(':')[1].split('.')[0])
                        if "TSM_INFRA" in i and "Phys" in i:
                            self.tsm_list.append(str(i).split(':')[1].split('.')[0])
        except Exception as e:
            log.info("Some error occurred while downloading / reading hostdb file: " + str(e))
            sys.exit(1)


# Class to check paths for VIO servers

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
        self.failed_luns = []
        global email_body

    def get_luns(self, vios):
        try:
            ssh.connect(hostname=vios, username='padmin', port=22, timeout=15)
            ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command("echo lspv -u | oem_setup_env | sed s/\ \ */\,/g")
            output = ssh_stdout.readlines()
            for i in output:
                if i and len(i) > 0:
                    self.luns.append([i])
        except:
            try:
                ssh.connect(hostname=args.nim, username='ibmadmin', timeout=15)
                ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command('nslookup ' + str(
                    vios) + '.ssm.sdc.gts.ibm.com|grep Address | grep -v "#53" | sed \'s/Address://g;s/ //g\'')
                output = ssh_stdout.readlines()
                if len(output) > 0:
                    for i in output:
                        if len(i) > 0:
                            ip = str(i).rstrip('\n')
                            ssh.connect(hostname=ip, username='padmin', port=22, timeout=15)
                            ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(
                                "echo lspv -u | oem_setup_env | sed s/\ \ */\,/g")
                            output = ssh_stdout.readlines()
                            for i in output:
                                if i and len(i) > 0:
                                    self.luns.append([i])
                else:
                    log.info(TermColors.FAIL + "[!] Unable to get data from: " + str(vios))
                    email_body.append("[!] Unable to get data from: " + str(vios))
            except Exception as e:
                log.info(TermColors.FAIL + "[!] Unable to get data from: " + str(vios) + " " + str(e))
                email_body.append("[!] Unable to get data from: " + str(vios) + " " + str(e))
                pass

    def get_wwpns(self, vios):
        try:
            ssh.connect(hostname=vios, username='padmin', port=22, timeout=15)
            ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(
                "for f in $(ioscli lsdev -type adapter | grep fcs | grep -Ei \"8Gb|16Gb FC Adapter\" | awk {'print $1'}); do wwpn=$(ioscli lsdev -dev $f -vpd | grep Network | sed s'/\.//g;s/Network Address//g;s/ //g');echo $f,$wwpn; done")
            output = ssh_stdout.readlines()
            for i in output:
                if i and len(i) > 0:
                    self.wwpns.append([i])
        except:
            try:
                ssh.connect(hostname=args.nim, username='ibmadmin', timeout=15)
                ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command('nslookup ' + str(
                    vios) + '.ssm.sdc.gts.ibm.com|grep Address | grep -v "#53" | sed \'s/Address://g;s/ //g\'')
                output = ssh_stdout.readlines()
                if len(output) > 0:
                    for i in output:
                        if len(i) > 0:
                            ip = str(i).rstrip('\n')
                            ssh.connect(hostname=ip, username='padmin', port=22, timeout=15)
                            ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(
                                "for f in $(ioscli lsdev -type adapter | grep fcs | grep -Ei \"8Gb|16Gb FC Adapter\" | awk {'print $1'}); do wwpn=$(ioscli lsdev -dev $f -vpd | grep Network | sed s'/\.//g;s/Network Address//g;s/ //g');echo $f,$wwpn; done")
                            output = ssh_stdout.readlines()
                            for i in output:
                                if i and len(i) > 0:
                                    self.wwpns.append([i])
                else:
                    log.info(TermColors.FAIL + "[!] Unable to get data from: " + str(vios))
                    email_body.append("[!] Unable to get data from: " + str(vios))
            except Exception as e:
                log.info(TermColors.FAIL + "[!] Unable to get data from: " + str(vios) + " " + str(e))
                email_body.append("[!] Unable to get data from: " + str(vios) + " " + str(e))
                pass

    def get_paths(self, vios):
        try:
            ssh.connect(hostname=vios, username='padmin', port=22, timeout=15)
            ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command('ioscli lspath | grep fscsi | sed s/\ \ */\,/g')
            output = ssh_stdout.readlines()
            for i in output:
                if i and len(i) > 0:
                    self.paths.append([i])
            self.count_paths()
        except:
            try:
                ssh.connect(hostname=args.nim, username='ibmadmin', timeout=15)
                ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command('nslookup ' + str(
                    vios) + '.ssm.sdc.gts.ibm.com|grep Address | grep -v "#53" | sed \'s/Address://g;s/ //g\'')
                output = ssh_stdout.readlines()
                if len(output) > 0:
                    for i in output:
                        if len(i) > 0:
                            ip = str(i).rstrip('\n')
                            ssh.connect(hostname=ip, username='padmin', port=22, timeout=15)
                            ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(
                                'ioscli lspath | grep fscsi | sed s/\ \ */\,/g')
                            output = ssh_stdout.readlines()
                            for i in output:
                                if i and len(i) > 0:
                                    self.paths.append([i])
                            self.count_paths()
                else:
                    log.info(TermColors.FAIL + "[!] Unable to get data from: " + str(vios))
                    email_body.append("[!] Unable to get data from: " + str(vios))
            except Exception as e:
                log.info(TermColors.FAIL + "[!] Unable to get data from: " + str(vios) + " " + str(e))
                email_body.append("[!] Unable to get data from: " + str(vios) + " " + str(e))
                pass

    def count_paths(self):
        global email_body
        for i in self.paths:
            if str(i).__contains__('Missing'):
                self.missing_paths.append(i)
            elif str(i).__contains__('Defined'):
                self.defined_paths.append(i)
            elif str(i).__contains__('Disabled'):
                self.disabled_paths.append(i)
            elif str(i).__contains__('Failed'):
                self.failed_paths.append(i)

        luns = []
        for disk in self.paths:
            luns.append(str(disk).split(',')[1])

        for failed_disk_path in self.failed_paths:
            self.disks.append(str(failed_disk_path).split(',')[1])

        for missing_disk_path in self.missing_paths:
            self.disks.append(str(missing_disk_path).split(',')[1])

        for defined_disk_path in self.defined_paths:
            self.disks.append(str(defined_disk_path).split(',')[1])

        for disabled_disk_path in self.disabled_paths:
            self.disks.append(str(disabled_disk_path).split(',')[1])

        for fail_path in self.failed_paths:
            self.hbaports.append(str(fail_path).split(',')[2])

        for defined_path in self.defined_paths:
            self.hbaports.append(str(defined_path).split(',')[2])

        for disabled_path in self.disabled_paths:
            self.hbaports.append(str(disabled_path).split(',')[2])

        for missing_path in self.missing_paths:
            self.hbaports.append(str(missing_path).split(',')[2])

        for element in set(luns):
            if str(self.vios).endswith("a") and luns.count(element) < 4:
                line = str(element) + " (" + str(luns.count(element)) + ")"
                self.failed_luns.append(line)
            elif (str(self.vios).endswith("1") or str(self.vios).endswith("2")) and luns.count(element) < 8:
                line = str(element) + " (" + str(luns.count(element)) + ")"
                self.failed_luns.append(line)

        with open(logfile, mode='at', encoding='latin-1') as f:
            for x in self.paths:
                f.writelines(str(self.vios).lower() + ": " + str(x) + "\n")
        if (len(self.failed_paths) == 0 and len(self.disabled_paths) == 0 and len(self.missing_paths) == 0 and len(
                self.defined_paths) == 0 and len(self.failed_luns) == 0):
            log.info(TermColors.OKGREEN + "OK: " + self.vios +
                     " has all paths online, total FC paths: " + str(len(self.paths)))
        else:
            log.info(TermColors.FAIL + "FAIL: " + self.vios + " has " + str(len(self.failed_paths)) +
                     " failed paths, " + str(len(self.missing_paths)) + " missing paths, " + str(
                len(self.disabled_paths)) + " disabled paths, " +
                     str(len(self.defined_paths)) + " defined paths. Total FC paths: " + str(
                len(self.paths)) + " | Affected adapter(s): " + ', '.join(sorted(set(self.hbaports))) +
                     " | Affected disk(s): " + TermColors.WARNING + ', '.join(
                sorted(set(self.disks))) + TermColors.FAIL +
                     " | Luns with not enough paths: " + TermColors.WARNING + ', '.join(self.failed_luns))

            with open('/tmp/.failed_vioses_list_' + args.nim + "_" + args.location, mode='at',
                      encoding='latin-1') as fh:
                fh.write(self.vios + "\n")

            if args.email:
                with open(mailfile, mode='at', encoding='latin-1') as mf:
                    mf.writelines("FAIL: " + self.vios + " has " + str(len(self.failed_paths)) +
                                  " failed paths, " + str(len(self.missing_paths)) + " missing paths, " + str(
                        len(self.disabled_paths)) + " disabled paths, " +
                                  str(len(self.defined_paths)) + " defined paths. Total FC paths: " + str(
                        len(self.paths)) + " | Affected adapter(s): " + ', '.join(sorted(set(self.hbaports))) +
                                  " | Luns with not enough paths: " + str(len(self.failed_luns)) + "\n")

        self.get_luns(self.vios)
        self.get_wwpns(self.vios)
        with open(logfile, mode='at', encoding='latin-1') as f:
            for x in self.luns:
                f.writelines(str(self.vios).lower() + ": " + str(x) + "\n")
        with open(logfile, mode='at', encoding='latin-1') as fw:
            for z in self.wwpns:
                fw.writelines(str(self.vios) + ":" + str(z).split(',')[0] + ":" + str(z).split(',')[1] + "\n")


# Class to check paths for TSM servers

class PathCheckTSM(object):
    def __init__(self, tsm):
        self.tsm = tsm
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
        self.failed_luns = []

    def get_luns(self, tsm):
        try:
            ssh.connect(hostname=tsm, username='ibmadmin', port=22, timeout=10)
            ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command("echo lspv -u | sed s/\ \ */\,/g")
            output = ssh_stdout.readlines()
            for i in output:
                if i and len(i) > 0:
                    self.luns.append([i])
        except:
            try:
                ssh.connect(hostname=args.nim, username='ibmadmin', timeout=10)
                ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command('nslookup ' + str(
                    tsm) + '.ssm.sdc.gts.ibm.com|grep Address | grep -v "#53" | sed \'s/Address://g;s/ //g\'')
                output = ssh_stdout.readlines()
                if len(output) > 0:
                    for i in output:
                        if len(i) > 0:
                            ip = str(i).rstrip('\n')
                            ssh.connect(hostname=ip, username='ibmadmin', port=22, timeout=10)
                            ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command("echo lspv -u | sed s/\ \ */\,/g")
                            output = ssh_stdout.readlines()
                            for i in output:
                                if i and len(i) > 0:
                                    self.luns.append([i])
                else:
                    log.info(TermColors.FAIL + "[!] Unable to get data from: " + str(tsm))
                    email_body.append("[!] Unable to get data from: " + str(tsm))
            except Exception as e:
                log.info(TermColors.FAIL + "[!] Unable to get data from: " + str(tsm) + " " + str(e))
                email_body.append("[!] Unable to get data from: " + str(tsm) + " " + str(e))
                pass

    def get_wwpns(self, tsm):
        try:
            ssh.connect(hostname=tsm, username='ibmadmin', port=22, timeout=10)
            ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(
                "for f in $(lsdev -Cc adapter | grep fcs | grep -Ei \"8Gb|16Gb FC Adapter\" | awk {'print $1'}); do wwpn=$(lscfg -vpl $f | grep Network | sed s'/\.//g;s/Network Address//g;s/ //g');echo $f,$wwpn; done")
            output = ssh_stdout.readlines()
            for i in output:
                if i and len(i) > 0:
                    self.wwpns.append([i])
        except:
            try:
                ssh.connect(hostname=args.nim, username='ibmadmin', timeout=10)
                ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command('nslookup ' + str(
                    tsm) + '.ssm.sdc.gts.ibm.com|grep Address | grep -v "#53" | sed \'s/Address://g;s/ //g\'')
                output = ssh_stdout.readlines()
                if len(output) > 0:
                    for i in output:
                        if len(i) > 0:
                            ip = str(i).rstrip('\n')
                            ssh.connect(hostname=ip, username='ibmadmin', port=22, timeout=5)
                            ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(
                                "for f in $(lsdev -Cc adapter | grep fcs | grep -Ei \"8Gb|16Gb FC Adapter\" | awk {'print $1'}); do wwpn=$(lscfg -vpl $f | grep Network | sed s'/\.//g;s/Network Address//g;s/ //g');echo $f,$wwpn; done")
                            output = ssh_stdout.readlines()
                            for i in output:
                                if i and len(i) > 0:
                                    self.wwpns.append([i])
                else:
                    log.info(TermColors.FAIL + "[!] Unable to get data from: " + str(tsm))
                    email_body.append("[!] Unable to get data from: " + str(tsm))
            except Exception as e:
                log.info(TermColors.FAIL + "[!] Unable to get data from: " + str(tsm) + " " + str(e))
                email_body.append("[!] Unable to get data from: " + str(tsm) + " " + str(e))
                pass

    def get_paths(self, tsm):
        try:
            ssh.connect(hostname=tsm, username='ibmadmin', port=22, timeout=10)
            ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(
                'lspath -F status,name,parent,connection | grep fscsi | sed s/\ \ */\,/g')
            output = ssh_stdout.readlines()
            for i in output:
                if i and len(i) > 0:
                    self.paths.append([i])
            self.count_paths()
        except:
            try:
                ssh.connect(hostname=args.nim, username='ibmadmin', timeout=10)
                ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command('nslookup ' + str(
                    tsm) + '.ssm.sdc.gts.ibm.com|grep Address | grep -v "#53" | sed \'s/Address://g;s/ //g\'')
                output = ssh_stdout.readlines()
                if len(output) > 0:
                    for i in output:
                        if len(i) > 0:
                            ip = str(i).rstrip('\n')
                            ssh.connect(hostname=ip, username='ibmadmin', port=22, timeout=10)
                            ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(
                                'lspath -F status,name,parent,connection | grep fscsi | sed s/\ \ */\,/g')
                            output = ssh_stdout.readlines()
                            for i in output:
                                if i and len(i) > 0:
                                    self.paths.append([i])
                            self.count_paths()
                else:
                    log.info(TermColors.FAIL + "[!] Unable to get data from: " + str(tsm))
                    email_body.append("[!] Unable to get data from: " + str(tsm))
            except Exception as e:
                log.info(TermColors.FAIL + "[!] Unable to get data from: " + str(tsm) + " " + str(e))
                email_body.append("[!] Unable to get data from: " + str(tsm) + " " + str(e))
                pass

    def count_paths(self):
        for i in self.paths:
            if str(i).__contains__('Missing'):
                self.missing_paths.append(i)
            elif str(i).__contains__('Defined'):
                self.defined_paths.append(i)
            elif str(i).__contains__('Disabled'):
                self.disabled_paths.append(i)
            elif str(i).__contains__('Failed'):
                self.failed_paths.append(i)

        luns = []
        for disk in self.paths:
            luns.append(str(disk).split(',')[1])

        for failed_disk_path in self.failed_paths:
            self.disks.append(str(failed_disk_path).split(',')[1])

        for missing_disk_path in self.missing_paths:
            self.disks.append(str(missing_disk_path).split(',')[1])

        for defined_disk_path in self.defined_paths:
            self.disks.append(str(defined_disk_path).split(',')[1])

        for disabled_disk_path in self.disabled_paths:
            self.disks.append(str(disabled_disk_path).split(',')[1])

        for fail_path in self.failed_paths:
            self.hbaports.append(str(fail_path).split(',')[2])

        for defined_path in self.defined_paths:
            self.hbaports.append(str(defined_path).split(',')[2])

        for disabled_path in self.disabled_paths:
            self.hbaports.append(str(disabled_path).split(',')[2])

        for missing_path in self.missing_paths:
            self.hbaports.append(str(missing_path).split(',')[2])

        for element in set(luns):
            if str(self.tsm).endswith("a") and luns.count(element) < 4:
                line = str(element) + " (" + str(luns.count(element)) + ")"
                self.failed_luns.append(line)
            elif (str(self.tsm).endswith("1") or str(self.tsm).endswith("2")) and luns.count(element) < 4:
                line = str(element) + " (" + str(luns.count(element)) + ")"
                self.failed_luns.append(line)

        with open(logfile, mode='at', encoding='latin-1') as f:
            for x in self.paths:
                f.writelines(str(self.tsm).lower() + ": " + str(x) + "\n")

        if (len(self.failed_paths) == 0 and len(self.disabled_paths) == 0 and len(self.missing_paths) == 0 and len(
                self.defined_paths) == 0 and len(self.failed_luns) == 0):
            log.info(TermColors.OKGREEN + "OK: " + self.tsm +
                     " has all paths online, total FC paths: " + str(len(self.paths)))
        else:
            log.info(TermColors.FAIL + "FAIL: " + self.tsm + " has " + str(len(self.failed_paths)) +
                     " failed paths, " + str(len(self.missing_paths)) + " missing paths, " + str(
                len(self.disabled_paths)) + " disabled paths, " +
                     str(len(self.defined_paths)) + " defined paths. Total FC paths: " + str(
                len(self.paths)) + " | Affected adapter(s): " + ', '.join(sorted(set(self.hbaports))) +
                     " | Affected disk(s): " + TermColors.WARNING + ', '.join(
                sorted(set(self.disks))) + TermColors.FAIL +
                     " | Luns with not enough paths: " + TermColors.WARNING + ', '.join(self.failed_luns))

            with open('/tmp/.failed_vioses_list_' + args.nim + "_" + args.location, mode='at',
                      encoding='latin-1') as fh:
                fh.write(self.tsm + "\n")

            if args.email:
                with open(mailfile, mode='at', encoding='latin-1') as mf:
                    mf.writelines("FAIL: " + self.tsm + " has " + str(len(self.failed_paths)) +
                                  " failed paths, " + str(len(self.missing_paths)) + " missing paths, " + str(
                        len(self.disabled_paths)) + " disabled paths, " +
                                  str(len(self.defined_paths)) + " defined paths. Total FC paths: " + str(
                        len(self.paths)) + " | Affected adapter(s): " + ', '.join(sorted(set(self.hbaports))) +
                                  " | Luns with not enough paths: " + str(len(self.failed_luns)) + "\n")

            self.get_luns(self.tsm)
            self.get_wwpns(self.tsm)
            with open(logfile, mode='at', encoding='latin-1') as f:
                for x in self.luns:
                    f.writelines(str(self.tsm).lower() + ": " + str(x) + "\n")
            with open(logfile, mode='at', encoding='latin-1') as fw:
                for z in self.wwpns:
                    fw.writelines(str(self.tsm) + ":" + str(z).split(',')[0] + ":" + str(z).split(',')[1] + "\n")


# Get the vios list

get_list = GetSystemList()
get_list.get_vios_list()

# Start multiprocessing for vios Path Checks. It will use CPUs - 1. You can adjust it to your liking

pool = multiprocessing.Pool(processes=multiprocessing.cpu_count() - 1)
for i in get_list.vios_list:
    updater = PathCheck(i)
    pool.apply_async(updater.get_paths, args=(i,))
pool.close()
pool.join()

# Start multiprocessing for TSM Path Checks. It will use CPUs - 1. You can adjust it to your liking

pool_tsm = multiprocessing.Pool(processes=multiprocessing.cpu_count() - 1)
for i in get_list.tsm_list:
    updater_tsm = PathCheckTSM(i)
    pool_tsm.apply_async(updater_tsm.get_paths, args=(i,))
pool_tsm.close()
pool_tsm.join()

with open('/tmp/path_check_' + args.type + "_" + str(current_date) + '.log', mode='rt', encoding='latin-1') as f:
    for line in f.readlines():
        if "OK" in line:
            okinfo.append(line)
        elif "Unable" in line:
            warninfo.append(line)
        elif "FAIL" in line:
            errors.append(line)

if len(errors) > 0:
    print("\n\n")
    print(TermColors.FAIL + TermColors.BOLD)
    print("------ Summary Results ------")
    print("------ Path check result is FAILED ------")
    print("------ Log file is " + '/tmp/path_check_' + args.type + "_" + str(current_date) + ".log")
    if args.email:
        try:
            MailBody = ""
            with open(mailfile, mode='rt', encoding='latin-1') as mf:
                for line in mf.readlines():
                    MailBody += str(line)
            print(MailBody)
            send_email(MailBody)
            os.remove(mailfile)
        except Exception as e:
            print("Exception occurred " + str(e))
            pass
    sys.exit(1)
elif len(warninfo) > 0:
    print("\n\n")
    print(TermColors.WARNING + TermColors.BOLD)
    print("------ Summary Results ------")
    print("------ Path check result is PASSED with WARNING, some systems might not be reachable via ssh ------")
    print("------ Log file is " + '/tmp/path_check_' + args.type + "_" + str(current_date) + ".log")
    if args.email:
        try:
            MailBody = ""
            with open(mailfile, mode='rt', encoding='latin-1') as mf:
                for line in mf.readlines():
                    MailBody += str(line)
            print(MailBody)
            send_email(MailBody)
            os.remove(mailfile)
        except Exception as e:
            print("Exception occurred " + str(e))
            pass
    sys.exit(2)
elif len(okinfo) > 0:
    print("\n\n")
    print(TermColors.OKGREEN + TermColors.BOLD)
    print("------ Summary Results ------")
    print("------ Path check result is PASSED ------")
    print("------ Log file is " + '/tmp/path_check_' + args.type + "_" + str(current_date) + ".log")
    sys.exit(0)
