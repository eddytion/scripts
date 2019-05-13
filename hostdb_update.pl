#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use threads;

my $result_file = "/usr/local/etc/dsadm.viostsm.db";
open(my $fh, '>', $result_file);
print $fh "#HOSTNAME:ADDRESS:OS:SITE:SERVICE:SERVICE_SITE:TYPE::STATUS:DESCRIPTION:::FRAME:ENV:RMCIP \n";
close($fh);

package DsadmHostDBUpdate;
sub new
{
    my $class = shift;
    my $self = {
        _hmcName     => shift,
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

sub get_vios_list()
{
    my ($self) = @_;
    my $hmc = $self->{_hmcName};
    my @data;
    my @ssh_errors;
    @data = eval { `ssh -l hscroot -o ConnectTimeout=45 -q -o ConnectionAttempts=1 $hmc "for m in \\\$(lssyscfg -r sys -F name); do for l in \\\$(lssyscfg -r lpar -m \\\$m -F name:lpar_env:state:rmc_ipaddr | grep -v Not); do echo \\\$m:\\\$l; done; done"`; };
    unless(@data)
    {
        print $@;
        push(@ssh_errors, $@);
    }
    foreach my $line (@data)
    {
        my $location;
        my $vios_type;
        my $tsm_type;
        my @line_params = split(/:/, $line);
        my $managed_system = $line_params[0];
        my $lpar_name = lc($line_params[1]);
        my $lparenv = $line_params[2];
        my $lpar_state = $line_params[3];
        my $lpar_rmc_ipaddr = $line_params[4];
        if($line =~ m/vioserver/i)
        {
            if((substr $lpar_name,-1) eq "a")
            {
                $location = "INFRA";
            }
            elsif((substr $lpar_name, -1) == "1")
            {
                $location = "POD1";
            }
            elsif((substr $lpar_name, -1) == "2")
            {
                $location = "POD2";
            }

            if(lc($lpar_name) =~ m/vsa/i)
            {
                $vios_type = "VIO Server - SAN A";
            }
            elsif(lc($lpar_name) =~ m/vsb/i)
            {
                $vios_type = "VIO Server - SAN B";
            }
            elsif(lc($lpar_name) =~ m/vna/i)
            {
                $vios_type = "VIO Server - LAN A";
            }
            elsif(lc($lpar_name) =~ m/vnb/i)
            {
                $vios_type = "VIO Server - LAN B";
            }
            write2file("$lpar_name:$lpar_name.ibr.ssm.sdc.com:VIO:$location:VIO:VIO_$location:Virtual::$lpar_state" . "::" . "$vios_type" . ":::" . "$managed_system:$lparenv:$lpar_rmc_ipaddr");
            print("$lpar_name:$lpar_name.ibr.ssm.sdc.com:VIO:$location:VIO:VIO_$location:Virtual::$lpar_state" . "::" . "$vios_type" . ":::" . "$managed_system:$lparenv:$lpar_rmc_ipaddr");
        }
        elsif($line =~ m/aixlinux/i && $line =~ m/tsm/i && $line =~ m/ccpx/i)
        {
            my $has_vios = `ssh -l hscroot -o ConnectTimeout=45 -q -o ConnectionAttempts=1 $hmc "lssyscfg -r lpar -m $managed_system -F name:lpar_env:state| grep -c vioserver"`;
            chomp($has_vios);

            if($has_vios eq "0")
            {
                $tsm_type = "Physical";
            }
            else
            {
                $tsm_type = "Virtual";
            }

            if((substr $lpar_name,-1) eq "a")
            {
                $location = "INFRA";
            }
            elsif((substr $lpar_name, -1) == "1")
            {
                $location = "POD1";
            }
            elsif((substr $lpar_name, -1) == "2")
            {
                $location = "POD2";
            }
            else
            {
                $location = "POD";
            }
            write2file("$lpar_name:$lpar_name.ssm.com:AIX:$location:TSM:TSM_$location:".$tsm_type."::$lpar_state" . "::" . "Tivoli Storage Manager" . ":::" . "$managed_system:$lparenv:$lpar_rmc_ipaddr");
            print("$lpar_name:$lpar_name.ssm.sdc.com:AIX:$location:TSM:TSM_$location:".$tsm_type."::$lpar_state" . "::" . "Tivoli Storage Manager" . ":::" . "$managed_system:$lparenv:$lpar_rmc_ipaddr");
        }
    }
}
1;

if($#ARGV < 0)
{
    die("No hmc specified");
}

my @threads;
my @a_hmc;
@a_hmc = @ARGV;
for my $i (@a_hmc)
{
    my $object = DsadmHostDBUpdate->new($i);
    push @threads, threads::async { $object->get_vios_list() }
}

foreach(@threads)
{
    $_->threads::join();
}
