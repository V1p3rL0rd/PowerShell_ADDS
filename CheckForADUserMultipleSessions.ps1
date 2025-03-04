# Import Active Directory module
Import-Module ActiveDirectory

# Settings
$pollingInterval = 10  # Interval between polls in seconds (to reduce load when scanning large networks)

# Function to get list of Windows servers
function Get-DomainServers {
    Get-ADComputer -Filter { 
        OperatingSystem -like "*Windows Server*" -and 
        Enabled -eq $true 
    } -Property Name, OperatingSystem | 
    Select-Object Name, OperatingSystem
}

# Function to test computer connectivity
function Test-ComputerConnection {
    param ([string]$ComputerName)
    Test-Connection -ComputerName $ComputerName -Count 1 -Quiet -ErrorAction SilentlyContinue
}

# Function to get active RDP sessions
function Get-RDPSessions {
    param ([string]$ComputerName)
    try {
        $sessions = qwinsta /server:$ComputerName 2>&1 | Select-Object -Skip 1 | ForEach-Object {
            $session = $_ -split '\s+'
            [PSCustomObject]@{
                ComputerName = $ComputerName
                SessionName  = $session[0]
                Username     = $session[1]
                SessionID    = $session[2]
                State        = $session[3]
                Type         = $session[4]
            }
        }
        return $sessions | Where-Object { $_.Username -ne "" -and $_.Username -ne "USERNAME" }
    } catch {
        Write-Warning ("RDP: Error on {0}: {1}" -f $ComputerName, $_.Exception.Message)
        return @()
    }
}

# Function to get active SMB sessions
function Get-SMBSessions {
    param ([string]$ComputerName)
    try {
        $sessions = Get-SmbSession -CimSession $ComputerName -ErrorAction Stop 2>&1
        return $sessions | ForEach-Object {
            [PSCustomObject]@{
                ComputerName = $ComputerName
                Username     = $_.ClientUserName
                SessionID    = $_.SessionId
            }
        }
    } catch {
        Write-Warning ("SMB: Error on {0}: {1}" -f $ComputerName, $_.Exception.Message)
        return @()
    }
}

# Function to get logged-on users info
function Get-LoggedOnUsers {
    param ([string]$ComputerName)
    try {
        $session = New-CimSession -ComputerName $ComputerName -ErrorAction Stop
        $users = Get-CimInstance -CimSession $session -ClassName Win32_ComputerSystem | Select-Object -ExpandProperty UserName
        Remove-CimSession -CimSession $session
        return $users | ForEach-Object {
            [PSCustomObject]@{
                ComputerName = $ComputerName
                Username     = $_
            }
        }
    } catch {
        Write-Warning ("Logins: Error on {0}: {1}" -f $ComputerName, $_.Exception.Message)
        return @()
    }
}

# Main script
$servers = Get-DomainServers
$allSessions = @()
$totalServers = $servers.Count
$currentCount = 0

Write-Host "Found servers: $totalServers" -ForegroundColor Cyan

foreach ($server in $servers) {
    $currentCount++
    $computer = $server.Name
    Write-Host "[$currentCount/$totalServers] Checking $computer ($($server.OperatingSystem))..." -ForegroundColor Cyan
    
    if (-not (Test-ComputerConnection -ComputerName $computer)) {
        Write-Warning "Server $computer is unreachable!"
        continue
    }

    # Data collection
    $rdpSessions = Get-RDPSessions -ComputerName $computer
    $smbSessions = Get-SMBSessions -ComputerName $computer
    $loggedOnUsers = Get-LoggedOnUsers -ComputerName $computer

    $allSessions += $rdpSessions + $smbSessions + $loggedOnUsers

    if ($currentCount -ne $totalServers) {
        Write-Host "Pausing for $pollingInterval seconds..." -ForegroundColor DarkGray
        Start-Sleep -Seconds $pollingInterval
    }
}

# Grouping and output results
$userSessions = $allSessions | Group-Object Username | Where-Object { $_.Count -gt 1 }

if ($userSessions.Count -gt 0) {
    Write-Host "`nResults (users with multiple connections):`n" -ForegroundColor Green
    $userSessions | ForEach-Object {
        Write-Host "User: $($_.Name)" -ForegroundColor Yellow
        $_.Group | ForEach-Object {
            $type = switch -Wildcard ($_.Type) {
                "RDP*"      { "Remote Desktop" }
                "SMB*"      { "File Sharing" }
                default     { "Local Login" }
            }
            Write-Host "  ├─ Computer: $($_.ComputerName)"
            Write-Host "  ├─ Type: $type"
            Write-Host "  └─ Session ID: $($_.SessionID)`n"
        }
    }
} else {
    Write-Host "`nNo active users with multiple connections found." -ForegroundColor Green
}