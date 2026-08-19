include("shared.lua")

local aimMaterial = Material("cable/redlaser")

local function visualModelBounds(ent)
    -- Scale around the model's own lowest local point rather than a guessed
    -- zombie/headcrab offset. Different Source models do not share one foot
    -- pivot, and a hard-coded value made some small variants sink visually into
    -- the generated floor even while their server NextBot remained grounded.
    if ent.OBBMins and ent.OBBMaxs then
        local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
        if mins and maxs and maxs.z > mins.z then return mins, maxs end
    end

    if util.GetModelBounds then
        local mins, maxs = util.GetModelBounds(ent:GetModel())
        if mins and maxs then return mins, maxs end
    end

    return Vector(-16, -16, 0), Vector(16, 16, 72)
end

local function applyVisualScale(ent)
    local size = math.Clamp(ent:GetNW2Float("LOD_SizeScale", 1), 0.33, 1.33)
    if ent.LODLastClientVisualScale == size then return end
    ent.LODLastClientVisualScale = size

    -- Server-side NextBots remain 1.0x. Preserve the native model's lowest
    -- rendered point while scaling everything above it. If p is the local sole
    -- plane, p must satisfy size*p + translation == p.
    local mins, maxs = visualModelBounds(ent)
    local pivotZ = mins.z
    local verticalCompensation = pivotZ * (1 - size)

    local matrix = Matrix()
    matrix:Scale(Vector(size, size, size))
    matrix:SetTranslation(Vector(0, 0, verticalCompensation))
    ent:EnableMatrix("RenderMultiply", matrix)

    -- Keep client render bounds synchronized with the transformed model without
    -- touching any server collision or locomotion state.
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
