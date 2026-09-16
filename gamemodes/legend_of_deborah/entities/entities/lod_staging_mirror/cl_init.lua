LOD = LOD or {}
LOD.RuntimeReceipts = LOD.RuntimeReceipts or {}
LOD.RuntimeReceipts["mirror"] = "weapon-surfaces-20260916-01"
include("shared.lua")

local RT_W, RT_H = 320, 640
local MIRROR_W, MIRROR_H = 64, 132
local rawRT = GetRenderTarget("lod_staging_full_length_mirror_raw_v4", RT_W, RT_H)
local displayRT = GetRenderTarget("lod_staging_full_length_mirror_display_v4", RT_W, RT_H)
local rawMat = CreateMaterial("lod_staging_full_length_mirror_raw_mat_v4", "UnlitGeneric", {
    ["$basetexture"] = rawRT:GetName(),
    ["$vertexcolor"] = "1",
    ["$vertexalpha"] = "1"
})
local mirrorMat = CreateMaterial("lod_staging_full_length_mirror_mat_v4", "UnlitGeneric", {
    ["$basetexture"] = displayRT:GetName(),
    ["$vertexcolor"] = "1",
    ["$vertexalpha"] = "1"
})

local renderingMirror = false
local nextUpdate = 0

function ENT:Initialize()
    self:SetRenderBounds(Vector(-110, -110, -20), Vector(110, 110, 170))
end

local function mirrorCenter(ent)
    return ent:GetPos() + Vector(0, 0, MIRROR_H * 0.5 + 5)
end

local function visibleNormal(ent, surfacePos)
    local normal = ent:GetForward():GetNormalized()
    if (EyePos() - surfacePos):Dot(normal) < 0 then normal = -normal end
    return normal
end

local function drawFrame(ent, useReflection)
    local pos = ent:GetPos()
    local ang = ent:GetAngles()
    local center = mirrorCenter(ent)
    local frameNormal = ent:GetForward():GetNormalized()

    render.SetColorMaterial()
    render.DrawBox(center, ang,
        Vector(-3.5, -(MIRROR_W * 0.5 + 5), -(MIRROR_H * 0.5 + 5)),
        Vector(3.5, MIRROR_W * 0.5 + 5, MIRROR_H * 0.5 + 5),
        Color(80, 62, 47))
    render.DrawBox(center + frameNormal * 3.7, ang,
        Vector(-0.8, -MIRROR_W * 0.5, -MIRROR_H * 0.5),
        Vector(0.8, MIRROR_W * 0.5, MIRROR_H * 0.5),
        Color(28, 32, 35))

    local surfacePos = center + frameNormal * 4.8
    local normal = visibleNormal(ent, surfacePos)
    if useReflection then
        render.SetMaterial(mirrorMat)
        render.DrawQuadEasy(surfacePos, normal, MIRROR_W, MIRROR_H,
            Color(255, 255, 255, 255), 0)
    else
        render.SetColorMaterial()
        render.DrawQuadEasy(surfacePos, normal, MIRROR_W, MIRROR_H,
            Color(82, 94, 104, 255), 0)
    end
end

function ENT:Draw()
    drawFrame(self, not renderingMirror)
end

function ENT:DrawTranslucent()
    self:Draw()
end

local function eligibleMirror()
    local ply = LocalPlayer()
    if not IsValid(ply) or ply:GetNW2Bool("LOD_Deployed", false) then return nil end
    if LOD and LOD.FieldManual and IsValid(LOD.FieldManual.Frame) then return nil end

    local best, bestDist
    for _, ent in ipairs(ents.FindByClass("lod_staging_mirror")) do
        if IsValid(ent) then
            local d = ply:GetPos():DistToSqr(ent:GetPos())
            if not bestDist or d < bestDist then best, bestDist = ent, d end
        end
    end
    if not IsValid(best) or bestDist > (900 * 900) then return nil end
    return best, ply
end

-- Render a small live camera from the mirror surface toward the staged player.
-- Source render targets arrive vertically inverted when mapped directly onto a
-- world quad, so copy the raw target through an explicit V-flip before display.
hook.Add("PreRender", "LOD_StagingMirrorRender", function()
    if renderingMirror or CurTime() < nextUpdate then return end
    local mirror, ply = eligibleMirror()
    if not IsValid(mirror) or not IsValid(ply) then return end
    nextUpdate = CurTime() + 0.10

    local center = mirrorCenter(mirror)
    local towardPlayer = ply:EyePos() - center
    if towardPlayer:LengthSqr() < 4 then return end
    towardPlayer:Normalize()

    local origin = center + towardPlayer * 8
    local target = ply:GetPos() + Vector(0, 0, 42)
    local viewAngles = (target - origin):Angle()

    renderingMirror = true

    local targetOpen, cameraOpen = false, false
    local ok, err = xpcall(function()
    render.PushRenderTarget(rawRT)
    targetOpen = true
        render.Clear(22, 25, 29, 255, true, true)
        render.RenderView({
            origin = origin,
            angles = viewAngles,
            x = 0,
            y = 0,
            w = RT_W,
            h = RT_H,
            fov = 96,
            drawhud = false,
            drawviewmodel = false,
            dopostprocess = false,
            drawviewer = true
        })
    render.PopRenderTarget()
    targetOpen = false

    render.PushRenderTarget(displayRT)
    targetOpen = true
        render.Clear(22, 25, 29, 255, true, true)
        cam.Start2D()
        cameraOpen = true
            surface.SetMaterial(rawMat)
            surface.SetDrawColor(255, 255, 255, 255)
            -- Flip V explicitly so the reflected image is upright and fill the
            -- entire display target rather than the upper half of the frame.
            surface.DrawTexturedRectUV(0, 0, RT_W, RT_H, 0, 1, 1, 0)
        cam.End2D()
        cameraOpen = false
    render.PopRenderTarget()
    targetOpen = false

    end, debug.traceback)
    -- A Lua error from RenderView/another addon's draw hook must not strand
    -- the engine on this render target or leave the recursion guard latched.
    if cameraOpen then cam.End2D() end
    if targetOpen then render.PopRenderTarget() end
    renderingMirror = false
    if not ok then
        nextUpdate = CurTime() + 5
        ErrorNoHalt("[LOD mirror] " .. tostring(err) .. "\n")
    end
end)

hook.Add("ShouldDrawLocalPlayer", "LOD_StagingMirrorLocalPlayer", function()
    if renderingMirror then return true end
end)
