include("shared.lua")

local floorColor = Color(58, 62, 64)
local stairColor = Color(76, 79, 80)
function ENT:Initialize()
    -- Networked box bounds can arrive after client Initialize. Keep the
    -- procedural collision geometry conservatively visible until then.
    self:SetRenderBounds(Vector(-512, -512, -512), Vector(512, 512, 512))
end

function ENT:Draw()
    local kind = self:GetBoxKind()
    if kind == 3 then return end
    render.SetColorMaterial()
    render.DrawBox(
        self:GetPos(),
        self:GetAngles(),
        self:GetBoxMins(),
        self:GetBoxMaxs(),
        kind == 2 and stairColor or floorColor
    )
end
