$start = Get-Date ([datetime]::UtcNow)
$InformationPreference = "Continue"
. (Join-Path $env:SystemDrive 'vagrant\src\utils\deploy-utils.ps1')

Write-ProvisionScriptHeader -ScriptName 'add-rsatadposh.ps1'
Write-Information -MessageData "Checking for and installing Windows Feature RSAT-AD-PowerShell."

if ((Get-WindowsFeature -Name RSAT-AD-PowerShell).Installed -eq $false) {
    Write-Information -MessageData "`tRSAT-AD-Tools PowerShell module not installed. Installing..."
    try {
        $null = Install-WindowsFeature RSAT-AD-PowerShell -IncludeManagementTools -ErrorAction Stop
        Write-Information -MessageData "`tRSAT-AD-Tools PowerShell module installed."
    } catch {
        Write-Error -Message "Failed to install RSAT-AD-Tools PowerShell module. Exiting."
    }
} else {
    Write-Information -MessageData "`tRSAT-AD-Tools PowerShell module already installed. Nothing to do."
}

$end = Get-Date ([datetime]::UtcNow)
Write-Information -MessageData "Time taken: $((New-TimeSpan -Start $start -End $end).ToString('c'))"
Write-Information -MessageData "Windows feature installation completed."
exit 0