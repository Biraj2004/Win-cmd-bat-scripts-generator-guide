@echo off
setlocal enabledelayedexpansion
title Remove @hamaracollege Watermark - by Biraj2004
cd /d "%~dp0"

:: =========================================================================================================
:: GitHub      : https://github.com/Biraj2004
:: Developer   : Biraj
:: Description : Recursively scans this folder and ALL subfolders for
::                ANY file whose name contains the "@hamaracollege" /
::                "@hmaracollege" watermark tag (in common case
::                variations), and strips ONLY that tag out of the
::                filename.
::                - Works on ALL file types (mp4, srt, vtt, pdf, etc.)
::                  since Udemy course downloads mix file types.
::                - Nothing else in the filename is touched.
::                - Batch string substitution is case-sensitive, so
::                  each common case variant is matched explicitly.
:: =========================================================================================================

echo =======================================================================================================
echo                       REMOVE "@HAMARACOLLEGE" WATERMARK SCRIPT
echo                       Developed by : Biraj
echo                       GitHub       : https://github.com/Biraj2004
echo =======================================================================================================
echo.
echo [INFO] Working Folder      : %CD%
echo [INFO] Target Files        : ALL files (any extension)
echo [INFO] Text Removed        : "@hamaracollege" / "@hmaracollege" (common case variants)
echo [INFO] Scope               : Current folder + ALL subfolders (Recursive)
echo [INFO] Safety              : Only the matched tag text is stripped out.
echo [INFO]                       The rest of each filename is left untouched.
echo.
echo =======================================================================================================
echo  WARNING: This will RENAME files inside:
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

for /r %%F in (*) do (
    set "filename=%%~nxF"
    set "newname=!filename!"

    rem --- try each common case variant of the watermark tag ---
    call set "newname=%%newname:@hamaracollege=%%"
    call set "newname=%%newname:@Hamaracollege=%%"
    call set "newname=%%newname:@HAMARACOLLEGE=%%"
    call set "newname=%%newname:@hmaracollege=%%"
    call set "newname=%%newname:@Hmaracollege=%%"
    call set "newname=%%newname:@HMARACOLLEGE=%%"

    if not "!filename!"=="!newname!" (
        ren "%%F" "!newname!" 2>nul
        if exist "%%~dpF!newname!" (
            echo [RENAMED]  !filename!
            echo            --^>   !newname!
            set /a renamed+=1
        ) else (
            echo [ERROR]    Could not rename !filename!
            set /a errors+=1
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
