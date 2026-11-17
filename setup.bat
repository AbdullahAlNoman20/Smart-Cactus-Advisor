:: setup.bat
@echo off
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1"
if errorlevel 1 (
  echo.
  echo SETUP FAILED. Read the error above.
) else (
  echo.
  echo SETUP DONE. Run start.bat
)
pause