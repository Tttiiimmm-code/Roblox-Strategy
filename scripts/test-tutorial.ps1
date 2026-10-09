# Tutorial-Ablauf mit echten Modulen und Roblox-Stubs prüfen.
$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$luau = Join-Path $projectRoot "tools/luau/luau.exe"
$runner = Join-Path $projectRoot "tools/tutorial.runner.luau"
if (-not (Test-Path $luau)) { Write-Host "tools/luau/luau.exe fehlt."; exit 1 }
$source = Get-Content -LiteralPath (Join-Path $projectRoot "tests/tutorial.stubs.luau") -Raw -Encoding UTF8
$modules = @("Config", "UnitData", "RunConfig", "MapChunks", "LevelGen", "Stages", "Grid", "Combat", "Recruit", "Tutorial", "ProfileStore", "RunService", "BossAbilities", "TutorialGuide")
foreach ($module in $modules) {
    $directory = if ($module -in @("ProfileStore", "RunService", "BossAbilities", "EnemyAI")) { "server" } elseif ($module -eq "TutorialGuide") { "client" } else { "shared" }
    $moduleSource = Get-Content -LiteralPath (Join-Path $projectRoot "src/$directory/$module.luau") -Raw -Encoding UTF8
    $moduleSource = [regex]::Replace($moduleSource, 'require\((?:script.Parent|Shared)\.([A-Za-z]+)\)', 'testModules.$1')
    $source += "`r`n testModules.$module = (function()`r`n$moduleSource`r`n end)()`r`n"
}
$serverSource = Get-Content -LiteralPath (Join-Path $projectRoot "src/server/Main.server.luau") -Raw -Encoding UTF8
$serverSource = [regex]::Replace($serverSource, 'require\((?:script.Parent|Shared)\.([A-Za-z]+)\)', 'testModules.$1')
$source += "`r`nlocal testServer = (function()`r`n$serverSource`r`nreturn { command = handleCommand, state = function() return state end, snapshot = snapshot, checkResult = checkResult }`r`nend)()`r`n"
$source += Get-Content -LiteralPath (Join-Path $projectRoot "tests/tutorial.test.luau") -Raw -Encoding UTF8
try {
    [System.IO.File]::WriteAllText($runner, $source, (New-Object System.Text.UTF8Encoding($false)))
    & $luau $runner
    $result = $LASTEXITCODE
} finally {
    if (Test-Path -LiteralPath $runner) { Remove-Item -LiteralPath $runner }
}
exit $result
