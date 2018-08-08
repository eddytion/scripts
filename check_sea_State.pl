#!/usr/bin/env perl

use strict;

# Naming convention for variables
# a_ ... array
# h_ ... hash
# s_ ... string
# i_ ... integer
# r_ ... reference

# Check OS type

my $OS=`uname`;
chomp($OS);
my @a_sea_rc;
    
if ($OS ne "AIX")
{
  unkn_logging("This must be run only on AIX");
}

# Logging functions --> General, OK, WARN, CRIT, UNKN

sub logging {
  my $timestamp=localtime(time);
  my ($msg) = @_;
  print "INFO: $msg \n";
}

sub ok_logging {
  my $timestamp=localtime(time);
  my ($msg) = @_;
  print "OK: $timestamp \t $msg \n";
  exit(0);
}

sub warn_logging {
  my $timestamp=localtime(time);
  my ($msg) = @_;
  print "WARN: $timestamp \t $msg \n";
  exit(1);
}

sub crit_logging {
  my $timestamp=localtime(time);
  my ($msg) = @_;
  print "CRIT: $timestamp \t $msg \n";
  exit(2);
}

sub unkn_logging {
  my $timestamp=localtime(time);
  my ($msg) = @_;
  print "UNKNOWN: $timestamp \t $msg \n";
  exit(3);
}

sub check_sea {
  my @a_sea = `/usr/sbin/lsdev -Ccadapter | grep -w "Shared Ethernet Adapter" | awk {'print \$1'}`;
  chomp(@a_sea);
  foreach my $sea (@a_sea)
  {
    my $test = `entstat -d $sea 2>/dev/null | grep -w \"Physical Port Link Status\" >/dev/null 2>&1`;
    if($? == 0)
    {
      my $phys_port=`/usr/bin/entstat -d $sea 2>/dev/null | grep -w \"Physical Port Link Status\" | cut -f 2 -d : | sed 's/ //g'`;
      my $logical_port=`/usr/bin/entstat -d $sea 2>/dev/null | grep -w "Logical Port Link Status" | cut -f 2 -d : | sed 's/ //g'`;
      chomp($phys_port,$logical_port);
      if($phys_port ne "Up" || $logical_port ne "Up")
      {
	push(@a_sea_rc,"$sea,CRIT");
      }
      else
      {
	push(@a_sea_rc,"$sea,OK");
      }
    }
    else
    {
      my $phys_port=`/usr/bin/entstat -d $sea 2>/dev/null | grep -w \"Link Status\" | cut -f 2 -d : | sed 's/ //g'`;
      chomp($phys_port);
      if($phys_port ne "Up")
      {
	push(@a_sea_rc,"$sea,CRIT");
      }
      else
      {
	push(@a_sea_rc,"$sea,OK");
      }
    }
  }
}

sub results {
  my @a_result_crit;
  my @a_result_ok;
  
  foreach my $result (@a_sea_rc)
  {
    my @a_sea = split(/\,/,$result);
    if($result =~ m/CRIT/)
    {
      push(@a_result_crit,$a_sea[0]);
    }
    else
    {
      push(@a_result_ok,$a_sea[0]);
    }
  }
  
  if(scalar @a_result_crit)
  {
    crit_logging("There are issues with " . join(",",@a_result_crit));
  }
  else
  {
    ok_logging("Status ok for " . join(",",@a_result_ok));
  }
}

&check_sea;
&results;
