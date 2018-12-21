<?php
require("header.php");
error_reporting(E_ALL);
ini_set('display_errors', 1);
?>
<div class="row">
<?php
    require 'config_dashboard.php';
    
    $vios_list = array();
    $defects = array();
    
    $query = "SELECT lparname FROM memory";
    $result = mysqli_query($db, $query);
    while($row = mysqli_fetch_assoc($result))
    {
        array_push($vios_list, $row['lparname']);
    }
    foreach ($vios_list as $value)
    {   
        $query_lpm = "SELECT * FROM lpm WHERE lparname='{$value}' AND status!=0";
        $result_lpm = mysqli_query($db, $query_lpm);
        while($row_lpm = mysqli_fetch_assoc($result_lpm))
        {
            array_push($defects, $row_lpm['lparname']);
        }
        
        $query_disk = "SELECT * FROM disk WHERE lparname='{$value}'";
        $result_disk = mysqli_query($db, $query_disk);
        while($row_disk = mysqli_fetch_assoc($result_disk))
        {
            if($row_disk['rw_timeout'] != 30 || $row_disk['queue_depth'] != 20 || $row_disk['algorithm'] != "shortest_queue" || $row_disk['timeout_policy'] != "fail_ctlr"
                    || $row_disk['reserve_policy'] != "no_reserve" || $row_disk['dist_tw_width'] != 10 || $row_disk['dist_err_pcnt'] != 1 || $row_disk['hcheck_interval'] != 180)
            {
                array_push($defects, $row_disk['lparname']);
            }
        }
        
        $query_fcs = "SELECT * FROM fcs WHERE lparname='{$value}' AND (max_xfer_size !='0x1000000' AND num_cmd_elems !='1024')";
        $result_fcs = mysqli_query($db, $query_fcs);
        while($row_fcs = mysqli_fetch_assoc($result_fcs))
        {
            array_push($defects, $row_fcs['lparname']);
        }
        
        $query_fscsi = "SELECT * FROM fscsi WHERE lparname='{$value}'";
        $result_fscsi = mysqli_query($db, $query_fscsi);
        while($row_fscsi = mysqli_fetch_assoc($result_fscsi))
        {
            if($row_fscsi['fc_err_recov'] != "fast_fail" || $row_fscsi['dyntrk'] != "yes")
            {
                array_push($defects, $row_fscsi['lparname']);
            }
        }
        
        $query_ieee = "SELECT * FROM ieee WHERE lparname='{$value}'";
        $result_ieee = mysqli_query($db, $query_ieee);
        while($row_ieee = mysqli_fetch_assoc($result_ieee))
        {
            if($row_ieee['hash_mode'] != "src_dst_port" || $row_ieee['s_interval'] != "short" || $row_ieee['mode'] != "8023ad" || $row_ieee['jumbo_frames'] != "yes")
            {
                array_push($defects, $row_ieee['lparname']);
            }
        }
        
        $query_swap = "SELECT swap.lparname as lparname, swap.swapsize as swapsize, memory.memorysize as memorysize FROM swap JOIN memory ON swap.lparname=memory.lparname WHERE swap.lparname='{$value}'";
        $result_swap = mysqli_query($db, $query_swap);
        while($row_swap = mysqli_fetch_assoc($result_swap))
        {
            if($row_swap['swapsize'] != ($row_swap['memorysize'] + 512))
            {
                array_push($defects, $row_swap['lparname']);
            }
        }
        
        $query_phys_ent = "SELECT * FROM phys_eth WHERE lparname='{$value}'";
        $result_phys_ent = mysqli_query($db, $query_phys_ent);
        while($row_phys_ent = mysqli_fetch_assoc($result_phys_ent))
        {
            if($row_phys_ent['checksum_offload'] != "yes" || $row_phys_ent['flow_ctrl'] != "yes" || $row_phys_ent['large_receive'] != "yes"
                    || $row_phys_ent['largesend'] != "yes")
            {
                array_push($defects, $row_phys_ent['lparname']);
            }
        }
        
        $query_sea = "SELECT * FROM sea WHERE lparname='{$value}'";
        $result_sea = mysqli_query($db, $query_sea);
        while($row_sea = mysqli_fetch_assoc($result_sea))
        {
        if($row_sea['largesend'] != 1 || $row_sea['large_receive'] != "yes" || $row_sea['adapter_reset'] != "no" || $row_sea['accounting'] != "enabled"
                || ($row_sea['ha_mode'] != "auto" || $row_sea['ha_mode'] != "sharing"))
            {
                array_push($defects, $row_sea['lparname']);
            }
        }
        
        $query_veth = "SELECT * FROM veth WHERE lparname='{$value}'";
        $result_veth = mysqli_query($db, $query_veth);
        while($row_veth = mysqli_fetch_assoc($result_veth))
        {
            if($row_veth['mtu_bypass'] != "on" || $row_veth['rfc1323'] != 1 || $row_veth['tcp_sendspace'] != 524288 || $row_veth['tcp_recvspace'] != 524288 || $row_veth['udp_recvspace'] != 655360
                    || $row_veth['udp_sendspace'] != 65536)
            {
                array_push($defects, $row_veth['lparname']);
            }
        }
        
        $query_veth_buf = "SELECT * FROM veth_buf WHERE lparname='{$value}'";
        $result_veth_buf = mysqli_query($db, $query_veth_buf);
        while($row_veth_buf = mysqli_fetch_assoc($result_veth_buf))
        {
            if($row_veth_buf['min_buf_tiny'] != "4096" || $row_veth_buf['max_buf_tiny'] != 4096 || $row_veth_buf['min_buf_small'] != 4096 || $row_veth_buf['max_buf_small'] != 4096
                    || $row_veth_buf['min_buf_medium'] != 1024 || $row_veth_buf['max_buf_medium'] != 1024 || $row_veth_buf['min_buf_large'] != 256 || $row_veth_buf['max_buf_large'] != 256
                    || $row_veth_buf['min_buf_huge'] != 128 || $row_veth_buf['max_buf_huge'] != 128)
            {
                array_push($defects, $row_veth_buf['lparname']);
            }
        }
    }

    $sorted_errors = array_unique($defects);
    $sorted_ok = array_diff($vios_list, $sorted_errors);
    foreach ($sorted_errors as $value)
    {
        print "
            <div class=\"col-sm-2\">
                <div class=\"card border-danger mb-3\">
                  <div class=\"card-body text-danger\">
                    <h5 class=\"card-title\">{$value}</h5>
                    <p class=\"card-text\">There are values not matching the CMS VIO build standards document. Click on details to find more</p>
                    <a href=\"#viosDetails\" data-toggle=\"modal\" data-viosname=\"{$value}\" class=\"btn-link\">Details</a>
                        |
                    <a href=\"vios_report.php?name={$value}\" target=\"_blank\" class=\"btn-link\">Report</a>
                  </div>
                </div>
            </div>
            ";
    }
    
    foreach ($sorted_ok as $value)
    {
        print "
            <div class=\"col-sm-2\">
                <div class=\"card border-success mb-3\">
                  <div class=\"card-body text-success\">
                    <h5 class=\"card-title\">{$value}</h5>
                    <p class=\"card-text\">All values are matching the CMS VIO build standards document</p>
                    <a href=\"#viosDetails\" data-toggle=\"modal\" data-viosname=\"{$value}\" class=\"btn-link\">Details</a>
                        |
                    <a href=\"vios_report.php?name={$value}\" target=\"_blank\" class=\"btn-link\">Report</a>
                  </div>
                </div>
            </div>
        ";
    }
?>    
</div>
<style>
    .modal-lg {
        max-width: 70% !important;
    }
</style>
<!-- Modal -->
<div class="modal fade" id="viosDetails" tabindex="-1" role="dialog" aria-labelledby="exampleModalLabel" aria-hidden="true">
  <div class="modal-dialog modal-lg" role="document">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="exampleModalLabel">Details</h5>
        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
          <span aria-hidden="true">&times;</span>
        </button>
      </div>
      <div class="modal-body" id="vios_details">
        ...
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
      </div>
    </div>
  </div>
</div>

<script>
$(document).ready(function(){ 
 $(".btn-link").on('click',function(){
    var vios = $(this).attr('data-viosname');

    $('.modal-body').html('loading');

       $.ajax({
        method: 'GET',
        url: 'vios_data.php',
        data: {vios: vios},
        success: function(data) {
          $('#vios_details').html(data);
          $('#viosDetails').modal("show");
        },
        error:function(err){
          alert("error"+JSON.stringify(err));
          console.log(err.message);
        }
    });
 });
});
</script>