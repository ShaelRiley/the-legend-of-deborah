ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "LOD Floor Map"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.BookModel = "models/props_lab/binderblue.mdl"
ENT.BookFallbackModel = "models/props_lab/clipboard.mdl"
ENT.MapRenderMins = Vector(-96, -96, -96)
ENT.MapRenderMaxs = Vector(96, 96, 96)

function ENT:SetupDataTables()
    self:NetworkVar("Int",0,"FloorIndex")
    self:NetworkVar("Vector",0,"PickupPosition")
end
