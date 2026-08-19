LOD = LOD or {}

-- MazeBuilder resolves the actual Flatgrass floor on the server at runtime.
-- Keep the shared client maze origin synchronized so the minimap chooses the
-- correct generated floor and current grid cell.
hook.Add("Think", "LOD_MinimapResolvedOriginSync", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:GetNW2Bool("LOD_MazeOriginValid", false) then return end
    if not LOD.Config or not LOD.Config.Maze then return end

    local x = ply:GetNW2Float("LOD_MazeOriginX", 0)
    local y = ply:GetNW2Float("LOD_MazeOriginY", 0)
    local z = ply:GetNW2Float("LOD_MazeOriginZ", 0)
    local current = LOD.Config.Maze.Origin or vector_origin

    if math.abs(current.x - x) > 0.01
        or math.abs(current.y - y) > 0.01
        or math.abs(current.z - z) > 0.01
    then
        LOD.Config.Maze.Origin = Vector(x, y, z)
    end
end)
