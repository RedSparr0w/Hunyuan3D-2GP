@echo off

cd /d "%~dp0"

echo.
echo ========================================
echo  Hunyuan3D-2GP
echo ========================================
echo.

if not exist ".venv\Scripts\python.exe" (
    echo ERROR: Hunyuan3D-2GP is not installed.
    echo.
    echo Run install-2gp.bat first.
    echo.
    pause
    exit /b 1
)

".venv\Scripts\python.exe" gradio_app.py

echo.
echo ========================================
echo  Hunyuan3D-2GP stopped
echo ========================================
echo.

pause
