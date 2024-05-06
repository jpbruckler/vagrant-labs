$start = Get-Date ([datetime]::UtcNow)
$InformationPreference = "Continue"
. (Join-Path $env:SystemDrive 'vagrant\scripts\utils\deploy-utils.ps1')

Write-ProvisionScriptHeader -ScriptName 'configure-servercore.ps1'

$pwshInstalled = Get-Command -Name "pwsh" -ErrorAction SilentlyContinue
$chocoInstalled = Get-Command -Name "choco" -ErrorAction SilentlyContinue


# ------------------------------------------------------------------------------
#
# For the lab environment, both Chocolatey and PowerShell 7 should be installed.
# If either is missing, install them.
# 
# ------------------------------------------------------------------------------
if ($null -eq $chocoInstalled) {
    Write-Information -MessageData "Installing Chocolatey.."
    try {
        & "$env:SystemDrive\vagrant\scripts\provision\install-choco.ps1" -SkipHeader
        $chocoInstalled = $true
    } catch {
        Write-Information -MessageData "`tERROR:Failed to install Chocolatey."
        $rc = 1
    }
}

if ($null -eq $pwshInstalled) {
    Write-Information -MessageData "Installing PowerShell v7.."
    try {
        choco install -y powershell-core
        Write-Information -MessageData "`tPowerShell v7 installed."
        $pwshInstalled = $true
    } catch {
        Write-Information -MessageData "`tERROR: Failed to install PowerShell v7."
        $rc = 1
    }
} else {
    Write-Information -MessageData "PowerShell v7 is already installed."
}

if ($rc -ne 0) {
    Write-Information -MessageData "ERROR: Failed to install Chocolatey or PowerShell v7. Unable to continue."
    exit $rc
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
}

Write-Information -MessageData "Setting PSGallery as a trusted repository..."
try {
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction Stop
    Write-Information -MessageData "`tPSGallery set as a trusted repository."
} catch {
    Write-Information -MessageData "ERROR: Failed to set PSGallery as a trusted repository."
}

# ------------------------------------------------------------------------------
# Filesystem Configuration
# ------------------------------------------------------------------------------
Write-Information -MessageData "Creating directories for tools and logs.."
& "$env:SystemDrive\vagrant\scripts\provision\configure-filesystem.ps1" -SkipHeader


# ------------------------------------------------------------------------------
# Configure default firewall rules
# ------------------------------------------------------------------------------
Write-Information -MessageData "Configuring default firewall rules..."
& "$env:SystemDrive\vagrant\scripts\provision\configure-firewall.ps1" -SkipHeader


# ------------------------------------------------------------------------------
# Enable Remote Desktop
# ------------------------------------------------------------------------------
Write-Information -MessageData "Enabling Remote Desktop..."
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name "fDenyTSConnections" -Value 0

# ------------------------------------------------------------------------------
# Server Core specific configuration
# ------------------------------------------------------------------------------
if ((Get-ItemProperty 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion' -Name 'InstallationType').InstallationType -ne 'Server Core') {
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