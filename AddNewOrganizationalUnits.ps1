# Installing the RSAT AD DS module
Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0 

# Importing the Active Directory module
Import-Module ActiveDirectory

# Specify the domain
$domain = "garuda.net"

# List of OUs to be created
$OUs = @("Accounts", "HR", "IT", "Booking", "Transfer", "Operators")

# Loop through each item in the list and create an OU
foreach ($ou in $OUs) {
    $ouPath = "OU=$ou,DC=garuda,DC=net"
    New-ADOrganizationalUnit -Name $ou -Path "DC=garuda,DC=net" -ProtectedFromAccidentalDeletion $false
    Write-Host "OU $ou created in the domain $domain"
}

Write-Host "All OUs have been created successfully!"
