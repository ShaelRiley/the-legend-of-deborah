-- Presentation only. The court's native hostile is the single damage/reward
-- authority; the horizon body and crowbar never own health or collision.
LOD.HectorPresentation=LOD.HectorPresentation or {}
local V=LOD.HectorPresentation
if V.Dispose then V.Dispose() end
local state
local props={}
local glow=Material("sprites/light_glow02_add")
local beam=Material("cable/redlaser")
local red=Color(255,75,65)
local blue=Color(110,185,255)
local purple=Color(215,100,255)
local gold=Color(255,175,65)
local up=Vector(0,0,1)
local function reduced()
    local c=GetConVar("lod_reduced_effects");return c and c:GetBool()
end
local function disposeProps()
    for name,e in pairs(props) do if IsValid(e) then e:Remove() end;props[name]=nil end
end
local function dispose()
    state=nil;disposeProps()
end
V.Dispose=dispose
local function fresh()
    return state and CurTime()-state.received<=2
end
local function prepareProps()
    for name,model in pairs({body="models/monk.mdl",crowbar="models/weapons/w_crowbar.mdl"}) do
        if not IsValid(props[name]) then
            local p=ClientsideModel(model,RENDERGROUP_OPAQUE)
            if IsValid(p) then
                p:SetNoDraw(true);p:DrawShadow(false);p:SetModelScale(64,0)
                p:SetColor(name=="body" and Color(235,65,70) or Color(190,195,205))
                if name=="body" then
                    if LOD.ApplyHermitPose then LOD.ApplyHermitPose(p)
                    else p:ResetSequence(0);p:SetCycle(0);p:SetPlaybackRate(0) end
                end
                props[name]=p
            end
        end
    end
end
net.Receive("LOD_HectorState",function()
    if not net.ReadBool() then dispose();return end
    local s={actor=net.ReadEntity(),center=net.ReadVector(),stage=net.ReadUInt(2),
        health=net.ReadFloat(),maximum=net.ReadFloat(),phase=net.ReadUInt(2),
        revealUntil=net.ReadFloat(),kind=net.ReadUInt(3),ready=net.ReadFloat(),marks={},hazards={},received=CurTime()}
    local n=net.ReadUInt(3)
    for i=1,n do local p=net.ReadVector();if i<=4 then s.marks[i]=p end end
    n=net.ReadUInt(4)
    for i=1,n do
        local q={kind=net.ReadUInt(3),pos=net.ReadVector(),velocity=net.ReadVector(),expires=net.ReadFloat(),radius=net.ReadFloat()}
        if i<=12 then s.hazards[i]=q end
    end
    -- Entity identity, not its reused EntIndex, retires the previous picture.
    if state and state.actor~=s.actor then disposeProps() end
    state=s
    if s.stage==3 or not IsValid(s.actor) then disposeProps() else prepareProps() end
end)
surface.CreateFont("LOD_HectorTitle",{font="Trebuchet MS",size=26,weight=900})
surface.CreateFont("LOD_HectorPhase",{font="Trebuchet MS",size=17,weight=700})
local warnings={"MISSILE VOLLEY — KEEP MOVING","BOMBS — CLEAR THE MARKS","CROWBAR — CLEAR THE MARKS","CORRUPTED LORE — DODGE THE ORBS"}
hook.Add("HUDPaint","LOD_HectorHealth",function()
    if not fresh() then return end
    local s=state;local width=math.min(640,ScrW()*.86);local x=(ScrW()-width)/2;local y=ScrH()*.08
    draw.SimpleText("HECTOR THE DIRECTOR","LOD_HectorTitle",ScrW()/2,y,Color(250,205,205),TEXT_ALIGN_CENTER)
    draw.RoundedBox(3,x,y+34,width,14,Color(10,10,18,225))
    draw.RoundedBox(3,x+2,y+36,(width-4)*math.Clamp(s.health/math.max(1,s.maximum),0,1),10,red)
    local instruction=s.stage==3 and "HECTOR DEFEATED — TAKE THE JAIL KEY"
        or s.stage==1 and "THE DIRECTOR REVEALS HIMSELF"
        or "ATTACK THE DIRECTOR'S HEART IN THE COURT"
    draw.SimpleText(instruction,"LOD_HectorPhase",ScrW()/2,y+54,Color(245,235,235),TEXT_ALIGN_CENTER)
    if s.stage==2 then
        local label=s.kind>0 and s.ready>CurTime() and warnings[s.kind]
            or ("PHASE "..s.phase.."  ·  "..math.max(0,math.ceil(s.health)).." / "..math.ceil(s.maximum))
        draw.SimpleText(label,"LOD_HectorPhase",ScrW()/2,y+76,gold,TEXT_ALIGN_CENTER)
    end
end)
local function ring(p,radius,color,filled)
    render.SetColorMaterial()
    if filled and LOD.MagicArea then LOD.MagicArea:Disc(p+up*2,radius,Vector(1,0,0),Vector(0,1,0),Color(color.r,color.g,color.b,75)) end
    render.SetMaterial(beam)
    local count=reduced() and 16 or 32
    for i=1,count do
        local a,b=(i-1)*math.pi*2/count,i*math.pi*2/count
        render.DrawBeam(p+Vector(math.cos(a)*radius,math.sin(a)*radius,3),
            p+Vector(math.cos(b)*radius,math.sin(b)*radius,3),4,0,1,color)
    end
end
local function horizon(s)
    local sign=LOD.CampaignTimeout and LOD.CampaignTimeout.FlattywoodSign or Vector(-82108,3781,-6272)
    local direction=sign-s.center;direction.z=0;direction:Normalize()
    -- The sign lives in the 3D skybox; place a depth-tested world silhouette
    -- on its bearing within native world bounds. No giant navigation actor.
    local pos=s.center+direction*6500+up*2500
    local facing=(s.center-pos):Angle();facing.p=0;facing.r=0
    local rise=s.stage==1 and math.Clamp(1-(s.revealUntil-CurTime())/3,0,1) or 1
    if not reduced() then pos=pos-up*((1-rise)*900) end
    return pos,facing
end
local function drawBody(s)
    local body=props.body;if not IsValid(body) then return end
    local pos,ang=horizon(s)
    body:SetPos(pos);body:SetAngles(ang);body:SetupBones()
    -- Retain only the enormous upper body; clipping is restored even when a
    -- third-party model hook throws, so a bad model cannot clip the whole map.
    local previous=render.EnableClipping(true)
    render.PushCustomClipPlane(up,up:Dot(pos+up*(34*64)))
    local ok,err=xpcall(function() body:DrawModel() end,debug.traceback)
    render.PopCustomClipPlane();render.EnableClipping(previous)
    if not ok then ErrorNoHalt("[LOD:HECTOR] "..tostring(err).."\n");return end
    local chest=pos+up*(52*64)
    if IsValid(s.actor) then
        render.SetMaterial(beam);render.DrawBeam(chest,s.actor:WorldSpaceCenter(),reduced() and 5 or 12,0,1,purple)
    end
    local crowbar=props.crowbar
    if IsValid(crowbar) then
        local bone=body:LookupBone("ValveBiped.Bip01_R_Hand")
        local matrix=bone and body:GetBoneMatrix(bone)
        local hand=matrix and matrix:GetTranslation() or pos+ang:Right()*(-19*64)+up*(47*64)
        local swing=s.kind==3 and math.Clamp(1-(s.ready-CurTime())/1.5,0,1) or 0
        crowbar:SetPos(hand);crowbar:SetAngles(Angle(-100+150*swing,ang.y,ang.r));crowbar:DrawModel()
    end
end
hook.Add("PostDrawTranslucentRenderables","LOD_HectorWorld",function(depth,sky)
    if depth or sky or not fresh() or state.stage==3 then return end
    local s=state
    drawBody(s)
    if s.kind>0 and s.ready>CurTime() then
        local blast=s.kind==2 or s.kind==3
        local color=s.kind==4 and purple or (blast and gold or blue)
        for _,p in ipairs(s.marks) do ring(p,blast and 180 or 48,color,blast) end
    end
    for _,q in ipairs(s.hazards) do
        if CurTime()<q.expires then
            local p=q.pos+q.velocity*math.min(.2,math.max(0,CurTime()-s.received))
            if EyePos():DistToSqr(p)<6000^2 then
                local color=q.kind==4 and purple or (q.kind==2 and gold or blue)
                if q.kind==2 or q.kind==3 then
                    if q.expires-CurTime()<.8 then color=red end
                    ring(p,math.Clamp(q.radius,1,512),color,true)
                    render.SetMaterial(glow);render.DrawSprite(p+up*12,28,28,color)
                else
                    render.SetMaterial(glow);render.DrawSprite(p,48,48,color)
                    if not reduced() then render.DrawSprite(p,20,20,Color(245,250,255)) end
                    render.SetMaterial(beam);render.DrawBeam(p-q.velocity:GetNormalized()*58,p,8,0,1,color)
                end
            end
        end
    end
end)
hook.Add("Think","LOD_HectorPropsRetire",function()
    if not fresh() then dispose()
    elseif state.stage~=3 and not IsValid(state.actor) then disposeProps() end
end)
hook.Add("PostCleanupMap","LOD_HectorMapCleanup",dispose)
hook.Add("ShutDown","LOD_HectorShutdown",dispose)
