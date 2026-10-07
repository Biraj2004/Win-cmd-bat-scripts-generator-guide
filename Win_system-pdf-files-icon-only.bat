@echo off
setlocal
set "GUID={E357FCCD-A995-4576-B01F-234630154E96}"
set "PROGID="

for /f "tokens=2,*" %%a in ('reg query "HKCR\.pdf" /ve 2^>nul ^| find "REG_SZ"') do set "PROGID=%%b"

echo Detected PDF app type: %PROGID%
echo.

reg add "HKCU\Software\Classes\.pdf\ShellEx\%GUID%" /ve /d "" /f >nul
if defined PROGID reg add "HKCU\Software\Classes\%PROGID%\ShellEx\%GUID%" /ve /d "" /f >nul

echo Thumbnails for PDF turned off. Restarting Explorer and clearing thumbnail cache...
taskkill /f /im explorer.exe >nul 2>&1
del /f /s /q "%LocalAppData%\Microsoft\Windows\Explorer\thumbcache_*.db" >nul 2>&1
start explorer.exe

echo.
echo Done. PDFs will now show the plain app icon.
pause
