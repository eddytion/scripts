#!/usr/bin/perl

use strict;

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

my $pass = `echo pass | base64 -d | base64 -d`;
chomp($pass);

if ($#ARGV != 1) 
{
  crit_logging("missing input parameters or too many params");
  exit(1);
}

my $server;
my $srv = $ARGV[0];
my $action = $ARGV[1];

if($action eq "reboot_os")
{
  if($srv =~ m/lsh/)
  {
    my $dns = `nslookup $srv >/dev/null 2>&1`;
    chomp($dns);
    if($? == 0)
    {
      $server = $srv;
    }
    else
    {
      my $temp_serv = $srv."le";
      my $dns_le = `nslookup $temp_serv >/dev/null 2>&1`;
      chomp($dns_le);
      if($? == 0)
      {
        $server = $srv."le";
      }
      else
      {
        $server = $srv."rh";
      }
    }
  }
  else
  {
    $server = $srv;
  }
  reboot_os($server);
}
elsif($action eq "reboot_hmc")
{
  $server = $srv;
  reboot_hmc($server);
}

sub reboot_os {
  my $server = shift;
  logging("Server to be rebooted is $server");
  my $os = `sshpass -p $pass ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q -l unix $server "uname"`;
  chomp($os);
  logging("OS type for $server is $os");
  
  if($os eq "Linux")
  {
    #my $cmd = "reboot";
    my $cmd = "uptime";
    logging("Sending reboot command to $server ...");
    system("timeout 5 sshpass -p $pass ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q -l unix $server \"$cmd\"");
    logging("Done");
  }
  elsif($os eq "AIX")
  {
    logging("Sending reboot command to $server ...");
    my $cmd = "shutdown -Fr";
    system("timeout 5 sshpass -p $pass ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q -l unix $server \"$cmd\"");
    logging("Done");
  }
}

sub reboot_hmc {
  my $server = shift;
  my $db_name = "websles";
  my $db_user = "root";
  my $db_table = "phys_sys";
  my $db_pass = "nXEzT0Ae0k9RJTM";
  
  logging("Server to be rebooted is $server");
  my $hmc = `mysql -sN -u $db_user -p$db_pass -e \"use $db_name; select hmc_name from $db_table where lpar_name='$server' limit 0,1\"`;
  chomp($hmc);
  logging("Server $server is managed by HMC: $hmc");
  my $ms_name = `mysql -sN -u $db_user -p$db_pass -e \"use $db_name; select ms_name from $db_table where lpar_name='$server' limit 0,1\"`;
  chomp($ms_name);
  logging("Server $server is hosted on $ms_name");
  my $cmd = "chsysstate -o shutdown -r lpar --immed --restart -m $ms_name -n $server";
  logging("Command to be sent to $hmc: $cmd");
  logging("Connecting to $hmc and sending command for reboot");
  system("ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q -l unix $hmc \"$cmd\"");
  logging("Done");
}
