if ((Get-ItemProperty 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion' -Name 'InstallationType').InstallationType -ne 'Server Core') {
    Write-Error -Message "This script is intended to be run on Server Core only."
    exit 0
}

$start = Get-Date ([datetime]::UtcNow)
$InformationPreference = "Continue"
. (Join-Path $env:SystemDrive 'vagrant\src\utils\deploy-utils.ps1')

Write-ProvisionScriptHeader -ScriptName 'configure-servercore.ps1'
$pwshInstalled = Get-Command -Name "pwsh" -ErrorAction SilentlyContinue
$chocoInstalled = Get-Command -Name "choco" -ErrorAction SilentlyContinue

if ($null -eq $chocoInstalled) {
    Write-Information -MessageData "Installing Chocolatey..."
    # Install Chocolatey
    Set-ExecutionPolicy Bypass -Scope Process -Force; 
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; 
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
} 

if ($null -eq $pwshInstalled) {
    Write-Information -MessageData "Installing PowerShell v7.."
    choco install -y powershell-core
    if (Test-Path (Join-Path $env:ProgramFiles 'PowerShell\7\pwsh.exe')) {
        Write-Information -MessageData "`tPowerShell v7 installed."
    } else {
        Write-Information -MessageData "`tFailed to install PowerShell v7."
    }
} elseif ($null -eq $pwshInstalled -and $null -eq $chocoInstalled) {
    Write-Error -Message "Neither chocolatey or PowerShell 7 are installed. Unable to continue."
} else {
    Write-Information -MessageData "PowerShell v7 is already installed."
    Write-Information -MessageData "Setting PowerShell v7 as the default shell.."
    try {
        # Set pwsh as the default shell
        Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name Shell -Value 'pwsh.exe -NoExit' -ErrorAction Stop
        Write-Information -MessageData "`tSet pwsh as the default shell."
    } catch {
        Write-Error -Message "Failed to set pwsh as the default shell."
    }
}

Write-Information -MessageData "Enabling Remote Desktop..."
$result = Start-Process cscript.exe -ArgumentList 'C:\Windows\System32\Scregedit.wsf /ar 0' -NoNewWindow -Wait -PassThru
if ($result.ExitCode -eq 0) {
    Write-Information -MessageData "`tRemote Desktop enabled."
} else {
    Write-Information -MessageData "Failed to enable Remote Desktop."
}

$end = Get-Date ([datetime]::UtcNow)
Write-Information -MessageData "Time taken: $((New-TimeSpan -Start $start -End $end).ToString('c'))"
Write-Information -MessageData "Server core configuration completed."
exit 0