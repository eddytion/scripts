#!/usr/bin/perl

system("clear");

# Legenda
# a_ ... array
# h_ ... hash
# s_ ... string
# i_ ... integer
# r_ ... reference

my $file = '/tmp/vios_pre.log';
unlink($file) if -e $file;
my $hostname = `uname -n`;
chomp($hostname);

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

sub mount_repo {
  my $host = `uname -n`;
  chomp($host);
  
  system("nfso -p -o nfs_use_reserved_ports=1; mount -o soft lsh35303.wdf.sap.corp:/viosconfig /mnt");
  if($? == 0)
  {
    ok_logging("NFS repo has been successfully mounted");
  }
  else
  {
    crit_logging("NFS repo could not be mounted, aborting ...");
    exit(1);
  }
  
  system("touch /mnt/test_$host; rm /mnt/test_$host");
  if($? == 0)
  {
    ok_logging("NFS repo is writable");
  }
  else
  {
    crit_logging("NFS repo is not writable, aborting");
    exit(1);
  }
}

sub save_sea {
  if(-e "/mnt/seacfg_$hostname")
  {
    unlink("/mnt/seacfg_$hostname");
  }
  
  my @a_sea=`lsdev -Ccadapter | grep \"Shared Ethernet Adapter\" | awk {'print \$1'}`;
  chomp(@a_sea);
  my $pvid = 10;
  foreach my $sea (@a_sea)
  {
    my $ctl_chan = `lsattr -El $sea | grep -w ctl_chan | awk {'print \$2'}`;
    my $pvid_adapter = `lsattr -El $sea | grep -w pvid_adapter | awk {'print \$2'}`;
    my $real_adapter = `lsattr -El $sea | grep -w real_adapter | awk {'print \$2'}`;
    my $virt_adapter = `lsattr -El $sea | grep -w virt_adapters | awk {'print \$2'}`;
    chomp($ctl_chan,$pvid_adapter,$real_adapter,$virt_adapter);
    
    open(FILE, ">> /mnt/seacfg_$hostname");
    print FILE "$ctl_chan,$pvid_adapter,$real_adapter,$virt_adapter,$pvid\n";
    close(FILE);
    $pvid = $pvid+10;
  }
}

sub save_fc_map {
  system("/usr/ios/cli/ioscli lsmap -all -npiv -field \"FC name\" Name -fmt , > /mnt/fcmap_$hostname");
  system("/usr/ios/cli/ioscli lsmap -all -field vtd svsa -fmt , > /mnt/scsimap_$hostname");
}

sub save_ssh_config {
  system("tar cvf /mnt/ssh_$hostname.tar /etc/ssh/* >/dev/null 2>&1");
}

sub save_network {
  my $gw = `netstat -nr | grep default | awk {'print \$2'}`;
  my $access_if = `netstat -nr | grep default | awk {'print \$6'}`;
  chomp($access_if);
  my $ip_addr = `host $hostname | awk {'print \$3'}`;
  my $dns = "10.17.121.30";
  my $fqdn = "wdf.sap.corp";
  my $netmask = `ifconfig $access_if | grep netmask | awk {'print \$4'} | sed 's/0x//g'`;
  chomp($gw,$access_if,$ip_addr,$dns,$fqdn,$netmask);
  
  my $netmask_decimal = convert_nmask($netmask);
  
  open(FILE,"> /mnt/netcfg_$hostname");
  print FILE "$hostname,$gw,$access_if,$ip_addr,$dns,$fqdn,$netmask_decimal\n";
  close(FILE);
}

&mount_repo;
&save_sea;
&save_fc_map;
&save_ssh_config;
&save_network;
