#!/bin/python3.6

import paramiko
import sys
import datetime
import logging
import threading

current_date = datetime.date.today()
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
threads = []

sys.tracebacklimit = 0
if len(sys.argv) < 2:
    logging.error("Not enough arguments")
    sys.exit(1)

lpars = []


def get_lpars(nim):
    ssh.connect(hostname=nim, username='ibmadmin', timeout=120)
    ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command('sudo ls -d /export/nim/mksysb/CLI/*/')
    output = ssh_stdout.readlines()
    for i in output:
        srv = str(i).split('/')[5]
        lpars.append(srv)


def get_mksysb_log_file(server, nim):
    ssh.connect(hostname=nim, username='ibmadmin', timeout=120)
    ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(
        'sudo ls -ltr /export/nim/mksysb/CLI/' + str(server) + "/*.log | tail -1 | awk {'print $9'}")
    output = ssh_stdout.readlines()
    for file in output:
        ssh.connect(hostname=nim, username='ibmadmin', timeout=120)
        ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command('sudo egrep -w "mkszfile:|mksysb:|0512-" ' + str(file))
        output = ssh_stdout.readlines()
        for i in set(output):
            if "Backup Completed Successfully." not in str(i) and "Backup Completed." not in str(i):
                print(server + ": " + str(file).split('_')[3].split('.')[0].rstrip('\n') + ": " + str(i).rstrip('\n'))


get_lpars(sys.argv[1])
for x in lpars:
    t = threading.Thread(target=get_mksysb_log_file, args=(x, sys.argv[1]))
    threads.append(t)

for i in threads:
    i.start()
    i.join()
