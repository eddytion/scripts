#!/usr/bin/env bash

if [[ "$#" -ne 6 ]]
then
	echo "ERR: This script requires exactly 6 parameters, you have provided only $#"
	exit 1
fi


HMC=$1
PHYSICAL_SYSTEM=$4
LPAR=$2
LPAR_HOST=
MAC_ADDRESS=
IP1=
IP2=
UUID=$5
C_ANS=$3
LPAR_BOOT=$2
MAC=
VALID_LPAR=$6



function get_mac() {

	echo "Looking for MAC address of LPAR $LPAR"
	MAC=$(ssh -l unix $HMC "lpar_netboot -M -f -i -n -t ent $LPAR default $PHYSICAL_SYSTEM" | grep -w ent | awk '{print $3}')
	MAC_ADDRESS=$(echo $MAC | sed 's/.\{2\}/&:/g;s/.$//')
	echo ${MAC_ADDRESS}
}

function get_ips() {

	echo "IP addresses ...."
	IP1=$(dig ${LPAR}.wdf.sap.corp | grep -A 1 "ANSWER SECTION:" | tail -n 1 | awk '{print $5}')
	if [[ -z "${IP1}" ]]
	then
        	IP1=$(dig ${LPAR}le.wdf.sap.corp | grep -A 1 "ANSWER SECTION:" | tail -n 1 | awk '{print $5}')
		LPAR_HOST="${LPAR}le"
		echo ${LPAR_HOST}
        	echo ${IP1}
	else
        	echo ${IP1}
	fi
	if [[ ${LPAR} == *"le"* ]]
	then
		LPAR_NAME=$(echo ${LPAR} | sed 's/le//g')
		IP2=$(dig ${LPAR_NAME}s.wdf.sap.corp | grep -A 1 "ANSWER SECTION:" | tail -n 1 | awk '{print $5}')
		echo ${IP2}
	else
		IP2=$(dig ${LPAR}s.wdf.sap.corp | grep -A 1 "ANSWER SECTION:" | tail -n 1 | awk '{print $5}')
		echo ${IP2}
	fi
}


function get_grub() {

	echo "Creating GRUB file ...."
	ssh -T unix@lsh35303 << _ENDSSH
	cp /tftpboot/grub_suse/grub.cfg.template /tftpboot/grub_suse/grub.cfg-${LPAR}
	sed -i "s/autoyast.xml/autoyast_${LPAR}.xml/g" /tftpboot/grub_suse/grub.cfg-${LPAR}
	if [[ "$HMC" == "ishmc40" ]]
	then
		scp /tftpboot/grub_suse/grub.cfg-${LPAR} unix@lsh35551le:/tftpboot/grub_suse/
	fi
_ENDSSH
	echo "<b><font color=\"red\">GRUB config file command is <i> configfile grub_suse/grub.cfg-${LPAR} </i></font></b>"
}


function get_autoyast() {

echo "Generating autoyast ...."

ssh -T unix@lsh35303 << _ENDSSH

	if [[ "$VALID_LPAR" == "Yes" && "$C_ANS" == "Yes" ]]
  	then
    		echo "You have selected to install a validation LPAR with C++ compiler"
    		cp /srv/install/autoyast/autoyast.xml /srv/install/autoyast/autoyast_${LPAR}.xml
    		sed -i "s/3600507680c808075b8000000000010df/3$UUID/g" /srv/install/autoyast/autoyast_${LPAR}.xml
    		sed -i "s/fa:81:e3:6d:eb:05/$MAC_ADDRESS/g" /srv/install/autoyast/autoyast_${LPAR}.xml
    
    		if [[ "$HMC" == "ishmc40" ]]
    		then
      			sed -i "s/post_setup_old_env.sh/post_setup_new_env_validation.sh/g" /srv/install/autoyast/autoyast_${LPAR}.xml
    		else
      			sed -i "s/post_setup_old_env.sh/post_setup_old_env_validation.sh/g" /srv/install/autoyast/autoyast_${LPAR}.xml
    		fi
  	elif [[ "$VALID_LPAR" == "Yes" && "$C_ANS" == "No" ]]
  	then
    		echo "You have selected to install a validation LPAR without C++ compiler"
    		cp /srv/install/autoyast/autoyast_make.xml /srv/install/autoyast/autoyast_${LPAR}.xml
    		sed -i "s/3600507680c808075b8000000000010df/3$UUID/g" /srv/install/autoyast/autoyast_${LPAR}.xml
    		sed -i "s/fa:81:e3:6d:eb:05/$MAC_ADDRESS/g" /srv/install/autoyast/autoyast_${LPAR}.xml
    
    		if [[ "$HMC" == "ishmc40" ]]
   		then
      			sed -i "s/post_setup_old_env.sh/post_setup_new_env_validation.sh/g" /srv/install/autoyast/autoyast_${LPAR}.xml
    		else
      			sed -i "s/post_setup_old_env.sh/post_setup_old_env_validation.sh/g" /srv/install/autoyast/autoyast_${LPAR}.xml
   		fi
  	elif [[ "$VALID_LPAR" == "No" && "$C_ANS" == "Yes" ]]
  	then
    		echo "You have selected to install LPAR with C++ compiler"
    		cp /srv/install/autoyast/autoyast.xml /srv/install/autoyast/autoyast_${LPAR}.xml
    		sed -i "s/3600507680c808075b8000000000010df/3$UUID/g" /srv/install/autoyast/autoyast_${LPAR}.xml
    		sed -i "s/fa:81:e3:6d:eb:05/$MAC_ADDRESS/g" /srv/install/autoyast/autoyast_${LPAR}.xml
    
    		if [[ "$HMC" == "ishmc40" ]]
    		then
      			sed -i "s/post_setup_old_env.sh/post_setup_new_env.sh/g" /srv/install/autoyast/autoyast_${LPAR}.xml
    		else
      			sed -i "s/post_setup_old_env.sh/post_setup_old_env.sh/g" /srv/install/autoyast/autoyast_${LPAR}.xml
    		fi
	else
    		echo "No validation LPAR and no C++ compiler"
    		cp /srv/install/autoyast/autoyast_make.xml /srv/install/autoyast/autoyast_${LPAR}.xml
    		sed -i "s/3600507680c808075b8000000000010df/3$UUID/g" /srv/install/autoyast/autoyast_${LPAR}.xml
    		sed -i "s/fa:81:e3:6d:eb:05/$MAC_ADDRESS/g" /srv/install/autoyast/autoyast_${LPAR}.xml
    
    		if [[ "$HMC" == "ishmc40" ]]
    		then
      			sed -i "s/post_setup_old_env.sh/post_setup_new_env.sh/g" /srv/install/autoyast/autoyast_${LPAR}.xml
    		else
      			sed -i "s/post_setup_old_env.sh/post_setup_old_env.sh/g" /srv/install/autoyast/autoyast_${LPAR}.xml
    		fi
  	fi
  
_ENDSSH

}


function get_dhcp() {

	if [[ "$HMC" == "ishmc40" ]]
        then
		ssh unix@lsh35551le "grep ${LPAR} /etc/dhcpd.conf > /dev/null"
		if [ $? -eq 0 ]
        	then
                	echo "Entry exists in DHCP"
        	else
                	echo "Adding entry in DHCP"
                	ssh unix@lsh35551le << _ENDSSH_
				echo "host ${LPAR} { filename \"/boot_suse/powerpc-ieee1275/core.elf\"; hardware ethernet $MAC_ADDRESS; fixed-address ${IP1}; }" >> /etc/dhcpd.conf
_ENDSSH_
                	ssh unix@lsh35551le "systemctl restart dhcpd"
        	fi
		return 0
	else
		ssh unix@lsh35303 "grep ${LPAR} /etc/dhcpd.conf > /dev/null"
                if [ $? -eq 0 ]
                then
                        echo "Entry exists in DHCP"
                else
                        echo "Adding entry in DHCP"
                        ssh unix@lsh35303 << _ENDSSH_
                                echo "host ${LPAR} { filename \"/boot_suse/powerpc-ieee1275/core.elf\"; hardware ethernet $MAC_ADDRESS; fixed-address ${IP1}; }" >> /etc/dhcpd.conf
_ENDSSH_
		fi
                        ssh unix@lsh35303 "systemctl restart dhcpd"
	fi
}


clear

echo "IyAgICAgIyAgICAjICAgICMgICAgICMgICAgIyAgICAgICAjIyMjIyMjICMgICAgICMgICAgIyMj
IyMjICAjIyMjIyMjICMgICAgICMgIyMjIyMjIyAjIyMjIyMgIAojICAgICAjICAgIyAjICAgIyMg
ICAgIyAgICMgIyAgICAgICMgICAgICMgIyMgICAgIyAgICAjICAgICAjICMgICAgICMgIyAgIyAg
IyAjICAgICAgICMgICAgICMgCiMgICAgICMgICMgICAjICAjICMgICAjICAjICAgIyAgICAgIyAg
ICAgIyAjICMgICAjICAgICMgICAgICMgIyAgICAgIyAjICAjICAjICMgICAgICAgIyAgICAgIyAK
IyMjIyMjIyAjICAgICAjICMgICMgICMgIyAgICAgIyAgICAjICAgICAjICMgICMgICMgICAgIyMj
IyMjICAjICAgICAjICMgICMgICMgIyMjIyMgICAjIyMjIyMgIAojICAgICAjICMjIyMjIyMgIyAg
ICMgIyAjIyMjIyMjICAgICMgICAgICMgIyAgICMgIyAgICAjICAgICAgICMgICAgICMgIyAgIyAg
IyAjICAgICAgICMgICAjICAgCiMgICAgICMgIyAgICAgIyAjICAgICMjICMgICAgICMgICAgIyAg
ICAgIyAjICAgICMjICAgICMgICAgICAgIyAgICAgIyAjICAjICAjICMgICAgICAgIyAgICAjICAK
IyAgICAgIyAjICAgICAjICMgICAgICMgIyAgICAgIyAgICAjIyMjIyMjICMgICAgICMgICAgIyAg
ICAgICAjIyMjIyMjICAjIyAjIyAgIyMjIyMjIyAjICAgICAjIAogICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgCg==" | base64 -d

echo "IF9fXyAgICAgICAgICBfICAgICAgICAgIF8gICAgXyAgICAgICAgICAgIAp8IF9ffCAgXyAgIF9f
KF8pICBfX18gX198IHxfIChfKV8gX18gIF9fIF8gCnwgX3wgfHwgfCAoXy08IHwgLyAtXykgX3wg
JyBcfCB8ICdfIFwvIF9gIHwKfF9fX1xfLF98IC9fXy9ffCBcX19fXF9ffF98fF98X3wgLl9fL1xf
XyxffAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgfF98ICAgICAgICAgCg==" | base64 -d

get_mac
get_ips
if [[ -z ${LPAR_HOST} ]]
then
        echo ${LPAR}
else
        LPAR=${LPAR_HOST}
fi
get_grub
get_autoyast
get_dhcp

#echo -e "You have selected $IMAGE\n$HMC\n$PHYSICAL_SYSTEM\n$LPAR\n$MAC_ADDRESS\n$IP1\n$IP2\n$UUID\n"
if [[ "$HMC" == "ishmc40" ]]
then
	ssh -T -l unix $HMC "lpar_netboot -m ${MAC} -f -i -t ent -T off -s auto -d auto -S 10.77.104.185 -G 10.77.104.1 -C ${IP1} -K 255.255.252.0 ${LPAR_BOOT} default $PHYSICAL_SYSTEM"
else 
	ssh -T -l unix $HMC "lpar_netboot -m ${MAC} -f -i -t ent -T off -s auto -d auto -S 10.76.177.146 -G 10.76.176.1 -C ${IP1} -K 255.255.248.0 ${LPAR_BOOT} default $PHYSICAL_SYSTEM"
fi

echo "Script not finished ... please wait ...."
sleep 30

/usr/bin/expect << EOD
	set timeout 10
	exp_internal 1
#	stty -echo
	spawn ssh -t unix@${HMC} mkvterm -m ${PHYSICAL_SYSTEM} -p ${LPAR_BOOT}
	sleep 3
	send "\r"
	send "\r"
	sleep 1
	expect "grub>" { send "configfile grub_suse/grub.cfg-${LPAR}\r" }
	sleep 25
	send "~."
#	stty echo
EOD

echo "Please login to VNC to monitor the installation !"
