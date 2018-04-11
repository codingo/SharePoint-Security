Add-PSSnapin Microsoft.SharePoint.PowerShell
Add-Type -Path 'C:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.dll'

$SiteUrl = "http://dev/sites/Testing"
#$SPSite = New-Object Microsoft.SharePoint.SPSite($SiteUrl);
$outfile = "uniqueUserPermissionsReport.csv"

$WebApps=Get-SPWebApplication


"Web Title,Web URL,List Title,User or Group,Role,Inherited" | out-file $outfile

#For all Web
foreach($SPSite in $WebApps.sites)
{
   
   	if ($SPSite.HasUniqueRoleAssignments) 
        { 
          $SPRoleAssignments = $SPSite.RoleAssignments; 
          foreach ($SPRoleAssignment in $SPRoleAssignments) 
          { 
            
            if($SPRoleAssignment.Member.GetType().Name -eq "SPUser")
            {        
            foreach ($SPRoleDefinition in $SPRoleAssignment.RoleDefinitionBindings) 
            { 
                $SPSite.Title + "," + $SPSite.Url + "," + "N/A" + "," + $SPRoleAssignment.Member.Name + "," + $SPRoleDefinition.Name + "," + $SPSite.HasUniqueRoleAssignments | out-file $outfile -append 
            }
            }
          }
        } 

#For all SiteCollections
foreach ($web in $SPSite.AllWebs) 
{ 
	if ($web.HasUniqueRoleAssignments) 
        { 
          $SPRoleAssignments = $web.RoleAssignments; 
          foreach ($SPRoleAssignment in $SPRoleAssignments) 
          { 
            
            if($SPRoleAssignment.Member.GetType().Name -eq "SPUser")
            {        
            foreach ($SPRoleDefinition in $SPRoleAssignment.RoleDefinitionBindings) 
            { 
                $web.Title + "," + $web.Url + "," + "N/A" + "," + $SPRoleAssignment.Member.Name + "," + $SPRoleDefinition.Name + "," + $web.HasUniqueRoleAssignments | out-file $outfile -append 
            }
            }
          }
        } 

        #For all list    
        foreach ($list in $web.Lists)
        {
           if ($list.HasUniqueRoleAssignments)
           {
             $SPRoleAssignments = $list.RoleAssignments; 
             foreach ($SPRoleAssignment in $SPRoleAssignments) 
             {
                 if($SPRoleAssignment.Member.GetType().Name -eq "SPUser")
            {  
               foreach ($SPRoleDefinition in $SPRoleAssignment.RoleDefinitionBindings)
               {
                   
                    $web.Title + "," + $web.Url + "," + $list.Title + "," + $SPRoleAssignment.Member.Name + "," + $SPRoleDefinition.Name | out-file $outfile -append
                    
               }
               }
             }
           }

           #for all list items
           foreach ($item in $list.items)
        {
           if ($item.HasUniqueRoleAssignments)
           {
             $SPRoleAssignments = $item.RoleAssignments; 
             foreach ($SPRoleAssignment in $SPRoleAssignments) 
             {
                 if($SPRoleAssignment.Member.GetType().Name -eq "SPUser")
            {  
               foreach ($SPRoleDefinition in $SPRoleAssignment.RoleDefinitionBindings)
               {
                   
                    $web.Title + "," + $web.Url + "," + $list.Title + "," +$item.Title + ","+ $SPRoleAssignment.Member.Name + "," + $SPRoleDefinition.Name | out-file $outfile -append
                    
               }
               }
             }
           }
        }
        }
}
}
$SPSite.Dispose();
