import paramiko
import sys
import datetime
import logging

current_date = datetime.date.today()
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

lspvu = []
lspvsize = []
combinedlspv = []
lsmap = []
result = []

sys.tracebacklimit = 0
if len(sys.argv) < 1:
    logging.error("Not enough arguments")
    sys.exit(1)

logging.basicConfig(filename='/tmp/cloud_logfile.log', level=logging.INFO)

ssh.connect(hostname=sys.argv[1], username='padmin', timeout=120)
ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(
    'echo lspv -u | oem_setup_env | grep fcp | sed -e \'s/\ \ */,/g;s/\,$//g\'')
output = ssh_stdout.readlines()
for i in output:
    lspvu.append(i)

ssh.connect(hostname=sys.argv[1], username='padmin', timeout=120)
ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command('ioscli lspv -size | sed -e \'s/\ \ */,/g;s/\,$//g\'')
output = ssh_stdout.readlines()
for i in output:
    if "NAME" not in i:
        lspvsize.append(i)

ssh.connect(hostname=sys.argv[1], username='padmin', timeout=120)
ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command('ioscli lsmap -all -field svsa clientid backing -fmt \',\' 2>&1')
output = ssh_stdout.readlines()
for i in output:
    lsmap.append(i)


for i in lspvsize:
    for j in lspvu:
        if str(i).split(',')[0] == str(j).split(',')[0]:
            combinedlspv.append(
                str(i).split(',')[0] + "," + str(i).split(',')[1] + "," + str(i).split(',')[2].rstrip('\n') + "," +
                str(j).split(',')[3][5:37].rstrip('\n'))

for x in combinedlspv:
    for y in lsmap:
        if str(x).split(',')[0] != str(y).split(',')[0]:
            result.append(x)

for value in result:
    print(value)
