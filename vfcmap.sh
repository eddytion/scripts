#!/usr/bin/env bash

LPAR="is0191"
HMC="ishmc10"
VIO1="isvioa91"
VIO2="isvioa92"
MS="sys09-8233-E8B-SN069A42R"

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
