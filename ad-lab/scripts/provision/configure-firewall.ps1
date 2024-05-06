param(
    [switch] $SkipHeader
)


if (-not $SkipHeader) {
    $start = Get-Date
    $InformationPreference = "Continue"
    . (Join-Path $env:SystemDrive 'vagrant\scripts\utils\deploy-utils.ps1')

    Write-ProvisionScriptHeader -ScriptName 'configure-firewall.ps1'
}
$rc = 0

$Rules = @(
    @{ Property = "DisplayName"; Value = "Windows Management Instrumentation (DCOM-In)" },
    @{ Property = "DisplayGroup"; Value = "Remote Event Log Management" },
    @{ Property = "DisplayGroup"; Value = "Remote Service Management" },
    @{ Property = "DisplayGroup"; Value = "Remote Volume Management" },
    @{ Property = "DisplayGroup"; Value = "Remote Scheduled Tasks Management" },
    @{ Property = "DisplayGroup"; Value = "Windows Defender Firewall Remote Management" },
    @{ Property = "DisplayGroup"; Value = "Windows Remote Management" },
    @{ Property = "DisplayGroup"; Value = "Remote Desktop" }
)
Write-Information -MessageData "Configuring firewall for remote management."
foreach ($Rule in $Rules) {
    Write-Information -MessageData "`tChecking firewall rule '$($Rule.Value)'"

    $splat = @{
        $Rule.Property = $Rule.Value
        ErrorAction = 'SilentlyContinue'
    }
    $ruleObject = Get-NetFirewallRule @splat

    if ($null -eq $ruleObject) {
        Write-Information -MessageData "`tFirewall rule '$($Rule.Value)' not found."
        continue
    }

    if ($ruleObject.Enabled) {
        Write-Information -MessageData "`tFirewall rule '$($Rule.Value)' already enabled."
        continue
    } else {
        Write-Information -MessageData "`tEnabling firewall rule '$($Rule.Value)'."
        try {
            $enableSplatt = @{
                $Rule.Property = $Rule.Value
                ErrorAction = 'Stop'
            }
            $null = Enable-NetFireWallRule @enableSplatt
            Write-Information -MessageData "`tFirewall rule '$($Rule.Value)' enabled."
        } catch {
            Write-Information -MessageData "`tERROR: Failed to enable firewall rule '$($Rule.Value)'."
            continue;
        }
    }
    
}

if (-not $SkipHeader) {
    $end = Get-Date
    Write-Information -MessageData "Time taken: $((New-TimeSpan -Start $start -End $end).ToString('c'))"
    Write-Information -MessageData "Default firewall configuration completed."
}
exit 0