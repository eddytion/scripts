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

sub sys_update {
  system("installp -c all >/dev/null 2>&1");
  system("mkdir /tmp/update; mount -o soft 10.66.140.27:/sapmnt/is0110/a/vios/VIOS_2.2.5.10 /tmp/update");
  system("install_all_updates -d /tmp/update -c -Y");
  system("installp -c all >/dev/null 2>&1");
  system("installp -aYXF -d /tmp/update bos.esagent 6.6.9.100");
  system("install_all_updates -d /tmp/update -cY");
  system("cd /; umount -f /tmp/update");
  system("mount -o soft 10.66.140.27:/sapmnt/is0110/a/misc/sddpcm2690 /tmp/update");
  system("install_all_updates -cY -d /tmp/update all");
  system("cd /; umount -f /tmp/update");
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

sub mtu_bypass_vadapters {
  my @a_vadapters = `lsdev -Ccadapter | grep "Virtual I/O Ethernet Adapter" | awk {'print \$1'} | sed 's/t//g'`;
  chomp(@a_vadapters);
  foreach $vadapter (@a_vadapters)
  {
    system("chdev -l $vadapter -a mtu_bypass=on -P");
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

sub sea_tuning {
  my @a_sea=`lsdev -Ccadapter | grep \"Shared Ethernet Adapter\" | awk {'print \$1'} | sort`;
  chomp(@a_sea);
  foreach my $sea (@a_sea)
  {
    system("chdev -l $sea -a jumbo_frames=yes -a large_receive=yes -a largesend=1 -a health_time=60 -P");
  }
}

sub access_if { 
  my $curr_access_if = `netstat -nr | grep default | awk {'print \$6'}`;
  chomp($curr_access_if);
  system("chdev -l $curr_access_if -a tcp_sendspace=524288 -a tcp_recvspace=524288 -a mtu_bypass=on -a mtu=9000 -a state=up -P");
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

sub lpar2rrd {
 system("mount 10.76.177.146:/srv/exports /tmp/update");
 system("rpm -Uvh /tmp/update/lpar2rrd-agent-4.95-4.aix5.1.ppc.rpm");
 system("crontab -l > /tmp/crontab_lpar2rrd");
 system("echo \"#LPAR2RRD Entries\" >> /tmp/crontab_lpar2rrd");
 system("echo \"00 00 * * * LANG=C; export LANG; /usr/bin/nmon -O -^ -f -t -D -E -s60 -c1440 -m'/home/lpar2rrd'\" >> /tmp/crontab_lpar2rrd");
 system("echo \"0 1 * * * find /home/lpar2rrd -type f -name \"*nmon*\" -mtime +7 -exec rm -f {} \;\" >> /tmp/crontab_lpar2rrd");
 system("echo \"0,30 * * * * /usr/bin/perl /opt/lpar2rrd-agent/lpar2rrd-agent.pl -n /home/lpar2rrd lsh35350rh.wdf.sap.corp > /var/tmp/lpar2rrd-agent-nmon.out 2>&1\" >> /tmp/crontab_lpar2rrd");
 system("cp /tmp/crontab_lpar2rrd /var/spool/cron/crontabs/root; crontab /var/spool/cron/crontabs/root");
 system("mkdir -p /home/lpar2rrd");
 system("cd /; umount -f /tmp/update");
}

&sys_update;
&network_tunables;
&network_buffers;
&mtu_bypass_vadapters;
&phys_adapter_tuning;
&sea_tuning;
&access_if;
&fcs_tuning;
&lpar2rrd;
