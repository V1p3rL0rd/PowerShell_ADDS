# Move-ADUserToOU.ps1
# This script moves AD users between Organizational Units

param(
    [Parameter(Mandatory=$true)]
    [string]$Username,
    
    [Parameter(Mandatory=$true)]
    [string]$TargetOU,
    
    [Parameter(Mandatory=$false)]
    [switch]$WhatIf
)

# Import required module
Import-Module ActiveDirectory

try {
    # Get the user
    $user = Get-ADUser -Identity $Username -Properties DistinguishedName
    
    if ($user) {
        Write-Host "User found: $($user.DisplayName)" -ForegroundColor Green
        Write-Host "Current location: $($user.DistinguishedName)" -ForegroundColor Yellow
        
        # Get the target OU
        $targetOU = Get-ADOrganizationalUnit -Identity $TargetOU
        
        if ($targetOU) {
            Write-Host "Target OU found: $($targetOU.DistinguishedName)" -ForegroundColor Green
            
            # Perform the move
            if ($WhatIf) {
                Write-Host "`nWhatIf: Would move user to:" -ForegroundColor Cyan
                Write-Host "OU: $($targetOU.DistinguishedName)" -ForegroundColor Cyan
            }
            else {
                Move-ADObject -Identity $user.DistinguishedName -TargetPath $targetOU.DistinguishedName
                Write-Host "`nUser moved successfully!" -ForegroundColor Green
                
                # Verify the move
                $movedUser = Get-ADUser -Identity $Username -Properties DistinguishedName
                Write-Host "New location: $($movedUser.DistinguishedName)" -ForegroundColor Green
            }
        }
        else {
            Write-Host "Target OU not found: $TargetOU" -ForegroundColor Red
        }
    }
    else {
        Write-Host "User not found: $Username" -ForegroundColor Red
    }
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
} 