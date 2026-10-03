local V=LOD.BossPresentation
V.Modules=V.Modules or {}
local M={}
function M:Pose(e,size,s)
    local a=e:GetAngles();local name=s.action or e:GetNW2String('LOD_BossAction','')
    if not s.dead and name=='BARREL ROLL' then return {angles=Angle(90,a.y,CurTime()*240)} end
    if s.dead then
        local t=math.max(0,CurTime()-(s.deathAt or CurTime()))
        return {angles=Angle(0,a.y,t<2.8 and math.sin(t*25)*2 or 90),offset=Vector(0,0,t>=2.8 and -35 or 0)}
    end
    return {angles=a}
end
function M:Draw(e,size,s)
    local scale=tonumber(size) or 2.65
    local name=s.action or e:GetNW2String('LOD_BossAction','')
    local t=s.dead and math.max(0,CurTime()-(s.deathAt or CurTime())) or 0
    render.SetColorMaterial()
    if name=='DARYL IS LIT' or (s.dead and t<2.8) then
        local fuse=e:GetPos()+Vector(0,0,48*scale)
        render.DrawSphere(fuse,4+math.sin(CurTime()*30)*1.5,8,6,Color(255,165,30))
        render.DrawLine(fuse-Vector(0,0,10),fuse,Color(245,215,150),false)
    end
    if (s.phase or 1)>=3 or e:GetNW2Bool('LOD_BossScorched',false) then
        for n=1,3 do
            render.DrawLine(e:LocalToWorld(Vector(12*scale,(n-2)*5*scale,12*scale)),e:LocalToWorld(Vector(14*scale,(n-2)*5*scale+3,35*scale)),Color(20,15,12),false)
        end
    end
    if s.dead and t>=2.8 then
        render.DrawQuadEasy(e:GetPos()+Vector(0,0,3),Vector(0,0,1),175,175,Color(18,16,15,230),0)
        if t<3.6 then
            local k=(t-2.8)/.8
            render.DrawSphere(e:GetPos()+Vector(0,0,45),35+190*k,16,12,Color(255,120,20,math.floor(190*(1-k))))
        end
    end
end
V.Modules.daryl=M
