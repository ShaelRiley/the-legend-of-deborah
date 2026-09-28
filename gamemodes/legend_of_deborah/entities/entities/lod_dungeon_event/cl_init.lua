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
    local archetype=self:GetNW2String('LOD_EventArchetype','')
    if archetype~='memory_terminal' and archetype~='relay_race' and archetype~='counterweight_cache'
        and archetype~='nerve_clock' then return end
    local ply=LocalPlayer()
    if not IsValid(ply) or ply:GetPos():DistToSqr(self:GetPos())>512*512 then return end
    local row
    for _,event in ipairs(LOD.DungeonEvents and LOD.DungeonEvents.events or {}) do
        if event.id==self:GetEventID() then
            for _,point in ipairs(event.details and event.details.endpoints or {}) do
                if point.entityIndex==self:EntIndex() then row=event;break end
            end
        end
        if row then break end
    end
    if not row or not row.details then return end
    local details,part=row.details,self:GetNW2Int('LOD_IncidentPart',0)
    local label,tint=nil,Color(210,220,235)
    if part>0 then
        label=tostring(part)
        if archetype=='memory_terminal' and details.phase=='watch' and details.visibleLight==part then
            tint=Color(255,220,80);label='['..label..']'
        end
    elseif archetype=='nerve_clock' and not details.spent then
        if details.phase=='green' then label,tint='GREEN',Color(90,240,120)
        elseif details.phase=='red' then label,tint='RED',Color(245,90,75) end
    end
    if not label then return end
    -- Recipient-only snapshots drive each Hero's clue. Upcoming memory choices
    -- and another Hero's clock are never sent or painted here.
    cam.Start3D2D(self:GetPos()+Vector(0,0,34),Angle(0,ply:EyeAngles().y-90,90),.18)
    draw.SimpleTextOutlined(label,'LOD_HUD_Small',0,0,tint,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER,1,Color(0,0,0,230))
    cam.End3D2D()
end
