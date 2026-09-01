<# :
@echo off
setlocal EnableDelayedExpansion
title Restart Windows Explorer - by Biraj2004
cd /d "%~dp0"

:: =======================================================================================================
:: GitHub      : https://github.com/Biraj2004
:: Developer   : Biraj
:: Description : Gracefully terminates and relaunches the Windows Explorer process (explorer.exe)
::                to instantly refresh the desktop, taskbar, shell extensions, and context menus
::                without requiring a system sign-out or restart.
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
$Host.UI.RawUI.WindowTitle = 'Restart Windows Explorer - by Biraj2004'

Write-Host '=======================================================================================================' -ForegroundColor Cyan
Write-Host '                                  RESTART WINDOWS EXPLORER                                             ' -ForegroundColor Cyan
Write-Host '                       Developed by : Biraj                                                            ' -ForegroundColor Gray
Write-Host '                       GitHub       : https://github.com/Biraj2004                                     ' -ForegroundColor Gray
Write-Host '=======================================================================================================' -ForegroundColor Cyan
Write-Host ''
Write-Host ('[INFO] Working Directory : ' + (Get-Location).Path) -ForegroundColor White
Write-Host '[INFO] Action            : Terminate & relaunch explorer.exe process' -ForegroundColor White
Write-Host '[INFO] Purpose           : Refresh taskbar, desktop, and file context menu changes' -ForegroundColor White
Write-Host '[INFO] Safety            : Running apps remain open; desktop will reload in ~1 second' -ForegroundColor White
Write-Host ''
Write-Host '=======================================================================================================' -ForegroundColor Yellow
Write-Host '  WARNING: This will briefly restart the Windows Explorer desktop and taskbar shell interface.        ' -ForegroundColor Yellow
Write-Host '=======================================================================================================' -ForegroundColor Yellow
Write-Host ''

$confirmGate = (Read-Host -Prompt 'Type Y and press Enter to restart Explorer, or N to cancel').Trim()
if ($confirmGate -notmatch '^(y|yes)$') {
    Write-Host ''
    Write-Host '[CANCELLED] Explorer restart cancelled. No processes were modified. Exiting safely.' -ForegroundColor Yellow
    Write-Host ''
    Write-Host '-------------------------------------------------------------------------------------------------------' -ForegroundColor Gray
    Write-Host '=======================================================================================================' -ForegroundColor Cyan
    Write-Host '[FINISHED] Script execution finished. GitHub: https://github.com/Biraj2004' -ForegroundColor Cyan
    Write-Host '=======================================================================================================' -ForegroundColor Cyan
    Write-Host ''
    for ($i = 5; $i -gt 0; $i--) {
        Write-Host ("`r[INFO] Exiting in $i sec... ") -NoNewline -ForegroundColor Yellow
        Start-Sleep -Seconds 1
    }
    Write-Host ''
    return
}

Write-Host ''
Write-Host '[PROCESSING] Terminating explorer.exe process...' -ForegroundColor Cyan

Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

$explorerCheck = Get-Process -Name explorer -ErrorAction SilentlyContinue
if (-not $explorerCheck) {
    Write-Host '[PROCESSING] Relaunching Windows Explorer shell...' -ForegroundColor Cyan
    Start-Process explorer.exe
}

Start-Sleep -Milliseconds 500

Write-Host ''
Write-Host '=======================================================================================================' -ForegroundColor Green
Write-Host '[SUCCESS] Windows Explorer restarted successfully! Shell changes applied.' -ForegroundColor Green
Write-Host '=======================================================================================================' -ForegroundColor Green
Write-Host ''
Write-Host '-------------------------------------------------------------------------------------------------------' -ForegroundColor Gray
Write-Host '=======================================================================================================' -ForegroundColor Cyan
Write-Host '[FINISHED] Script execution finished. GitHub: https://github.com/Biraj2004' -ForegroundColor Cyan
Write-Host '=======================================================================================================' -ForegroundColor Cyan
Write-Host ''

for ($i = 5; $i -gt 0; $i--) {
    Write-Host ("`r[INFO] Exiting in $i sec... ") -NoNewline -ForegroundColor Yellow
    Start-Sleep -Seconds 1
}
Write-Host ''
