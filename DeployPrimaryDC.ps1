# DeployPrimaryDC.ps1
# Script to deploy primary domain controller on dc01

# Параметры
$domainName = "domain.com"
$domainMode = "WinThreshold"  # Domain Mode for Windows Server 2016
$forestMode = "WinThreshold"  # Forest Mode for Windows Server 2016
$adminUser = "Administrator"  # Admin user
$adminPassword = "Pass_12345" | ConvertTo-SecureString -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($adminUser, $adminPassword)

# Function to create a new forest on dc01
function Install-NewForest {
    param (
        [string]$ServerName,
        [string]$DomainName,
        [string]$DomainMode,
        [string]$ForestMode,
        [System.Management.Automation.PSCredential]$Credential
    )

    Invoke-Command -ComputerName $ServerName -Credential $Credential -ScriptBlock {
        param ($DomainName, $DomainMode, $ForestMode)
        
        # Installing AD DS and DNS Roles
        Write-Host "Installing AD DS and DNS Roles..."
        Install-WindowsFeature -Name AD-Domain-Services, DNS -IncludeManagementTools

        # Creating a new forest and domain
        Write-Host "Creating a new forest and domain..."
        Install-ADDSForest -DomainName $DomainName -DomainMode $DomainMode -ForestMode $ForestMode -InstallDns -Force -NoRebootOnCompletion

        # Reboot server
        Write-Host "Reboot server $env:COMPUTERNAME after 10 seconds..."
        Start-Sleep -Seconds 10
        Restart-Computer -Force
    } -ArgumentList $DomainName, $DomainMode, $ForestMode
}

# Installation process
try {
    Write-Host "Start to install AD DS on host dc01 (Creating a new AD forest)..."
    Install-NewForest -ServerName "dc01" -DomainName $domainName -DomainMode $domainMode -ForestMode $forestMode -Credential $credential
    Write-Host "AD DS installation on host dc01 successfully completed! Server will be rebooted."
} catch {
    Write-Host "AD DS Installation error on dc01: $_"
    exit
}

Write-Host "Primary Domain Controller deployment completed successfully!"