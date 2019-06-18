import paramiko
import sys
import datetime
import threading
import logging

"""
Edit this line and add your command
"""
cmd2run = "ioscli lsdev -type adapter | grep 802.3ad; ioscli lsdev -type adapter | grep Shared; for agg in $(ioscli lsdev -type adapter | grep 802.3ad | awk {'print $1'}); do for sea in $(ioscli lsdev -type adapter | grep Shared | awk {'print $1'}); do ioscli lsdev -dev $sea -attr | grep $agg; done; done; echo"

sys.tracebacklimit = 0
if len(sys.argv) < 1:
    logging.error("Not enough arguments")
    sys.exit(1)

ssh = paramiko.SSHClient()
ssh.load_system_host_keys()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy)

current_date = datetime.date.today()
results = []
vios = ['vsa', 'vsb', 'vna', 'vnb']


def run_dsh(ip):
    try:
        if "vsa" or "vsb" in vios:
            ssh.connect(hostname=ip, port=22, username='padmin', timeout=50)
            ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(cmd2run)
            output = ssh_stdout.readlines()
            for line in output:
                if len(line) > 0:
                    results.append([ip, line])
        elif "hmc" in ip:
            ssh.connect(hostname=ip, port=22, username='hscroot', password="start1234", timeout=50)
            ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(cmd2run)
            output = ssh_stdout.readlines()
            for line in output:
                if len(line) > 0:
                    results.append([ip, line])
        else:
            ssh.connect(hostname=ip, port=22, username='ibmadmin', timeout=50)
            ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(cmd2run)
            output = ssh_stdout.readlines()
            for line in output:
                if len(line) > 0:
                    results.append([ip, line])
    except:
        print("[+] Unable to get info from " + str(ip)) + str(Exception)
    finally:
        pass


threads = []

for x in sys.argv[1:]:
    if x:
        t = threading.Thread(target=run_dsh, args=(x,))
        threads.append(t)

for i in threads:
    i.start()
    i.join()

print("\n------------------------------------------------------\n")
for line in results:
    if line:
        print(str(line[0]).rstrip('\n') + ": " + str(line[1]).rstrip('\n'))
print("\n------------------------------------------------------\n")
