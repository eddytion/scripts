#!/usr/bin/env bash

#find if /data existed before

EX_DATA=$(lvs | grep data | awk '{print $1}')
ROOT_DISK=$(ls /dev/disk/by-id | grep part3 | sort | head -1 | awk -F"-" '{ print $3 }' | cut -f 1 -d _)
OTHER_DISKS=($(multipath -l -v1 | grep -v $ROOT_DISK))
PVS=("${OTHER_DISKS[@]/%/_part1}")
PVS=("${PVS[@]/#//dev/mapper/}")

if [[ -n "${EX_DATA//}" ]]
then
	echo -e "Previous logical volume found ... Exiting\n"
	exit 1
fi

for index in ${OTHER_DISKS[@]}
do
	parted -s /dev/mapper/$index mklabel gpt mkpart primary 0GB 100% set 1 lvm on unit GB print
done

pvcreate ${PVS[@]}
vgcreate  -s 64M datavg ${PVS[@]}
lvcreate -I 256 -l 100%VG -n datalv datavg

mkfs.xfs -f -b size=4096 /dev/datavg/datalv

mkdir -p /data
echo -e "/dev/datavg/datalv\t/data\txfs\tdefaults\t0\t1" >> /etc/fstab
mount /data
