```powershell
$ErrorActionPreference = "Stop"

# ============================================================
# Hunyuan3D-2GP local installer
#
# Run this script from the ROOT of the Hunyuan3D-2GP repo.
#
# Expected:
#   .\install-2gp.ps1
#
# Creates:
#   .\.venv\
#
# Uses:
#   Python 3.11
#   PyTorch 2.5.1 + CUDA 12.4
# ============================================================

$Root = $PSScriptRoot

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Hunyuan3D-2GP Installer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Install directory:"
Write-Host "  $Root"
Write-Host ""

Set-Location $Root

# ------------------------------------------------------------
# Find Python 3.11
# ------------------------------------------------------------

$PythonLauncher = $null

if (Get-Command py -ErrorAction SilentlyContinue) {
    try {
        $versions = & py -0p 2>$null

        foreach ($line in $versions) {
            if ($line -match "3\.11") {
                $PythonLauncher = "py"
                break
            }
        }
    }
    catch {}
}

if (-not $PythonLauncher -and (Get-Command python -ErrorAction SilentlyContinue)) {
    try {
        $pythonVersion = & python --version 2>&1

        if ($pythonVersion -match "Python 3\.11") {
            $PythonLauncher = "python"
        }
    }
    catch {}
}

if (-not $PythonLauncher) {
    Write-Host ""
    Write-Host "ERROR: Python 3.11 was not found." -ForegroundColor Red
    Write-Host ""
    Write-Host "Install Python 3.11.x and run this installer again."
    exit 1
}

Write-Host "Python launcher found: $PythonLauncher" -ForegroundColor Green

# ------------------------------------------------------------
# Create virtual environment
# ------------------------------------------------------------

$VenvPython = Join-Path $Root ".venv\Scripts\python.exe"

if (-not (Test-Path $VenvPython)) {

    Write-Host ""
    Write-Host "Creating Python 3.11 virtual environment..." -ForegroundColor Cyan

    if ($PythonLauncher -eq "py") {
        & py -3.11 -m venv ".venv"
    }
    else {
        & python -m venv ".venv"
    }

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create virtual environment."
    }
}
else {
    Write-Host ""
    Write-Host "Existing .venv detected - keeping it." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Python version:" -ForegroundColor Cyan
& $VenvPython --version

# ------------------------------------------------------------
# Upgrade packaging tools
# ------------------------------------------------------------

Write-Host ""
Write-Host "Updating pip/setuptools/wheel..." -ForegroundColor Cyan

& $VenvPython -m pip install --upgrade pip setuptools wheel

# ------------------------------------------------------------
# Install PyTorch CUDA 12.4
# ------------------------------------------------------------

Write-Host ""
Write-Host "Installing PyTorch 2.5.1 + CUDA 12.4..." -ForegroundColor Cyan

& $VenvPython -m pip install `
    torch==2.5.1+cu124 `
    torchvision==0.20.1+cu124 `
    torchaudio==2.5.1+cu124 `
    --index-url https://download.pytorch.org/whl/cu124

if ($LASTEXITCODE -ne 0) {
    throw "PyTorch installation failed."
}

# ------------------------------------------------------------
# Install normal dependencies
# ------------------------------------------------------------

$WorkingRequirements = Join-Path $Root "requirements-working.txt"
$NormalRequirements  = Join-Path $Root "requirements.txt"

Write-Host ""

if (Test-Path $WorkingRequirements) {

    Write-Host "Installing tested dependency snapshot..." -ForegroundColor Cyan

    & $VenvPython -m pip install -r $WorkingRequirements

}
elseif (Test-Path $NormalRequirements) {

    Write-Host "requirements-working.txt not found." -ForegroundColor Yellow
    Write-Host "Using requirements.txt instead..." -ForegroundColor Yellow

    & $VenvPython -m pip install -r $NormalRequirements

}
else {

    throw "No requirements.txt or requirements-working.txt found."
}

if ($LASTEXITCODE -ne 0) {
    throw "Dependency installation failed."
}

# ------------------------------------------------------------
# Locate native components
# ------------------------------------------------------------

Write-Host ""
Write-Host "Searching for native 2GP components..." -ForegroundColor Cyan

# Search the repository for setup.py files associated with the
# native packages rather than assuming a particular directory.

$SetupFiles = Get-ChildItem $Root -Recurse -File -Filter "setup.py" |
    Where-Object {
        $_.FullName -notmatch "\\.venv\\" -and
        $_.FullName -notmatch "\\gradio_cache\\"
    }

foreach ($setup in $SetupFiles) {

    $setupText = Get-Content $setup.FullName -Raw -ErrorAction SilentlyContinue

    if ($setupText -match "custom_rasterizer") {

        Write-Host ""
        Write-Host "Found custom rasterizer:" -ForegroundColor Green
        Write-Host "  $($setup.Directory.FullName)"

        Push-Location $setup.Directory.FullName

        & $VenvPython -m pip install .

        if ($LASTEXITCODE -ne 0) {
            Pop-Location
            throw "custom_rasterizer build/install failed."
        }

        Pop-Location
    }

    if ($setupText -match "mesh.?processor") {

        Write-Host ""
        Write-Host "Found mesh processor:" -ForegroundColor Green
        Write-Host "  $($setup.Directory.FullName)"

        Push-Location $setup.Directory.FullName

        & $VenvPython -m pip install .

        if ($LASTEXITCODE -ne 0) {
            Pop-Location
            throw "mesh_processor build/install failed."
        }

        Pop-Location
    }
}

# ------------------------------------------------------------
# Verification
# ------------------------------------------------------------

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Verifying installation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

& $VenvPython -c @"
import sys
import torch

print("Python:", sys.version)
print("Torch:", torch.__version__)
print("CUDA:", torch.version.cuda)

if not torch.cuda.is_available():
    raise RuntimeError("CUDA is not available.")

print("GPU:", torch.cuda.get_device_name(0))

import mmgp
print("MMGP: OK")

import mesh_processor
print("mesh_processor: OK")
"@

if ($LASTEXITCODE -ne 0) {

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host " Verification reported an error" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "The environment was created, but one of the native"
    Write-Host "components may need attention."
    Write-Host ""

}
else {

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host " Installation verified successfully!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""

}

Write-Host "You can now run:"
Write-Host ""
Write-Host "  .\start-2gp.bat" -ForegroundColor Cyan
Write-Host ""
```
