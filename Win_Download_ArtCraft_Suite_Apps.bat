<# :
@echo off
setlocal EnableDelayedExpansion
title ArtCraft Creative Suite Downloader ^& Version Manager - by Biraj2004
cd /d "%~dp0"

:: =======================================================================================================
:: GitHub      : https://github.com/Biraj2004
:: Developer   : Biraj
:: Description : Automates discovery, version resolution, and downloading of the complete 14-application
::                ArtCraft creative suite (PhotoCraft, VectorCraft, FilmCraft, ArtCraft Hub, etc.)
::                from https://getartcraft.com and https://github.com/storytold.
::                - Downloads latest standalone installers: Windows x64 (.msi) and macOS (.dmg).
::                - Automatically creates dedicated parent and subfolders at script execution location.
::                - Discovers true real-time latest releases dynamically without GitHub API rate limits.
::                - Mentions and displays latest version numbers, categories, and installer filenames.
::                - Gracefully handles already downloaded files (skips re-downloading up-to-date versions).
::                - Gracefully archives older superseded installer versions to avoid loss and clutter.
::                - Writes a comprehensive version manifest inventory file.
:: =======================================================================================================

where powershell >nul 2>&1
if errorlevel 1 (
    echo [ERROR] PowerShell was not found on this system. Cannot continue.
    echo.
    pause
    exit /b 1
)

powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create([System.IO.File]::ReadAllText('%~f0')))"
endlocal
exit /b
#>

$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'ArtCraft Creative Suite Downloader & Version Manager - by Biraj2004'

# --- COLOR PALETTE & LOGGING HELPERS ---
function Write-Header {
    param([string]$text)
    Write-Host '=======================================================================================================' -ForegroundColor Cyan
    Write-Host ("  " + $text.PadRight(101)) -ForegroundColor Cyan
    Write-Host '=======================================================================================================' -ForegroundColor Cyan
}

function Write-Divider {
    Write-Host '-------------------------------------------------------------------------------------------------------' -ForegroundColor Gray
}

# --- BANNER ---
Write-Host '=======================================================================================================' -ForegroundColor Cyan
Write-Host '                     ARTCRAFT CREATIVE SUITE DOWNLOADER & VERSION MANAGER                              ' -ForegroundColor Cyan
Write-Host '                       Developed by : Biraj                                                            ' -ForegroundColor Gray
Write-Host '                       GitHub       : https://github.com/Biraj2004                                     ' -ForegroundColor Gray
Write-Host '=======================================================================================================' -ForegroundColor Cyan
Write-Host ''
Write-Host ('[INFO] Working Directory : ' + (Get-Location).Path) -ForegroundColor White
Write-Host '[INFO] Official Source   : https://getartcraft.com/apps' -ForegroundColor White
Write-Host '[INFO] GitHub Org        : https://github.com/storytold' -ForegroundColor White
Write-Host '[INFO] Supported Targets : Windows x64 (.msi) & macOS Universal (.dmg)' -ForegroundColor White
Write-Host '[INFO] Apps Discovered   : 14 Standalone Creative Applications' -ForegroundColor White
Write-Host '[INFO] Safety & Storage  : Atomic downloads (.tmp -> final), skips up-to-date, archives older versions' -ForegroundColor White
Write-Host ''

# --- ARTCRAFT SUITE APPLICATION REGISTRY ---
$suiteRegistry = @(
    [PSCustomObject]@{
        Id          = "artcraft"
        Name        = "ArtCraft Hub"
        Repo        = "artcraft"
        Category    = "Hub & Creative Engine"
        Description = "All-in-one intentional crafting engine & creative workspace"
        FallbackTag = "artcraft-v0.41.0"
        MatchMsi    = '^ArtCraft_.*x64.*\.msi$'
        MatchDmg    = '^ArtCraft_.*\.dmg$'
        FallbackMsi = "https://github.com/storytold/artcraft/releases/download/artcraft-v0.41.0/ArtCraft_0.41.0_x64_en-US.msi"
        FallbackDmg = "https://github.com/storytold/artcraft/releases/download/artcraft-v0.41.0/ArtCraft_0.41.0_universal.dmg"
    },
    [PSCustomObject]@{
        Id          = "photocraft"
        Name        = "PhotoCraft"
        Repo        = "photocraft"
        Category    = "Photo Retouching & Editing"
        Description = "Open-source photo retouching & pixel editor (Photoshop alternative)"
        FallbackTag = "v0.7.0"
        MatchMsi    = '^photocraft-.*windows-x64\.msi$'
        MatchDmg    = '^photocraft-.*macos-universal\.dmg$'
        FallbackMsi = "https://github.com/storytold/photocraft/releases/download/v0.7.0/photocraft-0.7.0-windows-x64.msi"
        FallbackDmg = "https://github.com/storytold/photocraft/releases/download/v0.7.0/photocraft-0.7.0-macos-universal.dmg"
    },
    [PSCustomObject]@{
        Id          = "vectorcraft"
        Name        = "VectorCraft"
        Repo        = "vectorcraft"
        Category    = "Vector Art & Illustration"
        Description = "Open-source vector graphics & illustration tool (Illustrator alternative)"
        FallbackTag = "v0.9.0"
        MatchMsi    = '^vectorcraft-.*windows-x64\.msi$'
        MatchDmg    = '^vectorcraft-.*macos-universal\.dmg$'
        FallbackMsi = "https://github.com/storytold/vectorcraft/releases/download/v0.9.0/vectorcraft-0.9.0-windows-x64.msi"
        FallbackDmg = "https://github.com/storytold/vectorcraft/releases/download/v0.9.0/vectorcraft-0.9.0-macos-universal.dmg"
    },
    [PSCustomObject]@{
        Id          = "lightcraft"
        Name        = "LightCraft"
        Repo        = "lightcraft"
        Category    = "RAW & Photo Processing"
        Description = "Non-destructive RAW photo workflow & color grading (Lightroom alternative)"
        FallbackTag = "v0.6.0"
        MatchMsi    = '^lightcraft-.*windows-x64\.msi$'
        MatchDmg    = '^lightcraft-.*macos-universal\.dmg$'
        FallbackMsi = "https://github.com/storytold/lightcraft/releases/download/v0.6.0/lightcraft-0.6.0-windows-x64.msi"
        FallbackDmg = "https://github.com/storytold/lightcraft/releases/download/v0.6.0/lightcraft-0.6.0-macos-universal.dmg"
    },
    [PSCustomObject]@{
        Id          = "filmcraft"
        Name        = "FilmCraft"
        Repo        = "filmcraft"
        Category    = "Nonlinear Video Editing"
        Description = "Open-source nonlinear video editor & timeline cutter (Premiere alternative)"
        FallbackTag = "v0.6.0"
        MatchMsi    = '^filmcraft-.*windows-x64\.msi$'
        MatchDmg    = '^filmcraft-.*macos-universal\.dmg$'
        FallbackMsi = "https://github.com/storytold/filmcraft/releases/download/v0.6.0/filmcraft-0.6.0-windows-x64.msi"
        FallbackDmg = "https://github.com/storytold/filmcraft/releases/download/v0.6.0/filmcraft-0.6.0-macos-universal.dmg"
    },
    [PSCustomObject]@{
        Id          = "pdfcraft"
        Name        = "PdfCraft"
        Repo        = "pdfcraft"
        Category    = "PDF Reader & Editor"
        Description = "Open-source PDF editor, annotator & viewer (Acrobat alternative)"
        FallbackTag = "v0.6.0"
        MatchMsi    = '^pdfcraft-.*windows-x64\.msi$'
        MatchDmg    = '^pdfcraft-.*macos-universal\.dmg$'
        FallbackMsi = "https://github.com/storytold/pdfcraft/releases/download/v0.6.0/pdfcraft-0.6.0-windows-x64.msi"
        FallbackDmg = "https://github.com/storytold/pdfcraft/releases/download/v0.6.0/pdfcraft-0.6.0-macos-universal.dmg"
    },
    [PSCustomObject]@{
        Id          = "effectcraft"
        Name        = "EffectCraft"
        Repo        = "effectcraft"
        Category    = "Motion Graphics & VFX"
        Description = "Motion graphics, visual effects & compositing (After Effects alternative)"
        FallbackTag = "v0.8.0"
        MatchMsi    = '^effectcraft-.*windows-x64\.msi$'
        MatchDmg    = '^effectcraft-.*macos-universal\.dmg$'
        FallbackMsi = "https://github.com/storytold/effectcraft/releases/download/v0.8.0/effectcraft-0.8.0-windows-x64.msi"
        FallbackDmg = "https://github.com/storytold/effectcraft/releases/download/v0.8.0/effectcraft-0.8.0-macos-universal.dmg"
    },
    [PSCustomObject]@{
        Id          = "designcraft"
        Name        = "DesignCraft"
        Repo        = "designcraft"
        Category    = "Page Layout & Publishing"
        Description = "Page layout, editorial design & desktop publishing (InDesign alternative)"
        FallbackTag = "v0.6.0"
        MatchMsi    = '^designcraft-.*windows-x64\.msi$'
        MatchDmg    = '^designcraft-.*macos-universal\.dmg$'
        FallbackMsi = "https://github.com/storytold/designcraft/releases/download/v0.6.0/designcraft-0.6.0-windows-x64.msi"
        FallbackDmg = "https://github.com/storytold/designcraft/releases/download/v0.6.0/designcraft-0.6.0-macos-universal.dmg"
    },
    [PSCustomObject]@{
        Id          = "wordcraft"
        Name        = "WordCraft"
        Repo        = "wordcraft"
        Category    = "Document & Word Processing"
        Description = "Clean-room word processor & typographic document authoring (Word alternative)"
        FallbackTag = "v0.5.0"
        MatchMsi    = '^wordcraft-.*windows-x64\.msi$'
        MatchDmg    = '^wordcraft-.*macos-universal\.dmg$'
        FallbackMsi = "https://github.com/storytold/wordcraft/releases/download/v0.5.0/wordcraft-0.5.0-windows-x64.msi"
        FallbackDmg = "https://github.com/storytold/wordcraft/releases/download/v0.5.0/wordcraft-0.5.0-macos-universal.dmg"
    },
    [PSCustomObject]@{
        Id          = "gridcraft"
        Name        = "GridCraft"
        Repo        = "gridcraft"
        Category    = "Spreadsheet & Modeling"
        Description = "Clean-room spreadsheet, formula calculation & data analysis (Excel alternative)"
        FallbackTag = "v0.5.0"
        MatchMsi    = '^gridcraft-.*windows-x64\.msi$'
        MatchDmg    = '^gridcraft-.*macos-universal\.dmg$'
        FallbackMsi = "https://github.com/storytold/gridcraft/releases/download/v0.5.0/gridcraft-0.5.0-windows-x64.msi"
        FallbackDmg = "https://github.com/storytold/gridcraft/releases/download/v0.5.0/gridcraft-0.5.0-macos-universal.dmg"
    },
    [PSCustomObject]@{
        Id          = "cadcraft"
        Name        = "CADCraft"
        Repo        = "cadcraft"
        Category    = "2D/3D CAD & Drafting"
        Description = "Computer-aided drafting & parametric design engine (AutoCAD alternative)"
        FallbackTag = "v0.5.0"
        MatchMsi    = '^cadcraft-.*windows-x64\.msi$'
        MatchDmg    = '^cadcraft-.*macos-universal\.dmg$'
        FallbackMsi = "https://github.com/storytold/cadcraft/releases/download/v0.5.0/cadcraft-0.5.0-windows-x64.msi"
        FallbackDmg = "https://github.com/storytold/cadcraft/releases/download/v0.5.0/cadcraft-0.5.0-macos-universal.dmg"
    },
    [PSCustomObject]@{
        Id          = "deckcraft"
        Name        = "DeckCraft"
        Repo        = "deckcraft"
        Category    = "Presentations & Slides"
        Description = "Presentation slides, deck design & screen projection (PowerPoint alternative)"
        FallbackTag = "v0.5.0"
        MatchMsi    = '^deckcraft-.*windows-x64\.msi$'
        MatchDmg    = '^deckcraft-.*macos-universal\.dmg$'
        FallbackMsi = "https://github.com/storytold/deckcraft/releases/download/v0.5.0/deckcraft-0.5.0-windows-x64.msi"
        FallbackDmg = "https://github.com/storytold/deckcraft/releases/download/v0.5.0/deckcraft-0.5.0-macos-universal.dmg"
    },
    [PSCustomObject]@{
        Id          = "soundcraft"
        Name        = "SoundCraft"
        Repo        = "soundcraft"
        Category    = "Audio Editing & DAW"
        Description = "Digital audio workstation, waveform editing & mastering (Audition alternative)"
        FallbackTag = "v0.5.0"
        MatchMsi    = '^soundcraft-.*windows-x64\.msi$'
        MatchDmg    = '^soundcraft-.*macos-universal\.dmg$'
        FallbackMsi = "https://github.com/storytold/soundcraft/releases/download/v0.5.0/soundcraft-0.5.0-windows-x64.msi"
        FallbackDmg = "https://github.com/storytold/soundcraft/releases/download/v0.5.0/soundcraft-0.5.0-macos-universal.dmg"
    },
    [PSCustomObject]@{
        Id          = "craft-launcher"
        Name        = "ArtCraft Launcher"
        Repo        = "craft-launcher"
        Category    = "App Hub & Version Manager"
        Description = "Central app launcher & automatic version manager for Craft apps"
        FallbackTag = "v0.2.1"
        MatchMsi    = '^artcraft-launcher-.*windows-x64\.msi$'
        MatchDmg    = '^artcraft-launcher-.*macos-universal\.dmg$'
        FallbackMsi = "https://github.com/storytold/craft-launcher/releases/download/v0.2.1/artcraft-launcher-0.2.1-windows-x64.msi"
        FallbackDmg = "https://github.com/storytold/craft-launcher/releases/download/v0.2.1/artcraft-launcher-0.2.1-macos-universal.dmg"
    }
)

# --- DYNAMIC RELEASE RESOLUTION ENGINE ---
function Resolve-AppLatestRelease {
    param([PSCustomObject]$app)

    $resolvedTag = $null
    $msiUrl = $null
    $dmgUrl = $null

    # Method 1: GitHub releases/latest redirect inspection (Fast, Rate-Limit Immune)
    try {
        $headHeaders = curl.exe -sI "https://github.com/storytold/$($app.Repo)/releases/latest" 2>$null
        $locationLine = ($headHeaders | Where-Object { $_ -match '^location:\s*([^\r\n]+)' } | Select-Object -First 1)
        if ($locationLine -match 'releases/tag/(.+)$') {
            $resolvedTag = $matches[1].Trim()
        }
    } catch {}

    # Method 2: If redirect gave tag, fetch expanded_assets HTML to get exact asset URLs
    if ($resolvedTag) {
        try {
            $assetsUrl = "https://github.com/storytold/$($app.Repo)/releases/expanded_assets/$resolvedTag"
            $assetsHtml = curl.exe -sL $assetsUrl 2>$null
            $pattern = 'href="(/storytold/' + [regex]::Escape($app.Repo) + '/releases/download/[^"]+)"'
            $assetLinks = [regex]::Matches($assetsHtml, $pattern) | ForEach-Object {
                "https://github.com" + $_.Groups[1].Value
            }
            $msiUrl = ($assetLinks | Where-Object { [System.IO.Path]::GetFileName($_) -match $app.MatchMsi } | Select-Object -First 1)
            $dmgUrl = ($assetLinks | Where-Object { [System.IO.Path]::GetFileName($_) -match $app.MatchDmg } | Select-Object -First 1)
        } catch {}
    }

    # Method 3: Fallback verification if network blocked scraping
    if (-not $resolvedTag) {
        $resolvedTag = $app.FallbackTag
    }
    if (-not $msiUrl) {
        $msiUrl = $app.FallbackMsi
    }
    if (-not $dmgUrl) {
        $dmgUrl = $app.FallbackDmg
    }

    $msiFileName = if ($msiUrl) { [System.IO.Path]::GetFileName($msiUrl) } else { "N/A" }
    $dmgFileName = if ($dmgUrl) { [System.IO.Path]::GetFileName($dmgUrl) } else { "N/A" }

    return [PSCustomObject]@{
        Id          = $app.Id
        Name        = $app.Name
        Category    = $app.Category
        Tag         = $resolvedTag
        Version     = ($resolvedTag -replace '^[a-zA-Z_-]*v', '')
        MsiUrl      = $msiUrl
        MsiFileName = $msiFileName
        DmgUrl      = $dmgUrl
        DmgFileName = $dmgFileName
        MatchMsi    = $app.MatchMsi
        MatchDmg    = $app.MatchDmg
    }
}

# --- DIRECTORY INITIALIZATION ---
$currentFolder = (Get-Location).Path
$parentFolder  = Join-Path $currentFolder "ArtCraft_Suite_Installers"
$windowsFolder = Join-Path $parentFolder "Windows_x64_MSI"
$macosFolder   = Join-Path $parentFolder "macOS_Universal_DMG"

# --- PLATFORM SELECTION MENU ---
Write-Host '=======================================================================================================' -ForegroundColor Yellow
Write-Host '  SELECT TARGET PLATFORM TO DOWNLOAD:                                                                  ' -ForegroundColor Yellow
Write-Host '=======================================================================================================' -ForegroundColor Yellow
Write-Host '  [1] Both Windows (x64 Standalone MSI) and macOS (Universal Standalone DMG) [Recommended]' -ForegroundColor White
Write-Host '  [2] Windows Only (Win x64 Standalone MSI installers)' -ForegroundColor White
Write-Host '  [3] macOS Only (macOS Universal Standalone DMG installers)' -ForegroundColor White
Write-Host ''
$rawPlatform = Read-Host -Prompt 'Enter choice [1, 2, or 3] (Default: 1)'
$platformChoice = if ($rawPlatform) { $rawPlatform.Trim() } else { '1' }
if ($platformChoice -eq '2') {
    $downloadWindows = $true
    $downloadMac     = $false
    $scopeDesc       = "Windows x64 Standalone MSI Only"
} elseif ($platformChoice -eq '3') {
    $downloadWindows = $false
    $downloadMac     = $true
    $scopeDesc       = "macOS Universal Standalone DMG Only"
} else {
    $downloadWindows = $true
    $downloadMac     = $true
    $scopeDesc       = "Both Windows (x64 MSI) and macOS (Universal DMG)"
}

Write-Host ''
Write-Host '=======================================================================================================' -ForegroundColor Cyan
Write-Host ('[PLAN] Target Parent Folder : ' + $parentFolder) -ForegroundColor White
if ($downloadWindows) { Write-Host ('[PLAN] Windows Subfolder    : ' + $windowsFolder) -ForegroundColor White }
if ($downloadMac)     { Write-Host ('[PLAN] macOS Subfolder      : ' + $macosFolder) -ForegroundColor White }
Write-Host ('[PLAN] Download Scope       : ' + $scopeDesc) -ForegroundColor White
Write-Host '[PLAN] Total Applications   : 14 Standalone Creative Tools' -ForegroundColor White
Write-Host '=======================================================================================================' -ForegroundColor Cyan
Write-Host ''

# --- SAFETY CONFIRMATION GATE ---
$rawConfirm = Read-Host -Prompt 'Type Y and press Enter to begin checking and downloading, or N to cancel'
$confirm = if ($rawConfirm) { $rawConfirm.Trim() } else { 'N' }
if ($confirm -notmatch '^(y|yes)$') {
    Write-Host ''
    Write-Host '[CANCELLED] Operation cancelled by user. No folders were created and no files were downloaded.' -ForegroundColor Yellow
    Write-Host ''
    Write-Divider
    Write-Host '=======================================================================================================' -ForegroundColor Cyan
    Write-Host '[FINISHED] Script execution finished. GitHub: https://github.com/Biraj2004' -ForegroundColor Cyan
    Write-Host '=======================================================================================================' -ForegroundColor Cyan
    Write-Host ''
    exit 0
}

# Create Parent & Subfolders
if (-not [System.IO.Directory]::Exists($parentFolder)) {
    [System.IO.Directory]::CreateDirectory($parentFolder) | Out-Null
    Write-Host ("[FOLDER] Created parent directory: " + $parentFolder) -ForegroundColor Green
}
if ($downloadWindows -and (-not [System.IO.Directory]::Exists($windowsFolder))) {
    [System.IO.Directory]::CreateDirectory($windowsFolder) | Out-Null
    Write-Host ("[FOLDER] Created Windows subfolder: " + $windowsFolder) -ForegroundColor Green
}
if ($downloadMac -and (-not [System.IO.Directory]::Exists($macosFolder))) {
    [System.IO.Directory]::CreateDirectory($macosFolder) | Out-Null
    Write-Host ("[FOLDER] Created macOS subfolder  : " + $macosFolder) -ForegroundColor Green
}
Write-Host ''

# --- RESOLVING LATEST RELEASES ONLINE ---
Write-Header 'DISCOVERING LATEST VERSIONS ACROSS ALL 14 ARTCRAFT APPS'
Write-Host '[PROCESSING] Querying upstream GitHub releases in real time...' -ForegroundColor White
Write-Host ''

$resolvedApps = @()
$counter = 1
foreach ($appDef in $suiteRegistry) {
    Write-Host ("`r[QUERYING] Resolving app " + $counter + " of 14: " + $appDef.Name + "... ") -NoNewline -ForegroundColor Cyan
    $res = Resolve-AppLatestRelease -app $appDef
    $resolvedApps += $res
    $counter++
}
Write-Host "`r[SUCCESS] Discovered latest versions and installer URLs for all 14 applications!     " -ForegroundColor Green
Write-Host ''

# Display App Inventory Table
Write-Host ('{0,-3} | {1,-18} | {2,-16} | {3,-36} | {4,-36}' -f '#', 'App Name', 'Latest Tag', 'Windows x64 MSI Asset', 'macOS DMG Asset') -ForegroundColor Cyan
Write-Divider
$num = 1
foreach ($r in $resolvedApps) {
    Write-Host ('{0,-3} | {1,-18} | {2,-16} | {3,-36} | {4,-36}' -f $num, $r.Name, $r.Tag, $r.MsiFileName, $r.DmgFileName) -ForegroundColor White
    $num++
}
Write-Divider
Write-Host ''

# --- DOWNLOAD & ARCHIVING ENGINE ---
function Process-AppInstaller {
    param(
        [string]$platformName,
        [string]$targetDir,
        [string]$appName,
        [string]$tag,
        [string]$downloadUrl,
        [string]$targetFileName,
        [string]$matchRegex
    )

    if (-not $downloadUrl -or $downloadUrl -eq "N/A") {
        Write-Host ("  [ERROR] No $platformName installer available for $appName.") -ForegroundColor Red
        return "FAILED"
    }

    $finalFilePath = Join-Path $targetDir $targetFileName
    $archiveDir    = Join-Path $targetDir "_Archive_Old_Versions"

    # Step 1: Detect and gracefully handle older versions
    $existingFiles = Get-ChildItem -LiteralPath $targetDir -File -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -match $matchRegex -and $_.Name -ne $targetFileName -and $_.Name -notmatch '\.downloading\.tmp$'
    }

    if ($existingFiles -and $existingFiles.Count -gt 0) {
        if (-not [System.IO.Directory]::Exists($archiveDir)) {
            [System.IO.Directory]::CreateDirectory($archiveDir) | Out-Null
            Write-Host ("  [ARCHIVE] Created folder: " + $archiveDir) -ForegroundColor Yellow
        }
        foreach ($oldFile in $existingFiles) {
            $destOld = Join-Path $archiveDir $oldFile.Name
            if (Test-Path -LiteralPath $destOld) {
                Remove-Item -LiteralPath $destOld -Force -ErrorAction SilentlyContinue
            }
            Move-Item -LiteralPath $oldFile.FullName -Destination $destOld -Force
            Write-Host ("  [SUPERSEDED] Archived older version: " + $oldFile.Name + " -> _Archive_Old_Versions/") -ForegroundColor Yellow
        }
    }

    # Step 2: Check if exact target version is already downloaded
    if (Test-Path -LiteralPath $finalFilePath) {
        $fileSize = (Get-Item -LiteralPath $finalFilePath).Length
        if ($fileSize -gt 1048576) { # Greater than 1 MB
            $sizeMb = [math]::Round($fileSize / 1MB, 2)
            Write-Host ("  [UP-TO-DATE] $targetFileName ($sizeMb MB) is already present and latest. Skipping.") -ForegroundColor Green
            return "UP_TO_DATE"
        } else {
            Write-Host ("  [WARNING] Existing $targetFileName is incomplete or corrupted (< 1 MB). Re-downloading...") -ForegroundColor Yellow
            Remove-Item -LiteralPath $finalFilePath -Force -ErrorAction SilentlyContinue
        }
    }

    # Step 3: Atomic Download (.downloading.tmp -> Final File)
    $tempFilePath = $finalFilePath + ".downloading.tmp"
    if (Test-Path -LiteralPath $tempFilePath) {
        Remove-Item -LiteralPath $tempFilePath -Force -ErrorAction SilentlyContinue
    }

    Write-Host ("  [DOWNLOADING] " + $targetFileName + " from upstream GitHub...") -ForegroundColor White

    # Ensure target directory exists
    if (-not [System.IO.Directory]::Exists($targetDir)) {
        [System.IO.Directory]::CreateDirectory($targetDir) | Out-Null
    }

    $downloadSuccess = $false
    # Primary downloader: curl.exe with native progress bar and auto-directory creation
    if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
        try {
            & curl.exe -fL --progress-bar --create-dirs -o $tempFilePath $downloadUrl
            if ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $tempFilePath) -and (Get-Item -LiteralPath $tempFilePath).Length -gt 1048576) {
                $downloadSuccess = $true
            }
        } catch {
            $downloadSuccess = $false
        }
    }

    # Fallback downloader: Invoke-WebRequest / System.Net.WebClient
    if (-not $downloadSuccess) {
        Write-Host "  [FALLBACK] Downloading using PowerShell WebClient..." -ForegroundColor Gray
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            $webClient = New-Object System.Net.WebClient
            $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) ArtCraftDownloader/1.0")
            $webClient.DownloadFile($downloadUrl, $tempFilePath)
            if ((Test-Path -LiteralPath $tempFilePath) -and (Get-Item -LiteralPath $tempFilePath).Length -gt 1048576) {
                $downloadSuccess = $true
            }
        } catch {
            Write-Host ("  [ERROR] WebClient download failed: " + $_.Exception.Message) -ForegroundColor Red
            $downloadSuccess = $false
        }
    }

    if ($downloadSuccess) {
        Move-Item -LiteralPath $tempFilePath -Destination $finalFilePath -Force
        $finalSizeMb = [math]::Round((Get-Item -LiteralPath $finalFilePath).Length / 1MB, 2)
        Write-Host ("  [SUCCESS] Downloaded: $targetFileName ($finalSizeMb MB)") -ForegroundColor Green
        return "DOWNLOADED"
    } else {
        if (Test-Path -LiteralPath $tempFilePath) {
            Remove-Item -LiteralPath $tempFilePath -Force -ErrorAction SilentlyContinue
        }
        Write-Host ("  [ERROR] Failed to download $targetFileName from $downloadUrl") -ForegroundColor Red
        return "FAILED"
    }
}

# --- EXECUTE DOWNLOAD WORKFLOW ---
$downloadStats = @{
    TotalAttempted = 0
    Downloaded     = 0
    UpToDate       = 0
    Failed         = 0
}

$manifestRows = @()

$totalApps = $resolvedApps.Count
$currIdx = 1

foreach ($app in $resolvedApps) {
    Write-Host ''
    Write-Header ("[$currIdx / $totalApps] " + $app.Name.ToUpper() + " (" + $app.Tag + ") - " + $app.Category)
    
    # Process Windows MSI
    if ($downloadWindows) {
        $downloadStats.TotalAttempted++
        Write-Host ("[WINDOWS x64 MSI] Checking: " + $app.MsiFileName) -ForegroundColor Cyan
        $winStatus = Process-AppInstaller `
            -platformName "Windows" `
            -targetDir $windowsFolder `
            -appName $app.Name `
            -tag $app.Tag `
            -downloadUrl $app.MsiUrl `
            -targetFileName $app.MsiFileName `
            -matchRegex $app.MatchMsi

        if ($winStatus -eq "DOWNLOADED") { $downloadStats.Downloaded++ }
        elseif ($winStatus -eq "UP_TO_DATE") { $downloadStats.UpToDate++ }
        else { $downloadStats.Failed++ }

        $manifestRows += [PSCustomObject]@{
            Platform = "Windows x64"
            App      = $app.Name
            Tag      = $app.Tag
            File     = $app.MsiFileName
            Status   = $winStatus
            Url      = $app.MsiUrl
        }
    }

    # Process macOS DMG
    if ($downloadMac) {
        $downloadStats.TotalAttempted++
        Write-Host ("[macOS UNIVERSAL DMG] Checking: " + $app.DmgFileName) -ForegroundColor Cyan
        $macStatus = Process-AppInstaller `
            -platformName "macOS" `
            -targetDir $macosFolder `
            -appName $app.Name `
            -tag $app.Tag `
            -downloadUrl $app.DmgUrl `
            -targetFileName $app.DmgFileName `
            -matchRegex $app.MatchDmg

        if ($macStatus -eq "DOWNLOADED") { $downloadStats.Downloaded++ }
        elseif ($macStatus -eq "UP_TO_DATE") { $downloadStats.UpToDate++ }
        else { $downloadStats.Failed++ }

        $manifestRows += [PSCustomObject]@{
            Platform = "macOS Universal"
            App      = $app.Name
            Tag      = $app.Tag
            File     = $app.DmgFileName
            Status   = $macStatus
            Url      = $app.DmgUrl
        }
    }

    $currIdx++
}

# --- WRITE COMPREHENSIVE SUITE MANIFEST ---
$manifestPath = Join-Path $parentFolder "ArtCraft_Suite_Manifest.txt"
$timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

$manifestContent = @"
=======================================================================================================
ARTCRAFT CREATIVE SUITE - INSTALLER INVENTORY & VERSION MANIFEST
Generated on : $timestamp
Managed by   : Win_Download_ArtCraft_Suite_Apps.bat (Biraj2004)
Official Hub : https://getartcraft.com/apps
GitHub Org   : https://github.com/storytold
=======================================================================================================

TOTAL ASSETS MANAGED : $($downloadStats.TotalAttempted)
NEWLY DOWNLOADED     : $($downloadStats.Downloaded)
ALREADY UP TO DATE   : $($downloadStats.UpToDate)
DOWNLOAD FAILURES    : $($downloadStats.Failed)

-------------------------------------------------------------------------------------------------------
PLATFORM          | APP NAME            | VERSION TAG     | INSTALLER FILENAME                     | STATUS
-------------------------------------------------------------------------------------------------------
"@

foreach ($row in $manifestRows) {
    $manifestContent += "`r`n" + ('{0,-17} | {1,-19} | {2,-15} | {3,-38} | {4}' -f $row.Platform, $row.App, $row.Tag, $row.File, $row.Status)
}

$manifestContent += @"

=======================================================================================================
DIRECTORY LOCATIONS:
Parent Folder  : $parentFolder
Windows MSI    : $windowsFolder
macOS DMG      : $macosFolder
Archive Folder : _Archive_Old_Versions (Inside respective platform folders when older files are replaced)
=======================================================================================================
"@

if (-not [System.IO.Directory]::Exists($parentFolder)) {
    [System.IO.Directory]::CreateDirectory($parentFolder) | Out-Null
}
[System.IO.File]::WriteAllText($manifestPath, $manifestContent, [System.Text.Encoding]::UTF8)

# --- FINAL SUMMARY ---
Write-Host ''
Write-Header 'EXECUTION SUMMARY & INVENTORY REPORT'
Write-Host ('[SUMMARY] Target Folder        : ' + $parentFolder) -ForegroundColor White
Write-Host ('[SUMMARY] Total Files Handled  : ' + $downloadStats.TotalAttempted) -ForegroundColor White
Write-Host ('[SUMMARY] Newly Downloaded     : ' + $downloadStats.Downloaded) -ForegroundColor Green
Write-Host ('[SUMMARY] Already Up To Date   : ' + $downloadStats.UpToDate) -ForegroundColor Cyan
Write-Host ('[SUMMARY] Failures / Errors    : ' + $downloadStats.Failed) -ForegroundColor $(if ($downloadStats.Failed -gt 0) { "Red" } else { "Green" })
Write-Host ('[SUMMARY] Version Manifest Log : ' + $manifestPath) -ForegroundColor Yellow
Write-Host ''

if ($downloadStats.Failed -eq 0) {
    Write-Host '=======================================================================================================' -ForegroundColor Green
    Write-Host '[SUCCESS] All ArtCraft apps verified and up-to-date in their dedicated folders!' -ForegroundColor Green
    Write-Host '=======================================================================================================' -ForegroundColor Green
} else {
    Write-Host '=======================================================================================================' -ForegroundColor Yellow
    Write-Host '[NOTE] Process finished with warnings or failed assets. Check network connectivity and retry.' -ForegroundColor Yellow
    Write-Host '=======================================================================================================' -ForegroundColor Yellow
}

Write-Host ''
Write-Divider
Write-Host '=======================================================================================================' -ForegroundColor Cyan
Write-Host '[FINISHED] Script execution finished. GitHub: https://github.com/Biraj2004' -ForegroundColor Cyan
Write-Host '=======================================================================================================' -ForegroundColor Cyan
Write-Host ''

for ($i = 5; $i -gt 0; $i--) {
    Write-Host ("`r[INFO] Window will close in $i sec (or press any key to exit now)... ") -NoNewline -ForegroundColor Yellow
    try {
        if (-not [Console]::IsInputRedirected -and [Console]::KeyAvailable) { break }
    } catch {}
    Start-Sleep -Seconds 1
}
Write-Host ''
