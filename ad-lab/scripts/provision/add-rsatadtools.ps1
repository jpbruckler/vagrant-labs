$start = Get-Date
$InformationPreference = "Continue"
. $PSScriptRoot\..\utils\deploy-utils.ps1

Write-ProvisionScriptHeader

if ((Get-WindowsFeature -Name RSAT-AD-Tools).Installed -eq $false) {
    Install-WindowsFeature RSAT-AD-Tools -IncludeManagementTools
}

if ((Get-WindowsFeature -Name RSAT-AD-PowerShell).Installed -eq $false) {
    Install-WindowsFeature RSAT-AD-PowerShell -IncludeManagementTools
}

$end = Get-Date
Write-Information -MessageData "Time taken: $(($end - $start).TotalSeconds) seconds."
Write-Information -MessageData "$($MyInvocation.MyCommand.Name) completed."
exit 0