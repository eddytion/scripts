#!/usr/bin/env /usr/bin/python3

import paramiko
import sys
import datetime
import multiprocessing
import logging
import time
import argparse

HMCPASSWD = "1234"
HMCUSER = "hscroot"

current_date = datetime.date.today()
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
sys.tracebacklimit = 0
if len(sys.argv) < 1:
    logging.error("Not enough arguments")
    sys.exit(1)

logging.basicConfig(filename='/tmp/itcs104_logfile.log', level=logging.INFO)

# Parser definition

parser = argparse.ArgumentParser(description="Apply ITCS-104 policies")
requiredParams = parser.add_argument_group('required arguments')
requiredParams.add_argument("-hmc", help="HMC list", nargs='+', required=True, type=str)
parser.add_argument("-tmo", help="Timeout for SSH connection in seconds (default 5 sec)", default=5, required=False,
                    type=int)
args = parser.parse_args()
print(args)

# Logging definition and formmating. Also, configure paramiko to show only warnings on screen during execution

logfile = '/tmp/itcs104_output_' + "_" + str(current_date) + ".log"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(message)s",
    handlers=[
        logging.FileHandler(logfile),
        logging.StreamHandler()
    ])

log = logging.getLogger()
logging.getLogger("paramiko").setLevel(logging.WARNING)


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


def get_lpars_from_hmc(hmc):
    print(TermColors.OKGREEN + "Getting lpar list from: " + str(hmc) + TermColors.ENDC)
    lpars = []
    cmd = "for m in $(lssyscfg -r sys -F name); do for l in $(lssyscfg -r lpar -m $m -F name:lpar_env:state:rmc_ipaddr | grep -v Not); do echo $m:$l; done; done"
    try:
        ssh.connect(hostname=hmc, username=HMCUSER, port=22, timeout=args.tmo, password=HMCPASSWD)
        ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(cmd, timeout=args.tmo)
        output = ssh_stdout.readlines()
        for i in output:
            if i and len(i) > 0:
                lpars.append(str(i))
                print(str(i).rstrip('\n'))
    except:
        try:
            site = hmc[:4]
            sobox = site + "sob011ccpsa"
            ssh.connect(hostname=sobox, username='root', timeout=args.tmo)
            ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command('nslookup ' + str(
                hmc) + '.ssm.sdc.gts.ibm.com|grep Address | grep -v "#53" | sed \'s/Address://g;s/ //g\'')
            output = ssh_stdout.readlines()
            if len(output) > 0:
                for i in output:
                    if len(i) > 0:
                        ip = str(i).rstrip('\n')
                        ssh.connect(hostname=ip, username=HMCUSER, port=22, timeout=args.tmo, password=HMCPASSWD)
                        ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(cmd, timeout=args.tmo)
                        output = ssh_stdout.readlines()
                        for i in output:
                            if i and len(i) > 0:
                                lpars.append(str(i))
                                print(str(i).rstrip('\n'))
            else:
                log.info(TermColors.FAIL + "[!] Unable to get DNS info from: " + str(sobox) + TermColors.ENDC)
        except Exception as e:
            log.info(TermColors.FAIL + "[!] Unable to get lpar list from: " + str(hmc) + " " + str(e) + TermColors.ENDC)
            pass
    return lpars


# def run_ssh(host, user, cmd):
#     try:
#         print("Running " + str(cmd))
#         ssh.connect(hostname=host, username=user, port=22, timeout=args.tmo)
#         ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(cmd, timeout=args.tmo)
#         output = ssh_stdout.readlines()
#         for i in output:
#             if i and len(i) > 0:
#                 print(str(host) + ": " + str(i).rstrip('\n'))
#     except:
#         try:
#             print("Running inside except")
#             site = host[:4]
#             sobox = site + "nim011ccpxa"
#             ssh.connect(hostname=sobox, username=user, timeout=args.tmo)
#             ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command('nslookup ' + str(
#                 host) + '.ssm.sdc.gts.ibm.com|grep Address | grep -v "#53" | sed \'s/Address://g;s/ //g\'')
#             output = ssh_stdout.readlines()
#             if len(output) > 0:
#                 for i in output:
#                     if len(i) > 0:
#                         ip = str(i).rstrip('\n')
#                         print(host + " has IP " + str(ip))
#                         ssh.connect(hostname=ip, username=user, port=22, timeout=args.tmo)
#                         ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(cmd, timeout=args.tmo)
#                         output = ssh_stdout.readlines()
#                         for i in output:
#                             if i and len(i) > 0:
#                                 print(str(host) + ": " + str(i).rstrip('\n'))
#             else:
#                 log.info(TermColors.FAIL + "[!] Unable to get DNS info from: " + str(sobox) + TermColors.ENDC)
#         except Exception as e:
#             log.info(TermColors.FAIL + "[!] Unable to run remote command on: " + str(host) + " " + str(e) + TermColors.ENDC)
#             pass

def run_ssh(host, user, cmd):
    ssh.connect(hostname=host, username=user, timeout=120)
    ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(cmd, timeout=60)
    output = ssh_stdout.readlines()
    for i in output:
        if len(i) > 0:
            print(i)

def apply_itcs104_policies_aix(host):
    print("Applying ITCS104 policies for AIX for " + str(host))
    run_ssh(str(host), "ibmadmin", "uname -a")


def apply_itcs104_policies_vios(host):
    print("Applying ITCS104 policies for VIOS for " + str(host))
    run_ssh(str(host), "padmin", "uname -a")


aixlpars = []
vioses = []


for hmc in args.hmc:
    serverlist = get_lpars_from_hmc(hmc)
    for s in serverlist:
        if s.__contains__("aixlinux"):
            aixlpars.append(s)
        elif s.__contains__("vioserver"):
            vioses.append(s)
        else:
            print(TermColors.WARNING + "ZZZ Unknown system type " + str(s).split(':')[2] + TermColors.ENDC)

# Start multiprocessing for AIX ITCS104. It will use CPUs - 1. You can adjust it to your liking

# pool = multiprocessing.Pool(processes=multiprocessing.cpu_count() - 1)
# for i in aixlpars:
#     if i.__contains__("ccpx"):
#         server = i.split(':')[1]
#         systemtype = i.split(':')[2]
#         pool.apply_async(apply_itcs104_policies_aix, args=(server, ))
# pool.close()
# pool.join()

# # Start multiprocessing for VIOS ITCS104. It will use CPUs - 1. You can adjust it to your liking
#
pool = multiprocessing.Pool(processes=multiprocessing.cpu_count() - 4)
for i in vioses:
    if i.__contains__("ccpx"):
        server = i.split(':')[1]
        systemtype = i.split(':')[2]
        pool.apply_async(apply_itcs104_policies_vios, args=(server, ))
pool.close()
pool.join()
