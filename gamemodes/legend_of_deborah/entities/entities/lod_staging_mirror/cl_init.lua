include("shared.lua")

local RT_W, RT_H = 256, 512
local MIRROR_W, MIRROR_H = 58, 116
local mirrorRT = GetRenderTarget("lod_staging_full_length_mirror_v1", RT_W, RT_H)
local mirrorMat = CreateMaterial("lod_staging_full_length_mirror_mat_v1", "UnlitGeneric", {
    ["$basetexture"] = mirrorRT:GetName(),
    ["$vertexcolor"] = "1",
    ["$vertexalpha"] = "1"
})
local renderingMirror = false
local nextUpdate = 0

function ENT:Initialize()
    self:SetRenderBounds(Vector(-12, -42, 0), Vector(12, 42, 125))
end

local function drawFrame(ent, useReflection)
    local pos = ent:GetPos()
    local ang = ent:GetAngles()
    local center = pos + Vector(0, 0, MIRROR_H * 0.5 + 4)

    render.SetColorMaterial()
    render.DrawBox(center, ang,
        Vector(-2.8, -(MIRROR_W * 0.5 + 4), -(MIRROR_H * 0.5 + 4)),
        Vector(2.8, MIRROR_W * 0.5 + 4, MIRROR_H * 0.5 + 4),
        Color(72, 61, 50))
    render.DrawBox(center + ent:GetForward() * 3.1, ang,
        Vector(-0.7, -MIRROR_W * 0.5, -MIRROR_H * 0.5),
        Vector(0.7, MIRROR_W * 0.5, MIRROR_H * 0.5),
        Color(25, 29, 33))

    local surfacePos = center + ent:GetForward() * 4.0
    if useReflection then
        render.SetMaterial(mirrorMat)
        render.DrawQuadEasy(surfacePos, ent:GetForward(), MIRROR_W - 5, MIRROR_H - 6,
            Color(225, 235, 242, 255), 0)
    else
        render.SetColorMaterial()
        render.DrawQuadEasy(surfacePos, ent:GetForward(), MIRROR_W - 5, MIRROR_H - 6,
            Color(72, 84, 92, 255), 0)
    end
end

function ENT:Draw()
    drawFrame(self, not renderingMirror)
end

local function eligibleMirror()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:GetNW2Bool("LOD_Staged", false) then return nil end
    if LOD and LOD.FieldManual and IsValid(LOD.FieldManual.Frame) then return nil end
    local mirrors = ents.FindByClass("lod_staging_mirror")
    local ent = mirrors[1]
    if not IsValid(ent) then return nil end
    if ply:GetPos():DistToSqr(ent:GetPos()) > (850 * 850) then return nil end
    return ent
end

hook.Add("PreRender", "LOD_StagingMirrorRender", function()
    if renderingMirror or CurTime() < nextUpdate then return end
    local mirror = eligibleMirror()
    if not IsValid(mirror) then return end
    nextUpdate = CurTime() + 0.12

    local normal = mirror:GetForward()
    local origin = mirror:GetPos() + normal * 7 + Vector(0, 0, 61)
    local angles = normal:Angle()

    renderingMirror = true
    render.PushRenderTarget(mirrorRT)
        render.Clear(16, 18, 21, 255, true, true)
        render.RenderView({
            origin = origin,
            angles = angles,
            x = 0,
            y = 0,
            w = RT_W,
            h = RT_H,
            fov = 72,
            drawhud = false,
            drawviewmodel = false,
            dopostprocess = false,
            drawviewer = true
        })
    render.PopRenderTarget()
    renderingMirror = false
end)
