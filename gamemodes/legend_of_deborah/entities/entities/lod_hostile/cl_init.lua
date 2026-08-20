include("shared.lua")

local aimMaterial = Material("cable/redlaser")

-- Visual scale stays client-only. Motion V2 deliberately places the server-side
-- humanoid entity origin on the authoritative graph floor plane instead of at
-- Source NextBot's historical ~24-unit-below-foot resting origin. Preserve the
-- same visible foot pivot while translating V2 humanoid models down to that new
-- server origin. Deadcrab keeps its native model-space pivot because its explicit
-- leap remains a genuine Source airborne movement state.
local HUMANOID_FOOT_PIVOT_Z = 24

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
    local signature = tostring(size) .. ":" .. tostring(motionV2)
    if ent.LODLastClientVisualScale == signature then return end
    ent.LODLastClientVisualScale = signature

    local archetype = ent:GetNW2String("LOD_Archetype", "")
    local mins, maxs = visualModelBounds(ent)
    local deadcrab = archetype == "deadcrab"
    local pivotZ = deadcrab and mins.z or HUMANOID_FOOT_PIVOT_Z
    local verticalCompensation = pivotZ * (1 - size)

    if motionV2 and not deadcrab then
        -- A humanoid foot at local pivotZ transforms to local Z=0 for every
        -- visible scale: pivotZ*size + (pivotZ*(1-size)-pivotZ) == 0.
        verticalCompensation = verticalCompensation - pivotZ
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
