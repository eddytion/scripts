#!/usr/bin/perl
use strict;
use warnings;
use threads;

my $identity = <<EOF;
-----BEGIN RSA PRIVATE KEY-----
-----END RSA PRIVATE KEY-----
EOF

my $idfile = "/tmp/tmpid.key";
unlink($idfile) if -e $idfile;
open(my $fh, '>', $idfile);
print($fh $identity);
#close($fh);
chmod 0400, $idfile;
my $result_file = "/tmp/.path_scan_slack.out";

my $hmc = $ARGV[0];

sub get_data()
{
    my $v = shift;
        my $system_model = `ssh -q -i $idfile -l padmin $v "ioscli uname -M"`;
        my $ioslevel = `ssh -q -i $idfile -l padmin $v "ioscli ioslevel"`;
        my $efixes = `ssh -q -i $idfile -l padmin $v "echo \"emgr -P\" | oem_setup_env | grep installp" | awk {'print \$3'} | tr '\n' ',' | sed 's/.\$//g'`;
        my @fcs = `ssh -q -i $idfile -l padmin $v "ioscli lsdev -type adapter | grep fcs | awk {'print \\\$1'}"`;
        chomp(@fcs);
        my $fc_mc_mod;
        foreach my $f (@fcs)
        {
            my $model = `ssh -q -i $idfile -l padmin $v "ioscli lsdev -dev $f -vpd | grep Part" | cut -f 18 -d .`;
            my $mc = `ssh -q -i $idfile -l padmin $v "echo \"lsmcode -cd $f\" | oem_setup_env" | tr '\\n' ' ' | awk {'print \$8'} | sed 's/.\$//g'`;
            chomp($model, $mc);
            $fc_mc_mod .= "$f:$model:$mc, ";
        }
        my $mpio = `ssh -q -i $idfile -l padmin $v "ioscli lssw | grep 'MPIO Disk'" | awk {'print \$1'}`;
        chomp($system_model, $ioslevel, $efixes, $fc_mc_mod, $mpio);
        print("$v: $system_model: $ioslevel: $efixes: $fc_mc_mod: $mpio\n");
}
my @threads;
my @a_vioses = `sshpass -p start1234 ssh -q -l hscroot $hmc "for m in \\\$(lssyscfg -r sys -F name); do for l in \\\$(lssyscfg -r lpar -m \\\$m -F name,lpar_env | grep vioserver | egrep 'vsa|vsb' | cut -f1 -d,); do echo \\\$l; done; done"`;
chomp(@a_vioses);
for my $i (@a_vioses)
{
    push @threads, async { &get_data($i); }
}

foreach(@threads)
{
    $_->join();
}
