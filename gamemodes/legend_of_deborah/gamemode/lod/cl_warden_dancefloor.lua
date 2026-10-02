-- Four lightweight citizen-rig dances. Presentation only: no client motion,
-- hull changes, model allocations or world scans. Native walking supplies feet.
local V=LOD.WardenPresentation
V.DancefloorBasePose=V.DancefloorBasePose or V.Pose
local basePose=V.DancefloorBasePose
local posed=setmetatable({},{__mode="k"})
local names={"ValveBiped.Bip01_Pelvis","ValveBiped.Bip01_Spine1",
    "ValveBiped.Bip01_Spine2","ValveBiped.Bip01_Head1",
    "ValveBiped.Bip01_L_UpperArm","ValveBiped.Bip01_R_UpperArm",
    "ValveBiped.Bip01_L_Forearm","ValveBiped.Bip01_R_Forearm"}
local captions={"Watch the shoulders!","Can't touch this.","Make room for Gordon.","Keep up, hero."}
local function bones(e)
    local model=e:GetModel()
    local cache=e.LODDanceBones
    if not cache or cache.model~=model then
        cache={model=model,ids={}}
        for i,name in ipairs(names) do cache.ids[i]=e:LookupBone(name) end
        e.LODDanceBones=cache
    end
    return cache.ids
end
local function clear(e)
    if IsValid(e) and e.LODDancePosed then
        for _,bone in pairs(bones(e)) do e:ManipulateBoneAngles(bone,Angle(0,0,0)) end
        e.LODDancePosed=nil
    end
    posed[e]=nil
end
local function dancing(e,now)
    return IsValid(e) and not e:IsDormant() and not e:GetNoDraw()
        and e:GetNW2String("LOD_Archetype","")=="warden"
        and e:GetNW2Int("LOD_WardenPhase",0)==1
        and not e:GetNW2Bool("LOD_WardenHidden",false)
        and e:GetNW2Float("LOD_DeathPulseStart",-1)<0
        and not e:GetNW2Bool("LOD_AudioRetired",false)
        and e:GetNW2Int("LOD_WardenDanceMove",0)>0
        and now>=e:GetNW2Float("LOD_WardenDanceStart",0)
        and now<e:GetNW2Float("LOD_WardenTauntUntil",0)
end
function V:Pose(e)
    local now=CurTime()
    local active=dancing(e,now)
    -- Restore before the original pose so toilet seating and private clone
    -- recoil can own their bones immediately on the same frame.
    if e.LODDancePosed then clear(e) end
    basePose(self,e)
    if not active then return end
    posed[e]=true
    local tell=self:Tell(e)
    if tell and tell.hurt>0 and now>=tell.hurt and now<tell.hurtUntil then return end
    local t=now-e:GetNW2Float("LOD_WardenDanceStart",now)
    local move=e:GetNW2Int("LOD_WardenDanceMove",1)
    -- Change the flourish every 1.6s inside a long dance, and rotate the opening
    -- move on each taunt. Adjacent clones start on different moves.
    move=((move-1+math.floor(t/1.6))%4)+1
    local beat=math.sin(t*math.pi*4)
    local sway=math.sin(t*math.pi*2)
    local angles
    if move==1 then -- shoulder shimmy
        angles={Angle(0,sway*7,sway*7),Angle(0,-sway*10,0),Angle(beat*9,beat*15,0),
            Angle(0,-beat*9,0),Angle(beat*12,0,-55+beat*18),Angle(-beat*12,0,55+beat*18),
            Angle(0,0,-25),Angle(0,0,25)}
    elseif move==2 then -- hip shake, with counter-rotating shoulders
        angles={Angle(0,sway*22,beat*10),Angle(0,-sway*16,0),Angle(0,-sway*10,-beat*5),
            Angle(0,sway*12,0),Angle(0,0,-65+beat*12),Angle(0,0,65-beat*12),
            Angle(0,0,-45),Angle(0,0,45)}
    elseif move==3 then -- swaggering disco strut; feet keep native locomotion
        angles={Angle(0,sway*10,sway*7),Angle(-6,0,0),Angle(0,sway*8,0),
            Angle(0,-sway*10,beat*4),Angle(sway*28,0,-25),Angle(-sway*28,0,25),
            Angle(0,0,-15-beat*10),Angle(0,0,15+beat*10)}
    else -- side-to-side arm sweep / bus-stop flourish
        angles={Angle(0,-sway*12,sway*10),Angle(0,sway*15,0),Angle(0,sway*12,beat*5),
            Angle(0,-sway*12,0),Angle(0,sway*20,-85+beat*18),Angle(0,sway*20,85+beat*18),
            Angle(0,0,-35+beat*20),Angle(0,0,35+beat*20)}
    end
    for i,bone in pairs(bones(e)) do e:ManipulateBoneAngles(bone,angles[i]) end
    e.LODDancePosed=true
end
hook.Add("HUDPaint","LOD_WardenDanceCaptions",function()
    local now=CurTime()
    for e in pairs(posed) do
        if not dancing(e,now) then clear(e)
        elseif EyePos():DistToSqr(e:GetPos())<6000^2 then
            local point=(e:GetPos()+Vector(0,0,100)):ToScreen()
            local move=e:GetNW2Int("LOD_WardenDanceMove",1)
            if point.visible then draw.SimpleText(captions[move] or captions[1],"LOD_WardenTitle",
                point.x,point.y,Color(255,170,60),TEXT_ALIGN_CENTER) end
        end
    end
end)
local function cleanup()
    for e in pairs(posed) do clear(e) end
end
hook.Add("PostCleanupMap","LOD_WardenDanceCleanup",cleanup)
hook.Add("ShutDown","LOD_WardenDanceShutdown",cleanup)
