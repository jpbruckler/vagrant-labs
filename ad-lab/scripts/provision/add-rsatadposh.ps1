$start = Get-Date
$InformationPreference = "Continue"
. (Join-Path $env:SystemDrive 'vagrant\scripts\utils\deploy-utils.ps1')

Write-ProvisionScriptHeader -ScriptName 'add-rsatadposh.ps1'
if ((Get-WindowsFeature -Name RSAT-AD-PowerShell).Installed -eq $false) {
    Write-Information -MessageData "`tRSAT-AD-Tools PowerShell module not installed. Installing..."
    try {
        Install-WindowsFeature RSAT-AD-PowerShell -IncludeManagementTools
        Write-Information -MessageData "`tRSAT-AD-Tools PowerShell module installed."
    } catch {
        Write-Error -Message "Failed to install RSAT-AD-Tools PowerShell module. Exiting."
    }
} else {
    Write-Information -MessageData "`tRSAT-AD-Tools PowerShell module already installed. Nothing to do."
}

$end = Get-Date
Write-Information -MessageData "Time taken: $((New-TimeSpan -Start $start -End $end).Seconds) seconds."
Write-Information -MessageData "Windows feature installation completed."
exit 0