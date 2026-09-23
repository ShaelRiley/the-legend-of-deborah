if LOD.LoopAudio then LOD.LoopAudio:StopGroup('gas') end
LOD.EnemyRosterVisual={}
local V=LOD.EnemyRosterVisual
local glow=Material("sprites/light_glow02_add")
local beam=Material("cable/redlaser")
local colors={flamer=Color(255,105,25),bigcrab=Color(255,105,25),arccaster=Color(110,190,255),
    lurker=Color(110,240,55),beamsweeper=Color(120,225,255),sentry=Color(255,75,45),razor=Color(255,165,60),
    gaoler=Color(90,180,255),silencer=Color(255,245,170),repulsor=Color(220,165,70),
    stitcher=Color(90,230,150),bulwark=Color(100,150,240),cantor=Color(235,180,70),
    pincer=Color(210,100,235),harrier=Color(65,215,215),waylayer=Color(245,145,65),
    caromer=Color(90,210,240),reeler=Color(235,180,95),forker=Color(150,240,180),
    pavise=Color(165,190,215),repriser=Color(230,100,180),redliner=Color(215,65,45)}
local projectiles,received={},0
local gas=Material("particle/particle_smokegrenade")
local gasColor=Color(70,180,65,45)
function V:Gas(e)
    if not e:GetNW2Bool("LOD_RosterAlive",false) then return end
    local pos=e:GetPos()
    if pos:DistToSqr(EyePos())>1600^2 then return end
    if LOD.LoopAudio then LOD.LoopAudio:Touch('gas',e,'ambient/gas/steam_loop1.wav',.18,85,62,.35) end
    local mc=LOD.Config.Maze;local origin=mc.Origin
    local x=math.floor((pos.x-origin.x)/mc.CellSize+(mc.Width+1)*.5+.5)
    local y=math.floor((pos.y-origin.y)/mc.CellSize+(mc.Height+1)*.5+.5)
    local center=Vector((x-(mc.Width+1)*.5)*mc.CellSize+origin.x,(y-(mc.Height+1)*.5)*mc.CellSize+origin.y,pos.z)
    render.SetMaterial(gas)
    local cv=GetConVar("lod_reduced_effects");local low=cv and cv:GetBool()
    for i=1,(low and 8 or 16) do
        local a=i*2.4+CurTime()*.12;local radius=40+(i%4)*25
        local p=center+Vector(math.cos(a)*radius,math.sin(a)*radius,28+(i%3)*28)
        render.DrawSprite(p,100,80,gasColor)
    end
end
net.Receive("LOD_RosterProjectiles",function()
    local count=net.ReadUInt(7);local list={}
    for i=1,count do list[i]={pos=net.ReadVector(),velocity=net.ReadVector(),kind=net.ReadUInt(2)} end
    projectiles=list;received=CurTime()
end)
hook.Add("PostDrawTranslucentRenderables","LOD_RosterProjectiles",function(depth,sky)
    if depth or sky or CurTime()-received>.3 then return end
    for _,q in ipairs(projectiles) do
        local pos=q.pos+q.velocity*math.min(.1,CurTime()-received)
        if EyePos():DistToSqr(pos)<2400^2 then
            local c=q.kind==3 and colors.reeler or (q.kind==1 and colors.lurker or (q.kind==2 and colors.silencer or colors.sentry))
            local wide=q.kind~=0
            render.SetMaterial(glow);render.DrawSprite(pos,wide and 24 or 10,wide and 24 or 10,c)
            render.SetMaterial(beam);render.DrawBeam(pos-q.velocity:GetNormalized()*24,pos,wide and 5 or 2,0,1,c)
            if q.kind==3 and q.velocity:LengthSqr()==0 then
                -- A hollow diamond marks Reeler's brief turnaround, even at reduced effects.
                local side=(EyePos()-pos):Angle():Right()*13;local up=Vector(0,0,13)
                render.DrawBeam(pos+up,pos+side,2,0,1,c);render.DrawBeam(pos+side,pos-up,2,0,1,c)
                render.DrawBeam(pos-up,pos-side,2,0,1,c);render.DrawBeam(pos-side,pos+up,2,0,1,c)
            end
        end
    end
end)
-- Support tells are semantic geometry, retained in reduced-effects mode. They
-- use existing entity snapshots; no per-frame actor scans or particle emitters.
local supportColors={colors.stitcher,colors.bulwark,colors.cantor}
local supportRecipients={{2,"SupportGuard"},{3,"SupportRally"}}
local supportKinds={stitcher=1,bulwark=2,cantor=3}
local function supportIcon(kind,center,color,width)
    local side=(EyePos()-center):Angle():Right();local up=Vector(0,0,1)
    render.SetMaterial(beam)
    if kind==1 then
        render.DrawBeam(center-side*11,center+side*11,width,0,1,color)
        render.DrawBeam(center-up*11,center+up*11,width,0,1,color)
    elseif kind==2 then
        local points={center-side*13+up*12,center+side*13+up*12,
            center+side*11-up*4,center-up*17,center-side*11-up*4}
        for i=1,#points do render.DrawBeam(points[i],points[i%#points+1],width,0,1,color) end
    else
        for i=0,1 do
            local top=center+up*(14-i*12)
            render.DrawBeam(top-side*10-up*10,top,width,0,1,color)
            render.DrawBeam(top,top+side*10-up*10,width,0,1,color)
        end
    end
end
function V:Support(e)
    if e:GetPos():DistToSqr(EyePos())>2400^2 then return end
    local now=CurTime();local origin=e:WorldSpaceCenter()+Vector(0,0,26)
    local id=e:GetNW2String("LOD_Archetype","")
    local kind=supportKinds[id] and e:GetNW2Int("LOD_SupportKind",0) or 0
    if kind>=1 and kind<=3 then
        local color=supportColors[kind]
        local charging=now<e:GetNW2Float("LOD_SupportReady",0)
        supportIcon(kind,origin,color,charging and 2 or 4)
        local target=e:GetNW2Entity("LOD_SupportTarget")
        if IsValid(target) then
            render.SetMaterial(beam)
            render.DrawBeam(origin,target:WorldSpaceCenter(),charging and 1 or 3,0,1,color)
            if kind==1 then supportIcon(1,target:WorldSpaceCenter()+Vector(0,0,30),color,2) end
        end
    end
    local healed=e:GetNW2Float("LOD_SupportHealedAt",0)
    if healed>0 and now>=healed and now-healed<.4 then supportIcon(1,origin,colors.stitcher,4) end
    for _,entry in ipairs(supportRecipients) do
        local id,suffix=entry[1],entry[2]
        local source=e:GetNW2Entity("LOD_"..suffix.."Source")
        if e:GetNW2Bool("LOD_Status"..suffix,false)
            and now<e:GetNW2Float("LOD_Status"..suffix.."Until",0) and IsValid(source) then
            local color=supportColors[id]
            supportIcon(id,origin,color,3)
            render.SetMaterial(beam)
            render.DrawBeam(source:WorldSpaceCenter(),e:WorldSpaceCenter(),2,0,1,color)
        end
    end
end
-- Finite tactical tells share the entity renderer and remain legible with
-- reduced effects. A destination is an intention, never a damaging floor mark.
function V:Pursuit(e)
    local mode=e:GetNW2Int("LOD_PursuitMode",0)
    local now=CurTime()
    if mode<1 or mode>3 or now>=e:GetNW2Float("LOD_PursuitExpires",0)
        or e:GetPos():DistToSqr(EyePos())>2400^2 then return end
    local color=({colors.pincer,colors.harrier,colors.waylayer})[mode]
    local center=e:WorldSpaceCenter()+Vector(0,0,30)
    local side=(EyePos()-center):Angle():Right();local up=Vector(0,0,1)
    render.SetMaterial(beam)
    local function line(a,b) render.DrawBeam(a,b,3,0,1,color) end
    if mode==1 then
        for _,sign in ipairs({-1,1}) do
            local tip=center+side*sign*15
            line(tip,center+up*10);line(tip,center-up*10)
        end
    elseif mode==2 then
        for offset=0,1 do
            local tip=center+side*(offset*12-12)
            line(tip,tip+side*10+up*10);line(tip,tip+side*10-up*10)
        end
    else
        line(center-side*14,center+side*14);line(center-up*14,center+up*14)
        local destination=e:GetNW2Vector("LOD_PursuitDestination",e:GetPos())+Vector(0,0,5)
        local radius=now<e:GetNW2Float("LOD_PursuitReady",0) and 30 or 22
        local points={Vector(-radius,-radius,0),Vector(radius,-radius,0),Vector(radius,radius,0),Vector(-radius,radius,0)}
        for i=1,4 do line(destination+points[i],destination+points[i%4+1]) end
    end
end
-- Self-defense is visible as geometry, not paint alone. Each tell has a server
-- deadline, so a missed clear packet cannot leave a permanent warning.
function V:Reaction(e)
    local mode=e:GetNW2Int("LOD_ReactionMode",0)
    local stage=e:GetNW2Int("LOD_ReactionStage",0)
    local now=CurTime()
    if mode~=1 and stage==2 and e:GetNW2Int("LOD_RosterAttack",0)==2 then stage=3 end
    if mode<1 or mode>3 or stage<1 or stage>5 or not e:GetNW2Bool("LOD_RosterAlive",false)
        or now>=e:GetNW2Float("LOD_ReactionUntil",0)
        or e:GetPos():DistToSqr(EyePos())>2400^2 then return end
    local color=({colors.pavise,colors.repriser,colors.redliner})[mode]
    local center=e:WorldSpaceCenter()+Vector(0,0,30)
    local side=(EyePos()-center):Angle():Right();local up=Vector(0,0,1)
    local width=stage==3 and 4 or 2
    render.SetMaterial(beam)
    local function line(a,b) render.DrawBeam(a,b,width,0,1,color) end
    if stage==4 then
        -- Two open bars identify recovery, distinct from an imminent strike.
        for _,offset in ipairs({-6,6}) do
            line(center-side*13+up*offset,center-side*3+up*offset)
            line(center+side*3+up*offset,center+side*13+up*offset)
        end
    elseif mode==1 then
        -- The plate and ground arc remain aligned with the frozen guard yaw.
        local yaw=e:GetNW2Float("LOD_ReactionYaw",0)
        local forward=Angle(0,yaw,0):Forward();local right=Angle(0,yaw,0):Right()
        local plate=e:WorldSpaceCenter()+forward*24
        local points={plate-right*16+up*17,plate+right*16+up*17,
            plate+right*13-up*7,plate-up*22,plate-right*13-up*7}
        for i=1,#points do line(points[i],points[i%#points+1]) end
        local ground=e:GetPos()+Vector(0,0,5)
        for i=1,8 do
            local a=Angle(0,yaw-60+(i-1)*15,0):Forward()*52
            local b=Angle(0,yaw-60+i*15,0):Forward()*52
            line(ground+a,ground+b)
        end
    elseif mode==2 then
        -- A hooked return arrow announces retaliation, not reflected damage.
        local left=center-side*13;local right=center+side*13
        line(left+up*10,right+up*10);line(right+up*10,right-up*10)
        line(right-up*10,left-up*10)
        line(left-up*10,left+side*8-up*2);line(left-up*10,left+side*8-up*18)
    else
        -- Jagged forward chevron: wounded approach or committed lunge.
        line(center-side*15-up*12,center+side*10)
        line(center+side*10,center-side*15+up*12)
        line(center-side*15+up*12,center-side*5)
        line(center-side*5,center-side*15-up*12)
        if stage==2 or stage==3 then
            local origin=e:GetNW2Vector("LOD_RosterOrigin",e:GetPos())
            local aim=e:GetNW2Vector("LOD_RosterAim",origin)
            local dir=aim-origin;dir.z=0
            if dir:LengthSqr()>0 then
                local from=Vector(origin.x,origin.y,e:GetPos().z+5)
                line(from,from+dir:GetNormalized()*507)
            end
        end
    end
end
-- The visible polyline is exactly the frozen server trajectory, including the
-- bank and both parallel lane origins. No client geometry guess or target tracking.
function V:Pattern(e)
    local mode=e:GetNW2Int("LOD_PatternMode",0)
    if mode<1 or mode>3 or not e:GetNW2Bool("LOD_RosterAlive",false)
        or e:GetNW2Int("LOD_RosterAttack",0)==0 or CurTime()>=e:GetNW2Float("LOD_PatternUntil",0) then return end
    local color=({colors.caromer,colors.reeler,colors.forker})[mode]
    local a=e:GetNW2Vector("LOD_PatternStart",e:GetPos());local b=e:GetNW2Vector("LOD_PatternEnd",a)
    local c=e:GetNW2Vector("LOD_PatternSecondStart",b);local d=e:GetNW2Vector("LOD_PatternSecondEnd",c)
    render.SetMaterial(beam)
    render.DrawBeam(a,b,2,0,1,color);render.DrawBeam(c,d,2,0,1,color)
    if mode==2 then
        local dir=(b-a):GetNormalized();local side=Vector(-dir.y,dir.x,0)
        local tip=b-dir*20
        render.DrawBeam(tip,tip+dir*16+side*12,3,0,1,color)
        render.DrawBeam(tip,tip+dir*16-side*12,3,0,1,color)
    elseif mode==1 and c:DistToSqr(d)>0 then
        -- Diamond at the bank distinguishes a bend from a second unrelated shot.
        local side=(EyePos()-b):Angle():Right()*10;local up=Vector(0,0,10)
        render.DrawBeam(b+up,b+side,2,0,1,color);render.DrawBeam(b+side,b-up,2,0,1,color)
        render.DrawBeam(b-up,b-side,2,0,1,color);render.DrawBeam(b-side,b+up,2,0,1,color)
    end
end
function V:Draw(e,size)
    self:Support(e)
    self:Pursuit(e)
    self:Reaction(e)
    if e:GetNW2String("LOD_Archetype","")=="nodule" then self:Gas(e);return end
    local stage=e:GetNW2Int("LOD_RosterAttack",0)
    if stage==0 or e:GetPos():DistToSqr(EyePos())>2400^2 then return end
    local id=e:GetNW2String("LOD_Archetype","");local color=colors[id];if not color then return end
    if id=="caromer" or id=="reeler" or id=="forker" then self:Pattern(e);return end
    local origin=e:GetNW2Vector("LOD_RosterOrigin",e:GetPos())
    local aim=e:GetNW2Vector("LOD_RosterAim",origin)
    local range=e:GetNW2Float("LOD_RosterRange",280)
    local cv=GetConVar("lod_reduced_effects");local low=cv and cv:GetBool()
    local pulse=stage==1 and (12+4*math.sin(CurTime()*16)) or 24
    render.SetMaterial(glow);render.DrawSprite(origin,pulse,pulse,color)
    if id=="arccaster" or id=="gaoler" or id=="repulsor" then
        local radius=id=="repulsor" and range or 112
        render.SetColorMaterial()
        if LOD.MagicArea then LOD.MagicArea:Disc(aim,radius,Vector(1,0,0),Vector(0,1,0),Color(color.r,color.g,color.b,102)) end
        render.SetMaterial(beam)
        for i=1,24 do
            local a,b=(i-1)*math.pi/12,i*math.pi/12
            local p=aim+Vector(math.cos(a)*radius,math.sin(a)*radius,0)
            local q=aim+Vector(math.cos(b)*radius,math.sin(b)*radius,0)
            render.DrawBeam(p,q,3,0,1,color)
            if stage==2 and (not low or i%4==0) then render.DrawBeam(p,p+Vector(0,0,85),4,0,1,color) end
        end
    elseif id=="beamsweeper" then
        local yaw=(aim-origin):Angle().y
        local fraction=math.Clamp((CurTime()-e:GetNW2Float("LOD_RosterRelease",CurTime()))/1.2,0,1)
        local angle=stage==2 and yaw-45+90*fraction or yaw-45
        render.SetMaterial(beam)
        if stage==1 then
            render.DrawBeam(origin,origin+Angle(0,yaw+45,0):Forward()*range,1,0,1,color)
            render.DrawBeam(origin,origin+Angle(0,yaw,0):Forward()*range,1,0,1,color)
        end
        render.DrawBeam(origin,origin+Angle(0,angle,0):Forward()*range,stage==2 and 6 or 2,0,1,color)
    elseif id=="flamer" or id=="bigcrab" then
        local dir=(aim-origin):GetNormalized();local right=dir:Angle():Right();local up=dir:Angle():Up()
        render.SetMaterial(beam)
        for _,sign in ipairs({-1,1}) do render.DrawBeam(origin,origin+(dir*math.cos(math.rad(28))+right*sign*math.sin(math.rad(28)))*range,2,0,1,color) end
        if stage==2 then
            render.SetMaterial(glow)
            local n=low and 8 or 20
            for i=1,n do
                local f=((CurTime()*1.8+i/n)%1);local distance=range*f
                local p=origin+dir*distance+(right*math.sin(i*2.4)+up*math.cos(i*2.4))*distance*.24
                render.DrawSprite(p,12+distance*.32,16+distance*.4,Color(255,100+90*(1-f),20,200*(1-f)))
            end
        end
    else
        render.SetMaterial(beam);render.DrawBeam(origin,aim,stage==2 and 4 or 1,0,1,color)
    end
end
