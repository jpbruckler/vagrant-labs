<#
    .SYNOPSIS
        Downloads, installs, and configures PowerShell Universal, sets service
        account permissions, and creates a local firewall rule.

    .DESCRIPTION
        This script is intended for deployment environments, automating the
        setup of PowerShell Universal. It handles the installation of the latest
        version of PowerShell Universal, configures service account permissions
        if provided, and establishes firewall rules to allow incoming traffic.
        It is part of a suite of scripts used during the deployment of virtual
        machines with Vagrant.

        When deploying with the Vagrantfile in this repository, a service account
        can be specified to run the PowerShell Universal service in the
        provision.yaml file using the irms directive.

        Example:

        - name: dev-irms01
          box: gusztavvargadr/windows-server-2022-standard-core
          memory: 4096
          cpus: 4
          roles:
            - member-server
            - powershelluniversal
          disks:
            - name: universal
              size: 120
              driveletter: D
          packages:
            - git
            - helix
          irms:
            service_account: "DTM\\svc-powershelluniversal"
            account_pw: "supersecretp@ssw0rd"

    .PARAMETER ServiceAccountUsername
        Specifies the username of the service account to be configured for
        running the PowerShell Universal service. It supports domain accounts.

    .PARAMETER ServiceAccountPW
        Specifies the password for the service account. This parameter is
        mandatory if a ServiceAccountUsername is provided. The script uses this
        password to create or update the account in Active Directory.

    .EXAMPLE
        PS> .\install-pwshuniversal.ps1 -ServiceAccountUsername "DOMAIN\User" -ServiceAccountPassword "Password"
        Installs PowerShell Universal using "DOMAIN\User" as the service account with the specified password.

    .EXAMPLE
        PS> .\install-pwshuniversal.ps1
        Installs PowerShell Universal without configuring a service account.

    .NOTES
        This script requires administrative privileges.
        It is recommended to verify the availability of network resources and
        permissions before execution.
        
        Ensure PowerShell Execution Policy allows script execution.
#>

param(
    [string] $ServiceAccountUsername,
    [string] $ServiceAccountPW,
    [string] $UniversalRepoPath
)

$start = Get-Date ([datetime]::UtcNow)
$InformationPreference = "Continue"
. (Join-Path $env:SystemDrive 'vagrant\src\utils\deploy-utils.ps1')

Write-ProvisionScriptHeader -ScriptName 'install-powershelluniversal.ps1'

$LASTEXITCODE = 0
$tmpDir = Join-Path $env:SystemDrive 'tmp'
Write-Information -MessageData "Checking for existing installer in $tmpDir..."
$installer = Get-ChildItem -Path $tmpDir -Filter 'PowerShellUniversal*.msi' -ErrorAction SilentlyContinue | Select-Object -First 1
if ($installer) {
    Write-Information -MessageData "`tFound existing installer in path: $($installer.FullName)"
    $InstallLog = "{0}\{1}-install.log" -f (Join-Path $env:SystemDrive 'tmp\logs'), $($installer.BaseName)

    $SB = [System.Text.StringBuilder]::new()
    $null = $SB.Append(('/i "{0}" /q /norestart /l*v {1} ' -f $($installer.FullName), $InstallLog))

    if ($UniversalRepoPath) {
        if (-not (Test-Path $UniversalRepoPath)) {
            Write-Information -MessageData "`tCreating Universal Repository folder at: $UniversalRepoPath"
            New-Item -Path $UniversalRepoPath -ItemType Directory
        }
        $ConnectionString = "filename={0}\database.db" -f $UniversalRepoPath
        $null = $SB.Append(('REPOFOLDER="{0}" CONNECTIONSTRING={1} ' -f $UniversalRepoPath, $ConnectionString))
    }

    if ($ServiceAccountUsername) {
        Write-Information -MessageData "`tAdding service account to msiexec command line..."
        $null = $SB.Append(('SERVICEACCOUNT="{0}" SERVICEACCOUNTPASSWORD="{1}" ' -f $ServiceAccountUsername, $ServiceAccountPW))

        try {
            $adUser = Get-AdUser (($ServiceAccountUsername -split '\\')[1]) -ErrorAction Stop
        }
        catch {
            $adUser = $null
        }

        if ($adUser) {
            Write-Information -MessageData "`tService account '$ServiceAccountUsername' found in Active Directory. Setting SERVICE_START to 1."
            $SERVICE_START = 1
        }
        else {
            Write-Information -MessageData "`tService account '$ServiceAccountUsername' not found in Active Directory. Setting SERVICE_START to 0."
            $SERVICE_START = 0
        }
    }

    $null = $SB.Append(('STARTSERVICE={0}' -f $SERVICE_START))

    $ArgList = $SB.ToString()

    Write-Information -MessageData "Executing msiexec with command line: $ArgList"
    Write-Information -MessageData "`tInstallation log can be found at: $InstallLog"

    $result = Start-Process msiexec.exe -ArgumentList $ArgList -Wait -PassThru
    Write-Information -MessageData "`tInstall exited with code: $($result.ExitCode)"
    if ($result.ExitCode -ne 0) {
        Write-Information -MessageData "`tERROR: PowerShell Universal installation failed. Check the log file for details: $InstallLog"
        $LASTEXITCODE = $result.ExitCode
    }
} else {
    Write-Information -MessageData "`tNo existing installer found."
    Write-Information -MessageData "`tPlease run the download-powershelluniversal.ps1 script to download the installer."
    $LASTEXITCODE = 1
}

$end = Get-Date ([datetime]::UtcNow)
Write-Information -MessageData "Time taken: $((New-TimeSpan -Start $start -End $end).ToString('c'))"
Write-Information -MessageData "PowershellUniversal Install completed."
exit $LASTEXITCODE