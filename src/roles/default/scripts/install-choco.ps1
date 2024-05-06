param(
    [switch] $SkipHeader
)

if (-not $SkipHeader) {
    $start = Get-Date ([datetime]::UtcNow)
    $InformationPreference = "Continue"
    . (Join-Path $env:SystemDrive 'vagrant\src\utils\deploy-utils.ps1')
    Write-ProvisionScriptHeader -ScriptName 'install-choco.ps1'
    $rc = 0
}

$rc = 0

if ($null -eq (Get-Command -Name "choco" -ErrorAction SilentlyContinue)) {
    Write-Information -MessageData "Installing Chocolatey..."
    # Install Chocolatey
    Set-ExecutionPolicy Bypass -Scope Process -Force; 
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; 
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
} else {
    Write-Information -MessageData "Chocolatey is already installed. Nothing to do."
}


if (-not $SkipHeader) {
    $end = Get-Date ([datetime]::UtcNow)
    Write-Information -MessageData "Time taken: $((New-TimeSpan -Start $start -End $end).ToString('c'))"
    Write-Information -MessageData "Chocolatey installation completed."
}
exit $rc