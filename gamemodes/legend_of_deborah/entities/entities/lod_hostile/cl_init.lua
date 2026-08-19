include("shared.lua")

local aimMaterial = Material("cable/redlaser")

-- Source NextBots keep their server entity at native 1.0x. Runtime diagnostics
-- showed that the humanoid visual sole plane sits about 24 Source units above
-- the NextBot entity origin. Scale around that stable native foot plane instead
-- of performing a world trace for every hostile on every Draw call.
--
-- The previous per-frame trace implementation also rebuilt an all-hostile filter
-- inside every enemy Draw. With 16 wanderers per floor that became roughly
-- O(N^2) client work every rendered frame and caused severe chug.
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
    if ent.LODLastClientVisualScale == size then return end
    ent.LODLastClientVisualScale = size

    local archetype = ent:GetNW2String("LOD_Archetype", "")
    local mins, maxs = visualModelBounds(ent)
    local pivotZ = archetype == "deadcrab" and mins.z or HUMANOID_FOOT_PIVOT_Z
    local verticalCompensation = pivotZ * (1 - size)

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
