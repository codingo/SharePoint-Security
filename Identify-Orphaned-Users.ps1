Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
 

 
#Function to Check if a User exists in AD
Function Check-UserExistsInAD()
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
  
#Get all Site Collections of the web application
$WebApp = Get-SPWebApplication 
 
 #Iterate through all Site Collections
Foreach($site in $WebApp.Sites) 
{
        #Get all Webs with Unique Permissions - Which includes Root Webs
        $WebsColl = $site.AllWebs | Where {$_.HasUniqueRoleAssignments -eq $True} | ForEach-Object {
         
        $OrphanedUsers = @()
         
       #Iterate through the users collection
       foreach($User in $_.SiteUsers)
       {
          #Exclude Built-in User Accounts , Security Groups
          if(($User.LoginName.ToLower() -ne "nt authority\authenticated users") -and
                ($User.LoginName.ToLower() -ne "sharepoint\system") -and
                  ($User.LoginName.ToLower() -ne "nt authority\local service")  -and
                      ($user.IsDomainGroup -eq $false ) )
                   {
                       $UserName = $User.LoginName.split("\")  #Domain\UserName
                       $AccountName = $UserName[1]    #UserName
                        if ( ( Check-UserExistsInAD $AccountName) -eq $false )
                        {
                                   Write-Host "$($User.Name)($($User.LoginName)) from $($_.URL) doesn't Exists in AD!"
                                     
                                    #Make a note of the Orphaned user
                                    $OrphanedUsers+=$User.LoginName
                        }
                   }
     
}
}
}
         
# ****  Remove Users ****#
# Remove the Orphaned Users from the site
# foreach($OrpUser in $OrphanedUsers)
#   {
#        $_.SiteUsers.Remove($OrpUser)
#        Write-host "Removed the Orphaned user $($OrpUser) from $($_.URL) "
#   }


