
$start = Get-Date
$InformationPreference = "Continue"
. (Join-Path $env:SystemDrive 'vagrant\scripts\utils\deploy-utils.ps1')

Write-ProvisionScriptHeader
$pwshInstalled = Get-Command -Name "PowerShell" -ErrorAction SilentlyContinue
$chocoInstalled = Get-Command -Name "Chocolatey" -ErrorAction SilentlyContinue

if ($null -eq $pwshInstalled -and $null -ne $chocoInstalled) {
    Write-Information -MessageData "Installing PowerShell v7.."
    try {
        choco install -y powershell-core
        Write-Information -MessageData "`tPowerShell v7 installed."
    } catch {
        Write-Error -Message "Failed to install PowerShell v7."
    }
} elseif ($null -eq $pwshInstalled -and $null -eq $chocoInstalled) {
    Write-Error -Message "Neither chocolatey or PowerShell 7 are installed. Unable to cotinue."
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

$end = Get-Date
Write-Information -MessageData "Time taken: $(($end - $start).TotalSeconds) seconds."
Write-Information -MessageData "$($MyInvocation.MyCommand.Name) completed."
exit 0