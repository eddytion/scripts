<?php
require("header2.php");
if(isset($_GET['msname']) && is_string($_GET['msname']))
{
    require("config.php");
    if(!$db)
    {
	die("Conn failed: " . mysqli_connect_error());
    }
    else
    {
        $msname = filter_var($_GET['msname'],FILTER_SANITIZE_STRING);
        $sql="
        SELECT *
        FROM ms_fw
        WHERE ms_name='{$msname}' LIMIT 0,1";
        $result = mysqli_query($db,$sql);
        if (mysqli_num_rows($result) > 0)
	{
                echo "<h3>Info from local DB</h3>";
		echo "<table class=\"table\">";
		echo "<thead><tr>";
		echo "<th>MS Name</th>
		      <th>FW Level</th>
                      </tr></thead><tbody>";
		while($row = mysqli_fetch_assoc($result)) 
		{
			echo "<tr>";
			echo "<td>" . $row["ms_name"] . "</td><td>" . 
                             $row["fw_level"] . "</td>";
			echo "</tr>";
                        
                        $pieces_mtm = explode("-",$row['ms_name']);
                        $mtm = $pieces_mtm[1]."-".$pieces_mtm[2];   
                        
                        $pieces_fw = explode(":",$row['fw_level']);
                        if(strlen(trim($pieces_fw[1])) < 3)
                        {
                            $fw = substr($pieces_fw[0],2,5)."_"."0".$pieces_fw[1];
                        }
                        else
                        {
                            $fw = substr($pieces_fw[0],2,6)."_".$pieces_fw[1];
                        }
		}
		echo "</tbody></table>";
//                $aContext = array(
//                'http' => array(
//                    'proxy' => 'tcp://129.35.62.20:8080',
//                    'request_fulluri' => true,
//                    ),
//                );
//                $cxContext = stream_context_create($aContext);

                function isJSON($string){
                    return is_string($string) && is_array(json_decode($string, true)) && (json_last_error() == JSON_ERROR_NONE) ? true : false;
                }
                //$content = file_get_contents("https://www14.software.ibm.com/webapp/set2/flrt/report?pageNm=home&reportType=power&plat=power&p0.mtm={$mtm}&p0.fw={$fw}&btnGo=SUBMIT&format=json", False, $cxContext);
                $content = file_get_contents("https://www14.software.ibm.com/webapp/set2/flrt/report?pageNm=home&reportType=power&plat=power&p0.mtm={$mtm}&p0.fw={$fw}&btnGo=SUBMIT&format=json");
                if(!empty($content) && isJSON($content))
                {
                    $data = json_decode($content, JSON_PRETTY_PRINT);
                    $inputVersion = $data["flrtReport"][0]["System"]["fw"]["input"]["version"];
                    $inputReleaseDate = $data["flrtReport"][0]["System"]["fw"]["input"]["releaseDate"];
                    $latestVersion = $data["flrtReport"][0]["System"]["fw"]["input"]["latest"]["version"];
                    $latestReleaseDate = $data["flrtReport"][0]["System"]["fw"]["input"]["latest"]["releaseDate"];
                    $latestReleaseLink = $data["flrtReport"][0]["System"]["fw"]["input"]["latest"]["url"];
                }
                else
                {
                    mysqli_close($db);
                    die("<div class=\"alert alert-danger\"><strong>Unable to fetch data from IBM FLRT</strong></div>");
                }
                
                echo "<h3>Info from FLRT</h3>";
                echo "<table class=\"table\">";
                echo "<thead><tr>";
                echo "<th>Input Version</th>";
                echo "<th>Release Date</th>";
                echo "<th>Latest Version</th>";
                echo "<th>Release Date</th>";
                echo "</tr>";
                echo "</thead><tbody><tr>";
                echo "<td><div class=\"alert alert-info\"><strong>{$inputVersion}</strong></div></td>";
                echo "<td><div class=\"alert alert-info\"><strong>{$inputReleaseDate}</strong></div></td>";
                if($inputVersion >= $latestVersion)
                {
                    echo "<td><div class=\"alert alert-success\"><strong>$latestVersion</strong> - Your system is running the latest release</div></td>";
                }
                else
                {
                    echo "<td><div class=\"alert alert-warning\"><strong>$latestVersion</strong> - You should consider updating your machine >> <a href=\"{$latestReleaseLink}\" target=\"_blank\"> Download</a></div></td>";
                }
                echo "<td><div class=\"alert alert-info\"><strong>{$latestReleaseDate}</strong></div></td>";
                echo "</tr></tbody></table>";
	}
	else
	{
	    echo "0 results";
	}
	mysqli_close($db);
    }
}
else
{
    die("<h2>Bad Request</h2>");
}
