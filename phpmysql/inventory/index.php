<?php require("header.php"); ?>
<div class="tables">
<br />
<br />
<br />
<br />
<?php
require("config.php");
if(!$db)
{
        die("Conn failed: " . mysqli_connect_error());
}
else
{
        $sql = "SELECT lpar_ms.id,
       hmc.NAME AS hmc_name,
       lpar_ms.hmc_id,
       lpar_ms.msname,
       lpar_ms.msmodel,
       lpar_ms.msserial,
       lpar_ms.lparname,
       lpar_ms.lparenv,
       lpar_ms.lparos,
       lpar_ms.lparstate,
       lpar_ms.lparip
       FROM   lpar_ms
       JOIN hmc
       ON lpar_ms.hmc_id = hmc.id";
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
                      <th>LPAR OS</th>
                      <th>LPAR State</th>
                      <th>RMC IP</th>
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
                        echo "<tr class=\"$class\" onmouseover=\"this.style.color='green'\" onmouseout=\"this.style.color='black'\">";
                        echo "<td>" . $row["hmc_name"] . "<br><a href=\"hmc.php?hmc={$row['hmc_name']}\" onclick=\"return popitup('hmc.php?hmc={$row['hmc_name']}')\">HMC Details</a>". "</td><td>" . 
                             "<img src=\"img/server-16.gif\" /> " . $row["msname"] . "<br><a href=\"ms_io.php?msname={$row['msname']}\" onclick=\"return popitup('ms_io.php?msname={$row['msname']}')\">MS IO</a>"
                             . " | <a href=\"ms_cpu_mem.php?msname={$row['msname']}\" onclick=\"return popitup('ms_cpu_mem.php?msname={$row['msname']}')\">MS CPU/MEM</a>"
                             . " | <a href=\"ms_fw.php?msname={$row['msname']}\" onclick=\"return popitup('ms_fw.php?msname={$row['msname']}')\">MS FW</a></td><td>" . 
                             $row["msmodel"] . "<br><a href=\"https://www.google.co.uk/#q=IBM+{$row['msmodel']}+redbook+filetype:pdf+site:redbooks.ibm.com\" onclick=\"return popitup('https://www.google.co.uk/#q=IBM+{$row['msmodel']}+redbook+filetype:pdf+site:redbooks.ibm.com')\">Search online</a>" ."</td><td>" . 
                             $row["msserial"] . "</td><td>" . 
                             "<img src=\"img/partition-16.gif\" /> " .$row["lparname"] . " <img src=\"img/terminal.png\" title=\"Click to copy mkvterm command to clipboard\" id=\"copy-button\" data-clipboard-text=\"mkvterm -m {$row['msname']} -p {$row['lparname']}\" /> "
                             . "<br /><a href=\"lpar.php?lpar={$row['lparname']}&env={$row['lparenv']}\" onclick=\"return popitup('lpar.php?lpar={$row['lparname']}&env={$row['lparenv']}')\">Details</a></td><td>" . 
                             $row["lparenv"] . "</td><td>";
                             if($row["lparos"] === "Unknown") {echo "(Check if lpar is activated and RMC is working)";} else {echo "{$row["lparos"]}";}
                             echo "</td><td>" . 
                             $row["lparstate"] . "</td><td>" . 
                             $row["lparip"] . "</td>";
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
