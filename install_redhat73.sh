#!/usr/bin/env bash


if [[ "$#" -ne 3 ]]
then
        echo "ERR: This script requires exactly 3 parameters, you have provided only $#"
        exit 1
fi

HMC=$1
MS=$2
LPAR=$3
MAC=
IP1=
HOST1=
MAC_TEMP=

function get_mac()
{
	echo "Getting MAC address of lpar ${LPAR}"
	wget -e use_proxy=off "http://lsh35350rh/install/getmac.php?lpar=${LPAR}" -O /tmp/${LPAR}_mac.txt > /dev/null 2>&1
	MAC=$(cat /tmp/${LPAR}_mac.txt)
	MAC_TEMP=$(echo ${MAC} | sed 's/://g')
	if [[ ${MAC} == "NULL" ]]
	then
		echo "MAC not found in database ..."
		echo "Retrieving MAC from HMC ... it will take a few minutes ..."
		MAC_TEMP=$(ssh -l unix ${HMC} "lpar_netboot -M -f -i -n -t ent ${LPAR} default ${MS}" | grep -w ent | awk '{print $3}')
		MAC=$(echo ${MAC_TEMP} | sed 's/.\{2\}/&:/g;s/.$//')
	fi
	echo "MAC address for ${LPAR} is ${MAC}"
}

function dhcp_entry()
{
	echo "Dealing with DHCP entry ..."
#	HOST1=$(echo ${LPAR}rh)
	HOST1=$(echo ${LPAR}le)
	IP1=$(dig ${HOST1}.wdf.sap.corp | grep -A 1 "ANSWER SECTION:" | tail -n 1 | awk '{print $5}')
	if [[ -z "${IP1}" ]]
        then
		echo "No IP address found ... please check DNS"
		echo "Installation will stop now"
		if [[ ${LPAR} == "lsh35304" ]]
		then
			IP1="10.76.178.223"
			HOST1=${LPAR}
		else
			exit 1
		fi
	fi
	echo "Deleting old entry (if exists) and creating new entry in DHCP for ${HOST1} and IP ${IP1} ...."
	if [[ ${HMC} == "ishmc31" || ${HMC} == "ishmc30" ]]
	then
		ssh -T root@lsh35350rh << EOD
		sed -i "/${HOST1}/d" /etc/dhcp/dhcpd.conf
		echo "host ${HOST1} { filename \"/boot_redhat73/powerpc-ieee1275/core.elf\"; hardware ethernet ${MAC}; fixed-address ${IP1}; }" >> /etc/dhcp/dhcpd.conf
		systemctl restart dhcpd
EOD
	fi
	if [[ ${HMC} == "ishmc40" || ${HMC} == "ishmc41" ]]
	then
		ssh -T unix@lsh35551le << EOD
		sed -i "/${HOST1}/d" /etc/dhcpd.conf
		echo "host ${HOST1} { filename \"/boot_redhat73/powerpc-ieee1275/core.elf\"; hardware ethernet ${MAC}; fixed-address ${IP1}; }" >> /etc/dhcpd.conf
		systemctl restart dhcpd
EOD
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
dhcp_entry

#echo "LPAR will boot in Open Firmware mode ... please wait ...."
#echo "LPAR will start the installation ... please wait ..."
echo "LPAR ${LPAR} will be booted in SMS mode. To finish the installation connect to ${HMC} and continue from there..."

if [[ ${HMC} == "ishmc40" || ${HMC} == "ishmc41" ]]
then
	ssh -T -l unix $HMC "chsysstate -m ${MS} -o shutdown -r lpar -n ${LPAR} --immed"
	sleep 3
	ssh -T -l unix $HMC "chsysstate -m ${MS} -o on -r lpar -n ${LPAR} -f default -b sms"
#	ssh -T -l unix $HMC "lpar_netboot -m ${MAC_TEMP} -f -i -t ent -T off -s auto -d auto -S 10.77.104.185 -G 10.77.104.1 -C ${IP1} -K 255.255.252.0 ${LPAR} default ${MS}"
else
	ssh -T -l unix $HMC "chsysstate -m ${MS} -o shutdown -r lpar -n ${LPAR} --immed"
        sleep 3
        ssh -T -l unix $HMC "chsysstate -m ${MS} -o on -r lpar -n ${LPAR} -f default -b sms"
#	ssh -T -l unix $HMC "lpar_netboot -m ${MAC_TEMP} -f -i -t ent -T off -s auto -d auto -S 10.76.182.245 -G 10.76.176.1 -C ${IP1} -K 255.255.248.0 ${LPAR} default ${MS}"
fi

#echo "The LPAR ${LPAR} has been booted in Open Firmware mode .... Please  wait ...."

#sleep 10

#/usr/bin/expect << EOD
#        set timeout 10
#        exp_internal 1
#       stty -echo
#	spawn ssh -t unix@${HMC} mkvterm -m ${MS} -p ${LPAR}
#	sleep 3
#        send "\r"
#        send "\r"
#        sleep 1
#	expect ">" { send "boot net dhcp\r" }
#	sleep 1
#        send "~."
#       stty echo
#EOD
