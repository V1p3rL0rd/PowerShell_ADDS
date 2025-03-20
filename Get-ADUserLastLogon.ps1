# Get-ADUserLastLogon.ps1
# This script retrieves the last logon time for all AD users

param(
    [Parameter(Mandatory=$false)]
    [string]$SearchBase = (Get-ADDomain).DistinguishedName,
    
    [Parameter(Mandatory=$false)]
    [int]$DaysInactive = 30
)

# Import required module
Import-Module ActiveDirectory

# Function to convert FileTime to DateTime
function Convert-FileTimeToDateTime {
    param([long]$FileTime)
    if ($FileTime -gt 0) {
        return [DateTime]::FromFileTime($FileTime)
    }
    return $null
}

# Get all AD users
$users = Get-ADUser -Filter * -SearchBase $SearchBase -Properties LastLogon, LastLogonTimestamp, Enabled, PasswordExpired, PasswordLastSet

# Create array to store results
$results = @()

foreach ($user in $users) {
    $lastLogon = if ($user.LastLogonTimestamp) {
        Convert-FileTimeToDateTime $user.LastLogonTimestamp
    } else {
        "Never"
    }

    $results += [PSCustomObject]@{
        Username = $user.SamAccountName
        DisplayName = $user.DisplayName
        LastLogon = $lastLogon
        Enabled = $user.Enabled
        PasswordExpired = $user.PasswordExpired
        PasswordLastSet = if ($user.PasswordLastSet) {
            $user.PasswordLastSet
        } else {
            "Never"
        }
    }
}

# Export results to CSV
$date = Get-Date -Format "yyyyMMdd"
$csvPath = "ADUserLastLogon_$date.csv"
$results | Export-Csv -Path $csvPath -NoTypeInformation

# Display inactive users
Write-Host "`nUsers inactive for more than $DaysInactive days:" -ForegroundColor Yellow
$results | Where-Object { 
    $_.LastLogon -ne "Never" -and 
    $_.LastLogon -lt (Get-Date).AddDays(-$DaysInactive)
} | Format-Table Username, DisplayName, LastLogon, Enabled

Write-Host "`nFull report exported to: $csvPath" -ForegroundColor Green 
