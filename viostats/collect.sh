#!/bin/sh

if [[ "$#" != 2 ]]
then
  echo "ERR: Usage $0 <COMMAND> <FILELIST>"
  echo "Eg:  $0 \"oslevel -s\" aix_lpars"
exit 1
fi

SERVERLIST=${2}

if [[ ! -s "$SERVERLIST" ]]
then
  echo "ERR: ${SERVERLIST} is empty, you need to add some servers there before running the script..."
  exit 1
fi

COMMAND=${1}
PASS=`echo XXXXX | base64 -d`
rm -f output.raw

function run_ssh() {
for server in `cat ${SERVERLIST}`
do
  OUTPUT=`sshpass -p ${PASS} ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q -l unix ${server} "${COMMAND}"`
  echo "${OUTPUT}"
done
}

run_ssh | tee -a output.raw
/srv/scripts/viostats/import.sh
