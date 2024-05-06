param(
    [string] $Identity = "dev\svc-irms",
    [string] $IdPw = "vagrant",
    [string] $DomainAdmin = "dev\vagrant",
    [string] $DomainAdminPw = "vagrant"
)

$start = Get-Date ([datetime]::UtcNow)
$InformationPreference = "Continue"
. (Join-Path $env:SystemDrive 'vagrant\src\utils\deploy-utils.ps1')

Write-ProvisionScriptHeader -ScriptName 'install-powershelluniversal.ps1'

$Credential = New-Object System.Management.Automation.PSCredential -ArgumentList ($DomainAdmin, (ConvertTo-SecureString $DomainAdminPw -AsPlainText -Force))
$Credential

if (Get-Module -ListAvailable -Name 'ActiveDirectory') {
    Write-Information -MessageData "Checking Active Directory for service account '$Identity'..."
    $ntbname,$uname = $Identity -split '\\'
    $domName        = ([System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain()).Name

    try {
        $adUser = Get-AdUser -Filter { SamAccountName -eq $uname } -Credential $Credential -ErrorAction Stop
    }
    catch {
        $adUser = $null
    }

    if ($adUser) {
        Write-Information -MessageData "Service account '$Identity' found in Active Directory. Nothing to do."
    }
    else {
        Write-Information -MessageData "Service account '$Identity' not found in Active Directory. Creating..."
        try {
            $newUser = New-AdUser `
            -SamAccountName $uname `
            -UserPrincipalName "$uname@$domName" `
            -Name $uname `
            -GivenName $uname `
            -Surname "Ironman" `
            -Enabled $True `
            -DisplayName $uname `
            -AccountPassword (convertto-securestring $IdPw -AsPlainText -Force) `
            -PasswordNeverExpires $True `
            -Credential $Credential `
        
            Write-Information -MessageData "`tService account '$Identity' created successfully."
            Write-Information -MessageData "`tPassword: $IdPw"
            Write-Information -MessageData "`tSamAccountName: $uname"
            
        } catch {
            Write-Information -MessageData "`tERROR: Failed to create service account '$Identity'."
            $LASTEXITCODE = 1
        }
    }
}

$end = Get-Date ([datetime]::UtcNow)
Write-Information -MessageData "Time taken: $((New-TimeSpan -Start $start -End $end).ToString('c'))"
Write-Information -MessageData "Service Account creation completed."
exit $LASTEXITCODE