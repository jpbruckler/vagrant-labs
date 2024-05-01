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

    .PARAMETER ServiceAccountPassword
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
    [string] $ServiceAccountPassword
)

. (Join-Path $env:SystemDrive 'vagrant\scripts\utils\psutils.ps1')

$SERVICE_START = 1

#region Service account configuration
if ($ServiceAccountUsername) {
    Write-Host "Service Account Username: $ServiceAccountUsername"

    $isDomJoined = (Get-CimInstance -Class Win32_ComputerSystem).PartOfDomain
    $isDomSvcAct = $ServiceAccountUsername -match '\\'

    if ($isDomJoined -and $isDomSvcAct) {
        Write-Host "Domain joined machine detected. Checking for Active Directory module..."
    
        if (Get-Module -ListAvailable -Name 'ActiveDirectory') {
            Write-Host "Checking Active Directory for service account '$ServiceAccountUsername'..."
            $ntbname,$uname = $ServiceAccountUsername -split '\\'
            $adUser         = Get-ADUser -Identity $uname -ErrorAction SilentlyContinue
            $domName        = ([System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain()).Name

            if ($adUser) {
                Write-Host "Service account '$ServiceAccountUsername' found in Active Directory."
            }
            else {
                Write-Host "Service account '$ServiceAccountUsername' not found in Active Directory. Creating..."
                New-AdUser `
                    -SamAccountName $uname `
                    -UserPrincipalName "$uname@$domName" `
                    -Name $uname `
                    -GivenName $uname `
                    -Surname "Ironman" `
                    -Enabled $True `
                    -DisplayName $uname `
                    -AccountPassword (convertto-securestring $ServiceAccountPassword -AsPlainText -Force) `
                    -PasswordNeverExpires $True
            }
        }
        else {
            Write-Host "Active Directory module not found. Skipping service account check."
            Write-Host "PowerShell Universal Service will be installed but not started."
            $SERVICE_START = 0
        }
    }
    else {
        Write-Host "Non-domain joined machine detected. Skipping Active Directory module check."
    }

    Write-Host "Setting local user rights for service account..."
    $inf = @"
[Unicode]
Unicode=yes
[Version]
signature="`$CHICAGO$"
Revision=1
[Privilege Rights]
SeServiceLogonRight = "{{USERNAME}}"
SeIncreaseQuotaPrivilege = "{{USERNAME}}"
SeAssignPrimaryTokenPrivilege = "{{USERNAME}}"
"@

    ($inf -replace '{{USERNAME}}', $ServiceAccountUsername) | Set-Content c:\tmp\pshu.inf -Force
    
    try {
        secedit.exe /configure /db secedit.sdb /cfg "C:\tmp\pshu.inf" /areas USER_RIGHTS

        Write-Host "Service account rights set."

        Write-Host "Adding $ServiceAccountUsername to Performance Monitor Users and Performance Log Users groups..."

        Add-LocalGroupMember -Group "Performance Monitor Users" -Member $ServiceAccountUsername -ErrorAction Stop
        Add-LocalGroupMember -Group "Performance Log Users" -Member $ServiceAccountUsername -ErrorAction Stop
    } catch {
        Write-Host "Failed to set service account rights."
        Write-Host "PowerShell Universal Service will be installed but not started."
        Write-Host "Consult PowerShell Universal documentation for setting service account rights manually."
        $SERVICE_START = 0
    }
}
else {
    Write-Host "Service Account Username not provided. Skipping service account configuration."
}
#endregion

Write-Host "Checking for existing installer in C:\vagrant\software..."
if (-not (Test-Path 'C:\vagrant\software\PowerShellUniversal*.msi')) {
    Write-Host "Installer not found. Downloading PowerShell Universal..."
    try {
        . C:\vagrant\scripts\roles\powershelluniversal\get-latestpwshuniversal.ps1
    } catch {
        Write-Host "Failed to download PowerShell Universal, unable to continue."
        exit 1
    }
}

# Determine Repository path. Default is D:\UniversalAutomation\Repository
$disks = Get-Disk | Where-Object { $_.PartitionStyle -eq 'GPT' -and $_.OperationalStatus -eq 'Online' }
if ($disks.Count -eq 1) {
    $driveLetter = $env:SystemDrive
}
else {
    $driveLetter = $disks[1] | Get-Partition | Where-Object Type -eq 'Basic' | Select-Object -ExpandProperty DriveLetter
}
$RepoFolder = '{0}:\UniversalAutomation\Repository' -f $driveLetter

# Install the MSI file
$MsiFilePath = (Resolve-Path 'C:\vagrant\software\PowerShellUniversal*.msi').Path
Write-Host "MsiFilePath: $MsiFilePath"
$InstallLog = "{0}\logs\{1}-install.log" -f 'c:\tmp', $(($MsiFilePath -split '\\')[-1])
$ConnectionString = "filename=$RepoFolder\database.db"

$ArgList = ('/i "{0}" /q /norestart /l*v {1} STARTSERVICE={2} REPOFOLDER="{3}" CONNECTIONSTRING="{4}"' -f $MsiFilePath, $InstallLog, $SERVICE_START, $RepoFolder, $ConnectionString)

if (-not (Test-Path $RepoFolder)) {
    New-Item -Path $RepoFolder -ItemType Directory
}

if ($ServiceAccountUsername) {
    Write-Host "Adding service account to msiexec command line..."
    $ArgList = '{0} SERVICEACCOUNT="{1}" SERVICEACCOUNTPASSWORD="{2}"' -f $ArgList, $ServiceAccountUsername, $ServiceAccountPassword 
    
}

Write-Host "Executing msiexec command line:"
Write-Host "`tmsiexec.exe $ArgList"
Write-Host "Msi log: $InstallLog"

$result = Start-Process msiexec.exe -ArgumentList $ArgList -Wait -PassThru
Write-Host "Install exited with code: $($result.ExitCode)"

if ($result.ExitCode -ne 0) {
    Write-Host "ERROR: PowerShell Universal installation failed. Check the log file for details: $InstallLog"
}

$fwRule = Get-NetFirewallRule | Where-Object { $_.DisplayName -match 'PowerShell Universal' }

if ($null -eq $fwRule) {
    Write-Host "Creating firewall rule for PowerShell Universal..."
    New-NetFirewallRule -DisplayName "PowerShell Universal" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 5000, 80, 443
    Write-Host "Firewall rule created."
}
else {
    Write-Host "Firewall rule for PowerShell Universal already exists."
}

exit 0