param(
    [string] $NicAlias,
    [string] $IpAddress,
    [string] $Gateway,
    [string] $DnsServer,
    [string] $DnsSuffix,
    [string[]] $DnsSearchList,
    [int] $MaskBits = 24
)


Write-Host "Static IP Configuration for box $($env:COMPUTERNAME)"

$Nic = Get-NetAdapter -Name $NicAlias
if (($Nic | Get-NetIPConfiguration).IPv4Address.IPAddress) {
    Write-Host "Removing existing IP configuration..."
    Remove-NetIPAddress -InterfaceIndex $Nic.InterfaceIndex -Confirm:$false
}


Write-Host "Configuring static IP address..."
$Nic | New-NetIPAddress -IPAddress $IpAddress -PrefixLength $MaskBits -DefaultGateway $Gateway

Write-Host "Configuring DNS server..."
$Nic | Set-DnsClientServerAddress -ServerAddresses $DnsServer

if ($DnsSearchList) {
    Write-Host "Configuring DNS search list..."
    Set-DnsClientGlobalSetting -SuffixSearchList $DnsSearchList
}

Write-Host "End of Static IP Configuration for box $($env:COMPUTERNAME)"