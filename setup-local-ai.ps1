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
