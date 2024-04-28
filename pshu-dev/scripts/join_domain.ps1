param (
    [string]$DomainName = "dev.local",
    [string]$DomainAdminUser = "vagrant",
    [string]$DomainAdminPassword = "vagrant"
)


# Create the credential object
$securePassword = ConvertTo-SecureString $DomainAdminPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($DomainAdminUser, $securePassword)
Add-Computer -DomainName $DomainName -Credential $credential