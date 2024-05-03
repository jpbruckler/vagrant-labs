param(
    [string[]] $Packages
)

$start = Get-Date
$InformationPreference = "Continue"
$ErrorActionPreference = "Stop"
. (Join-Path $env:SystemDrive 'vagrant\scripts\utils\deploy-utils.ps1')
Write-ProvisionScriptHeader -ScriptName 'install-chocopackages.ps1'
$rc = 0

$Packages += 'sysinternals'
$Pachages += 'powershell-core'

if (-not (Test-Path 'C:\ProgramData\chocolatey')) {
    Write-Information -MessageData "Chocolatey is not installed. Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force; 
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; 
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
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

# Update PATH environment variable
$chocoBinPath = [System.Environment]::GetEnvironmentVariable('ChocolateyInstall', 'Machine') + '\bin'
$oldPaths = [Environment]::GetEnvironmentVariable('PATH', 'Machine')
$newPaths = $oldPaths + ';' + $chocoBinPath
[Environment]::SetEnvironmentVariable('PATH', $newPaths, 'Machine')

Write-Information -MessageData "`tUpdated machine PATH environment variable to:"
[Environment]::GetEnvironmentVariable('PATH', 'Machine')

if (Test-Path "$PSHOME\profile.ps1") {
    Write-Host "System-wide PowerShell profile exists. Updating profile..."
} else {
    Write-Information -MessageData "`tSystem-wide PowerShell profile does not exist. Creating profile..."
    New-Item -Path $PSHOME -Name 'profile.ps1' -ItemType 'file' -Force
    Write-Information -MessageData "`tProfile created"
}

# Update system-wide PowerShell profile
$profilePath = "$PSHOME\profile.ps1"
$newContent = @'
# Ensure Chocolatey install is set
if (-not $env:ChocolateyInstall) {
    [System.Environment]::SetEnvironmentVariable('ChocolateyInstall', (Join-Path $env:ProgramData 'chocolatey\bin'))
}

# Add Chocolatey install to PATH
$env:PATH = ($env:PATH + ';' + $env:ChocolateyInstall + ';' + (Join-Path $env:ProgramFiles 'Microsoft VS Code\bin') ) -replace ';;', ';'
'@

Write-Information -MessageData "`tUpdating system-wide PowerShell profile..."
$newContent + "`n`n" + (Get-Content $profilePath -Raw) | Set-Content $profilePath -Force
. $profilePath

Write-Information -MessageData "`tSystem-wide PowerShell profile updated."

$end = Get-Date
Write-Information -MessageData "Time taken: $((New-TimeSpan -Start $start -End $end).Seconds) seconds."
Write-Information -MessageData "Chocolatey package installation completed."
exit $rc