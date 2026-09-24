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
    wirewright=Color(80,220,235),snarer=Color(100,165,255),cordon=Color(245,150,60),
    pavise=Color(165,190,215),repriser=Color(230,100,180),redliner=Color(215,65,45),
    afterburst=Color(255,150,65),carrion=Color(160,220,95),
    towline=Color(70,225,205),screenwright=Color(110,175,255),
    absolver=Color(170,240,225),exactor=Color(230,95,115),
    outrider=Color(225,170,80),conductor=Color(150,190,250),
    siphoner=Color(185,115,235),accumulator=Color(235,205,95),
    fusilier=Color(225,135,75),bombardier=Color(210,175,80),
    halter=Color(235,145,85),pacer=Color(90,215,225),
    interposer=Color(125,175,225),mourner=Color(195,125,215),
    censor=Color(210,170,110),surveyor=Color(110,215,190),
    relay=Color(120,205,235),lacemaker=Color(235,155,205),
    listener=Color(235,195,100),shy=Color(175,150,230),
    censer=Color(220,150,60),trailmaker=Color(130,195,85),
    reaper=Color(220,155,100),drubber=Color(245,100,70),fencer=Color(165,210,245)}
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
local supportColors={colors.stitcher,colors.bulwark,colors.cantor,colors.absolver}
local supportRecipients={{2,"SupportGuard"},{3,"SupportRally"}}
local supportKinds={stitcher=1,bulwark=2,cantor=3,absolver=4}
local function supportIcon(kind,center,color,width)
    local side=(EyePos()-center):Angle():Right();local up=Vector(0,0,1)
    render.SetMaterial(beam)
    if kind==1 then
        render.DrawBeam(center-side*11,center+side*11,width,0,1,color)
        render.DrawBeam(center-up*11,center+up*11,width,0,1,color)
    elseif kind==4 then
        local points={center+up*14,center+side*12,center-up*14,center-side*12}
        for i=1,4 do render.DrawBeam(points[i],points[i%4+1],width,0,1,color) end
        render.DrawBeam(center-side*16-up*10,center+side*16+up*10,width,0,1,color)
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
    if kind==4 and (not e:GetNW2Bool("LOD_RosterAlive",false) or now>=e:GetNW2Float("LOD_SupportReady",0)+.2) then kind=0 end
    if kind>=1 and kind<=4 then
        local color=supportColors[kind]
        local charging=now<e:GetNW2Float("LOD_SupportReady",0)
        supportIcon(kind,origin,color,charging and 2 or 4)
        local target=e:GetNW2Entity("LOD_SupportTarget")
        if IsValid(target) then
            render.SetMaterial(beam)
            render.DrawBeam(origin,target:WorldSpaceCenter(),charging and 1 or 3,0,1,color)
            if kind==1 or kind==4 then supportIcon(kind,target:WorldSpaceCenter()+Vector(0,0,30),color,2) end
            if kind==4 then
                local fraction=math.Clamp((e:GetNW2Float("LOD_SupportReady",0)-now)/1.5,0,1)
                render.DrawBeam(origin+Vector(-24,0,24),origin+Vector(-24+48*fraction,0,24),3,0,1,color)
            end
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
-- B6 uses frozen floor geometry from the existing actor snapshot. The same
-- boundaries, height posts and countdowns survive reduced effects unchanged.
-- No props, particles, lights, actor scan or separate render hook are needed.
function V:Trap(e)
    local mode=e:GetNW2Int("LOD_TrapMode",0)
    local stage=e:GetNW2Int("LOD_RosterAttack",0);local now=CurTime()
    local snap=e:GetNW2Float("LOD_TrapSnap",0)
    if mode<1 or mode>3 or stage==0 or not e:GetNW2Bool("LOD_RosterAlive",false)
        or now>=e:GetNW2Float("LOD_TrapUntil",0) or (mode==2 and snap>0 and now>=snap)
        or e:GetPos():DistToSqr(EyePos())>2400^2 then return end
    local color=({colors.wirewright,colors.snarer,colors.cordon})[mode]
    local width=stage==1 and 2 or 4
    local a=e:GetNW2Vector("LOD_TrapA",e:GetPos())
    local b=e:GetNW2Vector("LOD_TrapB",a)
    render.SetMaterial(beam)
    local function line(p,q,w) render.DrawBeam(p,q,w or width,0,1,color) end
    local function circle(radius)
        for i=1,24 do
            local from,to=(i-1)*math.pi/12,i*math.pi/12
            line(a+Vector(math.cos(from)*radius,math.sin(from)*radius,0),
                a+Vector(math.cos(to)*radius,math.sin(to)*radius,0))
        end
    end
    if mode==1 then
        local delta=b-a;delta.z=0;local dir=delta:GetNormalized()
        local right=Vector(-dir.y,dir.x,0);local side=right*14;local up=Vector(0,0,45)
        -- Endpoint posts reach floor+48; the narrow footprint shows the full
        -- collision width. The upper rail makes the jumpable height explicit.
        line(a,b);line(a-side,b-side);line(a+side,b+side)
        for i=1,6 do
            local p,q=(i-1)*math.pi/6,i*math.pi/6
            line(a+(right*math.cos(p)-dir*math.sin(p))*14,
                a+(right*math.cos(q)-dir*math.sin(q))*14)
            line(b+(right*math.cos(p)+dir*math.sin(p))*14,
                b+(right*math.cos(q)+dir*math.sin(q))*14)
        end
        line(a,a+up);line(b,b+up);line(a+up,b+up,1)
    elseif mode==2 then
        circle(72)
        if snap>0 then
            -- Four inward teeth announce the single impending snap. The bar
            -- drains against its fixed deadline, never a local restart timer.
            for i=0,3 do
                local angle=i*math.pi*.5;local dir=Vector(math.cos(angle),math.sin(angle),0)
                line(a+dir*72,a+dir*54,5)
            end
            local left=a+Vector(-24,0,32)
            line(left,left+Vector(48*math.Clamp((snap-now)/1.25,0,1),0,0),5)
        end
    else
        -- Unfilled concentric boundaries preserve the safe center. Short
        -- outer posts show the floor+72 upper limit without filling the ring.
        circle(80);circle(160)
        for i=0,3 do
            local angle=i*math.pi*.5
            local p=a+Vector(math.cos(angle)*160,math.sin(angle)*160,0)
            line(p,p+Vector(0,0,69),1)
        end
    end
    if now<e:GetNW2Float("LOD_TrapReady",0) then
        -- Hollow diamond denotes arming; live geometry becomes thicker.
        local center=(a+b)*.5+Vector(0,0,60)
        local side=Vector(0,10,0);local up=Vector(0,0,10)
        line(center+up,center+side);line(center+side,center-up)
        line(center-up,center-side);line(center-side,center+up)
    end
end
-- Frozen melee footprints convey spacing, not a target-following prediction.
-- Drubber's outer beat remains visible during the first warning; Fencer's
-- dashed retreat is movement intent, followed by the actual thrust footprint.
-- Geometry and fixed-deadline countdowns are identical at either effects level.
function V:Melee(e)
    local mode=e:GetNW2Int("LOD_MeleeMode",0);local now=CurTime()
    if mode<1 or mode>4 or not e:GetNW2Bool("LOD_RosterAlive",false)
        or e:GetNW2Int("LOD_RosterAttack",0)==0 or now>=e:GetNW2Float("LOD_MeleeUntil",0)
        or e:GetPos():DistToSqr(EyePos())>2400^2 then return end
    local origin=e:GetNW2Vector("LOD_MeleeOrigin",e:GetPos())+Vector(0,0,3)
    local dir=e:GetNW2Vector("LOD_MeleeDirection",Vector(1,0,0))
    local side=Vector(-dir.y,dir.x,0)
    local ready=e:GetNW2Float("LOD_MeleeReady",0)
    local id=e:GetNW2String("LOD_Archetype","")
    local color=id=="outrider" and colors.outrider or ({colors.reaper,colors.drubber,colors.fencer,colors.carrion})[mode]
    render.SetMaterial(beam)
    local function line(a,b,width) render.DrawBeam(a,b,width or 2,0,1,color) end
    local function countdown(deadline,duration)
        if now>=deadline then return end
        local left=origin+Vector(0,0,52)-side*24
        line(left,left+side*(48*math.Clamp((deadline-now)/duration,0,1)),3)
    end
    local function sector(radius,halfAngle,segments,width)
        local function point(angle)
            return origin+(dir*math.cos(angle)+side*math.sin(angle))*radius
        end
        local half=math.rad(halfAngle)
        line(origin,point(-half),width)
        for i=1,segments do
            line(point(-half+2*half*(i-1)/segments),point(-half+2*half*i/segments),width)
        end
        line(point(half),origin,width)
    end
    if mode==4 then
        sector(112,30,8,now<ready and 2 or 4)
        local id=e:GetNW2String("LOD_Archetype","")
        countdown(ready,id=="outrider" and 1.1 or ((id=="afterburst" or id=="listener" or id=="shy") and .9 or .8))
    elseif mode==1 then
        sector(144,90,12,now<ready and 2 or 4)
        countdown(ready,1.1)
    elseif mode==2 then
        local second=e:GetNW2Float("LOD_MeleeSecond",0)
        if now<ready then sector(112,30,8,2) end
        sector(184,30,8,now<ready and 1 or (now<second and 2 or 4))
        countdown(now<ready and ready or second,now<ready and 1 or .85)
    elseif now<ready-.9 then
        local start=e:GetNW2Vector("LOD_MeleeStart",origin-Vector(0,0,3))+Vector(0,0,3)
        local delta=origin-start
        for i=0,3 do line(start+delta*(i/4),start+delta*((i+.5)/4),1) end
        local tip=origin+dir*16
        line(origin,tip+side*10,1);line(origin,tip-side*10,1)
        local up=Vector(0,0,10);local center=origin+Vector(0,0,14)
        line(center+up,center+side*10,1);line(center+side*10,center-up,1)
        line(center-up,center-side*10,1);line(center-side*10,center+up,1)
    else
        local endpoint=origin+dir*240;local width=now<ready and 2 or 4
        line(origin-side*24,endpoint-side*24,width)
        line(endpoint-side*24,endpoint+side*24,width)
        line(endpoint+side*24,origin+side*24,width)
        line(origin+side*24,origin-side*24,width)
        countdown(ready,.9)
    end
end
-- Invoked directly by the native corpse Draw branch as well as living Draw.
function V:Remains(e)
    if e:GetPos():DistToSqr(EyePos())>2400^2 then return end
    local now=CurTime();render.SetMaterial(beam)
    local ready=e:GetNW2Float("LOD_RemainsBurstReady",0)
    if now<e:GetNW2Float("LOD_RemainsBurstUntil",0) then
        local origin=e:GetNW2Vector("LOD_RemainsOrigin",e:GetPos())+Vector(0,0,3)
        local color=colors.afterburst
        for i=1,24 do
            local a,b=(i-1)*math.pi/12,i*math.pi/12
            render.DrawBeam(origin+Vector(math.cos(a)*128,math.sin(a)*128,0),
                origin+Vector(math.cos(b)*128,math.sin(b)*128,0),now<ready and 2 or 4,0,1,color)
        end
        local left=origin+Vector(-24,0,52)
        render.DrawBeam(left,left+Vector(48*math.Clamp((ready-now)/.8,0,1),0,0),3,0,1,color)
    end
    local target=e:GetNW2Entity("LOD_RemainsTarget",NULL)
    if e:GetNW2Bool("LOD_RosterAlive",false) and IsValid(target) and now<e:GetNW2Float("LOD_RemainsFeedUntil",0) then
        local origin=e:GetNW2Vector("LOD_RemainsFeedOrigin",e:GetPos())+Vector(0,0,40)
        local aim=e:GetNW2Vector("LOD_RemainsFeedAim",target:GetPos())+Vector(0,0,8)
        render.DrawBeam(origin,aim,3,0,1,colors.carrion)
        -- Crossed jaws and a shrinking bar distinguish consumption from healing support.
        render.DrawBeam(aim+Vector(-12,-12,0),aim+Vector(12,12,0),3,0,1,colors.carrion)
        render.DrawBeam(aim+Vector(-12,12,0),aim+Vector(12,-12,0),3,0,1,colors.carrion)
        local left=origin+Vector(-24,0,16)
        local fraction=math.Clamp((e:GetNW2Float("LOD_RemainsFeedReady",0)-now)/.6,0,1)
        render.DrawBeam(left,left+Vector(48*fraction,0,0),3,0,1,colors.carrion)
    end
end
function V:Tactical(e)
    local mode=e:GetNW2Int("LOD_TacticalMode",0);local now=CurTime()
    if mode==0 or not e:GetNW2Bool("LOD_RosterAlive",false)
        or now>=e:GetNW2Float("LOD_TacticalUntil",0) then return end
    local origin=e:GetNW2Vector("LOD_TacticalOrigin",e:GetPos())
    local aim=e:GetNW2Vector("LOD_TacticalAim",origin)
    local dir=e:GetNW2Vector("LOD_TacticalDirection",Vector(1,0,0))
    local side=Vector(-dir.y,dir.x,0);local up=Vector(0,0,1)
    local color=mode==1 and colors.towline or colors.screenwright
    local ready=e:GetNW2Float("LOD_TacticalReady",0)
    render.SetMaterial(beam)
    local function line(a,b,w) render.DrawBeam(a,b,w or 2,0,1,color) end
    if mode==1 then
        -- Entire frozen corridor and inward chevrons survive reduced effects.
        for _,sign in ipairs({-1,1}) do line(origin+dir*96+side*(24*sign)+up*3,aim+dir*24+side*(24*sign)+up*3) end
        line(origin+up*40,aim+up*40)
        for _,sign in ipairs({-1,1}) do line(aim-dir*32+up*40,aim-dir*16+side*(12*sign)+up*40) end
    else
        local left,right=aim-side*80,aim+side*80
        local width=now<ready and 1 or 3
        line(left,right,width);line(left+up*96,right+up*96,width)
        line(left,left+up*96,width);line(right,right+up*96,width)
        line(origin+up*40,aim+up*48)
        -- Open slats distinguish passable probabilistic cover from a solid Wall.
        for _,offset in ipairs({-40,0,40}) do line(aim+side*offset+up*20,aim+side*offset+up*76,width) end
    end
    local duration=mode==1 and 1.2 or (now<ready and 1 or 3)
    local untilAt=now<ready and ready or e:GetNW2Float("LOD_TacticalUntil",ready)
    local start=origin-side*24+up*88
    line(start,start+side*(48*math.Clamp((untilAt-now)/duration,0,1)),3)
end
-- Mobile commitments expose a frozen route before moving. The carrier's live
-- circle follows its actual position; trail circles never follow their source.
-- All deadlines are server timestamps, including unplaced plans, so stale NW2
-- snapshots cannot keep a warning alive. Reduced effects retain every boundary.
function V:Mobile(e)
    local mode=e:GetNW2Int("LOD_MobileMode",0);local now=CurTime()
    local ready=e:GetNW2Float("LOD_MobileReady",0)
    local untilAt=e:GetNW2Float("LOD_MobileUntil",0)
    if mode<1 or mode>2 or not e:GetNW2Bool("LOD_RosterAlive",false)
        or e:GetNW2Int("LOD_RosterAttack",0)==0 or now>=untilAt
        or (mode==1 and now>=ready+1.8)
        or e:GetPos():DistToSqr(EyePos())>2400^2 then return end
    local start=e:GetNW2Vector("LOD_MobileStart",e:GetPos())
    local goal=e:GetNW2Vector("LOD_MobileGoal",start)
    local delta=goal-start;local dir=delta:GetNormalized();local side=Vector(-dir.y,dir.x,0)
    local color=mode==1 and colors.censer or colors.trailmaker
    render.SetMaterial(beam)
    local function line(a,b,width) render.DrawBeam(a,b,width or 2,0,1,color) end
    local function circle(center,radius,width,dashed)
        for i=1,24 do
            if not dashed or i%2==1 then
                local a,b=(i-1)*math.pi/12,i*math.pi/12
                line(center+Vector(math.cos(a)*radius,math.sin(a)*radius,0),
                    center+Vector(math.cos(b)*radius,math.sin(b)*radius,0),width)
            end
        end
    end
    local function countdown(center,deadline,duration)
        if now>=deadline then return end
        local left=center+Vector(-24,0,52)
        line(left,left+Vector(48*math.Clamp((deadline-now)/duration,0,1),0,0),3)
    end
    if mode==1 then
        if now<ready then
            -- The capsule is the whole swept footprint, not a contact hazard.
            line(start-side*64,goal-side*64);line(start+side*64,goal+side*64)
            for i=1,12 do
                local a,b=(i-1)*math.pi/12,i*math.pi/12
                line(start+(side*math.cos(a)-dir*math.sin(a))*64,
                    start+(side*math.cos(b)-dir*math.sin(b))*64)
                line(goal+(side*math.cos(a)+dir*math.sin(a))*64,
                    goal+(side*math.cos(b)+dir*math.sin(b))*64)
            end
            countdown(start,ready,1.2)
        else
            local center=e:GetPos()+Vector(0,0,2)
            circle(center,64,4)
            countdown(center,math.min(untilAt,ready+1.8),1.8)
        end
    else
        -- Dashed marks are prospective placement, solid thin rings are arming,
        -- and thick rings are live. Expired placed patches never become plans.
        if now<ready+1.8 then
            for i=0,3 do line(start+delta*(i/4),start+delta*((i+.5)/4),1) end
        end
        for i=1,3 do
            local center=start+delta*((i-1)/2)
            local patchReady=e:GetNW2Float("LOD_MobilePatchReady"..i,0)
            local patchUntil=e:GetNW2Float("LOD_MobilePatchUntil"..i,0)
            if patchReady>0 then
                if now<math.min(untilAt,patchUntil) then
                    circle(center,44,now<patchReady and 2 or 4)
                    countdown(center,now<patchReady and patchReady or math.min(untilAt,patchUntil),
                        now<patchReady and .8 or 1.2)
                end
            elseif now<ready+1.8 then
                circle(center,44,1,true)
            end
        end
        if now<ready then countdown(start,ready,1.2) end
    end
end
function V:Perception(e)
    local now=CurTime();local ready=e:GetNW2Float("LOD_PerceptionReady",0)
    local untilTime=e:GetNW2Float("LOD_PerceptionUntil",0)
    if not e:GetNW2Bool("LOD_RosterAlive",false) or now>=untilTime then return end
    local mode=e:GetNW2Int("LOD_PerceptionMode",0);if mode==0 then return end
    local start=e:GetNW2Vector("LOD_PerceptionStart",e:GetPos())
    local goal=e:GetNW2Vector("LOD_PerceptionGoal",start)
    local color=colors[e:GetNW2String("LOD_Archetype","")]
    render.SetMaterial(beam)
    -- Harmless investigative route: dashed line, fixed destination glyph and
    -- countdown. The ordinary solid melee arc is a separate damaging warning.
    for i=0,3 do
        render.DrawBeam(start+(goal-start)*(i/4),start+(goal-start)*((i+.5)/4),2,0,1,color)
    end
    local center=goal+Vector(0,0,6)
    if mode==1 then
        for _,radius in ipairs({12,22}) do
            for i=1,12 do
                local a,b=(i-1)*math.pi/6,i*math.pi/6
                render.DrawBeam(center+Vector(math.cos(a)*radius,math.sin(a)*radius,0),center+Vector(math.cos(b)*radius,math.sin(b)*radius,0),2,0,1,color)
            end
        end
    else
        for _,sign in ipairs({-1,1}) do
            render.DrawBeam(center+Vector(-24,0,0),center+Vector(0,14*sign,0),2,0,1,color)
            render.DrawBeam(center+Vector(0,14*sign,0),center+Vector(24,0,0),2,0,1,color)
        end
        render.DrawBeam(center+Vector(-16,-20,0),center+Vector(16,20,0),3,0,1,color)
    end
    local fraction=math.Clamp(((now<ready and ready or untilTime)-now)/(now<ready and .8 or 1.4),0,1)
    render.DrawBeam(center+Vector(-24,0,28),center+Vector(-24+48*fraction,0,28),3,0,1,color)
end
-- A broken-diamond condition glyph distinguishes this physical collection mark.
function V:Condition(e)
    local now=CurTime();local ready=e:GetNW2Float("LOD_ConditionReady",0)
    if not e:GetNW2Bool("LOD_RosterAlive",false) or now>=e:GetNW2Float("LOD_ConditionUntil",0) then return end
    local aim=e:GetNW2Vector("LOD_ConditionAim",e:GetPos())+Vector(0,0,3)
    local origin=e:GetNW2Vector("LOD_ConditionOrigin",e:GetPos())+Vector(0,0,48)
    local color=colors.exactor
    render.SetMaterial(beam)
    for i=1,24 do
        local a,b=(i-1)*math.pi/12,i*math.pi/12
        render.DrawBeam(aim+Vector(math.cos(a)*64,math.sin(a)*64,0),
            aim+Vector(math.cos(b)*64,math.sin(b)*64,0),3,0,1,color)
    end
    local points={Vector(0,-14,0),Vector(14,0,0),Vector(0,14,0),Vector(-14,0,0)}
    for i=1,4 do render.DrawBeam(aim+points[i],aim+points[i%4+1],3,0,1,color) end
    render.DrawBeam(aim+Vector(-18,-18,0),aim+Vector(18,18,0),3,0,1,color)
    render.DrawBeam(origin,aim,1,0,1,color)
    local fraction=math.Clamp((ready-now)/1.25,0,1)
    render.DrawBeam(aim+Vector(-24,0,28),aim+Vector(-24+48*fraction,0,28),3,0,1,color)
end
-- Party-spacing snapshots contain only frozen, server-visible commitments.
-- The twin circles and connecting line encode a pair; the lone bracket glyph
-- identifies isolation without resembling a second damaging footprint.
function V:Spacing(e)
    local mode=e:GetNW2Int("LOD_SpacingMode",0)
    local now=CurTime();local ready=e:GetNW2Float("LOD_SpacingReady",0)
    local untilAt=e:GetNW2Float("LOD_SpacingUntil",0)
    if (mode~=1 and mode~=2) or not e:GetNW2Bool("LOD_RosterAlive",false)
        or e:GetNW2Int("LOD_RosterAttack",0)==0 or ready~=ready or untilAt~=untilAt
        or math.abs(ready)==math.huge or math.abs(untilAt)==math.huge
        or untilAt>ready+.201 or now>=untilAt
        or e:GetPos():DistToSqr(EyePos())>2400^2 then return end
    local origin=e:GetNW2Vector("LOD_SpacingOrigin",e:GetPos())
    local color=mode==1 and colors.outrider or colors.conductor
    render.SetMaterial(beam)
    local function line(a,b,width) render.DrawBeam(a,b,width or 2,0,1,color) end
    if mode==1 then
        self:Melee(e)
        local center=origin+Vector(0,0,72)
        local side=(EyePos()-center):Angle():Right();local up=Vector(0,0,1)
        for _,sign in ipairs({-1,1}) do
            local endSide=center+side*sign*14
            line(endSide-up*12,endSide+up*12)
            line(endSide-up*12,endSide-side*sign*5-up*12)
            line(endSide+up*12,endSide-side*sign*5+up*12)
        end
        line(center-up*8,center+up*8,3)
        return
    end
    local a=e:GetNW2Vector("LOD_SpacingAimA",origin)+Vector(0,0,3)
    local b=e:GetNW2Vector("LOD_SpacingAimB",origin)+Vector(0,0,3)
    -- Invalid or unbounded snapshots must not expand a client render footprint.
    for _,point in ipairs({a,b}) do
        local distance=point:DistToSqr(origin)
        if distance~=distance or distance>364^2 then return end
    end
    for _,center in ipairs({a,b}) do
        for i=1,24 do
            local from,to=(i-1)*math.pi/12,i*math.pi/12
            line(center+Vector(math.cos(from)*64,math.sin(from)*64,0),
                center+Vector(math.cos(to)*64,math.sin(to)*64,0),3)
        end
        line(origin+Vector(0,0,48),center,1)
    end
    line(a,b,3)
    local middle=(a+b)*.5+Vector(0,0,28)
    local fraction=math.Clamp((ready-now)/1.4,0,1)
    line(middle+Vector(-24,0,0),middle+Vector(-24+48*fraction,0,0),3)
end
-- Resource pressure uses fixed ground marks; recharge has a self-only battery
-- glyph and no damaging footprint. Semantic geometry survives reduced effects.
function V:Resource(e)
    local mode=e:GetNW2Int("LOD_ResourceMode",0)
    local id=e:GetNW2String("LOD_Archetype","")
    local now=CurTime();local ready=e:GetNW2Float("LOD_ResourceReady",0)
    local untilAt=e:GetNW2Float("LOD_ResourceUntil",0)
    if (id=="siphoner" and mode~=1) or (id=="accumulator" and mode~=2 and mode~=3)
        or not e:GetNW2Bool("LOD_RosterAlive",false) or e:GetNW2Int("LOD_RosterAttack",0)~=1
        or ready~=ready or untilAt~=untilAt or math.abs(ready)==math.huge or math.abs(untilAt)==math.huge
        or untilAt>ready+.201 or untilAt<ready or now>=untilAt
        or e:GetPos():DistToSqr(EyePos())>2400^2 then return end
    local origin=e:GetNW2Vector("LOD_ResourceOrigin",e:GetPos())
    local aim=e:GetNW2Vector("LOD_ResourceAim",origin)
    local distance=aim:DistToSqr(origin);local drift=origin:DistToSqr(e:GetPos())
    if distance~=distance or distance>360^2 or drift~=drift or drift>4^2
        or (mode==3 and distance>.01) then return end
    local center=aim+Vector(0,0,3);local color=colors[id]
    render.SetMaterial(beam)
    local function line(a,b,width) render.DrawBeam(a,b,width or 3,0,1,color) end
    if mode~=3 then
        for i=1,24 do
            local from,to=(i-1)*math.pi/12,i*math.pi/12
            line(center+Vector(math.cos(from)*64,math.sin(from)*64,0),
                center+Vector(math.cos(to)*64,math.sin(to)*64,0))
        end
        line(origin+Vector(0,0,48),center,1)
    end
    local glyph=center+Vector(0,0,mode==3 and 68 or 16)
    local side=(EyePos()-glyph):Angle():Right();local up=Vector(0,0,1)
    if mode==1 then
        -- A hollow funnel points down: Magic leaves the marked Hero.
        line(glyph-side*14+up*12,glyph+side*14+up*12)
        line(glyph-side*14+up*12,glyph-up*5)
        line(glyph+side*14+up*12,glyph-up*5)
        line(glyph-up*5,glyph-up*16)
        line(glyph-up*16,glyph-side*5-up*10)
        line(glyph-up*16,glyph+side*5-up*10)
    elseif mode==2 then
        -- A zigzag bolt differs from both the drain and self-recharge glyphs.
        local points={glyph+side*6+up*16,glyph-side*8+up*1,glyph+side*7-up*1,glyph-side*6-up*16}
        for i=1,3 do line(points[i],points[i+1]) end
    else
        local points={glyph-side*17-up*12,glyph+side*17-up*12,glyph+side*17+up*12,glyph-side*17+up*12}
        for i=1,4 do line(points[i],points[i%4+1]) end
        line(glyph-side*6+up*16,glyph+side*6+up*16)
        line(glyph-side*7,glyph+side*7);line(glyph-up*7,glyph+up*7)
    end
    local fraction=math.Clamp((ready-now)/(mode==3 and 2 or 1.25),0,1)
    local bar=center+Vector(0,0,mode==3 and 96 or 48)
    line(bar-side*24,bar+side*(-24+48*fraction))
end
-- Careless fire has two different counterplays: intercept the narrow shot with
-- a body, or leave the blast and lure bodies into it. One bounded trace clips
-- the line against the current first obstruction; it never chooses a new aim.
-- Every semantic beam survives reduced effects, with no entities or emitters.
function V:Crossfire(e)
    local mode=e:GetNW2Int("LOD_CrossfireMode",0)
    local id=e:GetNW2String("LOD_Archetype","")
    local now=CurTime();local ready=e:GetNW2Float("LOD_CrossfireReady",0)
    local untilAt=e:GetNW2Float("LOD_CrossfireUntil",0)
    local duration=mode==1 and 1.25 or 1.6
    local function finite(n) return n==n and math.abs(n)<math.huge end
    local function finiteVector(v) return finite(v.x) and finite(v.y) and finite(v.z) end
    if not ((id=="fusilier" and mode==1) or (id=="bombardier" and mode==2))
        or not e:GetNW2Bool("LOD_RosterAlive",false) or e:GetNW2Int("LOD_RosterAttack",0)~=1
        or not finite(now) or not finite(ready) or not finite(untilAt)
        or untilAt>ready+.201 or untilAt<ready or now>=untilAt or ready>now+duration+.001 then return end
    local pos=e:GetPos();local eye=EyePos()
    local origin=e:GetNW2Vector("LOD_CrossfireOrigin",pos)
    local aim=e:GetNW2Vector("LOD_CrossfireAim",origin)
    if not finiteVector(pos) or not finiteVector(eye) or not finiteVector(origin) or not finiteVector(aim)
        or pos:DistToSqr(eye)>2400^2 or origin:DistToSqr(pos)>4^2
        or origin:DistToSqr(aim)>(mode==1 and 432 or 360)^2 then return end
    local color=colors[id];local up=Vector(0,0,1)
    local center=mode==1 and origin+up*76 or aim+up*48
    local side=(eye-center):Angle():Right()
    render.SetMaterial(beam)
    local function line(a,b,width) render.DrawBeam(a,b,width or 3,0,1,color) end
    if mode==1 then
        local start=origin+up*48
        if start:DistToSqr(aim)<.01 then return end
        local trace=util.TraceHull({start=start,endpos=aim,mins=Vector(-4,-4,-4),
            maxs=Vector(4,4,4),filter=e,mask=MASK_SHOT})
        local stop=trace.Hit and trace.HitPos or aim
        -- Reject malformed trace output before it can escape the render bounds.
        if not stop or not finiteVector(stop) or origin:DistToSqr(stop)>432^2 then return end
        local direction=(aim-start):GetNormalized()
        local right=direction:Angle():Right()
        line(start,stop,2)
        local tip=start+(stop-start)*.65
        line(tip,tip-direction*14+right*8,2)
        line(tip,tip-direction*14-right*8,2)
        if trace.Hit and not trace.HitWorld and IsValid(trace.Entity) then
            -- Square brackets make first-body interception explicit without
            -- promising damage to uncaptured or otherwise excluded bodies.
            for _,sign in ipairs({-1,1}) do
                local edge=stop+right*(sign*14)
                line(edge-up*18,edge+up*18)
                line(edge-up*18,edge-right*(sign*6)-up*18)
                line(edge+up*18,edge-right*(sign*6)+up*18)
            end
        end
    else
        local ground=aim+up*3
        for i=1,24 do
            local a,b=(i-1)*math.pi/12,i*math.pi/12
            line(ground+Vector(math.cos(a)*72,math.sin(a)*72,0),
                ground+Vector(math.cos(b)*72,math.sin(b)*72,0))
        end
        -- Disconnected outward fragments identify an area burst, including
        -- friendly bodies; no line of bodies can provide blast protection.
        for i=0,3 do
            local angle=i*math.pi*.5;local direction=Vector(math.cos(angle),math.sin(angle),0)
            line(ground+direction*12,ground+direction*28)
            local edge=ground+direction*72
            line(edge,edge+up*69,1)
        end
        line(origin+up*48,ground,1)
    end
    local fraction=math.Clamp((ready-now)/duration,0,1)
    line(center-side*24,center+side*(-24+48*fraction))
end
-- The server owns the captured life and voluntary-motion judgment. This tell
-- uses only its bounded aim snapshot, never a live entity's replacement life.
-- All semantic geometry and literal instructions survive reduced effects.
function V:Discipline(e)
    local mode=e:GetNW2Int("LOD_DisciplineMode",0)
    local id=e:GetNW2String("LOD_Archetype","")
    local now=CurTime();local ready=e:GetNW2Float("LOD_DisciplineReady",0)
    local untilAt=e:GetNW2Float("LOD_DisciplineUntil",0)
    local function finite(n) return n==n and math.abs(n)<math.huge end
    local function finiteVector(v) return finite(v.x) and finite(v.y) and finite(v.z) end
    if not ((id=="halter" and mode==1) or (id=="pacer" and mode==2))
        or not e:GetNW2Bool("LOD_RosterAlive",false) or e:GetNW2Int("LOD_RosterAttack",0)~=1
        or not finite(now) or not finite(ready) or not finite(untilAt)
        or untilAt>ready+.201 or untilAt<ready or now>=untilAt or ready>now+1.601 then return end
    local pos=e:GetPos();local eye=EyePos()
    local origin=e:GetNW2Vector("LOD_DisciplineOrigin",pos)
    local aim=e:GetNW2Vector("LOD_DisciplineAim",origin)
    if not finiteVector(pos) or not finiteVector(eye) or not finiteVector(origin) or not finiteVector(aim)
        or pos:DistToSqr(eye)>2400^2 or origin:DistToSqr(pos)>4^2
        or origin:DistToSqr(aim)>432^2 then return end
    local color=colors[id];local up=Vector(0,0,1)
    local center=origin+up*90;local side=(eye-center):Angle():Right()
    local judging=now>=ready-.4
    render.SetMaterial(beam)
    local function line(a,b,width) render.DrawBeam(a,b,width or (judging and 4 or 2),0,1,color) end
    line(origin+up*48,aim,1)
    if mode==1 then
        -- Octagonal STOP with pause bars, distinct without relying on color.
        for i=1,8 do
            local a,b=(i-.5)*math.pi/4,(i+.5)*math.pi/4
            line(center+side*(math.cos(a)*19)+up*(math.sin(a)*19),
                center+side*(math.cos(b)*19)+up*(math.sin(b)*19))
        end
        for _,sign in ipairs({-1,1}) do line(center+side*(sign*5)-up*9,center+side*(sign*5)+up*9) end
    else
        -- Double forward chevrons: KEEP MOVING.
        for _,offset in ipairs({-11,7}) do
            local tip=center+side*(offset+8)
            line(center+side*(offset-4)+up*13,tip)
            line(tip,center+side*(offset-4)-up*13)
        end
    end
    local fraction=math.Clamp((ready-now)/1.6,0,1)
    local bar=center-up*28
    -- A fixed quarter-bar bracket marks the final0.4s judging interval.
    line(bar-side*24-up*4,bar-side*12-up*4,1)
    line(bar-side*12-up*4,bar-side*12+up*4,1)
    line(bar-side*24,bar+side*(-24+48*fraction))
    local yaw=(eye-center):Angle().y
    cam.Start3D2D(center+up*31,Angle(0,yaw-90,90),.16)
    draw.SimpleText(mode==1 and "STOP" or "KEEP MOVING","DermaLarge",0,-32,color,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    draw.SimpleText(string.format("%s %.1fs",judging and "JUDGMENT" or "PREPARE",math.max(0,ready-now)),
        "DermaDefaultBold",0,0,color,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    cam.End3D2D()
end
-- Companion tells use finite snapshots, never ward/Hero entity positions. The
-- shield follows the source's actual body: it promises no remote protection.
function V:Companion(e)
    local mode=e:GetNW2Int("LOD_CompanionMode",0)
    local phase=e:GetNW2Int("LOD_CompanionPhase",0)
    local id=e:GetNW2String("LOD_Archetype","")
    local now=CurTime();local ready=e:GetNW2Float("LOD_CompanionReady",0)
    local untilAt=e:GetNW2Float("LOD_CompanionUntil",0)
    local function finite(n) return n==n and math.abs(n)<math.huge end
    local function finiteVector(v) return finite(v.x) and finite(v.y) and finite(v.z) end
    if not ((id=="interposer" and mode==1) or (id=="mourner" and mode==2))
        or (phase~=1 and phase~=2 and phase~=3) or not e:GetNW2Bool("LOD_RosterAlive",false)
        or e:GetNW2Int("LOD_RosterAttack",0)~=1 or not finite(now)
        or not finite(ready) or not finite(untilAt) or untilAt<ready or now>=untilAt then return end
    local duration=phase==1 and .8 or (phase==3 and 1.2 or (mode==1 and 2 or 3))
    local tail=phase==3 and .201 or (mode==1 and (phase==1 and 3.801 or 2.001) or (phase==1 and 3.001 or .001))
    if ready>now+duration+.001 or untilAt>ready+tail then return end
    local pos=e:GetPos();local eye=EyePos()
    local origin=e:GetNW2Vector("LOD_CompanionOrigin",pos)
    local goal=e:GetNW2Vector("LOD_CompanionGoal",origin)
    local ward=e:GetNW2Vector("LOD_CompanionWard",origin)
    local aim=e:GetNW2Vector("LOD_CompanionAim",origin)
    -- Arrival publishes Origin at Goal. Only the moving phase allows travel;
    -- the stationary bodyguard hold retains the normal four-unit drift bound.
    local moving=mode==1 and phase==2 and origin:DistToSqr(goal)>.05^2
    if not finiteVector(pos) or not finiteVector(eye) or not finiteVector(origin)
        or not finiteVector(goal) or not finiteVector(ward) or not finiteVector(aim)
        or pos:DistToSqr(eye)>2400^2 or origin:DistToSqr(pos)>(moving and 164^2 or 4^2)
        or origin:DistToSqr(goal)>164^2 or origin:DistToSqr(ward)>304^2
        or origin:DistToSqr(aim)>432^2 then return end
    local color=colors[id];local up=Vector(0,0,1)
    local center=pos+up*90;local side=(eye-center):Angle():Right()
    local function line(a,b,width) render.DrawBeam(a,b,width or 3,0,1,color) end
    render.SetMaterial(beam)
    local retaliation=phase==3 and e:GetNW2Int("LOD_CompanionRetaliation",0)==1
    local label=phase==3 and (retaliation and "RETALIATION" or "SHOT") or (mode==1 and "BODYGUARD" or "OATH")
    if phase==3 then
        -- Frozen lane arrow and target cross. Bodies/cover can absorb the shot.
        local start=origin+up*48;local direction=(aim-start):GetNormalized()
        local right=direction:Angle():Right();local tip=start+(aim-start)*.65
        line(start,aim,2);line(tip,tip-direction*14+right*8);line(tip,tip-direction*14-right*8)
        line(aim-right*10-up*10,aim+right*10+up*10)
        line(aim-right*10+up*10,aim+right*10-up*10)
    elseif mode==1 then
        local a=origin+up*3;local b=goal+up*3
        local direction=(b-a):GetNormalized();local right=direction:Angle():Right()
        line(a,b,2);line(b,b-direction*14+right*8);line(b,b-direction*14-right*8)
        -- Shield is attached to the real Interposer, not its ward or goal.
        local points={center-side*16+up*14,center+side*16+up*14,
            center+side*13-up*7,center-up*19,center-side*13-up*7}
        for i=1,5 do line(points[i],points[i%5+1]) end
        line(pos+up*48,ward,1)
    end
    if (mode==2 and phase~=3) or retaliation then
        -- Intact oath diamond versus separated halves of a broken oath.
        local gap=retaliation and 5 or 0
        line(center-side*(14+gap),center-side*gap+up*16)
        line(center-side*(14+gap),center-side*gap-up*16)
        line(center+side*(14+gap),center+side*gap+up*16)
        line(center+side*(14+gap),center+side*gap-up*16)
        if phase~=3 then line(origin+up*48,ward,1) end
    end
    local fraction=math.Clamp((ready-now)/duration,0,1);local bar=center-up*28
    line(bar-side*24,bar+side*(-24+48*fraction))
    cam.Start3D2D(center+up*31,Angle(0,(eye-center):Angle().y-90,90),.16)
    draw.SimpleText(label,"DermaLarge",0,-32,color,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    draw.SimpleText(string.format("%s %.1fs",phase==1 and "PREPARE" or (phase==3 and "FIRE" or "ACTIVE"),math.max(0,ready-now)),
        "DermaDefaultBold",0,0,color,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    cam.End3D2D()
end
-- Edicts are finite server snapshots. Client rendering neither judges a Hero's
-- attacks nor follows a recipient; every observer sees the same frozen choice.
function V:Edict(e)
    local mode=e:GetNW2Int("LOD_EdictMode",0)
    local phase=e:GetNW2Int("LOD_EdictPhase",0)
    local id=e:GetNW2String("LOD_Archetype","")
    local now=CurTime();local ready=e:GetNW2Float("LOD_EdictReady",0)
    local untilAt=e:GetNW2Float("LOD_EdictUntil",0)
    local function finite(n) return type(n)=="number" and n==n and math.abs(n)<math.huge end
    local function finiteVector(v) return v and finite(v.x) and finite(v.y) and finite(v.z) end
    if not ((id=="censor" and mode==1 and (phase==1 or phase==2 or phase==3))
        or (id=="surveyor" and mode==2 and phase==1))
        or not e:GetNW2Bool("LOD_RosterAlive",false) or e:GetNW2Int("LOD_RosterAttack",0)~=1
        or not finite(now) or not finite(ready) or not finite(untilAt)
        or untilAt<ready or now>=untilAt then return end
    local duration=mode==2 and 1.6 or (phase==1 and .8 or (phase==2 and 2.4 or 1.2))
    local tail=mode==2 and .201 or (phase==1 and 2.601 or .201)
    if ready>now+duration+.001 or untilAt>ready+tail then return end
    local pos=e:GetPos();local eye=EyePos()
    local origin=e:GetNW2Vector("LOD_EdictOrigin",nil)
    local aim=e:GetNW2Vector("LOD_EdictAim",nil)
    if not finiteVector(pos) or not finiteVector(eye) or not finiteVector(origin) or not finiteVector(aim)
        or pos:DistToSqr(eye)>2400^2 or origin:DistToSqr(pos)>4^2
        or origin:DistToSqr(aim)>(mode==2 and 360.01^2 or 432^2) then return end
    local refuge,escape
    if mode==2 then
        refuge=e:GetNW2Vector("LOD_EdictRefuge",nil);escape=e:GetNW2Vector("LOD_EdictEscape",nil)
        if not finiteVector(refuge) or not finiteVector(escape) then return end
        local a,b=refuge-aim,escape-aim
        if math.abs(a.z)>.01 or math.abs(b.z)>.01
            or math.abs(a:LengthSqr()-96^2)>1 or math.abs(b:LengthSqr()-160^2)>1
            or (a*(160/96)+b):LengthSqr()>.01 then return end
    end
    local color=colors[id];local up=Vector(0,0,1)
    local center=origin+up*90;local side=(eye-center):Angle():Right()
    render.SetMaterial(beam)
    local function line(a,b,width,tint) render.DrawBeam(a,b,width or 3,0,1,tint or color) end
    local function arrow(a,b,width)
        local direction=(b-a):GetNormalized();local right=direction:Angle():Right()
        line(a,b,width);line(b,b-direction*14+right*8,width);line(b,b-direction*14-right*8,width)
    end
    local function circle(center,radius,tint)
        for i=1,32 do
            local a,b=(i-1)*math.pi/16,i*math.pi/16
            line(center+Vector(math.cos(a)*radius,math.sin(a)*radius,0),
                center+Vector(math.cos(b)*radius,math.sin(b)*radius,0),2,tint)
        end
    end
    local function label(at,text,countdown)
        cam.Start3D2D(at,Angle(0,(eye-at):Angle().y-90,90),.16)
        draw.SimpleText(text,"DermaLarge",0,-32,color,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
        if countdown then draw.SimpleText(countdown,"DermaDefaultBold",0,0,color,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER) end
        cam.End3D2D()
    end
    if mode==2 then
        local ground=aim+up*3;local safe=refuge+up*3;local out=escape+up*3
        -- Full outer threat boundary and displaced refuge boundary, plus two
        -- literal escape choices. The refuge is not a center-on-target donut.
        circle(ground,144,color);circle(safe,48,Color(235,245,240))
        arrow(ground,safe,2);arrow(ground,out,2)
        line(origin+up*48,ground,1)
        -- Compass at source; shelter roof at the safe pocket, distinct in mono.
        line(center-up*17,center+up*17);line(center-side*17,center+side*17)
        line(center-up*17,center+side*17);line(center+up*17,center-side*17)
        line(safe-side*15+up*8,safe+up*22);line(safe+up*22,safe+side*15+up*8)
        label(safe+up*35,"REFUGE")
    elseif phase==3 then
        arrow(origin+up*48,aim,2)
        local right=(aim-origin):Angle():Right()
        line(aim-right*10-up*10,aim+right*10+up*10)
        line(aim-right*10+up*10,aim+right*10-up*10)
    else
        -- Crossed barrel: a weapon-use edict, visually distinct from Halter's
        -- octagonal STOP/motion command. PREPARE and WATCH are explicit.
        line(origin+up*48,aim,1)
        line(center-side*17+up*5,center+side*17+up*5)
        line(center-side*17-up*3,center+side*17-up*3)
        line(center-side*8-up*3,center-side*8-up*13)
        line(center-side*18-up*17,center+side*18+up*17,4)
    end
    local fraction=math.Clamp((ready-now)/duration,0,1);local bar=center-up*28
    line(bar-side*24,bar+side*(-24+48*fraction))
    label(center+up*31,mode==2 and "REFUGE / LEAVE RING" or (phase==3 and "RETALIATION" or "CEASE FIRE"),
        string.format("%s %.1fs",mode==2 and "JUDGMENT" or (phase==1 and "PREPARE" or (phase==2 and "WATCH" or "FIRE")),math.max(0,ready-now)))
end
-- Link attacks publish only finite positions and phase times. The client never
-- queries the moving ward or Hero; late observers reconstruct the same warning.
function V:Link(e)
    local id=e:GetNW2String("LOD_Archetype","")
    local mode=e:GetNW2Int("LOD_LinkMode",0);local phase=e:GetNW2Int("LOD_LinkPhase",0)
    local function finite(n) return type(n)=="number" and n==n and math.abs(n)<math.huge end
    local function vector(v) return v and finite(v.x) and finite(v.y) and finite(v.z) end
    local now=CurTime();local started=e:GetNW2Float("LOD_LinkStarted",0)
    local ready=e:GetNW2Float("LOD_LinkReady",0);local untilAt=e:GetNW2Float("LOD_LinkUntil",0)
    if not ((id=="relay" and (mode==1 or mode==3) and phase==1)
        or (id=="lacemaker" and ((mode==2 and (phase==1 or phase==2)) or (mode==3 and phase==1))))
        or not e:GetNW2Bool("LOD_RosterAlive",false) or e:GetNW2Int("LOD_RosterAttack",0)~=1
        or not finite(now) or not finite(started) or not finite(ready) or not finite(untilAt)
        or now<started or now>=untilAt then return end
    local warning=mode==2 and 1.2 or 1.4
    local tail=mode==2 and 2.2 or .2
    -- NW2 timestamps are floats: allow their quantization on long-lived servers.
    if math.abs(ready-started-warning)>.05 or math.abs(untilAt-ready-tail)>.05
        or (phase==2 and (now<ready or now>=ready+2))
        or (phase==1 and now>ready+.2) then return end
    local pos=e:GetPos();local eye=EyePos()
    local origin=e:GetNW2Vector("LOD_LinkOrigin",nil);local aim=e:GetNW2Vector("LOD_LinkAim",nil)
    local ward=e:GetNW2Vector("LOD_LinkWard",nil)
    if not vector(pos) or not vector(eye) or not vector(origin) or not vector(aim)
        or pos:DistToSqr(eye)>2400^2 or origin:DistToSqr(pos)>4^2
        or origin:DistToSqr(aim)>432^2 then return end
    if mode~=3 and (not vector(ward) or origin:DistToSqr(ward)>(mode==1 and 312^2 or 244^2)) then return end
    local up=Vector(0,0,1);local color=colors[id]
    local center=origin+up*90;local side=(eye-center):Angle():Right()
    render.SetMaterial(beam)
    local function line(a,b,width) render.DrawBeam(a,b,width or 3,0,1,color) end
    local function arrow(a,b)
        local direction=(b-a):GetNormalized();local right=direction:Angle():Right()
        line(a,b,2);line(b,b-direction*14+right*8,2);line(b,b-direction*14-right*8,2)
    end
    local function diamond(at,radius)
        local points={at+up*radius,at+side*radius,at-up*radius,at-side*radius}
        for i=1,4 do line(points[i],points[i%4+1]) end
    end
    local function label(at,text,countdown)
        cam.Start3D2D(at,Angle(0,(eye-at):Angle().y-90,90),.16)
        draw.SimpleText(text,"DermaLarge",0,-32,color,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
        if countdown then draw.SimpleText(countdown,"DermaDefaultBold",0,0,color,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER) end
        cam.End3D2D()
    end
    if mode==1 then
        line(origin+up*48,ward,1);arrow(ward,aim)
        diamond(center,15);diamond(ward,12)
        label(ward+up*27,"SHOT ORIGIN")
    elseif mode==2 then
        local a,b=origin+up*3,ward+up*3
        local delta=b-a;local length=math.sqrt(delta.x*delta.x+delta.y*delta.y)
        if length<1 then return end
        local right=Vector(-delta.y/length,delta.x/length,0)*18
        -- Exact two edges and endpoint discs show the whole damaging capsule.
        line(a+right,b+right);line(a-right,b-right)
        for _,endpoint in ipairs({a,b}) do for i=1,24 do
            local first,last=(i-1)*math.pi/12,i*math.pi/12
            line(endpoint+Vector(math.cos(first)*18,math.sin(first)*18,0),
                endpoint+Vector(math.cos(last)*18,math.sin(last)*18,0),2)
        end end
        line(a,b,phase==2 and 4 or 1)
        -- Crossed laces read differently from Relay's linked diamonds in mono.
        for i=0,2 do
            local at=center+up*(12-i*12)
            line(at-side*12,at+side*12-up*12);line(at+side*12,at-side*12-up*12)
        end
        label(b+up*35,"MOVING END")
    else
        arrow(origin+up*48,aim)
        line(center-side*16,center+side*16);line(center-up*16,center+up*16)
        diamond(center,20)
    end
    local duration=phase==2 and 2 or warning
    local deadline=phase==2 and ready+2 or ready
    local fraction=math.Clamp((deadline-now)/duration,0,1);local bar=center-up*36
    line(bar-side*24,bar+side*(-24+48*fraction))
    local instruction=mode==1 and "RELAY SHOT / BREAK LINK" or (mode==2 and "LEAVE RIBBON / BREAK LINK" or "SOURCE SHOT / SIDESTEP")
    label(center+up*31,instruction,string.format("%s %.1fs",phase==2 and "ACTIVE" or "PREPARE",math.max(0,deadline-now)))
end
function V:Draw(e,size)
    self:Remains(e)
    self:Support(e)
    self:Pursuit(e)
    self:Reaction(e)
    if e:GetNW2String("LOD_Archetype","")=="nodule" then self:Gas(e);return end
    local stage=e:GetNW2Int("LOD_RosterAttack",0)
    if stage==0 or e:GetPos():DistToSqr(EyePos())>2400^2 then return end
    local id=e:GetNW2String("LOD_Archetype","");local color=colors[id];if not color then return end
    if id=="relay" or id=="lacemaker" then self:Link(e);return end
    if id=="censor" or id=="surveyor" then self:Edict(e);return end
    if id=="interposer" or id=="mourner" then self:Companion(e);return end
    if id=="halter" or id=="pacer" then self:Discipline(e);return end
    if id=="fusilier" or id=="bombardier" then self:Crossfire(e);return end
    if id=="siphoner" or id=="accumulator" then self:Resource(e);return end
    if id=="outrider" then self:Spacing(e);return end
    if id=="conductor" then
        if not e:GetNW2Bool("LOD_RosterAlive",false) then return end
        if e:GetNW2Int("LOD_SpacingMode",0)>0 then self:Spacing(e);return end
        local deadline=e:GetNW2Float(stage==1 and "LOD_RosterReady" or "LOD_RosterRelease",0)
        if deadline~=deadline or math.abs(deadline)==math.huge or CurTime()>=deadline+.2 then return end
    end
    if id=="exactor" and e:GetNW2Bool("LOD_ConditionMark",false) then self:Condition(e);return end
    if id=="listener" or id=="shy" then
        if e:GetNW2Int("LOD_PerceptionMode",0)>0 then self:Perception(e) else self:Melee(e) end
        return
    end
    if id=="censer" or id=="trailmaker" then self:Mobile(e);return end
    if (id=="towline" or id=="screenwright") and e:GetNW2Int("LOD_TacticalMode",0)>0 then self:Tactical(e);return end
    if id=="caromer" or id=="reeler" or id=="forker" then self:Pattern(e);return end
    if id=="wirewright" or id=="snarer" or id=="cordon" then self:Trap(e);return end
    if id=="reaper" or id=="drubber" or id=="fencer" or id=="afterburst" or id=="carrion" then self:Melee(e);return end
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
        if id=="conductor" and stage==1 then
            local fraction=math.Clamp((e:GetNW2Float("LOD_RosterReady",0)-CurTime())/1.4,0,1)
            render.DrawBeam(origin+Vector(-24,0,24),origin+Vector(-24+48*fraction,0,24),3,0,1,color)
        end
    end
end
