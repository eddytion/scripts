#!/usr/bin/perl

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

if ($#ARGV != 0) 
{
  crit_logging("missing input parameters");
  exit(1);
}
else
{
  logging("Filename provided, $ARGV[0]");
}

sub install_systems {
  my $file = $ARGV[0];
  open (FILE,$file);
  my @a_content = <FILE>;
  close(FILE);
  chomp(@a_content);
  
  logging("The following systems are going to be installed");
  foreach $system (@a_content)
  {
    chomp($system);
    my @a_details = split(/,/,$system);
    my $lpar = $a_details[0];
    my $uuid = $a_details[1];
    my $os = $a_details[2];
    my $cpp = $a_details[3];
    my $validation = $a_details[4];
    my $make = $a_details[5];
    my $date = `date +\"%Y-%m-%d %H:%M:%S\"`;
    chomp($date,$lpar,$uuid,$os,$cpp,$validation,$make);
    
    print "<b><h5>LPAR: $lpar,SERIAL: $uuid, OS: $os, C++: $cpp, Validation: $validation, Make: $make</h5></b>\n";
    my $hmc=`mysql -u root websles -pnXEzT0Ae0k9RJTM -e \"SELECT hmc_name FROM phys_sys WHERE lpar_name='$lpar' LIMIT 0,1\" | grep -v hmc_name`;
    my $ms=`mysql -u root websles -pnXEzT0Ae0k9RJTM -e \"SELECT ms_name FROM phys_sys WHERE lpar_name='$lpar' LIMIT 0,1\" | grep -v ms_name`;
    chomp($ms,$hmc);
    
    if($os eq "rhel72")
    {
      my $cmd = "/srv/scripts/install_rhel.sh $hmc $ms $lpar";
      my $query = "INSERT INTO webrhel_log VALUES (NULL,'$date','$hmc','$lpar','$ms','$os','$uuid','$cmd')";
      system("mysql -u root -pnXEzT0Ae0k9RJTM websles -e \"$query\"");
      system($cmd);
      print "$cmd \n";
    }
    elsif($os eq "rhel73")
    {
      my $cmd = "/srv/scripts/install_redhat73.sh $hmc $ms $lpar";
      my $query = "INSERT INTO webrhel_log VALUES (NULL,'$date','$hmc','$lpar','$ms','$os','$uuid','$cmd')";
      system("mysql -u root -pnXEzT0Ae0k9RJTM websles -e \"$query\"");
      system($cmd);
      print "$cmd \n";
    }
    elsif($os eq "sles12sp1" || $os eq "sles12sp2")
    {
      my $cmd = "/srv/scripts/install_suse_new.sh $hmc $ms $lpar $os";
      my $query = "INSERT INTO websles_log VALUES (NULL,'$date','$hmc','$lpar','$cpp','$ms','$os','$uuid','$validation','$make','$cmd')";
      system("mysql -u root -pnXEzT0Ae0k9RJTM websles -e \"$query\"");
      system($cmd);
      print "$cmd \n";
    }
    elsif($os eq "sles11sp4")
    {
      my $cmd = "/srv/scripts/install_sles11sp4.sh $hmc $ms $lpar $os $uuid";
      my $query = "INSERT INTO websles_log VALUES (NULL,'$date','$hmc','$lpar','$cpp','$ms','$os','$uuid','$validation','$make','$cmd')";
      system("mysql -u root -pnXEzT0Ae0k9RJTM websles -e \"$query\"");
      system($cmd);
      print "$cmd \n";
    }
    else
    {
      crit_logging("Unsupported OS, $os");
    }
  }
}

&install_systems;
