# Set pwsh as the default shell
Write-Host "Setting PowerShell 7 as the default shell..."
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name Shell -Value 'pwsh.exe -NoExit'

# Enable Remote Desktop
Write-Host "Enabling Remote Desktop..."
$result = Start-Process cscript.exe -ArgumentList 'C:\Windows\System32\Scregedit.wsf /ar 0' -NoNewWindow -Wait -PassThru

if ($result.ExitCode -ne 0) {
    Write-Error "Failed to enable Remote Desktop. Exit code: $($result.ExitCode)"
}

exit 0