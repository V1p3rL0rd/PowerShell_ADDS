# Import the Active Directory module
Import-Module ActiveDirectory -ErrorAction Stop

# Get the current date and calculate the threshold date (current date + 14 days)
$currentDate = Get-Date
$thresholdDate = $currentDate.AddDays(14)

# Get all enabled users with an expiring password
$users = Get-ADUser -Filter { 
    Enabled -eq $true -and 
    PasswordNeverExpires -eq $false 
} -Properties Name, SamAccountName, msDS-UserPasswordExpiryTimeComputed -ErrorAction Stop

# Collecting users with expiring passwords
$expiringUsers = @()

foreach ($user in $users) {
    # Convert password expiration time from Active Directory format
    $passwordExpiryDate = [datetime]::FromFileTime($user.'msDS-UserPasswordExpiryTimeComputed')
    
    # Check if the password expires within 14 days
    if ($passwordExpiryDate -le $thresholdDate) {
        $daysRemaining = ($passwordExpiryDate - $currentDate).Days
        
        $userInfo = [PSCustomObject]@{
            UserName         = $user.SamAccountName
            DisplayName     = $user.Name
            ExpirationDate  = $passwordExpiryDate.ToString("yyyy-MM-dd")
            DaysRemaining   = $daysRemaining
        }
        
        $expiringUsers += $userInfo
    }
}

# Sorting and displaying the result
Write-Host "The following users will have their passwords about to expire or have already expired!"
$expiringUsers | Sort-Object DaysRemaining | Format-Table -AutoSize