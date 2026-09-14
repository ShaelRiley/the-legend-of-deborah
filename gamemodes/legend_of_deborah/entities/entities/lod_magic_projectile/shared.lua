ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.PrintName = "Legend of Deborah Magic Projectile"
ENT.Spawnable = false
ENT.AdminOnly = false

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "MagicForm")
end
