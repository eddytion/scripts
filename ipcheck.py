#!/usr/bin/env python3

import paramiko
import sys
import time
import logging
import os
import multiprocessing

# Global vars

current_date = time.strftime('%Y-%m-%d-%H_%M_%S')
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
sys.tracebacklimit = 0
logging.basicConfig(filename='/tmp/ipcheck_logfile.log', level=logging.DEBUG)

# Check script's arguments

if len(sys.argv) < 2:
    print("Not enough arguments")
    print("Usage: " + sys.argv[0] + " <ip_address>")
    sys.exit(1)


# Define main class and methods


class IPCheck(object):
    def __init__(self, hostname):
        print("")
        self.hostname = hostname
        self.ip = ""
        self.nim = ""

    @staticmethod
    def check_etc_hosts(hostname):
        try:
            if str(hostname) in open('/etc/hosts').read():
                print("[+] " + str(hostname) + " already exists in /etc/hosts:")
                with open('/etc/hosts', 'r') as f:
                    for line in f.readlines():
                        if str(hostname) in line and "ibr" not in line:
                            if line:
                                print("[+] " + line)
                return True
            else:
                print(str(hostname) + " does not exist in /etc/hosts")
                return False
        except Exception as e:
            print("Some error occured while trying to read /etc/hosts ===> " + str(e))
            return False

    def check_nim(self):
        try:
            self.nim = str(sys.argv[1])[0:4] + "nim011ccpxa"
            return self.nim
        except Exception as e:
            print("Unable to parse hostname " + str(e))
            return False

    def get_ip_from_nim(self, hostname):
        try:
            ssh.connect(hostname=self.nim, username='ibmadmin', timeout=5)
            ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command('nslookup ' + str(
                hostname) + '.ssm.sdc.gts.ibm.com|grep Address | grep -v "#53" | sed \'s/Address://g;s/ //g\'')
            output = ssh_stdout.readlines()
            if len(output) > 0:
                for i in output:
                    if len(i) > 0:
                        self.ip = str(i).rstrip(
                            '\n') + "\t" + self.hostname + "\t" + self.hostname + ".ssm.sdc.gts.ibm.com"
                        print("[+] Result from nim:")
                        print("[+] " + self.ip)
                    else:
                        print("[-] Some error occured while trying to get IP address from NIM")
                        sys.exit(1)
            else:
                print("[-] Some error occured while trying to get IP address from NIM for " + hostname)
                sys.exit(1)
        except Exception as e:
            print("[-] Unable to get IP from NIM " + hostname + " ===> " + str(e))
            sys.exit(1)

    def write2file(self):
        try:
            with open(os.environ['HOME'] + '/ipcheck_results.txt', 'a+') as f:
                f.write(self.ip + "\n")
        except Exception as e:
            print("Some error occured while saving results to file ===> " + str(e))
            return False


checker = IPCheck(sys.argv[1])
checker.check_etc_hosts(sys.argv[1])
checker.check_nim()
checker.get_ip_from_nim(sys.argv[1])
checker.write2file()
print("")
