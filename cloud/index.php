<?php require("header.php"); ?>
<div class="tables">
<?php
require("config.php");
if(!$db)
{
        die("Conn failed: " . mysqli_connect_error());
}
else
{
        $sql = "SELECT * FROM lpar_ms LIMIT 0,25";
        $result = mysqli_query($db,$sql);
        if (mysqli_num_rows($result) > 0) 
        {
                echo "<table class=\"table\" id=\"tblData\" width=\"100%\">";
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
        else
        {
            echo "0 results";
        }
        mysqli_close($db);
}
?>
</div>
<script type="text/javascript">
    (function(){
    new Clipboard('#copy-button');
})();
</script>
<script type="text/javascript">
                        $(document).ready(function()
                        {
                                $('#search').keyup(function()
                                {
                                        searchTable($(this).val());
                                });
                        });
                        function searchTable(inputVal)
                        {
                                var table = $('#tblData');
                                table.find('tr').each(function(index, row)
                                {
                                        var allCells = $(row).find('td');
                                        if(allCells.length > 0)
                                        {
                                                var found = false;
                                                allCells.each(function(index, td)
                                                {
                                                        var regExp = new RegExp(inputVal, 'i');
                                                        if(regExp.test($(td).text()))
                                                        {
                                                                found = true;
                                                                return false;
                                                        }
                                                });
                                                if(found === true)$(row).show();else $(row).hide();
                                        }
                                });
                        }
</script>
<script type="text/javascript">
$(document).ready(function() 
    { 
        $("#tblData").tablesorter(); 
    } 
);
</script>
</body>
</html>
