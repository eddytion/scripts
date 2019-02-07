#!/usr/bin/python3.6

import paramiko
import sys
import datetime

sys.tracebacklimit = 0
if len(sys.argv) < 3:
    print("Not enough arguments")
    sys.exit(1)

ssh = paramiko.SSHClient()
ssh.load_system_host_keys()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy)

current_date = datetime.date.today()
results = []


def close_event(ip, problem):
    try:
        print("\n")
        print("[+] Attempting to connect to " + str(sys.argv[1]) + " using hscroot and default password")
        ssh.connect(hostname=ip, port=22, username='hscroot', password="start1234", timeout=15)
        print("[+] Attempting to close event " + str(sys.argv[2]) + " on HMC " + str(sys.argv[1]))
        print("[+] Sending the following command to " + str(sys.argv[1]) + ": chsvcevent -o close -p " +
              str(sys.argv[2]) + " -h " + str(ip))
        ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command("chsvcevent -o close -p " + str(problem) + " -h " + str(ip))
        output = ssh_stdout.readlines()
        for line in output:
            if len(line) > 0:
                results.append([ip, line])
        print("[+] Done")
    except Exception as e:
        print("[!] Unable to close event on " + str(ip))
        print("[!] System returned the following error: " + str(e))
    finally:
        pass


close_event(str(sys.argv[1]), str(sys.argv[2]))

for line in results:
    if line:
        print(str(line[0]).rstrip('\n') + ": " + str(line[1]).rstrip('\n'))
