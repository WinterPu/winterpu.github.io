$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $scriptDir
$contentDir = Join-Path $rootDir 'content'
$staticDir = Join-Path $rootDir 'static'
$stateDir = Join-Path $rootDir '.content-assets-sync'
$manifestFile = Join-Path $stateDir 'targets.txt'

New-Item -ItemType Directory -Path $staticDir -Force | Out-Null
New-Item -ItemType Directory -Path $stateDir -Force | Out-Null

$managedTargets = @()

if (Test-Path -LiteralPath $manifestFile) {
    Get-Content -LiteralPath $manifestFile | ForEach-Object {
        if ($_ -and (Test-Path -LiteralPath $_)) {
            Remove-Item -LiteralPath $_ -Recurse -Force
        }
    }
}

Get-ChildItem -Path $staticDir -Filter '.content-assets-sync' -Recurse -File -ErrorAction SilentlyContinue | Remove-Item -Force

$sourceDirs = Get-ChildItem -Path $contentDir -Directory -Recurse | Where-Object { $_.Name -eq 'assets' } | Sort-Object FullName
foreach ($sourceDir in $sourceDirs) {
    $relativePath = $sourceDir.FullName.Substring($contentDir.Length).TrimStart([char[]]@('\', '/'))
    $targetDir = Join-Path $staticDir $relativePath
    $parentDir = Split-Path -Parent $sourceDir.FullName
    $relativeParent = $parentDir.Substring($contentDir.Length).TrimStart([char[]]@('\', '/'))
    $hasBaseAssets = $false

    $children = Get-ChildItem -LiteralPath $sourceDir.FullName -Force | Sort-Object FullName
    foreach ($child in $children) {
        if ($child.PSIsContainer) {
            $matchingMarkdown = Join-Path $parentDir ($child.Name + '.md')
            if (Test-Path -LiteralPath $matchingMarkdown -PathType Leaf) {
                $pageAssetsDir = Join-Path (Join-Path (Join-Path $staticDir $relativeParent) $child.Name) 'assets'
                New-Item -ItemType Directory -Path $pageAssetsDir -Force | Out-Null
                Copy-Item -LiteralPath $child.FullName -Destination (Join-Path $pageAssetsDir $child.Name) -Recurse -Force
                $managedTargets += $pageAssetsDir
                continue
            }

            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
            Copy-Item -LiteralPath $child.FullName -Destination (Join-Path $targetDir $child.Name) -Recurse -Force
            $hasBaseAssets = $true
            continue
        }

        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        Copy-Item -LiteralPath $child.FullName -Destination $targetDir -Force
        $hasBaseAssets = $true
    }

    if ($hasBaseAssets) {
        $managedTargets += $targetDir
    }
}

$managedTargets | Sort-Object -Unique | Set-Content -LiteralPath $manifestFile
