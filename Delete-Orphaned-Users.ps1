Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
 
#Function to Check if a User exists in AD
function CheckUserExistsInAD()
   {
   Param( [Parameter(Mandatory=$true)] [string]$UserLoginID ) 
  #Search the User in AD
  $forest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
  foreach ($Domain in $forest.Domains)
  {
   $context = new-object System.DirectoryServices.ActiveDirectory.DirectoryContext("Domain", $Domain.Name)
         $domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($context)
   $root = $domain.GetDirectoryEntry()
         $search = [System.DirectoryServices.DirectorySearcher]$root
         $search.Filter = "(&(objectCategory=User)(samAccountName=$UserLoginID))"
         $result = $search.FindOne()
          if ($result -ne $null)
         {
           return $true
         }
  }
  return $false 
 }
 
 #Get All site collections of all web applications
 $sites = Get-SPWebApplication | Get-SPSite -Limit All
 #Iterate through each site collection
 foreach($site in $sites)
 {
 
 Write-Host "Processing Site:"$site.Url -ForegroundColor Magenta
  foreach($Web in $site.AllWebs)
 {
  #Arrays to Hold Orphaned Alerts & Users
   $OrphanedAlerts = @()
  $AlertUsers  = @()
  #Get all Alerts created on the web
  $WebAlerts = $web.Alerts
  #Get Unique Users from All Alerts
  $AlertUsers = $web.Alerts | foreach { $_.User } | Select-Object -Unique
 
  #Check if any user with alerts is :Orphan!
  if($AlertUsers.length -gt 0)
  {
   foreach($AlertUser in $AlertUsers)
    {
     #Write-host "Checking User:"$AlertUser
     #Check if the user is valid - Not Orphan
     $UserName = $AlertUser.UserLogin.split("\")  #Get User Name from : Domain\UserName
     $AccountName = $UserName[1]    #UserName
                     if ((CheckUserExistsInAD $AccountName) -eq $false)
                     {
      $OrphanedAlerts+=$AlertUser.Alerts
      }
    }

    #Delete orphans alerts 
   if($OrphanedAlerts.Length -gt 0)
    {
     Write-Host "Total No. of Orphaned Alerts Found:" $OrphanedAlerts.Length  -ForegroundColor Red
     #Delete each orphaned alert
     #foreach ($OrphAlert in $OrphanedAlerts)
     #{
     # write-host "`nOrphaned Alert:" $OrphAlert.ID" on "$web.Url "List:" $OrphAlert.ListUrl "User:"$OrphAlert.User
     # Write-Host "Deleting Orphaned Alert..."
      #$WebAlerts.Delete($OrphAlert.ID)
     #}
    }
   }    
 }
 }


