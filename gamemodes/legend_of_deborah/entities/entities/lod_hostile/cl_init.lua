include("shared.lua")

local aimMaterial = Material("cable/redlaser")

local function visualModelBounds(ent)
    if util.GetModelBounds then
        local mins, maxs = util.GetModelBounds(ent:GetModel())
        if mins and maxs then return mins, maxs end
    end

    if ent.OBBMins and ent.OBBMaxs then
        local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
        if mins and maxs and maxs.z > mins.z then return mins, maxs end
    end

    return Vector(-16, -16, 0), Vector(16, 16, 72)
end

local function physicalFloorOffset(ent)
    local pos = ent:GetPos()
    local ignored = {ent}
    for _, other in ipairs(ents.FindByClass("lod_hostile")) do
        if IsValid(other) and other ~= ent then ignored[#ignored + 1] = other end
    end

    local tr = util.TraceLine({
        start = pos + Vector(0, 0, 96),
        endpos = pos - Vector(0, 0, 160),
        mask = MASK_SOLID,
        filter = ignored
    })

    if tr.StartSolid or not tr.Hit or not tr.HitNormal or tr.HitNormal.z < 0.55 then
        return nil
    end

    return tr.HitPos.z - pos.z
end

local function applyVisualScale(ent)
    local size = math.Clamp(ent:GetNW2Float("LOD_SizeScale", 1), 0.33, 1.33)
    local archetype = ent:GetNW2String("LOD_Archetype", "")
    local mins, maxs = visualModelBounds(ent)

    -- Server-side NextBots always remain native 1.0x. Humanoid visual scaling
    -- must preserve the physical floor-contact plane of the native entity, not
    -- scale around its buried Source entity origin. A downward trace gives the
    -- live floor offset; keeping that native contact point fixed yields
    -- translation = floorOffset * (1 - scale).
    local verticalCompensation = 0
    if archetype ~= "deadcrab" then
        local floorOffset = physicalFloorOffset(ent)
        if floorOffset then
            verticalCompensation = floorOffset * (1 - size)
        else
            -- Fallback only when no usable floor can be traced (for example an
            -- unusual transient airborne state).
            verticalCompensation = mins.z * (1 - size)
        end
    else
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
    -- Re-evaluate every draw. Unlike the previous cached transform, the floor
    -- offset changes while walking stairs and whenever Source re-settles the
    -- underlying NextBot origin.
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
