-- One bounded presentation/HUD stream. All mechanics remain server-side.
LOD.BossPresentation=LOD.BossPresentation or {}
local V=LOD.BossPresentation
if V.Dispose then V:Dispose() end
V.Modules=V.Modules or {};V.Props={}
local state,ghost
local glow=Material('sprites/light_glow02_add');local beam=Material('cable/redlaser')
local gold=Color(245,192,90);local red=Color(245,80,55)
local function vector(v) return v and Vector(tonumber(v.x) or 0,tonumber(v.y) or 0,tonumber(v.z) or 0) or Vector(0,0,0) end
local function angle(v) return v and Angle(tonumber(v.p) or 0,tonumber(v.y) or 0,tonumber(v.r) or 0) or Angle(0,0,0) end
local function reduced() local c=GetConVar('lod_reduced_effects');return c and c:GetBool() end
function V:Dispose()
    for k,e in pairs(self.Props or {}) do if IsValid(e) then e:Remove() end;self.Props[k]=nil end
    if IsValid(ghost) then ghost:Remove() end;ghost=nil;state=nil
end
function V:Prop(k,model)
    if IsValid(self.Props[k]) then return self.Props[k] end
    if table.Count(self.Props)>=8 then return end
    local e=ClientsideModel(model,RENDERGROUP_OPAQUE);if IsValid(e) then e:SetNoDraw(true);self.Props[k]=e;return e end
end
net.Receive('LOD_BossState',function()
    if not net.ReadBool() then V:Dispose();return end
    local n=net.ReadUInt(16);if n==0 or n>32768 then V:Dispose();return end
    local raw=util.Decompress(net.ReadData(n),131072);if not raw or #raw>131072 then V:Dispose();return end
    local s=util.JSONToTable(raw);if type(s)~='table' or not LOD.BossRegistry.Primary[s.id] or s.id=='warden'
        or type(s.serial)~='number' or type(s.phase)~='number' or type(s.maximum)~='number' then V:Dispose();return end
    if not state or state.serial~=s.serial or state.id~=s.id then V:Dispose() end
    s.position=vector(s.position);s.angles=angle(s.angles);if s.deathTarget then s.deathTarget=vector(s.deathTarget) end;if s.deathDestination then s.deathDestination=vector(s.deathDestination) end;s.received=CurTime();s.entity=Entity(s.actor or 0)
    for _,list in ipairs({s.warnings or {},s.zones or {}}) do
        for i=#list,25,-1 do list[i]=nil end
        for _,q in ipairs(list) do q.pos=vector(q.pos);if q.finish then q.finish=vector(q.finish) end end
    end
    for i,q in ipairs(s.beacons or {}) do if i<=2 then q.pos=vector(q.pos) end end
    state=s;local m=V.Modules[s.id]
    if m and m.Prepare then m:Prepare(s) end
    if s.dead and CurTime()<(s.deathAt or 0)+(s.deathDuration or 4) and not IsValid(ghost) and type(s.model)=='string' and #s.model<180 then
        ghost=ClientsideModel(s.model,RENDERGROUP_OPAQUE)
        if IsValid(ghost) then ghost:SetNoDraw(true);ghost:SetPos(s.position);ghost:SetAngles(s.angles)
            ghost:SetNW2String('LOD_BossId',s.id);ghost:SetNW2String('LOD_BossAction',s.action or '');ghost:SetNW2Float('LOD_SizeScale',s.size or 1)
            local v=s.visual or {};if v.color then ghost:SetColor(Color(v.color.r or 255,v.color.g or 255,v.color.b or 255,v.color.a or 255)) end
            for k,value in pairs(v.bools or {}) do ghost:SetNW2Bool(k,value==true) end
            for k,value in pairs(v.strings or {}) do ghost:SetNW2String(k,tostring(value):sub(1,160)) end
            for k,value in pairs(v.numbers or {}) do ghost:SetNW2Int(k,tonumber(value) or 0) end
            if s.id=='chuck' then ghost:SetNW2Bool('LOD_Beaver',true) end
        end
    end
end)
surface.CreateFont('LOD_BossTitle',{font='Trebuchet MS',size=26,weight=900})
surface.CreateFont('LOD_BossDetail',{font='Trebuchet MS',size=17,weight=700})
hook.Add('HUDPaint','LOD_ModularBossHUD',function()
    local s=state;if not s or CurTime()-s.received>2 then return end
    local p=LocalPlayer();if not IsValid(p) then return end
    local y=ScrH()*.075;local width=math.min(630,ScrW()*.72);local x=(ScrW()-width)/2
    if not s.dead then
        draw.SimpleText(string.upper(s.name or LOD.BossRegistry.Names[s.id]),'LOD_BossTitle',ScrW()/2,y,gold,TEXT_ALIGN_CENTER)
        draw.RoundedBox(3,x,y+33,width,14,Color(10,10,18,225))
        draw.RoundedBox(3,x+2,y+35,(width-4)*math.Clamp(s.health/math.max(1,s.maximum),0,1),10,s.phase==3 and red or gold)
        draw.SimpleText(tostring(s.phaseName or '')..'  '..math.max(0,math.ceil(s.health))..' / '..math.ceil(s.maximum),'LOD_BossDetail',ScrW()/2,y+51,color_white,TEXT_ALIGN_CENTER)
        draw.SimpleText(tostring(s.detail or ''):sub(1,180),'LOD_BossDetail',ScrW()/2,y+72,gold,TEXT_ALIGN_CENTER)
    elseif CurTime()<(s.deathAt or 0)+(s.deathDuration or 4) then
        draw.SimpleText(tostring(s.action or ''):sub(1,120),'LOD_BossTitle',ScrW()/2,y,gold,TEXT_ALIGN_CENTER)
    end
    for i,q in ipairs(s.beacons or {}) do if i<=2 then
        local point=(q.pos+Vector(0,0,70)):ToScreen()
        local x=math.Clamp(point.x,45,ScrW()-45);local y=math.Clamp(point.y,150,ScrH()-90)
        draw.SimpleText('▼ '..tostring(q.label or 'BUTTON'),'LOD_BossTitle',x,y,Color(255,65,55),TEXT_ALIGN_CENTER)
        draw.SimpleText(math.ceil(p:GetPos():Distance(q.pos)/LOD.Config.Maze.CellSize)..' squares','LOD_BossDetail',x,y+28,color_white,TEXT_ALIGN_CENTER)
    end end
    local carry=p:GetNW2String('LOD_BossCarry','')
    if carry~='' then draw.SimpleText(carry,'LOD_BossTitle',ScrW()/2,ScrH()*.76,gold,TEXT_ALIGN_CENTER) end
end)
function V:State(e)
    if not state or CurTime()-state.received>2 or e:GetNW2String('LOD_BossId','')~=state.id
        or e~=ghost and e:GetNW2Int('LOD_BossSerial',0)~=state.serial then return end
    return state
end
function V:DrawActor(e,force)
    local s=force or self:State(e)
    if not s then e:DrawModel();return end
    local size=math.Clamp(e:GetNW2Float('LOD_SizeScale',s.size or 1),.1,8)
    local model=e:GetModel();local signature=model..':'..size
    if e.LODBossVisualSignature~=signature then
        e.LODBossVisualSignature=signature
        local mins,maxs=util.GetModelBounds(model)
        mins,maxs=mins or Vector(-16,-16,0),maxs or Vector(16,16,72)
        local matrix=Matrix();matrix:Scale(Vector(size,size,size));matrix:SetTranslation(Vector(0,0,-mins.z*size))
        e:EnableMatrix('RenderMultiply',matrix)
        local lo,hi=mins*size,maxs*size;e:SetRenderBounds(Vector(lo.x-80,lo.y-80,-80),Vector(hi.x+80,hi.y+80,(maxs.z-mins.z)*size+120))
    end
    local m=self.Modules[s.id];local pose=m and m.Pose and m:Pose(e,size,s)
    if pose then if pose.angles then e:SetRenderAngles(pose.angles) end;if pose.offset then e:SetRenderOrigin(e:GetPos()+pose.offset) end end
    e:DrawModel()
    if m and m.Draw then m:Draw(e,size,s) end
    if e==ghost and m and m.Death then m:Death(e,size,s) end
    if pose then e:SetRenderAngles();e:SetRenderOrigin() end
end
function V:DrawObject(e)
    if not state or CurTime()-state.received>2 then return end
    local m=self.Modules[state.id];if m and m.DrawObject then m:DrawObject(e,e:GetModelScale(),state) end
end
local function mark(q,active)
    if not q.pos or not q.expires or CurTime()>q.expires or EyePos():DistToSqr(q.pos)>7000^2 then return end
    local color=active and Color(255,90,55,160) or Color(255,210,85,210)
    if q.color then color=Color(q.color.r or color.r,q.color.g or color.g,q.color.b or color.b,q.color.a or color.a) end
    local p=q.pos+Vector(0,0,4);render.SetMaterial(beam)
    if q.finish and (q.shape=='lane' or q.shape=='rect') then
        local d=(q.finish-q.pos):GetNormalized();local side=Vector(-d.y,d.x,0)*(q.width and q.width*.5 or q.radius or 48)
        local a,b,c,dest=p+side,p-side,q.finish+Vector(0,0,4)-side,q.finish+Vector(0,0,4)+side
        render.DrawBeam(a,b,3,0,1,color);render.DrawBeam(b,c,3,0,1,color);render.DrawBeam(c,dest,3,0,1,color);render.DrawBeam(dest,a,3,0,1,color)
    else
        local segments=reduced() and 12 or 24;local r=math.Clamp(q.radius or 64,4,1500)
        for i=1,segments do local a,b=(i-1)*math.pi*2/segments,i*math.pi*2/segments
            render.DrawBeam(p+Vector(math.cos(a)*r,math.sin(a)*r,0),p+Vector(math.cos(b)*r,math.sin(b)*r,0),3,0,1,color)
        end
    end
end
hook.Add('PostDrawTranslucentRenderables','LOD_ModularBossMarks',function(depth,sky)
    if depth or sky or not state or CurTime()-state.received>2 then return end
    for _,q in ipairs(state.warnings or {}) do mark(q,false) end
    for _,q in ipairs(state.zones or {}) do mark(q,CurTime()>=(q.ready or 0)) end
    for i,q in ipairs(state.beacons or {}) do if i<=2 then
        render.SetMaterial(beam);render.DrawBeam(q.pos,q.pos+Vector(0,0,260),14,0,1,Color(255,75,50,220))
        render.SetMaterial(glow);render.DrawSprite(q.pos+Vector(0,0,65),70,70,Color(255,100,60,230))
    end end
    if state.dead and IsValid(ghost) and CurTime()<(state.deathAt or 0)+(state.deathDuration or 4)
        and (not IsValid(state.entity) or state.entity:GetNoDraw()) then
        V:DrawActor(ghost,state)
    end
end)
hook.Add('Think','LOD_ModularBossPresentationLifetime',function()
    if state and CurTime()-state.received>2 then V:Dispose() end
    if state and IsValid(ghost) and CurTime()>=(state.deathAt or 0)+(state.deathDuration or 4) then ghost:Remove();ghost=nil end
end)
for _,event in ipairs({'PostCleanupMap','ShutDown'}) do hook.Add(event,'LOD_ModularBossPresentationCleanup',function() V:Dispose() end) end
