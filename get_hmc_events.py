#!/bin/python3.6

import paramiko
import sys
import datetime
import multiprocessing
import logging
import mysql.connector

DBUSER = "root"
DBPASS = "mariadbpwd"
DBHOST = "localhost"
DBNAME = "events"
DBPORT = 3306

current_date = datetime.date.today()
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
threads = []

sys.tracebacklimit = 0
if len(sys.argv) < 1:
    logging.error("Not enough arguments")
    sys.exit(1)

logging.basicConfig(filename='/tmp/hmc_events_logfile.log', level=logging.INFO)
mydb = mysql.connector.connect(
    host=DBHOST,
    user=DBUSER,
    passwd=DBPASS,
    database=DBNAME
)

mycursor = mydb.cursor()


class HmcEvents(object):
    def __init__(self, hmc):
        self.hmc = hmc
        self.events = []
        self.events_csv = "/tmp/events_" + str(hmc) + "_" + str(current_date) + ".csv"

    def get_hw_events(self, hmc):
        ssh.connect(hostname=hmc, username='hscroot', password='start1234', timeout=120)
        ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command('lssvcevents -t hardware --filter \'status=Open\' -F problem_num,pmh_num,refcode,status,first_time,sys_name,sys_mtms,enclosure_mtms,text')
        output = ssh_stdout.readlines()
        for i in output:
            if len(i) > 0 and "No results were found." not in i:
                self.events.append([i])
        with open(self.events_csv, 'a') as f:
            for line in self.events:
                if "#" not in line[0]:
                    print('DEFAULT' + ',' + str(hmc) + ',' + line[0])
                    f.write('DEFAULT' + ',' + str(hmc) + ',' + line[0])

    def update_database_hw_events(self):
        try:
            query = "LOAD DATA LOCAL INFILE '" + self.events_csv + "' IGNORE INTO TABLE events.hw_events FIELDS TERMINATED BY ',' ENCLOSED BY '\"' LINES TERMINATED BY '\n'"
            mycursor.execute(query)
            mydb.commit()
        except:
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
