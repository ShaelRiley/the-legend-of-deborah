include("shared.lua")
function ENT:Initialize() LOD.ProgressionProps:RefreshBounds(self) end
function ENT:Draw() LOD.ProgressionProps:Draw(self) end
-- The gamemode's shared aimed interaction prompt replaces the floating label.
