include("shared.lua")

local floorColor = Color(58, 62, 64)
local stairColor = Color(76, 79, 80)
function ENT:Initialize()
    self:SetRenderBounds(Vector(-512, -512, -512), Vector(512, 512, 512))
end

function ENT:Draw()
    local kind = self:GetBoxKind()
    -- Rail and merged wall boxes are collision-only. Container models provide
    -- the visible wall presentation for kind 4.
    if kind == 3 or kind == 4 then return end
    render.SetColorMaterial()
    render.DrawBox(
        self:GetPos(),
        self:GetAngles(),
        self:GetBoxMins(),
        self:GetBoxMaxs(),
        kind == 2 and stairColor or floorColor
    )
end
