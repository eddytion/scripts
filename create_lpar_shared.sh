#!/usr/bin/env bash

echo "Starting LPAR creation ...."

HMC=$1
MS=$2
LPAR=$3
MIN_PROC=$7
DESIRED_PROC=$8
MAX_PROC=$9
MIN_PROC_UNITS=$4
DESIRED_PROC_UNITS=$5
MAX_PROC_UNITS=$6
MIN_MEM=${10}
DESIRED_MEM=${11}
MAX_MEM=${12}
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
	mksyscfg -r lpar -m ${MS} -i "profile_name=default,name=${LPAR},lpar_env=aixlinux,all_resources=0,min_mem=${MIN_MEM},desired_mem=${DESIRED_MEM},max_mem=${MAX_MEM},min_num_huge_pages=0,desired_num_huge_pages=0,max_num_huge_pages=0,mem_mode=ded,hpt_ratio=1:128,proc_mode=shared,min_procs=${MIN_PROC},desired_procs=${DESIRED_PROC},max_procs=${MAX_PROC},min_proc_units=${MIN_PROC_UNITS},desired_proc_units=${DESIRED_PROC_UNITS},max_proc_units=${MAX_PROC_UNITS},sharing_mode=uncap,uncap_weight=128,affinity_group_id=none,io_slots=none,lpar_io_pool_ids=none,max_virtual_slots=10,\"virtual_serial_adapters=0/server/1/any//any/1,1/server/1/any//any/1\",virtual_scsi_adapters=none,\"virtual_eth_adapters=4/0/10//0/0/ETHERNET0//all/none,5/0/20//0/0/ETHERNET0//all/none\",virtual_eth_vsi_profiles=none,\"virtual_fc_adapters=\"\"2/client//${VIO1}/${FC_VIO1}//0\"\",\"\"3/client//${VIO2}/${FC_VIO2}//0\"\"\",vtpm_adapters=none,hca_adapters=none,boot_mode=norm,conn_monitoring=0,auto_start=0,power_ctrl_lpar_ids=none,work_group_id=none,redundant_err_path_reporting=0,lpar_proc_compat_mode=default,sriov_eth_logical_ports=none"
_ENDSSH_

if [[ $? -ne 0 ]]
then
	echo "Error in command to create LPAR ... Please check ..."
	exit 1
fi

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
