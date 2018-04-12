        Add-Type -Path "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.dll" 
        Add-Type -Path "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.Runtime.dll" 
        Add-Type -Path "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\ISAPI\Microsoft.Online.SharePoint.Client.Tenant.dll" 

function Get-SPOTenantSiteCollections 
{ 
    param ($sSiteUrl,$sUserName,$sPassword) 
    try 
    {     
        Write-Host "----------------------------------------------------------------------------"  -foregroundcolor Green 
        Write-Host "Getting the Tenant Site Collections and start Invertory" -foregroundcolor Green 
        Write-Host "----------------------------------------------------------------------------"  -foregroundcolor Green 
      
      
        #SPO Client Object Model Context 
        $spoCtx = New-Object Microsoft.SharePoint.Client.ClientContext($sSiteUrl)  
        $spoCredentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($sUsername, $sPassword)   
        $spoCtx.Credentials = $spoCredentials 
        $spoTenant= New-Object Microsoft.Online.SharePoint.TenantAdministration.Tenant($spoCtx) 
        $spoTenantSiteCollections=$spoTenant.GetSiteProperties(0,$true) 
        $spoCtx.Load($spoTenantSiteCollections) 
        $spoCtx.ExecuteQuery() 
         
        #We need to iterate through the $spoTenantSiteCollections object to get the information of each individual Site Collection 
        foreach($spoSiteCollection in $spoTenantSiteCollections){ 
             
            #Write-Host "Url: " $spoSiteCollection.Url " - Template: " $spoSiteCollection.Template " - Owner: "  $spoSiteCollection.Owner 
           Get-SPOAllSitePermisions $spoSiteCollection.Url $sUserName $sPassword
        } 
        $spoCtx.Dispose() 
    } 
    catch [System.Exception] 
    { 
        write-host -f red $_.Exception.ToString()    
    }     
} 
 

 
Function Get-SPOAllSitePermisions ($url,$admin,$pass) 
{ 

    $ctx = New-Object Microsoft.SharePoint.Client.ClientContext($url) 
    $ctx.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($admin, $pass) 
    $web = $ctx.Web    
    Load-CSOMProperties -Object $web -PropertyNames @("HasUniqueRoleAssignments", "Url", "Title") 
    $ctx.Load($ctx.Web.Webs)     
    $ctx.Load($ctx.Web.RoleAssignments)     
    $ctx.ExecuteQuery() 
    Write-Host $web.Url 
    $webUrl = $web.Url           
    if($web.HasUniqueRoleAssignments -eq $true) { 
        $firstIteration = $true #helps when to append commas 
        foreach($roleAssignment in $ctx.Web.RoleAssignments) { 
            Load-CSOMProperties -Object $roleAssignment -PropertyNames @("Member","RoleDefinitionBindings") 
            $ctx.ExecuteQuery() 
            $roles = ($roleAssignment.RoleDefinitionBindings | Select -ExpandProperty Name) -join ", "; 
            if($roleAssignment.Member.PrincipalType -eq "User")
            {          
            $web.Title + "," + $web.Url + "," + "N/A" + "," + $roleAssignment.Member.LoginName + "," + $roles + "," + $web.HasUniqueRoleAssignments | out-file $OutputFile -append 
            }

        }        
    }  

    $lists=$web.Lists;
    $ctx.Load($ctx.Web.Lists);
    $ctx.ExecuteQuery();
   # write-host "List count is" $lists.Count

    foreach($list in $lists)
    {
    
    Load-CSOMProperties -Object $list -PropertyNames @("HasUniqueRoleAssignments", "Title") 
    $ctx.Load($list)     
    $ctx.Load($list.RoleAssignments)     
    $ctx.ExecuteQuery() 

            if($list.HasUniqueRoleAssignments -eq $true) { 
        $firstIteration = $true #helps when to append commas 
        foreach($roleAssignment in $list.RoleAssignments) { 
            Load-CSOMProperties -Object $roleAssignment -PropertyNames @("Member","RoleDefinitionBindings") 
            $ctx.ExecuteQuery() 
            $roles = ($roleAssignment.RoleDefinitionBindings | Select -ExpandProperty Name) -join ", "; 
            write-host $roleAssignment.Member.LoginName
            if($roleAssignment.Member.PrincipalType -eq "User")
             {
                 #write-host $list.Title $roles
                 
            $web.Title + "," + $web.Url + "," + $list.Title  + "," + $roleAssignment.Member.LoginName + "," + $roles  | out-file $OutputFile -append 
            }

          
        }
        
	$listItems = $list.GetItems([Microsoft.SharePoint.Client.CamlQuery]::CreateAllItemsQuery())
	$ctx.load($listItems)

	$ctx.executeQuery()
	foreach($listItem in $listItems)
	{
	
          Load-CSOMProperties -Object $listItem -PropertyNames @("HasUniqueRoleAssignments") 
    $ctx.Load($listItem)     
    $ctx.Load($listItem.RoleAssignments)     
    $ctx.ExecuteQuery() 

            if($listItem.HasUniqueRoleAssignments -eq $true) { 
        $firstIteration = $true #helps when to append commas 
        foreach($roleAssignment in $listItem.RoleAssignments) { 
            Load-CSOMProperties -Object $roleAssignment -PropertyNames @("Member","RoleDefinitionBindings") 
            $ctx.ExecuteQuery() 
            $roles = ($roleAssignment.RoleDefinitionBindings | Select -ExpandProperty Name) -join ", "; 
            write-host $roleAssignment.Member.PrincipalType
            if($roleAssignment.Member.PrincipalType -eq "User") {
              	#Write-Host "ID - " $listItem["ID"] "Title - " $listItem["Title"] $roles
              $web.Title + "," + $web.Url + "," + $list.Title + "," +$listItem.Title + ","+ $roleAssignment.Member.LoginName + "," + $roles | out-file $OutputFile -append
            }

          
        }
    
	}      
    }
    } 
    }
     
    if($web.Webs.Count -eq 0) 
    { 
    
    } 
    else { 
        foreach ($web in $web.Webs) { 
            Get-SPOAllSitePermisions -Url $web.Url 
        } 
    } 
} 
#Required Parameters 
$sSiteUrl = ""  
$sUserName = ""  
#$sPassword = Read-Host -Prompt "Enter your password: " -AsSecureString   
$sPassword=convertto-securestring "Password" -asplaintext -force 

$OutputFile = "C:\Powershell\AllSitePermissions.csv" 

 
"Web Title,Web URL,List Title,User or Group,Role,Inherited" | out-file $OutPutfile

Get-SPOTenantSiteCollections -sSiteUrl $sSiteUrl -sUserName $sUserName -sPassword $sPassword
