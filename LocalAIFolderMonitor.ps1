# ==============================
# LocalAI Folder Monitor
#
# Creatd by Mikael Palmqvist, 2026-09-09
#
# Version 0.9
#
# ==============================

$BaseDir  = "$env:USERPROFILE\LocalAI"
$LogFile  = "$env:TEMP\LocalAI-FolderMonitor.html"
$Interval = 15

# Create log directory if needed
$LogDirectory = Split-Path $LogFile -Parent

if (-not (Test-Path $LogDirectory)) {
    New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
}

function HtmlEncode($Text) {
    return [System.Net.WebUtility]::HtmlEncode([string]$Text)
}

# Initial snapshot
$Previous = Get-ChildItem -Path $BaseDir -Recurse -Force -ErrorAction SilentlyContinue |
    Select-Object FullName, Length, LastWriteTime, Attributes

# Create initial HTML
@"
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta http-equiv="refresh" content="$Interval">

<title>LocalAI Folder Monitor</title>

<style>
body {
    font-family: Consolas, monospace;
    background: #111827;
    color: #e5e7eb;
    margin: 0;
    padding: 20px;
}

h1 {
    color: #60a5fa;
    margin-bottom: 5px;
}

.info {
    color: #9ca3af;
    margin-bottom: 20px;
    line-height: 1.6;
}

.log {
    background: #1f2937;
    border-radius: 8px;
    padding: 15px;
}

.entry {
    padding: 7px 10px;
    border-bottom: 1px solid #374151;
    white-space: pre-wrap;
}

.added {
    color: #4ade80;
}

.removed {
    color: #f87171;
}

.modified {
    color: #facc15;
}

.nochange {
    color: #9ca3af;
}
</style>
</head>

<body>

<h1>📁 LocalAI Folder Monitor</h1>

<div class="info">
    Monitoring:
    <strong>$(HtmlEncode $BaseDir)</strong>
    <br>

    Check interval:
    <strong>$Interval seconds</strong>
    <br>

    Started:
    <strong>$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</strong>
</div>

<div class="log">
<div class="entry nochange">
[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] Monitor started.
</div>
</div>

</body>
</html>
"@ | Set-Content -Path $LogFile -Encoding UTF8

# Open HTML log in Microsoft Edge
try {
    Start-Process "msedge.exe" -ArgumentList "`"$LogFile`""
}
catch {
    Start-Process $LogFile
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " LocalAI Folder Monitor" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Monitoring: $BaseDir" -ForegroundColor White
Write-Host "HTML Log:   $LogFile" -ForegroundColor White
Write-Host "Interval:   $Interval seconds" -ForegroundColor White
Write-Host ""
Write-Host "Press Ctrl+C to stop." -ForegroundColor Yellow
Write-Host ""

while ($true) {

    Start-Sleep -Seconds $Interval

    # Get current snapshot
    $Current = Get-ChildItem `
        -Path $BaseDir `
        -Recurse `
        -Force `
        -ErrorAction SilentlyContinue |
        Select-Object FullName, Length, LastWriteTime, Attributes

    # ------------------------------
    # Added
    # ------------------------------

    $Added = Compare-Object `
        -ReferenceObject $Previous `
        -DifferenceObject $Current `
        -Property FullName `
        -PassThru |
        Where-Object SideIndicator -eq "=>"

    # ------------------------------
    # Removed
    # ------------------------------

    $Removed = Compare-Object `
        -ReferenceObject $Previous `
        -DifferenceObject $Current `
        -Property FullName `
        -PassThru |
        Where-Object SideIndicator -eq "<="

    # ------------------------------
    # Modified
    # ------------------------------

    $Modified = foreach ($Item in $Current) {

        $OldItem = $Previous |
            Where-Object FullName -eq $Item.FullName |
            Select-Object -First 1

        if ($OldItem) {

            if (
                $OldItem.Length -ne $Item.Length -or
                $OldItem.LastWriteTime -ne $Item.LastWriteTime -or
                $OldItem.Attributes -ne $Item.Attributes
            ) {
                $Item
            }
        }
    }

    $Time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # Read existing HTML
    $Existing = Get-Content $LogFile -Raw

    # Extract existing log entries
    $LogEntries = ""

    if ($Existing -match '<div class="log">(.*?)</div>') {
        $LogEntries = $Matches[1]
    }

    $ChangesFound = $false

    # ------------------------------
    # Log Added
    # ------------------------------

    foreach ($Item in $Added) {

        $ChangesFound = $true
        $Path = HtmlEncode $Item.FullName

        $Message = "[$Time] ADDED:    $Path"

        Write-Host $Message -ForegroundColor Green

        $LogEntries = @"
<div class="entry added">$Message</div>
$LogEntries
"@
    }

    # ------------------------------
    # Log Removed
    # ------------------------------

    foreach ($Item in $Removed) {

        $ChangesFound = $true
        $Path = HtmlEncode $Item.FullName

        $Message = "[$Time] REMOVED:  $Path"

        Write-Host $Message -ForegroundColor Red

        $LogEntries = @"
<div class="entry removed">$Message</div>
$LogEntries
"@
    }

    # ------------------------------
    # Log Modified
    # ------------------------------

    foreach ($Item in $Modified) {

        $ChangesFound = $true
        $Path = HtmlEncode $Item.FullName

        $Message = "[$Time] MODIFIED: $Path"

        Write-Host $Message -ForegroundColor Yellow

        $LogEntries = @"
<div class="entry modified">$Message</div>
$LogEntries
"@
    }

    # ------------------------------
    # No changes
    # ------------------------------

    if (-not $ChangesFound) {

        $Message = "[$Time] No changes detected."

        Write-Host $Message -ForegroundColor DarkGray

        $LogEntries = @"
<div class="entry nochange">$Message</div>
$LogEntries
"@
    }

    # ------------------------------
    # Rebuild HTML
    # ------------------------------

    @"
<!DOCTYPE html>
<html>

<head>

<meta charset="UTF-8">

<meta http-equiv="refresh" content="$Interval">

<title>LocalAI Folder Monitor</title>

<style>

body {
    font-family: Consolas, monospace;
    background: #111827;
    color: #e5e7eb;
    margin: 0;
    padding: 20px;
}

h1 {
    color: #60a5fa;
    margin-bottom: 5px;
}

.info {
    color: #9ca3af;
    margin-bottom: 20px;
    line-height: 1.6;
}

.log {
    background: #1f2937;
    border-radius: 8px;
    padding: 15px;
}

.entry {
    padding: 7px 10px;
    border-bottom: 1px solid #374151;
    white-space: pre-wrap;
}

.added {
    color: #4ade80;
}

.removed {
    color: #f87171;
}

.modified {
    color: #facc15;
}

.nochange {
    color: #9ca3af;
}

</style>

</head>

<body>

<h1>📁 LocalAI Folder Monitor</h1>

<div class="info">

Monitoring:
<strong>$(HtmlEncode $BaseDir)</strong>

<br>

Check interval:
<strong>$Interval seconds</strong>

<br>

Last check:
<strong>$Time</strong>

</div>

<div class="log">

$LogEntries

</div>

</body>

</html>
"@ | Set-Content -Path $LogFile -Encoding UTF8

    # Update snapshot
    $Previous = $Current
}
```
