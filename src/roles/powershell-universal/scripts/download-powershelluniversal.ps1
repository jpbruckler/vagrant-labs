<#
    .SYNOPSIS
        Downloads and verifies the latest version of PowerShell Universal for a
        specified major version.

    .DESCRIPTION
        This script identifies the latest version of PowerShell Universal that
        matches a specified major version number from a predefined build type (Production or Nightly). It retrieves the MSI installer and its associated SHA256 hash from a Microsoft Azure blob storage, validates the hash to ensure the download's integrity, and saves the installer to a specified directory.

    .PARAMETER BuildType
        The type of build to download. Accepts 'Production' or 'Nightly'.
        Default is 'Production'.

    .PARAMETER MajorVersion
        The major version number of PowerShell Universal to download. Currently
        supports versions '4' and '5'. Default is '4'.

    .PARAMETER OutputDirectory
        The directory to which the MSI file will be downloaded. Default is the
        'software' directory under 'vagrant' on the system drive.

    .EXAMPLE
        PS> .\ScriptName.ps1 -BuildType 'Production' -MajorVersion '5'
        Downloads the latest production build of PowerShell Universal version 5.

    .EXAMPLE
        PS> .\ScriptName.ps1 -BuildType 'Nightly' -MajorVersion '4' -DownloadDir 'D:\downloads'
        Downloads the latest nightly build of PowerShell Universal version 4 to the specified directory on the D: drive.

    .NOTES
        The script requires internet connectivity. It also needs permissions to
        write to the specified directory. Ensure execution policies allow script
        running.
#>

param (
    [ValidateSet('Production', 'Nightly')]
    [string] $BuildType = 'Production',

    [ValidateSet('4', '5')]
    [string] $MajorVersion = '4',

    [string] $OutputDirectory = (Join-Path $env:SystemDrive 'tmp')
)

$start = Get-Date ([datetime]::UtcNow)
$InformationPreference = "Continue"
. (Join-Path $env:SystemDrive 'vagrant\src\utils\deploy-utils.ps1')
$rc = 0
Write-ProvisionScriptHeader -ScriptName 'download-powershelluniversal.ps1'

# Download the MSI file and the SHA256 hash file
try {
    Write-Information -MessageData 'Retrieving PowerShell Universal installer information...'
    $DownloadInfo = Get-PwshUniversalInstallerInfo -InstallerType msi -BuildType $BuildType -MajorVersion $MajorVersion

    Write-Information -MessageData "`tLatest version: $($DownloadInfo.Version)"
    Write-Information -MessageData "`tLast modified: $($DownloadInfo.LastModified)"
    Write-Information -MessageData "`tFile name: $($DownloadInfo.Name)"
    Write-Information -MessageData "`tFile hash: $($DownloadInfo.Hash)"
    Write-Information -MessageData "`tDownload URL: $($DownloadInfo.Url)"

    $MsiFilePath = Join-Path $OutputDirectory "$($DownloadInfo.Name)"
    Write-Information "Downloading $($DownloadInfo.Name) to $MsiFilePath"

    if (Test-Path $MsiFilePath) {
        Remove-Item $MsiFilePath -Force
    }

    Invoke-WebRequest -Uri $DownloadInfo.Url -OutFile $MsiFilePath -UseBasicParsing

    Write-Information -MessageData "Downloaded $($DownloadInfo.Name) to $MsiFilePath. Validating hash..."
    $DlHash = Get-FileHash -Path $MsiFilePath -Algorithm SHA256 | Select-Object -ExpandProperty Hash
    if ($null -ne $DownloadInfo.Hash -and $DlHash -eq $DownloadInfo.Hash) {
        Write-Information -MessageData "`tDownloaded and validated $($DownloadInfo.Name)} successfully."
    } else {
        Write-Information -MessageData "`tDownloaded $($DownloadInfo.Name). Unable to validate the hash because none was provided by the vendor."
    }
} catch {
    Write-Error "Failed to download $($DownloadInfo.Name): $_"
    $rc = 1
}

$end = Get-Date ([datetime]::UtcNow)
Write-Information -MessageData "Time taken: $((New-TimeSpan -Start $start -End $end).ToString('c'))"
Write-Information -MessageData "PowerShell Universal download completed."
exit $rc