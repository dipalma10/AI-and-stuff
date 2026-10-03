# ==============================================================
# LOCAL AI LAUNCHER - WINDOWS 11
#
# Created by Mikael Palmqvist, 2026-08-09
# Version 0.9
#
# ==============================================================

$ErrorActionPreference = "Continue"

$BaseDir  = "$env:USERPROFILE\LocalAI"
$WebUIDir = "$BaseDir\OpenWebUI"
$DataDir  = "$BaseDir\Data"

$WebUIExe = "$WebUIDir\Scripts\open-webui.exe"

Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "              LOCAL AI STARTING" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

# --------------------------------------------------------------
# Create directories
# --------------------------------------------------------------

New-Item -ItemType Directory -Force -Path $BaseDir | Out-Null
New-Item -ItemType Directory -Force -Path $DataDir | Out-Null

# --------------------------------------------------------------
# Open WebUI configuration
# --------------------------------------------------------------

$env:DATA_DIR = $DataDir
$env:WEBUI_SECRET_KEY_FILE = "$BaseDir\.webui_secret_key"

# --------------------------------------------------------------
# Ollama configuration
# --------------------------------------------------------------

$env:OLLAMA_HOST = "127.0.0.1:11434"

# --------------------------------------------------------------
# Offline configuration
# --------------------------------------------------------------

$env:OFFLINE_MODE = "true"
$env:HF_HUB_OFFLINE = "1"
$env:ENABLE_VERSION_UPDATE_CHECK = "false"
$env:RAG_EMBEDDING_MODEL_AUTO_UPDATE = "false"
$env:RAG_RERANKING_MODEL_AUTO_UPDATE = "false"
$env:WHISPER_MODEL_AUTO_UPDATE = "false"

# --------------------------------------------------------------
# Check Ollama
# --------------------------------------------------------------

Write-Host "Checking Ollama..." -ForegroundColor Yellow

$OllamaProcess = Get-Process ollama -ErrorAction SilentlyContinue

if (-not $OllamaProcess) {

    Write-Host "Ollama is not running. Starting it..." -ForegroundColor Yellow

    Start-Process "ollama" -ArgumentList "serve" -WindowStyle Hidden

    Start-Sleep -Seconds 5
}

try {

    Invoke-WebRequest `
        -Uri "http://127.0.0.1:11434/api/tags" `
        -UseBasicParsing `
        -TimeoutSec 10 | Out-Null

    Write-Host "Ollama: OK" -ForegroundColor Green

}
catch {

    Write-Host "Ollama: FAILED" -ForegroundColor Red
    Write-Host ""
    Write-Host "Try this command manually:"
    Write-Host "ollama list"
    Write-Host ""

    Read-Host "Press ENTER to exit"
    exit 1
}

# --------------------------------------------------------------
# Check Open WebUI
# --------------------------------------------------------------

if (-not (Test-Path $WebUIExe)) {

    Write-Host ""
    Write-Host "Open WebUI was not found." -ForegroundColor Red
    Write-Host ""
    Write-Host "Expected:"
    Write-Host $WebUIExe
    Write-Host ""

    Read-Host "Press ENTER to exit"
    exit 1
}

Write-Host "Open WebUI: OK" -ForegroundColor Green
Write-Host ""
Write-Host "Model:         qwen2.5:3b"
Write-Host "Web interface: http://127.0.0.1:8080"
Write-Host "Data folder:   $DataDir"
Write-Host ""

# --------------------------------------------------------------
# Start Open WebUI
# --------------------------------------------------------------

Write-Host "Starting Open WebUI..." -ForegroundColor Yellow
Write-Host ""

# Using Start-Process avoids PowerShell interpreting
# --host and --port as PowerShell operators.

$Arguments = @(
    "serve"
    "--host"
    "127.0.0.1"
    "--port"
    "8080"
)

Start-Process `
    -FilePath $WebUIExe `
    -ArgumentList $Arguments `
    -WorkingDirectory $BaseDir

# --------------------------------------------------------------
# Give Open WebUI time to start
# --------------------------------------------------------------

Write-Host "Waiting for Open WebUI..." -ForegroundColor Yellow

$Ready = $false

for ($i = 1; $i -le 30; $i++) {

    Start-Sleep -Seconds 2

    try {

        Invoke-WebRequest `
            -Uri "http://127.0.0.1:8080" `
            -UseBasicParsing `
            -TimeoutSec 2 | Out-Null

        $Ready = $true
        break

    }
    catch {
        Write-Host "." -NoNewline
    }
}

Write-Host ""

# --------------------------------------------------------------
# Open browser
# --------------------------------------------------------------

if ($Ready) {

    Write-Host ""
    Write-Host "==============================================" -ForegroundColor Green
    Write-Host "           LOCAL AI IS READY" -ForegroundColor Green
    Write-Host "==============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Open WebUI:"
    Write-Host "http://127.0.0.1:8080"
    Write-Host ""

    Start-Process "http://127.0.0.1:8080"

}
else {

    Write-Host ""
    Write-Host "Open WebUI did not respond within 60 seconds." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Try opening this manually:"
    Write-Host "http://127.0.0.1:8080"
    Write-Host ""
    Write-Host "The Open WebUI process may still be starting."
}

Write-Host ""
Write-Host "The Open WebUI process is running in the background."
Write-Host ""
Read-Host "Press ENTER to close this launcher"
```
