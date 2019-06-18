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
open(my $fhkey, '>', $idfile) or die("Unable to write private key to disk");
print($fhkey $identity);
close($fhkey);
chmod 0400, $idfile;

my $ssh_opts = " -i $idfile -o StrictHostKeyChecking=no -o ConnectTimeout=5 -q -o ConnectionAttempts=1 ";

my $server_list = $ARGV[0];
my $bf_version = "9.5.8.38";
my $ssh_user = "padmin";
my $logfile = "/tmp/Besclient_install.log";
my @servers;
my @threads;

sub logging {
    my $msg_type = shift;
    my $color;
    if($msg_type eq "INFO"){
        $color = "\033[0m";
    }elsif($msg_type eq "ERROR"){
        $color = "\033[91m";
    }elsif($msg_type eq "UNKN"){
        $color = "\033[96m";
    }elsif($msg_type eq "WARN"){
        $color = "\033[93m";
    }elsif($msg_type eq "OK"){
        $color = "\033[92m";
    }else{
        $color = "\033[0m";
    }
    my $msg = shift;
    my $timestamp=`date +"%Y-%m-%d %H:%M:%S"`;
    chomp($timestamp);
    print "$color [$timestamp] $msg_type:\t$msg \033[0m \n";
    open(my $fstream, '>>', $logfile);
    print $fstream "[$timestamp]" . $msg_type . "\t" . $msg . "\n";
    close($fstream);
}

sub trim($)
{
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}

if($#ARGV != 1)
{
    logging("ERROR","Missing parameters, you have to specify a file with servers and a site code");
    logging("INFO","Site codes: ABN BAR BLD EHN FAR HRT MOP POK RTP SYD TOK TOR WIN");
    logging("ERROR","Each server must be on a separate line");
    exit(1);
}
else
{
    open(my $fh, '<:encoding(UTF-8)', $server_list) or die "Could not open file '$server_list' $!";
    while (my $row = <$fh>) {
        chomp $row;
        push(@servers, trim($row));
    }
}

my $server_site = uc($ARGV[1]);
my $cfg_file = "/sds/local/sceplus/agents/TEM/$server_site" . "_PROD/besclient.config";
my $actionsite_file = "/sds/local/sceplus/agents/TEM/$server_site" . "_PROD/actionsite.afxm";

sub install_BESClient($)
{
    my $server = shift;
    logging("INFO","Checking if BESClient is already installed on $server");
    my $bf_check = `ssh $ssh_opts -q -l $ssh_user $server "ioscli lssw | grep BESClient | awk {'print \\\$2'}"`;
    chomp($bf_check);
    if($? >> 8 == 0)
    {
        logging("OK","Successfully checked BESClient installation on $server");
        if($bf_check ne "")
        {
            logging("INFO","BESClient is already installed on $server. Version installed: $bf_check");
        }
        else
        {
            logging("WARN","BESClient is not installed on $server");
            my $check_sds_mountpoint = `ssh $ssh_opts -q -l $ssh_user $server "ls -ld /sds"`; chomp($check_sds_mountpoint);
            if($check_sds_mountpoint =~ m/\/sds/) {
                logging("INFO","/sds is present on $server");
            }
            else
            {
                logging("ERROR","/sds is not present on $server");
            }
            my $check_sds_mounted = `ssh $ssh_opts -q -l $ssh_user $server "echo mount | oem_setup_env | grep -wc /sds"`; chomp($check_sds_mounted);
            if($check_sds_mounted > 0 && $check_sds_mounted ne ""){
                logging("INFO","/sds is mounted on $server");
            }
            else
            {
                logging("ERROR","/sds is not mounted on $server");
            }

            my $check_cfg_files = `ssh $ssh_opts -q -l $ssh_user $server "ls -l $cfg_file | grep -c config"`;
            chomp($check_cfg_files);
            if($check_cfg_files eq "1" && $check_cfg_files ne "")
            {
                logging("OK","BESClient config file is present in $cfg_file");
            }
            else
            {
                logging("ERROR","Cannot find BESClient config in $cfg_file");
            }

            my $check_actionsite_file = `ssh $ssh_opts -q -l $ssh_user $server "ls -l $actionsite_file | grep -c afxm"`;
            chomp($check_actionsite_file);
            if($check_actionsite_file eq "1" && $check_actionsite_file ne "")
            {
                logging("OK","BESClient actionsite file is present in $actionsite_file");
            }
            else
            {
                logging("ERROR","Cannot find BESClient actionsite in $actionsite_file");
            }

            my $check_sds_bf_package_exists = `ssh $ssh_opts -q -l $ssh_user $server "ls -l /sds/local/sceplus/agents/TEM/BESAgent-$bf_version.ppc64_aix61.pkg | grep -c aix"`; chomp($check_sds_bf_package_exists);
            if($check_sds_bf_package_exists eq "1"){
                logging("OK","BESClient package exists on /sds/local/sceplus/agents/TEM/BESAgent-$bf_version.ppc64_aix61.pkg");
                logging("INFO","Attempting to run a preview installation of BESClient on $server");
                my $install_preview = `ssh $ssh_opts -q -l $ssh_user $server "echo \"installp -apY -d /sds/local/sceplus/agents/TEM/ BESClient $bf_version\" | oem_setup_env"`;
                if($install_preview =~ m/Passed pre-installation verification/i)
                {
                    logging("OK","BESClient preview install on $server was successful");
                    logging("INFO","Attempting to install BESClient on $server");
                    `ssh $ssh_opts -q -l $ssh_user $server "echo \"mkdir -p /etc/opt/BESClient /var/opt/BESClient\" | oem_setup_env`;
                    if($? >> 8 == 0)
                    {
                        logging("OK","Successfully created BESClient directories on $server");
                        `ssh $ssh_opts -q -l $ssh_user $server "echo \"cp $actionsite_file /etc/opt/BESClient/\" | oem_setup_env"`;
                        if($? >> 8 == 0)
                        {
                            logging("OK","Successfully copied $actionsite_file on $server");
                            `ssh -q -l $ssh_opts $server "echo \"cp $cfg_file /var/opt/BESClient/besclient.config\" | oem_setup_env"`;
                            if($? >> 8 == 0)
                            {
                                logging("OK","Successfully copied $cfg_file on $server");
                                `ssh $ssh_opts -q -l $ssh_user $server "echo \"installp -aXY -d /sds/local/sceplus/agents/TEM/ BESClient $bf_version\" | oem_setup_env"`;
                                if($? >> 8 == 0)
                                {
                                    logging("OK","Successfully installed BESClient on $server");
                                    `ssh $ssh_opts -q -l $ssh_user $server "echo \"/etc/rc.d/rc2.d/SBESClientd start\" | oem_setup_env"`;
                                    if($? >> 8 == 0)
                                    {
                                        logging("OK","Successfully started BESClient on $server");
                                    }
                                    else
                                    {
                                        logging("ERROR","An error occurred on $server while trying to start BESClient");
                                    }
                                }
                                else
                                {
                                    logging("ERROR","An error occurred while trying to install BESClient on $server");
                                }
                            }
                            else
                            {
                                logging("ERROR","An error occurred while copying $cfg_file on $server");
                            }
                        }
                        else
                        {
                            logging("ERROR","An error occurred while copying $actionsite_file on $server");
                        }
                    }
                    else
                    {
                        logging("ERROR","An error occurred while creating directories on $server");
                    }
                }
                else{
                    logging("ERROR","BESClient failed preview install on $server");
                }
            }
            else
            {
                logging("ERROR","BESClient package does not exist on /sds/local/sceplus/agents/TEM/BESAgent-$bf_version.ppc64_aix61.pkg");
            }
        }
    }
    else
    {
        my $rc = $? >> 8;
        logging("ERROR","An error occurred for $server while connecting, SSH return code is $rc");
    }
}

for my $i (@servers)
{
    push @threads, threads::async { install_BESClient($i) }
}

foreach(@threads)
{
    $_->threads::join();
}
