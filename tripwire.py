import paramiko
import sys
import datetime
import multiprocessing
import logging

"""
Edit this line and add your command
"""

cmd2run = "sudo /usr/local/tripwire/te/agent/bin/uninstall.sh --removeall --force"
logging.basicConfig(filename='/tmp/tripwire_fix.log', level=logging.INFO)
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


def fix_tad4d(ip):
    try:
        ssh.connect(hostname=ip, port=22, username='ibmadmin', timeout=60)
        ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(cmd2run)
        output = ssh_stdout.readlines()
        for i in output:
            if i and len(i) > 0:
                print(ip + ":" + i.rstrip('\n'))
    except:
        print("[+] Unable to connect to: " + str(ip))
    finally:
        pass


threads = []

pool = multiprocessing.Pool(4)
for i in sys.argv[1:]:
    pool.apply_async(fix_tad4d, args=(i,))
pool.close()
pool.join()
