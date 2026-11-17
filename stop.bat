:: stop.bat
@echo off
taskkill /fi "WINDOWTITLE eq Cactus Backend*" /t /f >nul 2>&1
taskkill /fi "WINDOWTITLE eq Cactus Frontend*" /t /f >nul 2>&1
echo Stopped.