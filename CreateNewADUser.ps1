# Domain user
$username = "Smith_John"

# Password
$password = ConvertTo-SecureString "Qwerty_12345" -AsPlainText -Force

# OU
$ou = "OU=Accounts,DC=garuda,DC=net"  # Replace to your OU and domain

# Security group
$groupName = "gr_accounts"

# Creating domain user
New-ADUser -Name $username `
            -GivenName "John" `
            -Surname "Smith" `
            -SamAccountName $username `
            -UserPrincipalName "$username@garuda.net" `
            -AccountPassword $password `
            -Enabled $true `
            -Path $ou `
            -ChangePasswordAtLogon $true

Write-Host "User $username successfully created in OU $ou."

# Adding a user to a security group
Add-ADGroupMember -Identity $groupName -Members $username

Write-Host "User $username has been added to group $groupName."
