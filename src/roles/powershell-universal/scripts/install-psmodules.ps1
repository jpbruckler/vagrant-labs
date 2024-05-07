$start = Get-Date ([datetime]::UtcNow)
$InformationPreference = "Continue"
. (Join-Path $env:SystemDrive 'vagrant\src\utils\deploy-utils.ps1')

Write-ProvisionScriptHeader -ScriptName 'install-psmodules.ps1'

Write-Information -MessageData "Installing PowerShell modules."

if ((Get-PSRepository PSGallery).Trusted -eq $false) {
    Write-Information -MessageData "`tTrusting PSGallery repository..."
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
}

if (-not (Get-Module -ListAvailable -Name 'Carbon')) {
    Write-Information -MessageData "`tInstalling Carbon module for local group management..."
    try {
        Install-Module -Name 'Carbon' -Force -Scope AllUsers -ErrorAction Stop -AllowClobber
    } catch {
        Write-Information -MessageData "Failed to install Carbon module. $_"
        $LASTEXITCODE = 1
    }
    
}

if (-not (Get-Module -ListAvailable -Name 'Universal')) {
    Write-Information -MessageData "`tInstalling Universal module for PowerShell Universal management..."
    try {
        Install-Module -Name 'Universal' -Force -Scope AllUsers -ErrorAction Stop -AllowClobber
    } catch {
        Write-Information -MessageData "Failed to install ActiveDirectory module. $_"
        $LASTEXITCODE = 1
    }
}

$end = Get-Date ([datetime]::UtcNow)
Write-Information -MessageData "Time taken: $((New-TimeSpan -Start $start -End $end).ToString('c'))"
Write-Information -MessageData "PowerShell Module installation completed."
exit $LASTEXITCODE