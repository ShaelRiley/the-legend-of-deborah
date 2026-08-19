LOD = LOD or {}

hook.Add("Think", "LOD_MinimapAliveSafety", function()
    local map = LOD.Minimap
    if not map or not map.open then return end
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then
        map.open = false
    end
end)
