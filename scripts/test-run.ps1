# Lauf-/Bossablauf sowie Brett/Kamera mit echten Modulen und Roblox-Stubs prüfen.
$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$luau = Join-Path $projectRoot "tools/luau/luau.exe"
$runner = Join-Path $projectRoot "tools/run.runner.luau"
if (-not (Test-Path $luau)) { Write-Host "tools/luau/luau.exe fehlt."; exit 1 }
$source = Get-Content -LiteralPath (Join-Path $projectRoot "tests/tutorial.stubs.luau") -Raw -Encoding UTF8
$modules = @("Config", "UnitData", "RunConfig", "MapChunks", "LevelGen", "Stages", "Grid", "Combat", "Recruit", "Tutorial", "ProfileStore", "RunService", "BossAbilities", "EnemyAI", "TutorialGuide")
foreach ($module in $modules) {
    $directory = if ($module -in @("ProfileStore", "RunService", "BossAbilities", "EnemyAI")) { "server" } elseif ($module -eq "TutorialGuide") { "client" } else { "shared" }
    $moduleSource = Get-Content -LiteralPath (Join-Path $projectRoot "src/$directory/$module.luau") -Raw -Encoding UTF8
    $moduleSource = [regex]::Replace($moduleSource, 'require\((?:script.Parent|Shared)\.([A-Za-z]+)\)', 'testModules.$1')
    $source += "`r`n testModules.$module = (function()`r`n$moduleSource`r`n end)()`r`n"
}
$serverSource = Get-Content -LiteralPath (Join-Path $projectRoot "src/server/Main.server.luau") -Raw -Encoding UTF8
$serverSource = [regex]::Replace($serverSource, 'require\((?:script.Parent|Shared)\.([A-Za-z]+)\)', 'testModules.$1')
$source += "`r`nlocal testServer = (function()`r`n$serverSource`r`nreturn { command = handleCommand, state = function() return state end, snapshot = snapshot, checkResult = checkResult }`r`nend)()`r`n"
$source += Get-Content -LiteralPath (Join-Path $projectRoot "tests/run.test.luau") -Raw -Encoding UTF8
try {
    [System.IO.File]::WriteAllText($runner, $source, (New-Object System.Text.UTF8Encoding($false)))
    & $luau $runner
    $result = $LASTEXITCODE
} finally {
    if (Test-Path -LiteralPath $runner) { Remove-Item -LiteralPath $runner }
}
if ($result -ne 0) { exit $result }

# Separater Runner: tatsächlicher BoardBuilder statt des Server-Platzhalters.
$runner = Join-Path $projectRoot "tools/board.runner.luau"
$source = Get-Content -LiteralPath (Join-Path $projectRoot "tests/board.stubs.luau") -Raw -Encoding UTF8
foreach ($module in @("Config", "UnitData", "Grid", "Stages", "RunConfig", "MapChunks", "LevelGen", "EnvironmentAssets", "BoardBuilder", "CameraController", "ForestOutlines")) {
    $directory = if ($module -in @("EnvironmentAssets", "BoardBuilder")) { "server" } elseif ($module -in @("CameraController", "ForestOutlines")) { "client" } else { "shared" }
    $moduleSource = Get-Content -LiteralPath (Join-Path $projectRoot "src/$directory/$module.luau") -Raw -Encoding UTF8
    $moduleSource = [regex]::Replace($moduleSource, 'require\((?:script.Parent|Shared)\.([A-Za-z]+)\)', 'modules.$1')
    $moduleSource = $moduleSource.Replace('require(ReplicatedStorage:WaitForChild("Shared").Config)', 'modules.Config')
    $moduleSource = $moduleSource.Replace('require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))', 'modules.Config')
    $source += "`r`n modules.$module = (function()`r`n$moduleSource`r`n end)()`r`n"
}
$source += Get-Content -LiteralPath (Join-Path $projectRoot "tests/board.test.luau") -Raw -Encoding UTF8
$source += Get-Content -LiteralPath (Join-Path $projectRoot "tests/environment.test.luau") -Raw -Encoding UTF8
$source += Get-Content -LiteralPath (Join-Path $projectRoot "tests/forest-outlines.test.luau") -Raw -Encoding UTF8
$source += Get-Content -LiteralPath (Join-Path $projectRoot "tests/bridges.test.luau") -Raw -Encoding UTF8
$source += Get-Content -LiteralPath (Join-Path $projectRoot "tests/shore.test.luau") -Raw -Encoding UTF8
$source += Get-Content -LiteralPath (Join-Path $projectRoot "tests/environment-pack.fixture.luau") -Raw -Encoding UTF8
$source += Get-Content -LiteralPath (Join-Path $projectRoot "tests/outer.test.luau") -Raw -Encoding UTF8
$source += Get-Content -LiteralPath (Join-Path $projectRoot "tests/environment-metrics.test.luau") -Raw -Encoding UTF8
$source += Get-Content -LiteralPath (Join-Path $projectRoot "tests/meadow.test.luau") -Raw -Encoding UTF8
try {
    [System.IO.File]::WriteAllText($runner, $source, (New-Object System.Text.UTF8Encoding($false)))
    & $luau $runner
    $result = $LASTEXITCODE
} finally {
    if (Test-Path -LiteralPath $runner) { Remove-Item -LiteralPath $runner }
}
exit $result
