# PowerShell AD DS Administration Toolkit

A comprehensive collection of PowerShell scripts for Active Directory Domain Services (AD DS) administration and management.

## Overview

This toolkit provides a set of PowerShell scripts to automate common AD DS administrative tasks, making it easier to manage your Active Directory environment efficiently.

## Prerequisites

- Windows Server with Active Directory Domain Services role installed
- PowerShell 5.1 or higher
- Appropriate administrative privileges
- Active Directory PowerShell module

## Available Scripts

### Core AD DS Deployment
- `DeployPrimaryDC.ps1` - Deploys a new Primary Domain Controller
- `DeployAdditionalDC.ps1` - Deploys an Additional Domain Controller

### User Management
- `CreateNewADUser.ps1` - Creates new AD user accounts
- `CheckForADUserMultipleSessions.ps1` - Monitors and reports multiple user sessions
- `CheckADUserPasswordExpires.ps1` - Checks password expiration status for AD users

### Organizational Structure
- `AddNewSecurityGroups.ps1` - Creates new security groups
- `AddNewOrganizationalUnits.ps1` - Creates new Organizational Units

### Additional Tools
- `Get-ADUserLastLogon.ps1` - Reports last logon times for AD users
- `Set-ADUserPassword.ps1` - Manages user password changes
- `Get-ADGroupMembership.ps1` - Reports group membership information
- `Move-ADUserToOU.ps1` - Moves users between Organizational Units
- `Get-ADComputerStatus.ps1` - Reports computer account status in AD

## Usage

1. Clone this repository to your local machine
2. Open PowerShell with administrative privileges
3. Navigate to the script directory
4. Run the desired script with appropriate parameters

Example:
```powershell
.\CreateNewADUser.ps1 -Username "JohnDoe" -FirstName "John" -LastName "Doe" -Department "IT"
```

## Contributing

Feel free to submit issues and enhancement requests!

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Disclaimer

These scripts are provided as-is without any warranty. Always test scripts in a non-production environment first. 
