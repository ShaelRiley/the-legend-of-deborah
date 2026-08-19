include("shared.lua")

local aimMaterial = Material("cable/redlaser")

local function applyVisualScale(ent)
    local size = math.Clamp(ent:GetNW2Float("LOD_SizeScale", 1), 0.33, 1.33)
    if ent.LODLastClientVisualScale == size then return end
    ent.LODLastClientVisualScale = size

    -- Keep size variance purely in the render transform. The server-side
    -- NextBot remains an ordinary 1.0x Source entity so model scaling can never
    -- perturb locomotion, floor contact, collision, or stuck detection.
    local matrix = Matrix()
    matrix:Scale(Vector(size, size, size))
    ent:EnableMatrix("RenderMultiply", matrix)

    -- Expanded/shrunken client render bounds keep visibility/PVS decisions in
    -- step with the rendered model without touching server collision.
    if util.GetModelBounds then
        local mins, maxs = util.GetModelBounds(ent:GetModel())
        if mins and maxs then
            local scaledMins = Vector(mins.x * size, mins.y * size, mins.z * size)
            local scaledMaxs = Vector(maxs.x * size, maxs.y * size, maxs.z * size)
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
