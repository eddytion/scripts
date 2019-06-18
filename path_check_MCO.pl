#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
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
my $result_file = "/tmp/.path_scan_MCO_POD1.out";

sub trim($)
{
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}

sub write2file
{
    my $text = shift;
    open(my $fstream, '>>', $result_file);
    print $fstream $text;
    close($fstream);
}
sub uniq {
    my %seen;
    grep !$seen{$_}++, @_;
}

sub path_check($){
    my $vios = shift;
    my @data = `ssh -i $idfile -o StrictHostKeyChecking=no -o ConnectTimeout=10 -q -o ConnectionAttempts=1 -l padmin $vios "ioscli lspath | grep fscsi | grep -Ev 'Available|Enabled'"`;
    chomp(@data);
    my $failed_paths = scalar(@data);
    if($failed_paths > 0)
    {
        print("\033[93m $vios = $failed_paths\n");
        write2file("$vios = $failed_paths\n");
    }
    else
    {
        print("\033[92m $vios = $failed_paths\n");
        write2file("$vios = $failed_paths\n");
    }
}

sub run_threads{
    my @threads;
    my $date = `date`;
    chomp($date);
    my @vioses = `cat /usr/local/etc/dsadm.viostsm.db | grep POD1 | grep SAN`;
    chomp(@vioses);
    print("\033[94m *******************************Failed Path Status  - Date : $date *************************\n");
    write2file("\033[94m *******************************Failed Path Status  - Date : $date *************************\n");
    for my $i (@vioses)
    {
        my @params = split(/:/, $i);
        my $v = $params[0];
        push @threads, threads::async { path_check($v) }
    }

    foreach(@threads)
    {
        $_->threads::join();
    }
}

while(1){
    run_threads;
    print("\033[0m");
    sleep 300;
}