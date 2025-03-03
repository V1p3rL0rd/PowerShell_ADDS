# Importing the Active Directory module
Import-Module ActiveDirectory

# Defining group names
$groups = @("gr_accounts", "gr_hr", "gr_it", "gr_booking", "gr_transfer", "gr_operators")

# Specify the domain
$domain = "DC=garuda,DC=net"  # Replace to your domain
$ouPath = "OU=Groups,$domain"

# Check if OU "Groups" exists
if (-not (Get-ADOrganizationalUnit -Filter 'Name -eq "Groups"' -SearchBase $domain)) {
    # Create OU "Groups" if it does not exist
    New-ADOrganizationalUnit -Name "Groups" -Path $domain
    Write-Host "OU 'Groups' has been created."
}

# Loop to create each group
foreach ($group in $groups) {
    # Check if the group exists
    if (-not (Get-ADGroup -Filter { Name -eq $group })) {
        # Create a group
        New-ADGroup -Name $group -GroupCategory Security -GroupScope Global -Path $ouPath
        Write-Host "Group $group created."
    } else {
        Write-Host "The group $group already exists."
    }
}