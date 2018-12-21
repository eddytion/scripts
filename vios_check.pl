#!/usr/bin/perl

system("clear");

# Legenda
# a_ ... array
# h_ ... hash
# s_ ... string
# i_ ... integer
# r_ ... reference

my $hostname = `uname -n | cut -f 1 -d .`;
chomp($hostname);
my $file = '/tmp/'.$hostname .'_params.csv';
unlink($file) if -e $file;
my @a_values;

sub get_params {
    my $swap = `lsps -s | grep % | awk {'print \$1'} | sed 's/MB//g'`;
    chomp($swap);
    push(@a_values,"SWAP,$hostname,$swap");
    
    my $memory = `lsattr -El mem0 -a size | awk {'print \$2'}`;
    chomp($memory);
    push(@a_values,"MEMORY,$hostname,$memory");
    
    my @a_phys_ent = `lsdev -Ccadapter | grep ent | egrep -v "Logical Host Ethernet Port|Virtual I/O Ethernet Adapter|EtherChannel / IEEE 802.3ad|Shared Ethernet Adapter" | awk {'print \$1'}`;
    chomp(@a_phys_ent);
    
    if(scalar(@a_phys_ent))
    {
        foreach my $ent (@a_phys_ent)
        {
            my @a_params = `lsattr -El $ent -a chksum_offload -a jumbo_frames -a flow_ctrl -a flow_control -a large_receive -a large_send 2> /dev/null | awk {'print \$2'} | tr '\\n' ',' | sed 's/.\$//g'`;
            chomp(@a_params);
            for my $element (@a_params)
            {
                my ($checksum_offload, $jumbo_frames, $flow_ctrl, $large_receive, $large_send) = split(/\,/,$element);
                push(@a_values,"ENT,$hostname,$ent,$checksum_offload,$jumbo_frames,$flow_ctrl,$large_receive,$large_send");
            }
        }
    }
    
    my @a_ieee = `lsdev -Ccadapter | grep ent | grep IEEE | awk {'print \$1'}`;
    chomp(@a_ieee);
    
    if(scalar(@a_ieee))
    {
        foreach my $ieee (@a_ieee)
        {
            my @a_params = `lsattr -El $ieee -a hash_mode -a interval -a mode -a use_jumbo_frame | awk {'print \$2'} | tr '\\n' ',' | sed 's/.\$//g'`;
            chomp(@a_params);
            for my $element (@a_params)
            {
                my ($hash_mode, $interval, $mode, $use_jumbo_frame) = split(/\,/,$element);
                push(@a_values,"IEEE,$hostname,$ieee,$hash_mode,$interval,$mode,$use_jumbo_frame");
            }
        }
    }
    
    my @a_virt_en = `lsdev | grep en | grep -v ent | grep Ethernet | grep Available | awk {'print \$1'}`;
    chomp(@a_virt_en);
    
    if(scalar(@a_virt_en))
    {
        foreach my $en (@a_virt_en)
        {
            my @a_params = `lsattr -El $en -a mtu_bypass -a rfc1323 -a tcp_sendspace -a tcp_recvspace | awk {'print \$2'} | tr '\\n' ',' | sed 's/.\$//g'`;
            chomp(@a_params);
            my $udp_sendspace = `no -o udp_sendspace | awk {'print \$3'}`;
            my $udp_recvspace = `no -o udp_recvspace | awk {'print \$3'}`;
            chomp($udp_sendspace, $udp_recvspace);
            
            for my $element (@a_params)
            {
                my ($mtu_bypass,$rfc1323,$tcp_sendspace,$tcp_recvspace) = split(/\,/,$element);
                push(@a_values,"VETH,$hostname,$en,$mtu_bypass,$rfc1323,$tcp_sendspace,$tcp_recvspace,$udp_recvspace,$udp_sendspace");
            }
        }
    }
    
    my @a_seas = `lsdev -Ccadapter | grep "Shared Ethernet Adapter" | awk {'print \$1'}`;
    chomp(@a_seas);
    
    if(scalar(@a_seas))
    {
        foreach my $sea (@a_seas)
        {
            my @a_params = `lsattr -El $sea -a largesend -a large_receive -a jumbo_frames -a adapter_reset -a accounting -a ha_mode | awk {'print \$2'} | tr '\\n' ',' | sed 's/.\$//g'`;
            chomp(@a_params);
            
            for my $element (@a_params)
            {
                my ($largesend, $large_receive_sea, $jumbo_frames_sea, $adapter_reset, $accounting, $ha_mode) = split(/\,/,$element);
                push(@a_values,"SEA,$hostname,$sea,$largesend,$large_receive_sea,$jumbo_frames_sea,$adapter_reset,$accounting,$ha_mode");
            }
        }
    }
    
    my @a_virt_adapters = `lsdev -Ccadapter | grep ent | grep "Virtual I/O Ethernet Adapter" | awk {'print \$1'}`;
    chomp(@a_virt_adapters);
    
    if(scalar(@a_virt_adapters))
    {
        foreach my $adapt (@a_virt_adapters)
        {
            my @a_params = `lsattr -El $adapt -a min_buf_tiny -a max_buf_tiny -a min_buf_small -a max_buf_small -a min_buf_medium -a max_buf_medium -a min_buf_large -a max_buf_large -a min_buf_huge -a max_buf_huge | awk {'print \$2'} | tr '\\n' ',' | sed 's/.\$//g'`;
            chomp(@a_params);
            
            for my $element (@a_params)
            {
                my ($min_buf_tiny,$max_buf_tiny,$min_buf_small,$max_buf_small,$min_buf_medium,$max_buf_medium,$min_buf_large,$max_buf_large,$min_buf_huge,$max_buf_huge) = split(/\,/,$element);
                push(@a_values,"VETH_BUF,$hostname,$adapt,$min_buf_tiny,$max_buf_tiny,$min_buf_small,$max_buf_small,$min_buf_medium,$max_buf_medium,$min_buf_large,$max_buf_large,$min_buf_huge,$max_buf_huge");
            }
        }
    }
    
    my @a_fscsi = `lsdev | grep fscsi | awk {'print \$1'}`;
    chomp(@a_fscsi);
    
    if(scalar(@a_fscsi))
    {
        foreach my $fscsi_adapter (@a_fscsi)
        {
            my @a_params = `lsattr -El $fscsi_adapter -a fc_err_recov -a dyntrk | awk {'print \$2'} | tr '\\n' ',' | sed 's/.\$//g'`;
            chomp(@a_params);
            
            for my $element (@a_params)
            {
                my ($fc_err_recov,$dyntrk) = split(/\,/,$element);
                push(@a_values,"FSCSI,$hostname,$fscsi_adapter,$fc_err_recov,$dyntrk");
            }
        }
    }
    
    my @a_fcs = `lsdev -Ccadapter | grep fcs | grep -v FCoE | awk {'print \$1'}`;
    chomp(@a_fcs);
    
    if(scalar(@a_fcs))
    {
        foreach my $fcs_adapter (@a_fcs)
        {
            my @a_params = `lsattr -El $fcs_adapter -a max_xfer_size -a num_cmd_elems | awk {'print \$2'} | tr '\\n' ',' | sed 's/.\$//g'`;
            chomp(@a_params);
            
            for my $element (@a_params)
            {
                my ($max_xfer_size,$num_cmd_elems) = split(/\,/,$element);
                push(@a_values,"FCS,$hostname,$fcs_adapter,$max_xfer_size,$num_cmd_elems");
            }
        }
    }
    
    my $vioslpm0 = `lsattr -El vioslpm0 -a auto_tunnel | awk {'print \$2'}`;
    chomp($vioslpm0);
    push(@a_values,"LPM,$hostname,$vioslpm0");
    
    my @a_disks = `lspv -u | grep fcp | awk {'print \$1'}`;
    chomp(@a_disks);
    
    if(scalar(@a_disks))
    {
        foreach my $disk (@a_disks)
        {
            my @a_params = `lsattr -El $disk -a rw_timeout -a queue_depth -a algorithm -a timeout_policy -a reserve_policy -a dist_tw_width -a dist_err_pcnt -a hcheck_interval | awk {'print \$2'} | tr '\\n' ',' | sed 's/.\$//g'`;
            chomp(@a_params);
            
            for my $element (@a_params)
            {
                my ($rw_timeout,$queue_depth,$algorithm,$timeout_policy,$reserve_policy,$dist_tw_width,$dist_err_pcnt,$hcheck_interval) = split(/\,/,$element);
                push(@a_values,"DISK,$hostname,$disk,$rw_timeout,$queue_depth,$algorithm,$timeout_policy,$reserve_policy,$dist_tw_width,$dist_err_pcnt,$hcheck_interval");
            }
        }
    }
    
    open(FILEHANDLE, ">$file");
    $, = "\n";
    print FILEHANDLE @a_values;
    close FILEHANDLE;
}

get_params;
