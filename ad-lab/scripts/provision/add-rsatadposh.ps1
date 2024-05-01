if ((Get-WindowsFeature -Name RSAT-AD-PowerShell).Installed -eq $false) {
    Install-WindowsFeature RSAT-AD-PowerShell -IncludeManagementTools
}
