@echo off
REM Flutter's flutter.bat prefers pwsh.exe over Windows PowerShell 5.1. A broken PowerShell 7 host
REM (CLR HRESULT 80004005) breaks update_engine_version.ps1 and yields "Unable to determine engine version".
REM This script removes common PowerShell 7 install dirs from PATH for this process only, then runs Flutter.
setlocal
set "PATH=%PATH:C:\Program Files\PowerShell\7;=%"
set "PATH=%PATH:;C:\Program Files\PowerShell\7=%"
set "PATH=%PATH:C:\Program Files\PowerShell\7-preview;=%"
set "PATH=%PATH:;C:\Program Files\PowerShell\7-preview=%"

where flutter >nul 2>&1
if errorlevel 1 (
  echo Flutter not on PATH. Add your SDK bin folder ^(e.g. C:\flutter\flutter\bin^) to PATH.
  exit /b 1
)
for /f "delims=" %%F in ('where flutter') do (
  call "%%F" %*
  exit /b %ERRORLEVEL%
)
exit /b 1
