# Get-ADGroupMembership.ps1
# This script retrieves and reports group membership information in Active Directory

param(
    [Parameter(Mandatory=$false)]
    [string]$GroupName,
    
    [Parameter(Mandatory=$false)]
    [string]$Username,
    
    [Parameter(Mandatory=$false)]
    [switch]$Recursive,
    
    [Parameter(Mandatory=$false)]
    [switch]$ExportToCSV
)

# Import required module
Import-Module ActiveDirectory

# Function to get nested group members
function Get-NestedGroupMembers {
    param(
        [string]$GroupName
    )
    
    $members = Get-ADGroupMember -Identity $GroupName -Recursive:$Recursive
    return $members | ForEach-Object {
        [PSCustomObject]@{
            Name = $_.Name
            SamAccountName = $_.SamAccountName
            ObjectClass = $_.ObjectClass
            DistinguishedName = $_.DistinguishedName
            GroupName = $GroupName
        }
    }
}

try {
    $results = @()
    
    if ($GroupName) {
        # Get members of specific group
        Write-Host "Getting members of group: $GroupName" -ForegroundColor Cyan
        $results += Get-NestedGroupMembers -GroupName $GroupName
    }
    elseif ($Username) {
        # Get groups for specific user
        Write-Host "Getting groups for user: $Username" -ForegroundColor Cyan
        $userGroups = Get-ADUser -Identity $Username -Properties MemberOf | Select-Object -ExpandProperty MemberOf
        
        foreach ($group in $userGroups) {
            $groupName = (Get-ADGroup $group).Name
            $results += [PSCustomObject]@{
                Name = $Username
                SamAccountName = $Username
                ObjectClass = "User"
                DistinguishedName = (Get-ADUser $Username).DistinguishedName
                GroupName = $groupName
            }
        }
    }
    else {
        # Get all groups and their members
        Write-Host "Getting all groups and their members" -ForegroundColor Cyan
        $groups = Get-ADGroup -Filter *
        
        foreach ($group in $groups) {
            $results += Get-NestedGroupMembers -GroupName $group.Name
        }
    }
    
    # Display results
    if ($results.Count -gt 0) {
        Write-Host "`nFound $($results.Count) results:" -ForegroundColor Green
        $results | Format-Table Name, SamAccountName, ObjectClass, GroupName -AutoSize
        
        # Export to CSV if requested
        if ($ExportToCSV) {
            $date = Get-Date -Format "yyyyMMdd"
            $csvPath = "ADGroupMembership_$date.csv"
            $results | Export-Csv -Path $csvPath -NoTypeInformation
            Write-Host "`nResults exported to: $csvPath" -ForegroundColor Green
        }
    }
    else {
        Write-Host "No results found" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
} 