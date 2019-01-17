<?php
require("header.php");
error_reporting(E_ALL);
ini_set('display_errors', 1);
require 'config_dashboard.php';
$vios = mysqli_real_escape_string($db,$_GET['name']);

//FCS Table

$query_fcs = "SELECT * FROM fcs WHERE lparname='{$vios}'";
$result_fcs = mysqli_query($db, $query_fcs);
if (mysqli_num_rows($result_fcs) > 0) {
    echo "<table class=\"table table-hover table-striped\" width=\"100%\">";
    echo "<thead>";
    echo "<tr>";
    echo "<th>VM Name</th>
                      <th>Adapter</th>
                      <th>Max xfer size</th>
                      <th>Num cmd elems</th>
                      </thead></tr>
                      <tbody>";
    while ($row_fcs = mysqli_fetch_assoc($result_fcs)) {
        echo "<tr>";
        echo "<td>{$row_fcs['lparname']}</td>";
        echo "<td>{$row_fcs['adapter']}</td>";
        echo "<td>{$row_fcs['max_xfer_size']}</td>";
        echo "<td>{$row_fcs['num_cmd_elems']}</td>";
        echo "</tr>";
    }
    echo "</tbody></table>";
}

//FSCSI Table

$query_fscsi = "SELECT * FROM fscsi WHERE lparname='{$vios}'";
$result_fscsi = mysqli_query($db, $query_fscsi);
if (mysqli_num_rows($result_fscsi) > 0) {
    echo "<table class=\"table table-hover table-striped\" width=\"100%\">";
    echo "<thead>";
    echo "<tr>";
    echo "<th>VM Name</th>
                      <th>Adapter</th>
                      <th>FC err recov</th>
                      <th>Dyntrk</th>
                      </thead></tr>
                      <tbody>";
    while ($row_fscsi = mysqli_fetch_assoc($result_fscsi)) {
        echo "<tr>";
        echo "<td>{$row_fscsi['lparname']}</td>";
        echo "<td>{$row_fscsi['adapter']}</td>";
        echo "<td>{$row_fscsi['fc_err_recov']}</td>";
        echo "<td>{$row_fscsi['dyntrk']}</td>";
        echo "</tr>";
    }
    echo "</tbody></table>";
}

//IEEE Table

$query_ieee = "SELECT * FROM ieee WHERE lparname='{$vios}'";
$result_ieee = mysqli_query($db, $query_ieee);
if (mysqli_num_rows($result_ieee) > 0) {
    echo "<table class=\"table table-hover table-striped\" width=\"100%\">";
    echo "<thead>";
    echo "<tr>";
    echo "<th>VM Name</th>
                      <th>Adapter</th>
                      <th>Hash mode</th>
                      <th>Interval</th>
                      <th>Mode</th>
                      <th>Jumbo frames</th>
                      </thead></tr>
                      <tbody>";
    while ($row_ieee = mysqli_fetch_assoc($result_ieee)) {
        echo "<tr>";
        echo "<td>{$row_ieee['lparname']}</td>";
        echo "<td>{$row_ieee['adapter']}</td>";
        if($row_ieee['hash_mode'] != "src_dst_port")
        {
            echo "<td class=\"table-warning\">{$row_ieee['hash_mode']}</td>";
        }
        else
        {
            echo "<td class=\"table-success\">{$row_ieee['hash_mode']}</td>";
        }
        if($row_ieee['s_interval'] != "short")
        {
            echo "<td class=\"table-warning\">{$row_ieee['s_interval']}</td>";
        }
        else
        {
            echo "<td class=\"table-success\">{$row_ieee['s_interval']}</td>";
        }
        if($row_ieee['mode'] != "8023ad")
        {
            echo "<td class=\"table-warning\">{$row_ieee['mode']}</td>";
        }
        else
        {
            echo "<td class=\"table-success\">{$row_ieee['mode']}</td>";
        }
        if($row_ieee['jumbo_frames'] == "yes")
        {
            echo "<td class=\"table-success\">{$row_ieee['jumbo_frames']}</td>";
        }
        else
        {
            echo "<td class=\"table-warning\">{$row_ieee['jumbo_frames']}</td>";
        }
        echo "</tr>";
    }
    echo "</tbody></table>";
}

// SWAP Table

$query_swap = "SELECT swap.lparname as lparname, swap.swapsize as swapsize, memory.memorysize as memorysize FROM swap JOIN memory ON swap.lparname=memory.lparname WHERE swap.lparname='{$vios}'";
$result_swap = mysqli_query($db, $query_swap);
if (mysqli_num_rows($result_swap) > 0) {
    echo "<table class=\"table table-hover table-striped\" width=\"100%\">";
    echo "<thead>";
    echo "<tr>";
    echo "<th>VM Name</th>
                      <th>Memory</th>
                      <th>Swap (memory + 512MB)</th>
                      </thead></tr>
                      <tbody>";
    while ($row_swap = mysqli_fetch_assoc($result_swap)) {
        echo "<tr>";
        echo "<td>{$row_swap['lparname']}</td>";
        echo "<td>{$row_swap['memorysize']}</td>";
        if($row_swap['swapsize'] != ($row_swap['memorysize']+512))
        {
            echo "<td class=\"table-warning\">{$row_swap['swapsize']}</td>";
        }
        else
        {
            echo "<td class=\"table-success\">{$row_swap['swapsize']}</td>";
        }
        echo "</tr>";
    }
    echo "</tbody></table>";
}

// Phys Ethernet Table

$query_phys_ent = "SELECT * FROM phys_eth WHERE lparname='{$vios}'";
$result_phys_ent = mysqli_query($db, $query_phys_ent);
if (mysqli_num_rows($result_phys_ent) > 0) {
    echo "<table class=\"table table-hover table-striped\" width=\"100%\">";
    echo "<thead>";
    echo "<tr>";
    echo "<th>VM Name</th>
                      <th>Adapter</th>
                      <th>Checksum Offload</th>
                      <th>Jumbo Frames</th>
                      <th>Flow Ctrl</th>
                      <th>Large receive</th>
                      <th>Large send</th>
                      </thead></tr>
                      <tbody>";
    while ($row_phys_ent = mysqli_fetch_assoc($result_phys_ent)) {
        echo "<tr>";
        echo "<td>{$row_phys_ent['lparname']}</td>";
        echo "<td>{$row_phys_ent['ent']}</td>";
        echo "<td>{$row_phys_ent['checksum_offload']}</td>";
        echo "<td>{$row_phys_ent['jumbo_frames']}</td>";
        echo "<td>{$row_phys_ent['flow_ctrl']}</td>";
        echo "<td>{$row_phys_ent['large_receive']}</td>";
        echo "<td>{$row_phys_ent['largesend']}</td>";
        echo "</tr>";
    }
    echo "</tbody></table>";
}

// SEA Table

$query_sea = "SELECT * FROM sea WHERE lparname='{$vios}'";
$result_sea = mysqli_query($db, $query_sea);
if (mysqli_num_rows($result_sea) > 0) {
    echo "<table class=\"table table-hover table-striped\" width=\"100%\">";
    echo "<thead>";
    echo "<tr>";
    echo "<th>VM Name</th>
                      <th>Adapter</th>
                      <th>Large send</th>
                      <th>Large receive</th>
                      <th>Jumbo Frames</th>
                      <th>Adapter reset</th>
                      <th>Accounting</th>
                      <th>HA Mode</th>
                      </thead></tr>
                      <tbody>";
    while ($row_sea = mysqli_fetch_assoc($result_sea)) {
        echo "<tr>";
        echo "<td>{$row_sea['lparname']}</td>";
        echo "<td>{$row_sea['ent']}</td>";
        if($row_sea['largesend'] == 1)
        {
            echo "<td class=\"table-success\">{$row_sea['largesend']}</td>";
        }
        else
        {
            echo "<td class=\"table-warning\">{$row_sea['largesend']}</td>";
        }
        if($row_sea['large_receive'] != "yes")
        {
            echo "<td class=\"table-warning\">{$row_sea['large_receive']}</td>";
        }
        else
        {
            echo "<td class=\"table-success\">{$row_sea['large_receive']}</td>";
        }
        if($row_sea['jumbo_frames'] != "yes")
        {
            echo "<td class=\"table-warning\">{$row_sea['jumbo_frames']}</td>";
        }
        else
        {
            echo "<td class=\"table-success\">{$row_sea['jumbo_frames']}</td>";
        }
        if($row_sea['adapter_reset'] != "no")
        {
            echo "<td class=\"table-warning\">{$row_sea['adapter_reset']}</td>";   
        }
        else
        {
            echo "<td class=\"table-success\">{$row_sea['adapter_reset']}</td>";
        }
        if($row_sea['accounting'] != "enabled")
        {
            echo "<td class=\"table-warning\">{$row_sea['accounting']}</td>";
        }
        else
        {
            echo "<td class=\"table-success\">{$row_sea['accounting']}</td>";
        }
        if($row_sea['ha_mode'] == "standby")
        {
            echo "<td class=\"table-warning\">{$row_sea['ha_mode']}</td>";
        }
        else
        {
            echo "<td class=\"table-success\">{$row_sea['ha_mode']}</td>";
        }
        echo "</tr>";
    }
    echo "</tbody></table>";
}

// VETH Table

$query_veth = "SELECT * FROM veth WHERE lparname='{$vios}'";
$result_veth = mysqli_query($db, $query_veth);
if (mysqli_num_rows($result_veth) > 0) {
    echo "<table class=\"table table-hover table-striped\" width=\"100%\">";
    echo "<thead>";
    echo "<tr>";
    echo "<th>VM Name</th>
                      <th>Adapter</th>
                      <th>MTU Bypass</th>
                      <th>rfc1323</th>
                      <th>TCP Sendspace</th>
                      <th>TCP Recvspace</th>
                      <th>UDP Recvspace</th>
                      <th>UDP Sendspace</th>
                      </thead></tr>
                      <tbody>";
    while ($row_veth = mysqli_fetch_assoc($result_veth)) {
        echo "<tr>";
        echo "<td>{$row_veth['lparname']}</td>";
        echo "<td>{$row_veth['adapter']}</td>";
        if($row_veth['mtu_bypass'] != "on")
        {
            echo "<td class=\"table-warning\">{$row_veth['mtu_bypass']}</td>";
        }
        else
        {
            echo "<td class=\"table-success\">{$row_veth['mtu_bypass']}</td>";
        }
        if($row_veth['rfc1323'] != "1")
        {
            echo "<td class=\"table-warning\">{$row_veth['rfc1323']}</td>";
        }
        else
        {
            echo "<td class=\"table-success\">{$row_veth['rfc1323']}</td>";
        }
        if($row_veth['tcp_sendspace'] != "524288")
        {
            echo "<td class=\"table-warning\">{$row_veth['tcp_sendspace']}</td>";
        }
        else
        {
            echo "<td class=\"table-success\">{$row_veth['tcp_sendspace']}</td>";
        }
        if($row_veth['tcp_recvspace'] != "524288")
        {
            echo "<td class=\"table-warning\">{$row_veth['tcp_recvspace']}</td>";
        }
        else
        {
            echo "<td class=\"table-success\">{$row_veth['tcp_recvspace']}</td>";
        }
        if($row_veth['udp_recvspace'] != "655360")
        {
            echo "<td class=\"table-warning\">{$row_veth['udp_recvspace']}</td>";
        }
        else
        {
            echo "<td class=\"table-success\">{$row_veth['udp_recvspace']}</td>";
        }
        if($row_veth['udp_sendspace'] != "65536")
        {
            echo "<td class=\"table-warning\">{$row_veth['udp_sendspace']}</td>";
        }
        else
        {
            echo "<td class=\"table-success\">{$row_veth['udp_sendspace']}</td>";
        }
        echo "</tr>";
    }
    echo "</tbody></table>";
}

// VETH Buffers

$query_veth_buf = "SELECT * FROM `veth_buf` WHERE lparname='{$vios}'";
$result_veth_buf = mysqli_query($db, $query_veth_buf);
if (mysqli_num_rows($result_veth_buf) > 0) {
    echo "<table class=\"table table-hover table-striped\" width=\"100%\">";
    echo "<thead>";
    echo "<tr>";
    echo "<th>VM Name</th>
                      <th>Adapter</th>
                      <th>min_buf_tiny</th>
                      <th>max_buf_tiny</th>
                      <th>min_buf_small</th>
                      <th>max_buf_small</th>
                      <th>min_buf_medium</th>
                      <th>max_buf_medium</th>
                      <th>min_buf_large</th>
                      <th>max_buf_large</th>
                      <th>min_buf_huge</th>
                      <th>max_buf_huge</th>
                      </thead></tr>
                      <tbody>";
    while ($row_veth_buf = mysqli_fetch_assoc($result_veth_buf)) {
        echo "<tr>";
        echo "<td>{$row_veth_buf['lparname']}</td>";
        echo "<td>{$row_veth_buf['adapter']}</td>";
        echo "<td>{$row_veth_buf['min_buf_tiny']}</td>";
        echo "<td>{$row_veth_buf['max_buf_tiny']}</td>";
        echo "<td>{$row_veth_buf['min_buf_small']}</td>";
        echo "<td>{$row_veth_buf['max_buf_small']}</td>";
        echo "<td>{$row_veth_buf['min_buf_medium']}</td>";
        echo "<td>{$row_veth_buf['max_buf_medium']}</td>";
        echo "<td>{$row_veth_buf['min_buf_large']}</td>";
        echo "<td>{$row_veth_buf['max_buf_large']}</td>";
        echo "<td>{$row_veth_buf['min_buf_huge']}</td>";
        echo "<td>{$row_veth_buf['max_buf_huge']}</td>";
        echo "</tr>";
    }
    echo "</tbody></table>";
}

// DISKS

$query_disk = "SELECT * FROM disk WHERE lparname='{$vios}'";
$result_disk = mysqli_query($db, $query_disk);
if (mysqli_num_rows($result_disk) > 0) {
    echo "<table class=\"table table-hover table-striped\" width=\"100%\">";
    echo "<thead>";
    echo "<tr>";
    echo "<th>VM Name</th>
                      <th>Disk</th>
                      <th>rw_timeout</th>
                      <th>queue_depth</th>
                      <th>algorithm</th>
                      <th>timeout_policy</th>
                      <th>reserve_policy</th>
                      <th>dist_tw_width</th>
                      <th>dist_err_pcnt</th>
                      <th>hcheck_interval</th>
                      </thead></tr>
                      <tbody>";
    while ($row_disk = mysqli_fetch_assoc($result_disk)) {
        echo "<tr>";
        echo "<td>{$row_disk['lparname']}</td>";
        echo "<td>{$row_disk['disk']}</td>";
        echo "<td>{$row_disk['rw_timeout']}</td>";
        echo "<td>{$row_disk['queue_depth']}</td>";
        echo "<td>{$row_disk['algorithm']}</td>";
        echo "<td>{$row_disk['timeout_policy']}</td>";
        echo "<td>{$row_disk['reserve_policy']}</td>";
        echo "<td>{$row_disk['dist_tw_width']}</td>";
        echo "<td>{$row_disk['dist_err_pcnt']}</td>";
        echo "<td>{$row_disk['hcheck_interval']}</td>";
        echo "</tr>";
    }
    echo "</tbody></table>";
}