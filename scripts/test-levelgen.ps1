# Generatorprüfung ohne Roblox; temporärer Runner bleibt in tools (nicht im Git).
$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$luau = Join-Path $projectRoot "tools/luau/luau.exe"
$runner = Join-Path $projectRoot "tools/levelgen.runner.luau"
if (-not (Test-Path $luau)) { Write-Host "tools/luau/luau.exe fehlt."; exit 1 }
$source = @'
local Color3 = { fromRGB = function(...) return { ... } end }
local Vector3 = { new = function(x, y, z) return { x, y, z, X = x, Y = y, Z = z } end }
local Vector2 = { new = function(...) return { ... } end }
local Enum = { Material = setmetatable({}, { __index = function(_, key) return key end }) }
local testModules = {}
'@
foreach ($module in @("Config", "RunConfig", "MapChunks", "LevelGen")) {
    $moduleSource = Get-Content -LiteralPath (Join-Path $projectRoot "src/shared/$module.luau") -Raw -Encoding UTF8
    foreach ($dependency in @("Config", "RunConfig", "MapChunks", "LevelGen")) {
        $moduleSource = $moduleSource.Replace("require(script.Parent.$dependency)", "testModules.$dependency")
    }
    $source += "
 testModules.$module = (function()
$moduleSource
 end)()
"
}
$source += Get-Content -LiteralPath (Join-Path $projectRoot "tests/levelgen.test.luau") -Raw -Encoding UTF8
try {
    [System.IO.File]::WriteAllText($runner, $source, (New-Object System.Text.UTF8Encoding($false)))
    & $luau $runner
    $result = $LASTEXITCODE
} finally {
    if (Test-Path -LiteralPath $runner) { Remove-Item -LiteralPath $runner }
}
exit $result
