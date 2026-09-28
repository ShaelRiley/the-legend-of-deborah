include("shared.lua")

local GC = LOD and LOD.Config and LOD.Config.Geometry or {}
local floorColor = GC.FloorColor or Color(46, 49, 51, 255)
local stairColor = GC.StairColor or Color(68, 72, 74, 255)
local stairEdgeColor = GC.DebugColor or Color(225, 145, 48, 255)
local textureTile = GC.FloorTextureTile or 384

local function floorMaterial()
    if LOD.TexturedBox and LOD.TexturedBox.GetIndustrialMaterial then
        return LOD.TexturedBox:GetIndustrialMaterial(GC.FloorMaterialFallback)
    end
    local mat = Material(GC.FloorMaterial or "models/props_wasteland/metal_tram001a")
    if mat:IsError() then
        mat = Material(GC.FloorMaterialFallback or "models/props_c17/FurnitureMetal001a")
    end
    return mat
end

local visualBoxes = visualBoxes or setmetatable({}, {__mode = "k"})

-- Transmission can resume before SetupDataTables installs the accessors.
-- Keep registry membership while waiting so the next ready frame recovers.
local function networkReady(ent)
    return ent.GetBoxMins and ent.GetBoxMaxs and ent.GetBoxKind
end

local function refreshRenderBounds(ent)
    if not networkReady(ent) then return false end
    local mins = ent:GetBoxMins()
    local maxs = ent:GetBoxMaxs()
    local margin = Vector(32, 32, 32)
    ent:SetRenderBounds(mins - margin, maxs + margin)
    return true
end

function ENT:Initialize()
    visualBoxes[self] = true
    refreshRenderBounds(self)
    self._LODNextBoundsRefresh = 0
end

function ENT:Think()
    visualBoxes[self] = true
    if CurTime() >= (self._LODNextBoundsRefresh or 0) and refreshRenderBounds(self) then
        self._LODNextBoundsRefresh = CurTime() + 1
    end
end

function ENT:OnRemove(fullUpdate)
    -- Source may retain this entity across cl_fullupdate without Initialize.
    if not fullUpdate then visualBoxes[self] = nil end
end

hook.Add("NotifyShouldTransmit", "LOD_Recover_lod_static_box", function(ent, transmitting)
    if transmitting and IsValid(ent) and ent:GetClass() == "lod_static_box" then
        visualBoxes[ent] = true
        -- Defer bounds until Think; accessors may not exist in this hook.
        ent._LODNextBoundsRefresh = 0
    end
end)

function ENT:Draw()
end

local function drawFloorSlab(ent, color, getMaterial)
    if ent:GetNW2Bool("LOD_CrateGrate",false) and LOD.TexturedBox and LOD.TexturedBox.DrawGrate then
        LOD.TexturedBox:DrawGrate(ent:GetPos(),ent:GetAngles(),ent:GetBoxMins(),ent:GetBoxMaxs())
        return
    end
    local material = getMaterial()
    if LOD.TexturedBox and LOD.TexturedBox.DrawSlab then
        LOD.TexturedBox:DrawSlab(
            ent:GetPos(),
            ent:GetAngles(),
            ent:GetBoxMins(),
            ent:GetBoxMaxs(),
            material,
            color,
            textureTile
        )
        return
    end

    render.SetMaterial(material)
    render.DrawBox(ent:GetPos(), ent:GetAngles(), ent:GetBoxMins(), ent:GetBoxMaxs(), color)
end

local function drawFullMetalBox(ent, color, getMaterial)
    local material = getMaterial()
    if LOD.TexturedBox and LOD.TexturedBox.Draw then
        LOD.TexturedBox:Draw(
            ent:GetPos(),
            ent:GetAngles(),
            ent:GetBoxMins(),
            ent:GetBoxMaxs(),
            material,
            color,
            textureTile
        )
        return
    end

    render.SetMaterial(material)
    render.DrawBox(ent:GetPos(), ent:GetAngles(), ent:GetBoxMins(), ent:GetBoxMaxs(), color)
end

-- These boxes are submitted manually, bypassing the native entity draw culler.
-- Reject only spheres wholly BEHIND the current perspective camera. A sphere
-- about the entity origin encloses every corner at any rotation, including large
-- offset underdecks. There is no distance/floor/occlusion guess and no draw cap.
local function currentPerspective()
    if not render.GetViewSetup or not EyePos or not EyeVector then return nil end
    local view = render.GetViewSetup(true)
    if not view or view.ortho or view.offcenter
        or not view.fov or not (view.fov > 0 and view.fov < 180)
        or not view.znear or not (view.znear >= 0) then return nil end
    return EyePos(), EyeVector()
end

local function inFrontOfCamera(ent, eye, forward)
    if not eye or not forward then return true end
    local mins, maxs = ent:GetBoxMins(), ent:GetBoxMaxs()
    local cached = ent._LODVisualSphere
    -- Compare scalar copies: native datatable vectors can change in place.
    if not cached or cached.x0 ~= mins.x or cached.y0 ~= mins.y or cached.z0 ~= mins.z
        or cached.x1 ~= maxs.x or cached.y1 ~= maxs.y or cached.z1 ~= maxs.z then
        local x = math.max(math.abs(mins.x), math.abs(maxs.x))
        local y = math.max(math.abs(mins.y), math.abs(maxs.y))
        local z = math.max(math.abs(mins.z), math.abs(maxs.z))
        cached = {x0=mins.x, y0=mins.y, z0=mins.z, x1=maxs.x, y1=maxs.y, z1=maxs.z,
            radius=math.sqrt(x*x + y*y + z*z) + 1}
        ent._LODVisualSphere = cached
    end
    local pos = ent:GetPos()
    local depth = (pos.x-eye.x)*forward.x + (pos.y-eye.y)*forward.y + (pos.z-eye.z)*forward.z
    -- A malformed/unavailable view fails open rather than hiding the floor.
    return not (depth < -cached.radius)
end

hook.Add("PostDrawOpaqueRenderables", "LOD.DrawGeneratedStaticGeometry", function(drawingDepth, drawingSkybox, drawing3DSkybox)
    if drawingDepth or drawingSkybox or drawing3DSkybox then return end

    local eye, forward = currentPerspective()
    -- Resolve the mounted concrete/fallback once per pass, only if needed.
    -- Pass-local ownership is safe for nested RenderView and retries next frame.
    local material
    local function getMaterial()
        if not material then material = floorMaterial() end
        return material
    end
    for ent in pairs(visualBoxes) do
        if IsValid(ent) and networkReady(ent) and not ent:GetNW2Bool("LOD_GeometryHidden", false)
            and inFrontOfCamera(ent, eye, forward) then
            local kind = ent:GetBoxKind()

            -- Ordinary floor runs render only their top and underside. Their
            -- collision remains a substantial 32-unit slab, but internal
            -- row-run side faces are not visible, eliminating false step/riser
            -- seams across a mathematically flat deck. Stair boxes retain all six
            -- faces because their vertical risers are real geometry.
            if kind == 1 then
                drawFloorSlab(ent, floorColor, getMaterial)
                if ent:GetNW2String("LOD_EventArchetype", "") == "false_floor" then
                    render.DrawWireframeBox(ent:GetPos(), ent:GetAngles(), ent:GetBoxMins(), ent:GetBoxMaxs(), stairEdgeColor, false)
                end
            elseif kind == 2 then
                drawFullMetalBox(ent, stairColor, getMaterial)
                render.DrawWireframeBox(
                    ent:GetPos(),
                    ent:GetAngles(),
                    ent:GetBoxMins(),
                    ent:GetBoxMaxs(),
                    stairEdgeColor,
                    true
                )
            elseif kind == 5 then
                -- The continuous level-0 underdeck is deliberately recessed only
                -- half a unit beneath the ordinary deck. Use the identical material
                -- and color and draw only broad faces, so any container-base or
                -- exterior-corner sightline resolves to continuous concrete.
                drawFloorSlab(ent, floorColor, getMaterial)
            end
            -- Kind 7 is the native-hut staging containment boundary. It owns only
            -- server collision and is intentionally invisible on the client.
        end
    end
end)
