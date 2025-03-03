# DeployAdditionalController.ps1
# ATENTION! Before running this script, you must join the computer from which it is launched to the domain
# Script to add additional domain controller on dc02

# Settings
$domainName = "garuda.net" # Replace to your domain
$adminUser = "GARUDA\Administrator"  # Replace to your domain admin
$adminPassword = "Pass_12345" | ConvertTo-SecureString -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($adminUser, $adminPassword)

# Function to add additional domain controller on dc02
function Install-AdditionalDC {
    param (
        [string]$ServerName,
        [string]$DomainName,
        [System.Management.Automation.PSCredential]$Credential
    )

    Invoke-Command -ComputerName $ServerName -Credential $Credential -ScriptBlock {
        param ($DomainName)
        
        # Installing AD DS and DNS Roles
        Write-Host "Installing AD DS and DNS Roles..."
        Install-WindowsFeature -Name AD-Domain-Services, DNS -IncludeManagementTools

        # Joining a server to an existing domain as an additional domain controller
        Write-Host "Joining a server to domain $DomainName..."
        Install-ADDSDomainController -DomainName $DomainName -InstallDns -NoRebootOnCompletion -Force -Credential $using:Credential

        # Rebooting server
        Write-Host "Rebooting server $env:COMPUTERNAME after 10 seconds..."
        Start-Sleep -Seconds 10
        Restart-Computer -Force
    } -ArgumentList $DomainName
}

# Installation process
try {
    Write-Host "Starting AD DS installation on server dc02 (adding to existing forest)..."
    Install-AdditionalDC -ServerName "dc02" -DomainName $domainName -Credential $credential
    Write-Host "Установка AD DS на сервере dc02 завершена. Сервер будет перезагружен."
} catch {
    Write-Host "Error installing AD DS on server dc02: $_"
    exit
}

Write-Host "Adding additional domain controller completed successfully!"