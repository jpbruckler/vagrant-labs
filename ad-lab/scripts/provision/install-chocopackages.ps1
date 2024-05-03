param(
    [System.Collections.Generic.List[string]] $Packages
)

$start = Get-Date
$InformationPreference = "Continue"
$ErrorActionPreference = "Stop"
. (Join-Path $env:SystemDrive 'vagrant\scripts\utils\deploy-utils.ps1')
Write-ProvisionScriptHeader -ScriptName 'install-chocopackages.ps1'
$rc = 0

if (-not $Packages) {
    $Packages = New-Object 'System.Collections.Generic.List[string]'
}
$null = $Packages.add('sysinternals')
$null = $Packages.add('powershell-core')

Write-Information -MessageData "Chocolatey packages to install:"
Write-Information -MessageData ("`t{0}" -f ($Packages -join "`n`t"))

if (-not (Test-Path 'C:\ProgramData\chocolatey')) {
    Write-Information -MessageData "Chocolatey is not installed. Installing Chocolatey..."
    Start-Process powershell.exe -ArgumentList "-File $env:SystemDrive\vagrant\scripts\provision\install-choco.ps1 -NoProfile" -Wait
}

if ($Packages) {
    Write-Information -MessageData "Installing Chocolatey packages..."
    foreach ($Package in $Packages) {
        Write-Information -MessageData "`tInstalling $Package..."
        choco install $Package -y
    }
}

Write-Information -MessageData "Chocolatey packages installed"
Write-Information -MessageData "Updating PATH environment variable..."

$end = Get-Date
Write-Information -MessageData "Time taken: $((New-TimeSpan -Start $start -End $end).ToString('c'))"
Write-Information -MessageData "Chocolatey package installation completed."
exit $rc