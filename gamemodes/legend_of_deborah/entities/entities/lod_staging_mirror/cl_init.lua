include("shared.lua")

local RT_W, RT_H = 256, 512
local MIRROR_W, MIRROR_H = 62, 122
local mirrorRT = GetRenderTarget("lod_staging_full_length_mirror_v2", RT_W, RT_H)
local mirrorMat = CreateMaterial("lod_staging_full_length_mirror_mat_v2", "UnlitGeneric", {
    ["$basetexture"] = mirrorRT:GetName(),
    ["$vertexcolor"] = "1",
    ["$vertexalpha"] = "1"
})
local renderingMirror = false
local nextUpdate = 0

function ENT:Initialize()
    self:SetRenderBounds(Vector(-16, -48, 0), Vector(16, 48, 132))
end

local function drawFrame(ent, useReflection)
    local pos = ent:GetPos()
    local ang = ent:GetAngles()
    local normal = ent:GetForward()
    local center = pos + Vector(0, 0, MIRROR_H * 0.5 + 5)

    render.SetColorMaterial()
    render.DrawBox(center, ang,
        Vector(-3.5, -(MIRROR_W * 0.5 + 5), -(MIRROR_H * 0.5 + 5)),
        Vector(3.5, MIRROR_W * 0.5 + 5, MIRROR_H * 0.5 + 5),
        Color(80, 62, 47))
    render.DrawBox(center + normal * 3.7, ang,
        Vector(-0.8, -MIRROR_W * 0.5, -MIRROR_H * 0.5),
        Vector(0.8, MIRROR_W * 0.5, MIRROR_H * 0.5),
        Color(28, 32, 35))

    local surfacePos = center + normal * 4.7
    if useReflection then
        render.SetMaterial(mirrorMat)
        render.DrawQuadEasy(surfacePos, normal, MIRROR_W - 6, MIRROR_H - 7,
            Color(235, 241, 246, 255), 0)
    else
        render.SetColorMaterial()
        render.DrawQuadEasy(surfacePos, normal, MIRROR_W - 6, MIRROR_H - 7,
            Color(78, 88, 96, 255), 0)
    end
end

function ENT:Draw()
    drawFrame(self, not renderingMirror)
end

local function eligibleMirror()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:GetNW2Bool("LOD_Staged", false) then return nil end
    if LOD and LOD.FieldManual and IsValid(LOD.FieldManual.Frame) then return nil end
    local ent = ents.FindByClass("lod_staging_mirror")[1]
    if not IsValid(ent) then return nil end
    if ply:GetPos():DistToSqr(ent:GetPos()) > (900 * 900) then return nil end
    return ent, ply
end

hook.Add("PreRender", "LOD_StagingMirrorRender", function()
    if renderingMirror or CurTime() < nextUpdate then return end
    local mirror, ply = eligibleMirror()
    if not IsValid(mirror) or not IsValid(ply) then return end
    nextUpdate = CurTime() + 0.10

    local normal = mirror:GetForward():GetNormalized()
    local plane = mirror:GetPos() + normal * 5 + Vector(0, 0, 64)
    local eye = EyePos()
    local eyeAngles = EyeAngles()
    local distance = (eye - plane):Dot(normal)
    if distance <= 2 then return end

    local reflectedOrigin = eye - normal * (2 * distance)
    local viewForward = eyeAngles:Forward()
    local reflectedForward = viewForward - normal * (2 * viewForward:Dot(normal))
    local reflectedAngles = reflectedForward:Angle()

    renderingMirror = true
    render.PushRenderTarget(mirrorRT)
        render.Clear(14, 16, 18, 255, true, true)
        render.RenderView({
            origin = reflectedOrigin,
            angles = reflectedAngles,
            x = 0,
            y = 0,
            w = RT_W,
            h = RT_H,
            fov = 74,
            drawhud = false,
            drawviewmodel = false,
            dopostprocess = false,
            drawviewer = true
        })
    render.PopRenderTarget()
    renderingMirror = false
end)
