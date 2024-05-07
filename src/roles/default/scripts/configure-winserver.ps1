$start = Get-Date ([datetime]::UtcNow)
$InformationPreference = "Continue"
. (Join-Path $env:SystemDrive 'vagrant\src\utils\deploy-utils.ps1')

Write-ProvisionScriptHeader -ScriptName 'configure-winserver.ps1' 

$pwshInstalled = Get-Command -Name "pwsh" -ErrorAction SilentlyContinue
$chocoInstalled = Get-Command -Name "choco" -ErrorAction SilentlyContinue
$provisionScriptPath = Join-Path $env:SystemDrive 'vagrant\src\roles\default\scripts'


# ------------------------------------------------------------------------------
#
# For the lab environment, both Chocolatey and PowerShell 7 should be installed.
# If either is missing, install them.
# 
# ------------------------------------------------------------------------------
if ($null -eq $chocoInstalled) {
    Write-Information -MessageData "Installing Chocolatey.."
    try {
        & "$env:SystemDrive\vagrant\src\default\install-choco.ps1" -SkipHeader
        $chocoInstalled = $true
    } catch {
        Write-Information -MessageData "`tERROR:Failed to install Chocolatey."
        $rc = 1
    }
}

if ($null -eq $pwshInstalled) {
    Write-Information -MessageData "Installing PowerShell v7.."
    choco install -y powershell-core
    if (Test-Path (Join-Path $env:ProgramFiles 'PowerShell\7\pwsh.exe')) {
        Write-Information -MessageData "`tPowerShell v7 installed."
        $pwshInstalled = $true
    } else {
        Write-Information -MessageData "`tFailed to install PowerShell v7."
        $rc = 1
    }
    
} else {
    Write-Information -MessageData "PowerShell v7 is already installed."
}


# ==============================================================================
# General Windows Server Configuration
# 
#   - sets the execution policy to RemoteSigned
#   - sets PSGallery as a trusted
#   - creates directories for tools and logs
#   - configures default firewall rules
#   - enables Remote Desktop
#   - (Server Core) sets PowerShell v7 as the default shell
#
# ==============================================================================

# ------------------------------------------------------------------------------
# PowerShell Configuration
# ------------------------------------------------------------------------------
Write-Information -MessageData "Setting Execution Policy to RemoteSigned..."
try {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force -ErrorAction Stop
    Write-Information -MessageData "`tExecution Policy set to RemoteSigned."
} catch {
    Write-Information -MessageData "ERROR: Failed to set Execution Policy to RemoteSigned."
    Write-Information -MessageData "$_"
}

Write-Information -MessageData "Setting PSGallery as a trusted repository..."
try {
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction Stop
    Write-Information -MessageData "`tPSGallery set as a trusted repository."
} catch {
    Write-Information -MessageData "ERROR: Failed to set PSGallery as a trusted repository."
    Write-Information -MessageData "$_"
}

# ------------------------------------------------------------------------------
# Filesystem Configuration
# ------------------------------------------------------------------------------
Write-Information -MessageData "Creating directories for tools and logs.."
& "$provisionScriptPath\configure-filesystem.ps1" -SkipHeader


# ------------------------------------------------------------------------------
# Configure default firewall rules
# ------------------------------------------------------------------------------
Write-Information -MessageData "Configuring default firewall rules..."
& "$provisionScriptPath\configure-firewall.ps1" -SkipHeader


# ------------------------------------------------------------------------------
# Enable Remote Desktop
# ------------------------------------------------------------------------------
Write-Information -MessageData "Enabling Remote Desktop..."
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name "fDenyTSConnections" -Value 0

# ------------------------------------------------------------------------------
# Server Core specific configuration
# ------------------------------------------------------------------------------
if ((Get-ItemProperty 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion' -Name 'InstallationType').InstallationType -eq 'Server Core') {
    Write-Information -MessageData 'Windows Server Core detected.'
    Write-Information -MessageData "Setting PowerShell v7 as the default login shell.."
    try {
        # Set pwsh as the default shell
        Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name Shell -Value 'pwsh.exe -NoExit' -ErrorAction Stop
        Write-Information -MessageData "`tSet pwsh as the default login shell."
    } catch {
        Write-Information -MessageData "`tERROR: Failed to set pwsh as the default shell."
    }
}

$end = Get-Date ([datetime]::UtcNow)
Write-Information -MessageData "Time taken: $((New-TimeSpan -Start $start -End $end).ToString('c'))"
Write-Information -MessageData "Server configuration completed."
exit $rc