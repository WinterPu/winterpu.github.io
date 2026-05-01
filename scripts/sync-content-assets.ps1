$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $scriptDir
$contentDir = Join-Path $rootDir 'content'
$staticDir = Join-Path $rootDir 'static'
$stateDir = Join-Path $rootDir '.content-assets-sync'
$manifestFile = Join-Path $stateDir 'targets.txt'

function Get-PublishRelativeDir {
    param(
        [string]$markdownFile,
        [string]$fallbackRelativeDir
    )

    if (-not (Test-Path -LiteralPath $markdownFile -PathType Leaf)) {
        return $fallbackRelativeDir
    }

    $lines = Get-Content -LiteralPath $markdownFile
    $frontMatterOpened = $false
    $frontMatterClosed = $false

    foreach ($line in $lines) {
        if (-not $frontMatterOpened) {
            if ($line -eq '---') {
                $frontMatterOpened = $true
            }
            continue
        }

        if ($line -eq '---') {
            $frontMatterClosed = $true
            break
        }

        if ($line -match '^url:\s*(.+?)\s*$') {
            $urlPath = $matches[1].Trim()
            if ($urlPath) {
                return $urlPath.Trim('/').Replace('/', [IO.Path]::DirectorySeparatorChar)
            }
        }
    }

    if (-not $frontMatterClosed) {
        return $fallbackRelativeDir
    }

    return $fallbackRelativeDir
}

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

$sourceDirs = Get-ChildItem -Path $contentDir -Directory -Recurse | Where-Object { $_.Name -eq '.assets' } | Sort-Object FullName
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
                $pageRelativeDir = Get-PublishRelativeDir -markdownFile $matchingMarkdown -fallbackRelativeDir (Join-Path $relativeParent $child.Name)
                $pageAssetsDir = Join-Path (Join-Path $staticDir $pageRelativeDir) 'assets'
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
