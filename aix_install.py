#!/usr/bin/env python3

import os
import subprocess
import sys
import socket
import datetime
import requests
import paramiko

if len(sys.argv) != 5:
    print("Invalid nr of arguments passed, " + str(len(sys.argv) - 1) + " provided, 4 required")
    sys.exit(1)
else:
    HMC = sys.argv[1]
    MS = sys.argv[2]
    LPAR = sys.argv[3]
    AIX = sys.argv[4]
    NIM = "is0124"
    SPOT = "spot-" + AIX
    LPP_SOURCE = "lpp_source-" + AIX
    BOSINST_DATA = "aix_bosinst_base"
    NIM_IP = socket.gethostbyname(NIM)
    DATE = datetime.date.today()


def getmac():
    MAC_TMP = str(requests.get("http://lsh35350rh/webaix/getmac.php?lpar=" + LPAR + "&mac=get").text)
    if len(MAC_TMP) < 1 or MAC_TMP == "NULL":
        print("WARN: I was unable to get the MAC address for " + LPAR + " from database... reading HMC profile")
        client = paramiko.SSHClient()
        client.load_system_host_keys()
        client.set_missing_host_key_policy(paramiko.WarningPolicy)
        client.connect(HMC, 22, 'unix')
        stdin, stdout, stderr = client.exec_command(
            'lshwres -r virtualio -m ' + MS + ' --rsubtype eth --level lpar -F lpar_name,is_trunk,port_vlan_id,vswitch,mac_addr | grep -w ' + LPAR + ' | grep "0,10" | cut -f 5 -d , ')
        MAC_TMP = stdout.read().decode('utf-8').rstrip('\n')
        client.close()

        if len(MAC_TMP) < 1:
            print("ERR: I was unable to get the MAC address for " + LPAR + " from HMC profile... exiting")
            sys.exit(1)
        else:
            getmac.MAC = MAC_TMP
            print("MAC Address is: " + ':'.join(MAC_TMP[i:i + 2] for i in range(0, len(MAC_TMP), 2)))
    else:
        getmac.MAC = MAC_TMP
        print("MAC Address is: " + ':'.join(MAC_TMP[i:i + 2] for i in range(0, len(MAC_TMP), 2)))


def check_nim():
    client = paramiko.SSHClient()
    client.load_system_host_keys()
    client.set_missing_host_key_policy(paramiko.WarningPolicy)
    client.connect(NIM, 22, 'unix')
    stdin, stdout, stderr = client.exec_command('lsnim -l ' + LPAR)

    if stdout.channel.recv_exit_status() == 0:
        print("INFO: Host " + LPAR + " is already defined on nim server " + NIM + " , I will reset it ....")
        stdin, stdout, stderr = client.exec_command('nim -Fo reset ' + LPAR + '; nim -Fo deallocate -a subclass=all ' + LPAR)
        if stdout.channel.recv_exit_status() == 0:
            print("INFO: Host " + LPAR + " has been reset on nim server " + NIM)
            client.exec_command(
                'nim -o bos_inst -a source=rte -a spot=' + SPOT + ' -a lpp_source=' + LPP_SOURCE + ' -a fb_script=aix_post_setup -a accept_licenses=yes -a force_push=no -a boot_client=no -a installp_flags=\'-agQXY\' -a bosinst_data=' + BOSINST_DATA + ' ' + LPAR)
            if stdout.channel.recv_exit_status() == 0:
                print(
                    "INFO: Host " + LPAR + " has been setup for installation on nim server " + NIM + " with the following resources:\n")
                print("SPOT: " + SPOT)
                print("LPP_SOURCE: " + LPP_SOURCE)
                print("BOSINST_DATA: " + BOSINST_DATA)
                stdout,stdin,stderr = client.exec_command('lsnim -l ' + LPAR,get_pty=True)
            else:
                print("ERR: Unable to setup " + LPAR + " for installation, please check manually on " + NIM + " ...")
                client.close()
                sys.exit(1)
        else:
            print("ERR: I was unable to reset host " + LPAR + " on nim server " + NIM)
            client.close()
            sys.exit(1)
    else:
        stdin, stdout, stderr = client.exec_command(
            'nim -o define -t standalone -a platform=chrp -a netboot_kernel=64 -a cable_type1=tp -a if1=\"find_net ' + LPAR + ' 0\" ' + LPAR)
        if stdout.channel.recv_exit_status() == 0:
            print("INFO: Host " + LPAR + " defined successfully on nim server " + NIM)
            stdin, stdout, stderr = client.exec_command(
                'nim -o bos_inst -a source=rte -a spot=' + SPOT + ' -a lpp_source=' + LPP_SOURCE + ' -a fb_script=aix_post_setup -a accept_licenses=yes -a force_push=no -a boot_client=no -a installp_flags=\'-agQXY\' -a bosinst_data=' + BOSINST_DATA + ' ' + LPAR)
            if stdout.channel.recv_exit_status() == 0:
                print(
                    "INFO: Host " + LPAR + " has been setup for installation on nim server " + NIM + " with the following resources:\n")
                print("SPOT: " + SPOT)
                print("LPP_SOURCE: " + LPP_SOURCE)
                print("BOSINST_DATA: " + BOSINST_DATA)
                stdin, stdout, stderr = client.exec_command('lsnim -l ' + LPAR,get_pty=True)

                client.close()
            else:
                print("ERR: Unable to setup "+LPAR+" for installation, please check manually on "+NIM+" ... ")
                client.close()
                sys.exit(1)
        else:
            print("ERR: Unable to define " + LPAR + " on nim server " + NIM)
            client.close()
            sys.exit(1)


def lpar_netboot():
    print("INFO: Getting network parameters for lpar_netboot command ... ")
    client = paramiko.SSHClient()
    client.load_system_host_keys()
    client.set_missing_host_key_policy(paramiko.WarningPolicy)
    client.connect(NIM, 22, 'unix')

    stdin, stdout, stderr = client.exec_command('lsnim -l ' + LPAR + ' | grep -w if1 | awk {\'print $3\'}')
    NET = stdout.read().decode('utf-8').rstrip('\n')
    print("NET = "+NET)

    stdin, stdout, stderr = client.exec_command('lsnim -l ' + NET + ' | grep -w routing1 | awk {\'print $4\'}')
    GW = stdout.read().decode('utf-8').rstrip('\n')
    print("GW = "+GW)

    stdin, stdout, stderr = client.exec_command('lsnim -l ' + NET + ' | grep -w snm | awk {\'print $3\'}')
    MASK = stdout.read().decode('utf-8').rstrip('\n')
    print("NETMASK = "+MASK)

    IPADDR = socket.gethostbyname(LPAR)
    print("INFO: Booting lpar "+LPAR+" to start installation ...")
    client.close()

    client.connect(HMC, 22, 'unix')
    stdout,stderr,stdin = client.exec_command(
      'lpar_netboot -m ' + getmac.MAC.lower() + ' -f -i -t ent -T off -s auto -d auto -S ' + NIM_IP + ' -G ' + GW + ' -C ' + IPADDR + ' -K ' + MASK + ' ' + LPAR + ' default ' + MS)
    exit_status = stdout.channel.recv_exit_status()
    if exit_status == 0:
        print("lpar_netboot succeeded")
        print('lpar_netboot -m ' + getmac.MAC.lower() + ' -f -i -t ent -T off -s auto -d auto -S ' + NIM_IP + ' -G ' + GW + ' -C ' + IPADDR + ' -K ' + MASK + ' ' + LPAR + ' default ' + MS)
        client.close()
    else:
        print("Some error occured", exit_status)
        print('lpar_netboot -m ' + getmac.MAC.lower() + ' -f -i -t ent -T off -s auto -d auto -S ' + NIM_IP + ' -G ' + GW + ' -C ' + IPADDR + ' -K ' + MASK + ' ' + LPAR + ' default ' + MS)
        client.close()


getmac()
check_nim()
lpar_netboot()
