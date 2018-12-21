<meta name="viewport" content="width=device-width, initial-scale=1">
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.1.3/css/bootstrap.min.css">
<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.14.0/umd/popper.min.js"></script>
<script src="https://maxcdn.bootstrapcdn.com/bootstrap/4.1.3/js/bootstrap.min.js"></script>
<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
<script type="text/javascript" src="js/jquery-1.7.1.js"></script>
<script type="text/javascript" src="js/clipboardjs/dist/clipboard.min.js"></script>
<script type="text/javascript" src="js/tablesort/jquery.tablesorter.min.js"></script>
<link rel="stylesheet" href="css/custom_table.css">
<br>
<br>
<br>
<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
if(isset($_GET['q']) && is_string($_GET['q']))
{
    require 'config.php';
    $string = filter_var($_GET['q'],FILTER_SANITIZE_STRING);
    $query = "select * from lpar_ms where hmc_id like '%{$string}%' OR msname like '%{$string}%' OR lparname like '%{$string}%'";
    $result = mysqli_query($db, $query);
    if(mysqli_num_rows($result) > 0)
    {
        print "<table class=\"table\" width=\"100%\">";
                echo "<thead>";
                echo "<tr>";
                echo "<th>HMC</th>
                      <th>MS Name</th>
                      <th>MS Model</th>
                      <th>MS Serial</th>
                      <th>LPAR Name</th>
                      <th>LPAR Env</th>
                      <th>OSLEVEL</th>
                      <th>LPAR State</th>
                      <th>RMC IP</th>
                      <th>RMC State</th>
                      <th>CPU Compat Mode</th>
                      </tr>
                      </thead>
                      <tbody>";
                $counter=0;
                while($row = mysqli_fetch_assoc($result)) 
                {
                if($counter%2==0)
                {
                  $class="even";
                }
                else
                {
                  $class="odd";
                }
                        echo "<tr class=\"$class\" onmouseover=\"this.style.color='red'\" onmouseout=\"this.style.color='#566787'\">";
                        echo "<td>" . "<a class=\"text-primary\" href=\"https://{$row["hmc_id"]}\" target=\"_blank\">{$row["hmc_id"]}</a>" . "<br><a href=\"hmc.php?hmc={$row['hmc_id']}\" onclick=\"return popitup('hmc.php?hmc={$row['hmc_id']}')\">HMC Details</a>". "</td><td>" . 
                             "<i class=\"fas fa-server\"></i> " . $row["msname"] . 
                                "<br><a href=\"ms_io.php?msname={$row['msname']}\" onclick=\"return popitup('ms_io.php?msname={$row['msname']}')\">MS IO</a>"
                             . " | <a href=\"ms_cpu_mem.php?msname={$row['msname']}\" onclick=\"return popitup('ms_cpu_mem.php?msname={$row['msname']}')\">MS CPU/MEM</a>"
                             . " | <a href=\"ms_fw.php?msname={$row['msname']}\" onclick=\"return popitup('ms_fw.php?msname={$row['msname']}')\">MS FW</a>" 
                             . " | <a href=\"lpars.php?msname={$row['msname']}\" onclick=\"return popitup('lpars.php?msname={$row['msname']}')\">LPARS</a></td><td>" . 
                             $row["msmodel"] . "<br><a href=\"https://www.google.co.uk/#q=IBM+{$row['msmodel']}+redbook+filetype:pdf+site:redbooks.ibm.com\" onclick=\"return popitup('https://www.google.co.uk/#q=IBM+{$row['msmodel']}+redbook+filetype:pdf+site:redbooks.ibm.com')\">Search online</a>" ."</td><td>" . 
                             $row["msserial"] . "</td><td>" . 
                             "<i class=\"fas fa-desktop\"></i>&nbsp;" .$row["lparname"] . " <i class=\"fas fa-terminal\" title=\"Click to copy mkvterm command to clipboard\" id=\"copy-button\" data-clipboard-text=\"mkvterm -m {$row['msname']} -p {$row['lparname']}\"></i>"
                             . "<br /><a href=\"lpar.php?lpar={$row['lparname']}&env={$row['lparenv']}\" onclick=\"return popitup('lpar.php?lpar={$row['lparname']}&env={$row['lparenv']}')\">Details</a></td><td>" . 
                             $row["lparenv"] . "</td><td>";
                             echo "{$row["lparos"]}";
                             echo "</td><td>" . 
                             $row["lparstate"] . "</td><td>" . 
                             "<i class=\"fas fa-network-wired\"></i>&nbsp;" . $row["lparip"] . "</td><td>" .
                             $row["rmc_state"] . "</td><td>" .
                             $row["curr_lpar_proc_compat_mode"] . "</td>";
                        echo "</tr>";
                $counter++;
                }
                echo "</tbody>";
                echo "</table>";
    }
}