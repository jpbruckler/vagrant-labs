param(
    [string] $Identity = "dev\svc-irms",
    [string[]] $AccountRights = @("SeServiceLogonRight", "SeBatchLogonRight", "SeInteractiveLogonRight")
)

$start = Get-Date ([datetime]::UtcNow)
$InformationPreference = "Continue"
. (Join-Path $env:SystemDrive 'vagrant\src\utils\deploy-utils.ps1')

Write-ProvisionScriptHeader -ScriptName 'grant-serviceaccountrights.ps1'


if (-not (Get-Module -ListAvailable -Name 'Carbon')) {
    Write-Information -MessageData "Installing Carbon module for local group management..."
    Install-Module -Name 'Carbon' -Force -AcceptLicense -Scope AllUsers
    Import-Module -Name 'Carbon' -Force
    Write-Information -MessageData "`tCarbon module installed."
}

try {
    Write-Information -MessageData "Adding service account to Perfomance Monitor Users group..."
    Add-CGroupMember -Name 'Performance Monitor Users' -Member $Identity -ErrorAction Stop

    Write-Information -MessageData "Adding service account to Performance Log Users group..."
    Add-CGroupMember -Name 'Performance Log Users' -Member $Identity -ErrorAction Stop

    Write-Information -MessageData "Setting local user rights for service account..."
} catch {
    Write-Error -Message "Failed to add service account to Performance Monitor Users or Performance Log Users group. $_"
    $LASTEXITCODE = 1
}

$failed = @()
$AccountRights | ForEach-Object {
    $Privilege = $_
    Write-Information -MessageData "`tGranting $Privilege to $Identity..."
    try {
        Grant-CPrivilege -Identity $Identity -Privilege $Privilege -ErrorAction Stop
    } catch {
        $failed += $Privilege
        Write-Information -MessageData "`tFailed to grant $Privilege to $Identity."
        continue;
    }
}


if ($failed.Count -gt 0) {
    Write-Error -Message "Failed to grant the following privileges to $($Identity): $($failed -join ', ')"
    $LASTEXITCODE = 1
}

$end = Get-Date ([datetime]::UtcNow)
Write-Information -MessageData "Time taken: $((New-TimeSpan -Start $start -End $end).ToString('c'))"
Write-Information -MessageData "Service account configuration completed."
exit $LASTEXITCODE