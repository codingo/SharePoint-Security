# Source: https://support.office.com/en-us/article/turn-external-sharing-on-or-off-for-sharepoint-online-6288296a-b6b7-4ea4-b4ed-c297bf833e30#ID0EAABAAA=Office_365_Groups

$userCredential = Get-Credential

Connect-SPOService -Url https://TenantName-admin.sharepoint.com -Credential $userCredential
$sites = Get-sposite -template GROUP#0 -includepersonalsite:$false

Foreach($site in $sites)
{
   Set-SPOSite -Identity $site.Url -SharingCapability SharingOption
}

Write-Host("External Sharing Capability updated for all sites.")
