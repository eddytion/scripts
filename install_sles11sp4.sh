#!/usr/bin/env bash


if [[ "$#" -ne 5 ]]
then
        echo "ERR: This script requires exactly 5 parameters, you have provided only $#"
        exit 1
fi

HMC=$1
MS=$2
LPAR=$3
MAC=
IP1=
HOST1=
MAC_TEMP=
MAC_YABOOT=
OS=$4
UUID=$5

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
        MAC_YABOOT=$(echo ${MAC} | sed 's/:/-/g')
}

function dhcp_entry()
{
        echo "Dealing with DHCP entry ..."
        HOST1=$(echo ${LPAR})
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
        if [[ ${HMC} == "ishmc31" || ${HMC} == "ishmc30" || ${HMC} == "ishmc10" ]]
        then
                ssh -T root@lsh35350rh << EOD
                sed -i "/${HOST1}/d" /etc/dhcp/dhcpd.conf
                echo "host ${HOST1} { filename \"/boot_sles11/yaboot.ibm\"; hardware ethernet ${MAC}; fixed-address ${IP1}; }" >> /etc/dhcp/dhcpd.conf
                systemctl restart dhcpd
EOD
        fi
        if [[ ${HMC} == "ishmc40" || ${HMC} == "ishmc41" ]]
        then
                ssh -T unix@lsh35551le << EOD
                sed -i "/${HOST1}/d" /etc/dhcpd.conf
                echo "host ${HOST1} { filename \"/boot_sles11/yaboot.ibm\"; hardware ethernet ${MAC}; fixed-address ${IP1}; }" >> /etc/dhcpd.conf
                systemctl restart dhcpd
EOD
        fi
}

function mk_yaboot()
{
        echo "creating YABOOT config file ..."
                if [[ ${HMC} == "ishmc31" || ${HMC} == "ishmc30" || ${HMC} == "ishmc10" ]]
                then
                        ssh -T root@lsh35350rh << EOD
                        rm -f /var/lib/tftpboot/boot_sles11/yaboot.conf-`echo ${MAC_YABOOT}`
                        cd /var/lib/tftpboot/boot_sles11
                        cp ./yaboot.conf ./yaboot.conf-`echo ${MAC_YABOOT}`
                        sed -i 's/lsh35xxx/${HOST1}/g' ./yaboot.conf-`echo ${MAC_YABOOT}`
                        cp /var/www/html/websles/autoyast/autoyast_sles11_lsh35xxx.xml /var/www/html/websles/autoyast/autoyast_sles11_${HOST1}.xml
                        sed -i "s/fa:81:e3:6d:eb:05/$MAC/g" /var/www/html/websles/autoyast/autoyast_sles11_${HOST1}.xml
                        sed -i "s/3600507680c808075b8000000000010df/3$UUID/g" /var/www/html/websles/autoyast/autoyast_sles11_${HOST1}.xml
                        cd /var/lib/tftpboot
                        ln -sf boot_sles11/yaboot.conf-`echo ${MAC_YABOOT}` yaboot.conf-`echo ${MAC_YABOOT}`
EOD
                fi
                if [[ ${HMC} == "ishmc40" || ${HMC} == "ishmc41" ]]
                then
                        ssh -T unix@lsh35551le << EOD
                        rm -f /tftpboot/boot_sles11/yaboot.conf-`echo ${MAC_YABOOT}`
                        cd /tftpboot/boot_sles11
                        cp ./yaboot.conf ./yaboot.conf-`echo ${MAC_YABOOT}`
                        sed -i 's/lsh35xxx/${HOST1}/g' ./yaboot.conf-`echo ${MAC_YABOOT}`
                        cd /tftpboot
                        ln -sf boot_sles11/yaboot.conf-`echo ${MAC_YABOOT}` yaboot.conf-`echo ${MAC_YABOOT}`
EOD
			ssh -T root@lsh35350rh << EOD
			cp /var/www/html/websles/autoyast/autoyast_sles11_lsh35xxx.xml /var/www/html/websles/autoyast/autoyast_sles11_${HOST1}.xml
                        sed -i "s/fa:81:e3:6d:eb:05/$MAC/g" /var/www/html/websles/autoyast_sles11_${HOST1}.xml
                        sed -i "s/3600507680c808075b8000000000010df/3$UUID/g" /var/www/html/websles/autoyast/autoyast_sles11_${HOST1}.xml
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
mk_yaboot
echo "MS is ${MS}"

echo "LPAR will be booted in SMS mode where you can start the installation ... please wait ..."

if [[ ${HMC} == "ishmc40" || ${HMC} == "ishmc41" ]]
then
        ssh -T -l unix $HMC "chsysstate -m ${MS} -o shutdown -r lpar -n ${LPAR} --immed"
        sleep 3
        ssh -T -l unix $HMC "chsysstate -m ${MS} -o on -r lpar -n ${LPAR} -f default -b sms"
else
        ssh -T -l unix $HMC "chsysstate -m ${MS} -o shutdown -r lpar -n ${LPAR} --immed"
        sleep 3
        ssh -T -l unix $HMC "chsysstate -m ${MS} -o on -r lpar -n ${LPAR} -f default -b sms"
fi

echo "The LPAR ${LPAR} has been booted in SMS mode .... Please  wait ...."
echo "Please continue the installation from SMS mode .... until all Managed Systems firmware will be updated ... any volunteers !?  "

