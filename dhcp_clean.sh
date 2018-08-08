#!/usr/bin/bash 


find /backups -type f -mtime +60 -exec rm -f {} \; 
DATE=`date +%Y-%m-%d` 
cp /etc/dhcp/dhcpd.conf /backups/dhcpd.conf.${DATE} 
cat /etc/dhcp/dhcpd.conf | grep -v filename > /tmp/dhcpd.conf.${DATE} 
mv -f /tmp/dhcpd.conf.${DATE} /etc/dhcp/dhcpd.conf
systemctl restart dhcpd
