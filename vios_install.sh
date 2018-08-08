#!/usr/bin/sh

if [[ "$#" -ne 3 ]]
then
  echo "ERR: The script needs exactly 3 parameters, you have provided $#"
  echo "$0 <hmc> <managed system> <vios name>"
  exit 1
fi

HMC=$1
MS=$2
VIOS=$3
ADAPTER_LOCATION_CODE=
NIM="is0124"
MKSYSB="vios_2260_mksysb"
SPOT="vios_2260_spot"
BOSINST_DATA="vios_2260_bosinst"
SSH_NIM="ssh -T -l unix ${NIM}"
SSH_HMC="ssh -T -l unix ${HMC}"
NIM_IP=$(nslookup ${NIM} | grep Address | grep -v "#53" | awk {'print $2'})
DATE=$(date +"%Y-%m-%d")

LANG=C

function getmac ()
{
  ADAPTER_LOCATION_CODE=$(${SSH_HMC} "lshwres -r io -m ${MS} --rsubtype slot -F lpar_name,description,drc_name --filter "lpar_names=${VIOS}" | grep -v Fibre | cut -f 3 -d ,")
  if [[ -z "${ADAPTER_LOCATION_CODE}" || "${ADAPTER_LOCATION_CODE}" == "NULL" || "${ADAPTER_LOCATION_CODE}" == "" ]]
  then
    echo "ERR: I was unable to get the location code for the physical network adapter"
    exit 1
  else
    echo "INFO: Adapter location code for ${VIOS} is ${ADAPTER_LOCATION_CODE}"
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

function lpar_netboot()
{
  echo "INFO: Getting network parameters for lpar_netboot command ... "
  NET=$(${SSH_NIM} "lsnim -l ${VIOS} | grep -w if1 | awk {'print \$3'}")
  GW=$(${SSH_NIM} "lsnim -l ${NET} | grep -w routing1 | awk {'print \$4'}")
  MASK=$(${SSH_NIM} "lsnim -l ${NET} | grep -w snm | awk {'print \$3'}")
  IPADDR=$(nslookup ${VIOS} | grep Address | grep -v "#53" | awk {'print $2'})
  
  echo "INFO: Booting lpar ${VIOS} to start installation using adapter with location code ${ADAPTER_LOCATION_CODE} ..."
  ${SSH_HMC} "lpar_netboot -f -t ent -l ${ADAPTER_LOCATION_CODE} -s auto -d auto -S ${NIM_IP} -G ${GW} -C ${IPADDR} -K ${MASK} ${VIOS} default ${MS}"
  echo "lpar_netboot -t ent -l ${ADAPTER_LOCATION_CODE} -s auto -d auto -S ${NIM_IP} -G ${GW} -C ${IPADDR} -K ${MASK} ${VIOS} default ${MS}"
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
lpar_netboot
