#!/usr/bin/sh

if [[ "$#" -ne 3 ]]
then
  echo "ERR: The script needs exactly 3 parameters, you have provided $#"
  exit 1
fi

HMC=$1
MS=$2
VIOS=$3
MAC=
NIM="is0122"
MKSYSB="VIOS_22510"
SPOT="SPOT_22510"
BOSINST_DATA="bosinst_vios22510"
SSH_NIM="ssh -T -l unix ${NIM}"
SSH_HMC="ssh -T -l unix ${HMC}"
NIM_IP=$(nslookup ${NIM} | grep Address | grep -v "#53" | awk {'print $2'})
DATE=$(date +"%Y-%m-%d")

LANG=C

function getmac ()
{
  MAC=$(wget -e use_proxy=no "http://lsh35350rh/webvios/getmac.php?vios=${VIOS}&mac=get" -O /tmp/${VIOS}.mac > /dev/null 2>&1; cat /tmp/${VIOS}.mac)
  if [[ -z "${MAC}" ]]
  then
    echo "WARN: I was unable to get the MAC address for ${VIOS} from database... reading HMC profile"
    MAC=$(${SSH_HMC} "lshwres -r virtualio -m ${MS} --rsubtype eth --level lpar -F lpar_name,is_trunk,port_vlan_id,vswitch,mac_addr | grep ${VIOS} | grep \"1,10\" | cut -f 5 -d ,")
    if [[ -z "${MAC}" ]]
    then
      echo "ERR: I was unable to get the MAC address for ${VIOS} from HMC profile... exiting"
      exit 1
    else
      echo "INFO: MAC Address is ${MAC}"
    fi
  else
    echo "INFO: MAC Address is ${MAC}"
  fi
}

function check_nim ()
{
  ${SSH_NIM} "lsnim -l ${VIOS} >/dev/null 2>&1"
  if [[ $? == 0 ]]
  then
    echo "INFO: Host ${VIOS} is already defined on nim server ${NIM}, I will reset it ... "
    ${SSH_NIM} "nim -Fo reset ${VIOS}; nim -Fo deallocate -a subclass=all ${VIOS}"
    if [[ $? == 0 ]]
    then
      echo "INFO: Host ${VIOS} has been reset on nim server ${NIM} ... "
      ${SSH_NIM} "nim -o bos_inst -a source=mksysb -a spot=${SPOT} -a mksysb=${MKSYSB} -a accept_licenses=yes -a force_push=no -a boot_client=no -a installp_flags='-agQXY' -a bosinst_data=${BOSINST_DATA} ${VIOS}"
      if [[ $? == 0 ]]
      then
        echo "INFO: Host ${VIOS} has been setup for installation on nim server ${NIM} with the following resources:"
        echo "SPOT: ${SPOT}"
        echo "MKSYSB: ${MKSYSB}"
        echo "BOSINST_DATA: ${BOSINST_DATA}"
        echo "----------------------------------------------------------------------------------"
        ${SSH_NIM} "lsnim -l ${VIOS}"
      else
        echo "ERR: Unable to setup ${VIOS} for installation, please check manually on ${NIM} ..." 
        exit 1
      fi
    else
      echo "WARN: I was unable to reset host ${VIOS} on nim server ${NIM} ... "
      exit 1
    fi
  else
    ${SSH_NIM} "nim -o define -t standalone -a platform=chrp -a netboot_kernel=64 -a cable_type1=tp -a if1=\"find_net ${VIOS} 0\" ${VIOS}"
    if [[ $? == 0 ]]
    then
      echo "INFO: Host ${VIOS} defined successfully on nim server ${NIM} ... "
      ${SSH_NIM} "nim -o bos_inst -a source=mksysb -a spot=${SPOT} -a mksysb=${MKSYSB} -a accept_licenses=yes -a force_push=no -a boot_client=no -a installp_flags='-agQXY' -a bosinst_data=${BOSINST_DATA} ${VIOS}"
      if [[ $? == 0 ]]
      then
        echo "INFO: Host ${VIOS} has been setup for installation with the following resources:"
        echo "SPOT: ${SPOT}"
        echo "MKSYSB: ${MKSYSB}"
        echo "BOSINST_DATA: ${BOSINST_DATA}"
        echo "----------------------------------------------------------------------------------"
        ${SSH_NIM} "lsnim -l ${VIOS}"
      else
        echo "ERR: Unable to setup ${VIOS} for installation, please check manually on ${NIM} ... "
        exit 1
      fi
    fi
  fi
}

function save_config()
{
  PASS=$(echo asd | base64 -d)
  sshpass -p ${PASS} scp -o ConnectTimeout=1 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null /srv/scripts/vios_pre.pl unix@${VIOS}:/tmp/
  if [[ $? == 0 ]]
  then
    echo "OK: Script vios_pre was copied successfully to the target ${VIOS} ... "
    sshpass -p ${PASS} ssh -o ConnectTimeout=1 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q -l unix ${VIOS} "/usr/bin/perl /tmp/vios_pre.pl"
    if [[ $? == 0 ]]
    then
      echo "INFO: Script has been successfully run on ${VIOS} ... "
    else
      echo "ERR: Remote script returned a non-zero exit code ... "
      exit 1
    fi
  else
    echo "ERR: I was unable to copy the vios_pre script on target ${VIOS} ... "
    exit 1
  fi
  
  COUNT=$(ssh -l unix lsh35303 "ls /viosconfig | grep -c ${VIOS}")
  if [[ "${COUNT}" -lt 4 ]]
  then
    echo "ERR: I was unable to save vios config... please check manually ..."
    exit 1
  else
    echo "OK: Vios config has been saved"
    ssh -l unix lsh35303 "ls -l /viosconfig | grep ${VIOS}"
  fi
}

function lpar_netboot()
{
  echo "INFO: Getting network parameters for lpar_netboot command ... "
  NET=$(${SSH_NIM} "lsnim -l ${VIOS} | grep -w if1 | awk {'print \$3'}")
  GW=$(${SSH_NIM} "lsnim -l ${NET} | grep -w routing1 | awk {'print \$4'}")
  MASK=$(${SSH_NIM} "lsnim -l ${NET} | grep -w snm | awk {'print \$3'}")
  IPADDR=$(nslookup ${VIOS} | grep Address | grep -v "#53" | awk {'print $2'})
  
  echo "INFO: Booting lpar ${VIOS} to start installation ..."
  ${SSH_HMC} "lpar_netboot -m ${MAC} -f -i -t ent -T off -s auto -d auto -S ${NIM_IP} -G ${GW} -C ${IPADDR} -K ${MASK} ${VIOS} default ${MS}"
  echo "lpar_netboot -m ${MAC} -f -i -t ent -T off -s auto -d auto -S ${NIM_IP} -G ${GW} -C ${IPADDR} -K ${MASK} ${VIOS} default ${MS}"
}

echo "IyAgICAgIyAgICMjIyAgICMjIyMjIyMgICAgICAgICAgIyMjIyMgICMjIyMjIyMgIyMjIyMjICAj
ICAgICAjICMjIyMjIyMgIyMjIyMjCiMgICAgICMgICAgIyAgICAjICAgICAjICAgICAgICAgIyAg
ICAgIyAjICAgICAgICMgICAgICMgIyAgICAgIyAjICAgICAgICMgICAgICMKIyAgICAgIyAgICAj
ICAgICMgICAgICMgICAgICAgICAjICAgICAgICMgICAgICAgIyAgICAgIyAjICAgICAjICMgICAg
ICAgIyAgICAgIwojICAgICAjICAgICMgICAgIyAgICAgIyAgICAgICAgICAjIyMjIyAgIyMjIyMg
ICAjIyMjIyMgICMgICAgICMgIyMjIyMgICAjIyMjIyMKICMgICAjICAgICAjICAgICMgICAgICMg
ICAgICAgICAgICAgICAjICMgICAgICAgIyAgICMgICAgIyAgICMgICMgICAgICAgIyAgICMKICAj
ICMgICAgICAjICAgICMgICAgICMgICAgICAgICAjICAgICAjICMgICAgICAgIyAgICAjICAgICMg
IyAgICMgICAgICAgIyAgICAjCiAgICMgICAgICAjIyMgICAjIyMjIyMjICAgICAgICAgICMjIyMj
ICAjIyMjIyMjICMgICAgICMgICAgIyAgICAjIyMjIyMjICMgICAgICMK" | base64 -d

getmac
check_nim
save_config
lpar_netboot
