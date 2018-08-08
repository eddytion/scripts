#!/usr/bin/perl
 
system("clear");
 
# Legenda
# a_ ... array
# h_ ... hash
# s_ ... string
# i_ ... integer
# r_ ... reference

# Netmask conversion subroutine

sub convert_nmask {
  my $netmask = shift;
  my @netmask_out = ($netmask =~ m/.{2}/g);
  my @arr;
  foreach $piece (@netmask_out)
  {
    $x = hex ($piece);
    push(@arr,"$x");
  }
  my $nmask = "$arr[0].$arr[1].$arr[2].$arr[3]";
}

my $hostname = `uname -n | cut -f 1 -d .`;
chomp($hostname);
system("echo \"domain wdf.sap.corp\" > /etc/resolv.conf");
system("echo \"nameserver 10.17.121.30\" >> /etc/resolv.conf");
system("nfso -p -o nfs_use_reserved_ports=1");
my $s_new_if_acc;
my $ip_addr = `host $hostname | awk {'print \$3'}`;
my $dns = "10.17.121.30";
my $fqdn = "wdf.sap.corp";
my $access_if = `ifconfig -a | grep -v lo0 | grep en | cut -f 1 -d : | head -1`;
chomp($access_if);
my $netmask = `ifconfig $access_if | grep netmask | awk {'print \$4'} | sed 's/0x//g'`;
my $gw = `netstat -nr | grep default | awk {'print \$2'}`;
chomp($gw,$ip_addr,$dns,$fqdn,$netmask);
my $netmask_decimal = convert_nmask($netmask);
 
# Logging functions --> General, OK, WARN, CRIT, UNKN
 
sub logging {
  my ($msg) = @_;
  print "INFO: $msg \n";
  open(FILE, ">> $file");
  print FILE "$msg\n";
  close(FILE);
}
 
sub ok_logging {
  my ($msg) = @_;
  print "OK:\t $msg \n";
}
 
sub warn_logging {
  my ($msg) = @_;
  print "WARN:\t $msg \n";
}
 
sub crit_logging {
  my ($msg) = @_;
  print "CRIT:\t $msg \n";
}
 
sub unkn_logging {
  my ($msg) = @_;
  print "UNKNOWN:\t $msg \n";
}
 
system("lslpp -l ios.sea >/dev/null 2>&1");
if($? != 0)
{
  crit_logging("This script must be run on a VIO server");
  exit(1);
}

sub chfs {
  system("chfs -a size=1G /");
  system("chfs -a size=7G /usr");
  system("chfs -a size=5G /var");
  system("chfs -a size=6G /tmp");
  system("chfs -a size=5G /home");
  system("chfs -a size=3G /opt");
  system("chfs -a size=1G /var/adm/ras/livedump");
}
 
sub network_tunables {
  system("no -p -o rfc1323=1");
  system("no -p -o tcp_recvspace=262144 -o tcp_sendspace=262144");
  system("no -p -o tcp_nodelayack=1");
  system("no -p -o sack=1");
  system("no -p -o udp_sendspace=65536");
  system("no -p -o udp_recvspace=655360");
  system("chdev -l vioslpm0 -a auto_tunnel=0 -P");
}
 
sub network_buffers {
  my @a_vadapters = `lsdev -Ccadapter | grep -i "Virtual I/O Ethernet Adapter" | awk {'print \$1'}`;
  chomp(@a_vadapters);
  foreach $vadapter (@a_vadapters)
  {
    system("chdev -l $vadapter -a max_buf_small=4096 -a min_buf_small=4096 -a min_buf_medium=512 -a max_buf_medium=1024 -a min_buf_large=96 -a max_buf_large=256 -a min_buf_huge=96 -a max_buf_huge=128 -a min_buf_tiny=4096 -a max_buf_tiny=4096 -P");
  }
}
 
sub phys_adapter_tuning {
  my @a_padapters = `lsdev -Ccadapter | grep ent | egrep -v "Virtual|Shared" | awk {'print \$1'}`;
  chomp(@a_padapters);
  foreach $padapter (@a_padapters)
  {
    system("chdev -l $padapter -a large_receive=yes -a large_send=yes -a jumbo_frames=yes -a chksum_offload=yes -a flow_ctrl=yes -P");
  }
}
 
sub mtu_bypass_vadapters {
  my @a_vadapters = `lsdev -Ccadapter | grep "Virtual I/O Ethernet Adapter" | awk {'print \$1'} | sed 's/t//g'`;
  chomp(@a_vadapters);
  foreach $vadapter (@a_vadapters)
  {
    system("chdev -l $vadapter -a mtu_bypass=on -P");
  }
}
 
sub fscsi_tuning {
  my @a_fscsi = `lsdev | grep fscsi | awk {'print \$1'}`;
  chomp(@a_fscsi);
  foreach $fscsi (@a_fscsi)
  {
    system("chdev -l $fscsi -a fc_err_recov=fast_fail -a dyntrk=yes -P");
  }
}
 
sub fcs_tuning {
  my @a_fcs = `lsdev | grep fcs | grep 8Gb | awk {'print \$1'}`;
  chomp(@a_fcs);
  foreach $fcs (@a_fcs)
  {
    my $xfer_size = `lsattr -El $fcs | grep -w max_xfer_size | awk {'print \$2'}`;
    chomp($xfer_size);
    if($xfer_size eq "0x400000")
    {
      ok_logging("$fcs has max_xfer_size set to $xfer_size");
    }
    else
    {
      system("chdev -l $fcs -a max_xfer_size=\"0x400000\" -P");
    }
 } 
}
 
sub access_if {
  my $curr_access_if = `ifconfig -a | grep -v lo0 | grep en | cut -f 1 -d : | head -1`;
  chomp($curr_access_if);
 
  my @a_vadapters = `lsdev -Ccadapter | grep "Virtual I/O Ethernet Adapter" | awk {'print \$1'} | sed 's/t//g' | grep -v $curr_access_if`;
  chomp(@a_vadapters);
  foreach $vadapter (@a_vadapters)
  {
    my $port_vlan = `entstat -d $vadapter | grep "Port VLAN ID" | cut -f 2 -d \\: | sed 's/ //g'`;
    my $trunk_adapter = `entstat -d $vadapter | grep Trunk | cut -f 2 -d \\: | sed 's/ //g'`;
    chomp($port_vlan,$trunk_adapter);
    if($port_vlan eq "10" && $trunk_adapter eq "False")
    {
      my $s_new_if_acc_tmp = `echo $vadapter | sed 's/t//g'`;
      chomp($s_new_if_acc_tmp);
      $s_new_if_acc = $s_new_if_acc_tmp;
    }
    system("ifconfig $vadapter 0 >/dev/null 2>&1");
    system("ifconfig $vadapter detach >/dev/null 2>&1");
  }
  
  system("chdev -l $curr_access_if -a netaddr=' ' -a netmask=' ' -a mtu_bypass=on");
  system("ifconfig $curr_access_if 0");
  system("ifconfig $curr_access_if detach");
  system("chdev -l $s_new_if_acc -a netmask='$netmask_decimal' -a netaddr='$ip_addr' -a tcp_sendspace=524288 -a tcp_recvspace=524288 -a mtu_bypass=on -a mtu=9000 -a state=up");
  system("/usr/sbin/mktcpip -h'$hostname' -a'$ip_addr' -m'$netmask_decimal' -i '$s_new_if_acc' -n'$dns' -d'$fqdn' -g'$gw' -A'no' -t'N/A' '-s'");
}

 
sub roce_config {
  my @a_roce_hba = `lsdev -Ccadapter | grep RoCE | grep hba | awk {'print \$1'}`;
  my @a_roce_ent = `lsdev -Ccadapter | grep RoCE | grep -v hba | grep ent | awk {'print \$1'}`;
  chomp(@a_roce_ent,@a_roce_hba);
 
  if(scalar @a_roce_hba > 0 && scalar @a_roce_ent > 0)
  {
    foreach $hba (@a_roce_hba)
    {
      my $hba_mode = `lsattr -El $hba | grep -w stack_type | awk {'print \$2'}`;
      chomp($hba_mode);
      if($hba_mode ne "ofed")
      {
        foreach $ent (@a_roce_ent)
        {
          system("rmdev -dl $ent");
        }
        system("chdev -l $hba -a stack_type=ofed -P");
        system("cfgmgr");
      }
    }
  }
}
 
sub sea_config {
    system("/usr/ios/cli/ioscli mkvdev -sea ent0 -vadapter ent4 -default ent4 -defaultid 10 -attr ha_mode=auto ctl_chan=ent5 jumbo_frames=yes large_receive=yes largesend=1 health_time=60");
    system("/usr/ios/cli/ioscli mkvdev -sea ent1 -vadapter ent6 -default ent6 -defaultid 20 -attr ha_mode=auto ctl_chan=ent7 jumbo_frames=yes large_receive=yes largesend=1 health_time=60");
    system("/etc/rc.tcpip");
}

sub mkuser {
  my $unixp = `echo | openssl enc -base64 -d`;
  chomp($unixp);
  system("mount -o soft 10.76.182.245:/exports /mnt");
  system("mkuser unix");
  system("echo \"unix:$unixp\" | chpasswd");
  system("pwdadm -c unix");
  system("cp /etc/passwd /etc/passwd.bak; cat /etc/passwd | grep -v unix > /tmp/passwd; echo \"unix:!:0:0::/home/unix:/usr/bin/ksh\" >> /tmp/passwd; cp /tmp/passwd /etc/passwd");
  system("cp /mnt/viosconf/profile_aix /home/unix/.profile; chown unix /home/unix/.profile; chmod 600 /home/unix/.profile");
  system("mkdir /home/unix/.ssh; cp /mnt/viosconf/authorized_keys_unx /home/unix/.ssh/authorized_keys");
  system("chown -R unix /home/unix; chmod 400 /home/unix/.ssh/authorized_keys");
  system("umount -f /mnt");
}

 
sub lpar2rrd {
  system("mkdir -p /tmp/update >/dev/null 2>&1");
  system("mount 10.76.182.245:/exports /tmp/update");
  system("rpm -Uvh /tmp/update/lpar2rrd/lpar2rrd-agent-5.00-4.ppc.rpm");
  system("crontab -l > /tmp/crontab_lpar2rrd");
  system("echo \"#LPAR2RRD Entries\" >> /tmp/crontab_lpar2rrd");
  system("echo \"00 00 * * * LANG=C; export LANG; /usr/bin/nmon -O -^ -f -t -D -E -s60 -c1440 -m'/home/lpar2rrd'\" >> /tmp/crontab_lpar2rrd");
  system("echo \"0 1 * * * find /home/lpar2rrd -type f -name \"*nmon*\" -mtime +7 -exec rm -f {} \\;\" >> /tmp/crontab_lpar2rrd");
  system("echo \"0,30 * * * * /usr/bin/perl /opt/lpar2rrd-agent/lpar2rrd-agent.pl -n /home/lpar2rrd lsh35350rh.wdf.sap.corp > /var/tmp/lpar2rrd-agent-nmon.out 2>&1\" >> /tmp/crontab_lpar2rrd");
  system("cp /tmp/crontab_lpar2rrd /var/spool/cron/crontabs/root; crontab /var/spool/cron/crontabs/root");
  system("mkdir -p /home/lpar2rrd");
  system("cd /; umount -f /tmp/update");
}
 
sub fscsi_autoconfig {
  my @a_active_fscsi = `lspath | grep fscsi | awk {'print \$3'} | sort | uniq`;
  my @a_all_fscsi = `lsdev | grep fscsi | awk {'print \$1'}`;
  chomp(@a_active_fscsi,@a_all_fscsi);
  my @a_final_array;
 
  foreach $elem (@a_all_fscsi)
  {
    if(grep { $_ eq $elem } @a_active_fscsi)
    {
      print "skipping $elem \n";
    }
    else
    {
      push(@a_final_array,$elem);
    }
  }
 
  foreach $fscsi (@a_final_array)
  {
    system("chdev -l $fscsi -a \"autoconfig=defined\" -P");
  }
}
 
sub microcode {
  my $model = `lsconf | grep \"System Model\" | cut -f 2 -d ,`;
  chomp($model);
  system("mount -o soft 10.66.140.27:/sapmnt/is0110/a/firmware/$model /mnt");
  if($? ne "0")
  {
    crit_logging("Unable to mount repository for microcode, please check manually");
  }
  else
  {
    system("rpm -Uvh /mnt/*.rpm --ignoreos");
    if($? eq "0")
    {
      ok_logging("Microcodes have been installed, apply them with DIAG tool");
    }
    else
    {
      warn_logging("Previous command exited with a non-zero exit code");
    }
    system("umount -f /mnt");
  }
}

sub sys_update {
  system("installp -c all >/dev/null 2>&1");
  system("mkdir /tmp/update >/dev/null 2>&1; mount -o soft 10.66.140.27:/sapmnt/is0110/a/vios/VIOS_2.2.6.10 /tmp/update");
  system("install_all_updates -d /tmp/update -c -Y");
  system("installp -c all >/dev/null 2>&1");
  system("cd /; umount -f /tmp/update");
  system("mount -o soft 10.66.140.27:/sapmnt/is0110/a/misc/sddpcm2700_vios /tmp/update");
  system("install_all_updates -cY -d /tmp/update all");
  system("cd /; umount -f /tmp/update");
  system("installp -c all >/dev/null 2>&1");
  system("echo \"PermitRootLogin yes\" >> /etc/ssh/sshd_config");
  system("stopsrc -s sshd; sleep 2; startsrc -s sshd");
}

sub syslog_setup {
  system("mount -o soft 10.66.128.13:/export/install/cfg /mnt");
  if($? != 0)
  {
    warn_logging("Unable to mount repo, syslog will not be setup");
  }
  else
  {
    system("cp /mnt/syslog.conf /etc/syslog.conf");
    system("mkdir -p /var/adm/syslog");
    system("touch /var/adm/syslog/syslog.log; touch /var/adm/syslog/kern.log ;touch /var/adm/syslog/user.log ;touch /var/adm/syslog/mail.log ;touch /var/adm/syslog/daemon.log");
    system("touch /var/adm/syslog/auth.log ;touch /var/adm/syslog/lpr.log ;touch /var/adm/syslog/news.log ;touch /var/adm/syslog/uucp.log ;touch /var/adm/syslog/problem.log");
    system("touch /var/log/aso/aso.log; touch /var/log/aso/aso_process.log; touch /var/adm/ras/syslog.caa; touch /var/log/aso/aso_debug.log");
    system("stopsrc -s syslogd; sleep 2; startsrc -s syslogd");
  }
}
 
&chfs;
&network_tunables;
&network_buffers;
&phys_adapter_tuning;
&mtu_bypass_vadapters;
&fscsi_tuning;
&fcs_tuning;
&access_if;
&roce_config;
&sea_config;
&mkuser;
&lpar2rrd;
&fscsi_autoconfig;
&microcode;
&sys_update;
&syslog_setup;
