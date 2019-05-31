#!/bin/python3.6

import paramiko
import sys
import datetime
import multiprocessing
import logging
import time
import base64
import requests

UPLOAD_URL = "https://localhost/upload_hw_events.php"
HMCUSER = "hscroot"
HMCPASSWD = "abc1234"

current_date = datetime.date.today()
mysql_date = time.strftime('%Y-%m-%d %H:%M:%S')
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
threads = []
requests.packages.urllib3.disable_warnings()

sys.tracebacklimit = 0
if len(sys.argv) < 2:
    logging.error("Specify at least 1 HMC. HMCs must be separated by space")
    sys.exit(1)

logging.basicConfig(filename='/tmp/hmc_events_logfile.log', level=logging.INFO)


class HmcEvents(object):
    def __init__(self, hmc):
        self.hmc = hmc
        self.events = []
        self.events_csv = "/tmp/events_" + str(hmc) + "_" + str(current_date) + ".csv"
        self.encoded_file = "/tmp/events_" + str(hmc) + "_" + str(current_date) + ".b64"

    def get_hw_events(self, hmc):
        try:
            ssh.connect(hostname=hmc, username=HMCUSER, password=HMCPASSWD, timeout=30, allow_agent=False, look_for_keys=False)
            ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(
                'lssvcevents -t hardware -F problem_num,pmh_num,refcode,status,first_time,sys_name,sys_mtms,enclosure_mtms,text',
                timeout=30)
            output = ssh_stdout.readlines()
            for i in output:
                if len(i) > 0 and "No results were found." not in i:
                    self.events.append([i])
            with open(self.events_csv, 'w') as f:
                for line in self.events:
                    if "#" not in line[0]:
                        print('DEFAULT' + ',' + str(hmc) + ',' + mysql_date + ',' + line[0])
                        f.write('DEFAULT' + ',' + str(hmc) + ',' + mysql_date + ',' + line[0])
        except Exception as e:
            print("Exception occurred for " + str(hmc) + " : " + str(e))
            with open(self.events_csv, 'w') as f:
                f.write("DEFAULT," + str(
                    hmc) + ',' + mysql_date + ",99999,Script_ERR,Python_ERR,Open," + mysql_date + "," + str(
                    hmc) + "," + str(
                    hmc) + "," + str(hmc) + ",\"Error reported by script: " + str(e) + "\"")
        finally:
            ssh.close()

    def update_database_hw_events(self):
        try:
            print("Encoding file")
            with open(self.events_csv, "rb") as file:
                encoded_file = base64.b64encode(file.read())
            print("Generating payload")
            paylod = {'content': encoded_file, 'submit': 'SUBMIT', 'file_name': self.encoded_file, 'hmc': self.hmc}
            r = requests.post(url=UPLOAD_URL, data=paylod, verify=False)
            print(r.text)
        except Exception as e:
            print("Exception occurred during data upload for " + str(self.hmc) + " : " + str(e))
            pass


pool = multiprocessing.Pool(processes=6)
for i in sys.argv[1:]:
    updater = HmcEvents(i)
    pool.apply_async(updater.get_hw_events, args=(i,))
pool.close()
pool.join()

for i in sys.argv[1:]:
    updater = HmcEvents(i)
    updater.update_database_hw_events()
