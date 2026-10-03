local V = LOD.BossPresentation
V.Modules = V.Modules or {}
local M = {}
function M:Pose(e, size, s)
    local a = e:GetAngles()
    if s.dead then
        local t = math.max(0, CurTime() - (s.deathAt or CurTime()))
        return {angles = Angle(a.p, a.y + math.min(t,1)*40, math.min(math.max(t-1,0),1)*70), offset = s.deathDestination and (Vector(s.deathDestination.x,s.deathDestination.y,s.deathDestination.z)-e:GetPos())*math.min(t,1) or e:GetForward()*math.min(t,1)*80}
    end
    local damaged = (s.phase or 1) == 3
    return {angles = Angle(a.p, a.y, math.sin(CurTime()*(damaged and 15 or 5))*(damaged and 6 or 1.5))}
end
function M:Draw(e, size, s)
    render.SetColorMaterial()
    local scale = tonumber(size) or 1.45
    local rummage = tostring(s.action or e:GetNW2String('LOD_BossAction','')):find('RUMMAGE',1,true)
    -- Face and rattling basket stock remain attached to the cart, not unowned props.
    for _, side in ipairs({-1,1}) do
        local eye = e:LocalToWorld(Vector(23*scale, side*12*scale, 48*scale))
        render.DrawSphere(eye, 4*scale, 8, 5, Color(245,240,210))
        render.DrawSphere(eye+e:GetForward()*2*scale, 2*scale, 6, 4, Color(15,20,20))
    end
    for i = 1, 3 do
        local height = rummage and math.sin(CurTime()*19+i)*4 or 0
        render.DrawBox(e:LocalToWorld(Vector((i-2)*13*scale,0,(43+height)*scale)),e:GetAngles(),Vector(-5,-5,-5)*scale,Vector(5,5,5)*scale,Color(140+i*20,170,90),true)
    end
end
V.Modules.ollie = M
