# Erstellt eine Mal-Datei oder exportiert die auf der Festplatte gespeicherte Textur.
# Setup: powershell -ExecutionPolicy Bypass -File scripts/paint.ps1 -Name leon -Mode Setup
# Export: powershell -ExecutionPolicy Bypass -File scripts/paint.ps1 -Name leon -Mode Export
# Exit-Code 0 = erfolgreich, 1 = ungültiger Aufruf; Blender-Fehler werden durchgereicht.
param(
	[string]$Name,
	[string]$Dir,
	[string]$Mode,
	[switch]$Force,
	[string]$Blender
)

$ErrorActionPreference = 'Stop'
try {
	if (-not $Name -or -not $Name.Trim() -or $Name -match '[<>:"/\\|?*]' -or $Name -in '.', '..' -or $Name.EndsWith('.')) {
		throw 'Bitte -Name mit einer Figuren-ID ohne Pfad angeben (zum Beispiel -Name leon).'
	}
	if ($Mode -notin 'Setup', 'Export') {
		throw 'Bitte -Mode Setup oder -Mode Export angeben.'
	}
	if ($Force -and $Mode -eq 'Export') { throw '-Force ist nur für -Mode Setup vorgesehen.' }
	if (-not $Dir) { $Dir = Join-Path (Join-Path $PSScriptRoot '../assets/raw') $Name }
	$directory = [IO.Path]::GetFullPath($Dir)
	$clean = Join-Path $directory 'clean'
	$required = @((Join-Path $clean "${Name}_clean.glb"), (Join-Path $clean "${Name}_tex.png"))
	if ($Mode -eq 'Setup') {
		$required += @((Join-Path $directory 'ref_vorne.png'), (Join-Path $directory 'ref_hinten.png'))
	} else {
		$required += (Join-Path $clean "${Name}_tex_bemalt.png")
	}
	foreach ($path in $required) {
		if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Eingabedatei fehlt: $path" }
	}
	if ($Mode -eq 'Setup' -and -not $Force -and (Test-Path -LiteralPath (Join-Path $clean "${Name}_malen.blend"))) {
		throw "Mal-Datei existiert bereits. Zum Malen öffnen; nur zum bewussten Neuerstellen -Force verwenden."
	}
	if (-not $Blender) {
		$candidates = Get-ChildItem 'C:/Program Files/Blender Foundation' -Directory |
			Where-Object { $_.Name -match '^Blender \d+(\.\d+)*$' } |
			Sort-Object { [version]($_.Name -replace '^Blender ', '') } -Descending
		foreach ($candidate in $candidates) {
			$executable = Join-Path $candidate.FullName 'blender.exe'
			if (Test-Path -LiteralPath $executable -PathType Leaf) { $Blender = $executable; break }
		}
	}
	if (-not $Blender -or -not (Test-Path -LiteralPath $Blender -PathType Leaf)) {
		throw 'Blender nicht gefunden. Installationspfad mit -Blender angeben.'
	}
	$scriptName = if ($Mode -eq 'Setup') { 'paint_setup.py' } else { 'paint_export.py' }
	$scriptPath = Join-Path $PSScriptRoot "cleanup/$scriptName"
	if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) { throw "Blender-Skript fehlt: $scriptPath" }
	$blenderArgs = @('-b', '--factory-startup', '--python-exit-code', '1', '--python', $scriptPath,
		'--', '--dir', $directory, '--name', $Name)
	if ($Force) { $blenderArgs += '--force' }
	& $Blender @blenderArgs
	exit $LASTEXITCODE
} catch {
	Write-Host "Textur-Malen fehlgeschlagen: $($_.Exception.Message)"
	exit 1
}
