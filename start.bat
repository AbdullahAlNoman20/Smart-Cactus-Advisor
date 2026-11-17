:: start.bat
@echo off
cd /d "%~dp0"
set "PY=%~dp0.portable\venv\Scripts\python.exe"
if not exist "%PY%" (
  echo Run setup.bat first.
  pause
  exit /b 1
)
if not exist "%~dp0frontend\build\index.html" (
  echo Frontend build missing. Run setup.bat again.
  pause
  exit /b 1
)

set "PYTHONPATH="
set "PYTHONHOME="
set "PYTHONNOUSERSITE=1"
set "TF_CPP_MIN_LOG_LEVEL=2"

start "Cactus Backend" /d "%~dp0backend" "%PY%" -m waitress --listen=127.0.0.1:5055 --threads=4 app:app
start "Cactus Frontend" "%PY%" -m http.server 3055 --bind 127.0.0.1 --directory "%~dp0frontend\build"

timeout /t 6 >nul
start "" http://localhost:3055