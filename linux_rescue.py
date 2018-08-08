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
    OS_VER = sys.argv[4]


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
            print("MAC Address is: " + '-'.join(MAC_TMP[i:i + 2] for i in range(0, len(MAC_TMP), 2)))
    else:
        getmac.MAC = MAC_TMP
        print("MAC Address is: " + '-'.join(MAC_TMP[i:i + 2] for i in range(0, len(MAC_TMP), 2)))


def mk_grub():
    print("Creating grub file for maintenance mode ...")
    if OS_VER == "sles12sp1" or OS_VER == "sles12sp2" or OS_VER == "sles12sp3":

        SPACK = OS_VER[6:]
        if SPACK == "sp1":
            boot = ""
        elif SPACK == "sp2" or SPACK == "sp3":
            boot = '_' + SPACK

        if HMC == "ishmc31" or HMC == "ishmc30":
            try:
                os.remove('/var/lib/tftpboot/boot_suse/grub.cfg-01-' + getmac.MAC.lower())
                grub_file = '/var/lib/tftpboot/boot_suse/grub.cfg-01-' + getmac.MAC.lower()
                with open(grub_file, mode='wt', encoding='utf-8') as f:

                    # General options

                    f.write('set timeout=10\n')
                    f.write('set default=0\n')
                    f.write('\nGRUB_TERMINAL=console\n\n')
                    f.write('insmod gettext\n')
                    f.write('insmod gfxterm\n\n')

                    # Rescue System menu entry

                    f.write('menuentry \'Rescue System\' $arch --class opensuse --class gnu-linux --class gnu {\n')
                    f.write(' echo \'Loading kernel ...\'\n')
                    f.write(
                        ' linux /boot_suse/linux' + boot + ' rescue=1 install=nfs://lsh35350rh:/exports/images/SUSE12'+SPACK.upper())
                    f.write(' echo \'Loading initial ramdisk ...\'\n')
                    f.write(' initrd /boot_suse/initrd' + boot + '\n')
                    f.write('}\n')

                    # Reboot menu entry

                    f.write('\nsubmenu \'Other Options ...\' {\n')
                    f.write(' menuentry \'Reboot\' {\n')
                    f.write(' reboot\n')
                    f.write('}\n')

                    # Exit to open firmware menu

                    f.write(' menuentry \'Exit to Open Firmware\' {\n')
                    f.write(' exit\n')
                    f.write(' }\n}\n')

                    os.system('/usr/bin/systemctl restart dhcpd')

            except:
                print("Some error occured" + os.error())
                sys.exit(1)
        elif HMC == "ishmc40" or HMC == "ishmc41":
            try:
                client = paramiko.SSHClient()
                client.load_system_host_keys()
                client.set_missing_host_key_policy(paramiko.WarningPolicy)
                client.connect('lsh35551le', 22, 'root')
                stdin, stdout, stderr = client.exec_command(
                    'rm -f /tftpboot/boot_suse/grub.cfg-01-' + getmac.MAC.lower())

                # Write file locally and then copy it remotely

                grub_file = '/var/lib/tftpboot/boot_suse/grub.cfg-01-' + getmac.MAC.lower()
                with open(grub_file, mode='wt', encoding='utf-8') as f:

                    # General options

                    f.write('set timeout=10\n')
                    f.write('set default=0\n')
                    f.write('\nGRUB_TERMINAL=console\n\n')
                    f.write('insmod gettext\n')
                    f.write('insmod gfxterm\n\n')

                    # Rescue System menu entry

                    f.write('menuentry \'Rescue System\' $arch --class opensuse --class gnu-linux --class gnu {\n')
                    f.write(' echo \'Loading kernel ...\'\n')
                    f.write(
                        ' linux /boot_suse/linux' + boot + ' rescue=1 install=nfs://lsh35350rh:/exports/images/SUSE12'+SPACK.upper())
                    f.write(' echo \'Loading initial ramdisk ...\'\n')
                    f.write(' initrd /boot_suse/initrd' + boot + '\n')
                    f.write('}\n')

                    # Reboot menu entry

                    f.write('\nsubmenu \'Other Options ...\' {\n')
                    f.write(' menuentry \'Reboot\' {\n')
                    f.write(' reboot\n')
                    f.write('}\n')

                    # Exit to open firmware menu

                    f.write(' menuentry \'Exit to Open Firmware\' {\n')
                    f.write(' exit\n')
                    f.write(' }\n}\n')

                sftp = client.open_sftp()
                sftp.put(grub_file, '/tftpboot/boot_suse/grub.cfg-01-' + getmac.MAC.lower())
                sftp.close()
                stdin, stdout, stderr = client.exec_command('/usr/bin/systemctl restart dhcpd')
                client.close()
            except:
                print('Some error occured')
                sys.exit(1)
    else:
        print("Unsupported OS: " + OS_VER)
        sys.exit(1)

