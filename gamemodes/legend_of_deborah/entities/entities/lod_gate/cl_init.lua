include("shared.lua")

local PC = LOD.Config.Progression
local GATE_UI_HEIGHT = 72
local GATE_VISUAL_HEIGHT = PC.GateBlockerHeight
local GATE_METAL_COLOR = Color(72, 76, 78, 255)
local GATE_RIB_COLOR = Color(38, 41, 43, 255)

-- Reuse the same proven dark industrial floor material so locked progression
-- barriers read as part of one heavy steel construction vocabulary rather than
-- as flat debug-colored volumes.
local gateMetalMaterial = Material("phoenix_storms/metalfloor_2-3")
local solidMaterial = CreateMaterial("lod_gate_solid_v2", "UnlitGeneric", {
    ["$basetexture"] = "color/white",
    ["$vertexcolor"] = "1",
    ["$vertexalpha"] = "1"
})
local readerMaterial = CreateMaterial("lod_gate_reader_v1", "UnlitGeneric", {
    ["$basetexture"] = "color/white",
    ["$vertexcolor"] = "1",
    ["$vertexalpha"] = "1"
})

LOD.ClientGates = LOD.ClientGates or setmetatable({}, {__mode = "k"})

function ENT:Initialize()
    LOD.ClientGates[self] = true
end

function ENT:OnRemove()
    LOD.ClientGates[self] = nil
end

function ENT:Draw()
end

local function gateLocalBounds(ent)
    local halfThickness = PC.GateThickness * 0.5
    local halfWidth = PC.GateWidth * 0.5
    local halfHeight = GATE_VISUAL_HEIGHT * 0.5
    if ent:GetGateAxis() == 0 then
        return Vector(-halfThickness, -halfWidth, -halfHeight), Vector(halfThickness, halfWidth, halfHeight)
    end
    return Vector(-halfWidth, -halfThickness, -halfHeight), Vector(halfWidth, halfThickness, halfHeight)
end

local function openingFraction(ent)
    if not ent:GetOpened() then return 0 end
    local started = ent:GetOpenedAt()
    if started <= 0 then return 1 end
    return math.Clamp((CurTime() - started) / PC.GateOpenSeconds, 0, 1)
end

local function drawStructuralBox(ent, center, mins, maxs, color)
    render.SetMaterial(solidMaterial)
    render.DrawBox(center, angle_zero, mins, maxs, color)
end

local function drawReinforcement(ent, center)
    local halfThickness = PC.GateThickness * 0.5
    local halfWidth = PC.GateWidth * 0.5
    local halfHeight = GATE_VISUAL_HEIGHT * 0.5
    local ribDepth = halfThickness + 4
    local ribHalfWidth = 6

    -- Five raised vertical ribs plus two horizontal braces make the door read as
    -- a reinforced prison/industrial shutter while remaining completely opaque.
    for _, offset in ipairs({-0.72, -0.36, 0, 0.36, 0.72}) do
        local lateral = halfWidth * offset
        if ent:GetGateAxis() == 0 then
            drawStructuralBox(ent, center + Vector(0, lateral, 0),
                Vector(-ribDepth, -ribHalfWidth, -halfHeight), Vector(ribDepth, ribHalfWidth, halfHeight), GATE_RIB_COLOR)
        else
            drawStructuralBox(ent, center + Vector(lateral, 0, 0),
                Vector(-ribHalfWidth, -ribDepth, -halfHeight), Vector(ribHalfWidth, ribDepth, halfHeight), GATE_RIB_COLOR)
        end
    end

    for _, z in ipairs({-halfHeight * 0.48, halfHeight * 0.48}) do
        if ent:GetGateAxis() == 0 then
            drawStructuralBox(ent, center + Vector(0, 0, z),
                Vector(-ribDepth, -halfWidth, -7), Vector(ribDepth, halfWidth, 7), GATE_RIB_COLOR)
        else
            drawStructuralBox(ent, center + Vector(0, 0, z),
                Vector(-halfWidth, -ribDepth, -7), Vector(halfWidth, ribDepth, 7), GATE_RIB_COLOR)
        end
    end
end

local function drawColorBand(ent, center, color)
    local halfThickness = PC.GateThickness * 0.5 + 5
    local halfWidth = PC.GateWidth * 0.5
    local halfBandHeight = 10
    local z = -GATE_VISUAL_HEIGHT * 0.5 + GATE_UI_HEIGHT + 52

    render.SetMaterial(solidMaterial)
    if ent:GetGateAxis() == 0 then
        render.DrawBox(center + Vector(0, 0, z), angle_zero,
            Vector(-halfThickness, -halfWidth, -halfBandHeight), Vector(halfThickness, halfWidth, halfBandHeight), color)
    else
        render.DrawBox(center + Vector(0, 0, z), angle_zero,
            Vector(-halfWidth, -halfThickness, -halfBandHeight), Vector(halfWidth, halfThickness, halfBandHeight), color)
    end
end

hook.Add("PostDrawOpaqueRenderables", "LOD_DrawSecurityGates", function()
    render.CullMode(MATERIAL_CULLMODE_NONE)

    for ent in pairs(LOD.ClientGates) do
        if IsValid(ent) then
            local index = math.Clamp(ent:GetGateIndex(), 1, 3)
            local card = PC.Cards[index]
            local mins, maxs = gateLocalBounds(ent)
            local frac = openingFraction(ent)

            if frac < 1 then
                -- Locked gates are floor-to-ceiling opaque steel shutters. On
                -- unlock the whole reinforced assembly retracts upward, preserving
                -- the existing readable opening animation without exposing the
                -- next sector beforehand.
                local center = ent:GetPos() + Vector(0, 0, GATE_VISUAL_HEIGHT * frac)
                render.SetMaterial(gateMetalMaterial)
                render.DrawBox(center, angle_zero, mins, maxs, GATE_METAL_COLOR)
                drawReinforcement(ent, center)
                drawColorBand(ent, center, card.color)
            end

            local locked = not ent:GetOpened()
            local readerColor = locked and card.color or Color(72, 190, 92)
            local halfHeight = PC.GateBlockerHeight * 0.5
            local readerZ = -halfHeight + GATE_UI_HEIGHT
            render.SetMaterial(readerMaterial)
            if ent:GetGateAxis() == 0 then
                render.DrawBox(ent:GetPos() + Vector(PC.GateThickness * 0.5 + 12, PC.GateWidth * 0.32, readerZ), angle_zero,
                    Vector(-6, -18, -28), Vector(6, 18, 28), readerColor)
            else
                render.DrawBox(ent:GetPos() + Vector(PC.GateWidth * 0.32, PC.GateThickness * 0.5 + 12, readerZ), angle_zero,
                    Vector(-18, -6, -28), Vector(18, 6, 28), readerColor)
            end
        end
    end

    render.CullMode(MATERIAL_CULLMODE_CCW)
end)

local function drawGateLabel(ent, card, pos, ang)
    cam.Start3D2D(pos, ang, 0.12)
        draw.RoundedBox(4, -150, -34, 300, 68, Color(18, 20, 22, 235))
        draw.SimpleText(card.letter .. " / " .. card.symbol, "DermaLarge", 0, -8, card.color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(ent:GetOpened() and "UNLOCKED" or "LOCKED — USE READER", "DermaDefaultBold", 0, 20,
            ent:GetOpened() and Color(100, 230, 120) or Color(235, 235, 235), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end

hook.Add("PostDrawTranslucentRenderables", "LOD_DrawSecurityGateLabels", function()
    for ent in pairs(LOD.ClientGates) do
        if IsValid(ent) then
            local card = PC.Cards[math.Clamp(ent:GetGateIndex(), 1, 3)]
            local halfHeight = PC.GateBlockerHeight * 0.5
            local z = -halfHeight + GATE_UI_HEIGHT
            if ent:GetGateAxis() == 0 then
                drawGateLabel(ent, card, ent:GetPos() + Vector(PC.GateThickness * 0.5 + 1, 0, z), Angle(0, 90, 90))
                drawGateLabel(ent, card, ent:GetPos() + Vector(-PC.GateThickness * 0.5 - 1, 0, z), Angle(0, -90, 90))
            else
                drawGateLabel(ent, card, ent:GetPos() + Vector(0, PC.GateThickness * 0.5 + 1, z), Angle(0, 180, 90))
                drawGateLabel(ent, card, ent:GetPos() + Vector(0, -PC.GateThickness * 0.5 - 1, z), Angle(0, 0, 90))
            end
        end
    end
end)
