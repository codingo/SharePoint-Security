# Source: Read more: http://www.sharepointdiary.com/2013/12/blocked-file-types-in-sharepoint-2013.html#ixzz5CLp6pkZM

Write-host "Enter the Web Application URL:"
$WebAppURL= Read-Host
$WebApplication = Get-SPWebApplication $webAppURL
$Extensions = $WebApplication.BlockedFileExtensions
     
write-host "Blocked File Types:"
$Extensions | ForEach-Object {Write-Host $_}
  
#To Add a Blocked File type
$Extensions.Add("dlg")
$WebApplication.Update()
write-host "DLG File type has been Blocked"
  
#To Remove a Blocked File type
$Extensions.Remove("dlg")
$WebApplication.Update()
write-host "Blocked File type DLG has been Removed"
