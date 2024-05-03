$start = Get-Date
$InformationPreference = "Continue"
. (Join-Path $env:SystemDrive 'vagrant\scripts\utils\deploy-utils.ps1')

Write-ProvisionScriptHeader -ScriptName 'add-rsatadtools.ps1'

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
Write-Information -MessageData "Time taken: $((New-TimeSpan -Start $start -End $end).Seconds) seconds."
Write-Information -MessageData "Windows Feature installation completed."
exit 0