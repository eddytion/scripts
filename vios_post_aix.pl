#!/usr/bin/perl
 
system("clear");
 
# Legenda
# a_ ... array
# h_ ... hash
# s_ ... string
# i_ ... integer
# r_ ... reference
 
my $hostname = `uname -n | cut -f 1 -d .`;
chomp($hostname);
system("nfso -p -o nfs_use_reserved_ports=1");
 
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
 
sub mount_repo {
  system("mount -o soft 10.76.177.146:/viosconfig /mnt");
  if($? == 0)
  {
    ok_logging("NFS repo has been successfully mounted");
  }
  else
  {
    crit_logging("NFS repo could not be mounted, aborting ...");
    exit(1);
  }
 
  system("touch /mnt/test_$hostname; rm /mnt/test_$hostname");
  if($? == 0)
  {
    ok_logging("NFS repo is writable");
  }
  else
  {
    crit_logging("NFS repo is not writable, aborting");
    exit(1);
  }
 
  my $file_count = `ls /mnt | grep -c $hostname`;
  chomp($file_count);
 
  if($file_count < 4)
  {
    crit_logging("There is no proper backup present for this system in /mnt. Script cannot continue");
    exit(1);
  }
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

sub copy_files_locally {
  system("mkdir /tmp/prev_config");
  system("cp /mnt/fcmap_$hostname /tmp/prev_config >/dev/null 2>&1");
  system("cp /mnt/netcfg_$hostname /tmp/prev_config >/dev/null 2>&1");
  system("cp /mnt/seacfg_$hostname /tmp/prev_config >/dev/null 2>&1");
  system("cp /mnt/ssh_$hostname.tar /tmp/prev_config >/dev/null 2>&1");
  system("cp /mnt/scsimap_$hostname /tmp/prev_config >/dev/null 2>&1");
  unlink("/etc/niminfo");
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
  open (FILE,"/tmp/prev_config/netcfg_$hostname");
  my $a_network_cfg = <FILE>;
  close(FILE);
  chomp($a_network_cfg);
 
  my $curr_access_if = `ifconfig -a | grep -v lo0 | grep en | cut -f 1 -d : | head -1`;
  chomp($curr_access_if);
 
  my @a_vadapters = `lsdev -Ccadapter | grep "Virtual I/O Ethernet Adapter" | awk {'print \$1'} | grep -v $curr_access_if | sed 's/t//g'`;
  chomp(@a_vadapters);
  foreach $vadapter (@a_vadapters)
  {
    system("ifconfig $vadapter 0 >/dev/null 2>&1");
    system("ifconfig $vadapter detach >/dev/null 2>&1");
  }
 
  my @a_network = split(/,/,$a_network_cfg);
  my $prev_hostname = $a_network[0];
  my $prev_gw = $a_network[1];
  my $previous_access_if = $a_network[2];
  my $prev_acc_ip = $a_network[3];
  my $prev_dns = $a_network[4];
  my $prev_fqdn = $a_network[5];
  my $prev_nmask = $a_network[6];
 
  if($curr_access_if eq $previous_access_if)
  {
    system("chdev -l $curr_access_if -a tcp_sendspace=524288 -a tcp_recvspace=524288 -a mtu_bypass=on -a mtu=9000 -a state=up");
    system("/usr/sbin/mktcpip -h'$prev_hostname' -a'$prev_acc_ip' -m'$prev_nmask' -i '$curr_access_if' -n'$prev_dns' -d'$prev_fqdn' -g'$prev_gw' -A'no' -t'N/A' '-s'");
  }
  else
  {
    system("chdev -l $curr_access_if -a netaddr=' ' -a netmask=' ' -a mtu_bypass=on");
    system("ifconfig $curr_access_if 0");
    system("ifconfig $curr_access_if detach");
    system("chdev -l $previous_access_if -a netmask='$prev_nmask' -a netaddr='$prev_acc_ip' -a tcp_sendspace=524288 -a tcp_recvspace=524288 -a mtu_bypass=on -a mtu=9000 -a state=up");
    system("/usr/sbin/mktcpip -h'$prev_hostname' -a'$prev_acc_ip' -m'$prev_nmask' -i '$previous_access_if' -n'$prev_dns' -d'$prev_fqdn' -g'$prev_gw' -A'no' -t'N/A' '-s'");
  }
}
 
sub ssh_config {
  system("tar xvf /mnt/ssh_$hostname.tar");
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
  open(FILE, "/tmp/prev_config/seacfg_$hostname");
  my @a_seacfg = <FILE>;
  close(FILE);
  chomp(@a_seacfg);
  foreach $sea (@a_seacfg)
  {
    my @a_sea_params = split(/,/,$sea);
    my $ctl_chan = $a_sea_params[0];
    my $pvid_adapter = $a_sea_params[1];
    my $real_adapter = $a_sea_params[2];
    my $virt_adapters = $a_sea_params[3];
    my $pvid = $a_sea_params[4];
    system("/usr/ios/cli/ioscli mkvdev -sea $real_adapter -vadapter $virt_adapters -default $virt_adapters -defaultid $pvid -attr ha_mode=auto ctl_chan=$ctl_chan jumbo_frames=yes large_receive=yes largesend=1 health_time=60");
  }
}

sub mkuser {
  my $unixp = `echo asd | openssl enc -base64 -d`;
  chomp($unixp);
  system("mkuser unix");
  system("echo \"unix:$unixp\" | chpasswd");
  system("pwdadm -c unix");
  system("cp /etc/passwd /etc/passwd.bak; cat /etc/passwd | grep -v unix > /tmp/passwd; echo \"unix:!:0:0::/home/unix:/usr/bin/ksh\" >> /tmp/passwd; cp /tmp/passwd /etc/passwd");
  system("cp /mnt/conf/profile_aix /home/unix/.profile; chown unix /home/unix/.profile; chmod 600 /home/unix/.profile");
  system("mkdir /home/unix/.ssh; cp /mnt/conf/authorized_keys_unx /home/unix/.ssh/authorized_keys");
  system("chown -R unix /home/unix; chmod 400 /home/unix/.ssh/authorized_keys");
}
 
sub fcsmap {
  print "INFO: mapping vfchosts ... \n";
  my $sys_index = substr($hostname,-1);
  chomp($sys_index);
 
  if($sys_index eq "1")
  {
    my @a_fcs = `lspath | grep fscsi | awk {'print \$3'} | sort | uniq | cut -c6-6`;
    my @a_vfc = `/usr/ios/cli/ioscli lsmap -all -npiv | grep vfchost | awk {'print \$1'}`;
    chomp(@a_fcs,@a_vfc);
   
    my $index_max = scalar @a_fcs;
    my $index = 0;
    my $j = 0;
   
    foreach $i (@a_vfc)
    {
      $index = $j;
      my $fcs = $a_fcs[$j];
      system("/usr/ios/cli/ioscli vfcmap -vadapter $i -fcp fcs$fcs");
      $j++;
      if($j ge $index_max)
      {
        $j = 0;
      }
    }
  }
  else
  {
    my @a_fcs = `lspath | grep fscsi | awk {'print \$3'} | sort | uniq | cut -c6-6`;
    my @a_vfc = `/usr/ios/cli/ioscli lsmap -all -npiv | grep vfchost | awk {'print \$1'}`;
    chomp(@a_fcs,@a_vfc);
    @a_fcs = reverse (@a_fcs);
   
    my $index_max = scalar @a_fcs;
    my $index = 0;
    my $j = 0;
   
    foreach $i (@a_vfc)
    {
      $index = $j;
      my $fcs = $a_fcs[$j];
      system("/usr/ios/cli/ioscli vfcmap -vadapter $i -fcp fcs$fcs");
      $j++;
      if($j ge $index_max)
      {
        $j = 0;
      }
    }
  }
}
 
sub lpar2rrd {
  system("mkdir -p /tmp/update");
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
  system("mount -o soft is0110:/sapmnt/is0110/a/firmware/$model /mnt");
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
  system("mkdir /tmp/update; mount -o soft 10.66.140.27:/sapmnt/is0110/a/vios/VIOS_2.2.5.20 /tmp/update");
  system("install_all_updates -d /tmp/update -c -Y");
  system("installp -c all >/dev/null 2>&1");
  system("cd /; umount -f /tmp/update");
  system("mount -o soft 10.66.140.27:/sapmnt/is0110/a/misc/sddpcm2700_vios /tmp/update");
  system("install_all_updates -cY -d /tmp/update all");
  system("cd /; umount -f /tmp/update");
  system("installp -c all >/dev/null 2>&1");
}

sub ifix_install {
  system("mount -o soft is0110:/sapmnt/is0110/a/vios/22520_fixes /mnt");
  my @a_ifixes = `ls /mnt`;
  chomp(@a_ifixes);
  foreach my $fix (@a_ifixes)
  {
    system("emgr -e /mnt/$fix");
  }
  system("umount -f /mnt");
}

sub syslog_setup {
  system("mount -o soft is0124:/export/install/cfg /mnt");
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
 
&mount_repo;
&chfs;
&copy_files_locally;
&network_tunables;
&network_buffers;
&phys_adapter_tuning;
&mtu_bypass_vadapters;
&fscsi_tuning;
&fcs_tuning;
&access_if;
&roce_config;
&sea_config;
&ssh_config;
&mkuser;
&fcsmap;
&lpar2rrd;
&fscsi_autoconfig;
&microcode;
&sys_update;
&ifix_install;
&syslog_setup;
