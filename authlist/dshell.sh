#!/bin/sh

server=$1
COMMAND=$2
rm -f /tmp/result_oslevel.tmp
touch /tmp/result_oslevel.tmp

PASS=`echo asd | base64 -d`

  nslookup $server >/dev/null 2>&1
  RC=$?
  if [[ "$RC" -eq 0 ]]
  then
    OUTPUT=`timeout 180 sshpass -p ${PASS} ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q -l unix ${server} "${COMMAND}"` 
    echo "$server:$OUTPUT" | tee -a /tmp/result_oslevel.tmp
  else
    nslookup ${server}le >/dev/null 2>&1
    RC=$?
    if [[ "$RC" -eq 0 ]]
    then
	    OUTPUT=`timeout 60 sshpass -p ${PASS} ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q -l unix ${server}le "${COMMAND}"`
	    echo "$server:$OUTPUT" | tee -a /tmp/result_oslevel.tmp
    else
	    OUTPUT=`timeout 60 sshpass -p ${PASS} ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q -l unix ${server}rh "${COMMAND}"`
	    echo "$server:$OUTPUT" | tee -a /tmp/result_oslevel.tmp
    fi
  fi
