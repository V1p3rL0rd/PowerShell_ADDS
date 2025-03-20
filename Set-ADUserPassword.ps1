# Set-ADUserPassword.ps1
# This script manages user passwords in Active Directory

param(
    [Parameter(Mandatory=$true)]
    [string]$Username,
    
    [Parameter(Mandatory=$false)]
    [string]$NewPassword,
    
    [Parameter(Mandatory=$false)]
    [switch]$RequirePasswordChange,
    
    [Parameter(Mandatory=$false)]
    [switch]$ResetPassword,
    
    [Parameter(Mandatory=$false)]
    [switch]$UnlockAccount
)

# Import required module
Import-Module ActiveDirectory

# Function to generate a secure random password
function New-SecurePassword {
    $length = 12
    $nonAlphanumeric = 2
    return [System.Web.Security.Membership]::GeneratePassword($length, $nonAlphanumeric)
}

try {
    # Get the user
    $user = Get-ADUser -Identity $Username -Properties LockedOut, PasswordExpired, PasswordLastSet
    
    if ($user) {
        Write-Host "User found: $($user.DisplayName)" -ForegroundColor Green
        
        # Handle account unlock
        if ($UnlockAccount) {
            Unlock-ADAccount -Identity $user
            Write-Host "Account unlocked successfully" -ForegroundColor Green
        }
        
        # Handle password reset
        if ($ResetPassword) {
            if (-not $NewPassword) {
                $NewPassword = New-SecurePassword
            }
            
            Set-ADAccountPassword -Identity $user -NewPassword (ConvertTo-SecureString $NewPassword -AsPlainText -Force)
            
            if ($RequirePasswordChange) {
                Set-ADUser -Identity $user -ChangePasswordAtLogon $true
            }
            
            Write-Host "Password reset successfully" -ForegroundColor Green
            if (-not $NewPassword) {
                Write-Host "Generated password: $NewPassword" -ForegroundColor Yellow
            }
        }
        
        # Display account status
        Write-Host "`nAccount Status:" -ForegroundColor Cyan
        Write-Host "Locked Out: $($user.LockedOut)"
        Write-Host "Password Expired: $($user.PasswordExpired)"
        Write-Host "Password Last Set: $($user.PasswordLastSet)"
        Write-Host "Enabled: $($user.Enabled)"
    }
    else {
        Write-Host "User not found: $Username" -ForegroundColor Red
    }
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
} 