# Packages to install
$packages = @(
    'git.install',
    '7zip',
    'vscode',
    'sysinternals',
    'helix'
)

if (Get-Command choco -ErrorAction SilentlyContinue) {
    Write-Host "Chocolatey is already installed"
} else {
    Write-Host "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

foreach ($package in $packages) {
    Write-Host "Installing $package"
    choco install $package -y
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
