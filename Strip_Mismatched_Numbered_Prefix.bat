@echo off
setlocal enabledelayedexpansion
title Strip Numbered Prefix - by Biraj2004
cd /d "%~dp0"

:: =========================================================================================================
:: GitHub      : https://github.com/Biraj2004
:: Developer   : Biraj
:: Description : Recursively scans this folder and ALL subfolders for
::                .mp4 and .pdf files, and strips a leading numeric
::                prefix (e.g. "07-", "12 -") from each filename, IF
::                the text before the FIRST hyphen is made up of
::                digits only.
::                - Only the part up to and including the first "-"
::                  is removed. Everything after it is left untouched.
::                - Files whose prefix is NOT purely numeric (e.g.
::                  "Part1-Intro.mp4") are left alone.
::                - Files with no hyphen at all are left alone.
:: =========================================================================================================

echo =======================================================================================================
echo                       STRIP NUMBERED PREFIX SCRIPT
echo                       Developed by : Biraj
echo                       GitHub       : https://github.com/Biraj2004
echo =======================================================================================================
echo.
echo [INFO] Working Folder      : %CD%
echo [INFO] Target Extensions   : .mp4, .pdf
echo [INFO] Action              : Strip leading "NUMBER-" prefix from filenames
echo [INFO] Scope               : Current folder + ALL subfolders (Recursive)
echo [INFO] Safety              : Only files with a PURELY NUMERIC prefix before
echo [INFO]                       the first hyphen are touched. Everything else
echo [INFO]                       is left completely untouched.
echo.
echo =======================================================================================================
echo  WARNING: This will RENAME .mp4 and .pdf files inside:
echo    %CD%
echo  ...and every SUB-FOLDER inside it.
echo =======================================================================================================
echo.
set "CONFIRM="
set /p CONFIRM=Type Y and press Enter to proceed, or N to cancel : 

if /i "%CONFIRM%"=="Y" goto :PROCEED
if /i "%CONFIRM%"=="YES" goto :PROCEED

echo.
echo [CANCELLED] No files were scanned or renamed. Exiting safely.
echo.
pause
endlocal
exit /b 0

:PROCEED
echo.
echo [PROCESSING] Scanning files...
echo =======================================================================================================
echo.

set "renamed=0"
set "errors=0"

for /r %%F in (*.mp4 *.pdf) do (
    set "fname=%%~nxF"
    set "prefix="

    rem --- get the part before the first hyphen ---
    for /f "delims=-" %%A in ("!fname!") do set "prefix=%%A"

    rem --- check if that prefix is ONLY digits ---
    set "isnum=1"
    set "check=!prefix!"
    for /f "delims=0123456789" %%C in ("!check!") do set "isnum=0"

    if defined prefix if "!isnum!"=="1" (
        rem --- strip everything up to and including the first hyphen ---
        set "newname=!fname:*-=!"

        if not "!newname!"=="!fname!" (
            ren "%%F" "!newname!" 2>nul
            if exist "%%~dpF!newname!" (
                echo [RENAMED]  !fname!
                echo            --^>   !newname!
                set /a renamed+=1
            ) else (
                echo [ERROR]    Could not rename !fname!
                set /a errors+=1
            )
        )
    )
)

echo.
echo =======================================================================================================
echo [SUMMARY] Renamed : !renamed!
echo [SUMMARY] Errors  : !errors!
echo =======================================================================================================
echo.
echo [FINISHED] Script execution finished. GitHub: https://github.com/Biraj2004
echo =======================================================================================================
echo.
pause
endlocal
