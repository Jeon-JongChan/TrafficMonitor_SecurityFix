@echo off
REM TrafficMonitor Fast Portable Dev Build Launcher
REM Usage: build-dev.cmd [Configuration (default: Release)] [Platform (default: x64)]

"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%~dp0build-dev.ps1" -Configuration "%~1" -Platform "%~2"
set EXIT_CODE=%ERRORLEVEL%

if %EXIT_CODE% neq 0 (
    echo.
    echo [Build Failed with code %EXIT_CODE%]
    echo %cmdcmdline% | find /i "%~f0" >nul && pause
    exit /b %EXIT_CODE%
)

echo %cmdcmdline% | find /i "%~f0" >nul && pause
exit /b 0

