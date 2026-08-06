@echo off
setlocal enabledelayedexpansion

echo ==============================================
echo   Strip trailing ".webm" from "*.mp4.webm" filenames
echo   (recursively, in this folder + all subfolders)
echo ==============================================
echo.

set "count=0"

for /r %%F in (*.mp4.webm) do (
    set "fname=%%~nxF"

    rem --- detect: filename must end with ".mp4.webm" ---
    set "newname=!fname:.mp4.webm=.mp4!"

    if not "!newname!"=="!fname!" (
        rem --- strip: rename to drop the trailing ".webm" ---
        ren "%%F" "!newname!"
        echo Renamed: !fname!
        echo    -^>   !newname!
        echo.
        set /a count+=1
    )
)

echo ==============================================
echo Done. !count! file(s) renamed.
echo ==============================================
pause
