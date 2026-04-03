@echo off
REM Strips PowerShell 7 from PATH before starting Gradle so flutter.bat uses Windows PowerShell 5.1
REM (fixes CLR 80004005 / "Unable to determine engine version" during compileFlutterBuildDebug).
REM Use: gradlew_flutter.cmd assembleDebug   (from android folder)
REM After first use, run: gradlew.bat --stop   if the daemon was started with the old PATH.
setlocal
set "PATH=%PATH:C:\Program Files\PowerShell\7;=%"
set "PATH=%PATH:;C:\Program Files\PowerShell\7=%"
set "PATH=%PATH:C:\Program Files\PowerShell\7-preview;=%"
set "PATH=%PATH:;C:\Program Files\PowerShell\7-preview=%"
cd /d "%~dp0"
call gradlew.bat %*
endlocal
