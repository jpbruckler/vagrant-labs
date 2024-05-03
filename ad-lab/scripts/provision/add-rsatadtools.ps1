$start = Get-Date
$InformationPreference = "Continue"
. (Join-Path $env:SystemDrive 'vagrant\scripts\utils\deploy-utils.ps1')

Write-ProvisionScriptHeader

if ((Get-WindowsFeature -Name RSAT-AD-Tools).Installed -eq $false) {
    Write-Information -MessageData "`tRSAT-AD-Tools not installed. Installing..."
    Install-WindowsFeature RSAT-AD-Tools -IncludeManagementTools
} else {
    Write-Information -MessageData "`tRSAT-AD-Tools already installed."
}

if ((Get-WindowsFeature -Name RSAT-AD-PowerShell).Installed -eq $false) {
    Write-Information -MessageData "`tRSAT-AD-PowerShell not installed. Installing..."
    Install-WindowsFeature RSAT-AD-PowerShell -IncludeManagementTools
} else {
    Write-Information -MessageData "`tRSAT-AD-PowerShell already installed."
}

$end = Get-Date
Write-Information -MessageData "Time taken: $(($end - $start).TotalSeconds) seconds."
Write-Information -MessageData "$($MyInvocation.MyCommand.Name) completed."
exit 0