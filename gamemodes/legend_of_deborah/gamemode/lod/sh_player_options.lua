LOD.PlayerOptions=LOD.PlayerOptions or {}
local O=LOD.PlayerOptions
local function alwaysRun(p) return p.GetInfoNum and p:GetInfoNum("lod_always_run",0)~=0 end
if CLIENT then
    O.AlwaysRun=CreateClientConVar("lod_always_run","0",true,true,"Run normally; hold your sprint key to walk",0,1)
    O.ThirdPerson=CreateClientConVar("lod_third_person","0",true,false,"Use the desktop third-person camera",0,1)
    O.MapScale=CreateClientConVar("lod_map_scale","1",true,false,"Map size relative to its usual size",0.5,1.5)
    O.MapOpacity=CreateClientConVar("lod_map_opacity","1",true,false,"Map opacity relative to its usual opacity",0,1)
    local function preference(cv,low,high)
        local n=tonumber(cv:GetFloat())
        if not n or n~=n then return 1 end
        return math.Clamp(n,low,high)
    end
    function O:MapScaleValue() return preference(self.MapScale,0.5,1.5) end
    function O:MapOpacityValue() return preference(self.MapOpacity,0,1) end
end
function O:WantsSprint(p)
    local held=p:KeyDown(IN_SPEED)
    if LOD.SoldierMovement and LOD.SoldierMovement:Active(p) then return false end
    if alwaysRun(p) then return not held end
    return held
end
function O:ApplyMove(p,m)
    if not alwaysRun(p) or p:GetMoveType()~=MOVETYPE_WALK
        or LOD.SoldierMovement and LOD.SoldierMovement:Active(p) then return end
    local held=p:KeyDown(IN_SPEED)
    local from=held and p:GetRunSpeed() or p:GetWalkSpeed()
    local to=held and p:GetWalkSpeed() or p:GetRunSpeed()
    if from<=0 or to<=0 then return end
    -- Convert the horizontal request AND its cap. Raising only the cap leaves
    -- walking-sized (including analog) input at walking speed.
    -- Leave IN_SPEED untouched: Shift+Use and every other modifier still work.
    local ratio=to/from
    local cap,client=m:GetMaxSpeed(),m:GetMaxClientSpeed()
    if client>0 then cap=math.min(cap,client) end
    m:SetForwardSpeed(m:GetForwardSpeed()*ratio)
    m:SetSideSpeed(m:GetSideSpeed()*ratio)
    m:SetMaxSpeed(cap*ratio)
    m:SetMaxClientSpeed(cap*ratio)
end
