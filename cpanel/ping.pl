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

if ($#ARGV != 0) 
{
  crit_logging("missing input parameters or too many params");
  exit(1);
}

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

sub ping {
  my $server = shift;
  system("ping -c 2 $server");
}

&ping($server);
