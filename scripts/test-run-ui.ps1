# Lager-/Wahloberfläche mit echten UI-Modulen prüfen (kein Renderer).
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$source = Get-Content "$taskRoot/tests/run-ui.stubs.luau" -Raw -Encoding UTF8
foreach ($name in @('Config', 'UnitData', 'Stages', 'Grid', 'Tutorial', 'RunConfig', 'MapChunks', 'LevelGen', 'Recruit', 'UIKit', 'UI', 'CollectionUI', 'RunUI', 'MenuUI', 'TutorialGuide')) {
	$folder = if ($name -in @('UIKit', 'UI', 'CollectionUI', 'RunUI', 'MenuUI', 'TutorialGuide')) { 'client' } else { 'shared' }
	$body = Get-Content "$taskRoot/src/$folder/$name.luau" -Raw -Encoding UTF8
	$body = $body -replace 'require\(script.Parent.(\w+)\)', 'modules.$1'
	$body = $body -replace 'require\(Shared.(\w+)\)', 'modules.$1'
	$body = $body -replace 'require\((?:Shared|script.Parent):WaitForChild\("(\w+)"\)\)', 'modules.$1'
	$source += "`nmodules.$name = (function()`n$body`nend)()`n"
}
$source += "`nVector3.new = function(x,y,z) return setmetatable({X=x,Y=y,Z=z}, {__add=function(a,b) return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end}) end`n"
$source += Get-Content "$taskRoot/tests/run-ui.test.luau" -Raw -Encoding UTF8
$runner = Join-Path $taskRoot "tools/run-ui.runner.luau"
try {
    [System.IO.File]::WriteAllText($runner, $source, (New-Object System.Text.UTF8Encoding($false)))
    & "$taskRoot/tools/luau/luau.exe" $runner
    $result = $LASTEXITCODE
} finally {
    if (Test-Path -LiteralPath $runner) { Remove-Item -LiteralPath $runner }
}
exit $result
