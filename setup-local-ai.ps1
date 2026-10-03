# --------------------------------------------------------------
# CREATE START SCRIPT
#
# Created by Mikael Palmqvist, 2026-08-09
# Version 0.9
# --------------------------------------------------------------
# ==============================================================
# Windows 11 LOCAL AI SETUP
# ==============================================================
#
# Hardware:
#   16 GB RAM
#   Intel HD 510
#
# Existing AI:
#   Ollama
#   qwen2.5:3b
#
# Installs:
#   Open WebUI
#
# Configures:
#   Localhost-only access
#   Offline mode
#   Local data directory
#   Desktop launcher
#   Automatic Ollama startup
#
# IMPORTANT:
#   Internet is required during installation.
#   After setup is complete, the AI can be used offline.
#
# ==============================================================

$ErrorActionPreference = "Stop"

# --------------------------------------------------------------
# VARIABLES
# --------------------------------------------------------------

$BaseDir   = "$env:USERPROFILE\LocalAI"
$WebUIDir  = "$BaseDir\OpenWebUI"
$DataDir   = "$BaseDir\Data"
$LogDir    = "$BaseDir\Logs"
$Model     = "qwen2.5:3b"

$PythonExe = "$WebUIDir\Scripts\python.exe"
$PipExe    = "$WebUIDir\Scripts\pip.exe"
$WebUIExe  = "$WebUIDir\Scripts\open-webui.exe"

# --------------------------------------------------------------
# ADMIN CHECK
# --------------------------------------------------------------

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)

if (-not $principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)) {
    Write-Host ""
    Write-Host "ERROR: Please run PowerShell as Administrator." -ForegroundColor Red
    Write-Host ""
    Read-Host "Press ENTER to exit"
    exit 1
}

# --------------------------------------------------------------
# HEADER
# --------------------------------------------------------------

Clear-Host

Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host "             WINDOWS 11 LOCAL AI SETUP" -ForegroundColor Cyan
Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Hardware : 16 GB RAM / Intel HD 510"
Write-Host "Model    : $Model"
Write-Host "Interface: Open WebUI"
Write-Host ""


# --------------------------------------------------------------
# Install download and install C++ VRedistributables
# --------------------------------------------------------------


$vcRedistUrls = @(
    "https://aka.ms/vs/17/release/vc_redist.x86.exe",
    "https://aka.ms/vs/17/release/vc_redist.x64.exe"
)

$downloadPath = "$env:TEMP\VC_Redistributables"

if (!(Test-Path -Path $downloadPath)) {
    New-Item -ItemType Directory -Path $downloadPath | Out-Null
}

function Install-VC_Redist {
    param (
        [string]$url
    )

    $fileName = $url -split '/' | Select-Object -Last 1
    $filePath = Join-Path -Path $downloadPath -ChildPath $fileName

    Write-Host "Downloading $fileName..."
    Invoke-WebRequest -Uri $url -OutFile $filePath

    Write-Host "Installing $fileName..."
    Start-Process -FilePath $filePath -ArgumentList "/quiet /norestart" -Wait

    Remove-Item -Path $filePath -Force
}

# Download and install both x86 and x64 versions
foreach ($url in $vcRedistUrls) {
    Install-VC_Redist -url $url
}

Write-Host "Visual Studio Redistributables installed successfully." -ForegroundColor Green

# --------------------------------------------------------------
# Install .NET Framework 3.5
# --------------------------------------------------------------

DISM /Online /Enable-Feature /FeatureName:NetFx3 /All /NoRestart

Write-Host "[0/10] .NET Framework with Dism..." -ForegroundColor Yellow

# --------------------------------------------------------------
# CREATE DIRECTORIES
# --------------------------------------------------------------

Write-Host "[1/10] Creating directories..." -ForegroundColor Yellow

New-Item -ItemType Directory -Force -Path $BaseDir  | Out-Null
New-Item -ItemType Directory -Force -Path $DataDir  | Out-Null
New-Item -ItemType Directory -Force -Path $LogDir   | Out-Null

Write-Host "       OK" -ForegroundColor Green

# --------------------------------------------------------------
# CHECK OLLAMA
# --------------------------------------------------------------

Write-Host "[2/10] Checking Ollama..." -ForegroundColor Yellow

$OllamaCommand = Get-Command ollama -ErrorAction SilentlyContinue

if (-not $OllamaCommand) {

    Write-Host ""
    Write-Host "Ollama was not found." -ForegroundColor Red
    Write-Host ""
    Write-Host "Install Ollama first, then run this script again."
    Write-Host ""
    Read-Host "Press ENTER to exit"
    exit 1
}

Write-Host "       Ollama found." -ForegroundColor Green

# --------------------------------------------------------------
# CHECK MODEL
# --------------------------------------------------------------

Write-Host "[3/10] Checking Qwen model..." -ForegroundColor Yellow

$modelList = & cmd.exe /c "ollama list" 2>$null

if (-not ($modelList -match "qwen2.5:3b")) {

    Write-Host ""
    Write-Host "Qwen2.5 3B was not found." -ForegroundColor Red
    Write-Host ""
    Write-Host "Run this command manually:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host 'cmd /c "ollama pull qwen2.5:3b"' -ForegroundColor White
    Write-Host ""
    Read-Host "Press ENTER to exit"
    exit 1
}

Write-Host "       qwen2.5:3b found." -ForegroundColor Green

# --------------------------------------------------------------
# OLLAMA LOCAL CONFIGURATION
# --------------------------------------------------------------

Write-Host "[4/10] Configuring Ollama..." -ForegroundColor Yellow

# Only allow local connections.
[Environment]::SetEnvironmentVariable(
    "OLLAMA_HOST",
    "127.0.0.1:11434",
    "User"
)

# Only one model at a time.
[Environment]::SetEnvironmentVariable(
    "OLLAMA_MAX_LOADED_MODELS",
    "1",
    "User"
)

# One request at a time - useful for 16 GB RAM.
[Environment]::SetEnvironmentVariable(
    "OLLAMA_NUM_PARALLEL",
    "1",
    "User"
)

# Unload model after inactivity.
[Environment]::SetEnvironmentVariable(
    "OLLAMA_KEEP_ALIVE",
    "5m",
    "User"
)

Write-Host "       Local-only configuration saved." -ForegroundColor Green

# --------------------------------------------------------------
# CHECK PYTHON
# --------------------------------------------------------------

Write-Host "[5/10] Checking Python..." -ForegroundColor Yellow

$PythonCommand = Get-Command py -ErrorAction SilentlyContinue

if (-not $PythonCommand) {

    $PythonCommand = Get-Command python -ErrorAction SilentlyContinue
}

if (-not $PythonCommand) {

    Write-Host ""
    Write-Host "Python was not found." -ForegroundColor Red
    Write-Host ""
    Write-Host "Installing Python 3.11 with winget..." -ForegroundColor Yellow

    winget install `
        --id Python.Python.3.11 `
        --exact `
        --accept-package-agreements `
        --accept-source-agreements

    # Refresh PATH
    $env:Path =
        [Environment]::GetEnvironmentVariable(
            "Path",
            "Machine"
        ) + ";" +
        [Environment]::GetEnvironmentVariable(
            "Path",
            "User"
        )
}

$PythonCommand = Get-Command py -ErrorAction SilentlyContinue

if (-not $PythonCommand) {
    $PythonCommand = Get-Command python -ErrorAction SilentlyContinue
}

if (-not $PythonCommand) {

    Write-Host ""
    Write-Host "Python installation could not be detected." -ForegroundColor Red
    Write-Host "Restart Windows and run this script again."
    Write-Host ""

    Read-Host "Press ENTER to exit"
    exit 1
}

Write-Host "       Python found." -ForegroundColor Green

# --------------------------------------------------------------
# CREATE VIRTUAL ENVIRONMENT
# --------------------------------------------------------------

Write-Host "[6/10] Creating Open WebUI environment..." -ForegroundColor Yellow

if (-not (Test-Path "$WebUIDir\Scripts\python.exe")) {

    try {
        & py -3.11 -m venv $WebUIDir
    }
    catch {

        & python -m venv $WebUIDir
    }
}

if (-not (Test-Path $PythonExe)) {

    Write-Host ""
    Write-Host "Could not create Python environment." -ForegroundColor Red
    Read-Host "Press ENTER to exit"
    exit 1
}

Write-Host "       Virtual environment ready." -ForegroundColor Green

# --------------------------------------------------------------
# INSTALL / UPDATE OPEN WEBUI
# --------------------------------------------------------------

Write-Host "[7/10] Installing Open WebUI..." -ForegroundColor Yellow

& $PythonExe -m pip install --upgrade pip

if (-not (Test-Path $WebUIExe)) {

    & $PipExe install open-webui
}

if (-not (Test-Path $WebUIExe)) {

    Write-Host ""
    Write-Host "Open WebUI installation failed." -ForegroundColor Red
    Read-Host "Press ENTER to exit"
    exit 1
}

Write-Host "       Open WebUI installed." -ForegroundColor Green

# --------------------------------------------------------------
# CREATE START SCRIPT
# --------------------------------------------------------------

Write-Host "[8/10] Creating Local AI launcher..." -ForegroundColor Yellow

$StartScript = "$BaseDir\Start-LocalAI.ps1"

@"
# ==============================================================
# LOCAL AI LAUNCHER
# ==============================================================

`$ErrorActionPreference = "Stop"

# --------------------------------------------------------------
# Ollama
# --------------------------------------------------------------

`$env:OLLAMA_HOST = "127.0.0.1:11434"

# --------------------------------------------------------------
# Open WebUI offline mode
# --------------------------------------------------------------

`$env:OFFLINE_MODE = "true"
`$env:HF_HUB_OFFLINE = "1"

# Disable automatic online checks
`$env:ENABLE_VERSION_UPDATE_CHECK = "false"

`$env:RAG_EMBEDDING_MODEL_AUTO_UPDATE = "false"
`$env:RAG_RERANKING_MODEL_AUTO_UPDATE = "false"
`$env:WHISPER_MODEL_AUTO_UPDATE = "false"

# --------------------------------------------------------------
# Local data
# --------------------------------------------------------------

`$env:DATA_DIR = "$DataDir"

New-Item `
    -ItemType Directory `
    -Force `
    -Path "$DataDir" | Out-Null

# --------------------------------------------------------------
# Check Ollama
# --------------------------------------------------------------

`$ollama = Get-Process ollama -ErrorAction SilentlyContinue

if (-not `$ollama) {

    Write-Host "Starting Ollama..." -ForegroundColor Yellow

    Start-Process `
        "ollama" `
        -ArgumentList "serve" `
        -WindowStyle Hidden

    Start-Sleep -Seconds 5
}

# --------------------------------------------------------------
# Start Open WebUI
# --------------------------------------------------------------

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "               LOCAL AI IS STARTING" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Open WebUI:"
Write-Host "http://127.0.0.1:8080"
Write-Host ""
Write-Host "Model:"
Write-Host "qwen2.5:3b"
Write-Host ""
Write-Host "Internet is NOT required after setup."
Write-Host ""
Write-Host "Close this window to stop Open WebUI."
Write-Host ""

Start-Process `
    "http://127.0.0.1:8080"

& "$WebUIExe" serve `
    --host 127.0.0.1 `
    --port 8080
"@ | Set-Content -Encoding UTF8 $StartScript

Write-Host "       Launcher created." -ForegroundColor Green

# --------------------------------------------------------------
# CREATE DESKTOP SHORTCUT
# --------------------------------------------------------------

Write-Host "[9/10] Creating desktop shortcut..." -ForegroundColor Yellow

$DesktopPath = [Environment]::GetFolderPath("Desktop")
$ShortcutPath = "$DesktopPath\Local AI.lnk"

$Shell = New-Object -ComObject WScript.Shell

$Shortcut = $Shell.CreateShortcut($ShortcutPath)

$Shortcut.TargetPath = "powershell.exe"

$Shortcut.Arguments =
    "-NoProfile -ExecutionPolicy Bypass -File `"$StartScript`""

$Shortcut.WorkingDirectory = $BaseDir
$Shortcut.Description = "Start Local AI"

$Shortcut.Save()

Write-Host "       Desktop shortcut created." -ForegroundColor Green

# --------------------------------------------------------------
# CREATE TEST SCRIPT
# --------------------------------------------------------------

Write-Host "[10/10] Creating AI test utility..." -ForegroundColor Yellow

$TestScript = "$BaseDir\Test-LocalAI.ps1"

@"
Write-Host ""
Write-Host "Testing local Ollama..." -ForegroundColor Cyan
Write-Host ""

cmd /c "ollama run qwen2.5:3b `"Reply with exactly: LOCAL AI WORKS`""

Write-Host ""
Write-Host "Test complete." -ForegroundColor Green
Write-Host ""
Read-Host "Press ENTER to exit"
"@ | Set-Content -Encoding UTF8 $TestScript

Write-Host "       Test utility created." -ForegroundColor Green

# --------------------------------------------------------------
# FINISHED
# --------------------------------------------------------------

Write-Host ""
Write-Host "==============================================================" -ForegroundColor Green
Write-Host "                 INSTALLATION COMPLETE" -ForegroundColor Green
Write-Host "==============================================================" -ForegroundColor Green
Write-Host ""

Write-Host "Local AI directory:"
Write-Host "  $BaseDir"
Write-Host ""

Write-Host "Model:"
Write-Host "  qwen2.5:3b"
Write-Host ""

Write-Host "Open WebUI:"
Write-Host "  http://127.0.0.1:8080"
Write-Host ""

Write-Host "Desktop shortcut:"
Write-Host "  Local AI"
Write-Host ""

Write-Host "Test command:"
Write-Host "  $TestScript"
Write-Host ""

Write-Host "==============================================================" -ForegroundColor Yellow
Write-Host "IMPORTANT" -ForegroundColor Yellow
Write-Host "==============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Internet was required for installation."
Write-Host ""
Write-Host "DO NOT disconnect from the Internet yet."
Write-Host ""
Write-Host "We still need to prepare the local document/PDF"
Write-Host "components before using the system completely offline."
Write-Host ""

Read-Host "Press ENTER to finish"
```
