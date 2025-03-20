# Get-ADComputerStatus.ps1
# This script reports the status of computer accounts in Active Directory

param(
    [Parameter(Mandatory=$false)]
    [string]$ComputerName,
    
    [Parameter(Mandatory=$false)]
    [int]$DaysInactive = 30,
    
    [Parameter(Mandatory=$false)]
    [switch]$ExportToCSV
)

# Import required module
Import-Module ActiveDirectory

# Function to convert FileTime to DateTime
function Convert-FileTimeToDateTime {
    param([long]$FileTime)
    return [DateTime]::FromFileTime($FileTime)
}

try {
    $results = @()
    
    if ($ComputerName) {
        # Get specific computer
        $computers = @(Get-ADComputer -Identity $ComputerName -Properties *)
    }
    else {
        # Get all computers
        $computers = Get-ADComputer -Filter * -Properties *
    }
    
    foreach ($computer in $computers) {
        $lastLogon = if ($computer.LastLogonTimestamp) {
            Convert-FileTimeToDateTime $computer.LastLogonTimestamp
        } else {
            "Never"
        }
        
        $results += [PSCustomObject]@{
            Name = $computer.Name
            Enabled = $computer.Enabled
            LastLogon = $lastLogon
            OperatingSystem = $computer.OperatingSystem
            OperatingSystemVersion = $computer.OperatingSystemVersion
            LastLogonDate = $computer.LastLogonDate
            PasswordLastSet = if ($computer.PasswordLastSet) {
                Convert-FileTimeToDateTime $computer.PasswordLastSet
            } else {
                "Never"
            }
            DistinguishedName = $computer.DistinguishedName
            Status = if ($computer.Enabled) {
                if ($lastLogon -ne "Never" -and $lastLogon -lt (Get-Date).AddDays(-$DaysInactive)) {
                    "Inactive"
                } else {
                    "Active"
                }
            } else {
                "Disabled"
            }
        }
    }
    
    # Display results
    if ($results.Count -gt 0) {
        Write-Host "`nFound $($results.Count) computer(s):" -ForegroundColor Green
        
        # Display inactive computers
        $inactiveComputers = $results | Where-Object { $_.Status -eq "Inactive" }
        if ($inactiveComputers.Count -gt 0) {
            Write-Host "`nInactive computers (no logon for $DaysInactive+ days):" -ForegroundColor Yellow
            $inactiveComputers | Format-Table Name, LastLogon, OperatingSystem, Status -AutoSize
        }
        
        # Display disabled computers
        $disabledComputers = $results | Where-Object { $_.Status -eq "Disabled" }
        if ($disabledComputers.Count -gt 0) {
            Write-Host "`nDisabled computers:" -ForegroundColor Red
            $disabledComputers | Format-Table Name, LastLogon, OperatingSystem, Status -AutoSize
        }
        
        # Export to CSV if requested
        if ($ExportToCSV) {
            $date = Get-Date -Format "yyyyMMdd"
            $csvPath = "ADComputerStatus_$date.csv"
            $results | Export-Csv -Path $csvPath -NoTypeInformation
            Write-Host "`nFull report exported to: $csvPath" -ForegroundColor Green
        }
    }
    else {
        Write-Host "No computers found" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
} 