#!/usr/bin/env bash

#find if /sapfs existed before

EX_DATA=$(lvs | grep data | awk '{print $1}')
ROOT_DISK=$(ls /dev/disk/by-id | grep part3 | sort | head -1 | awk -F"-" '{ print $3 }')
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
lvcreate -I 256 -i ${#PVS[@]} -l 100%VG -n datalv datavg

mkfs.xfs -f -b size=4096 /dev/datavg/datalv

mkdir -p /sapfs
echo -e "/dev/datavg/datalv\t/sapfs\txfs\tdefaults\t0\t1" >> /etc/fstab
mount /sapfs
cd /sapfs
mkdir db2  hana  hanamnt  informix  lost+found  oracle  sapdb  sapmnt  sybase  tmp.install  usr.sap
echo -e "/sapfs/sapmnt\t/sapmnt\tnone\tbind\t0\t0" >> /etc/fstab
echo -e "/sapfs/sapdb\t/sapdb\tnone\tbind\t0\t0" >> /etc/fstab
echo -e "/sapfs/oracle\t/oracle\tnone\tbind\t0\t0" >> /etc/fstab
echo -e "/sapfs/db2\t/db2\tnone\tbind\t0\t0" >> /etc/fstab
echo -e "/sapfs/usr.sap\t/usr/sap\tnone\tbind\t0\t0" >> /etc/fstab
echo -e "/sapfs/tmp.install\t/tmp/install none\tbind\t0\t0" >> /etc/fstab
echo -e "/sapfs/informix\t/informix\tnone\tbind\t0\t0" >> /etc/fstab
echo -e "/sapfs/sybase\t/sybase\tnone\tbind\t0\t0" >> /etc/fstab
echo -e "/sapfs/hanamnt\t/hanamnt\tnone\tbind\t0\t0" >> /etc/fstab
echo -e "/sapfs/hana\t/hana\tnone\tbind\t0\t0" >> /etc/fstab
mount -a
cd /usr/scripts/
rm -f SAPCAR
ln -s /usr/linux_em/Tools/ppc64le/SAPCAR /usr/scripts/SAPCAR 
cd /usr
ln -s /sapmnt/fatools fa_scripte
ln -s /net/lsi033.data/linux linux_em
/usr/bin/ln -s /net/sapmnt.fatools /sapmnt/fatools
/usr/bin/mkdir /sapmnt/hs0100
/usr/bin/ln -s /net/sapmnt.hs0100.f /sapmnt/hs0100/f
/usr/bin/mkdir /sapmnt/hsi035
/usr/bin/mkdir /sapmnt/hsi035/b
/usr/bin/ln -s /net/sapmnt.hsi035.b.tcheck /sapmnt/hsi035/b/tcheck
/usr/bin/ln -s /net/sapmnt.kernelpatches /sapmnt/kernelpatches
/usr/bin/ln -s /net/sapmnt.patch_inbox_external /sapmnt/patch_inbox_external
/usr/bin/ln -s /usr/bin/perl /usr/bin/fa_perl
