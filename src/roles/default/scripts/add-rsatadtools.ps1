$start = Get-Date ([datetime]::UtcNow)
$InformationPreference = "Continue"
. (Join-Path $env:SystemDrive 'vagrant\src\utils\deploy-utils.ps1')

Write-ProvisionScriptHeader -ScriptName 'add-rsatadtools.ps1'
Write-Information -MessageData "Checking for and installing Windows Features RSAT-AD-Tools and RSAT-AD-PowerShell."

if ((Get-WindowsFeature -Name RSAT-AD-Tools).Installed -eq $false) {
    Write-Information -MessageData "`tRSAT-AD-Tools not installed. Installing..."
    $null = Install-WindowsFeature RSAT-AD-Tools -IncludeManagementTools
} else {
    Write-Information -MessageData "`tRSAT-AD-Tools already installed."
}

if ((Get-WindowsFeature -Name RSAT-AD-PowerShell).Installed -eq $false) {
    Write-Information -MessageData "`tRSAT-AD-PowerShell not installed. Installing..."
    $null = Install-WindowsFeature RSAT-AD-PowerShell -IncludeManagementTools
} else {
    Write-Information -MessageData "`tRSAT-AD-PowerShell already installed."
}

$end = Get-Date ([datetime]::UtcNow)
Write-Information -MessageData "Time taken: $((New-TimeSpan -Start $start -End $end).ToString('c'))"
Write-Information -MessageData "Windows Feature installation completed."
exit 0