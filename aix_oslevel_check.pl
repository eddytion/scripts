#!/usr/bin/perl

system("clear");

# Legenda
# a_ ... array
# h_ ... hash
# s_ ... string
# i_ ... integer
# r_ ... reference

my @a_servers = `cat valid_aix`;
chomp(@a_servers);
my @a_consistent;
my @a_inconsistent;

foreach my $server (@a_servers)
{
  my $oslevel_s = `sshpass -p password ssh -o ConnectTimeout=1 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q -l unix $server \"oslevel -s\"`;
  my $oslevel_qs = `sshpass -p password ssh -o ConnectTimeout=1 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q -l unix $server \"oslevel -qs | head -1\"`;
  chomp($oslevel_s,$oslevel_qs);
  
  if($oslevel_s ne $oslevel_qs)
  {
    push(@a_inconsistent,"$server,inconsistent,$oslevel_s,$oslevel_qs\n");
  }
  else
  {
    push(@a_inconsistent,"$server,consistent,$oslevel_s,$oslevel_qs\n");
  }
}

open(FILE, ">> oslevel_results");
print FILE "Server Name,Result,Current OS,Highest OS\n";
print FILE @a_consistent;
print FILE @a_inconsistent;
close(FILE);
