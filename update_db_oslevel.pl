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

sub get_dns {
  my $lpar = shift;
  system("nslookup $lpar >/dev/null 2>&1");
  if($? == 0)
  {
    $hostname = $lpar;
  }
  else
  {
    $hostname = $lpar . "le";
  }
}

sub get_lpar_from_db {
  unlink("/tmp/lparlist.out") if -e "/tmp/lparlist.out";
  system("mysql -u root -pnXEzT0Ae0k9RJTM -e \"use sap; SELECT lparname FROM lpar_ms WHERE lparname LIKE 'lsh%' or lparname LIKE 'is%'\" > /tmp/lparlist.out");
  system("sed -i '/lparname/d' /tmp/lparlist.out");
}

sub get_data {
  my @a_hosts = `cat /tmp/lparlist.out`;
  chomp(@a_hosts);
  unlink("/tmp/oslevel_report.sql") if -e "/tmp/oslevel_report.sql";
  open(FILE, ">> /tmp/oslevel_report.sql");
  foreach $hostname (@a_hosts)
  {
    $host = get_dns($hostname);
    my $uname = `sshpass -p password ssh -o ConnectTimeout=1 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q -l unix $host \"uname\"`;
    chomp($uname);
    if($uname eq "AIX")
    {
      my $oslevel = `sshpass -p password ssh -o ConnectTimeout=1 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q -l unix $host \"oslevel -s\"`;
      chomp($oslevel);
      print FILE "UPDATE lpar_ms SET lparos='$uname,$oslevel' WHERE lparname='$host';\n";
    }
    elsif($uname eq "Linux")
    {
      my $oslevel = `sshpass -p password ssh -o ConnectTimeout=1 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q -l unix $host \"cat /etc/os-release | grep -w PRETTY_NAME | cut -f 2 -d =\"`;
      chomp($oslevel);
      print FILE "UPDATE lpar_ms SET lparos='$uname,$oslevel' WHERE lparname='$host';\n";
    }
    else
    {
      unkn_logging("$uname not supported");
    }
  }
  close(FILE);
}

&get_lpar_from_db;
&get_data;
