local V = LOD.BossPresentation
V.Modules = V.Modules or {}
local M = {}
function M:Pose(e,size,s)
    local a=e:GetAngles()
    if s.dead then
        local t=math.max(0,CurTime()-(s.deathAt or CurTime()))
        return {angles=Angle(a.p,a.y+(t<.8 and math.sin(t*40)*8 or 0),math.min(math.max(t-1.6,0),1)*78)}
    end
    local cycle=e:GetNW2String('LOD_BossCycle','Fill')
    local spin=cycle=='Spin'
    return {angles=Angle(a.p,a.y,math.sin(CurTime()*(spin and 24 or 5))*(spin and ((s.phase or 1)==3 and 7 or 3) or 1)),
        offset=Vector(0,0,tostring(s.action or ''):find('WALKING',1,true) and math.abs(math.sin(CurTime()*8))*8 or 0)}
end
function M:Draw(e,size,s)
    render.SetColorMaterial()
    local scale=tonumber(size) or 1.7
    local open=s.dead or e:GetNW2Bool('LOD_BossDoorOpen',false)
    local drum=e:LocalToWorld(Vector(15,0,25)*scale)
    render.DrawSphere(drum,10*scale,16,8,Color(30,40,50))
    local angle=CurTime()*(e:GetNW2String('LOD_BossCycle','Fill')=='Spin' and 14 or 2)
    for i=1,4 do
        local theta=angle+i*math.pi/2
        render.DrawSphere(drum+e:GetRight()*math.cos(theta)*7*scale+Vector(0,0,math.sin(theta)*7*scale),2.3*scale,6,4,Color(150,185,220))
    end
    local door=drum+e:GetRight()*(open and 17 or 0)*scale
    render.DrawWireframeSphere(door,12*scale,16,8,open and Color(240,210,105) or Color(160,170,180),true)
end
V.Modules.moshi = M
-- Owned drainage objects dispatch here; no searches or render-time model allocation.
function M:DrawObject(e,size,s)
    local kind=e:GetNW2String('LOD_BossObjectKind','')
    if kind~='moshi_central_grate' and kind~='moshi_drain' and kind~='moshi_channel' and kind~='moshi_dry_platform' then return end
    render.SetColorMaterial()
    local p=e:GetPos()
    if kind=='moshi_channel' then
        local start=e:GetNW2Vector('LOD_MoshiChannelFrom',p)
        local finish=e:GetNW2Vector('LOD_MoshiChannelTo',p)
        local direction=(finish-start):GetNormalized()
        local side=Vector(-direction.y,direction.x,0)*13
        if not e.LODMoshiChannelBounds then
            local extent=finish-start
            e:SetRenderBounds(Vector(-math.abs(extent.x)-20,-math.abs(extent.y)-20,-8),Vector(math.abs(extent.x)+20,math.abs(extent.y)+20,20))
            e.LODMoshiChannelBounds=true
        end
        render.DrawQuad(start+side,finish+side,finish-side,start-side,Color(25,55,70))
        for i=0,7 do
            local at=start+(finish-start)*(i/7)
            render.DrawLine(at-side,at+side,Color(130,150,160),false)
        end
    elseif kind=='moshi_dry_platform' then
        if not e.LODMoshiPlatformBounds then e:SetRenderBounds(Vector(-40,-110,-5),Vector(40,110,15));e.LODMoshiPlatformBounds=true end
        render.DrawBox(p,Angle(),Vector(-31,-98,0),Vector(31,98,1),Color(210,200,140),true)
        for _,y in ipairs({-94,94}) do
            render.DrawBox(p+Vector(0,y,1),Angle(),Vector(-30,-3,0),Vector(30,3,1),Color(70,80,65),true)
        end
    else
        local half=kind=='moshi_central_grate' and 57 or 25
        render.DrawBox(p,Angle(),Vector(-half,-half,-1),Vector(half,half,1),Color(35,45,50),true)
        for i=-4,4 do
            local offset=i*half/5
            render.DrawBox(p+Vector(offset,0,2),Angle(),Vector(-1.7,-half,0),Vector(1.7,half,1),Color(145,165,170),true)
        end
        if kind=='moshi_drain' and e:GetNW2String('LOD_BossObjectState','')~='DRAIN CLEAR' then
            render.DrawBox(p+Vector(0,0,6),Angle(),Vector(-17,-12,-3),Vector(17,12,3),Color(175,130,90),true)
        end
    end
end
