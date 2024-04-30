param(
    [string] $ServiceAccountUsername = "DEV\dev-irms-pshu",
    [string] $ServiceAccountPassword = "sockMonkey0!"
)

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
secedit.exe /configure /db secedit.sdb /cfg "C:\tmp\pshu.inf" /areas USER_RIGHTS
Add-LocalGroupMember -Group "Performance Monitor Users" -Member $ServiceAccountUsername
Add-LocalGroupMember -Group "Performance Log Users" -Member $ServiceAccountUsername


# Install the MSI file
$MsiFilePath = (Resolve-Path 'C:\vagrant\software\PowerShellUniversal*.msi').Path
Write-Host "MsiFilePath: $MsiFilePath"
$InstallLog = "{0}\logs\{1}-install.log" -f 'c:\tmp', $(($MsiFilePath -split '\\')[-1])
$RepoFolder = 'D:\UniversalAutomation\Repository'
$ConnectionString = "filename=$RepoFolder\database.db"

if (-not (Test-Path $RepoFolder)) {
    New-Item -Path $RepoFolder -ItemType Directory
}

if ($ServiceAccountUsername -and $ServiceAccountPassword) {
    $ServiceCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ServiceAccountUsername, (ConvertTo-SecureString -String $ServiceAccountPassword -AsPlainText -Force)
} 

if ($ServiceCred) {
    Write-Host "Executing msiexec with Service Account configuration..."
    Write-Host "Msi log: $InstallLog"

    $ArgList = ('/i "{0}" /q /norestart /l*v {1} STARTSERVICE=1 REPOFOLDER="{2}" CONNECTIONSTRING="{3}" SERVICEACCOUNT="{4}" SERVICEACCOUNTPASSWORD="{5}"' -f $MsiFilePath, $InstallLog, $RepoFolder, $ConnectionString, $ServiceAccountUsername, $ServiceAccountPassword)
    
}
else {
    $ArgList = ('/i "{0}" /q /norestart /l*v {1} STARTSERVICE=1 REPOFOLDER="{2}" CONNECTIONSTRING="{3}"' -f $MsiFilePath, $InstallLog, $RepoFolder, $ConnectionString)
    Write-Host "Executing msiexec command line:"
    Write-Host "`tmsiexec.exe $ArgList"
    Write-Host "Msi log: $InstallLog"
}

$result = Start-Process msiexec.exe -ArgumentList $ArgList -Wait -PassThru
Write-Host "Install exited with code: $($result.ExitCode)"