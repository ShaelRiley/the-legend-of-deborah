local V=LOD.BossPresentation
V.Modules=V.Modules or {}
local M={}
function M:Draw(e,size,state)
    render.SetColorMaterial()
    local p=e:GetPos()+Vector(0,0,12)
    render.DrawBox(p,e:GetAngles(),Vector(-22,-18,-8),Vector(22,18,4),Color(45,48,53))
    render.DrawSphere(p+Vector(0,0,state.dead and 1 or 8),15,12,6,state.dead and Color(75,30,30) or Color(245,35,35))
end
V.Modules.button=M
