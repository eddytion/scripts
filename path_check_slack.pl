#!/usr/bin/perl

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
my $result_file = "/tmp/.path_scan_slack.out";

package PathCheck;

sub new
{
    my $class = shift;
    my $self = {
        _viosName     => shift,
        _viosLocation => shift,
        _debug        => shift,
    };
    bless $self, $class;
    return $self;
}

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
sub check_paths()
{
    my @failed_paths;
    my @disabled_paths;
    my @missing_paths;
    my @defined_paths;
    my @affected_disks;
    my @affected_fc;
    my @disk_ins_paths;
    my @ssh_errors;
    my @luns;

    my ($self, $viosName) = @_;
    my $vios = $self->{_viosName};
    my $location = $self->{_viosLocation};
    my $debug = $self->{_debug};
    my @data;
    my $path_count_test = `ssh -i $idfile -o StrictHostKeyChecking=no -o ConnectTimeout=45 -q -o ConnectionAttempts=1 -l padmin $vios "ioscli lspath | sed 's/\ \ */\,/g' | grep -c fscsi"`;
    chomp($path_count_test);
    if($path_count_test eq "0")
    {
        print("OK: $location -> $vios has no FC paths \n");
    }
    elsif(`echo $?` != 0)
    {
        print(`echo return code $?` . "\n");
        push(@ssh_errors, "ERROR");
    }
    else
    {
        @data = eval { `ssh -i $idfile -o StrictHostKeyChecking=no -o ConnectTimeout=45 -q -o ConnectionAttempts=1 -l padmin $vios "ioscli lspath | sed 's/\ \ */\,/g' | grep fscsi"`; };
        unless(@data)
        {
            print $@;
            print(`echo return code $?` . "\n");
            push(@ssh_errors, $@);
        }
        foreach my $line (@data)
        {
            my @line_params = split(/,/, $line);
            my $disk = $line_params[1];
            push(@luns, "$disk,");
        }

        foreach my $path (@data)
        {
            my @a_path_params = split(/\,/, $path);
            my $s_disk = $a_path_params[1];
            my $disk_count = grep(/$s_disk/, @luns);
            chomp($disk_count);

            if($location =~ m/INFRA/i && $disk_count < 4)
            {
                push(@disk_ins_paths, $s_disk);
            }
            elsif($location =~ m/POD/i && $disk_count < 8)
            {
                push(@disk_ins_paths, $s_disk);
            }
            elsif(!defined($location) && ($disk_count !=4 || $disk_count != 8))
            {
                push(@disk_ins_paths, $s_disk);
            }

            my $s_fc = $a_path_params[2];
            if($path =~ m/Failed/i)
            {
                push(@failed_paths, "$path");
                push(@affected_disks, $s_disk);
                push(@affected_fc, $s_fc);
            }
            elsif($path =~ m/Defined/i)
            {
                push(@defined_paths, "$path");
                push(@affected_disks, $s_disk);
                push(@affected_fc, $s_fc);
            }
            elsif($path =~ m/Missing/i)
            {
                push(@missing_paths, "$path");
                push(@affected_disks, $s_disk);
                push(@affected_fc, $s_fc);
            }
            elsif($path =~ m/Disabled/i)
            {
                push(@disabled_paths, "$path");
                push(@affected_disks, $s_disk);
                push(@affected_fc, $s_fc);
            }
        }
    }
    if(scalar(@failed_paths) > 0 || scalar(@defined_paths) > 0 || scalar(@disabled_paths) > 0 || scalar(@missing_paths) > 0 || scalar(@affected_disks) > 0 || scalar(@disk_ins_paths) > 0)
    {
        if($debug eq "true")
        {
            print("FAIL: $location -> $vios has " . scalar(@failed_paths) . " failed paths, " . scalar(@missing_paths) . " missing paths, " . scalar(@defined_paths) . " defined paths, " . scalar(@disabled_paths) . " disabled paths, " . scalar(@data) . " total paths. Affected luns: " . join(', ',uniq(@affected_disks)) . " | Affected FC adapters: " . join(', ',uniq(@affected_fc)) . " | Disks with insufficient paths: " . scalar(uniq(@disk_ins_paths)) . " ==> " . join(', ', uniq(@disk_ins_paths)) . "\n");
        }
        else
        {
            print("FAIL: $location -> $vios has " . scalar(@failed_paths) . " failed paths, " . scalar(@missing_paths) . " missing paths, " . scalar(@defined_paths) . " defined paths, " . scalar(@disabled_paths) . " disabled paths, " . scalar(@data) . " total paths. Total affected luns: " . scalar(uniq(@affected_disks)) . " | Affected FC adapters: " . join(',',uniq(@affected_fc)) . " | Disks with insufficient paths: " . join(', ',uniq(@disk_ins_paths)) . "\n");
        }
        my $msg = "FAIL: $location -> $vios has " . scalar(@failed_paths) . " failed paths, " . scalar(@missing_paths) . " missing paths, " . scalar(@defined_paths) . " defined paths, " . scalar(@disabled_paths) . " disabled paths, " . scalar(@data) . " total paths. Total affected luns: " . scalar(uniq(@affected_disks)) . " | Affected FC adapters: " . join(',',uniq(@affected_fc)) . " | Disks with insufficient paths: " . scalar(uniq(@disk_ins_paths)) . "\n";
        write2file($msg);
    }
    elsif(scalar(@ssh_errors) > 0)
    {
        print("ARRRAY: @ssh_errors \n");
        print("FAIL: $location -> $vios returned an error while connecting $@ --> $? --> $! --> END \n");
        my $msg = "FAIL: $location -> $vios returned an error while connecting \n";
        write2file($msg);
    }
    else
    {
        print("OK: $location -> $vios has all paths online. ". scalar(@data) . " total paths \n");
    }
}
1;

use strict;
use warnings FATAL => 'all';
use threads;

my @a_vioses;
my @threads;

my ($details, $vios, $op) = @ARGV;
if(defined($details) && $details =~ m/^-[Dd]/)
{
    if(!defined($vios))
    {
        die("When using details flag you have to specify a vios name");
    }
    else
    {
        @a_vioses = `grep $vios /usr/local/etc/dsadm.viostsm.db | grep SAN | cut -f 2,4 -d : | grep -v "^#" | sort | uniq`;
    }
}
else
{
    @a_vioses = `grep VIO /usr/local/etc/dsadm.viostsm.db | grep SAN | cut -f 2,4 -d : | grep -v "^#" | sort | uniq`;
}
chomp(@a_vioses);

sub post2slack
{
    my $dbg = shift;
    if($dbg eq "true")
    {
        die("Not posting to slack due to debugging flag");
    }
    print("\n\n\n");
    my @slack_msg;
    my $site = `uname -n | cut -c1-4`;
    chomp($site);
    my $proxy = "https://" . $site . "sob011ccpsa:8080/";
    my $title = uc($site);
    open(my $handle, '<:encoding(UTF-8)', $result_file) or die("No result file found, no data to upload --> $! --> $? --> $@");
    while(my $row = <$handle>)
    {
        chomp($row);
        push(@slack_msg, $row);

    }
    print("\n\n\n") ;
    print(join('\n', PathCheck::uniq(@slack_msg)));
    my $msg = join('\n', PathCheck::uniq(@slack_msg));
    print("{\"attachments\":[{\"color\":\"#FF0000\",\"title\":\"Path check status for $title\",\"text\":\"$msg\"}]}");
    #system("export https_proxy=$proxy; /usr/local/bin/wget_112 --no-check-certificate --post-data='{\"attachments\":[{\"color\":\"#FF0000\",\"title\":\"Path check status for $title\",\"text\":\"$msg\"}]}' --header='Content-Type:application/json' 'https://hooks.slack.com/services/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'");
}

for my $i (@a_vioses)
{
    my @params = split(/:/, $i);
    my $v = $params[0];
    my $loc = $params[1];
    if(defined($details))
    {
        my $object = PathCheck->new($v, $loc, "true");
        push @threads, threads::async { $object->check_paths() }
    }
    else
    {
        my $object = PathCheck->new($v, $loc, "false");
        push @threads, threads::async { $object->check_paths() }
    }
}

foreach(@threads)
{
    $_->threads::join();
}
unlink($idfile);
if(defined($details))
{
    post2slack("true");
}
else
{
    post2slack("false");
}
unlink($result_file);
