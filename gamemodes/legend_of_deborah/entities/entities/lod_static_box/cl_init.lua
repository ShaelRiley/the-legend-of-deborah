include("shared.lua")

local floorColor = Color(58, 62, 64, 255)
local stairColor = Color(120, 126, 132, 255)
local stairEdgeColor = Color(225, 145, 48, 255)

local function refreshRenderBounds(ent)
    local mins = ent:GetBoxMins()
    local maxs = ent:GetBoxMaxs()

    -- Upper-floor geometry is merged into long row-run entities. A fixed
    -- +/-512 render bound causes perfectly solid floors to disappear visually
    -- when the entity origin leaves the client's visibility volume. Use the
    -- actual authored bounds instead, with a small safety margin.
    local margin = Vector(32, 32, 32)
    ent:SetRenderBounds(mins - margin, maxs + margin)
end

function ENT:Initialize()
    refreshRenderBounds(self)
    self._LODNextBoundsRefresh = 0
end

function ENT:Think()
    -- Networked box dimensions can arrive just after client entity creation.
    -- Refresh briefly/cheaply so the final authoritative dimensions always
    -- become the render bounds even if Initialize saw defaults.
    if CurTime() >= (self._LODNextBoundsRefresh or 0) then
        refreshRenderBounds(self)
        self._LODNextBoundsRefresh = CurTime() + 1
    end
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
