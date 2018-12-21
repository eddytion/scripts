<?php
require("header2.php");
$vioses = array('vna','vnb','vsa','vsb','via','vib');
if(isset($_GET['msname']) && is_string($_GET['msname']))
{
    require("config.php");
    $msname = filter_var($_GET['msname'], FILTER_SANITIZE_STRING);
    
    if(!$db)
    {
	die("Conn failed: " . mysqli_connect_error());
    }
    else
    {
        $sql="SELECT * FROM lpar_ms WHERE msname='{$msname}' ORDER BY lparenv DESC";
        $result = mysqli_query($db, $sql);
        if (mysqli_num_rows($result) > 0) 
        {
                echo "<table class=\"table table-striped\" id=\"tblData\" width=\"100%\">";
                echo "<thead class=\"thead-dark\">";
                echo "<tr>";
                echo "<th>HMC</th>
                      <th>MS Name</th>
                      <th>LPAR Name</th>
                      <th>RMC IP</th>
                      <th>LPAR Env</th>
                      <th>LPAR ID ( DEC / HEX )</th>
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
                        echo "<td>{$row['hmc_id']}</td>";
                        echo "<td>{$row['msname']}</td>";
                        if(preg_match('/vna/',$row['lparname']) || preg_match('/vnb/',$row['lparname']) || preg_match('/vsb/',$row['lparname']) || preg_match('/vsa/',$row['lparname']) || preg_match('/vib/',$row['lparname']) || preg_match('/via/',$row['lparname']) || preg_match('/vio/',$row['lparname']))
                        {
                            echo "<td class=\"table-primary\">{$row['lparname']}</td>";
                        }
                        else
                        {
                            echo "<td >{$row['lparname']}</td>";
                        }
                        echo "<td>{$row['lparip']}</td>";
                        echo "<td>{$row['lparenv']}</td>";
                        echo "<td>" . $row['lpar_id'] . " / <font color=\"navy\">0x" . dechex($row['lpar_id']) . "</font></td>";
                        echo "</tr>";
                }
                echo "</tbody></table>";
        }
    }
}
