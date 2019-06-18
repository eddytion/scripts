#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use threads;

my $identity = <<EOF;
-----BEGIN RSA PRIVATE KEY-----
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
