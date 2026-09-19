include('shared.lua')
function ENT:Draw()
    if LOD.Damsels and LOD.Damsels.DrawActor then LOD.Damsels:DrawActor(self,true) else self:DrawModel() end
end
