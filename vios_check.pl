#!/usr/bin/perl

system("clear");

# Legenda
# a_ ... array
# h_ ... hash
# s_ ... string
# i_ ... integer
# r_ ... reference

my $file = '/tmp/vios_setup.log';
unlink($file) if -e $file;

# Logging functions --> General, OK, WARN, CRIT, UNKN

sub logging {
  my ($msg) = @_;
  print "INFO: $msg \n";
  open(FILE, ">> $file");
  print FILE "INFO:\t$msg \n";
  close(FILE);
}

sub ok_logging {
  my ($msg) = @_;
  print "OK:\t $msg \n";
  open(FILE, ">> $file");
  print FILE "OK:\t$msg \n";
  close(FILE);
}

sub warn_logging {
  my ($msg) = @_;
  print "WARN:\t $msg \n";
  open(FILE, ">> $file");
  print FILE "WARN:\t$msg \n";
  close(FILE);
}

sub crit_logging {
  my ($msg) = @_;
  print "CRIT:\t $msg \n";
  open(FILE, ">> $file");
  print FILE "CRIT:\t$msg \n";
  close(FILE);
}

sub unkn_logging {
  my ($msg) = @_;
  print "UNKNOWN:\t $msg \n";
  open(FILE, ">> $file");
  print FILE "UNKNOWN:\t$msg \n";
  close(FILE);
}

#Start checks
my $who = `whoami`;
chomp($who);

if($who ne "root")
{
  crit_logging("This script must be run as root");
  exit(1);
}

system("lslpp -l ios.sea >/dev/null 2>&1");
if($? != 0)
{
  crit_logging("This script must be run on a VIO server");
  exit(1);
}

sub check_ioslevel {
  my $ioslevel=`/usr/ios/cli/ioscli ioslevel`;
  chomp($ioslevel);
  if($ioslevel eq "2.2.4.23" || $ioslevel eq "2.2.5.10" || $ioslevel eq "2.2.5.20")
  {
   ok_logging("Ioslevel is $ioslevel"); 
  }
  else
  {
    warn_logging("Ioslevel is not 2.2.4.23 / 2.2.5.10 but $ioslevel");
  }
}

sub check_lppchk {
  system("lppchk -vm3 >/dev/null 2>&1");
  if($? != 0)
  {
    warn_logging("lppchk command returned some errors, please check");
  }
  else
  {
    ok_logging("lppchk command returned ok");
  }
}

sub check_network_tunables {
  my $rfc1323 = `no -o rfc1323 | awk {'print \$3'}`;
  my $tcp_sendspace = `no -o tcp_sendspace | awk {'print \$3'}`;
  my $tcp_recvspace = `no -o tcp_recvspace | awk {'print \$3'}`;
  my $tcp_nodelayack = `no -o tcp_nodelayack | awk {'print \$3'}`;
  my $sack = `no -o sack | awk {'print \$3'}`;
  my $vioslpm0 = `lsattr -El vioslpm0 | grep -w auto_tunnel | awk {'print \$2'}`; 
  my $udp_sendspace = `no -o udp_sendspace | awk {'print \$3'}`;
  my $udp_recvspace = `no -o udp_recvspace | awk {'print \$3'}`;
  chomp($rfc1323,$tcp_sendspace,$tcp_recvspace,$tcp_nodelayack,$sack,$vioslpm0,$udp_recvspace,$udp_sendspace);
  
  if($rfc1323 eq "1")
  {
    ok_logging("TCP window scaling is activated");
  }
  else
  {
    warn_logging("TCP window scaling is not activated");
  }
  
  if($tcp_sendspace >= "262144")
  {
    ok_logging("TCP Sendspace is set to $tcp_sendspace");
  }
  else
  {
    warn_logging("TCP Sendspace is set to $tcp_sendspace, instead of 262144");
  }
  
  if($tcp_recvspace >= "262144")
  {
    ok_logging("TCP Receive space is set to $tcp_recvspace");
  }
  else
  {
    warn_logging("TCP Receive space is set to $tcp_recvspace, instead of 262144");
  }
  
  if($tcp_nodelayack eq "1")
  {
    ok_logging("TCP no delay ack is active");
  }
  else
  {
    warn_logging("TCP no delay ack is not active");
  }
  
  if($sack eq "1")
  {
    ok_logging("TCP Selective ack is active");
  }
  else
  {
    warn_logging("TCP Selective ack is not active");
  }
  
  if($vioslpm0 eq "0")
  {
    ok_logging("VIO lpm0 auto tunnel encryption is disabled");
  }
  else
  {
    warn_logging("VIO lpm0 auto tunnel encryption is not disabled");
  }
  
  if($udp_sendspace >= "65536")
  {
    ok_logging("UDP Send space is set to $udp_sendspace");
  }
  else
  {
    warn_logging("UDP Send space is not set to 65536 but to $udp_sendspace");
  }
  
  if($udp_recvspace >= "655360")
  {
    ok_logging("UDP receive space is set to $udp_recvspace");
  }
  else
  {
    warn_logging("UDP receive space is not set to 655360 but to $udp_recvspace");
  }
}

sub check_sea {
  my @a_sea=`lsdev -Ccadapter | grep \"Shared Ethernet Adapter\" | awk {'print \$1'}`;
  chomp(@a_sea);
  foreach my $sea (@a_sea)
  {
    my $largesend = `lsattr -El $sea | grep -w largesend | awk {'print \$2'}`;
    my $large_receive = `lsattr -El $sea | grep -w large_receive| awk {'print \$2'}`;
    my $jumbo_frames = `lsattr -El $sea | grep -w jumbo_frames| awk {'print \$2'}`;
    chomp($largesend,$large_receive,$jumbo_frames);
    
    if($largesend eq "1")
    {
      ok_logging("$sea has largesend activated");
    }
    else
    {
      warn_logging("$sea does not have largesend activated");
    }
    
    if($large_receive eq "yes")
    {
      ok_logging("$sea has large_receive activated");
    }
    else
    {
      warn_logging("$sea does not have large_receive activated");
    }
    
    if($jumbo_frames eq "yes")
    {
      ok_logging("$sea has jumbo_frames activated");
    }
    else
    {
      warn_logging("$sea does not have jumbo_frames activated");
    }
  }
}

sub check_virtual_adapters {
  my @a_virt_adapt_parent = `lsdev -Ccadapter | grep "Virtual I/O Ethernet Adapter" | awk {'print \$1'}`;
  chomp(@a_virt_adapt_parent);
  foreach my $vadapter (@a_virt_adapt_parent)
  {
    my $max_buf_small = `lsattr -El $vadapter | grep -w max_buf_small | awk {'print \$2'}`;
    my $min_buf_small = `lsattr -El $vadapter | grep -w min_buf_small | awk {'print \$2'}`;
    my $min_buf_medium = `lsattr -El $vadapter | grep -w min_buf_medium | awk {'print \$2'}`;
    my $max_buf_medium = `lsattr -El $vadapter | grep -w max_buf_medium | awk {'print \$2'}`;
    my $min_buf_large = `lsattr -El $vadapter | grep -w min_buf_large | awk {'print \$2'}`;
    my $max_buf_large = `lsattr -El $vadapter | grep -w max_buf_large | awk {'print \$2'}`;
    my $min_buf_huge = `lsattr -El $vadapter | grep -w min_buf_huge | awk {'print \$2'}`;
    my $max_buf_huge = `lsattr -El $vadapter | grep -w max_buf_huge | awk {'print \$2'}`;
    my $min_buf_tiny = `lsattr -El $vadapter | grep -w min_buf_tiny | awk {'print \$2'}`;
    my $max_buf_tiny = `lsattr -El $vadapter | grep -w max_buf_tiny | awk {'print \$2'}`;
    chomp($max_buf_small,$min_buf_small,$min_buf_medium,$max_buf_medium,$min_buf_large,$max_buf_large,$min_buf_huge,$max_buf_huge,$min_buf_tiny,$max_buf_tiny);
    
    if($max_buf_small eq "4096")
    {
      ok_logging("$vadapter has max_buf_small set to $max_buf_small");
    }
    else
    {
      warn_logging("$vadapter has max_buf_small set to $max_buf_small");
    }
    
    if($min_buf_small eq "4096")
    {
      ok_logging("$vadapter has min_buf_small set to $min_buf_small");
    }
    else
    {
      warn_logging("$vadapter has min_buf_small set to $min_buf_small");
    }
    
    if($min_buf_medium eq "512")
    {
      ok_logging("$vadapter has min_buf_medium set to $min_buf_medium");
    }
    else
    {
      warn_logging("$vadapter has min_buf_medium set to $min_buf_medium");
    }
    
    if($max_buf_medium eq "1024")
    {
      ok_logging("$vadapter has max_buf_medium set to $max_buf_medium");
    }
    else
    {
      warn_logging("$vadapter has max_buf_medium set to $max_buf_medium");
    }
    
    if($min_buf_large eq "96")
    {
      ok_logging("$vadapter has min_buf_large set to $min_buf_large");
    }
    else
    {
      warn_logging("$vadapter has min_buf_large set to $min_buf_large");
    }
    
    if($max_buf_large eq "256")
    {
      ok_logging("$vadapter has max_buf_large set to $max_buf_large");
    }
    else
    {
      warn_logging("$vadapter has max_buf_large set to $max_buf_large");
    }
    
    if($min_buf_huge eq "96")
    {
      ok_logging("$vadapter has min_buf_huge set to $min_buf_huge");
    }
    else
    {
      warn_logging("$vadapter has min_buf_huge set to $min_buf_huge");
    }
    
    if($max_buf_huge eq "128")
    {
      ok_logging("$vadapter has max_buf_huge set to $max_buf_huge");
    }
    else
    {
      warn_logging("$vadapter has max_buf_huge set to $max_buf_huge");
    }
    
    if($min_buf_tiny eq "4096")
    {
      ok_logging("$vadapter has min_buf_tiny set to $min_buf_tiny");
    }
    else
    {
      warn_logging("$vadapter has min_buf_tiny set to $min_buf_tiny");
    }
    
    if($max_buf_tiny eq "4096")
    {
      ok_logging("$vadapter has max_buf_tiny set to $max_buf_tiny");
    }
    else
    {
      warn_logging("$vadapter has max_buf_tiny set to $max_buf_tiny");
    }
  }
  
  my @a_virt_adapt_child = `lsdev -Ccadapter | grep "Virtual I/O Ethernet Adapter" | awk {'print \$1'} | sed 's/t//g'`;
  chomp(@a_virt_adapt_child);
  
  foreach $child (@a_virt_adapt_child)
  {
    my $mtu_bypass = `lsattr -El $child | grep -w mtu_bypass | awk {'print \$2'}`;
    chomp($mtu_bypass);
    if($mtu_bypass eq "on")
    {
      ok_logging("$child has mtu_bypass activated");
    }
    else
    {
      warn_logging("$child does not have mtu_bypass activated");
    }
  }
}

sub check_fscsi {
  my @a_fscsi=`lsdev | grep fscsi | awk {'print \$1'}`;
  chomp(@a_fscsi);
  foreach my $fscsi (@a_fscsi)
  {
    my $fast_fail = `lsattr -El $fscsi | grep -w fc_err_recov | awk {'print \$2'}`;
    my $dyntrk = `lsattr -El $fscsi | grep -w dyntrk | awk {'print \$2'}`;
    chomp($fast_fail,$dyntrk);
    
    if($fast_fail eq "fast_fail")
    {
      ok_logging("$fscsi has fast fail activated");
    }
    else
    {
      warn_logging("$fscsi does not have fast fail activated");
    }
    
    if($dyntrk eq "yes")
    {
      ok_logging("$fscsi has dynamic tracking activated");
    }
    else
    {
      warn_logging("$fscsi does not have dynamic tracking activated");
    }
  }
}

sub check_real_ent_adapter {
  my @a_real_ent = `lsdev -Ccadapter | grep ent | egrep -v "Virtual I/O Ethernet Adapter|Shared Ethernet Adapter" | awk {'print \$1'}`;
  chomp(@a_real_ent);
  foreach my $ent (@a_real_ent)
  {
    my $chksum_offload = `lsattr -El $ent | grep -w chksum_offload | awk {'print \$2'}`;
    my $flow_ctrl = `lsattr -El $ent | egrep -w "flow_ctrl|flow_control" | awk {'print \$2'}`;
    chomp($chksum_offload,$flow_ctrl);
    
    if($chksum_offload eq "yes")
    {
      ok_logging("$ent has checksum offload activated");
    }
    else
    {
      warn_logging("$ent does not have checksum offload activated");
    }
    
    if($flow_ctrl eq "yes")
    {
      ok_logging("$ent has flow control activated");
    }
    else
    {
      warn_logging("$ent does not have flow control activated");
    }
  }
}

sub check_nfso {
  my $nfso = `nfso -o nfs_use_reserved_ports | awk {'print \$3'}`;
  chomp($nfso);
  if($nfso eq "1")
  {
    ok_logging("NFS use reserved ports is activated");
  }
  else
  {
    warn_logging("NFS use reserved ports is not activated");
  }
}

sub check_sddpcm {
  system("lslpp -l devices.sddpcm.61.rte >/dev/null 2>&1");
  if($? == 0)
  {
    ok_logging("SDDPCM is installed");
  }
  else
  {
    warn_logging("SDDPCM is not installed");
  }
}

sub check_access_if {
  my $acc_nic = `netstat -nr | grep -w default | awk {'print \$6'}`;
  chomp($acc_nic);
  my $acc_nic_tcpsendspace = `lsattr -El $acc_nic | grep -w tcp_sendspace | awk {'print \$2'}`;
  my $acc_nic_tcprecvspace = `lsattr -El $acc_nic | grep -w tcp_recvspace | awk {'print \$2'}`;
  my $acc_mtu = `lsattr -El $acc_nic | grep -w mtu | awk {'print \$2'} `;
  chomp($acc_nic_tcprecvspace,$acc_nic_tcpsendspace,$acc_mtu);
  
  if($acc_mtu eq "9000")
  {
    ok_logging("$acc_nic has mtu set to $acc_mtu");
  }
  else
  {
    warn_logging("$acc_nic does not have mtu set to 9000");
  }
  
  if($acc_nic_tcprecvspace eq "524288")
  {
    ok_logging("$acc_nic has TCP receive space set to $acc_nic_tcprecvspace");
  }
  else
  {
    warn_logging("$acc_nic does not have TCP receive space set to 524288");
  }
  
  if($acc_nic_tcpsendspace eq "524288")
  {
    ok_logging("$acc_nic has TCP send space set to $acc_nic_tcpsendspace");
  }
  else
  {
    warn_logging("$acc_nic does not have TCP send space set to 524288");
  }
}

sub check_bteam {
  system("id bteam >/dev/null 2>&1");
  if($? == 0)
  {
    ok_logging("bteam user has been created");
  }
  else
  {
    crit_logging("bteam user is missing");
  }
}

sub check_sea_health_time {	
  my $ioslevel=`/usr/ios/cli/ioscli ioslevel`;
  chomp($ioslevel);
  
  if($ioslevel eq "2.2.5.10")
  {
    my @a_sea_adapters = `lsdev -Ccadapter | grep \"Shared Ethernet Adapter\" | awk {'print \$1'}`;
    chomp(@a_sea_adapters);
    foreach $adapter (@a_sea_adapters)
    {
      my $htime = `lsattr -El $adapter | grep -w health_time | awk {'print \$2'}`;
      chomp($htime);
      if($htime eq "60")
      {
	ok_logging("SEA $adapter has health_time set to $htime");
      }
      else
      {
	warn_logging("SEA $adapter does not have health_time set to 60");
      }
    }
  }
}

sub check_xfer_size {
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
      warn_logging("$fcs does not have max_xfer_size set to 0x400000");
    }
  }
}

&check_ioslevel;
&check_lppchk;
&check_network_tunables;
&check_sea;
&check_virtual_adapters;
&check_fscsi;
&check_real_ent_adapter;
&check_nfso;
&check_sddpcm;
&check_access_if;
&check_bteam;
&check_sea_health_time;
&check_xfer_size;
