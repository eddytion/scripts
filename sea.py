import paramiko
import sys
import datetime
import threading
import logging

sys.tracebacklimit = 0
if len(sys.argv) < 1:
    logging.error("Not enough arguments")
    sys.exit(1)

ssh = paramiko.SSHClient()
ssh.load_system_host_keys()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy)

current_date = datetime.date.today()
hmcpassword = "start1234"
clusters = []


def get_ms_list(ip):
    #print("Getting info from " + str(ip))
    try:
        ssh.connect(hostname=ip, port=22, username='ibmadmin', timeout=5)
        ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(
            "lspv | grep caavg")
        output = ssh_stdout.readlines()
        for line in output:
            if "caavg" in line:
                mystring = ip + ":" + "Cluster node: YES"
                clusters.append(mystring)
    except:
        print("Unable to get info from " + str(ip))
    finally:
        pass


threads = []

for x in sys.argv[1:]:
    if x:
        t = threading.Thread(target=get_ms_list, args=(x,))
        threads.append(t)

for i in threads:
    i.start()
    i.join()

print("\n------------------------------------------------------\n")
for line in clusters:
    print(line)
print("\n------------------------------------------------------\n")
