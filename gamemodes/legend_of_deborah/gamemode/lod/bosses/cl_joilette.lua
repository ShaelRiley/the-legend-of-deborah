-- The BDD's crack count is server-owned; circles never infer hits locally.
local V=LOD.BossPresentation
V.Modules=V.Modules or {}
local M={}
function M:Pose(e,size,state)
    local a=e:GetAngles()
    if state.dead then
        local age=math.max(0,CurTime()-(state.deathAt or CurTime()))
        return {angles=Angle(a.p,a.y+age*age*75,a.r),offset=Vector(0,0,-math.min(60,age*22))}
    end
    return {angles=a}
end
function M:Draw(e,size,state)
    render.SetColorMaterial()
    local p=e:GetPos()+Vector(0,0,75)
    local hits=e:GetNW2Int("LOD_BDDHits",0)
    if e:GetNW2Bool("LOD_BDDActive",true) and not state.dead then
        render.DrawWireframeSphere(p,115,16,8,Color(95+hits*50,210-hits*45,255),true)
        for i=1,hits do
            local side=i==1 and 1 or -1
            render.DrawBeam(p+Vector(side*28,-100,-45),p+Vector(side*5,-106,0),5,0,1,Color(255,235,140))
            render.DrawBeam(p+Vector(side*5,-106,0),p+Vector(side*40,-90,60),5,0,1,Color(255,235,140))
        end
    elseif state.dead then
        local age=math.max(0,CurTime()-(state.deathAt or CurTime()))
        if age<2.4 then
            for i=1,10 do
                local angle=i*math.pi*.2+age*6
                local radius=math.max(4,105-age*44)
                render.DrawSphere(p+Vector(math.cos(angle)*radius,math.sin(angle)*radius,20-age*30),4,5,4,Color(170,225,255))
            end
        end
    end
end
V.Modules.joilette=M
