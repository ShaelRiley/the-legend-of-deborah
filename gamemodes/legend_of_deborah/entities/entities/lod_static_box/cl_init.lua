include("shared.lua")

local floorColor = Color(58, 62, 64, 255)
local stairColor = Color(120, 126, 132, 255)
local stairEdgeColor = Color(225, 145, 48, 255)

-- render.SetColorMaterial() uses Garry's Mod's built-in translucent color
-- material. That is convenient for effects but causes depth/sorting artifacts
-- when many large generated floor slabs overlap in view. Use a deliberately
-- opaque material for authoritative maze surfaces instead.
local opaqueGeometryMaterial = CreateMaterial("lod_generated_geometry_opaque_v1", "UnlitGeneric", {
    ["$basetexture"] = "color/white",
    ["$vertexcolor"] = "1",
    ["$vertexalpha"] = "1"
})

local function refreshRenderBounds(ent)
    local mins = ent:GetBoxMins()
    local maxs = ent:GetBoxMaxs()

    -- Upper-floor geometry is merged into long row-run entities. Use each
    -- entity's actual authored dimensions rather than a fixed render bound.
    local margin = Vector(32, 32, 32)
    ent:SetRenderBounds(mins - margin, maxs + margin)
end

function ENT:Initialize()
    refreshRenderBounds(self)
    self._LODNextBoundsRefresh = 0
end

function ENT:Think()
    -- Networked box dimensions can arrive just after client entity creation.
    if CurTime() >= (self._LODNextBoundsRefresh or 0) then
        refreshRenderBounds(self)
        self._LODNextBoundsRefresh = CurTime() + 1
    end
end

local function drawFilled(ent, color)
    render.SetMaterial(opaqueGeometryMaterial)

    -- Floor slabs are gameplay surfaces and must remain visually legible from
    -- above and below. Disable face culling only for this draw and immediately
    -- restore Source's ordinary counter-clockwise culling afterward.
    render.CullMode(MATERIAL_CULLMODE_NONE)
    render.DrawBox(
        ent:GetPos(),
        ent:GetAngles(),
        ent:GetBoxMins(),
        ent:GetBoxMaxs(),
        color
    )
    render.CullMode(MATERIAL_CULLMODE_CCW)
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
        drawFilled(self, stairColor)
        drawOutlined(self, stairEdgeColor)
        return
    end

    drawFilled(self, floorColor)
end
