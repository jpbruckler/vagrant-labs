if (-not (Test-Path -Path "C:\tools" -PathType Container)) {
    New-Item -Path "C:\" -Name "tools" -ItemType "Directory"
}

if (-not (Test-Path -Path "C:\temp" -PathType Container)) {
    New-Item -Path "C:\" -Name "temp" -ItemType "Directory"
}


# Install RSAT-AD-Tools
if ((Get-WindowsFeature -Name RSAT-AD-Tools).Installed -eq $false) {
    Install-WindowsFeature RSAT-AD-Tools -IncludeManagementTools
}

# Install RSAT-AD-PowerShell
if ((Get-WindowsFeature -Name RSAT-AD-PowerShell).Installed -eq $false) {
    Install-WindowsFeature RSAT-AD-PowerShell -IncludeManagementTools
}

# Install Sysinternals Tools
$SysInternalsDownloadUrl = "https://download.sysinternals.com/files/SysinternalsSuite.zip"
$downloaded = Invoke-WebRequest -Uri $SysInternalsDownloadUrl -OutFile "C:\temp\SysinternalsSuite.zip"
Expand-Archive -Path "C:\temp\SysinternalsSuite.zip" -DestinationPath "C:\tools\sysinternals" -Force


# Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force; 
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; 
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install Chocolatey packages
choco install -y git.install
choco install -y 7zip
choco install -y vscode
