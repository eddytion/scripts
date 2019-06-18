import paramiko
import os
import sys
import subprocess
import string

hostname = sys.argv[1]


def findtunnel(val):
    country = val[:2]
    city = val[2:4]
    appl_type = val[4:7]
    code = val[7:10]
    values = (country, city, appl_type, code)
    return values


def start_socks(val):
    system = findtunnel(val)
    if system[0] == 'au':
        print("Starting Sydney tunnel")
    elif system[0] == 'br':
        print("Starting Hortolandia tunnel")
    elif system[0] == 'ca':
        print("Starting Toronto tunnel")
    elif system[0] == 'ch':
        print("Starting Winterthur tunnel")
    elif system[0] == 'de':
        print("Starting Ehningen tunnel")
        redsocks = subprocess.Popen(["/usr/bin/redsocks-sasgui", ' -c', ' /home/eduard/.sasgui/redsocks.conf.d/20232'])
        ssh = subprocess.Popen(["/usr/bin/ssh", '-p 22', '-a', '-D' ' 10232', '9.149.246.101',
                                '-l sas -o ConnectTimeout=15 -t -o StrictHostKeyChecking=no -o ServerAliveInterval=15 -o ExitOnForwardFailure=yes'])

        clientConnect = paramiko.SSHClient()
        clientConnect.load_system_host_keys()
        clientConnect.set_missing_host_key_policy(paramiko.AutoAddPolicy)
        clientConnect.connect(hostname,port=22,username='hscroot',password='start1234')
        stdin, stdout, stderr = clientConnect.exec_command('lshmc -V')
        print(stdout.read())

    elif system[0] == 'es':
        print("Starting Barcelona tunnel")
    elif system[0] == 'fr':
        print("Starting Montpellier tunnel")
    elif system[0] == 'gb':
        print("Starting Fareham tunnel")
    elif system[0] == 'jp':
        print("Starting Japan tunnel")
    elif system[0] == 'nl':
        print("Starting Amsterdam tunnel")
    elif system[0] == 'uk':
        print("Starting Portsmouth tunnel")
    elif system[0] == 'us':
        print("Starting Raleigh tunnel")


start_socks(hostname)
