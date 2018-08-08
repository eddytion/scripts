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

my $action = $ARGV[0];

sub errpt {
  my $os = `uname`;
  chomp($os);
  if($os eq "AIX")
  {
    my @a_result = `errpt | head -20`;
    chomp(@a_result);
    foreach my $line (@a_result)
    {
      print "$line \n";
    }
  }
  else
  {
    warn_logging("Command is valid only for AIX");
  }
}

sub diskusage {
  my $os = `uname`;
  chomp($os);
  if($os eq "AIX")
  {
    my @a_result = `df -g`;
    chomp(@a_result);
    foreach my $line (@a_result)
    {
      print "$line \n";
    }
  }
  elsif($os eq "Linux")
  {
    my @a_result = `df -h`;
    chomp(@a_result);
    foreach my $line (@a_result)
    {
      print "$line \n";
    }
  }
  else
  {
    warn_logging("Unsupported OS");
  }
}

sub show_disks {
  my $os = `uname`;
  chomp($os);
  if($os eq "Linux")
  {
    my @a_result = `lsblk --nodeps -o NAME,SIZE -n| sed -r -e 's/\\s+/,/g'`;
    chomp(@a_result);
    foreach my $line (@a_result)
    {
      my @params = split(/,/,$line);
      chomp(@params);
      print "Disk Name: $params[0]\tDisk Size: $params[1]\n";
    }
  }
  elsif($os eq "AIX")
  {
    print "Disk Name:\t Disk Size: (GB) \n";
    my @a_result = `lspv | grep hdisk | awk {'print \$1'}`;
    chomp(@a_result);
    foreach my $disk (@a_result)
    {
      my $size=`bootinfo -s $disk`;
      chomp($size);
      my $size_f = ($size/1024);
      print "$disk\t\t$size_f\n";
    }
  }
}

sub listpkgs {
  my $os = `uname`;
  chomp($os);
  if($os eq "Linux")
  {
    my @a_result = `rpm -qa --qf '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH} %{VENDOR}\n'`;
    chomp(@a_result);
    foreach my $line (@a_result)
    {
     print "$line \n";
    }
  }
  elsif($os eq "AIX")
  {
    my @a_result = `lslpp -Lc`;
    chomp(@a_result);
    foreach my $line (@a_result)
    {
     print "$line \n";
    }
  }
}

if($action eq "errpt")
{
  errpt;
}
elsif($action eq "diskusage")
{
  diskusage;
}
elsif($action eq "show_disks")
{
  show_disks;
}
elsif($action eq "listpkgs")
{
  listpkgs;
}
