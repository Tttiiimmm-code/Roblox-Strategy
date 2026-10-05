# Prüft alle Luau-Skripte: Syntax (luau-compile) + Analyse auf undefinierte Variablen (luau-analyze).
# Aufruf aus dem Projektordner:  powershell -ExecutionPolicy Bypass -File scripts/check.ps1
# Exit-Code 0 = alles in Ordnung, 1 = Fehler gefunden.

# "Continue": luau-analyze schreibt auf stderr; in Windows PowerShell 5.1 wäre das sonst ein Abbruch
$ErrorActionPreference = "Continue"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$compile = Join-Path $root "tools/luau/luau-compile.exe"
$analyze = Join-Path $root "tools/luau/luau-analyze.exe"
if (-not (Test-Path $compile) -or -not (Test-Path $analyze)) {
    Write-Host "Luau-Werkzeuge fehlen in tools/luau (luau-windows.zip von github.com/luau-lang/luau/releases entpacken)."
    exit 1
}

$files = Get-ChildItem src -Recurse -Filter *.luau
$failed = 0

# 1) Syntax
foreach ($f in $files) {
    $out = & $compile --null $f.FullName 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "SYNTAXFEHLER $($f.FullName): $out"
        $failed++
    }
}

# 2) Undefinierte Variablen (Roblox-API-Globals sind dem Analyzer unbekannt und werden ignoriert)
$robloxGlobals = 'CFrame|Color3|ColorSequence|ColorSequenceKeypoint|Enum|game|Instance|NumberRange|NumberSequence|NumberSequenceKeypoint|PhysicalProperties|Random|RaycastParams|Ray|Rect|Region3|script|task|tick|TweenInfo|typeof|UDim|UDim2|Vector2|Vector3|warn|workspace'
$analysis = & $analyze ($files | ForEach-Object FullName) 2>&1 | ForEach-Object { "$_" }
$unknown = $analysis | Where-Object { $_ -match "Unknown global '([^']+)'" -and $Matches[1] -notmatch "^($robloxGlobals)$" }
foreach ($line in $unknown) {
    Write-Host "UNDEFINIERT $line"
    $failed++
}

if ($failed -gt 0) {
    Write-Host "Pruefung fehlgeschlagen: $failed Problem(e) in $($files.Count) Dateien."
    exit 1
}
Write-Host "OK: $($files.Count) Dateien geprueft (Syntax + undefinierte Variablen)."
exit 0
