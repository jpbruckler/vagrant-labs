param(
    [string[]] $Packages
)

$Packages += 'sysinternals'

$ErrorActionPreference = "Stop"

if (-not (Test-Path 'C:\ProgramData\chocolatey')) {
    Write-Host "Chocolatey is not installed. Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force; 
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; 
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

if ($Packages) {
    Write-Host "Installing Chocolatey packages..."
    foreach ($Package in $Packages) {
        Write-Host "Installing $Package..."
        choco install $Package -y
    }
}

Write-Host "Chocolatey packages installed"
Write-Host "Updating PATH environment variable..."

# Update PATH environment variable
$chocoBinPath = [System.Environment]::GetEnvironmentVariable('ChocolateyInstall', 'Machine') + '\bin'
$oldPaths = [Environment]::GetEnvironmentVariable('PATH', 'Machine')
$newPaths = $oldPaths + ';' + $chocoBinPath
[Environment]::SetEnvironmentVariable('PATH', $newPaths, 'Machine')

Write-Host "Updated machine PATH environment variable to:"
[Environment]::GetEnvironmentVariable('PATH', 'Machine')

if (Test-Path "$PSHOME\profile.ps1") {
    Write-Host "System-wide PowerShell profile exists. Updating profile..."
} else {
    Write-Host "System-wide PowerShell profile does not exist. Creating profile..."
    New-Item -Path $PSHOME -Name 'profile.ps1' -ItemType 'file' -Force
    Write-Host "Profile created"
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

Write-Host "Updating system-wide PowerShell profile..."
$newContent + "`n`n" + (Get-Content $profilePath -Raw) | Set-Content $profilePath -Force
. $profilePath

Write-Host "System-wide PowerShell profile updated."