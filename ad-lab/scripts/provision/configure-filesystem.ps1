if (-not (Test-Path -Path "C:\tools" -PathType Container)) {
    New-Item -Path "C:\" -Name "tools" -ItemType "Directory"
}

if (-not (Test-Path -Path "C:\tmp" -PathType Container)) {
    New-Item -Path "C:\" -Name "tmp" -ItemType "Directory"
}

if (-not (Test-Path -Path "C:\tmp\logs" -PathType Container)) {
    New-Item -Path "C:\tmp" -Name "logs" -ItemType "Directory"
}