$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$themeVersionFile = Join-Path $scriptDir 'themes\hugo-theme-next\VERSION'

function Show-Banner {
    param(
        [string]$Version
    )

    @'
========================================
  _   _ _______  _______ _____
 | \ | | ____\ \/ /_   _|_   _|
 |  \| |  _|  \  /  | |   | |
 | |\  | |___ /  \  | |   | |
 |_| \_|_____/_/\_\ |_|   |_|
========================================
Hugo NexT version {0}
Documentation: https://hugo-next.eu.org
========================================
'@ -f $Version
}

$themeVersion = Get-Content -LiteralPath $themeVersionFile -Raw
Show-Banner $themeVersion.Trim()

& (Join-Path $scriptDir 'scripts\sync-content-assets.ps1')
hugo server --port 1414