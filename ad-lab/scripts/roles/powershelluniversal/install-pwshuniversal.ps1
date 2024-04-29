param(
    [string] $ServiceAccountUsername,
    [string] $ServiceAccountPassword
)

$MAJOR_VERSION  = 4  # 4 or 5
$BUILD_TYPE     = 'Production' # 'Production' or 'Nightly'
$TEMP_DIR       = 'C:\Temp' # Directory to download files to


# Don't change anything below this line
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
$pattern    = '^production\/[\d\.]+\/PowerShellUniversal[\d\.]+msi'
$baseUri    = 'https://imsreleases.blob.core.windows.net/{0}' -f $(if ($BUILD_TYPE -eq 'Nightly') { 'universal-nightly' } else { 'universal' })
$versUri    = '{0}/production/v{1}-version.txt' -f $baseUri, $MAJOR_VERSION
$xmlUri     = '{0}?restype=container&comp=list' -f $baseUri
$downloads  = @{ Name = ''; Msi = ''; Hash = ''}

# The XML response from the blob storage API is not well-formed, so we need to
# clean it up by removing non-word characters from the beginning of the response
$response   = [regex]::replace((Invoke-WebRequest -Uri $xmlUri).Content, "^[\W]+<", "<")

# Get the latest version from the version file if it's not known. This saves
# us from having to do date math to determine the latest version
$latestVer  = Invoke-RestMethod -Uri $versUri

# Parse the XML response. Try/Catch here to handle any parsing errors. If XML
# parsing fails, the script will exit with an error.
try {
    $releases = [xml]$response
} catch {
    Write-Error "Failed to parse XML response: $response"
    exit 1
}


# Determine the target files based on the latest version or the latest date
if ($latestVer) {
    # No need to do any date math if the latest version is known
    $files = $releases.EnumerationResults.Blobs.Blob | 
                Where-Object { $_.Name -match $latestVer -and $_.Name -match $pattern }
} else {
    # If the latest version is known, determine target files by date
    $files = $releases.EnumerationResults.Blobs.Blob | 
                Where-Object Name -match $pattern | 
                Select-Object -Property Name, Url, @{n="LastModified";e={(Get-Date $_.Properties.'Last-Modified')}} | 
                Sort-Object -Property LastModified -Descending | 
                Select-Object -First 2
    $latestVer = $files[0].Name.split('/')[1]
    
}

if ($files) {
    $Msi = $files | Where-Object Name -notmatch 'sha256'
    $HashUrl = $files | Where-Object Name -match 'sha256' | Select-Object -ExpandProperty Url
    $downloads.Hash = (Invoke-WebRequest -Uri $HashUrl).Content -replace '\s', ''
    $downloads.Name = $Msi.Name
    $downloads.Msi  = $Msi.Url
    $downloads.Hash = (Invoke-RestMethod -Uri $HashUrl) -replace '\s', ''
} else {
    Write-Error "No files found matching the pattern: $pattern"
    exit 1
}

# Download the MSI file and the SHA256 hash file
try {
    $MsiFilePath = Join-Path $TEMP_DIR "$(($downloads.Name -split '/')[-1])"
    Write-Information "Downloading $($downloads.Name) to $MsiFilePath"
    if (Test-Path $MsiFilePath) {
        Remove-Item $MsiFilePath -Force
    }

    Invoke-WebRequest -Uri $downloads.Msi -OutFile $MsiFilePath

    $DlHash = Get-FileHash -Path $MsiFilePath -Algorithm SHA256 | Select-Object -ExpandProperty Hash
    if ($DlHash -eq $downloads.Hash) {
        Write-Output "Downloaded $($downloads.Name) successfully"
    } else {
        Write-Error "Failed to download $($downloads.Name): SHA256 hash mismatch"
        exit 1
    }
} catch {
    Write-Error "Failed to download $($downloads.Name): $_"
    exit 1
}

# Install the MSI file
$InstallLog = "{0}\logs\{1}-install.log" -f 'c:\tmp\logs', $downloads.Name
$RepoFolder = 'D:\UniversalAutomation'
$ConnectionString = "Source=$RepoFolder\database.db"
if ($ServiceAccountUsername -and $ServiceAccountPassword) {
    $ServiceCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ServiceAccountUsername, (ConvertTo-SecureString -String $ServiceAccountPassword -AsPlainText -Force)
} 

if ($ServiceCred) {
    $ServiceAccount = $($ServiceCred.username)
    $ServiceAccountPW = $($ServiceCred.getnetworkcredential().password)
    Write-Host "Executing msiexec with Service Account configuration..."
    Write-Host "Msi log: $InstallLog"
    msiexec /i ("{0}" -f $msi.FullName) /q /norestart /l*v $InstallLog REPOFOLDER="$RepoFolder" CONNECTIONSTRING="$ConnectionString" SERVICEACCOUNT="$ServiceAccount" SERVICEACCOUNTPASSWORD="$ServiceAccountPW"
}
else {
    Write-Host "Executing msiexec..."
    msiexec /i ("{0}" -f $msi.FullName) /q /norestart /l*v $InstallLog REPOFOLDER="RepoFolder" CONNECTIONSTRING="$ConnectionString"
}