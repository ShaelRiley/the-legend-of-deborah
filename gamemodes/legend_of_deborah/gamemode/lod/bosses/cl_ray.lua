local V = LOD.BossPresentation
V.Modules = V.Modules or {}
local M = {}
function M:Pose(e, size, s)
    local a = e:GetAngles()
    if s.dead then
        local t = math.max(0,CurTime()-(s.deathAt or CurTime()))
        return {angles=Angle(a.p,a.y,math.min(math.max(t-1,0),1)*85)}
    end
    local heat = e:GetNW2Int('LOD_BossHeat',0)
    return {angles=Angle(a.p,a.y,math.sin(CurTime()*(8+heat*5))*heat*.8)}
end
function M:Draw(e, size, s)
    render.SetColorMaterial()
    local scale = tonumber(size) or 1.7
    local heat = s.dead and 0 or e:GetNW2Int('LOD_BossHeat',0)
    local color = heat == 0 and Color(60,80,95) or Color(130+heat*35,70+heat*15,35)
    for i=-3,3 do
        render.DrawBox(e:LocalToWorld(Vector(8,i*5,25)*scale),e:GetAngles(),Vector(-1,-1,-17)*scale,Vector(1,1,17)*scale,color,true)
    end
    local dial=e:LocalToWorld(Vector(8,0,48)*scale)
    render.DrawSphere(dial,5*scale,10,6,Color(220,215,185))
    render.DrawLine(dial,dial+Vector(0,math.sin(heat)*5,math.cos(heat)*5)*scale,Color(200,35,25),false)
end
V.Modules.ray = M
