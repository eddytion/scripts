import paramiko
import sys
import datetime
import multiprocessing
import logging

"""
Edit this line and add your command
"""
cmd2run = "echo /sds/local/sceplus/sup/AIX/bin/check_tsm_backups.sh | oem_setup_env"
# cmd2run = "if [[ `uname` == \"AIX\" ]]; then lslpp -l | grep -i tad; else rpm -qa | grep TAD4D; fi"
# cmd2run = "ps -ef | egrep -i \"tlmagent|wscan\" | grep -v SCM | grep -v grep"
# cmd2run = "sudo ls -l /opt/tivoli/cit/bin | wc -l"
# cmd2run = "if [[ `uname` == \"AIX\" ]]; then sudo stopsrc -s tlmagent; sudo /opt/itlm/tlmagent -resetcache; " \
#          "sudo startsrc -s tlmagent; else sudo /var/itlm/tlmagent -e; sudo /var/itlm/tlmagent -resetcache; " \
#          "sudo /var/itlm/tlmagent -g; fi"
# cmd2run = "startsrc -s tlmagent"
# cmd2run = "if [[ `uname` == \"AIX\" ]]; then sudo /opt/itlm/tlmagent -s; else sudo /var/itlm/tlmagent -s; fi"
# cmd2run = "if [[ `uname` == \"AIX\" ]]; then sudo /opt/itlm/tlmagent -p; else sudo /var/itlm/tlmagent -p; fi"
# cmd2run = "if [[ `uname` == \"AIX\" ]]; then sudo /opt/itlm/tlmagent -cmds | grep successful; " \
#          "else sudo /var/itlm/tlmagent -cmds | grep successful; fi"
# cmd2run = "if [[ `uname` == \"AIX\" ]]; then sudo /opt/itlm/tlmagent -hw; else sudo /var/itlm/tlmagent -hw; fi"
# cmd2run = "if [[ `uname` == \"AIX\" ]]; then sudo startsrc -s tlmagent; else sudo /var/itlm/tlmagent -g; fi"
# cmd2run = "sudo /tmp/7.5.0-TIV-ILMT-TAD4D-IF0026-agent-linux-x86.bin -install"
# cmd2run = "sudo install_all_updates -d /sds/aix/TAD4D/7.5"
logging.basicConfig(filename='/tmp/tad4d_fix.log', level=logging.INFO)
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
        ssh.connect(hostname=ip, port=22, username='padmin', timeout=20)
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

pool = multiprocessing.Pool(6)
for i in sys.argv[1:]:
    pool.apply_async(fix_tad4d, args=(i,))
pool.close()
pool.join()
