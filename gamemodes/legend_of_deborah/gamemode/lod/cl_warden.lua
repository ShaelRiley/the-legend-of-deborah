LOD.WardenPresentation=LOD.WardenPresentation or {}
local V=LOD.WardenPresentation
if V.DisposeProps then V.DisposeProps() end
if V.ClearTells then V:ClearTells() end
local glow=Material("sprites/light_glow02_add")
local beam=Material("cable/redlaser")
local blue=Color(110,185,255,230)
local gold=Color(255,170,60,255)
local state
local captions={"Lucky shot.","Too slow.","Still aiming?","Keep dancing."}
local prepareProps
net.Receive("LOD_WardenState",function()
    if not net.ReadBool() then state=nil;if V.ClearTells then V:ClearTells() end;return end
    local s={actor=net.ReadEntity(),health=net.ReadFloat(),maximum=net.ReadFloat(),phase=net.ReadUInt(2),hazards={},received=CurTime()}
    local n=net.ReadUInt(5)
    for i=1,n do s.hazards[i]={id=net.ReadUInt(16),bomb=net.ReadBool(),pos=net.ReadVector(),velocity=net.ReadVector(),expires=net.ReadFloat()} end
    s.cues={}
    for i=1,net.ReadUInt(4) do
        local q={kind=net.ReadUInt(2),pos=net.ReadVector(),start=net.ReadFloat(),expires=net.ReadFloat(),caption=net.ReadUInt(3)}
        if i<=10 and q.kind>=1 and q.kind<=3 and q.expires>CurTime()
            and q.expires-q.start>0 and q.expires-q.start<=1.2 then s.cues[#s.cues+1]=q end
    end
    state=s
    if prepareProps then prepareProps(s.phase) end
end)
-- Private, finite observations. No client message asks the server to reveal a
-- fake. Tokens are generic native/observer lifetimes, not persistent discovery.
local tells
local fakePosed=setmetatable({},{__mode="k"})
local tellCache=setmetatable({},{__mode="k"})
function V:ClearTells()
    tells=nil;tellCache=setmetatable({},{__mode="k"})
    for e in pairs(fakePosed) do
        if IsValid(e) then self:Pose(e) end
        fakePosed[e]=nil
    end
end
net.Receive("LOD_WardenTells",function()
    local count=net.ReadUInt(3)
    if count==0 or count>4 then V:ClearTells();return end
    local s={sent=net.ReadFloat(),expires=net.ReadFloat(),root=net.ReadEntity(),rootLife=net.ReadUInt(31),
        observerLife=net.ReadUInt(31),serial=net.ReadUInt(32),range=net.ReadFloat(),records={}}
    for i=1,count do
        local q={actor=net.ReadEntity(),life=net.ReadUInt(31),phase=net.ReadUInt(2),eye=net.ReadUInt(1),
            wink=net.ReadFloat(),hurt=net.ReadFloat(),hurtUntil=net.ReadFloat()}
        if IsValid(q.actor) then s.records[q.actor]=q end
    end
    local now=CurTime()
    if not IsValid(s.root) or s.sent~=s.sent or s.expires~=s.expires or s.range~=s.range
        or s.sent>now+0.05 or s.expires<=now or s.expires-s.sent<=0 or s.expires-s.sent>0.45
        or s.range<=0 or s.range==math.huge then V:ClearTells();return end
    tells=s;tellCache=setmetatable({},{__mode="k"})
end)
local function tellAlive(e)
    return IsValid(e) and not e:IsDormant() and not e:GetNoDraw()
        and e:GetNW2Float("LOD_DeathPulseStart",-1)<0 and not e:GetNW2Bool("LOD_AudioRetired",false)
end
function V:Tell(e)
    local s=tells;local q=s and s.records[e]
    if not q then return end
    local frame=FrameNumber();local cached=tellCache[e]
    if cached and cached.frame==frame then return cached.value end
    cached={frame=frame};tellCache[e]=cached
    local now=CurTime();local p=LocalPlayer()
    local world=LOD.ClientState
    if world and (world.failed or world.levelCleared) then return end
    if now<s.sent or now>=s.expires or not IsValid(p) or not p:Alive()
        or not p:GetNW2Bool("LOD_Deployed",false) or p:GetNW2Bool("LOD_IsSoldier",false)
        or p:GetNW2Bool("LOD_Staged",false) or p:GetNW2Bool("LOD_Eliminated",false)
        or p:GetNW2Int("LOD_WardenObserverLife",0)~=s.observerLife
        or p:GetNW2Int("LOD_HeroSerial",0)~=s.serial
        or not state or state.actor~=s.root or CurTime()-state.received>2
        or not tellAlive(s.root) or s.root:GetNW2Int("LOD_WardenVisualLife",0)~=s.rootLife
        or not tellAlive(e) or e==s.root or e:GetNW2String("LOD_Archetype","")~="warden"
        or e:GetNW2Int("LOD_WardenVisualLife",0)~=q.life or q.life<=0
        or e:GetNW2Int("LOD_WardenPhase",0)~=q.phase or q.phase<1 or q.phase>3
        or e:GetNW2Bool("LOD_WardenHidden",false)
        or p:GetPos():DistToSqr(e:GetPos())>s.range*s.range then return end
    local tr=util.TraceLine({start=p:EyePos(),endpos=e:WorldSpaceCenter(),mask=MASK_VISIBLE,filter=p})
    if not tr or tr.StartSolid or tr.Hit and tr.Entity~=e then return end
    cached.value=q;return q
end
surface.CreateFont("LOD_WardenTitle",{font="Trebuchet MS",size=26,weight=900})
surface.CreateFont("LOD_WardenPhase",{font="Trebuchet MS",size=17,weight=700})
hook.Add("HUDPaint","LOD_WardenHealth",function()
    local s=state;if not s or not IsValid(s.actor) or CurTime()-s.received>2 then return end
    local width=math.min(580,ScrW()*0.64);local x=(ScrW()-width)/2;local y=ScrH()*0.08
    draw.SimpleText("GORDON THE WARDEN","LOD_WardenTitle",ScrW()/2,y,Color(240,225,210),TEXT_ALIGN_CENTER)
    draw.RoundedBox(3,x,y+34,width,14,Color(10,10,18,225))
    draw.RoundedBox(3,x+2,y+36,(width-4)*math.Clamp(s.health/math.max(1,s.maximum),0,1),10,
        s.phase==3 and Color(240,75,55) or gold)
    local name=({"VANISHING VOLLEYS","TOILET BOMBER — WATCH THE FUSES","CROWBAR BERSERKER"})[s.phase]
    draw.SimpleText(name.."  ·  "..math.max(0,math.ceil(s.health)).." / "..math.ceil(s.maximum),
        "LOD_WardenPhase",ScrW()/2,y+54,Color(235,235,245),TEXT_ALIGN_CENTER)
    for _,q in ipairs(s.cues or {}) do
        if q.kind==3 and captions[q.caption] and CurTime()>=q.start and CurTime()<q.expires and EyePos():DistToSqr(q.pos)<6000^2 then
            local point=(q.pos+Vector(0,0,90)):ToScreen()
            if point.visible then draw.SimpleText(captions[q.caption],"LOD_WardenTitle",point.x,point.y,gold,TEXT_ALIGN_CENTER) end
        end
    end
end)
local function reduced()
    local c=GetConVar("lod_reduced_effects");return c and c:GetBool()
end
-- Cosmetic ground glyphs: a contracting ring means departure; a fixed square
-- with inward chevrons means arrival. Reduced effects keep the same geometry.
function V:DrawPhaseCue(q,now)
    if q.kind==3 or now<q.start or now>=q.expires or EyePos():DistToSqr(q.pos)>=6000^2 then return end
    local p=q.pos+Vector(0,0,4)
    local progress=math.Clamp((now-q.start)/math.max(0.001,q.expires-q.start),0,1)
    render.SetMaterial(beam)
    if q.kind==1 then
        local radius=60-48*progress
        for i=1,16 do
            local a,b=(i-1)*math.pi/8,i*math.pi/8
            render.DrawBeam(p+Vector(math.cos(a)*radius,math.sin(a)*radius,0),
                p+Vector(math.cos(b)*radius,math.sin(b)*radius,0),4,0,1,blue)
        end
    elseif q.kind==2 then
        local corners={Vector(-46,-46,0),Vector(46,-46,0),Vector(46,46,0),Vector(-46,46,0)}
        for i=1,4 do
            render.DrawBeam(p+corners[i],p+corners[i%4+1],4,0,1,gold)
            local a=(i-1)*math.pi/2;local forward=Vector(math.cos(a),math.sin(a),0)
            local side=Vector(-math.sin(a),math.cos(a),0)
            local tip=p+forward*(32-16*progress)
            render.DrawBeam(tip+forward*14+side*10,tip,4,0,1,gold)
            render.DrawBeam(tip+forward*14-side*10,tip,4,0,1,gold)
        end
    end
    if not reduced() then
        render.SetMaterial(glow);render.DrawSprite(p+Vector(0,0,20),20,20,q.kind==1 and blue or gold)
    end
end
hook.Add("PostDrawTranslucentRenderables","LOD_WardenHazards",function(depth,sky)
    if depth or sky or not state or not IsValid(state.actor) or CurTime()-state.received>2 then return end
    for _,q in ipairs(state.cues or {}) do V:DrawPhaseCue(q,CurTime()) end
    for _,q in ipairs(state.hazards) do
        if CurTime()<q.expires then
            local p=q.pos+q.velocity*math.min(0.2,math.max(0,CurTime()-state.received))
            if EyePos():DistToSqr(p)<6000^2 then
                if q.bomb then
                    local left=math.max(0,q.expires-CurTime())
                    local color=left<0.8 and Color(255,70,40,255) or gold
                    render.SetMaterial(glow);render.DrawSprite(p+Vector(0,0,12),24,24,color)
                    -- Filled blast footprint and opaque boundary match the real
                    -- 180-unit sphere projected onto the bomb's floor.
                    render.SetColorMaterial()
                    if LOD.MagicArea then LOD.MagicArea:Disc(p+Vector(0,0,2),180,Vector(1,0,0),Vector(0,1,0),Color(color.r,color.g,color.b,102)) end
                    render.SetMaterial(beam)
                    local count=reduced() and 16 or 32
                    for i=1,count do
                        local a,b=(i-1)*math.pi*2/count,i*math.pi*2/count
                        local from=p+Vector(math.cos(a)*180,math.sin(a)*180,2)
                        local to=p+Vector(math.cos(b)*180,math.sin(b)*180,2)
                        render.DrawBeam(from,to,3,0,1,color)
                    end
                else
                    render.SetMaterial(glow);render.DrawSprite(p,48,48,blue)
                    if not reduced() then render.DrawSprite(p,22,22,Color(245,250,255)) end
                    render.SetMaterial(beam);render.DrawBeam(p-q.velocity:GetNormalized()*58,p,8,0,1,blue)
                end
            end
        end
    end
end)
-- Exactly two reusable client models, never parented to moving native physics.
-- They are created on phase entry and retired on boss loss/map shutdown.
local props={}
local function dispose()
    for k,e in pairs(props) do if IsValid(e) then e:Remove() end;props[k]=nil end
end
V.DisposeProps=dispose
hook.Add("PostCleanupMap","LOD_WardenPropsMapCleanup",function() V:ClearTells();state=nil;dispose() end)
prepareProps=function(phase)
    -- Clones can enter different phases. Reuse the same two props for every
    -- draw, allocated on the encounter snapshot, never inside the render hook.
    for name,model in pairs({toilet="models/props_c17/FurnitureToilet001a.mdl",crowbar="models/weapons/w_crowbar.mdl"}) do
        if not IsValid(props[name]) then
            local p=ClientsideModel(model,RENDERGROUP_OPAQUE)
            if IsValid(p) then p:SetNoDraw(true);props[name]=p end
        end
    end
end
function V:Pose(e)
    if e:GetNW2String("LOD_Archetype", "")~="warden" then
        if fakePosed[e] then
            for _,name in ipairs({"ValveBiped.Bip01_Spine2","ValveBiped.Bip01_L_UpperArm","ValveBiped.Bip01_R_UpperArm"}) do
                local bone=e:LookupBone(name);if bone then e:ManipulateBoneAngles(bone,Angle(0,0,0)) end
            end
            fakePosed[e]=nil;e.LODWasTaunting=nil
        end
        return
    end
    local model=e:GetModel()
    if e.LODWardenBuildModel~=model then
        e.LODWardenBuildModel=model;e.LODWardenSeated=nil
        -- Citizen meshes have no heavy bodygroup. Broaden their existing torso
        -- and upper legs locally, once per model; never touch the server hull.
        for name,scale in pairs({
            ["ValveBiped.Bip01_Pelvis"]=Vector(1.12,1.32,1.30),
            ["ValveBiped.Bip01_Spine"]=Vector(1.10,1.48,1.45),
            ["ValveBiped.Bip01_Spine1"]=Vector(1.08,1.35,1.32),
            ["ValveBiped.Bip01_Spine2"]=Vector(1.05,1.22,1.22),
            ["ValveBiped.Bip01_L_Thigh"]=Vector(1,1.20,1.20),
            ["ValveBiped.Bip01_R_Thigh"]=Vector(1,1.20,1.20)
        }) do
            local bone=e:LookupBone(name)
            if bone then e:ManipulateBoneScale(bone,scale) end
        end
    end
    local taunting=e:GetNW2Float("LOD_WardenTauntUntil",0)>CurTime()
    local tell=self:Tell(e);local now=CurTime()
    local recoiling=tell and tell.hurt>0 and now>=tell.hurt and now<tell.hurtUntil
        and tell.hurtUntil-tell.hurt<=0.4
    local recoil=recoiling and math.sin(math.pi*(now-tell.hurt)/math.max(0.001,tell.hurtUntil-tell.hurt))*35 or 0
    if taunting or e.LODWasTaunting or recoiling or fakePosed[e] then
        local sway=taunting and math.sin(CurTime()*12)*25 or 0
        for name,angle in pairs({
            ["ValveBiped.Bip01_Spine2"]=Angle(sway*.4,recoil*.35,sway*.5+recoil),
            ["ValveBiped.Bip01_L_UpperArm"]=Angle(recoil*.5,0,(taunting and -75+sway or 0)-recoil),
            ["ValveBiped.Bip01_R_UpperArm"]=Angle(-recoil*.5,0,(taunting and 75+sway or 0)+recoil*.6)
        }) do local bone=e:LookupBone(name);if bone then e:ManipulateBoneAngles(bone,angle) end end
        e.LODWasTaunting=taunting;fakePosed[e]=recoiling and true or nil
    end
    local seated=e:GetNW2Int("LOD_WardenPhase",1)==2
    if e.LODWardenSeated==seated then return end
    e.LODWardenSeated=seated
    for _,side in ipairs({"L","R"}) do
        for suffix,amount in pairs({Thigh=-70,Calf=75}) do
            local bone=e:LookupBone("ValveBiped.Bip01_"..side.."_"..suffix)
            if bone then e:ManipulateBoneAngles(bone,Angle(0,0,seated and amount or 0)) end
        end
    end
end
local maskPink=Color(218,147,143)
local snoutPink=Color(238,166,158)
local innerPink=Color(148,69,75)
local maskDark=Color(43,25,30)
local fakePink=Color(187,147,129)
local fakeSnout=Color(205,166,142)
local tonguePink=Color(244,100,143)
function V:DrawPigMask(e,size)
    if e:GetNW2Bool("LOD_WardenHidden",false) then return end
    local attachment=e:LookupAttachment("eyes")
    local eyes=attachment and attachment>0 and e:GetAttachment(attachment)
    local pos,ang
    if eyes then pos,ang=eyes.Pos,eyes.Ang
    else
        local bone=e:LookupBone("ValveBiped.Bip01_Head1")
        local matrix=bone and e:GetBoneMatrix(bone)
        if not matrix then return end -- never float a mask at the actor origin
        pos,ang=matrix:GetTranslation(),e:GetAngles()
    end
    local f,r,u=ang:Forward(),ang:Right(),ang:Up()
    local center=pos+f*(3*size)-u*(2*size)
    local function point(x,y,z) return center+f*(x*size)+r*(y*size)+u*(z*size) end
    local segments=reduced() and 10 or 16
    local tell=self:Tell(e)
    local pink,snout=tell and fakePink or maskPink,tell and fakeSnout or snoutPink
    local wink=tell and CurTime()>=tell.wink and CurTime()<tell.wink+0.35
    render.SetColorMaterial()
    render.DrawSphere(center,8.8*size,segments,8,pink)
    -- Rounded, protruding snout with two dark nostrils; black eye apertures
    -- and folded triangular ears make the silhouette readable at a distance.
    render.DrawSphere(point(7,0,-2),4.7*size,segments,8,snout)
    for _,side in ipairs({-1,1}) do
        render.DrawSphere(point(11.1,side*1.8,-1.8),1.15*size,8,6,maskDark)
        if wink and side==(tell.eye==0 and -1 or 1) then
            local a,b,c,d=point(8.6,side*3.5-1.4,2.7),point(8.6,side*3.5+1.4,2.7),
                point(8.6,side*3.5+1.4,3.3),point(8.6,side*3.5-1.4,3.3)
            render.DrawQuad(a,b,c,d,maskDark);render.DrawQuad(d,c,b,a,maskDark)
        else render.DrawSphere(point(7.1,side*3.5,3.0),1.9*size,8,6,maskDark) end
        local a,b,c=point(0,side*5,6),point(-1,side*12,13),point(2,side*10,4)
        render.DrawQuad(a,b,c,c,pink);render.DrawQuad(c,b,a,a,pink)
        local ia,ib,ic=point(1,side*6,6),point(0,side*10.5,11.5),point(2.6,side*9.5,5)
        render.DrawQuad(ia,ib,ic,ic,innerPink);render.DrawQuad(ic,ib,ia,ia,innerPink)
    end
    if tell then
        local a,b,c,d=point(8,-1.2,-5),point(8,1.2,-5),point(11,1.2,-8),point(11,-1.2,-8)
        render.DrawQuad(a,b,c,d,tonguePink);render.DrawQuad(d,c,b,a,tonguePink)
        render.DrawSphere(point(11,0,-8),1.25*size,8,6,tonguePink)
    end
end
function V:Draw(e,size)
    if e:GetNW2String("LOD_Archetype","")~="warden" or e:GetNW2Bool("LOD_WardenHidden",false) then return end
    self:DrawPigMask(e,size)
    local phase=e:GetNW2Int("LOD_WardenPhase",1)
    local p=props[phase==2 and "toilet" or (phase==3 and "crowbar" or "")]
    if not IsValid(p) then return end
    local pos=e:GetPos();local ang=e:GetAngles()
    if phase==2 then
        p:SetPos(pos+e:GetForward()*(-5*size)+Vector(0,0,18*size));p:SetAngles(ang)
    else
        local bone=e:LookupBone("ValveBiped.Bip01_R_Hand")
        local mat=bone and e:GetBoneMatrix(bone)
        local hand=mat and mat:GetTranslation() or pos+e:GetForward()*14+Vector(0,0,40*size)
        local swing=math.Clamp((e:GetNW2Float("LOD_WardenSwing",0)-CurTime())/0.3,0,1)
        p:SetPos(hand);p:SetAngles(Angle(-70+120*swing,ang.y,ang.r))
    end
    if p.LODVisualSize~=size then p:SetModelScale(size,0);p.LODVisualSize=size end
    p:DrawModel()
end
hook.Add("Think","LOD_WardenPropsRetire",function()
    if tells and CurTime()>=tells.expires then V:ClearTells() end
    -- At most four previously recoiling clones; no world scan or extra hook per actor.
    for e in pairs(fakePosed) do
        if not IsValid(e) then fakePosed[e]=nil
        else
            local q=V:Tell(e)
            if not q or CurTime()>=q.hurtUntil then V:Pose(e) end
        end
    end
    if next(props) and (not state or not IsValid(state.actor) or CurTime()-state.received>2) then dispose() end
end)
hook.Add("ShutDown","LOD_WardenPropsShutdown",function() V:ClearTells();dispose() end)
