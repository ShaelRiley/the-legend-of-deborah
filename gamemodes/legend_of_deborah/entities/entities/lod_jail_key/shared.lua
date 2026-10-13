ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "LOD Jail Key"
ENT.Spawnable = false
ENT.AdminOnly = false
ENT.RenderGroup = RENDERGROUP_BOTH

-- The entity origin/pickup point stays at the canonical 40-unit key height.
-- Only this low, narrow plinth is solid; the floating display cannot block a
-- jump. Client paint and server collision share the same deck-relative bounds.
ENT.PedestalHalfWidth = 20
ENT.PedestalHeight = 28
local deck = -LOD.Config.Progression.KeycardHeight
ENT.PedestalMins = Vector(-20, -20, deck)
ENT.PedestalMaxs = Vector(20, 20, deck + ENT.PedestalHeight)
-- Include all facing angles, bob extrema, labels and the temporary Core beacon.
-- The stock placeholder cube's tiny bounds must never decide display visibility.
ENT.KeyRenderMins = Vector(-64, -64, deck - 2)
ENT.KeyRenderMaxs = Vector(64, 64, 144)

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "KeySource")
end
