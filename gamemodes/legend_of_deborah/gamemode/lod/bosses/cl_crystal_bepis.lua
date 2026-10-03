local V = LOD.BossPresentation
V.Modules = V.Modules or {}
local M = {}
function M:Pose(e, size, s)
    local a = e:GetAngles()
    if s.dead then
        local t = math.max(0,CurTime()-(s.deathAt or CurTime()))
        return {angles = Angle(math.min(t,1)*28,a.y,math.min(t,1)*12),offset=(s.deathDestination and (Vector(s.deathDestination.x,s.deathDestination.y,s.deathDestination.z)-e:GetPos())*math.min(t,1) or Vector())+Vector(0,0,-math.min(t,1)*25)}
    end
end
function M:Draw(e, size, s)
    render.SetColorMaterial()
    local scale = tonumber(size) or 1.1
    local p = e:LocalToWorld(Vector(12,-13,45)*scale)
    render.DrawBox(p,e:GetAngles(),Vector(-3,-3,-6)*scale,Vector(3,3,6)*scale,Color(30,95,175),true)
    render.DrawBox(p+Vector(0,0,2),e:GetAngles(),Vector(-3.2,-3.2,-1)*scale,Vector(3.2,3.2,1)*scale,Color(235,245,230),true)
    if tostring(s.action or ''):find('THIRSTY',1,true) then
        render.DrawWireframeSphere(e:GetPos()+Vector(0,0,85)*scale,7,10,5,Color(80,220,105),true)
    end
end
V.Modules.crystal_bepis = M
