-- Mirror facets and separated bone outlines use only existing render primitives.
local V=LOD.BossPresentation
V.Modules=V.Modules or {}
local M={}
function M:Pose(e,size,state)
    local a=e:GetAngles();local broken=e:GetNW2Float("LOD_BoneBreakUntil",0)>CurTime()
    if broken then return {angles=Angle(0,a.y,72),offset=Vector(0,0,12)} end
    if state.dead then
        local age=math.max(0,CurTime()-(state.deathAt or CurTime()))
        return {angles=Angle(a.p,a.y+age*35,math.min(85,age*45)),offset=Vector(0,0,-math.min(45,age*20))}
    end
    return {angles=a}
end
function M:Draw(e,size,state)
    render.SetColorMaterial()
    local giant=e:GetNW2Bool("LOD_MelfGiant",false)
    local origin=e:GetPos();local radius=giant and 60 or 20
    if e:GetNW2Float("LOD_BoneBreakUntil",0)>CurTime() then
        for i=1,6 do
            local angle=i*math.pi/3
            local p=origin+Vector(math.cos(angle)*35,math.sin(angle)*35,10+i*2)
            render.DrawBox(p,Angle(0,math.deg(angle),i*17),Vector(-13,-2,-2),Vector(13,2,2),Color(245,240,215))
        end
    end
    if state.dead then
        local age=math.max(0,CurTime()-(state.deathAt or CurTime()))
        if age<2.4 then
            for i=1,12 do
                local angle=i*math.pi/6
                local p=origin+Vector(math.cos(angle),math.sin(angle),.4)*(radius+age*80)+Vector(0,0,70-age*22)
                render.DrawBox(p,Angle(age*90+i*31,i*30,age*50),Vector(-3,-1,-8),Vector(3,1,8),Color(155,225,255,220))
            end
            render.DrawWireframeSphere(origin+Vector(0,0,40),math.max(2,32-age*16),10,6,Color(220,245,255),true)
        end
    else
        render.DrawWireframeSphere(origin+Vector(0,0,giant and 130 or 44),radius,8,4,Color(140,220,255,50),true)
    end
end
V.Modules.melf=M
