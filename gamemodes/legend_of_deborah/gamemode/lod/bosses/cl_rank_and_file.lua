local V = LOD.BossPresentation
V.Modules = V.Modules or {}
local M = {}
local labels = {'PERSONNEL','COMPLAINTS','DECEASED','PENDING','DENIED'}
function M:Draw(e,size,state)
    if e:GetNW2String('LOD_BossSupportId','') ~= '' then return end
    size = tonumber(size) or 3.2
    local all = state.dead or e:GetNW2Bool('LOD_RankAllDrawers',false)
    local selected = e:GetNW2Int('LOD_RankDrawer',0)
    render.SetColorMaterial()
    for i,label in ipairs(labels) do
        local opened = all or selected == i
        local x,z = opened and 33 or 20,69 - i * 11
        render.DrawBox(e:LocalToWorld(Vector(x,0,z) * size),e:GetAngles(),Vector(-12,-17,-4.5) * size,
            Vector(2,17,4.5) * size,opened and Color(150,158,151) or Color(89,99,93))
        render.DrawBox(e:LocalToWorld(Vector(x + 2.2,0,z) * size),e:GetAngles(),Vector(-.3,-12,-2.5) * size,
            Vector(.3,12,2.5) * size,Color(230,225,191))
        local angle = e:GetAngles()
        angle:RotateAroundAxis(angle:Up(),90); angle:RotateAroundAxis(angle:Forward(),90)
        cam.Start3D2D(e:LocalToWorld(Vector(x + 2.8,0,z) * size),angle,.065 * size)
        draw.SimpleText(state.dead and i == 5 and 'MISC / CASE CLOSED' or label,'DermaDefaultBold',0,0,Color(20,25,22),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
        cam.End3D2D()
    end
    if state.dead then
        local t = math.min(1,math.max(0,CurTime() - (state.deathAt or CurTime())))
        for i = 1,9 do
            local p = e:LocalToWorld(Vector(38 + i * 4,-25 + i * 5,45 - i * 3 - t * 20) * size)
            render.DrawBox(p,Angle(i * 17,CurTime() * 30 + i * 30,0),Vector(-7,-5,-.2),Vector(7,5,.2),Color(238,230,206))
        end
    end
end
function M:Pose(e,size,state)
    if state.dead then
        return {angles = Angle(math.min(80,math.max(0,CurTime() - (state.deathAt or CurTime()) - .5) * 65),e:GetAngles().y,0)}
    end
end
V.Modules.rank_and_file = M
