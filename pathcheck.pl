#!/usr/bin/perl

package PathCheck;

sub new
{
    my $class = shift;
    my $self = {
        _viosName => shift,
        _viosLocation => shift,
    };
    #print "VIOS name is $self->{_viosName}\n";
    #print "VIOS location is $self->{_viosLocation}\n";
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
sub check_paths()
{
    my @failed_paths;
    my @disabled_paths;
    my @total_paths;
    my @missing_paths;
    my @defined_paths;
    my @affected_disks;
    my @affected_fc;
    my @disk_ins_paths;
    my @ssh_errors;
    
    my ($self, $viosName) = @_;
    my $vios = $self->{_viosName};
    my $location = $self->{_viosLocation};
    my @data = eval { `ssh -o ConnectTimeout=3 -q -o ConnectionAttempts=1 -l padmin $vios "ioscli lspath | sed 's/\ \ */\,/g' | grep fscsi"`; };
    unless(@data)
    {
        print $@;
        push(@ssh_errors, $@);
    }
    foreach my $path (@data)
    {
        my @a_path_params = split(/\,/, $path);
        my $s_disk = $a_path_params[1];
        my $disk_count = grep(/$s_disk/, @data);
        
        if($location == "INFRA" && $disk_count < 4)
        {
            push(@disk_ins_paths, $s_disk);
        }
        elsif($location =~ m/POD/i && $disk_count < 8)
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
    if(scalar(@failed_paths) > 0 || scalar(@defined_paths) > 0 || scalar(@disabled_paths) > 0 || scalar(@missing_paths) > 0 || scalar(@affected_disks) > 0 || scalar(@disk_ins_paths) > 0)
    {
        print("FAIL: $location -> $vios has " . scalar(@failed_paths) . " failed paths, " . scalar(@missing_paths) . " missing paths, " . scalar(@defined_paths) . " defined paths, " . scalar(@disabled_paths) . " disabled paths, " . scalar(@data) . " total paths. Total affected luns: " . scalar(uniq(@affected_disks)) . " | Affected FC adapters: " . join(',',uniq(@affected_fc)) . " | Disks with insufficient paths: " . scalar(uniq(@disk_ins_paths)) . "\n");
        $msg = "FAIL: $location -> $vios has " . scalar(@failed_paths) . " failed paths, " . scalar(@missing_paths) . " missing paths, " . scalar(@defined_paths) . " defined paths, " . scalar(@disabled_paths) . " disabled paths, " . scalar(@data) . " total paths. Total affected luns: " . scalar(uniq(@affected_disks)) . " | Affected FC adapters: " . join(',',uniq(@affected_fc)) . " | Disks with insufficient paths: " . scalar(uniq(@disk_ins_paths)) . "\n";
        my $site = `uname -n | cut -c 1-4`;
        chomp($site);
        my $proxy = "https://" . $site . "sob011ccpsa:8080/";
        system("export https_proxy=$proxy; curl -X POST -H 'Content-type: application/json' --data '{\"text\":\"$msg\"}' https://hooks.slack.com/services/'");
        system("export https_proxy=$proxy; wget -q --no-check-certificate --post-data='{\"text\":\"$msg\"}' --header='Content-Type:application/json' 'https://hooks.slack.com/services/'");
    }
    elsif(scalar(@ssh_errors) > 0)
    {
        print("FAIL: $location -> $vios returned an error while connecting \n");
        $msg = "FAIL: $location -> $vios returned an error while connecting \n";
        my $site = `uname -n | cut -c 1-4`;
        chomp($site);
        my $proxy = "https://" . $site . "sob011ccpsa:8080/";
        system("curl -X POST -H 'Content-type: application/json' --data '{\"text\":\"$msg\"}' https://hooks.slack.com/services/");
    }
    else
    {
        print("OK: $location -> $vios has all paths online. ". scalar(@data) . " total paths \n");
    }
}
1;


use strict;
use threads;

my @a_vioses = `grep VIO /tmp/dsadm.hostdb | grep SAN | cut -f 1,4 -d : | grep -v "#"`;
chomp(@a_vioses);

my @threads;

for my $i (@a_vioses)
{
    my @params = split(/:/, $i);
    my $v = $params[0];
    my $loc = $params[1];
    my $object = PathCheck->new($v, $loc);
    push @threads, async { $object->check_paths() }
}

foreach(@threads)
{
    $_->join();
}
