#!/usr/bin/env /usr/bin/python3

import paramiko
import time
import multiprocessing
import logging
import argparse
import socket
import sys

current_hostname = socket.gethostname()
current_date = time.strftime('%Y-%m-%d-%H_%M_%S')
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
sys.tracebacklimit = 0

# Parser definition

parser = argparse.ArgumentParser(description="Run a command on multiple systems in parallel")
requiredParams = parser.add_argument_group('required arguments')
requiredParams.add_argument("-hosts", help="Host list", nargs='+', required=True, type=str)
requiredParams.add_argument("-cmd", help="Command to run on target host(s)", default='date', required=True, type=str)
parser.add_argument("-user", help="Username (default ibmadmin)", default='ibmadmin', required=False, type=str)
parser.add_argument("-tmo", help="Timeout for SSH connection in seconds (default 5 sec)", default=5, required=False, type=int)
args = parser.parse_args()
# print(args)
logfile = '/tmp/dsh_output_' + "_" + str(current_date) + ".log"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(message)s",
    handlers=[
        logging.FileHandler(logfile),
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


class RunDSH(object):
    def __init__(self, host):
        self.host = host

    def RunCMD(self, host):
        try:
            ssh.connect(hostname=host, username=args.user, port=22, timeout=args.tmo)
            ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(args.cmd)
            output = ssh_stdout.readlines()
            for i in output:
                if i and len(i) > 0:
                    log.info(TermColors.OKGREEN + str(host) + ": " + str(i).rstrip('\n'))
                else:
                    log.info(TermColors.OKGREEN + str(host) + ": No data received")
        except Exception as e:
            log.info(TermColors.FAIL + "[!] Unable to get data from: " + str(host) + " " + str(e).rstrip('\n'))


print("-" * 100)
dsh = RunDSH
pool = multiprocessing.Pool(processes=multiprocessing.cpu_count() - 1)
for i in args.hosts:
    runner = dsh(i)
    pool.apply_async(runner.RunCMD, args=(i, ))
pool.close()
pool.join()
