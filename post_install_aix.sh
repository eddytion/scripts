#!/bin/sh

HOST=$(uname -n|cut -f 1 -d".")
IPADDR=$(nslookup ${HOST} | grep Address | grep -v "#53" | cut -f 2 -d : | sed 's/ //g')
IPADDR_B=$(nslookup ${HOST}b | grep Address | grep -v "#53" | cut -f 2 -d : | sed 's/ //g')

chdev -l inet0 -a hostname=${HOST}

for fscsi in $(lsdev |grep fscsi|awk '{print $1}')
do
  chdev -l $fscsi -P -a fc_err_recov=fast_fail -a dyntrk=yes
done

for disk in $(lsdev -Cc disk |awk '{print $1}')
do 
  chdev -l $disk -P -a algorithm='fail_over' -a reserve_policy='no_reserve' -a hcheck_mode='nonactive' -a hcheck_cmd='test_unit_rdy' -a hcheck_interval='60' -a dist_tw_width='50' -a dist_err_pcnt='0' -a queue_depth='10'
done

for no in $(lsdev -Cc adapter |grep -e '^ent[0-9] Available' |sed -e 's/ent//' -e 's/ Available.*//')
do 
  chdev -l en$no -a mtu_bypass=on
done

wget http://lsh35350rh/instaix/mount.map -O /etc/mount.map
echo -e '/net\t/etc/mount.map' > /etc/auto_master
stopsrc -s automountd && sleep 2 && startsrc -s automountd

cd /net
ls|grep "^sapmnt"|while read nn
do
  mm=`echo $nn |awk -F. '{ OFS = "\/"; i=1; for (i=1;i<=NF; i++) printf OFS $i}'`
  oo=`echo $nn |awk -F. '{ OFS = "\/"; i=1; for (i=1;i<NF; i++) printf OFS $i}'`
  if [ ! -d $oo ]
  then
    echo "mkdir -p $oo"|ksh -x
  fi
  echo "ln -fs /net/$nn $mm"|ksh -x
done

/sapmnt/is0110/a/misc/HPed/hp_agent_install.sh > /tmp/hped_install.log 2>&1

crontab -l > /tmp/root.crontab
echo "9 * * * * /sapmnt/unixadmin/bin/sapui.pl > /tmp/sapui.log 2>&1" >> /tmp/root.crontab
cp /tmp/root.crontab /var/spool/cron/crontabs/root
crontab /var/spool/cron/crontabs/root

RVGDISK=`lsvg -p rootvg | grep hdisk | awk {'print $1'}`
PREFPATHS=`pcmpath query device | grep -wip ${RVGDISK} | grep fscsi | grep OPEN | grep -v "*" | awk {'print $1'} | tr '\n' ',' | sed 's/.$//'`
bootlist -m normal -o ${RVGDISK} pathid=${PREFPATHS}
