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

if ($#ARGV != 1)
{
  crit_logging("missing input parameters or too many params");
  exit(1);
}

my $action = $ARGV[1];
my $server;
my $srv = $ARGV[0];

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

my $pass = `echo "VG1saFpXRnBiQzRLCg==" | base64 -d | base64 -d`;
chomp($pass);

my @a_result = `timeout 5 sshpass -p $pass ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q -l unix $server 'perl - $action' < /srv/scripts/cpanel/main.pl`;
chomp(@a_result);
if(scalar @a_result)
{
  foreach my $line (@a_result)
  {
    print "$line \n";
  }
}
else
{
  warn_logging("<font color=\"red\"><b>An error has occured, most probably remote command timed out due to some issue with the target host. eg: if you re trying to run \"df\" command and some NFS is hanging, you will not get any results.</b></font>");
}
