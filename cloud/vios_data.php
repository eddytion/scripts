<?php

require 'config_dashboard.php';
$vios = $_GET['vios'];

//FCS Table

$query_fcs = "SELECT * FROM fcs WHERE lparname='{$vios}' AND (max_xfer_size !='0x1000000' AND num_cmd_elems !='1024')";
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
        echo "<tr class=\"table-warning\">";
        echo "<td>{$row_fcs['lparname']}</td>";
        echo "<td>{$row_fcs['adapter']}</td>";
        echo "<td>{$row_fcs['max_xfer_size']}</td>";
        echo "<td>{$row_fcs['num_cmd_elems']}</td>";
        echo "</tr>";
    }
    echo "</tbody></table>";
}

//FSCSI Table

$query_fscsi = "SELECT * FROM fscsi WHERE lparname='{$vios}' AND (fc_err_recov!='fast_fail' OR dyntrk!='yes')";
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
        echo "<tr class=\"table-warning\">";
        echo "<td>{$row_fscsi['lparname']}</td>";
        echo "<td>{$row_fscsi['adapter']}</td>";
        echo "<td>{$row_fscsi['fc_err_recov']}</td>";
        echo "<td>{$row_fscsi['dyntrk']}</td>";
        echo "</tr>";
    }
    echo "</tbody></table>";
}

//IEEE Table

$query_ieee = "SELECT * FROM ieee WHERE lparname='{$vios}' AND (s_interval!='short' OR mode!='8023ad' OR hash_mode!='src_dst_port')";
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
        echo "<tr class=\"table-warning\">";
        echo "<td>{$row_ieee['lparname']}</td>";
        echo "<td>{$row_ieee['adapter']}</td>";
        echo "<td>{$row_ieee['hash_mode']}</td>";
        echo "<td>{$row_ieee['s_interval']}</td>";
        echo "<td>{$row_ieee['mode']}</td>";
        echo "<td>{$row_ieee['jumbo_frames']}</td>";
        echo "</tr>";
    }
    echo "</tbody></table>";
}

// SWAP Table

$query_swap = "SELECT swap.lparname as lparname, swap.swapsize as swapsize, memory.memorysize as memorysize FROM swap JOIN memory ON swap.lparname=memory.lparname WHERE swap.lparname='{$vios}' AND (swap.swapsize!=memory.memorysize+512)";
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
        echo "<tr class=\"table-warning\">";
        echo "<td>{$row_swap['lparname']}</td>";
        echo "<td>{$row_swap['memorysize']}</td>";
        echo "<td>{$row_swap['swapsize']}</td>";
        echo "</tr>";
    }
    echo "</tbody></table>";
}

// Phys Ethernet Table

$query_phys_ent = "SELECT * FROM phys_eth WHERE lparname='{$vios}' AND (checksum_offload!='yes' OR flow_ctrl!='yes' OR large_receive!='yes' OR largesend!='yes')";
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
        echo "<tr class=\"table-warning\">";
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

$query_sea = "SELECT * FROM sea WHERE lparname='{$vios}' AND (largesend!='1' OR large_receive!='yes' OR adapter_reset!='no' OR accounting!='enabled' OR ha_mode='standby')";
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
        echo "<tr class=\"table-warning\">";
        echo "<td>{$row_sea['lparname']}</td>";
        echo "<td>{$row_sea['ent']}</td>";
        echo "<td>{$row_sea['largesend']}</td>";
        echo "<td>{$row_sea['large_receive']}</td>";
        echo "<td>{$row_sea['jumbo_frames']}</td>";
        echo "<td>{$row_sea['adapter_reset']}</td>";
        echo "<td>{$row_sea['accounting']}</td>";
        echo "<td>{$row_sea['ha_mode']}</td>";
        echo "</tr>";
    }
    echo "</tbody></table>";
}

// VETH Table

$query_veth = "SELECT * FROM veth WHERE lparname='{$vios}' AND (mtu_bypass!='on' OR rfc1323!='1' OR tcp_sendspace!='524288' OR tcp_recvspace!='524288' OR udp_recvspace!='655360' OR udp_sendspace!='65536')";
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
        echo "<tr class=\"table-warning\">";
        echo "<td>{$row_veth['lparname']}</td>";
        echo "<td>{$row_veth['adapter']}</td>";
        echo "<td>{$row_veth['mtu_bypass']}</td>";
        echo "<td>{$row_veth['rfc1323']}</td>";
        echo "<td>{$row_veth['tcp_sendspace']}</td>";
        echo "<td>{$row_veth['tcp_recvspace']}</td>";
        echo "<td>{$row_veth['udp_sendspace']}</td>";
        echo "<td>{$row_veth['udp_recvspace']}</td>";
        echo "</tr>";
    }
    echo "</tbody></table>";
}

// VETH Buffers

$query_veth_buf = "SELECT * FROM `veth_buf` WHERE lparname='{$vios}' AND (min_buf_tiny!='4096' OR max_buf_tiny!='4096' OR min_buf_small!='4096' OR max_buf_small!='4096' OR min_buf_medium!='1024' OR max_buf_medium!='1024' OR min_buf_large!='256' OR max_buf_large!='256' OR min_buf_huge!='128' OR max_buf_huge !='128')";
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
        echo "<tr class=\"table-warning\">";
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