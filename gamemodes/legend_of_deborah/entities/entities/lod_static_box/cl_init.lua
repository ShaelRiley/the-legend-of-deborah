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

LOD = LOD or {}
LOD.TexturedBox = LOD.TexturedBox or {}
-- Scheduled Think must not delay existing floor registration after Lua refresh.
-- Keep the same weak registry with the existing textured-geometry authority.
LOD.TexturedBox.StaticVisualBoxes = LOD.TexturedBox.StaticVisualBoxes or setmetatable({}, {__mode = "k"})
local visualBoxes = LOD.TexturedBox.StaticVisualBoxes

-- Transmission can resume before SetupDataTables installs the accessors.
-- Keep registry membership while waiting so the next ready frame recovers.
local function networkReady(ent)
    return ent.GetBoxMins and ent.GetBoxMaxs and ent.GetBoxKind
end

local function refreshRenderBounds(ent)
    if not networkReady(ent) then return false end
    local mins = ent:GetBoxMins()
    local maxs = ent:GetBoxMaxs()
    local b = ent._LODBoundsSnapshot
    if b and b[1]==mins.x and b[2]==mins.y and b[3]==mins.z
        and b[4]==maxs.x and b[5]==maxs.y and b[6]==maxs.z then return true end
    ent._LODBoundsSnapshot = {mins.x,mins.y,mins.z,maxs.x,maxs.y,maxs.z}
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
    local now = CurTime()
    if now >= (self._LODNextBoundsRefresh or 0) and refreshRenderBounds(self) then
        self._LODNextBoundsRefresh = now + 1
    end
    -- Bounds already refresh once per second. Let Source sleep until that
    -- deadline instead of invoking an otherwise empty callback every frame.
    -- Incomplete datatables retain immediate native retries.
    if self.SetNextClientThink and (self._LODNextBoundsRefresh or 0) > now then
        self:SetNextClientThink(self._LODNextBoundsRefresh)
        return true
    end
end

function ENT:OnRemove(fullUpdate)
    -- Source may retain this entity across cl_fullupdate without Initialize.
    if not fullUpdate then visualBoxes[self] = nil end
    self._LODBoundsSnapshot = nil
    self._LODVisualBox = nil
end

hook.Add("NotifyShouldTransmit", "LOD_Recover_lod_static_box", function(ent, transmitting)
    if transmitting and IsValid(ent) and ent:GetClass() == "lod_static_box" then
        visualBoxes[ent] = true
        -- Defer bounds until Think; accessors may not exist in this hook.
        ent._LODNextBoundsRefresh = 0
        ent._LODBoundsSnapshot = nil
        ent._LODVisualBox = nil
        if ent.SetNextClientThink then ent:SetNextClientThink(CurTime()) end
    end
end)

function ENT:Draw()
end

local function drawFloorSlab(ent, box, color, getMaterial)
    if ent:GetNW2Bool("LOD_CrateGrate",false) and LOD.TexturedBox and LOD.TexturedBox.DrawGrate then
        LOD.TexturedBox:DrawGrate(box.position,box.angles,box.mins,box.maxs,ent)
        return
    end
    local material = getMaterial()
    if LOD.TexturedBox and LOD.TexturedBox.DrawSlab then
        LOD.TexturedBox:DrawSlab(
            box.position,
            box.angles,
            box.mins,
            box.maxs,
            material,
            color,
            textureTile,
            ent
        )
        return
    end

    render.SetMaterial(material)
    render.DrawBox(box.position, box.angles, box.mins, box.maxs, color)
end

local function drawFullMetalBox(ent, box, color, getMaterial)
    local material = getMaterial()
    if LOD.TexturedBox and LOD.TexturedBox.Draw then
        LOD.TexturedBox:Draw(
            box.position,
            box.angles,
            box.mins,
            box.maxs,
            material,
            color,
            textureTile,
            ent
        )
        return
    end

    render.SetMaterial(material)
    render.DrawBox(box.position, box.angles, box.mins, box.maxs, color)
end

-- These boxes are submitted manually, bypassing the native entity draw culler.
-- Reject only oriented boxes wholly outside one current-view frustum plane.
-- Origin-centred spheres substantially over-admit long, thin floor runs and
-- stairs. Exact support bounds also preserve offset underdecks at any rotation.
-- There is no distance/floor/occlusion guess and no draw cap.
local function currentPerspective()
    if not render.GetViewSetup or not EyePos or not EyeVector then return nil end
    local view = render.GetViewSetup(true)
    if not view or view.ortho or view.offcenter
        or not view.fov or not (view.fov > 0 and view.fov < 180)
        or not view.znear or not (view.znear >= 0) then return nil end
    -- GetViewSetup(true) describes this render pass, including nested cameras.
    -- Its fov is ALREADY aspect-adjusted; applying Source's 4:3 correction again
    -- would hide visible geometry on some displays. Incomplete setups retain the
    -- previous conservative rear-plane check instead of guessing screen size.
    local angles = view.angles
    if not angles or not angles.Forward or not angles.Right or not angles.Up
        or not view.origin or not view.aspect or not (view.aspect > 0 and view.aspect < math.huge)
        or not angles.p or not angles.y or not angles.r
        or angles.p ~= angles.p or angles.y ~= angles.y or angles.r ~= angles.r then
        return EyePos(), EyeVector()
    end
    local tanX = math.tan(math.rad(view.fov) * 0.5)
    local tanY = tanX / view.aspect
    return view.origin, angles:Forward(), angles:Right(), angles:Up(),
        tanX, tanY, math.sqrt(1 + tanX*tanX), math.sqrt(1 + tanY*tanY)
end

local function visualSnapshot(ent)
    local mins, maxs = ent:GetBoxMins(), ent:GetBoxMaxs()
    local pos, angles = ent:GetPos(), ent:GetAngles()
    local pitch, yaw, roll = angles and angles.p, angles and angles.y, angles and angles.r
    local cached = ent._LODVisualBox
    -- Snapshot once per pass; reuse identical geometry/pose across passes.
    -- Scalars observe in-place native vector/angle mutations immediately.
    if not cached or cached.x0 ~= mins.x or cached.y0 ~= mins.y or cached.z0 ~= mins.z
        or cached.x1 ~= maxs.x or cached.y1 ~= maxs.y or cached.z1 ~= maxs.z
        or cached.px ~= pos.x or cached.py ~= pos.y or cached.pz ~= pos.z
        or cached.pitch ~= pitch or cached.yaw ~= yaw or cached.roll ~= roll then
        cached = {x0=mins.x,y0=mins.y,z0=mins.z,x1=maxs.x,y1=maxs.y,z1=maxs.z,
            px=pos.x,py=pos.y,pz=pos.z,pitch=pitch,yaw=yaw,roll=roll,
            position=pos,angles=angles,mins=mins,maxs=maxs}
        if angles and angles.Forward and angles.Right and angles.Up then
            local f, r, u = angles:Forward(), angles:Right(), angles:Up()
            local x, y, z = (mins.x+maxs.x)*0.5,(mins.y+maxs.y)*0.5,(mins.z+maxs.z)*0.5
            cached.f, cached.r, cached.u = f, r, u
            cached.cx=pos.x+f.x*x-r.x*y+u.x*z
            cached.cy=pos.y+f.y*x-r.y*y+u.y*z
            cached.cz=pos.z+f.z*x-r.z*y+u.z*z
            cached.hx, cached.hy, cached.hz = (maxs.x-mins.x)*0.5,(maxs.y-mins.y)*0.5,(maxs.z-mins.z)*0.5
        else
            -- An incomplete angle accessor cannot supply oriented support.
            -- Retain the previous rotation-independent origin sphere for the
            -- conservative rear-plane fallback until native axes are ready.
            local x = math.max(math.abs(mins.x), math.abs(maxs.x))
            local y = math.max(math.abs(mins.y), math.abs(maxs.y))
            local z = math.max(math.abs(mins.z), math.abs(maxs.z))
            cached.radius = math.sqrt(x*x+y*y+z*z) + 1
        end
        ent._LODVisualBox = cached
    end
    return cached
end

local function support(box, x, y, z)
    local f, r, u = box.f, box.r, box.u
    return box.hx*math.abs(f.x*x+f.y*y+f.z*z)
        + box.hy*math.abs(r.x*x+r.y*y+r.z*z)
        + box.hz*math.abs(u.x*x+u.y*y+u.z*z)
end
local function inCamera(box, eye, forward, right, up, tanX, tanY, normX, normY)
    if not eye or not forward then return true end
    if not box.f then
        local dx, dy, dz = box.px-eye.x, box.py-eye.y, box.pz-eye.z
        return dx*forward.x+dy*forward.y+dz*forward.z >= -box.radius
    end
    local dx, dy, dz = box.cx-eye.x, box.cy-eye.y, box.cz-eye.z
    local depth = dx*forward.x + dy*forward.y + dz*forward.z
    -- A malformed/unavailable view fails open rather than hiding the floor.
    if depth + support(box,forward.x,forward.y,forward.z) < -1 then return false end
    if right and up then
        local side = dx*right.x + dy*right.y + dz*right.z
        local height = dx*up.x + dy*up.y + dz*up.z
        -- Unnormalized inward planes with one world-unit tolerance. A box is
        -- rejected only when its greatest support lies strictly outside a plane.
        if depth*tanX-side+support(box,forward.x*tanX-right.x,forward.y*tanX-right.y,forward.z*tanX-right.z) < -normX
            or depth*tanX+side+support(box,forward.x*tanX+right.x,forward.y*tanX+right.y,forward.z*tanX+right.z) < -normX
            or depth*tanY-height+support(box,forward.x*tanY-up.x,forward.y*tanY-up.y,forward.z*tanY-up.z) < -normY
            or depth*tanY+height+support(box,forward.x*tanY+up.x,forward.y*tanY+up.y,forward.z*tanY+up.z) < -normY then return false end
    end
    return true
end

hook.Add("PostDrawOpaqueRenderables", "LOD.DrawGeneratedStaticGeometry", function(drawingDepth, drawingSkybox, drawing3DSkybox)
    if drawingDepth or drawingSkybox or drawing3DSkybox then return end

    local eye, forward, right, up, tanX, tanY, normX, normY = currentPerspective()
    -- Resolve the mounted concrete/fallback once per pass, only if needed.
    -- Pass-local ownership is safe for nested RenderView and retries next frame.
    local material
    local function getMaterial()
        if not material then material = floorMaterial() end
        return material
    end
    for ent in pairs(visualBoxes) do
        local kind = IsValid(ent) and networkReady(ent) and ent:GetBoxKind()
        -- Most generated boxes are invisible collision walls. Resolve their
        -- cheap kind before native visibility/bounds/transform work; the kind is
        -- still read every pass so late datatables and mutations recover.
        if (kind==1 or kind==2 or kind==5) and not ent:GetNW2Bool("LOD_GeometryHidden", false) then
            local box = visualSnapshot(ent)
            if inCamera(box, eye, forward, right, up, tanX, tanY, normX, normY) then

                -- Ordinary floor runs render only their top and underside. Their
                -- collision remains a substantial 32-unit slab, but internal
                -- row-run side faces are not visible, eliminating false step/riser
                -- seams across a mathematically flat deck. Stair boxes retain all six
                -- faces because their vertical risers are real geometry.
                if kind == 1 then
                    drawFloorSlab(ent, box, floorColor, getMaterial)
                    if ent:GetNW2String("LOD_EventArchetype", "") == "false_floor" then
                        render.DrawWireframeBox(box.position, box.angles, box.mins, box.maxs, stairEdgeColor, false)
                    end
                elseif kind == 2 then
                    drawFullMetalBox(ent, box, stairColor, getMaterial)
                    render.DrawWireframeBox(
                        box.position,
                        box.angles,
                        box.mins,
                        box.maxs,
                        stairEdgeColor,
                        true
                    )
                elseif kind == 5 then
                    -- The continuous level-0 underdeck is deliberately recessed only
                    -- half a unit beneath the ordinary deck. Use the identical material
                    -- and color and draw only broad faces, so any container-base or
                    -- exterior-corner sightline resolves to continuous concrete.
                    drawFloorSlab(ent, box, floorColor, getMaterial)
                end
                -- Kind 7 is the native-hut staging containment boundary. It owns only
                -- server collision and is intentionally invisible on the client.
            end
        end
    end
end)
