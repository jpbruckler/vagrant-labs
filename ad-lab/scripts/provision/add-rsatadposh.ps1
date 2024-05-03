$start = Get-Date
$InformationPreference = "Continue"
. $PSScriptRoot\..\utils\deploy-utils.ps1

Write-ProvisionScriptHeader
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
Write-Information -MessageData "Time taken: $(($end - $start).TotalSeconds) seconds."
Write-Information -MessageData "$($MyInvocation.MyCommand.Name) completed."
exit 0