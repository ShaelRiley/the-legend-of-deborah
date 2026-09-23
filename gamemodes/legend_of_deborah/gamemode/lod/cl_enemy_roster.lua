if LOD.LoopAudio then LOD.LoopAudio:StopGroup('gas') end
LOD.EnemyRosterVisual={}
local V=LOD.EnemyRosterVisual
local glow=Material("sprites/light_glow02_add")
local beam=Material("cable/redlaser")
local colors={flamer=Color(255,105,25),bigcrab=Color(255,105,25),arccaster=Color(110,190,255),
    lurker=Color(110,240,55),beamsweeper=Color(120,225,255),sentry=Color(255,75,45),razor=Color(255,165,60),
    gaoler=Color(90,180,255),silencer=Color(255,245,170),repulsor=Color(220,165,70)}
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
            local c=q.kind==1 and colors.lurker or (q.kind==2 and colors.silencer or colors.sentry)
            local wide=q.kind~=0
            render.SetMaterial(glow);render.DrawSprite(pos,wide and 24 or 10,wide and 24 or 10,c)
            render.SetMaterial(beam);render.DrawBeam(pos-q.velocity:GetNormalized()*24,pos,wide and 5 or 2,0,1,c)
        end
    end
end)
function V:Draw(e,size)
    if e:GetNW2String("LOD_Archetype","")=="nodule" then self:Gas(e);return end
    local stage=e:GetNW2Int("LOD_RosterAttack",0)
    if stage==0 or e:GetPos():DistToSqr(EyePos())>2400^2 then return end
    local id=e:GetNW2String("LOD_Archetype","");local color=colors[id];if not color then return end
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
