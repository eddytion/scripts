#!/usr/bin/env perl

use strict;

# Naming convention for variables
# a_ ... array
# h_ ... hash
# s_ ... string
# i_ ... integer
# r_ ... reference

# Clear screen

system("clear");

# Check OS type

my $OS=`uname`;
chomp($OS);
    
if ($OS ne "AIX")
{
  unkn_logging("This must be run only on AIX or VIOS");
  exit(3);
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
}

sub warn_logging {
  my $timestamp=localtime(time);
  my ($msg) = @_;
  print "WARN: $timestamp \t $msg \n";
}

sub crit_logging {
  my $timestamp=localtime(time);
  my ($msg) = @_;
  print "CRIT: $timestamp \t $msg \n";
}

sub unkn_logging {
  my $timestamp=localtime(time);
  my ($msg) = @_;
  print "UNKNOWN: $timestamp \t $msg \n";
}


# AIX part

sub aix_tunning {
  system("no -p -o rfc1323=1");
  system("no -p -o tcp_recvspace=262144 -o tcp_sendspace=262144");
  system("no -p -o tcp_nodelayack=1");
  system("no -p -o sack=1");
  system("no -p -o udp_sendspace=65536");
  system("no -p -o udp_recvspace=655360");
  logging("General TCP/IP parameters applied");
  
  my @a_vadapters = `lsdev -Ccadapter | grep -i "Virtual I/O Ethernet Adapter" | awk {'print \$1'}`;
  chomp(@a_vadapters);
  if(scalar @a_vadapters)
  {
    foreach my $vadapter (@a_vadapters)
    {
      system("chdev -l $vadapter -a max_buf_small=4096 -a min_buf_small=4096 -a min_buf_medium=512 -a max_buf_medium=1024 -a min_buf_large=96 -a max_buf_large=256 -a min_buf_huge=96 -a max_buf_huge=128 -a min_buf_tiny=4096 -a max_buf_tiny=4096 -P");
      logging("$vadapter parameters applied");
    }
  }
  else
  {
    warn_logging("No virtual adapters found, skipping");
  }
  
  my @a_vadapters2 = `lsdev -Ccadapter | grep "Virtual I/O Ethernet Adapter" | awk {'print \$1'} | sed 's/t//g'`;
  chomp(@a_vadapters2);
  if(scalar @a_vadapters2)
  {
    foreach my $vadapter2 (@a_vadapters2)
    {
      system("chdev -l $vadapter2 -a mtu_bypass=on -P");
    }
  }
  else
  {
    warn_logging("No virtual adapters found, skipping");
  }
  
  my @a_padapters = `lsdev -Ccadapter | grep ent | egrep -v "Virtual|Shared" | awk {'print \$1'}`;
  chomp(@a_padapters);
  if(scalar @a_padapters)
  {
    foreach my $padapter (@a_padapters)
    {
      system("chdev -l $padapter -a large_receive=yes -a large_send=yes -a jumbo_frames=yes -a chksum_offload=yes -a flow_ctrl=yes -P >/dev/null 2>&1");
      logging("$padapter parameters applied");
    }
  }
  else
  {
    warn_logging("No physical adapters found, skipping");
  }
}


# VIOS part

sub vios_tunning {
  my $s_check = `tail -1 /var/adm/ras/devinst.log`;
  my $s_ioslevel = `/usr/ios/cli/ioscli ioslevel`;
  chomp($s_check,$s_ioslevel);
  if($s_check eq "END:Tue Aug 10 20:33:08 2010:081020330810")
  {
    logging("This system has been installed from an mksysb or cloned --> $s_check");
  }
  
  if($s_ioslevel ne "2.2.5.10" || $s_ioslevel ne "2.2.5.20")
  {
    print "\n\n";
    warn_logging("You should consider upgrading your VIO server to one of the latest releases (2.2.5.10 / 2.2.5.20). Your current release is $s_ioslevel\n\n");
  }
  
  system("no -p -o rfc1323=1");
  system("no -p -o tcp_recvspace=262144 -o tcp_sendspace=262144");
  system("no -p -o tcp_nodelayack=1");
  system("no -p -o sack=1");
  system("no -p -o udp_sendspace=65536");
  system("no -p -o udp_recvspace=655360");
  system("chdev -l vioslpm0 -a auto_tunnel=0 -P");
  logging("General TCP/IP parameters applied");
  
  my @a_vadapters = `lsdev -Ccadapter | grep -i "Virtual I/O Ethernet Adapter" | awk {'print \$1'}`;
  chomp(@a_vadapters);
  if(scalar @a_vadapters)
  {
    foreach my $vadapter (@a_vadapters)
    {
      system("chdev -l $vadapter -a max_buf_small=4096 -a min_buf_small=4096 -a min_buf_medium=512 -a max_buf_medium=1024 -a min_buf_large=96 -a max_buf_large=256 -a min_buf_huge=96 -a max_buf_huge=128 -a min_buf_tiny=4096 -a max_buf_tiny=4096 -P >/dev/null 2>&1");
      logging("$vadapter parameters applied");
    }
  }
  else
  {
    warn_logging("No virtual adapters found, skipping");
  }
  
  my @a_vadapters2 = `lsdev -Ccadapter | grep "Virtual I/O Ethernet Adapter" | awk {'print \$1'} | sed 's/t//g'`;
  chomp(@a_vadapters2);
  if(scalar @a_vadapters2)
  {
    foreach my $vadapter2 (@a_vadapters2)
    {
      system("chdev -l $vadapter2 -a mtu_bypass=on -P");
    }
  }
  else
  {
    warn_logging("No virtual adapters found, skipping");
  }
  
  my @a_padapters = `lsdev -Ccadapter | grep ent | egrep -v "Virtual|Shared" | awk {'print \$1'}`;
  chomp(@a_padapters);
  if(scalar @a_padapters)
  {
    foreach my $padapter (@a_padapters)
    {
      system("chdev -l $padapter -a large_receive=yes -a large_send=yes -a jumbo_frames=yes -a chksum_offload=yes -a flow_ctrl=yes -P >/dev/null 2>&1");
      logging("$padapter parameters applied");
    }
  }
  else
  {
    warn_logging("No physical adapters found, skipping");
  }
  
  my $model = `lsconf | grep \"System Model\" | cut -f 2 -d ,`;
  chomp($model);
  system("mount -o soft is0110:/sapmnt/is0110/a/firmware/$model /mnt");
  if($? ne "0")
  {
    crit_logging("Unable to mount repository for microcode, please check manually");
  }
  else
  {
    system("rpm -Uvh /mnt/*.rpm --ignoreos >/dev/null 2>&1");
    logging("Microcodes have been installed, apply them with DIAG tool");
    system("umount -f /mnt >/dev/null 2>&1");
  }
  
  my @a_seas = `lsdev -Ccadapter | grep "Shared Ethernet Adapter" | awk {'print \$1'}`;
  chomp(@a_seas);
  if(scalar @a_seas)
  {
    foreach my $sea (@a_seas)
    {
      system("chdev -l $sea -a jumbo_frames=yes -a large_receive=yes -a largesend=1 -P >/dev/null 2>&1");
      logging("$sea parameters applied");
    }
  }
  else
  {
    warn_logging("No SEA adapters found, skipping");
  }
}

system("lslpp -l ios.sea >/dev/null 2>&1");
if($? != 0)
{
  logging("This is not a VIO server, AIX parameters will be applied");
  &aix_tunning;
}
elsif($? == 0)
{
  logging("This is a VIO servers, VIO parameters will be applied");
  &vios_tunning;
}
else
{
  unkn_logging("Unable to determine system type, aborting...");
  exit(3);
}
