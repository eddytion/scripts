#!/usr/bin/perl
use strict;
use warnings;
use threads;

my $identity = <<EOF;
-----BEGIN RSA PRIVATE KEY-----
MIIEogIBAAKCAQEAz0zo+L137+CZLPDR+vm9J+VzgKlOWTecy8SOgdUaZ9aNtILo
pDQ0cYbAfWRVfPPDDo8tR6wMet1jZizucvg1yTA9ANXKMYdp7nEnP5kjaiSGxWqB
JKg4rraX5gMURLfU14av0lfFAExsDWfmXPybqkJwt0FoAIOsUnJbDoN/eBye/5UL
AoMIgRqNe8oCSCzEvlSEIN/0Ari6G3riR8cNX2VTGtQye94X9io60V6YWnYj7Q0A
fya8XXuOq2n4P7s7mMu7hdF125aGFKhDEVSqHQmfOdZYdmBy+MSy5+HUjN5j5cfT
/KkvASnXPOrTUP3DzwakFZkwXO4ChRFf/+2hlQIBIwKCAQEAjiYcGEdoL3VwWVSt
PmIbTo61mg2yEUq0qPvPbviHIqHAQUPSub1lyjCD/jYr/ej6yCeqBULGuqZwC4yG
QDUsMi+0zV9mE1WKd54MSN4Jp96ITNtRPbUuLqkXs6pXCoyvNLQgyr/Xiy0W5J8E
XQT9Bwj81W6ttzW3/gVFwM8y1gPCLVSIGSAl/cEPF1UX6h6FSsO9QD9d3jCXSI6x
INEkdKa8B/lCKYPE9UlvnrBDmkLwem8Iw2HgieaI6P2ngOVEKVhH5ducxRiJFVLl
mxEWp05HuZbdCCrIJp6hEIR23ejFtxbxY7cOJOCLRHSRxoIqAPap0SCIjpmbiXbS
SHan6wKBgQD7YQFRia63RF35JYpTc19mxj7EKHBQ2nMRys79MgCYJPger4Wt/fp0
JdHrpnHC6K51Ok3k/wBC82P7GOJmN6MnL4bULnZ9MQ7XZxwfi38XP2b1+87stPnW
R+uGqSlGWt99qXbsNlf2N2ws+xCPNM9V86eHVSQT4hEiCcT9T2iH4wKBgQDTHHhy
/trEgAMI/uOWn2DblbhL+r3k7ul2XDEixerKuvoM362urAN56qKMY4EdhiYQADKE
DeJnS6dhPsBTFsm7rPl+fXq0Cxk8GR3qA7H8fvsrT2C+wCg4zdyBW/dg2QtwkU9y
ajuZfqDfKLBE2rCbRKIPxNBVVZIy/X8asYK6JwKBgHoZLIawlrDJb3kDmvVVS5hR
qXU4No2r7r9/w5+NUL7tYpKPxJZWyhsoUAS+jwbmC5gGYFlIqFsIgQTu1F2IvPXG
oJLx/wmbfDy9Dajr++a4ZTWmMU5mh/pdcmX6ZIFCFMgB2q0+94Y4LTprUS+dTsNZ
FttVPWi+QtYEvsQt4lChAoGATmmpFMUPbY6iCqfQ4CyRsKVTFOgapX1PZnoDnzOR
uQOetFMUn/a/dm0Xzb6PCvdP91CHyqYSQ5/B06mX5Fjr1/5rTD08ND6i+RCktgFf
XcjDsQA54HNCI7otVJ6AdG3frXfNDT1mmBkXLlDxA6GvT50mQF8LjWjtKOHQH9uI
U8UCgYEAoiPVNEgAXQn4m6G+q7TaA6OuiYDW/yNOLaxzKPUaGX73Gfq1TgWqUSbz
EPojzY43tl+teilwbKnLPYM3GbZThLq/u11CVTC75EHvKueUczLyuf3bgIIXyzik
r3Tirv51U0409UEZ3Sat1h2acB4hsPbcqSeffM+aqP2x3C6Ll8M=
-----END RSA PRIVATE KEY-----
EOF

my $idfile = "/tmp/tmpid.key";
unlink($idfile) if -e $idfile;
open(my $fh, '>', $idfile);
print($fh $identity);
close($fh);
chmod 0400, $idfile;

my $hmc = $ARGV[0];
if(!defined($ARGV[0]))
{
    print("\nERR: Specify hmc name \n");
    print("Usage: $0 <hmc> \n\n");
    exit(1);
}

sub get_data()
{
    my $v = shift;
        my $system_model = `ssh -q -i $idfile -l padmin $v "ioscli uname -M"`;
        my $ioslevel = `ssh -q -i $idfile -l padmin $v "ioscli ioslevel"`;
        my $efixes = `ssh -q -i $idfile -l padmin $v "echo \"emgr -P\" | oem_setup_env | grep installp" | awk {'print \$3'} | tr '\n' ',' | sed 's/.\$//g'`;
        my @fcs = `ssh -q -i $idfile -l padmin $v "ioscli lsdev -type adapter | grep fcs | awk {'print \\\$1'}"`;
        chomp(@fcs);
        my $fc_mc_mod;
        my $count = scalar(@fcs);
        my $i = 1;
        foreach my $f (@fcs)
        {
            my $model = `ssh -q -i $idfile -l padmin $v "ioscli lsdev -dev $f -vpd | grep Part" | cut -f 18 -d .`;
            my $mc = `ssh -q -i $idfile -l padmin $v "echo \"lsmcode -cd $f\" | oem_setup_env" | tr '\\n' ' ' | awk {'print \$8'} | sed 's/.\$//g'`;
            chomp($model, $mc);
            if($i < $count)
            {
                $fc_mc_mod .= "$f:$model:$mc, ";
            }
            else
            {
                $fc_mc_mod .= "$f:$model:$mc";
            }
            $i++;
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
    push @threads, threads::async { &get_data($i); }
}

foreach(@threads)
{
    $_->threads::join();
}