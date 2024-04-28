$ErrorActionPreference = 'Stop'
$pattern = 'PowerShell\-([\d\.]+)-win-x64.msi'
$dldir = 'C:\vagrant\software'
$msiArgs = '/quiet ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1 ADD_FILE_CONTEXT_MENU_RUNPOWERSHELL=1 REGISTER_MANIFEST=1 USE_MU=1 ENABLE_MU=1 ADD_PATH=1'

Write-Host 'Checking for the latest stable version of PowerShell...'

if ((Invoke-RestMethod https://aka.ms/powershell-release?tag=stable) -match $pattern) {
    $version    = $matches[1]
    $filename   = $matches[0]
    $hashUrl    = 'https://github.com/PowerShell/PowerShell/releases/download/v{0}/hashes.sha256' -f $version
    $msiUrl     = 'https://github.com/PowerShell/PowerShell/releases/download/v{0}/{1}' -f $version, $filename
    
    Write-Host "Latest stable version is............... $version"
    Write-Host "Filename is............................ $filename"

    if (Test-Path "$dldir\$filename") {
        Write-Host "PowerShell $version is already downloaded. Starting installation."
        
    } else {
        Write-Host "PowerShell $version is not downloaded yet. Starting download."
        Write-Host "Hash URL is............................ $hashUrl"
        Write-Host "MSI URL is............................. $msiUrl"

        Write-Host "Downloading PowerShell $filename..."
        
        
        try {
            Invoke-WebRequest -Uri $hashUrl -OutFile "$dldir\hashes.sha256"
            Invoke-WebRequest -Uri $msiUrl -OutFile "$dldir\$filename"

            $checksum = (Get-Content -Path "$dldir\hashes.sha256" | Where-Object { $_ -match $filename }).Split(' ')[0]
            $hash = Get-FileHash -Path "$dldir\$filename" -Algorithm SHA256 | Select-Object -ExpandProperty Hash

            Write-Host "Checksum is............................ $checksum"
            Write-Host "Download hash is....................... $hash"

            if ($checksum -ne $hash) {
                Write-Error "Checksum mismatch for PowerShell MSI."
                exit 1
            } else {
                Write-Host "Checksum verified for PowerShell MSI."
            }

        } catch {
            Write-Error "Failed to download PowerShell MSI: $_"
            exit 1
        }
    }

    Write-Host "Installing PowerShell $version..."
    $msiArgs = '/i {0} {1}' -f "$dldir\$filename", $msiArgs
    Write-Host "Calling msiexec with args:`n$msiArgs"
    $msip = Start-Process -FilePath msiexec.exe -ArgumentList $msiArgs -Wait -WorkingDirectory $dldir -PassThru

    if ($msip.ExitCode -ne 0) { 
        throw "MSI Installation failed with error code: $($msip.ExitCode)" 
    } else {
        Write-Host "PowerShell $version installed successfully."
    }
    
}