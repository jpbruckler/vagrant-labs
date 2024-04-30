param(
    [Parameter(Mandatory = $false, Position = 0)]
    [ValidateSet('Production', 'Nightly')]
    [string] $BuildType = 'Production',

    [Parameter(Mandatory = $false, Position = 1)]
    [ValidateSet('4', '5')]
    [string] $MajorVersion = '4',

    [Parameter(Mandatory = $false, Position = 2)]
    [string] $DownloadDir = 'C:\vagrant\software'
)

# Don't change anything below this line
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
$pattern    = '^production\/[\d\.]+\/PowerShellUniversal[\d\.]+msi'
$baseUri    = 'https://imsreleases.blob.core.windows.net/{0}' -f $(if ($BuildType -eq 'Nightly') { 'universal-nightly' } else { 'universal' })
$versUri    = '{0}/production/v{1}-version.txt' -f $baseUri, $MajorVersion
$xmlUri     = '{0}?restype=container&comp=list' -f $baseUri
$downloads  = @{ Name = ''; Msi = ''; Hash = ''}

# The XML response from the blob storage API is not well-formed, so we need to
# clean it up by removing non-word characters from the beginning of the response
$response   = [regex]::replace((Invoke-WebRequest -Uri $xmlUri -UseBasicParsing).Content, "^[\W]+<", "<")

# Get the latest version from the version file if it's not known. This saves
# us from having to do date math to determine the latest version
$latestVer  = Invoke-RestMethod -Uri $versUri -UseBasicParsing

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
    $downloads.Hash = (Invoke-WebRequest -Uri $HashUrl -UseBasicParsing).Content -replace '\s', ''
    $downloads.Name = ($Msi.Name -split '/')[-1]
    $downloads.Msi  = $Msi.Url
    $downloads.Hash = (Invoke-RestMethod -Uri $HashUrl -UseBasicParsing) -replace '\s', ''
} else {
    Write-Error "No files found matching the pattern: $pattern"
    exit 1
}

# Download the MSI file and the SHA256 hash file
try {
    $MsiFilePath = Join-Path $DownloadDir "$(($downloads.Name -split '/')[-1])"
    Write-Information "Downloading $($downloads.Name) to $MsiFilePath"
    if (Test-Path $MsiFilePath) {
        Remove-Item $MsiFilePath -Force
    }

    Invoke-WebRequest -Uri $downloads.Msi -OutFile $MsiFilePath -UseBasicParsing

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