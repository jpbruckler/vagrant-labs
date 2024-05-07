$start = Get-Date ([datetime]::UtcNow)
$InformationPreference = "Continue"
. (Join-Path $env:SystemDrive 'vagrant\src\utils\deploy-utils.ps1')
$LASTEXITCODE = 0
Write-ProvisionScriptHeader -ScriptName 'create-pwshufirewallrule.ps1'

Write-Information -MessageData "Checking for existing firewall rule..."

$fwRule = Get-NetFirewallRule | Where-Object { $_.DisplayName -match 'PowerShell Universal' }

if ($null -eq $fwRule) {
    Write-Information -MessageData "Creating firewall rule for PowerShell Universal..."
    $null = New-NetFirewallRule -DisplayName "PowerShell Universal" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 5000, 80, 443
    Write-Information -MessageData "`tFirewall rule created."
}
else {
    Write-Information -MessageData "`tFirewall rule for PowerShell Universal already exists."
}

$end = Get-Date ([datetime]::UtcNow)
Write-Information -MessageData "Time taken: $((New-TimeSpan -Start $start -End $end).ToString('c'))"
Write-Information -MessageData "PowerShell Universal firewall configuration completed."
exit $LASTEXITCODE