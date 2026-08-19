include("shared.lua")

local aimMaterial = Material("cable/redlaser")

local function visualFootPivot(ent)
    -- Runtime grounding diagnostics show that Source keeps the native NextBot
    -- entity origin below the visible sole plane. Render-only size variation must
    -- therefore scale around that sole plane, not around GetPos(), or small models
    -- visually shrink downward into the floor while their locomotion stays valid.
    local archetype = ent:GetNW2String("LOD_Archetype", "")
    if archetype == "deadcrab" then return 20 end
    return 24
end

local function applyVisualScale(ent)
    local size = math.Clamp(ent:GetNW2Float("LOD_SizeScale", 1), 0.33, 1.33)
    if ent.LODLastClientVisualScale == size then return end
    ent.LODLastClientVisualScale = size

    -- Server-side NextBots remain 1.0x. The render matrix scales the visible
    -- model around its planted-foot pivot so both tiny and large variants keep
    -- the same sole plane as the native Source model.
    local pivot = visualFootPivot(ent)
    local verticalCompensation = pivot * (1 - size)
    local matrix = Matrix()
    matrix:Scale(Vector(size, size, size))
    matrix:SetTranslation(Vector(0, 0, verticalCompensation))
    ent:EnableMatrix("RenderMultiply", matrix)

    -- Expanded/shrunken client render bounds keep visibility/PVS decisions in
    -- step with the rendered model without touching server collision.
    if util.GetModelBounds then
        local mins, maxs = util.GetModelBounds(ent:GetModel())
        if mins and maxs then
            local scaledMins = Vector(
                mins.x * size,
                mins.y * size,
                mins.z * size + verticalCompensation
            )
            local scaledMaxs = Vector(
                maxs.x * size,
                maxs.y * size,
                maxs.z * size + verticalCompensation
            )
            ent:SetRenderBounds(scaledMins, scaledMaxs)
        end
    end
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
