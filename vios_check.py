import paramiko
import sys
import datetime
import multiprocessing
import logging
import mysql.connector
import os
import time


DBUSER = "root"
DBPASS = "mariadbpwd"
DBHOST = "localhost"
DBNAME = "sap"
DBPORT = 3306

current_date = datetime.date.today()
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
threads = []

sys.tracebacklimit = 0
if len(sys.argv) < 1:
    logging.error("Not enough arguments")
    sys.exit(1)

logging.basicConfig(filename='/tmp/vios_check.log', level=logging.INFO)
mydb = mysql.connector.connect(
    host=DBHOST,
    user=DBUSER,
    passwd=DBPASS,
    database=DBNAME
)

mycursor = mydb.cursor()


class CheckVios(object):
    def __init__(self, vios):
        self.vios = vios
        self.network = []
        self.network_csvfile = "/tmp/" + str(vios) + "_tunables_" + str(current_date) + ".csv"
        self.network_buffers = []
        self.network_buffers_csvfile = "/tmp/" + str(vios) + "_buffers_" + str(current_date) + ".csv"
        self.lppchk = []
        self.sea = []
        self.buffers = []
        self.fscsi = []
        self.fcs = []
        self.memory = []
        self.disks = []
        self.ioslevel = []

    def get_network_tunables(self, vios):
        ssh.connect(hostname=vios, username='padmin', password='start1234', timeout=10)
        ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command("echo \"no -o rfc1323 -o tcp_sendspace -o tcp_recvspace -o tcp_nodelayack -o sack -o udp_sendspace -o udp_recvspace | sed 's/ //g'\" | oem_setup_env")
        output = ssh_stdout.readlines()
        for i in output:
            if i and len(i) > 0:
                self.network.append(i.rstrip('\n'))
                # print(i)

    def validate_network_tunables(self, vios):
        for i in self.network:
            if "rfc1323" in i:
                if int(i.split('=')[1]) == 1:
                    print(vios + ": " + "RFC1323 - OK")
                else:
                    print(vios + ": " + "RFC1323 - NOK")

            if "tcp_sendspace" in i:
                if int(i.split('=')[1]) == 524288:
                    print(vios + ": " + "TCP SendSpace - OK")
                else:
                    print(vios + ": " + "TCP SendSpace - NOK")

            if "tcp_recvspace" in i:
                if int(i.split('=')[1]) == 524288:
                    print(vios + ": " + "TCP RecvSpace - OK")
                else:
                    print(vios + ": " + "TCP RecvSpace - NOK")

            if "tcp_nodelayack" in i:
                if int(i.split('=')[1]) == 1:
                    print(vios + ": " + "TCP NoDelayAck - OK")
                else:
                    print(vios + ": " + "TCP NoDelayAck - NOK")

            if "sack" in i:
                if int(i.split('=')[1]) == 1:
                    print(vios + ": " + "SACK - OK")
                else:
                    print(vios + ": " + "SACK - NOK")

            if "udp_sendspace" in i:
                if int(i.split('=')[1]) == 65536:
                    print(vios + ": " + "UDP SendSpace - OK")
                else:
                    print(vios + ": " + "UDP SendSpace - NOK")

            if "udp_recvspace" in i:
                if int(i.split('=')[1]) == 655360:
                    print(vios + ": " + "UDP RecvSpace - OK")
                else:
                    print(vios + ": " + "UDP RecvSpace - NOK")

        with open(self.network_csvfile, 'a') as f:
            f.write(vios + ",")
            counter = len(self.network)
            x = 1
            for i in self.network:
                if i and x < counter:
                    f.write(i.split('=')[1] + ",")
                else:
                    f.write(i.split('=')[1])
                x += 1

    def get_network_buffers(self, vios):
        cmd = "for ent in \$(lsdev -Ccadapter | grep \"Virtual I/O Ethernet Adapter\" | awk {'print \$1'}); do attr=\$(lsattr -El \$ent -O | grep -v \"#\"); echo \"\$ent:\$attr\"; done"
        ssh.connect(hostname=vios, username='padmin', password='start1234', timeout=10)
        ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command("echo \" " + cmd + " \" | oem_setup_env")
        output = ssh_stdout.readlines()
        for i in output:
            if i and len(i) > 0:
                print(i)
                self.network_buffers.append(i)


check = CheckVios(sys.argv[1])
check.get_network_tunables(sys.argv[1])
check.validate_network_tunables(sys.argv[1])
check.get_network_buffers(sys.argv[1])
