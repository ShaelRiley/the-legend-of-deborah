-- No model allocation, world queries or gameplay authority in presentation callbacks.
local V=LOD.BossPresentation
V.Modules=V.Modules or {}
local M={}
local function age(s) return math.max(0,CurTime()-(s.deathAt or CurTime())) end
function M:Pose(e,size,s)
    local a=e:GetAngles()
    if s.dead then
        local t=age(s)
        return {angles=Angle(a.p,a.y,t>=1.5 and 90 or math.sin(t*22)*3),offset=Vector(0,0,t>=1.5 and -3 or 0)}
    end
    return {angles=Angle(a.p,a.y,math.sin(CurTime()*3)*4)}
end
function M:Draw(e,size,s)
    render.SetColorMaterial()
    local running=not s.dead or age(s)<1.5
    local bob=running and math.sin(CurTime()*28)*.8 or 0
    for _,x in ipairs({-3,3}) do
        for _,y in ipairs({-2.4,2.4}) do
            render.DrawSphere(e:LocalToWorld(Vector(x,y,1.5+bob)),1.5,6,4,Color(40,45,50))
        end
    end
    if s.dead and age(s)>=1.9 and age(s)<2.25 then
        render.DrawWireframeSphere(e:GetPos()+Vector(0,0,12),7+(age(s)-1.9)*60,12,6,Color(255,215,50),true)
    end
end
V.Modules.chonker=M
