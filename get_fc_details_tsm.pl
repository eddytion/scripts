#!/usr/bin/perl
use strict;
use warnings;
use threads;

print("HOSTNAME: HW MODEL: OSLEVEL: iFixes: FC ADAPTERS(NAME:PART:MCODE): MPIO Version + Host attachment: SDDPCM Version\n");
sub get_data()
{
    my $v = shift;
    my $system_model = `ssh -q -l ibmadmin $v "uname -M"`;
    my $ioslevel = `ssh -q -l ibmadmin $v "oslevel -s"`;
    my $efixes = `ssh -q -l ibmadmin $v "sudo emgr -P | grep installp | awk {'print \\\$3'} | tr '\\n' ',' | sed 's/.\$//g'"`;
    my @fcs_phys = `ssh -q -l ibmadmin $v "lsdev -Cc adapter | grep fcs | grep -v Virtual | awk {'print \\\$1'}" | sed 's/\,\$//g'`;
    chomp(@fcs_phys);
    my $details = `ssh -q -l ibmadmin $v "for f in \\\$(lsdev -Cc adapter | grep fcs | grep -v Virtual | awk {'print \\\$1'}); do pn=\\\$(lscfg -vpl \\\$f | grep 'Part Number' | cut -f 18 -d .); mc=\\\$(sudo lsmcode -cd \\\$f | tr '\\n' ' ' | awk {'print \\\$8'}); echo \\\$f:\\\$pn:\\\$mc;done" | tr '\\n' ' ' | sed 's/\\. /,/g'`;
    chomp($details);
    my $mpio = `ssh -q -l ibmadmin $v "lslpp -l | egrep 'MPIO Disk|MPIO FCP' | sort | uniq | awk {'print \\\$1'}" | tr '\\n' ',' | sed 's/\,\$//g'`;
    my $sddpcm = `ssh -q -l ibmadmin $v "lslpp -l | grep 'IBM SDD PCM' | sort | uniq | awk {'print \\\$2'}"`;
    my $atape = `ssh -q -l ibmadmin $v "lslpp -l | grep 'Atape.driver' | sort | uniq | awk {'print \\\$2'}"`;
    chomp($system_model, $ioslevel, $efixes, $details, $mpio, $sddpcm, $atape);
    $details =~ s/,$//;
    print("$v: Model => $system_model: AIX => $ioslevel: EMGR => $efixes: FC => $details: MPIO => $mpio: SDDPCM => $sddpcm: ATAPE => $atape\n");
}
my @threads;
my @a_vioses;
foreach(@ARGV)
{
    push(@a_vioses, $_);
}
chomp(@a_vioses);
for my $i (@a_vioses)
{
    push @threads, threads::async { &get_data($i); }
}

foreach(@threads)
{
    $_->threads::join();
}