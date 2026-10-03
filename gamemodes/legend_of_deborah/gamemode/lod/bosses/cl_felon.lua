local V=LOD.BossPresentation
V.Modules=V.Modules or {}
local M={}
function M:Pose(e,size,s)
    local a=e:GetAngles()
    if s.dead then
        local t=math.max(0,CurTime()-(s.deathAt or CurTime()))
        return {angles=Angle(t<1.3 and t*180 or 90,a.y,0),offset=Vector(0,0,t<1.3 and math.sin(t/1.3*math.pi)*230 or -8)}
    end
    return {angles=Angle(a.p,a.y,math.sin(CurTime()*2)*6)}
end
function M:Draw(e,size,s)
    local scale=tonumber(size) or 3.4
    if (s.phase or 1)>=3 or e:GetNW2Bool('LOD_BossCracked',false) then
        for n=1,3 do
            local y=(n-2)*4*scale
            render.DrawLine(e:LocalToWorld(Vector(-5*scale,y,7*scale)),e:LocalToWorld(Vector(0,y+3*scale,9*scale)),Color(165,45,40),false)
            render.DrawLine(e:LocalToWorld(Vector(0,y+3*scale,9*scale)),e:LocalToWorld(Vector(5*scale,y,7*scale)),Color(165,45,40),false)
        end
    end
    if s.dead then
        local t=math.max(0,CurTime()-(s.deathAt or CurTime()))
        if t>=1.3 then
            render.SetColorMaterial()
            render.DrawQuadEasy(e:GetPos()+Vector(0,0,2),Vector(0,0,1),105,90,Color(180,45,40,210),0)
        end
    end
end
V.Modules.felon=M
