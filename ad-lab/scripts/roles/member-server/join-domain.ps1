param (
    [string] $DomainName = "dev.local",
    [string] $DnsServer = "",
    [string] $DomainAdminUser = "vagrant",
    [string] $DomainAdminPassword = "vagrant"
)

if ($DnsServer) {
    Set-DnsClientServerAddress -ServerAddresses $DnsServer
}

$UpdatedSearchList = @()
$UpdatedSearchList += $DomainName
Get-DnsClientGlobalSetting | Select-Object -ExpandProperty SuffixSearchList | Foreach-Object { 
    $UpdatedSearchList += "$_" 
}


Set-DnsClientGlobalSetting -SuffixSearchList ($UpdatedSearchList -join ',')

# Create the credential object
$securePassword = ConvertTo-SecureString $DomainAdminPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($DomainAdminUser, $securePassword)

# Join the computer to the domain
# reboot to be handled by vagrant
Add-Computer -DomainName $DomainName -Credential $credential