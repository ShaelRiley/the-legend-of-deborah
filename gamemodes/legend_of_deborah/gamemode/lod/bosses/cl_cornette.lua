local V = LOD.BossPresentation
V.Modules = V.Modules or {}
local M = {}
local steel,dark = Color(178,198,207),Color(45,54,65)
local function drill(start,forward,right,up,size,spin)
    render.SetColorMaterial()
    local oldA,oldB
    for i = 0,8 do
        local t = i / 8
        local center = start + forward * (t * 25 * size)
        local radius = (5.8 * (1 - t) + .3) * size
        render.DrawSphere(center,radius,8,6,steel)
        local theta = spin + t * math.pi * 5
        local radial = right * math.cos(theta) + up * math.sin(theta)
        local a,b = center + radial * radius,center - radial * radius
        if oldA then render.DrawBeam(oldA,a,1.8 * size,0,1,dark); render.DrawBeam(oldB,b,1.8 * size,0,1,dark) end
        oldA,oldB = a,b
    end
end
local function bonePoint(e,name,fallback,size)
    local id = e:LookupBone(name)
    if id then local p = e:GetBonePosition(id); if p and p:DistToSqr(e:GetPos()) > 1 then return p end end
    return e:LocalToWorld(fallback * size)
end
function M:Draw(e,size,state)
    if e:GetNW2String('LOD_BossSupportId','') ~= '' then return end
    size = tonumber(size) or 1.15
    local f,r,u = e:GetForward(),e:GetRight(),e:GetUp()
    local strain = e:GetNW2Int('LOD_CornetteStrain',0)
    local spin = CurTime() * (12 + strain * .14)
    for i,hand in ipairs({'Left','Right'}) do
        local sign = i == 1 and -1 or 1
        local point = bonePoint(e,i == 1 and 'ValveBiped.Bip01_L_Hand' or 'ValveBiped.Bip01_R_Hand',Vector(4,sign * 18,45),size)
        if not state.dead and not e:GetNW2Bool('LOD_CornetteMissing' .. hand,false) then drill(point,f,r,u,size,spin * sign)
        else render.SetColorMaterial(); render.DrawSphere(point,4 * size,8,6,dark) end
        local foot = bonePoint(e,i == 1 and 'ValveBiped.Bip01_L_Foot' or 'ValveBiped.Bip01_R_Foot',Vector(2,sign * 6,4),size)
        render.DrawBox(foot - u * (2 * size),e:GetAngles(),Vector(-6,-4,-1) * size,Vector(10,4,1) * size,steel)
        for j = -1,1,2 do
            for k = -1,1,2 do render.DrawSphere(foot + f * (j * 5 * size) + r * (k * 4 * size) - u * (4 * size),2.8 * size,8,6,dark) end
        end
        -- Exposed metal forearm/shin plates make the stock female body read as an android.
        render.DrawBox(e:LocalToWorld(Vector(2,sign * 8,23) * size),e:GetAngles(),Vector(-4,-3,-9) * size,Vector(4,3,9) * size,steel)
    end
    local head = bonePoint(e,'ValveBiped.Bip01_Head1',Vector(2,0,66),size)
    if e:GetNW2Bool('LOD_CornetteCrying',false) and not state.dead then
        for sign = -1,1,2 do
            local p = head + f * (5 * size) + r * (sign * 2.4 * size)
            render.DrawBeam(p,p - u * (8 * size),1.2 * size,0,1,Color(120,220,255,180))
        end
    end
    if (state.phase or 1) >= 3 then
        for i = 1,3 do
            local p = e:LocalToWorld(Vector(0,(i - 2) * 10,48) * size)
            render.DrawBeam(p,p + Vector(math.sin(spin + i) * 8,math.cos(spin + i) * 8,9),1,0,1,Color(255,195,65,150))
            render.DrawSphere(p + Vector(0,0,8 + i * 5),3 + i,6,4,Color(70,75,80,45))
        end
    end
    if state.dead then
        local t = math.max(0,CurTime() - (state.deathAt or CurTime()))
        if t < 1.6 then
            for sign = -1,1,2 do
                drill(e:GetPos() + r * (sign * (25 + t * 180)) + u * 50,r * sign,f,u,size,spin)
            end
        end
    end
end
function M:DrawObject(e,size,state)
    local kind = e:GetNW2String('LOD_BossObjectKind','')
    if kind == 'cornette_column' then
        render.SetColorMaterial()
        render.DrawBox(e:GetPos(),e:GetAngles(),Vector(-22,-22,0),Vector(22,22,150),Color(125,130,125))
        for i = 1,4 do render.DrawBox(e:GetPos() + Vector(0,0,i * 31),e:GetAngles(),Vector(-24,-24,-3),Vector(24,24,3),Color(80,89,85)) end
        return
    end
    if kind ~= 'cornette_drill' then return end
    drill(e:GetPos(),e:GetForward(),e:GetRight(),e:GetUp(),.8,CurTime() * 35)
end
function M:Pose(e,size,state)
    local a = e:GetAngles()
    if state.dead then
        local t = math.max(0,CurTime() - (state.deathAt or CurTime()))
        return {angles = Angle(0,a.y + t * 400,math.min(85,t * 60))}
    end
    local backwards = e:GetNW2String('LOD_BossAction','') == 'TEARFUL RETREAT: BREATHER'
    return {angles = Angle(a.p,a.y + (backwards and 180 or 0),math.sin(CurTime() * 4) * (e:GetNW2Int('LOD_CornetteStrain',0) * .08 + 3))}
end
V.Modules.cornette = M
