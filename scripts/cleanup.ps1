# Bereitet ein KI-Figurenmodell oder Umgebungsobjekt mit Blender für den Roblox-Import auf.
# Aufruf: powershell -ExecutionPolicy Bypass -File scripts/cleanup.ps1 -In assets/raw/leon/leon_meshy.fbx -Name leon
# Exit-Code 0 = erfolgreich, 1 = ungültiger Aufruf; Blender-Fehler werden durchgereicht.
param(
	[Parameter(Mandatory = $true)][string]$In,
	[string]$Out,
	[string]$Name,
	[ValidateSet('+X', '-X', '+Y', '-Y')][string]$Front = '+X',
	[ValidateRange(16, 1024)][int]$Size = 1024,
	[ValidateRange(0.0, 1.0)][double]$HeadShare = 0.25,
	[ValidateRange(1, 20000)][int]$MaxTris = 19000,
	[switch]$Prop,
	[switch]$Cel,
	[ValidateRange(2, 256)][int]$CelColors = 16,
	[ValidateRange(0, 64)][int]$Threads = 0,
	[string]$Blender
)

if ($Prop) {
	if (-not $PSBoundParameters.ContainsKey('Size')) { $Size = 512 }
	if (-not $PSBoundParameters.ContainsKey('MaxTris')) { $MaxTris = 3000 }
}

$ErrorActionPreference = 'Stop'
try {
	if (-not (Test-Path -LiteralPath $In -PathType Leaf)) {
		throw "Eingabedatei fehlt: $In"
	}
	$inputPath = (Resolve-Path -LiteralPath $In).Path
	if ([IO.Path]::GetExtension($inputPath).ToLowerInvariant() -notin '.fbx', '.glb') {
		throw 'Eingabe muss eine FBX- oder GLB-Datei sein.'
	}
	if (-not $Out) { $Out = Join-Path (Split-Path -Parent $inputPath) 'clean' }
	$outputPath = [IO.Path]::GetFullPath($Out)
	if (-not $Name) { $Name = [IO.Path]::GetFileNameWithoutExtension($inputPath) }
	if ($Name -match '[<>:"/\\|?*]' -or $Name -in '.', '..' -or $Name.EndsWith('.')) {
		throw 'Name muss ein einfacher Dateiname ohne Pfad sein.'
	}
	if (-not $Prop -and ($HeadShare -le 0 -or $HeadShare -ge 1)) {
		throw 'HeadShare muss größer als 0 und kleiner als 1 sein.'
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
	$scriptPath = Join-Path $PSScriptRoot 'cleanup/cleanup_model.py'
	$blenderArgs = @('-b', '--factory-startup', '--python-exit-code', '1', '--python', $scriptPath,
		'--', '--input', $inputPath, '--output', $outputPath, '--name', $Name,
		"--front=$Front", '--size', "$Size", '--head-share', $HeadShare.ToString([Globalization.CultureInfo]::InvariantCulture),
		'--max-tris', "$MaxTris", '--cel-colors', "$CelColors")
	if ($Threads -gt 0) { $blenderArgs = @('-t', "$Threads") + $blenderArgs }
	if ($Prop) { $blenderArgs += '--prop' }
	if ($Cel) { $blenderArgs += '--cel' }
	& $Blender @blenderArgs
	exit $LASTEXITCODE
} catch {
	Write-Host "Aufräumen fehlgeschlagen: $($_.Exception.Message)"
	exit 1
}
