$ip = Get-NetIPAddress -InterfaceAlias Ethernet0 -AddressFamily IPv4 | Select-Object -ExpandProperty IPAddress
$hostname = $env:computername

Write-Output "IP Address:... $ip"
Write-Output "Hostname:..... $hostname"

# Export the IP address and hostname to a text file
"$ip`t$hostname" | Out-File -FilePath C:\vagrant\lab-hosts.txt -Append