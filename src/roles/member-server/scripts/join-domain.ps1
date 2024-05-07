<#
    .SYNOPSIS
    Configures DNS settings and joins the computer to a specified domain.

    .DESCRIPTION
        This script sets the DNS client server address if specified, updates the
        DNS suffix search list with the domain name, and joins the computer to
        the provided domain using specified domain admin credentials. The
        computer must be rebooted after running this script to complete the
        domain join process. This reboot should be handled in the Vagrantfile.

    .PARAMETER DomainName
        The name of the domain to join. Default is "dev.local".

        This is controlled in provision.yaml using the env: block.
        
        env:
          labdomain: dev.local

    .PARAMETER DnsServer
        The IP address of the DNS server to use. If not specified, the DNS
        server address is not changed.

        This is controlled in provision.yaml using the env: block.

        env:
          labdns: 192.168.13.10

    .PARAMETER DomainAdminUser
        The username of the domain administrator used to join the domain. Default
        is "vagrant".

    .PARAMETER DomainAdminPassword
        The password for the domain administrator. Default is "vagrant".

    .EXAMPLE
        PS> .\ScriptName.ps1 -DomainName 'dev.local' -DnsServer '192.168.1.1' -DomainAdminUser 'admin' -DomainAdminPassword 'password'
        Sets the DNS server address, updates the DNS suffix search list, and
        joins the computer to the 'dev.local' domain using the provided admin
        credentials.

    .EXAMPLE
        PS> .\ScriptName.ps1
        Joins the computer to the 'dev.local' domain with default admin
        credentials without changing DNS server settings.

    .NOTES
        Ensure the script is run with administrative privileges.
        Reboot the computer after execution to complete the domain join process.
#>
param (
    [string] $DomainName = $env:labdomain,
    [string] $DnsServer = $env:labdns,
    [string] $DomainAdminUser = "vagrant",
    [string] $DomainAdminPassword = "vagrant"
)

$start = Get-Date ([datetime]::UtcNow)
$InformationPreference = "Continue"
. (Join-Path $env:SystemDrive 'vagrant\src\utils\deploy-utils.ps1')

Write-ProvisionScriptHeader -ScriptName 'join-domain.ps1'

Write-Information -MessageData "Setting DNS server address and joining the computer to the domain..."
Write-Information -MessageData "`tDomain: $DomainName"
Write-Information -MessageData "`tDNS Server: $DnsServer"
Write-Information -MessageData "`tDomain Admin User: $DomainAdminUser"


if ($DnsServer) {
    Write-Information -MessageData "`tSetting DNS server address to $DnsServer for interface 'Ethernet0'."
    Set-DnsClientServerAddress -ServerAddresses $DnsServer -InterfaceAlias 'Ethernet0'
}

$UpdatedSearchList = @()
$UpdatedSearchList += $DomainName
Write-Information -MessageData "`tUpdating DNS suffix search list with domain name '$DomainName'."
Get-DnsClientGlobalSetting | Select-Object -ExpandProperty SuffixSearchList | Foreach-Object { 
    $UpdatedSearchList += "$_" 
}

Set-DnsClientGlobalSetting -SuffixSearchList ($UpdatedSearchList -join ',')

# Create the credential object
$securePassword = ConvertTo-SecureString $DomainAdminPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($DomainAdminUser, $securePassword)

# Join the computer to the domain
# reboot to be handled by vagrant

try {
    Add-Computer -DomainName $DomainName -Credential $credential -ErrorAction Stop
} catch {
    Write-Error -MessageData "Failed to join the computer to the domain. Error: $_"
    exit 1
}


$end = Get-Date ([datetime]::UtcNow)
Write-Information -MessageData "Time taken: $((New-TimeSpan -Start $start -End $end).ToString('c'))"
Write-Information -MessageData "Member join completed."
exit $LASTEXITCODE