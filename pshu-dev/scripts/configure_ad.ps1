param
(
    [string]$DomainName = "dev.local",
    [string]$DomainNetBiosName = "DEV",
    [string]$SafeModePass = "Admin123#"
)

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
