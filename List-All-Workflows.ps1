# Source: https://blogs.msdn.microsoft.com/vijay/2009/10/01/how-to-list-all-the-sub-sites-and-the-site-collections-within-a-sharepoint-web-application-using-windows-powershell/
param ([boolean] $writeToFile = $true)
#Get List of all workflows in farm with specified custom workflow activity
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

#If boolean is set to true, you can specify an outputlocation, to save to textfile.

if($writeToFile -eq $true)
{
	$outputPath = Read-Host "Outputpath (e.g. C:\directory\filename.txt)"
}
#Counter variables
$webcount = 0
$listcount = 0
$associationcount = 0

#Get all webs
Get-SPSite -Limit All | % {$webs += $_.Allwebs}
if($webs.count -ge 1)
{	
	#Iterate through all webs
	foreach($web in $webs)
	{
		#Grab all lists in the current web
		$lists = $web.Lists
		foreach($list in $lists)
		{
			foreach($wf in $list.WorkflowAssociations)
                {
					#Ignore previous versions - Check for other languages too
					if($wf.Name -like "*Previous*")
					{continue}
					
					
						#Read Workflow instance XOML file					
						write-host "`Iterating workflows: " $wf.Name -ForegroundColor "Yellow"
						[xml]$xmldocument =  $wf.SoapXml
						if($xmldocument.FirstChild -ne $null)
						{
							$name = $xmldocument.FirstChild.GetAttribute("Name")
							$wfName = $name.Replace(" ", "%20")
							$webRelativeFolder = "Workflows/" + $wfName
							$xomlFileName = $wfName + ".xoml"

							$wfFolder = $wf.ParentWeb.GetFolder($webRelativeFolder)

							$xomlFile = $wfFolder.Files[$xomlFileName]
							if ($xomlFile.Exists)
							{
								$xomlStream = $xomlFile.OpenBinaryStream()
								$xmldocument.Load($xomlStream)
								$xomlStream.Close()

								Write-Host $wf.Name
								#Write below custom action dll reference
								if($xmldocument.OuterXml -like "*CustomDLLName*")
								{
									Add-Content -Path $outputPath -Value "$($web.url)+$($list.title)+$($wf.Name)+Custom"  
								}
								else
								{
									Add-Content -Path $outputPath -Value "$($web.url)+$($list.title)+$($wf.Name)+OOB/Designer"  
								}
							}
							else
							{								 
								 Add-Content -Path $outputPath -Value "$($web.url)+$($list.title)+$($wf.Name)+OOB/Designer"  
							}
						}
						else
						{
							Add-Content -Path $outputPath -Value "$($web.url)+$($list.title)+$($wf.Name)+OOB/Designer"  
						}					
                }
		}
		$webcount +=1
		$web.Dispose()
	}
	#Show total counter for checked webs & lists
	Write-Host "Amount of webs checked:"$webcount

	$webcount = "0"
}
else
{
	Write-Host "No webs retrieved" -ForegroundColor Red -BackgroundColor Black
	$webcount = "0"
}
