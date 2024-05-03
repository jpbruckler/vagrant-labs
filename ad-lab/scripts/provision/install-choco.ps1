$start = Get-Date
$InformationPreference = "Continue"
. (Join-Path $env:SystemDrive 'vagrant\scripts\utils\deploy-utils.ps1')
Write-ProvisionScriptHeader
$rc = 0

if ($null -eq (Get-Command -Name "choco" -ErrorAction SilentlyContinue)) {
    Write-Information -MessageData "Installing Chocolatey..."
    # Install Chocolatey
    Set-ExecutionPolicy Bypass -Scope Process -Force; 
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; 
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
} else {
    Write-Information -MessageData "Chocolatey is already installed."
    Write-Information -MessageData "Exiting..."
}


$end = Get-Date
Write-Information -MessageData "Time taken: $(($end - $start).TotalSeconds) seconds."
Write-Information -MessageData "$($MyInvocation.MyCommand.Name) completed."
exit $rc