include("shared.lua")

local aimMaterial = Material("cable/redlaser")

-- Motion V2 owns world-space placement: an ordinary hostile entity origin sits
-- on the graph-authored walking surface (+ a tiny safety lift), and explicit
-- stair/leap motion changes that world position deliberately. Visual variance
-- therefore needs only one invariant: the LOWEST point of the rendered model
-- must remain at the entity origin for every scale. The old hard-coded 24-unit
-- humanoid pivot came from the retired Source-ground-locomotion architecture and
-- could push some models visibly into the deck; Deadcrab could likewise extend
-- downward through an upper-floor slab.
--
-- This uses cached model bounds only. There are no traces or hostile-list scans
-- in Draw(), preserving Motion V2's recovered frame-time performance.

local function visualModelBounds(ent)
    if util.GetModelBounds then
        local mins, maxs = util.GetModelBounds(ent:GetModel())
        if mins and maxs then return mins, maxs end
    end
    return Vector(-16, -16, 0), Vector(16, 16, 72)
end

local function applyVisualScale(ent)
    local size = math.Clamp(ent:GetNW2Float("LOD_SizeScale", 1), 0.33, 1.33)
    local motionV2 = ent:GetNW2Bool("LOD_MotionV2", false)
    local model = ent:GetModel() or ""
    local signature = string.format("%s:%.4f:%s", model, size, tostring(motionV2))
    if ent.LODLastClientVisualScale == signature then return end
    ent.LODLastClientVisualScale = signature

    local mins, maxs = visualModelBounds(ent)

    -- Under Motion V2, local Z=0 is the authoritative visual foot plane. Scale
    -- the complete model, then translate its scaled minimum-Z back to that plane.
    -- This works for humanoids and Deadcrab alike and remains valid while a
    -- Deadcrab is airborne because the entity origin itself follows the leap.
    local verticalCompensation
    if motionV2 then
        verticalCompensation = -(mins.z * size)
    else
        -- Defensive legacy fallback for any entity created before Motion V2's
        -- network flag arrives. Preserve the model's native minimum-Z plane.
        verticalCompensation = mins.z * (1 - size)
    end

    local matrix = Matrix()
    matrix:Scale(Vector(size, size, size))
    matrix:SetTranslation(Vector(0, 0, verticalCompensation))
    ent:EnableMatrix("RenderMultiply", matrix)

    ent:SetRenderBounds(
        Vector(mins.x * size, mins.y * size, mins.z * size + verticalCompensation),
        Vector(maxs.x * size, maxs.y * size, maxs.z * size + verticalCompensation)
    )
end

function ENT:Draw()
    applyVisualScale(self)
    self:DrawModel()
    if self:GetNW2String("LOD_Archetype", "") ~= "soldier" then return end
    if not self:GetNW2Bool("LOD_SoldierTelegraph", false) then return end

    local aim = self:GetNW2Vector("LOD_SoldierAim", vector_origin)
    if aim == vector_origin then return end

    local startPos = self:WorldSpaceCenter() + Vector(0, 0, 12) + self:GetForward() * 24
    render.SetMaterial(aimMaterial)
    render.DrawBeam(startPos, aim, 2.5, 0, 1, Color(255, 80, 60, 220))
end
