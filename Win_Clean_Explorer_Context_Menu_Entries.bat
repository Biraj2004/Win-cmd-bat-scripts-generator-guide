<# :
@echo off
setlocal EnableDelayedExpansion
title Explorer Context Menu Cleaner - by Biraj2004
cd /d "%~dp0"

:: =======================================================================================================
:: GitHub      : https://github.com/Biraj2004
:: Developer   : Biraj
:: Description : Scans Windows File Explorer context menu entries in HKLM & HKCU registry locations,
::                identifies leftover/orphaned entries pointing to non-existent executables or uninstalled
::                applications (e.g. PyCharm, WebStorm, Codex, MediaInfo, ArmouryCrate / GameLibrary),
::                creates an automatic .reg backup before any changes, allows selective manual or bulk
::                removal, and optionally restarts Windows Explorer to apply changes immediately.
:: =======================================================================================================

where powershell >nul 2>&1
if errorlevel 1 (
    echo [ERROR] PowerShell was not found on this system. Cannot continue.
    echo.
    pause
    exit /b 1
)

powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create([System.IO.File]::ReadAllText('%~f0')))"

echo -------------------------------------------------------------------------------------------------------
echo =======================================================================================================
echo [FINISHED] Script execution finished. GitHub: https://github.com/Biraj2004
echo =======================================================================================================
echo.
pause
endlocal
exit /b
#>

$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'Explorer Context Menu Cleaner - by Biraj2004'

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

Write-Host '=======================================================================================================' -ForegroundColor Cyan
Write-Host '                               EXPLORER CONTEXT MENU CLEANER                                           ' -ForegroundColor Cyan
Write-Host '                       Developed by : Biraj                                                            ' -ForegroundColor Gray
Write-Host '                       GitHub       : https://github.com/Biraj2004                                     ' -ForegroundColor Gray
Write-Host '=======================================================================================================' -ForegroundColor Cyan
Write-Host ''
Write-Host ('[INFO] Working Directory : ' + (Get-Location).Path) -ForegroundColor White
if ($isAdmin) {
    Write-Host '[INFO] Privilege Level   : Administrator (Full Access - HKLM & HKCU)' -ForegroundColor Green
} else {
    Write-Host '[INFO] Privilege Level   : Standard User (Tip: Run as Admin if cleaning HKLM keys)' -ForegroundColor Yellow
}
Write-Host '[INFO] Scope             : HKLM & HKCU Context Menu Registry Roots (shell & shellex)' -ForegroundColor White
Write-Host '[INFO] Targets           : Orphaned entries, missing .exe targets, uninstalled software' -ForegroundColor White
Write-Host '[INFO] Safety            : Automatic timestamped .reg backup created before any registry deletion' -ForegroundColor White
Write-Host ('[INFO] Backup Location  : ' + (Join-Path (Get-Location).Path 'context_menu_backup_YYYYMMDD_HHMMSS.reg')) -ForegroundColor White
Write-Host ''
Write-Host '=======================================================================================================' -ForegroundColor Yellow
Write-Host '  WARNING: This tool will scan context menu entries and allow you to select and delete leftover keys.  ' -ForegroundColor Yellow
Write-Host '=======================================================================================================' -ForegroundColor Yellow
Write-Host ''

$confirmGate = (Read-Host -Prompt 'Type Y and press Enter to scan and proceed, or N to cancel').Trim()
if ($confirmGate -notmatch '^(y|yes)$') {
    Write-Host ''
    Write-Host '[CANCELLED] Scan cancelled. No files or registry keys were modified. Exiting safely.' -ForegroundColor Yellow
    Write-Host ''
    return
}

Write-Host ''
Write-Host '[PROCESSING] Scanning registry context menu locations across HKLM & HKCU...' -ForegroundColor White
Write-Host '=======================================================================================================' -ForegroundColor Gray

$registryRoots = @(
    @{ Hive = [Microsoft.Win32.Registry]::LocalMachine; SubKey = 'Software\Classes\Directory\shell'; Name = 'HKLM\Software\Classes\Directory\shell'; Type = 'shell' },
    @{ Hive = [Microsoft.Win32.Registry]::CurrentUser;  SubKey = 'Software\Classes\Directory\shell'; Name = 'HKCU\Software\Classes\Directory\shell'; Type = 'shell' },
    @{ Hive = [Microsoft.Win32.Registry]::LocalMachine; SubKey = 'Software\Classes\Directory\Background\shell'; Name = 'HKLM\Software\Classes\Directory\Background\shell'; Type = 'shell' },
    @{ Hive = [Microsoft.Win32.Registry]::CurrentUser;  SubKey = 'Software\Classes\Directory\Background\shell'; Name = 'HKCU\Software\Classes\Directory\Background\shell'; Type = 'shell' },
    @{ Hive = [Microsoft.Win32.Registry]::LocalMachine; SubKey = 'Software\Classes\Folder\shell'; Name = 'HKLM\Software\Classes\Folder\shell'; Type = 'shell' },
    @{ Hive = [Microsoft.Win32.Registry]::CurrentUser;  SubKey = 'Software\Classes\Folder\shell'; Name = 'HKCU\Software\Classes\Folder\shell'; Type = 'shell' },
    @{ Hive = [Microsoft.Win32.Registry]::LocalMachine; SubKey = 'Software\Classes\*\shell'; Name = 'HKLM\Software\Classes\*\shell'; Type = 'shell' },
    @{ Hive = [Microsoft.Win32.Registry]::CurrentUser;  SubKey = 'Software\Classes\*\shell'; Name = 'HKCU\Software\Classes\*\shell'; Type = 'shell' },
    @{ Hive = [Microsoft.Win32.Registry]::LocalMachine; SubKey = 'Software\Classes\Directory\shellex\ContextMenuHandlers'; Name = 'HKLM\Software\Classes\Directory\shellex\ContextMenuHandlers'; Type = 'shellex' },
    @{ Hive = [Microsoft.Win32.Registry]::CurrentUser;  SubKey = 'Software\Classes\Directory\shellex\ContextMenuHandlers'; Name = 'HKCU\Software\Classes\Directory\shellex\ContextMenuHandlers'; Type = 'shellex' },
    @{ Hive = [Microsoft.Win32.Registry]::LocalMachine; SubKey = 'Software\Classes\Directory\Background\shellex\ContextMenuHandlers'; Name = 'HKLM\Software\Classes\Directory\Background\shellex\ContextMenuHandlers'; Type = 'shellex' },
    @{ Hive = [Microsoft.Win32.Registry]::CurrentUser;  SubKey = 'Software\Classes\Directory\Background\shellex\ContextMenuHandlers'; Name = 'HKCU\Software\Classes\Directory\Background\shellex\ContextMenuHandlers'; Type = 'shellex' },
    @{ Hive = [Microsoft.Win32.Registry]::LocalMachine; SubKey = 'Software\Classes\Folder\shellex\ContextMenuHandlers'; Name = 'HKLM\Software\Classes\Folder\shellex\ContextMenuHandlers'; Type = 'shellex' },
    @{ Hive = [Microsoft.Win32.Registry]::CurrentUser;  SubKey = 'Software\Classes\Folder\shellex\ContextMenuHandlers'; Name = 'HKCU\Software\Classes\Folder\shellex\ContextMenuHandlers'; Type = 'shellex' },
    @{ Hive = [Microsoft.Win32.Registry]::LocalMachine; SubKey = 'Software\Classes\*\shellex\ContextMenuHandlers'; Name = 'HKLM\Software\Classes\*\shellex\ContextMenuHandlers'; Type = 'shellex' },
    @{ Hive = [Microsoft.Win32.Registry]::CurrentUser;  SubKey = 'Software\Classes\*\shellex\ContextMenuHandlers'; Name = 'HKCU\Software\Classes\*\shellex\ContextMenuHandlers'; Type = 'shellex' }
)

$targetKeywords = @('pycharm', 'webstorm', 'codex', 'mediainfo', 'armoury', 'gamelibrary', 'asus')

function Extract-ExePath {
    param([string]$cmdStr)
    if (-not $cmdStr) { return $null }
    $cmdStr = $cmdStr.Trim()
    if ($cmdStr -match '^"([^"]+)"') {
        return $matches[1]
    } elseif ($cmdStr -match '^([^\s]+\.exe)') {
        return $matches[1]
    } elseif ($cmdStr -match '^([^\s]+)') {
        return $matches[1]
    }
    return $cmdStr
}

$allEntries = [System.Collections.Generic.List[PSCustomObject]]::new()

foreach ($r in $registryRoots) {
    try {
        $baseKey = $r.Hive.OpenSubKey($r.SubKey)
        if ($baseKey) {
            $subKeyNames = $baseKey.GetSubKeyNames()
            foreach ($skName in $subKeyNames) {
                $itemKey = $baseKey.OpenSubKey($skName)
                if ($itemKey) {
                    $displayVal = $itemKey.GetValue('')
                    $iconVal = $itemKey.GetValue('Icon')
                    $muiverb = $itemKey.GetValue('MUIVerb')
                    
                    $cmdVal = $null
                    $cmdKey = $itemKey.OpenSubKey('command')
                    if ($cmdKey) {
                        $cmdVal = $cmdKey.GetValue('')
                        $cmdKey.Close()
                    }
                    $itemKey.Close()
                    
                    $fullRegPath = ($r.Name + '\' + $skName)
                    $exeFromCmd = Extract-ExePath $cmdVal

                    $isOrphaned = $false
                    $reason = ''

                    $combinedText = "$skName $displayVal $muiverb $iconVal $cmdVal".ToLower()
                    $matchedKw = $null
                    foreach ($kw in $targetKeywords) {
                        if ($combinedText -match [regex]::Escape($kw)) {
                            $matchedKw = $kw
                            break
                        }
                    }

                    $missingExe = $false
                    if ($exeFromCmd -and ($exeFromCmd -like '*.exe' -or $exeFromCmd -like '*\*')) {
                        $expanded = [System.Environment]::ExpandEnvironmentVariables($exeFromCmd)
                        if (-not (Test-Path -LiteralPath $expanded -PathType Leaf)) {
                            $foundInPath = $false
                            if (-not ($expanded -match '[\\/]')) {
                                $cmdObj = Get-Command $expanded -ErrorAction SilentlyContinue
                                if ($cmdObj) { $foundInPath = $true }
                            }
                            if (-not $foundInPath) {
                                $missingExe = $true
                                $reason = "Executable not found: $expanded"
                            }
                        }
                    }

                    # Check shellex CLSID handlers
                    if ($r.Type -eq 'shellex' -and $displayVal -match '^\{[0-9a-fA-F-]{36}\}$') {
                        $clsid = $displayVal
                        $clsidKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("Software\Classes\CLSID\$clsid\InprocServer32")
                        if (-not $clsidKey) {
                            $clsidKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey("Software\Classes\CLSID\$clsid\InprocServer32")
                        }
                        if ($clsidKey) {
                            $dllPath = $clsidKey.GetValue('')
                            $clsidKey.Close()
                            if ($dllPath) {
                                $expandedDll = [System.Environment]::ExpandEnvironmentVariables($dllPath)
                                if (-not (Test-Path -LiteralPath $expandedDll)) {
                                    $missingExe = $true
                                    $reason = "InprocServer32 COM DLL missing ($expandedDll)"
                                }
                            }
                        } else {
                            $missingExe = $true
                            $reason = "CLSID $clsid not found in InprocServer32"
                        }
                    }

                    if ($matchedKw) {
                        $isOrphaned = $true
                        if ($missingExe) {
                            $reason = "Target uninstalled software ($matchedKw) & missing target ($reason)"
                        } else {
                            $reason = "Target uninstalled software ($matchedKw)"
                        }
                    } elseif ($missingExe) {
                        $isOrphaned = $true
                    }

                    $allEntries.Add([PSCustomObject]@{
                        Index        = 0
                        HiveName     = if ($r.Name -like 'HKLM*') { 'HKLM' } else { 'HKCU' }
                        SubKeyPath   = ($r.SubKey + '\' + $skName)
                        FullPath     = $fullRegPath
                        KeyName      = $skName
                        DisplayName  = if ($displayVal) { $displayVal } else { $muiverb }
                        Icon         = $iconVal
                        Command      = $cmdVal
                        IsOrphaned   = $isOrphaned
                        Reason       = $reason
                        Type         = $r.Type
                    })
                }
            }
            $baseKey.Close()
        }
    } catch {
        Write-Warning ("Error scanning " + $r.Name + ": " + $_)
    }
}

$orphanedList = $allEntries | Where-Object { $_.IsOrphaned }
$orphanedCount = ($orphanedList | Measure-Object).Count

Write-Host ('[INFO] Total Context Menu Entries Scanned : ' + $allEntries.Count) -ForegroundColor Gray
Write-Host ('[INFO] Orphaned / Uninstalled Detected    : ' + $orphanedCount) -ForegroundColor $(if ($orphanedCount -gt 0) { 'Yellow' } else { 'Green' })
Write-Host ''
Write-Host '=======================================================================================================' -ForegroundColor Cyan
Write-Host '                     DETECTED LEFTOVER / ORPHANED CONTEXT MENU ENTRIES                                 ' -ForegroundColor Cyan
Write-Host '=======================================================================================================' -ForegroundColor Cyan
Write-Host ''

if ($orphanedCount -eq 0) {
    Write-Host '[SUCCESS] No orphaned or uninstalled context menu entries were found! Your registry is clean.' -ForegroundColor Green
    Write-Host ''
    return
}

$idx = 1
foreach ($item in $orphanedList) {
    $item.Index = $idx
    Write-Host ("[$idx] " + $item.FullPath) -ForegroundColor Yellow
    $displayInfo = if ($item.DisplayName) { " [" + $item.DisplayName + "]" } else { "" }
    Write-Host ("    Name / Verb : " + $item.KeyName + $displayInfo) -ForegroundColor White
    if ($item.Icon)    { Write-Host ("    Icon        : " + $item.Icon) -ForegroundColor Gray }
    if ($item.Command) { Write-Host ("    Command     : " + $item.Command) -ForegroundColor Gray }
    Write-Host ("    Status      : " + $item.Reason) -ForegroundColor Red
    Write-Host ''
    $idx++
}

Write-Host '=======================================================================================================' -ForegroundColor Cyan
Write-Host ' CLEANUP OPTIONS:' -ForegroundColor Cyan
Write-Host '   [A]     - Delete ALL detected orphaned / uninstalled entries above' -ForegroundColor White
Write-Host '   [1,2..] - Delete specific entry numbers (e.g. 1, 3, 5 or 1-4, 7)' -ForegroundColor White
Write-Host '   [N]     - Cancel and exit without deleting anything' -ForegroundColor White
Write-Host '=======================================================================================================' -ForegroundColor Cyan
Write-Host ''

$choice = (Read-Host -Prompt 'Enter your choice ([A]ll / Numbers / [N]o)').Trim()

if (-not $choice -or $choice -match '^(n|no|q|quit)$') {
    Write-Host ''
    Write-Host '[CANCELLED] No registry entries were modified. Exiting safely.' -ForegroundColor Yellow
    Write-Host ''
    return
}

$selectedItems = [System.Collections.Generic.List[PSCustomObject]]::new()

if ($choice -match '^(a|all)$') {
    $selectedItems.AddRange($orphanedList)
} else {
    $tokens = $choice -split '[,\s]+'
    foreach ($token in $tokens) {
        if ($token -match '^(\d+)-(\d+)$') {
            $start = [int]$matches[1]
            $end = [int]$matches[2]
            for ($i = $start; $i -le $end; $i++) {
                $matchItem = $orphanedList | Where-Object { $_.Index -eq $i }
                if ($matchItem -and -not $selectedItems.Contains($matchItem)) {
                    $selectedItems.Add($matchItem)
                }
            }
        } elseif ($token -match '^\d+$') {
            $num = [int]$token
            $matchItem = $orphanedList | Where-Object { $_.Index -eq $num }
            if ($matchItem -and -not $selectedItems.Contains($matchItem)) {
                $selectedItems.Add($matchItem)
            }
        }
    }
}

if ($selectedItems.Count -eq 0) {
    Write-Host ''
    Write-Host '[WARNING] No valid entries were selected from the list. Exiting safely.' -ForegroundColor Yellow
    Write-Host ''
    return
}

# Check if any selected item is in HKLM while not admin
$hasHklmSelected = ($selectedItems | Where-Object { $_.HiveName -eq 'HKLM' } | Measure-Object).Count -gt 0
if ($hasHklmSelected -and -not $isAdmin) {
    Write-Host ''
    Write-Host '=======================================================================================================' -ForegroundColor Red
    Write-Host ' [WARNING] ELEVATION REQUIRED TO DELETE HKLM KEYS:' -ForegroundColor Red
    Write-Host ' You have selected keys under HKEY_LOCAL_MACHINE (HKLM).' -ForegroundColor Red
    Write-Host ' Deleting HKLM keys requires Administrator privileges.' -ForegroundColor Red
    Write-Host ' Please right-click "Win_Clean_Explorer_Context_Menu_Entries.bat" and choose "Run as administrator".' -ForegroundColor Yellow
    Write-Host '=======================================================================================================' -ForegroundColor Red
    Write-Host ''
    $proceedAnyway = (Read-Host -Prompt 'Do you want to proceed with HKCU keys only? Type Y for HKCU only, or N to exit').Trim()
    if ($proceedAnyway -match '^(y|yes)$') {
        $hkcuOnly = [System.Collections.Generic.List[PSCustomObject]]::new()
        foreach ($item in $selectedItems) {
            if ($item.HiveName -eq 'HKCU') {
                $hkcuOnly.Add($item)
            }
        }
        $selectedItems = $hkcuOnly
        if ($selectedItems.Count -eq 0) {
            Write-Host '[INFO] No HKCU keys selected. Exiting safely.' -ForegroundColor Yellow
            return
        }
    } else {
        Write-Host '[CANCELLED] Exiting safely. Please run as Administrator.' -ForegroundColor Yellow
        return
    }
}

Write-Host ''
Write-Host '=======================================================================================================' -ForegroundColor Yellow
Write-Host (" CONFIRMATION GATE: You selected " + $selectedItems.Count + " registry key(s) to remove:") -ForegroundColor Yellow
Write-Host '=======================================================================================================' -ForegroundColor Yellow
foreach ($si in $selectedItems) {
    Write-Host ("  -> [" + $si.Index + "] " + $si.FullPath) -ForegroundColor Yellow
}
Write-Host ''
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backupFile = Join-Path (Get-Location).Path ("context_menu_backup_" + $timestamp + ".reg")
Write-Host ('[SAFETY] A full registry backup will be saved to:' ) -ForegroundColor Cyan
Write-Host ('         ' + $backupFile) -ForegroundColor Cyan
Write-Host ''

$confirmFinal = (Read-Host -Prompt 'Are you SURE you want to delete these keys? Type Y to proceed, or N to cancel').Trim()
if ($confirmFinal -notmatch '^(y|yes)$') {
    Write-Host ''
    Write-Host '[CANCELLED] Deletion cancelled by user. No registry keys were removed.' -ForegroundColor Yellow
    Write-Host ''
    return
}

# Step 1: Automatic Backup to .reg file
Write-Host ''
Write-Host '[BACKUP] Exporting selected keys to backup file...' -ForegroundColor Cyan

$regHeader = "Windows Registry Editor Version 5.00`r`n`r`n"
[System.IO.File]::WriteAllText($backupFile, $regHeader, [System.Text.Encoding]::Unicode)

foreach ($si in $selectedItems) {
    $tempFile = [System.IO.Path]::GetTempFileName()
    $exportPath = $si.FullPath
    $proc = Start-Process reg.exe -ArgumentList ("export `"" + $exportPath + "`" `"" + $tempFile + "`" /y") -Wait -NoNewWindow -PassThru
    if ($proc.ExitCode -eq 0 -and (Test-Path -LiteralPath $tempFile)) {
        $exportedContent = Get-Content -LiteralPath $tempFile -Raw -Encoding Unicode
        $cleanContent = $exportedContent -replace "^Windows Registry Editor Version 5\.00\r?\n\r?\n", ""
        [System.IO.File]::AppendAllText($backupFile, "; Backup of: $exportPath`r`n" + $cleanContent + "`r`n", [System.Text.Encoding]::Unicode)
        Remove-Item -LiteralPath $tempFile -Force -ErrorAction SilentlyContinue
    }
}
Write-Host ('[BACKUP COMPLETED] Full Path : ' + $backupFile) -ForegroundColor Green

# Step 2: Delete Selected Registry Keys
Write-Host ''
Write-Host '[PROCESSING] Removing selected registry keys...' -ForegroundColor Cyan
$deletedCount = 0
$failCount = 0

foreach ($si in $selectedItems) {
    $regKeyPath = $si.FullPath
    $proc = Start-Process reg.exe -ArgumentList ("delete `"" + $regKeyPath + "`" /f") -Wait -NoNewWindow -PassThru
    if ($proc.ExitCode -eq 0) {
        Write-Host ('[DELETED] Successfully removed: ' + $regKeyPath) -ForegroundColor Green
        $deletedCount++
    } else {
        Write-Host ('[ERROR] Failed to delete: ' + $regKeyPath + ' (Error code: ' + $proc.ExitCode + ')') -ForegroundColor Red
        $failCount++
    }
}

Write-Host ''
Write-Host '=======================================================================================================' -ForegroundColor Cyan
Write-Host ('[SUMMARY] Keys Removed : ' + $deletedCount + ' | Failed: ' + $failCount) -ForegroundColor Green
Write-Host ('[BACKUP FILE LOCATION] : ' + $backupFile) -ForegroundColor Green
Write-Host '=======================================================================================================' -ForegroundColor Cyan
Write-Host ''

# Step 3: Prompt for Explorer Restart
$restartAns = (Read-Host -Prompt 'Would you like to restart Windows Explorer now to apply changes? (Y/N)').Trim()
if ($restartAns -match '^(y|yes)$') {
    Write-Host ''
    Write-Host '[PROCESSING] Restarting Windows Explorer...' -ForegroundColor Cyan
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
    $explorerCheck = Get-Process -Name explorer -ErrorAction SilentlyContinue
    if (-not $explorerCheck) {
        Start-Process explorer.exe
    }
    Write-Host '[SUCCESS] Windows Explorer restarted successfully!' -ForegroundColor Green
} else {
    Write-Host ''
    Write-Host '[INFO] Windows Explorer restart skipped. Changes will take effect on next login or reboot.' -ForegroundColor Gray
}
