include("shared.lua")

local floorColor = Color(58, 62, 64, 255)
local stairColor = Color(120, 126, 132, 255)
local stairEdgeColor = Color(225, 145, 48, 255)

function ENT:Initialize()
    self:SetRenderBounds(Vector(-512, -512, -512), Vector(512, 512, 512))
end

local function drawFilled(ent, color)
    render.SetColorMaterial()
    render.DrawBox(
        ent:GetPos(),
        ent:GetAngles(),
        ent:GetBoxMins(),
        ent:GetBoxMaxs(),
        color
    )
end

local function drawOutlined(ent, color)
    render.DrawWireframeBox(
        ent:GetPos(),
        ent:GetAngles(),
        ent:GetBoxMins(),
        ent:GetBoxMaxs(),
        color,
        true
    )
end

function ENT:Draw()
    local kind = self:GetBoxKind()

    -- Rails and merged anti-bypass wall blockers remain collision-only.
    -- Visible cargo-container props already communicate the walls.
    if kind == 3 or kind == 4 then return end

    if kind == 2 then
        -- Make stairs conspicuous and legible.
        drawFilled(self, stairColor)
        drawOutlined(self, stairEdgeColor)
        return
    end

    drawFilled(self, floorColor)
end
