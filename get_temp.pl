#!/usr/bin/env perl

use strict;

# Naming convention for variables
# a_ ... array
# h_ ... hash
# s_ ... string
# i_ ... integer
# r_ ... reference

# Define global variables

my @a_ms_list;
my $s_out_dir = "/tmp/temps_sap";
if(-d $s_out_dir)
{
	system("rm -rf $s_out_dir/*");
}
else
{
	system("mkdir $s_out_dir");
}

my $s_hmc_user = "unix";
my $i_cim_port = "5989";
my $i_ssh_tun_port = "65000";

# Unset system proxy

system("unset http_proxy; unset ftp_proxy; unset https_proxy");

# Define HMC array

my @a_hmc = ("ishmc40","ishmc31","ishmc30","ishmc11");

# SSH tunnel functions

sub ssh_tunnel_open {
  my $s_hmc = shift;
  my $s_fsp_ip = shift;
  system("ssh -M -S temp-monitor-socket -fnNT -4 -L $i_ssh_tun_port:$s_fsp_ip:$i_cim_port -l $s_hmc_user $s_hmc");
}

sub ssh_tunnel_close {
  my $s_hmc = shift;
  system("ssh -S temp-monitor-socket -O exit -l $s_hmc_user $s_hmc");
}

# Get all MS and ip addresses from each hmc

sub get_list {
  my $s_hmc = shift;
  my @a_list = `ssh -l $s_hmc_user -q $s_hmc "for ms in \\\$(lssyscfg -r sys -F name,ipaddr); do echo \\\$(uname -n|cut -f 1 -d .),\\\$ms; done"`;
  push @a_ms_list,@a_list;
}

# Get temperatures from systems

system("mkdir -p $s_out_dir");
foreach my $hmc (@a_hmc)
{
  get_list($hmc);
}

print "@a_ms_list";

foreach my $ms (@a_ms_list)
{
  chomp($ms);
  my @a_data = split(/,/,$ms);
  my $hmc_name = $a_data[0];
  my $ms_name = $a_data[1];
  my $ip_addr = $a_data[2];
  
  print "\n$ms\n";
  ssh_tunnel_open($hmc_name,$ip_addr);
  system("unset http_proxy; unset ftp_proxy; unset https_proxy; wbemcli -nl -noverify ei \"https://HMC:password\@localhost:$i_ssh_tun_port/root/ibmsd:fips_thermalmetricvalue\" > $s_out_dir/$ms_name.out");
  ssh_tunnel_close($hmc_name);
}

my $s_curr_date = `date +%Y-%m-%d`; chomp($s_curr_date);
my $s_db_user = "root";
my $s_db_pass = "nXEzT0Ae0k9RJTM";
my $s_db_host = "localhost";
my $s_work_dir = "/tmp/temps_sap";
unlink("$s_work_dir/filtered_$s_curr_date.csv");
system("find $s_work_dir -type f -size 0 -delete");

my @a_lines;
my @a_csv;

sub lineup {
  my @a_files = `ls $s_work_dir | grep sys`;
  chomp(@a_files);
  foreach my $file (@a_files)
  {
    my @a_temp = `cat $s_work_dir/$file | egrep -v \"FipS_ThermalMetricValue|ElementName|Description|Caption|MetricDefinitionId|BreakdownDimension|BreakdownValue|Volatile|Duration\" | sed 's/^.//g' | awk 'ORS=NR\%2?FS:RS' | awk 'ORS=NR\%2?FS:RS' | sed 's/ /,/g;s/.000000+000//g;'`;
    chomp(@a_temp);
    
    my @a_system = split(/\./,$file);
    my $ms_name = $a_system[0];
    foreach my $line (@a_temp)
    {
      my $s_line = "$ms_name,$line \n";
      chomp($s_line);
      push(@a_lines,$s_line);
    }
  }
}

sub filter_lines {
  foreach my $s_unfiltered_line (@a_lines)
  {
    chomp($s_unfiltered_line);
    my @a_fields = split(/\,/,$s_unfiltered_line);
    my $ms = $a_fields[0];
    my @a_mon_type_IBM = split(/\"/,$a_fields[1]);
    my @a_mon_type_in_out = split(/[:,_]+/,$a_mon_type_IBM[1]);
    my $mon_type = $a_mon_type_in_out[1];
    my $tstamp = $a_fields[3];
    
    # we need to split by "=" sign
    my @a_time_pieces = split(/\=/,$tstamp);
    
    # convert AIX format to MySQL format
    my $timestamp = $a_time_pieces[1];
    my $year = substr($timestamp,0,4);
    my $month = substr($timestamp,4,2);
    my $day = substr($timestamp,6,2);
    
    my $s_hh = substr($timestamp,8,2);
    my $s_mm = substr($timestamp,10,2);
    my $s_ss = substr($timestamp,12,2);
    
    # put everything together
    my $s_timestamp = "$year-$month-$day $s_hh:$s_mm:$s_ss";
    
    # split metric value by "=" sign
    my $metric_value = $a_fields[4];
    my @a_metrics = split(/[=\"]+/,$metric_value);
    my $i_temperature = $a_metrics[1];
    
    # put all the parameters in one line and push it to array
    my $s_final_line = "DEFAULT,$ms,$mon_type,$s_timestamp,$i_temperature\n";
    push(@a_csv,$s_final_line);
  }
}

sub write2file {
  if(scalar(@a_csv))
  {
    open(FILE, ">> $s_work_dir/filtered_$s_curr_date.csv");
    print FILE @a_csv;
    close(FILE);
  }
  
  open(FILE, "> $s_work_dir/filtered_$s_curr_date.sql");
  print FILE "LOAD DATA LOCAL INFILE '$s_work_dir/filtered_$s_curr_date.csv'\n";
  print FILE "INTO TABLE sap.temp_monitor \n";
  print FILE "FIELDS TERMINATED BY ',' \n";
  print FILE "ENCLOSED BY '\"' \n";
  print FILE "LINES TERMINATED BY '\\n' \n";
  close(FILE);
  
  system("mysql -u root -pnXEzT0Ae0k9RJTM sap < $s_work_dir/filtered_$s_curr_date.sql --local-infile=1");
}

&lineup;
&filter_lines;
&write2file;
