param
(
    [string]$DomainName = "dev.local",
    [string]$DomainNetBiosName = "DEV",
    [string]$SafeModePass = "Admin123#"
)

Write-Host "Installing Active Directory Domain Services and DNS..."

Import-Module ServerManager


Install-WindowsFeature AD-Domain-Services, DNS -IncludeManagementTools
Install-ADDSForest `
    -DatabasePath "C:\Windows\NTDS" `
    -DomainMode WinThreshold `
    -DomainName "$DomainName" `
    -DomainNetbiosName "$DomainNetBiosName" `
    -ForestMode WinThreshold `
    -InstallDns `
    -LogPath "C:\Windows\NTDS" `
    -NoRebootOnCompletion `
    -SysvolPath "C:\Windows\SYSVOL" `
    -SafeModeAdministratorPassword (ConvertTo-SecureString "$SafeModePass" -AsPlainText -Force) `
    -Force

([WMIClass]'Win32_NetworkAdapterConfiguration').SetDNSSuffixSearchOrder($DomainName) | Out-Null
