include("shared.lua")

function ENT:DrawTranslucent()
    self:DrawModel()
    if LOD.AdventurePresentation then
        LOD.AdventurePresentation:Glint(self:WorldSpaceCenter()+Vector(0,0,10),self:EntIndex())
    end
end
