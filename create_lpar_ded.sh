#!/usr/bin/env bash

echo "Starting LPAR creation ...."

HMC=$1
MS=$2
LPAR=$3
MIN_PROC=$4
DESIRED_PROC=$5
MAX_PROC=$6
MIN_MEM=$7
DESIRED_MEM=$8
MAX_MEM=$9
VIO=($(ssh -T -l unix ${HMC} "lssyscfg -m ${MS} -r lpar | grep vioserver | cut -d = -f 2 | cut -d , -f 1 | sort"))
VIO1=${VIO[0]}
VIO2=${VIO[1]}
FC_VIO1=`expr $(ssh -T -l unix ${HMC} "lshwres -m ${MS} -r virtualio --rsubtype fc --filter lpar_names=${VIO1} --level lpar -F slot_num | sort -n | tail -1") + 1`
FC_VIO2=`expr $(ssh -T -l unix ${HMC} "lshwres -m ${MS} -r virtualio --rsubtype fc --filter lpar_names=${VIO2} --level lpar -F slot_num | sort -n | tail -1") + 1`
RMC_VIO1=`ssh -l unix ${HMC} lssyscfg -m ${MS} -r lpar -F rmc_state --filter "lpar_names=${VIO1}"`
RMC_VIO2=`ssh -l unix ${HMC} lssyscfg -m ${MS} -r lpar -F rmc_state --filter "lpar_names=${VIO2}"`

echo "Checking RMC connections to VIO servers ${VIO1} and ${VIO2} ...."

if [[ ${RMC_VIO1} != "active" ]]
then
	echo "RMC connection is not active on ${VIO1}"
	echo "Please fix RMC connection first"
	exit 1
else
	echo "RMC connection to ${VIO1} is active"
fi

if [[ ${RMC_VIO2} != "active" ]]
then
        echo "RMC connection is not active on ${VIO2}"
	echo "Please fix RMC connection first"
        exit 1
else
        echo "RMC connection to ${VIO2} is active"
fi

if [ ${FC_VIO1} -gt ${FC_VIO2} ]
then
        FC_VIO2=${FC_VIO1}
fi

if [ ${FC_VIO1} -lt ${FC_VIO2} ]
then
        FC_VIO1=${FC_VIO2}
fi

echo "Creating LPAR profile ...."

ssh -T -l unix ${HMC} << _ENDSSH_
	mksyscfg -r lpar -m ${MS} -i "profile_name=default,name=${LPAR},lpar_env=aixlinux,all_resources=0,min_mem=${MIN_MEM},desired_mem=${DESIRED_MEM},max_mem=${MAX_MEM},min_num_huge_pages=0,desired_num_huge_pages=0,max_num_huge_pages=0,mem_mode=ded,hpt_ratio=1:128,proc_mode=ded,min_procs=${MIN_PROC},desired_procs=${DESIRED_PROC},max_procs=${MAX_PROC},sharing_mode=share_idle_procs,affinity_group_id=none,io_slots=none,lpar_io_pool_ids=none,max_virtual_slots=10,\"virtual_serial_adapters=0/server/1/any//any/1,1/server/1/any//any/1\",virtual_scsi_adapters=none,\"virtual_eth_adapters=4/0/10//0/0/ETHERNET0//all/none,5/0/20//0/0/ETHERNET0//all/none\",virtual_eth_vsi_profiles=none,\"virtual_fc_adapters=\"\"2/client//${VIO1}/${FC_VIO1}//0\"\",\"\"3/client//${VIO2}/${FC_VIO2}//0\"\"\",vtpm_adapters=none,hca_adapters=none,boot_mode=norm,conn_monitoring=0,auto_start=0,power_ctrl_lpar_ids=none,work_group_id=none,redundant_err_path_reporting=0,lpar_proc_compat_mode=default,sriov_eth_logical_ports=none"
_ENDSSH_

	sleep 5

echo "Adding Virtual Adapters to VIO servers ...."

	ssh -T -l unix ${HMC} << _ENDSSH_
		chhwres -r virtualio -m ${MS} -o a -p ${VIO1} --rsubtype fc -s ${FC_VIO1} -a "adapter_type=server,remote_lpar_name=${LPAR},remote_slot_num=2"
		chhwres -r virtualio -m ${MS} -o a -p ${VIO2} --rsubtype fc -s ${FC_VIO2} -a "adapter_type=server,remote_lpar_name=${LPAR},remote_slot_num=3"
_ENDSSH_

echo "Saving VIO's profiles ...."

	ssh -T -l unix ${HMC} << _ENDSSH_
		mksyscfg -r prof -m ${MS} -o save -p ${VIO1} -n default --force
		mksyscfg -r prof -m ${MS} -o save -p ${VIO2} -n default --force
_ENDSSH_

ssh -T -l unix ${HMC} "lssyscfg -r prof -m ${MS} --filter "lpar_names=${LPAR}" -F virtual_fc_adapters | cut -f 6,12 -d / | sed 's/\//,/g' | sed -e $'s/,/\\\n/g'" > /tmp/WWPN_${LPAR}.txt

#echo "Booting LPAR in SMS mode ...."

#	ssh -T -l unix ${HMC} << _ENDSSH_
#		chsysstate -r lpar -m ${MS} -o on -f default -b sms -n ${LPAR}
#_ENDSSH_

#	sleep 5

#	echo "WWPN are ...."
#	echo ${LPAR} > /tmp/WWPN_${LPAR}.txt
#	echo "============================" >> /tmp/WWPN_${LPAR}.txt
#	ssh -T -l unix ${HMC} "lsnportlogin -m ${MS} --filter \"lpar_names=${LPAR}\"  -F wwpn" >> /tmp/WWPN_${LPAR}.txt
#	echo >> /tmp/WWPN_${LPAR}.txt

echo "WWPN are ...."
echo "============================"
cat /tmp/WWPN_${LPAR}.txt

PASS=`echo asd | base64 -d`
conn="sshpass -p ${PASS}  ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q -l unix"

LPAR_ID=`$conn ${HMC} "lssyscfg -r lpar -m ${MS} -F name,lpar_id | grep -w ${LPAR} | cut -f 2 -d ,"`
VFCHOST_V1=`$conn ${VIO1} /usr/ios/cli/ioscli lsmap -all -npiv -field Name ClntID -fmt : | grep -w ${LPAR_ID} | cut -f 1 -d :`
VFCHOST_V2=`$conn ${VIO1} /usr/ios/cli/ioscli lsmap -all -npiv -field Name ClntID -fmt : | grep -w ${LPAR_ID} | cut -f 1 -d :`
FCS_V1=`$conn ${VIO1} lspath | awk {'print \$3'} | cut -c6-6 | sort | uniq | head -1`
FCS_V2=`$conn ${VIO2} lspath | awk {'print \$3'} | cut -c6-6 | sort | uniq | tail -1`

echo "${LPAR} command for ${VIO1} --> /usr/ios/cli/ioscli vfcmap -vadapter ${VFCHOST_V1} -fcp fcs${FCS_V1}"
echo "${LPAR} command for ${VIO2} --> /usr/ios/cli/ioscli vfcmap -vadapter ${VFCHOST_V2} -fcp fcs${FCS_V2}"

$conn ${VIO1} /usr/ios/cli/ioscli vfcmap -vadapter ${VFCHOST_V1} -fcp fcs${FCS_V1}
$conn ${VIO2} /usr/ios/cli/ioscli vfcmap -vadapter ${VFCHOST_V2} -fcp fcs${FCS_V2}

############################################################################################################################
if [[ ${HMC} == "ishmc31" || ${HMC} == "ishmc30" ]]
then
	echo "Run this command on FABRIC1 and FABRIC2:"
	echo "alicreate \"${LPAR}_npiv\", `cat /tmp/WWPN_${LPAR}.txt | sed ':a;N;$!ba;s/\n/ /g'`"
	echo "zonecreate \"${LPAR}_hopsvc_n1\", \"${LPAR}_npiv; hopsvc_n1a2p1; hopsvc_n1a2p2; hopsvc_n1a2p3; hopsvc_n1a2p4\""
	echo "zonecreate \"${LPAR}_hopsvc_n2\", \"${LPAR}_npiv; hopsvc_n2a2p1; hopsvc_n2a2p2; hopsvc_n2a2p3; hopsvc_n2a2p4\""
	echo "zonecreate \"${LPAR}_hopsvc_n3\", \"${LPAR}_npiv; hopsvc_n3a2p1; hopsvc_n3a2p2; hopsvc_n3a2p3; hopsvc_n3a2p4\""
	echo "zonecreate \"${LPAR}_hopsvc_n4\", \"${LPAR}_npiv; hopsvc_n4a2p1; hopsvc_n4a2p2; hopsvc_n4a2p3; hopsvc_n4a2p4\""
	echo "zonecreate \"${LPAR}_hopsvc_n5\", \"${LPAR}_npiv; hopsvc_n5a2p1; hopsvc_n5a2p2; hopsvc_n5a2p3; hopsvc_n5a2p4\""
	echo "zonecreate \"${LPAR}_hopsvc_n6\", \"${LPAR}_npiv; hopsvc_n6a2p1; hopsvc_n6a2p2; hopsvc_n6a2p3; hopsvc_n6a2p4\""
	echo "zonecreate \"${LPAR}_hopsvc_n7\", \"${LPAR}_npiv; hopsvc_n7a2p1; hopsvc_n7a2p2; hopsvc_n7a2p3; hopsvc_n7a2p4\""
	echo "zonecreate \"${LPAR}_hopsvc_n8\", \"${LPAR}_npiv; hopsvc_n8a2p1; hopsvc_n8a2p2; hopsvc_n8a2p3; hopsvc_n8a2p4\""
	echo "cfgadd \"default\", \"${LPAR}_hopsvc_n1; ${LPAR}_hopsvc_n2; ${LPAR}_hopsvc_n3; ${LPAR}_hopsvc_n4; ${LPAR}_hopsvc_n5; ${LPAR}_hopsvc_n6; ${LPAR}_hopsvc_n7; ${LPAR}_hopsvc_n8\""
	echo "cfgsave"
	echo "cfgenable \"default\""
fi
