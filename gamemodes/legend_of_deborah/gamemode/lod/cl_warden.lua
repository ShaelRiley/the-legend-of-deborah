LOD.WardenPresentation=LOD.WardenPresentation or {}
local V=LOD.WardenPresentation
local glow=Material("sprites/light_glow02_add")
local beam=Material("cable/redlaser")
local blue=Color(110,185,255,230)
local gold=Color(255,170,60,255)
local state
local prepareProps
net.Receive("LOD_WardenState",function()
    if not net.ReadBool() then state=nil;return end
    local s={actor=net.ReadEntity(),health=net.ReadFloat(),maximum=net.ReadFloat(),phase=net.ReadUInt(2),hazards={},received=CurTime()}
    local n=net.ReadUInt(5)
    for i=1,n do s.hazards[i]={id=net.ReadUInt(16),bomb=net.ReadBool(),pos=net.ReadVector(),velocity=net.ReadVector(),expires=net.ReadFloat()} end
    state=s
    if prepareProps then prepareProps(s.phase) end
end)
surface.CreateFont("LOD_WardenTitle",{font="Trebuchet MS",size=26,weight=900})
surface.CreateFont("LOD_WardenPhase",{font="Trebuchet MS",size=17,weight=700})
hook.Add("HUDPaint","LOD_WardenHealth",function()
    local s=state;if not s or CurTime()-s.received>2 then return end
    local width=math.min(580,ScrW()*0.64);local x=(ScrW()-width)/2;local y=ScrH()*0.08
    draw.SimpleText("GORDON THE WARDEN","LOD_WardenTitle",ScrW()/2,y,Color(240,225,210),TEXT_ALIGN_CENTER)
    draw.RoundedBox(3,x,y+34,width,14,Color(10,10,18,225))
    draw.RoundedBox(3,x+2,y+36,(width-4)*math.Clamp(s.health/math.max(1,s.maximum),0,1),10,
        s.phase==3 and Color(240,75,55) or gold)
    local name=({"VANISHING VOLLEYS","TOILET BOMBER — WATCH THE FUSES","CROWBAR BERSERKER"})[s.phase]
    draw.SimpleText(name.."  ·  "..math.max(0,math.ceil(s.health)).." / "..math.ceil(s.maximum),
        "LOD_WardenPhase",ScrW()/2,y+54,Color(235,235,245),TEXT_ALIGN_CENTER)
end)
local function reduced()
    local c=GetConVar("lod_reduced_effects");return c and c:GetBool()
end
hook.Add("PostDrawTranslucentRenderables","LOD_WardenHazards",function(depth,sky)
    if depth or sky or not state or CurTime()-state.received>2 then return end
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
prepareProps=function(phase)
    local name=phase==2 and "toilet" or (phase==3 and "crowbar" or nil)
    for k,p in pairs(props) do if k~=name then if IsValid(p) then p:Remove() end;props[k]=nil end end
    if not name or IsValid(props[name]) then return end
    local model=phase==2 and "models/props_c17/FurnitureToilet001a.mdl" or "models/weapons/w_crowbar.mdl"
    local p=ClientsideModel(model,RENDERGROUP_OPAQUE)
    if IsValid(p) then p:SetNoDraw(true);props[name]=p end
end
function V:Pose(e)
    if e:GetNW2String("LOD_Archetype", "")~="warden" then return end
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
    render.SetColorMaterial()
    render.DrawSphere(center,8.8*size,segments,8,maskPink)
    -- Rounded, protruding snout with two dark nostrils; black eye apertures
    -- and folded triangular ears make the silhouette readable at a distance.
    render.DrawSphere(point(7,0,-2),4.7*size,segments,8,snoutPink)
    for _,side in ipairs({-1,1}) do
        render.DrawSphere(point(11.1,side*1.8,-1.8),1.15*size,8,6,maskDark)
        render.DrawSphere(point(7.1,side*3.5,3.0),1.9*size,8,6,maskDark)
        local a,b,c=point(0,side*5,6),point(-1,side*12,13),point(2,side*10,4)
        render.DrawQuad(a,b,c,c,maskPink);render.DrawQuad(c,b,a,a,maskPink)
        local ia,ib,ic=point(1,side*6,6),point(0,side*10.5,11.5),point(2.6,side*9.5,5)
        render.DrawQuad(ia,ib,ic,ic,innerPink);render.DrawQuad(ic,ib,ia,ia,innerPink)
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
    if next(props) and (not state or not IsValid(state.actor) or CurTime()-state.received>2) then dispose() end
end)
hook.Add("ShutDown","LOD_WardenPropsShutdown",dispose)
