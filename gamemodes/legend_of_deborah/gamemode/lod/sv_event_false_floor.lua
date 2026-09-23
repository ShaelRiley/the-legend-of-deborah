-- A real retracting floor; gravity, movement and fall damage remain native.
-- There is no captured-player timer, teleport, velocity override or new graph edge.
LOD.FalseFloorEvent = LOD.FalseFloorEvent or {}
local F, Run, Builder = LOD.FalseFloorEvent, LOD.RunManager, LOD.MazeBuilder
F.ApertureHalf, F.OpenSeconds = 64, 3
local function key(c) return LOD.MazeGenerator.CellKey(c.x,c.y,c.z) end

function F:CanClose(instance)
    local floor = instance.floor
    if not floor or not IsValid(floor.lid) then return false end
    local center, a = Builder:CellCenter(instance.cell), self.ApertureHalf
    local ignored={floor.original,floor.lid}
    for _,rim in ipairs(floor.rims) do ignored[#ignored+1]=rim end
    local tr = util.TraceHull({start=center, endpos=center,
        mins=Vector(-a,-a,-LOD.Config.Geometry.FloorThickness-2), maxs=Vector(a,a,4),
        mask=MASK_PLAYERSOLID, filter=ignored})
    if tr.Hit or tr.StartSolid or tr.AllSolid then return false end
    for _, ent in ipairs(ents.FindInBox(center+Vector(-a,-a,-LOD.Config.Geometry.FloorThickness-2), center+Vector(a,a,4))) do
        if ent~=floor.original and ent~=floor.lid
            and (ent:IsPlayer() or ent:IsNPC() or ent.LODHostile or ent:GetClass()=="trigger_hurt") then return false end
    end
    return true
end

local function owns(director,instance)
    if not director:IsCurrent(instance) or instance.state~="active" then return false end
    local lid=instance.floor and instance.floor.lid
    if not IsValid(lid) or lid.LODEventInstance~=instance then return false end
    for _,ent in ipairs(instance.entities) do if ent==lid then return true end end
    return false
end

local function running()
    if Run.State.SimulationFrozen then return false end
    local clock=Run.State.CampaignClock
    return not (clock and (clock.expired or clock.scene or (clock.deadline and SysTime()>=clock.deadline)))
end
local function returnRoute(instance,lower)
    return LOD.MazeNavigator:FindPath(Run.State.Graph,lower,instance.cell)
        and LOD.MazeNavigator:FindPath(Run.State.Graph,instance.cell,lower)
end

function F:TryOpen(director, instance, ply)
    local floor = instance.floor
    if not owns(director,instance) or instance.open
        or not floor or not IsValid(floor.lid) or not running() then return false end
    local T = LOD.SafeTeleport
    local binding = T:Bind(ply)
    if not binding or not ply:OnGround() or ply:GetGroundEntity()~=floor.lid then return false end
    local identity=ply:SteamID64()
    local lower = Run.State.Graph.Cells[instance.placement.destinationCellKey]
    if not returnRoute(instance,lower) then return false end
    local landing = T:DropLanding(ply,Run.State.Graph,instance.cell,lower,floor,self.ApertureHalf)
    if not landing or instance.floor~=floor or not returnRoute(instance,lower)
        or not T:Matches(binding) or not owns(director,instance) or not running() or ply:SteamID64()~=identity
        or not IsValid(floor.lid) or ply:GetGroundEntity()~=floor.lid then return false end
    instance.open, instance.openedAt = true, CurTime()
    floor.lid:SetNW2Bool("LOD_FalseFloorOpen",true)
    floor.lid:SetNotSolid(true)
    floor.lid:SetNW2Bool("LOD_GeometryHidden",true)
    -- Unground only the freshly revalidated triggering body. Source sometimes
    -- retains a removed support until movement; no displacement is prescribed.
    ply:SetGroundEntity(NULL)
    director:SyncAll()
    return true
end

function F:Tick(director, instance)
    if not owns(director,instance) or not running() then return end
    local floor=instance.floor
    if instance.open then
        if CurTime() >= instance.openedAt+self.OpenSeconds and self:CanClose(instance)
            and instance.floor==floor and owns(director,instance) and running() then
            instance.open=false
            instance.floor.lid:SetNotSolid(false)
            instance.floor.lid:SetNW2Bool("LOD_GeometryHidden",false)
            instance.floor.lid:SetNW2Bool("LOD_FalseFloorOpen",false)
            director:SyncAll()
        end
        return
    end
    for _, ply in ipairs(player.GetAll()) do
        if self:TryOpen(director,instance,ply) then return end
    end
end

LOD.EventRegistry:Register({
    id="false_floor", contract="HAZARD", production=true, reversible=true, dropFloor=true,
    previewNotice="False-floor preview is unranked. Step onto the central panel; ordinary gravity and fall damage apply. Return by the existing stairs.",
    Place=function(_,_,g,cell)
        if cell.z<=0 then return nil end
        local destination=LOD.MazeGenerator.CellKey(cell.x,cell.y,cell.z-1)
        if not g.Cells[destination] then return nil end
        return {cellKey=key(cell),destinationCellKey=destination}
    end,
    Create=function(director,instance,g)
        local floor=Builder:CreateFalseFloor(instance.cell,F.ApertureHalf)
        if not floor then return nil,"ordinary elevated floor unavailable" end
        instance.floor,instance.open=floor,false
        local lid=floor.lid
        lid:SetNW2String("LOD_EventArchetype","false_floor")
        lid:SetNW2String("LOD_EventID",instance.id)
        lid:SetNW2Bool("LOD_FalseFloorOpen",false)
        local tracked=director:Track(instance,lid)
        for _, rim in ipairs(floor.rims) do tracked=director:Track(instance,rim) and tracked end
        if not tracked then
            Builder:RestoreFalseFloor(floor)
            if IsValid(lid) then lid:Remove() end
            for _,rim in ipairs(floor.rims) do if IsValid(rim) then rim:Remove() end end
            return nil,"event ownership changed during floor creation"
        end
        return lid
    end,
    Interact=function() return false,"Step onto the central panel; no Use action is required." end,
    Tick=function(director,instance) F:Tick(director,instance) end,
    Snapshot=function(instance) return {open=instance.open==true,destinationCellKey=instance.placement.destinationCellKey} end,
    Cleanup=function(_,instance)
        if instance.floor and not F:CanClose(instance) then
            -- Event invalidation must never materialize steel through a body.
            -- These boxes were already registered to MazeBuilder. Leave an inert
            -- open aperture until its normal complete geometry teardown.
            for _,ent in ipairs(instance.entities) do
                if IsValid(ent) then
                    ent.LODEventInstance=nil
                    ent:SetNW2String("LOD_EventArchetype","")
                    ent:SetNW2String("LOD_EventID","")
                end
            end
            instance.entities={}
        else Builder:RestoreFalseFloor(instance.floor) end
    end
})
