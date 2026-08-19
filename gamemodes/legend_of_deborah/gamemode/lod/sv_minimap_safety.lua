LOD = LOD or {}

local Minimap = LOD.MinimapServer
if not Minimap or Minimap.LODAliveGatePatched then return end
Minimap.LODAliveGatePatched = true

local baseCanUse = Minimap.CanUse
function Minimap:CanUse(ply)
    if not IsValid(ply) or not ply:Alive() then return false end
    return baseCanUse(self, ply)
end
