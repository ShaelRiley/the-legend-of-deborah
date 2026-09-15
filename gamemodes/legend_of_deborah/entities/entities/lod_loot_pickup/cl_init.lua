include("shared.lua")

function ENT:DrawTranslucent()
    self:DrawModel()
    local styled=LOD.WeaponAppearance and LOD.WeaponAppearance:DrawPickup(self)
    if not styled and LOD.AdventurePresentation then
        LOD.AdventurePresentation:Glint(self:WorldSpaceCenter()+Vector(0,0,10),self:EntIndex())
    end
end

