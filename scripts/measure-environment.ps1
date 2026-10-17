# Gleiche Paket-Fixtures und Seeds für beliebige Git-Stände; kein Checkout nötig.
param([string[]]$Revision = @('working'))
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $taskRoot 'tools/environment-measure.runner.luau'
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
foreach ($state in $Revision) {
    $source = Get-Content "$taskRoot/tests/board.stubs.luau" -Raw -Encoding UTF8
    foreach ($module in @('Config', 'UnitData', 'Grid', 'Stages', 'RunConfig', 'MapChunks', 'LevelGen', 'EnvironmentAssets', 'LandscapeBuilder', 'BoardBuilder')) {
        $folder = if ($module -in @('EnvironmentAssets', 'LandscapeBuilder', 'BoardBuilder')) { 'server' } else { 'shared' }
        $path = "src/$folder/$module.luau"
        if ($state -eq 'working') { $body = Get-Content "$taskRoot/$path" -Raw -Encoding UTF8 }
        else {
            if ($module -eq 'LandscapeBuilder') {
                $exists = & git -C $taskRoot ls-tree --name-only $state -- $path
                if (-not $exists) { continue }
            }
            $lines = & git -C $taskRoot show "${state}:$path"
            if ($LASTEXITCODE -ne 0) { throw "Git-Stand $state fehlt: $path" }
            $body = $lines -join "`n"
        }
        $body = [regex]::Replace($body, 'require\((?:script.Parent|Shared)\.([A-Za-z]+)\)', 'modules.$1')
        $body = $body.Replace('require(ReplicatedStorage:WaitForChild("Shared").Config)', 'modules.Config')
        $body = $body.Replace('require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))', 'modules.Config')
        $source += "`nmodules.$module = (function()`n$body`nend)()`n"
    }
    $source += @'

local Board, Grid, Gen, RC, Config = modules.BoardBuilder, modules.Grid, modules.LevelGen, modules.RunConfig, modules.Config
local function freshAssets()
    models:Destroy()
    models = Instance.new("Folder")
    models.Name, models.Parent = "EnvironmentModels", services.ServerStorage
end
'@
    $source += Get-Content "$taskRoot/tests/environment-pack.fixture.luau" -Raw -Encoding UTF8
    $source += @'

originalMetricAssets()
local parts, maxParts, triangles, maxTriangles, seconds, maxSeconds = 0, 0, 0, 0, 0, 0
local calls, maxCalls, clearCalls, voxelCalls, voxels, maxVoxels, volume, maxVolume = 0, 0, 0, 0, 0, 0, 0, 0
for seed = 1, 100 do
    local stage = Gen.generate(seed, "greenland", 1, "axe", RC.MAX_TEAM)
    Grid.setMap(stage.map)
    local beforeBlocks, beforeVoxels, beforeClears = #terrainBlocks, terrainVoxelWrites, #terrainClears
    local start = os.clock()
    local board = Board.build("greenland", stage.features, stage)
    local elapsed = os.clock() - start
    seconds += elapsed; maxSeconds = math.max(maxSeconds, elapsed)
    local writes = board:GetAttribute("TerrainWriteCalls") or (#terrainBlocks - beforeBlocks + terrainVoxelWrites - beforeVoxels)
    local solid = board:GetAttribute("TerrainVolume") or 0
    if solid > 0 and not board:GetAttribute("TerrainClearCalls") then
        -- Der Zwischenstand zählte Fernboden unter Nahblöcken doppelt.
        local w, h = Grid.width() * Config.TILE_SIZE, Grid.height() * Config.TILE_SIZE
        for _, column in terrainColumns do
            if column.x < 0 or column.x >= w or column.z < 0 or column.z >= h then
                solid -= (Config.LANDSCAPE.foundationTop + Config.FEEL.terrainDepth) * Config.LANDSCAPE.resolution ^ 2
            end
        end
    end
    local cells = board:GetAttribute("TerrainVoxels") or 0
    calls += writes; maxCalls = math.max(maxCalls, writes)
    clearCalls += board:GetAttribute("TerrainClearCalls") or (#terrainClears - beforeClears)
    voxelCalls += board:GetAttribute("TerrainVoxelCalls") or (terrainVoxelWrites - beforeVoxels)
    voxels += cells; maxVoxels = math.max(maxVoxels, cells)
    volume += solid; maxVolume = math.max(maxVolume, solid)
    local count, estimate = 0, 0
    for _, part in board:GetDescendants() do if part:IsA("BasePart") then
        count += 1
        estimate += part:GetAttribute("EstimatedTriangles") or (part.Shape == Enum.PartType.Ball and 288 or part.Shape == Enum.PartType.Cylinder and 128 or part:IsA("WedgePart") and 8 or 12)
    end end
    parts += count; maxParts = math.max(maxParts, count)
    triangles += estimate; maxTriangles = math.max(maxTriangles, estimate)
end
print(string.format("100 Seeds: Teile Mittel %.1f / Max %d; Dreiecke Mittel %.0f / Max %d; Stub-Aufbau Mittel %.2f / Max %.2f ms.", parts / 100, maxParts, triangles / 100, maxTriangles, seconds * 10, maxSeconds * 1000))
print(string.format("Terrain: Aufrufe inkl. Loeschen Mittel %.2f / Max %d (davon Air %.2f, WriteVoxels %.2f); Schreibvoxels Mittel %.0f / Max %d; Festvolumen Mittel %.0f / Max %.0f Studs^3. Terrain-Dreiecke nicht geschaetzt.", calls / 100, maxCalls, clearCalls / 100, voxelCalls / 100, voxels / 100, maxVoxels, volume / 100, maxVolume))
assert(triangles / 100 <= Config.ENVIRONMENT.estimatedTriangleBudget, "Mittleres Dreieckbudget ueberschritten")
'@
    try {
        [System.IO.File]::WriteAllText($runner, $source, (New-Object System.Text.UTF8Encoding($false)))
        Write-Host "Stand $state (masshaltige Paket-Fixtures, inkl. Umgebung):"
        & "$taskRoot/tools/luau/luau.exe" $runner
        if ($LASTEXITCODE -ne 0) { throw "Messung fuer $state fehlgeschlagen" }
    } finally {
        if (Test-Path -LiteralPath $runner) { Remove-Item -LiteralPath $runner }
    }
}
