-- Stock citizen plus actual muzzle, incisors, ears and a broad crosshatched tail.
-- Render-only geometry: no client entities, model allocations or world scans.
local V = LOD.BossPresentation
V.Modules = V.Modules or {}
local M = {}
local fur,dark,teeth = Color(115,70,38),Color(57,36,24),Color(245,233,193)
local function localBox(e,size,p,lo,hi,color)
    render.DrawBox(e:LocalToWorld(p * size),e:GetAngles(),lo * size,hi * size,color)
end
function M:Draw(e,size,state)
    size = tonumber(size) or 1
    render.SetColorMaterial()
    if e:GetNW2String('LOD_BossSupportId','') == 'jane_propane' then
        local leaks = e:GetNW2Int('LOD_JaneLeaks',0)
        for i = 0,leaks do
            local start = e:LocalToWorld(Vector(0,0,18 + i * 5) * size)
            local finish = start + e:GetRight() * ((i % 2 == 0 and 1 or -1) * (30 + math.sin(CurTime() * 12) * 4))
            render.DrawBeam(start,finish,5,0,1,Color(180,220,180,140))
        end
        local text = e:GetNW2String('LOD_BossAction','')
        if string.find(text,'BLOWTORCH',1,true) or string.find(text,'FLAME BURST',1,true) then
            render.DrawBeam(e:LocalToWorld(Vector(8,0,24) * size),e:LocalToWorld(Vector(32,0,24) * size),6,0,1,Color(255,160,45,200))
        end
        return
    end
    if not e:GetNW2Bool('LOD_Beaver',false) then return end
    -- A readable beaver mask remains visible from the front even over the human face.
    local head = e:LocalToWorld(Vector(2,0,65) * size)
    local bone = e:LookupBone('ValveBiped.Bip01_Head1')
    if bone then local p = e:GetBonePosition(bone); if p and p:DistToSqr(e:GetPos()) > 1 then head = p end end
    local f,r,u = e:GetForward(),e:GetRight(),e:GetUp()
    render.DrawSphere(head + f * (4 * size) + r * (3.3 * size),4.9 * size,10,7,fur)
    render.DrawSphere(head + f * (4 * size) - r * (3.3 * size),4.9 * size,10,7,fur)
    render.DrawSphere(head + f * (8 * size) + u * size,2.2 * size,10,7,dark)
    for _, sign in ipairs({-1,1}) do
        render.DrawSphere(head + r * (sign * 5.1 * size) + u * (6 * size),2.5 * size,8,6,fur)
        render.DrawBox(head + f * (7 * size) + r * (sign * 1.65 * size) - u * (4.1 * size),e:GetAngles(),
            Vector(-1,-1.4,-3.3) * size,Vector(1.2,1.4,1.2) * size,teeth)
    end
    -- Nine finite slices form a flattened, rounded paddle with a narrow root.
    localBox(e,size,Vector(-5,0,23),Vector(-9,-4,-2),Vector(0,4,2),fur)
    for i = 1,9 do
        local halfWidth = 5 + math.sin((i - 1) / 8 * math.pi) * 8
        localBox(e,size,Vector(-12 - i * 3,0,22 - i * 1.3),Vector(-2,-halfWidth,-1.6),Vector(2,halfWidth,1.6),dark)
    end
    for i = 1,6 do
        local x = -16 - i * 4
        render.DrawLine(e:LocalToWorld(Vector(x,-8,23 + (x + 12) * .43) * size),
            e:LocalToWorld(Vector(x - 7,8,20 + (x + 12) * .43) * size),Color(150,102,60),false)
        render.DrawLine(e:LocalToWorld(Vector(x,8,23 + (x + 12) * .43) * size),
            e:LocalToWorld(Vector(x - 7,-8,20 + (x + 12) * .43) * size),Color(150,102,60),false)
    end
end
function M:DrawObject(e,size,state)
    local kind = e:GetNW2String('LOD_BossObjectKind','')
    render.SetColorMaterial()
    if kind == 'chuck_panel' or kind == 'chuck_wood' then
        local label = e:GetNW2String('LOD_BossObjectLabel','')
        if kind == 'chuck_panel' or label == 'PANEL' then
            render.DrawBox(e:GetPos(),e:GetAngles(),Vector(-4,-34,-25),Vector(4,34,25),Color(156,112,62))
            for i = -2,2 do
                render.DrawLine(e:LocalToWorld(Vector(4.2,i * 12,-24)),e:LocalToWorld(Vector(4.2,i * 12,24)),Color(85,59,36),false)
            end
        elseif label == 'TIMBER' then
            render.DrawBox(e:GetPos(),e:GetAngles(),Vector(-37,-12,-12),Vector(37,12,12),Color(109,72,37))
        elseif label == 'PLANK' then
            render.DrawBox(e:GetPos(),e:GetAngles(),Vector(-35,-8,-2),Vector(35,8,2),Color(181,139,85))
        end
    elseif kind == 'jane_rack' then
        local p = e:GetPos()
        for i = -1,1 do
            render.DrawBox(p + Vector(0,i * 14,22),e:GetAngles(),Vector(-6,-5,-16),Vector(6,5,16),Color(160,178,170))
            render.DrawBeam(p + Vector(0,i * 14,38),p + Vector(0,i * 14,48),4,0,1,Color(90,100,105))
        end
        render.DrawBeam(p + Vector(0,-20,49),p + Vector(0,20,49),5,0,1,Color(105,118,125))
    elseif kind == 'jane_death' then
        local t = math.max(0,CurTime() - e:GetCreationTime())
        local p = e:GetPos()
        if t < 1.6 then
            render.DrawBeam(p + Vector(0,0,45),p + Vector(18,0,45),2,0,1,Color(190,220,190,100))
        else
            local fraction = math.max(0,1 - (t - 1.6) / 1.6)
            render.DrawSphere(p + Vector(0,0,22),(1 - fraction) * 100 + 20,12,8,Color(255,150,35,math.floor(fraction * 145)))
            render.DrawSphere(p + Vector(0,0,30),(1 - fraction) * 65 + 15,10,8,Color(255,230,120,math.floor(fraction * 130)))
        end
    end
end
function M:Pose(e,size,state)
    if state.dead and e:GetNW2String('LOD_BossSupportId','') == '' then
        return {angles = Angle(0,e:GetAngles().y,math.min(85,(CurTime() - (state.deathAt or CurTime())) * 80))}
    end
end
V.Modules.chuck = M
