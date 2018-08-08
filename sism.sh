#!/usr/bin/bash


export http_proxy=''
export ftp_proxy=''
export https_proxy=''


curl "http://cmp.wdf.sap.corp:1080/sap(bD1lbiZjPTAwMQ==)/bc/bsp/sap/zbbtcheck/TBA_VM.htm?User=ibm&Mode=Status&Name=" -o /tmp/sism.out > /dev/null 2>&1

