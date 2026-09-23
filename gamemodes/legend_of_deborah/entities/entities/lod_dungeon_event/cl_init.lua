include('shared.lua')
function ENT:Draw()
    if self:GetNW2String('LOD_EventArchetype','')=='equipment_quiz' then
        for _,row in ipairs(LOD.DungeonEvents and LOD.DungeonEvents.events or {}) do
            if row.id==self:GetEventID() and row.entityIndex==self:EntIndex()
                and row.details and row.details.spent then return end
        end
        if LOD.ApplyHermitPose then LOD.ApplyHermitPose(self) end
    end
    self:DrawModel()
end
