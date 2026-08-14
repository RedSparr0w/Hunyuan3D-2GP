```bat
@echo off
cd /d "%~dp0"

echo.
echo ========================================
echo  Hunyuan3D-2GP
echo ========================================
echo.

if not exist ".venv\Scripts\python.exe" (
    echo ERROR: .venv was not found.
    echo.
    echo Run install-2gp.ps1 first.
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
```
