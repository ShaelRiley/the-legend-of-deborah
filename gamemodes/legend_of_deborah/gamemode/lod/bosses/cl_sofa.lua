local V=LOD.BossPresentation
V.Modules=V.Modules or {}
local M={}
function M:Pose(e,size,s)
    local a=e:GetAngles()
    if s.dead then
        local t=math.max(0,CurTime()-(s.deathAt or CurTime()))
        local roll=t<.65 and 0 or math.min(180,(t-.65)/.55*180)
        return {angles=Angle(a.p,a.y,roll),offset=e:GetForward()*math.min(t,.65)*65}
    end
    if e:GetNW2Bool('LOD_BossInverted',false) then return {angles=Angle(0,a.y,180),offset=Vector(0,0,40)} end
    if e:GetNW2Bool('LOD_BossVertical',false) then return {angles=Angle(78,a.y,0),offset=Vector(0,0,30)} end
    return {angles=Angle(a.p,a.y,(s.phase or 1)>=3 and 7 or 0)}
end
function M:Draw(e,size,s)
    local scale=tonumber(size) or 2.8
    render.SetColorMaterial()
    if (s.phase or 1)>=3 or e:GetNW2Bool('LOD_BossTorn',false) then
        -- Torn upholstery and springs use inexpensive canonical render primitives.
        for n=-1,1 do
            local p=e:LocalToWorld(Vector(n*16*scale,-10*scale,23*scale))
            render.DrawSphere(p,4*scale,6,4,Color(235,226,195))
            for k=0,3 do
                local z=k*3
                render.DrawLine(p+Vector(-4,0,z),p+Vector(4,0,z+2),Color(90,95,105),false)
            end
        end
    end
    if e:GetNW2Bool('LOD_BossSectionDetached',false) then
        render.DrawLine(e:LocalToWorld(Vector(0,-24*scale,12*scale)),e:LocalToWorld(Vector(0,24*scale,20*scale)),Color(25,20,18),false)
    end
    if s.dead then
        local t=math.max(0,CurTime()-(s.deathAt or CurTime()))
        if t>=2.5 and t<3.2 then
            local p=e:GetPos()+Vector(0,0,55)
            render.DrawWireframeSphere(p,8+math.sin((t-2.5)*math.pi/.7)*24,10,5,Color(180,185,195),true)
        end
    end
end
V.Modules.sofa=M
