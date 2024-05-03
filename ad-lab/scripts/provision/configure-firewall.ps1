$start = Get-Date
$InformationPreference = "Continue"
. $PSScriptRoot\..\utils\deploy-utils.ps1

Write-ProvisionScriptHeader

$Rules = @(
    "Windows Management Instrumentation (DCOM-In)",
    "Remote Event Log Management",
    "Remote Service Management",
    "Remote Volume Management",
    "Remote Scheduled Tasks Management",
    "Windows Defender Firewall Remote Management",
    "Windows Remote Management"
)

foreach ($Rule in $Rules) {
    $ruleObject = Get-NetFirewallRule -DisplayName $Rule -ErrorAction SilentlyContinue

    if ($null -eq $ruleObject) {
        Write-Warning -Message "Firewall rule '$Rule' not found."
        continue
    }

    if ($ruleObject.Enabled) {
        Write-Information -MessageData "`tFirewall rule '$Rule' already enabled."
        continue
    } else {
        Write-Information -MessageData "`tEnabling firewall rule '$Rule'."
        try {
            $null = Enable-NetFireWallRule -DisplayName $Rule -ErrorAction Stop
            Write-Information -MessageData "`tFirewall rule '$Rule' enabled."
        } catch {
            Write-Error -Message "Failed to enable firewall rule '$Rule'."
            continue;
        }
    }
    
}

$end = Get-Date
Write-Information -MessageData "Time taken: $(($end - $start).TotalSeconds) seconds."
Write-Information -MessageData "$($MyInvocation.MyCommand.Name) completed."
exit 0