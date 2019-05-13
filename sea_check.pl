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
my $result_file = "/tmp/.sea_scan_slack.out";

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
    my $sea_count_test = `ssh -i $idfile -o StrictHostKeyChecking=no -o ConnectTimeout=45 -q -o ConnectionAttempts=1 -l padmin $vios "ioscli lsdev -type adapter | grep -c 'Shared Ethernet Adapter'"`;
    chomp($sea_count_test);
    if($sea_count_test eq "0")
    {
        print("OK: $vios has no SEA \n");
    }
    else
    {
        my @sealist = `ssh -i $idfile -o StrictHostKeyChecking=no -o ConnectTimeout=45 -q -o ConnectionAttempts=1 -l padmin $vios "ioscli lsdev -type adapter | grep 'Shared Ethernet Adapter'" | awk {'print \$1'}`;
        chomp(@sealist);
        foreach my $sea (@sealist)
        {
            my $sea_macs;
            my $err_count = `ssh -i $idfile -o StrictHostKeyChecking=no -o ConnectTimeout=45 -q -o ConnectionAttempts=1 -l padmin $vios "echo 'entstat -d $sea 2>/dev/null' | oem_setup_env | grep -E 'OUT_OF_SYNC|Down'" | tr '\n' ',' | tr '\t' ' ' | sed 's/.\$//g'`;
            my $sea_state = `ssh -i $idfile -o StrictHostKeyChecking=no -o ConnectTimeout=45 -q -o ConnectionAttempts=1 -l padmin $vios "echo 'entstat -d $sea 2>/dev/null' | oem_setup_env | grep -E 'PRIMARY|BACKUP'"`;
            my $sea_priority = `ssh -i $idfile -o StrictHostKeyChecking=no -o ConnectTimeout=45 -q -o ConnectionAttempts=1 -l padmin $vios "echo 'entstat -d $sea 2>/dev/null' | oem_setup_env | grep -w 'Priority:' | grep -vE 'FCOE|Active|0x'" | cut -f 2 -d : | sed 's/ //g'`;
            $sea_macs = `ssh -i $idfile -o StrictHostKeyChecking=no -o ConnectTimeout=45 -q -o ConnectionAttempts=1 -l padmin $vios "echo 'entstat -d $sea 2>/dev/null' | oem_setup_env | grep -E 'Actor System:|Partner System:'" | cut -f 2 -d : | sed s'/ //g' | tr '\n' ':' | sed 's/.\$//g'`;
            my $sea_hamode = `ssh -i $idfile -o StrictHostKeyChecking=no -o ConnectTimeout=45 -q -o ConnectionAttempts=1 -l padmin $vios "ioscli lsdev -dev $sea -attr ha_mode | tail -1"`;
            chomp($err_count, $sea_state, $sea_priority, $sea_macs, $sea_hamode);
            if($sea_macs eq "" || $sea_macs !~ m/-/x)
            {
                $sea_macs = `ssh -i $idfile -o StrictHostKeyChecking=no -o ConnectTimeout=45 -q -o ConnectionAttempts=1 -l padmin $vios "echo 'entstat -d $sea 2>/dev/null' | oem_setup_env | grep -E 'Hardware Address:" | cut -f 2,3,4,5,6,7 -d : | sed s'/ //g' | tr '\n' '|' | sed 's/.\$//g'`;
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
@a_vioses = `grep VIO /usr/local/etc/dsadm.viostsm.db | cut -f 2,4 -d : | grep -v "^#" | sort | uniq`;
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
    #system("export https_proxy=$proxy; /usr/local/bin/wget_112 --no-check-certificate --post-data='{\"attachments\":[{\"color\":\"#FF0000\",\"title\":\"SEA status for $title\",\"text\":\"$msg\"}]}' --header='Content-Type:application/json' 'https://hooks.slack.com/services/'");
    #system("export https_proxy=$proxy; /usr/local/bin/wget_112 --no-check-certificate --post-data='{\"attachments\":[{\"color\":\"#FF0000\",\"title\":\"SEA status for $title\",\"text\":\"$msg\"}]}' --header='Content-Type:application/json' 'https://hooks.slack.com/services/'");
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
