@echo off
setlocal EnableExtensions EnableDelayedExpansion

cd /d "%~dp0"

echo.
echo ========================================
echo  Hunyuan3D-2GP Installer
echo ========================================
echo.

set "ROOT=%~dp0"
set "VENV=%ROOT%.venv"
set "PYTHON=%VENV%\Scripts\python.exe"

echo Install directory:
echo %ROOT%
echo.

REM ============================================================
REM Find Python 3.11
REM ============================================================

where py >nul 2>&1

if %errorlevel%==0 (
    echo Checking for Python 3.11...
    py -3.11 --version >nul 2>&1

    if !errorlevel!==0 (
        set "SYSTEM_PYTHON=py -3.11"
        goto :python_found
    )
)

where python >nul 2>&1

if %errorlevel%==0 (
    python --version 2>&1 | findstr /C:"Python 3.11" >nul

    if !errorlevel!==0 (
        set "SYSTEM_PYTHON=python"
        goto :python_found
    )
)

echo.
echo ERROR: Python 3.11 was not found.
echo.
echo Please install Python 3.11.x and run this again.
echo.
pause
exit /b 1

:python_found

echo Python 3.11 found.
echo.

REM ============================================================
REM Create virtual environment
REM ============================================================

if not exist "%PYTHON%" (
    echo Creating Python virtual environment...
    echo.

    %SYSTEM_PYTHON% -m venv "%VENV%"

    if errorlevel 1 (
        echo.
        echo ERROR: Failed to create virtual environment.
        pause
        exit /b 1
    )
) else (
    echo Existing .venv found - keeping it.
)

echo.
echo Python version:
"%PYTHON%" --version

REM ============================================================
REM Upgrade pip
REM ============================================================

echo.
echo Updating pip, setuptools and wheel...
echo.

"%PYTHON%" -m pip install --upgrade pip setuptools wheel

if errorlevel 1 (
    echo.
    echo ERROR: Failed to update pip.
    pause
    exit /b 1
)

REM ============================================================
REM Install PyTorch CUDA 12.4
REM ============================================================

echo.
echo ========================================
echo Installing PyTorch 2.5.1 + CUDA 12.4
echo ========================================
echo.

"%PYTHON%" -m pip install ^
    torch==2.5.1+cu124 ^
    torchvision==0.20.1+cu124 ^
    torchaudio==2.5.1+cu124 ^
    --index-url https://download.pytorch.org/whl/cu124

if errorlevel 1 (
    echo.
    echo ERROR: PyTorch installation failed.
    pause
    exit /b 1
)

REM ============================================================
REM Install dependencies
REM ============================================================

echo.
echo ========================================
echo Installing dependencies
echo ========================================
echo.

REM diso requires PyTorch during its build.
REM Install it separately without build isolation.

echo Installing diso...
"%PYTHON%" -m pip install diso==0.1.4 --no-build-isolation

if errorlevel 1 (
    echo.
    echo ERROR: diso installation failed.
    pause
    exit /b 1
)

if exist "%ROOT%requirements-working.txt" (
    echo.
    echo Installing remaining dependencies...
    echo.

    "%PYTHON%" -m pip install -r "%ROOT%requirements-working.txt" --no-deps

) else if exist "%ROOT%requirements.txt" (
    echo.
    echo Installing requirements.txt...
    echo.

    "%PYTHON%" -m pip install -r "%ROOT%requirements.txt"
) else (
    echo.
    echo ERROR: No requirements file found.
    pause
    exit /b 1
)

if errorlevel 1 (
    echo.
    echo ERROR: Dependency installation failed.
    pause
    exit /b 1
)


REM ============================================================
REM Install Hunyuan3D package
REM ============================================================

echo.
echo ========================================
echo Installing Hunyuan3D package
echo ========================================
echo.

if exist "%ROOT%setup.py" (
    "%PYTHON%" -m pip install "%ROOT%"
    
    if errorlevel 1 (
        echo.
        echo ERROR: Hunyuan3D package installation failed.
        pause
        exit /b 1
    )
)

REM ============================================================
REM Check native packages
REM ============================================================

echo.
echo ========================================
echo Checking native components
echo ========================================
echo.

"%PYTHON%" -c "import mesh_processor; print('mesh_processor: OK')"

if errorlevel 1 (
    echo.
    echo WARNING: mesh_processor could not be imported.
    echo We may need to build its native component separately.
    echo.
)

"%PYTHON%" -c "import mmgp; print('MMGP: OK')"

if errorlevel 1 (
    echo.
    echo WARNING: MMGP could not be imported.
    echo.
)

REM ============================================================
REM CUDA verification
REM ============================================================

echo.
echo ========================================
echo Verifying CUDA
echo ========================================
echo.

"%PYTHON%" -c "import torch; print('Torch:', torch.__version__); print('CUDA:', torch.version.cuda); print('CUDA available:', torch.cuda.is_available()); print('GPU:', torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'NONE')"

if errorlevel 1 (
    echo.
    echo WARNING: CUDA verification failed.
    echo.
)

REM ============================================================
REM Finished
REM ============================================================

echo.
echo ========================================
echo Installation finished
echo ========================================
echo.
echo The virtual environment is:
echo %VENV%
echo.
echo Start Hunyuan3D-2GP with:
echo.
echo     start-2gp.bat
echo.

pause
