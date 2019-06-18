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
my $result_file = "/tmp/.sea_scan_slack.out";

my $ssh_opts = " -o BatchMode=yes -i $idfile -o StrictHostKeyChecking=no -o ConnectTimeout=45 -q -o ConnectionAttempts=1 -l padmin ";

package SeaCheck;
sub new
{
    my $class = shift;
    my $self = {
        _viosName     => shift,
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
sub uniq {
    my %seen;
    grep !$seen{$_}++, @_;
}
sub write2file
{
    my $text = shift;
    open(my $fstream, '>>', $result_file);
    print $fstream $text;
    close($fstream);
}
sub check_sea_stat()
{
    my ($self) = @_;
    my $vios = $self->{_viosName};
    my $sea_count_test = `ssh $ssh_opts $vios "ioscli lsdev -type adapter | grep -c 'Shared Ethernet Adapter'"`;
    chomp($sea_count_test);
    if($sea_count_test eq "0")
    {
        print("OK: $vios has no SEA \n");
    }
    else
    {
        my @sealist = `ssh $ssh_opts $vios "ioscli lsdev -type adapter | grep 'Shared Ethernet Adapter'" | awk {'print \$1'}`;
        chomp(@sealist);
        foreach my $sea (@sealist)
        {
            my $sea_macs;
            my $err_count = `ssh $ssh_opts $vios "echo 'entstat -d $sea 2>/dev/null' | oem_setup_env | grep -E 'OUT_OF_SYNC|Down'" | tr '\n' ',' | tr '\t' ' ' | sed 's/.\$//g'`;
            my $sea_state = `ssh $ssh_opts $vios "echo 'entstat -d $sea 2>/dev/null' | oem_setup_env | grep -E 'PRIMARY|BACKUP'"`;
            my $sea_priority = `ssh $ssh_opts $vios "echo 'entstat -d $sea 2>/dev/null' | oem_setup_env | grep -w 'Priority:' | grep -vE 'FCOE|Active|0x'" | cut -f 2 -d : | sed 's/ //g'`;
            $sea_macs = `ssh $ssh_opts $vios "echo 'entstat -d $sea 2>/dev/null' | oem_setup_env | grep -E 'Actor System:|Partner System:'" | cut -f 2 -d : | sed s'/ //g' | tr '\n' ':' | sed 's/.\$//g'`;
            my $sea_hamode = `ssh $ssh_opts $vios "ioscli lsdev -dev $sea -attr ha_mode | tail -1"`;
            chomp($err_count, $sea_state, $sea_priority, $sea_macs, $sea_hamode);
            if($sea_macs eq "" || $sea_macs !~ m/-/x)
            {
                $sea_macs = `ssh $ssh_opts $vios "echo 'entstat -d $sea 2>/dev/null' | oem_setup_env | grep -E 'Hardware Address:" | cut -f 2,3,4,5,6,7 -d : | sed s'/ //g' | tr '\n' '|' | sed 's/.\$//g'`;
                chomp($sea_macs);
            }
            $vios =~ s/.ibr.ssm.sdc.gts.ibm.com//g;
            if($err_count =~ m/Down/i || $err_count =~ m/OUT_OF_SYNC/i)
            {
                print("WARN: $vios: $sea: $err_count\n");
                print("WARN: $vios: Actor/Partner MACs: $sea_macs\n");
                write2file("WARN: $vios: $sea: $err_count\n");
                write2file("WARN: $vios: Actor/Partner MACs: $sea_macs\n");
            }
            if($sea_state =~ m/PRIMARY/i && $sea_priority ne 1)
            {
                print("WARN: $vios: $sea: State: PRIMARY with prio $sea_priority but should be BACKUP.\n");
                write2file("WARN: $vios: $sea: State: PRIMARY with prio $sea_priority but should be BACKUP.\n");
            }
            if($sea_state =~ m/BACKUP/i && $sea_priority ne 2)
            {
                print("WARN: $vios: $sea: State: BACKUP with prio $sea_priority but should be PRIMARY\n");
                write2file("WARN: $vios: $sea: State: BACKUP with prio $sea_priority but should be PRIMARY\n");
            }
            if($sea_hamode =~ m/standby/i)
            {
                print("WARN: $vios: $sea: HA Mode: $sea_hamode but should be auto / sharing\n");
                write2file("WARN: $vios: $sea: HA Mode: $sea_hamode but should be auto / sharing\n");
            }
        }
    }
}
1;

my @a_vioses;
my @threads;
@a_vioses = `grep VIO /usr/local/etc/dsadm.viostsm.db | cut -f 1,4 -d : | grep -v "^#" | sort | uniq`;
chomp(@a_vioses);

sub post2slack
{
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
    @slack_msg = sort @slack_msg;
    print("\n\n\n") ;
    print(join('\n', uniq(@slack_msg)));
    my $msg = join('\n', uniq(@slack_msg));
    print("{\"attachments\":[{\"color\":\"#FF0000\",\"title\":\"SEA status for $title\",\"text\":\"$msg\"}]}");
    #system("export https_proxy=$proxy; /usr/local/bin/wget_112 --no-check-certificate --post-data='{\"attachments\":[{\"color\":\"#FF0000\",\"title\":\"SEA status for $title\",\"text\":\"$msg\"}]}' --header='Content-Type:application/json' 'https://hooks.slack.com/services/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'");
    #system("export https_proxy=$proxy; /usr/local/bin/wget_112 --no-check-certificate --post-data='{\"attachments\":[{\"color\":\"#FF0000\",\"title\":\"SEA status for $title\",\"text\":\"$msg\"}]}' --header='Content-Type:application/json' 'https://hooks.slack.com/services/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'");
}

for my $i (@a_vioses)
{
    my @params = split(/:/, $i);
    my $v = $params[0];
    my $object = SeaCheck->new($v);
    push @threads, threads::async { $object->check_sea_stat() }
}

foreach(@threads)
{
    $_->threads::join();
}
post2slack;
unlink($idfile);
