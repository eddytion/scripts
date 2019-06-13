#!/usr/bin/bash

curr_date=`date +"%Y-%m-%d"`
 bkp_file=~/dbbackup/hw_events-${curr_date}.sql
 mysqldump cloud hw_events > ${bkp_file}
 if [[ $? != 0 ]]
 then
 	echo "An error occurred while saving current events"
 	exit 1
 else
 	mysql cloud -e "truncate table hw_events;"
 fi

echo "Reloading firewall"
sudo firewall-cmd --complete-reload
script=$1

echo Sydney

/usr/bin/redsocks-sasgui -c ~/.sasgui/redsocks.conf.d/20267 &
/usr/bin/ssh -M -S Sydney -fnNT -p 22 -a -D 10267 sas@146.89.215.71 -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o ServerAliveInterval=15 -o ExitOnForwardFailure=yes -o BatchMode=yes
sudo iptables -t nat -N REDSOCKS
sudo iptables -t nat -A REDSOCKS -d 146.89.170.196/24 -p tcp -j REDIRECT --to-ports 20267
sudo iptables -t nat -A REDSOCKS -d 146.89.215.88/24 -p tcp -j REDIRECT --to-ports 20267
sudo iptables -t nat -A OUTPUT -p tcp -j REDSOCKS
sudo iptables -t nat -A PREROUTING -p tcp -j REDSOCKS
~/PycharmProjects/pssh/get_hmc_events_ssl.py au04hmc011ccpx1 au04hmc011ccpxa au04hmc021ccpx1 au04hmc021ccpxa
ssh -S Sydney -O exit sas@146.89.215.71
sudo iptables -t nat -F REDSOCKS
sudo iptables -t nat -D OUTPUT -p tcp -j REDSOCKS
sudo iptables -t nat -D PREROUTING -p tcp -j REDSOCKS
sudo iptables -t nat -X REDSOCKS
pkill redsocks-sasgui

echo Hortolandia

/usr/bin/redsocks-sasgui -c ~/.sasgui/redsocks.conf.d/20238 &
/usr/bin/ssh -M -S Hortolandia -fnNT -p 22 -a -D 10238 sas@146.89.111.71 -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o ServerAliveInterval=15 -o ExitOnForwardFailure=yes -o BatchMode=yes
sudo iptables -t nat -N REDSOCKS
sudo iptables -t nat -A REDSOCKS -d 146.89.170.196/24 -p tcp -j REDIRECT --to-ports 20238
sudo iptables -t nat -A REDSOCKS -d 146.89.111.88/24 -p tcp -j REDIRECT --to-ports 20238
sudo iptables -t nat -A OUTPUT -p tcp -j REDSOCKS
sudo iptables -t nat -A PREROUTING -p tcp -j REDSOCKS
~/PycharmProjects/pssh/get_hmc_events_ssl.py brhohmc011ccpx1 brhohmc011ccpxa brhohmc021ccpx1 brhohmc021ccpxa
ssh -S Hortolandia -O exit sas@146.89.111.71
sudo iptables -t nat -F REDSOCKS
sudo iptables -t nat -D OUTPUT -p tcp -j REDSOCKS
sudo iptables -t nat -D PREROUTING -p tcp -j REDSOCKS
sudo iptables -t nat -X REDSOCKS
pkill redsocks-sasgui

echo Toronto

/usr/bin/redsocks-sasgui -c ~/.sasgui/redsocks.conf.d/20276 &
/usr/bin/ssh -M -S Toronto -fnNT -p 22 -a -D 10276 sas@146.89.23.70 -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o ServerAliveInterval=15 -o ExitOnForwardFailure=yes -o BatchMode=yes
sudo iptables -t nat -N REDSOCKS
sudo iptables -t nat -A REDSOCKS -d 146.89.170.196/24 -p tcp -j REDIRECT --to-ports 20276
sudo iptables -t nat -A REDSOCKS -d 146.89.23.88/24 -p tcp -j REDIRECT --to-ports 20276
sudo iptables -t nat -A OUTPUT -p tcp -j REDSOCKS
sudo iptables -t nat -A PREROUTING -p tcp -j REDSOCKS
~/PycharmProjects/pssh/get_hmc_events_ssl.py catrhmc011ccpx1 catrhmc011ccpxa catrhmc021ccpx1 catrhmc021ccpxa
ssh -S Toronto -O exit sas@146.89.23.70
sudo iptables -t nat -F REDSOCKS
sudo iptables -t nat -D OUTPUT -p tcp -j REDSOCKS
sudo iptables -t nat -D PREROUTING -p tcp -j REDSOCKS
sudo iptables -t nat -X REDSOCKS
pkill redsocks-sasgui

echo Ehningen

/usr/bin/redsocks-sasgui -c ~/.sasgui/redsocks.conf.d/20232 &
/usr/bin/ssh -M -S Ehningen -fnNT -p 22 -a -D 10232 sas@9.149.246.102 -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o ServerAliveInterval=15 -o ExitOnForwardFailure=yes -o BatchMode=yes
sudo iptables -t nat -N REDSOCKS
sudo iptables -t nat -A REDSOCKS -d 146.89.170.196/24 -p tcp -j REDIRECT --to-ports 20232
sudo iptables -t nat -A REDSOCKS -d 146.89.171.196/24 -p tcp -j REDIRECT --to-ports 20232
sudo iptables -t nat -A REDSOCKS -d 146.89.131.88/24 -p tcp -j REDIRECT --to-ports 20232
sudo iptables -t nat -A OUTPUT -p tcp -j REDSOCKS
sudo iptables -t nat -A PREROUTING -p tcp -j REDSOCKS
~/PycharmProjects/pssh/get_hmc_events_ssl.py deehhmc011ccpx1 deehhmc011ccpx2 deehhmc011ccpxa deehhmc021ccpx1 deehhmc021ccpx2 deehhmc021ccpxa
ssh -S Ehningen -O exit sas@9.149.246.102
sudo iptables -t nat -F REDSOCKS
sudo iptables -t nat -D OUTPUT -p tcp -j REDSOCKS
sudo iptables -t nat -D PREROUTING -p tcp -j REDSOCKS
sudo iptables -t nat -X REDSOCKS
pkill redsocks-sasgui

echo Ehningen NG

/usr/bin/redsocks-sasgui -c ~/.sasgui/redsocks.conf.d/20864 &
/usr/bin/ssh -M -S Ehningen_NG -fnNT -p 22 -a -D 10864 sas@146.89.186.80 -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o ServerAliveInterval=15 -o ExitOnForwardFailure=yes -o BatchMode=yes
sudo iptables -t nat -N REDSOCKS
sudo iptables -t nat -A REDSOCKS -d 146.89.186.66/24 -p tcp -j REDIRECT --to-ports 20864
sudo iptables -t nat -A OUTPUT -p tcp -j REDSOCKS
sudo iptables -t nat -A PREROUTING -p tcp -j REDSOCKS
~/PycharmProjects/pssh/get_hmc_events_ssl.py deehhmc016ccpxa deehhmc026ccpxa
ssh -S Ehningen_NG -O exit sas@146.89.186.80
sudo iptables -t nat -F REDSOCKS
sudo iptables -t nat -D OUTPUT -p tcp -j REDSOCKS
sudo iptables -t nat -D PREROUTING -p tcp -j REDSOCKS
sudo iptables -t nat -X REDSOCKS
pkill redsocks-sasgui

echo Barcelona

/usr/bin/redsocks-sasgui -c ~/.sasgui/redsocks.conf.d/20350 &
/usr/bin/ssh -M -S Barcelona -fnNT -p 22 -a -D 10350 sas@130.103.151.71 -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o ServerAliveInterval=15 -o ExitOnForwardFailure=yes -o BatchMode=yes
sudo iptables -t nat -N REDSOCKS
sudo iptables -t nat -A REDSOCKS -d 146.89.170.196/24 -p tcp -j REDIRECT --to-ports 20350
sudo iptables -t nat -A REDSOCKS -d 130.103.151.88/24 -p tcp -j REDIRECT --to-ports 20350
sudo iptables -t nat -A OUTPUT -p tcp -j REDSOCKS
sudo iptables -t nat -A PREROUTING -p tcp -j REDSOCKS
~/PycharmProjects/pssh/get_hmc_events_ssl.py es03hmc011ccpx1 es03hmc011ccpxa es03hmc021ccpx1 es03hmc021ccpxa
ssh -S Barcelona -O exit sas@130.103.151.71
sudo iptables -t nat -F REDSOCKS
sudo iptables -t nat -D OUTPUT -p tcp -j REDSOCKS
sudo iptables -t nat -D PREROUTING -p tcp -j REDSOCKS
sudo iptables -t nat -X REDSOCKS
pkill redsocks-sasgui

echo Montpellier

/usr/bin/redsocks-sasgui -c ~/.sasgui/redsocks.conf.d/20263 &
/usr/bin/ssh -M -S Montpellier -fnNT -p 22 -a -D 10263 sas@146.89.159.70 -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o ServerAliveInterval=15 -o ExitOnForwardFailure=yes -o BatchMode=yes
sudo iptables -t nat -N REDSOCKS
sudo iptables -t nat -A REDSOCKS -d 146.89.170.196/24 -p tcp -j REDIRECT --to-ports 20263
sudo iptables -t nat -A REDSOCKS -d 146.89.159.88/24 -p tcp -j REDIRECT --to-ports 20263
sudo iptables -t nat -A OUTPUT -p tcp -j REDSOCKS
sudo iptables -t nat -A PREROUTING -p tcp -j REDSOCKS
~/PycharmProjects/pssh/get_hmc_events_ssl.py frgrhmc011ccpx1 frgrhmc011ccpxa frgrhmc021ccpx1 frgrhmc021ccpxa
ssh -S Montpellier -O exit sas@146.89.159.70
sudo iptables -t nat -F REDSOCKS
sudo iptables -t nat -D OUTPUT -p tcp -j REDSOCKS
sudo iptables -t nat -D PREROUTING -p tcp -j REDSOCKS
sudo iptables -t nat -X REDSOCKS
pkill redsocks-sasgui

echo Fareham

/usr/bin/redsocks-sasgui -c ~/.sasgui/redsocks.conf.d/20809 &
/usr/bin/ssh -M -S Fareham -fnNT -p 22 -a -D 10809 sas@158.87.135.71 -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o ServerAliveInterval=15 -o ExitOnForwardFailure=yes -o BatchMode=yes
sudo iptables -t nat -N REDSOCKS
sudo iptables -t nat -A REDSOCKS -d 129.41.126.2/24 -p tcp -j REDIRECT --to-ports 20809
sudo iptables -t nat -A REDSOCKS -d 158.87.135.88/24 -p tcp -j REDIRECT --to-ports 20809
sudo iptables -t nat -A OUTPUT -p tcp -j REDSOCKS
sudo iptables -t nat -A PREROUTING -p tcp -j REDSOCKS
~/PycharmProjects/pssh/get_hmc_events_ssl.py gbfmhmc011ccpx1 gbfmhmc011ccpxa gbfmhmc021ccpx1 gbfmhmc021ccpxa
ssh -S Fareham -O exit sas@158.87.135.71
sudo iptables -t nat -F REDSOCKS
sudo iptables -t nat -D OUTPUT -p tcp -j REDSOCKS
sudo iptables -t nat -D PREROUTING -p tcp -j REDSOCKS
sudo iptables -t nat -X REDSOCKS
pkill redsocks-sasgui

echo Tokyo

/usr/bin/redsocks-sasgui -c ~/.sasgui/redsocks.conf.d/20254 &
/usr/bin/ssh -M -S Tokyo -fnNT -p 22 -a -D 10254 sas@146.89.223.71 -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o ServerAliveInterval=15 -o ExitOnForwardFailure=yes -o BatchMode=yes
sudo iptables -t nat -N REDSOCKS
sudo iptables -t nat -A REDSOCKS -d 146.89.170.196/24 -p tcp -j REDIRECT --to-ports 20254
sudo iptables -t nat -A REDSOCKS -d 146.89.223.88/24 -p tcp -j REDIRECT --to-ports 20254
sudo iptables -t nat -A OUTPUT -p tcp -j REDSOCKS
sudo iptables -t nat -A PREROUTING -p tcp -j REDSOCKS
~/PycharmProjects/pssh/get_hmc_events_ssl.py jp08hmc011ccpx1 jp08hmc011ccpxa jp08hmc021ccpx1 jp08hmc021ccpxa
ssh -S Tokyo -O exit sas@146.89.223.71
sudo iptables -t nat -F REDSOCKS
sudo iptables -t nat -D OUTPUT -p tcp -j REDSOCKS
sudo iptables -t nat -D PREROUTING -p tcp -j REDSOCKS
sudo iptables -t nat -X REDSOCKS
pkill redsocks-sasgui

echo Amsterdam

/usr/bin/redsocks-sasgui -c ~/.sasgui/redsocks.conf.d/20389 &
/usr/bin/ssh -M -S Amsterdam -fnNT -p 22 -a -D 10389 sas@146.89.149.96 -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o ServerAliveInterval=15 -o ExitOnForwardFailure=yes -o BatchMode=yes
sudo iptables -t nat -N REDSOCKS
sudo iptables -t nat -A REDSOCKS -d 146.89.170.196/24 -p tcp -j REDIRECT --to-ports 20389
sudo iptables -t nat -A REDSOCKS -d 146.89.149.88/24 -p tcp -j REDIRECT --to-ports 20389
sudo iptables -t nat -A OUTPUT -p tcp -j REDSOCKS
sudo iptables -t nat -A PREROUTING -p tcp -j REDSOCKS
~/PycharmProjects/pssh/get_hmc_events_ssl.py nl03hmc011ccpxa nl03hmc021ccpxa
ssh -S Amsterdam -O exit sas@146.89.149.96
sudo iptables -t nat -F REDSOCKS
sudo iptables -t nat -D OUTPUT -p tcp -j REDSOCKS
sudo iptables -t nat -D PREROUTING -p tcp -j REDSOCKS
sudo iptables -t nat -X REDSOCKS
pkill redsocks-sasgui

echo Portsmouth

/usr/bin/redsocks-sasgui -c ~/.sasgui/redsocks.conf.d/20455 &
/usr/bin/ssh -M -S Portsmouth -fnNT -p 22 -a -D 10455 sas@130.103.159.70 -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o ServerAliveInterval=15 -o ExitOnForwardFailure=yes -o BatchMode=yes
sudo iptables -t nat -N REDSOCKS
sudo iptables -t nat -A REDSOCKS -d 146.89.170.196/24 -p tcp -j REDIRECT --to-ports 20455
sudo iptables -t nat -A REDSOCKS -d 130.103.159.88/24 -p tcp -j REDIRECT --to-ports 20455
sudo iptables -t nat -A OUTPUT -p tcp -j REDSOCKS
sudo iptables -t nat -A PREROUTING -p tcp -j REDSOCKS
~/PycharmProjects/pssh/get_hmc_events_ssl.py ukpmhmc011ccpx1 ukpmhmc011ccpxa ukpmhmc021ccpx1 ukpmhmc021ccpxa
ssh -S Portsmouth -O exit sas@130.103.159.70
sudo iptables -t nat -F REDSOCKS
sudo iptables -t nat -D OUTPUT -p tcp -j REDSOCKS
sudo iptables -t nat -D PREROUTING -p tcp -j REDSOCKS
sudo iptables -t nat -X REDSOCKS
pkill redsocks-sasgui

echo Poughkeepsie

/usr/bin/redsocks-sasgui -c ~/.sasgui/redsocks.conf.d/20885 &
/usr/bin/ssh -M -S Poughkeepsie -fnNT -p 22 -a -D 10885 sas@158.87.29.71 -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o ServerAliveInterval=15 -o ExitOnForwardFailure=yes -o BatchMode=yes
sudo iptables -t nat -N REDSOCKS
sudo iptables -t nat -A REDSOCKS -d 129.41.126.2/24 -p tcp -j REDIRECT --to-ports 20885
sudo iptables -t nat -A REDSOCKS -d 158.87.29.88/24 -p tcp -j REDIRECT --to-ports 20885
sudo iptables -t nat -A OUTPUT -p tcp -j REDSOCKS
sudo iptables -t nat -A PREROUTING -p tcp -j REDSOCKS
~/PycharmProjects/pssh/get_hmc_events_ssl.py us22hmc011ccpx1 us22hmc011ccpxa us22hmc021ccpx1 us22hmc021ccpxa
ssh -S Poughkeepsie -O exit sas@158.87.29.71
sudo iptables -t nat -F REDSOCKS
sudo iptables -t nat -D OUTPUT -p tcp -j REDSOCKS
sudo iptables -t nat -D PREROUTING -p tcp -j REDSOCKS
sudo iptables -t nat -X REDSOCKS
pkill redsocks-sasgui

echo Boulder

/usr/bin/redsocks-sasgui -c ~/.sasgui/redsocks.conf.d/20252 &
/usr/bin/ssh -M -S Boulder -fnNT -p 22 -a -D 10252 sas@146.89.17.70 -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o ServerAliveInterval=15 -o ExitOnForwardFailure=yes -o BatchMode=yes
sudo iptables -t nat -N REDSOCKS
sudo iptables -t nat -A REDSOCKS -d 146.89.170.196/24 -p tcp -j REDIRECT --to-ports 20252
sudo iptables -t nat -A REDSOCKS -d 146.89.17.88/24 -p tcp -j REDIRECT --to-ports 20252
sudo iptables -t nat -A OUTPUT -p tcp -j REDSOCKS
sudo iptables -t nat -A PREROUTING -p tcp -j REDSOCKS
~/PycharmProjects/pssh/get_hmc_events_ssl.py usbdhmc011ccpx1 usbdhmc011ccpxa usbdhmc021ccpx1 usbdhmc021ccpxa
ssh -S Boulder -O exit sas@146.89.17.70
sudo iptables -t nat -F REDSOCKS
sudo iptables -t nat -D OUTPUT -p tcp -j REDSOCKS
sudo iptables -t nat -D PREROUTING -p tcp -j REDSOCKS
sudo iptables -t nat -X REDSOCKS
pkill redsocks-sasgui


echo Raleigh

/usr/bin/redsocks-sasgui -c ~/.sasgui/redsocks.conf.d/20235 &
/usr/bin/ssh -M -S Raleigh -fnNT -p 22 -a -D 10235 sas@146.89.1.71 -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o ServerAliveInterval=15 -o ExitOnForwardFailure=yes -o BatchMode=yes
sudo iptables -t nat -N REDSOCKS
sudo iptables -t nat -A REDSOCKS -d 146.89.170.196/24 -p tcp -j REDIRECT --to-ports 20235
sudo iptables -t nat -A REDSOCKS -d 146.89.170.197/24 -p tcp -j REDIRECT --to-ports 20235
sudo iptables -t nat -A REDSOCKS -d 146.89.171.196/24 -p tcp -j REDIRECT --to-ports 20235
sudo iptables -t nat -A REDSOCKS -d 146.89.1.89/24 -p tcp -j REDIRECT --to-ports 20235
sudo iptables -t nat -A OUTPUT -p tcp -j REDSOCKS
sudo iptables -t nat -A PREROUTING -p tcp -j REDSOCKS
~/PycharmProjects/pssh/get_hmc_events_ssl.py usrdhmc011ccpxa usrdhmc021ccpxa usrdhmc011ccpx1 usrdhmc021ccpx1 usrdhmc011ccpx2 usrdhmc021ccpx2
ssh -S Raleigh -O exit sas@146.89.1.71
sudo iptables -t nat -F REDSOCKS
sudo iptables -t nat -D OUTPUT -p tcp -j REDSOCKS
sudo iptables -t nat -D PREROUTING -p tcp -j REDSOCKS
sudo iptables -t nat -X REDSOCKS
pkill redsocks-sasgui

echo Raleigh Staging

/usr/bin/redsocks-sasgui -c ~/.sasgui/redsocks.conf.d/20259 &
/usr/bin/ssh -M -S Raleigh_Staging -fnNT -p 22 -a -D 10259 sas@146.89.5.71 -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o ServerAliveInterval=15 -o ExitOnForwardFailure=yes -o BatchMode=yes
sudo iptables -t nat -N REDSOCKS
sudo iptables -t nat -A REDSOCKS -d 146.89.170.196/24 -p tcp -j REDIRECT --to-ports 20259
sudo iptables -t nat -A REDSOCKS -d 146.89.5.88/24 -p tcp -j REDIRECT --to-ports 20259
sudo iptables -t nat -A OUTPUT -p tcp -j REDSOCKS
sudo iptables -t nat -A PREROUTING -p tcp -j REDSOCKS
~/PycharmProjects/pssh/get_hmc_events_ssl.py usrdhmc012ccpxa usrdhmc022ccpxa usrdhmc012ccpx1 usrdhmc022ccpx1
ssh -S Raleigh_Staging -O exit sas@146.89.5.71
sudo iptables -t nat -F REDSOCKS
sudo iptables -t nat -D OUTPUT -p tcp -j REDSOCKS
sudo iptables -t nat -D PREROUTING -p tcp -j REDSOCKS
sudo iptables -t nat -X REDSOCKS
pkill redsocks-sasgui

echo Raleigh Staging NG Central

/usr/bin/redsocks-sasgui -c ~/.sasgui/redsocks.conf.d/20400 &
/usr/bin/ssh -M -S Raleigh_Staging_NG_Central -fnNT -p 22 -a -D 10400 sas@130.103.49.80 -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o ServerAliveInterval=15 -o ExitOnForwardFailure=yes -o BatchMode=yes
sudo iptables -t nat -N REDSOCKS
sudo iptables -t nat -A REDSOCKS -d 130.103.49.66/24 -p tcp -j REDIRECT --to-ports 20400
sudo iptables -t nat -A OUTPUT -p tcp -j REDSOCKS
sudo iptables -t nat -A PREROUTING -p tcp -j REDSOCKS
~/PycharmProjects/pssh/get_hmc_events_ssl.py usrdhmc019ccpxa usrdhmc029ccpxa
ssh -S Raleigh_Staging_NG_Central -O exit sas@130.103.49.80
sudo iptables -t nat -F REDSOCKS
sudo iptables -t nat -D OUTPUT -p tcp -j REDSOCKS
sudo iptables -t nat -D PREROUTING -p tcp -j REDSOCKS
sudo iptables -t nat -X REDSOCKS
pkill redsocks-sasgui

echo Raleigh Staging NG Site

/usr/bin/redsocks-sasgui -c ~/.sasgui/redsocks.conf.d/20902 &
/usr/bin/ssh -M -S Raleigh_Staging_NG_Site -fnNT -p 22 -a -D 10902 sas@130.103.51.95 -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o ServerAliveInterval=15 -o ExitOnForwardFailure=yes -o BatchMode=yes
sudo iptables -t nat -N REDSOCKS
sudo iptables -t nat -A REDSOCKS -d 130.103.51.88/24 -p tcp -j REDIRECT --to-ports 20902
sudo iptables -t nat -A REDSOCKS -d 129.41.125.2/24 -p tcp -j REDIRECT --to-ports 20902
sudo iptables -t nat -A OUTPUT -p tcp -j REDSOCKS
sudo iptables -t nat -A PREROUTING -p tcp -j REDSOCKS
~/PycharmProjects/pssh/get_hmc_events_ssl.py usrdhmc018ccpxa usrdhmc028ccpxa
ssh -S Raleigh_Staging_NG_Site -O exit sas@130.103.51.95
sudo iptables -t nat -F REDSOCKS
sudo iptables -t nat -D OUTPUT -p tcp -j REDSOCKS
sudo iptables -t nat -D PREROUTING -p tcp -j REDSOCKS
sudo iptables -t nat -X REDSOCKS
pkill redsocks-sasgui

echo Winterthur

/usr/bin/redsocks-sasgui -c ~/.sasgui/redsocks.conf.d/20327 &
/usr/bin/ssh -M -S Winterthur -fnNT -p 22 -a -D 10327 sas@130.103.157.71 -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o ServerAliveInterval=15 -o ExitOnForwardFailure=yes -o BatchMode=yes
sudo iptables -t nat -N REDSOCKS
sudo iptables -t nat -A REDSOCKS -d 146.89.170.196/24 -p tcp -j REDIRECT --to-ports 20327
sudo iptables -t nat -A REDSOCKS -d 130.103.157.88/24 -p tcp -j REDIRECT --to-ports 20327
sudo iptables -t nat -A OUTPUT -p tcp -j REDSOCKS
sudo iptables -t nat -A PREROUTING -p tcp -j REDSOCKS
~/PycharmProjects/pssh/cloud_update.py chwthmc011ccpx1 chwthmc011ccpxa chwthmc021ccpx1 chwthmc021ccpxa
ssh -S Winterthur -O exit sas@130.103.157.71
sudo iptables -t nat -F REDSOCKS
sudo iptables -t nat -D OUTPUT -p tcp -j REDSOCKS
sudo iptables -t nat -D PREROUTING -p tcp -j REDSOCKS
sudo iptables -t nat -X REDSOCKS
pkill redsocks-sasgui

