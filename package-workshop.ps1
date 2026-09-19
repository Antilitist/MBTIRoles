# Package MBTIRoles for local play + Steam Workshop (B42 multi-folder)
# Source of truth: this repo. Does NOT upload to Steam (use in-game Workshop UI).

$ErrorActionPreference = "Stop"
$Src = $PSScriptRoot
# Zomboid cache on F: (-cachedir=X:\Users\USER\Zomboid)
$Zomboid = "X:\Users\USER\Zomboid"
$Live = Join-Path $Zomboid "mods\MBTIRoles"
$WorkshopRoot = Join-Path $Zomboid "Workshop\MBTIRoles"
$WorkshopMod = Join-Path $WorkshopRoot "Contents\mods\MBTIRoles"

function Sync-Tree($from, $to) {
    if (-not (Test-Path $from)) { throw "Missing source: $from" }
    New-Item -ItemType Directory -Path $to -Force | Out-Null
    # Mirror media + mod assets; keep destination clean of stale files
    robocopy $from $to /MIR /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
    $code = $LASTEXITCODE
    if ($code -ge 8) { throw "robocopy failed ($code): $from -> $to" }
}

Write-Host "Syncing common -> 42 (source mirror)..."
Sync-Tree (Join-Path $Src "common") (Join-Path $Src "42")

Write-Host "Syncing to local play: $Live"
New-Item -ItemType Directory -Path $Live -Force | Out-Null
Sync-Tree (Join-Path $Src "common") (Join-Path $Live "common")
Sync-Tree (Join-Path $Src "42") (Join-Path $Live "42")
Copy-Item (Join-Path $Src "common\mod.info") (Join-Path $Live "mod.info") -Force
Copy-Item (Join-Path $Src "common\icon.png") (Join-Path $Live "icon.png") -Force -ErrorAction SilentlyContinue
Copy-Item (Join-Path $Src "common\poster.png") (Join-Path $Live "poster.png") -Force -ErrorAction SilentlyContinue

Write-Host "Syncing to Workshop package: $WorkshopMod"
New-Item -ItemType Directory -Path $WorkshopMod -Force | Out-Null
Sync-Tree (Join-Path $Src "common") (Join-Path $WorkshopMod "common")
Sync-Tree (Join-Path $Src "42") (Join-Path $WorkshopMod "42")
Copy-Item (Join-Path $Src "common\mod.info") (Join-Path $WorkshopMod "mod.info") -Force
Copy-Item (Join-Path $Src "common\icon.png") (Join-Path $WorkshopMod "icon.png") -Force -ErrorAction SilentlyContinue
Copy-Item (Join-Path $Src "common\poster.png") (Join-Path $WorkshopMod "poster.png") -Force -ErrorAction SilentlyContinue

# Workshop root assets
Copy-Item (Join-Path $Src "preview.png") (Join-Path $WorkshopRoot "preview.png") -Force -ErrorAction SilentlyContinue
# workshop.txt lives only under Workshop root (keep id=); do not overwrite from git unless present
$wsTxtSrc = Join-Path $Src "workshop.txt"
if (Test-Path $wsTxtSrc) {
    Copy-Item $wsTxtSrc (Join-Path $WorkshopRoot "workshop.txt") -Force
}

$ver = (Select-String -Path (Join-Path $Src "common\mod.info") -Pattern "modversion=").Line
Write-Host "Done. $ver"
Write-Host "Upload via: PZ Main Menu -> Workshop -> Create and update items -> MBTIRoles"
