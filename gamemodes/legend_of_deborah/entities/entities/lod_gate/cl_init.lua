include("shared.lua")

local PC = LOD.Config.Progression
local GC = LOD.Config.Geometry or {}
local GATE_VISUAL_HEIGHT = PC.GateBlockerHeight
local GATE_METAL_COLOR = Color(92, 96, 98, 255)
local GATE_RIB_COLOR = Color(38, 41, 43, 255)
local READER_HOUSING_COLOR = Color(28, 31, 33, 255)
local READER_SLOT_COLOR = Color(10, 12, 13, 255)
local GATE_SIGN_HEIGHT = 126
local GATE_READER_HEIGHT = 62
local GATE_TEXTURE_TILE = GC.FloorTextureTile or 256

-- Keep the gate and decks in one material language, but use the flattened
-- no-bump/no-phong wrapper so the grip pattern cannot masquerade as geometry.
local function gateMetalMaterial()
    if LOD.TexturedBox and LOD.TexturedBox.GetIndustrialMaterial then
        return LOD.TexturedBox:GetIndustrialMaterial(GC.FloorMaterialFallback)
    end
    return Material(GC.FloorMaterialFallback or "models/props_c17/FurnitureMetal001a")
end

local solidMaterial = CreateMaterial("lod_gate_solid_v3", "UnlitGeneric", {
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

local function drawSolidBox(center, mins, maxs, color)
    render.SetMaterial(solidMaterial)
    render.DrawBox(center, angle_zero, mins, maxs, color)
end

local function drawReinforcement(ent, center)
    local halfThickness = PC.GateThickness * 0.5
    local halfWidth = PC.GateWidth * 0.5
    local halfHeight = GATE_VISUAL_HEIGHT * 0.5
    local ribDepth = halfThickness + 4
    local ribHalfWidth = 6

    for _, offset in ipairs({-0.72, -0.36, 0, 0.36, 0.72}) do
        local lateral = halfWidth * offset
        if ent:GetGateAxis() == 0 then
            drawSolidBox(center + Vector(0, lateral, 0),
                Vector(-ribDepth, -ribHalfWidth, -halfHeight), Vector(ribDepth, ribHalfWidth, halfHeight), GATE_RIB_COLOR)
        else
            drawSolidBox(center + Vector(lateral, 0, 0),
                Vector(-ribHalfWidth, -ribDepth, -halfHeight), Vector(ribHalfWidth, ribDepth, halfHeight), GATE_RIB_COLOR)
        end
    end

    for _, z in ipairs({-halfHeight * 0.48, halfHeight * 0.48}) do
        if ent:GetGateAxis() == 0 then
            drawSolidBox(center + Vector(0, 0, z),
                Vector(-ribDepth, -halfWidth, -7), Vector(ribDepth, halfWidth, 7), GATE_RIB_COLOR)
        else
            drawSolidBox(center + Vector(0, 0, z),
                Vector(-halfWidth, -ribDepth, -7), Vector(halfWidth, ribDepth, 7), GATE_RIB_COLOR)
        end
    end
end

local function drawColorBand(ent, center, color)
    local halfThickness = PC.GateThickness * 0.5 + 5
    local halfWidth = PC.GateWidth * 0.5
    local halfBandHeight = 10
    local z = -GATE_VISUAL_HEIGHT * 0.5 + 118

    if ent:GetGateAxis() == 0 then
        drawSolidBox(center + Vector(0, 0, z),
            Vector(-halfThickness, -halfWidth, -halfBandHeight), Vector(halfThickness, halfWidth, halfBandHeight), color)
    else
        drawSolidBox(center + Vector(0, 0, z),
            Vector(-halfWidth, -halfThickness, -halfBandHeight), Vector(halfWidth, halfThickness, halfBandHeight), color)
    end
end

local function drawReader(ent, card, locked)
    local halfThickness = PC.GateThickness * 0.5
    local halfHeight = GATE_VISUAL_HEIGHT * 0.5
    local z = -halfHeight + GATE_READER_HEIGHT
    local screenColor = locked and card.color or Color(72, 190, 92)

    -- Physical reader on BOTH faces of the gate, directly below the instruction
    -- sign. The colored lamp is the keycard affordance; the narrow dark recess is
    -- the visible card slot.
    for _, side in ipairs({-1, 1}) do
        if ent:GetGateAxis() == 0 then
            local x = side * (halfThickness + 9)
            drawSolidBox(ent:GetPos() + Vector(x, 0, z), Vector(-5, -24, -32), Vector(5, 24, 32), READER_HOUSING_COLOR)
            drawSolidBox(ent:GetPos() + Vector(side * (halfThickness + 15), 0, z + 10), Vector(-2, -16, -10), Vector(2, 16, 10), screenColor)
            drawSolidBox(ent:GetPos() + Vector(side * (halfThickness + 16), 0, z - 12), Vector(-2, -14, -3), Vector(2, 14, 3), READER_SLOT_COLOR)
        else
            local y = side * (halfThickness + 9)
            drawSolidBox(ent:GetPos() + Vector(0, y, z), Vector(-24, -5, -32), Vector(24, 5, 32), READER_HOUSING_COLOR)
            drawSolidBox(ent:GetPos() + Vector(0, side * (halfThickness + 15), z + 10), Vector(-16, -2, -10), Vector(16, 2, 10), screenColor)
            drawSolidBox(ent:GetPos() + Vector(0, side * (halfThickness + 16), z - 12), Vector(-14, -2, -3), Vector(14, 2, 3), READER_SLOT_COLOR)
        end
    end
end

hook.Add("PostDrawOpaqueRenderables", "LOD_DrawSecurityGates", function()
    for ent in pairs(LOD.ClientGates) do
        if IsValid(ent) then
            local index = math.Clamp(ent:GetGateIndex(), 1, 3)
            local card = PC.Cards[index]
            local mins, maxs = gateLocalBounds(ent)
            local frac = openingFraction(ent)

            if frac < 1 then
                local center = ent:GetPos() + Vector(0, 0, GATE_VISUAL_HEIGHT * frac)
                local material = gateMetalMaterial()
                if LOD.TexturedBox and LOD.TexturedBox.Draw then
                    LOD.TexturedBox:Draw(center, angle_zero, mins, maxs, material, GATE_METAL_COLOR, GATE_TEXTURE_TILE)
                else
                    render.SetMaterial(material)
                    render.DrawBox(center, angle_zero, mins, maxs, GATE_METAL_COLOR)
                end
                drawReinforcement(ent, center)
                drawColorBand(ent, center, card.color)
            end

            drawReader(ent, card, not ent:GetOpened())
        end
    end
end)

local function drawGateLabel(ent, card, pos, ang)
    cam.Start3D2D(pos, ang, 0.12)
        draw.RoundedBox(4, -180, -36, 360, 72, Color(18, 20, 22, 242))
        draw.SimpleText(card.letter .. " / " .. card.symbol, "DermaLarge", 0, -9, card.color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(ent:GetOpened() and "UNLOCKED" or "USE READER WITH KEYCARD", "DermaDefaultBold", 0, 21,
            ent:GetOpened() and Color(100, 230, 120) or Color(245, 245, 245), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end

hook.Add("PostDrawTranslucentRenderables", "LOD_DrawSecurityGateLabels", function()
    for ent in pairs(LOD.ClientGates) do
        if IsValid(ent) then
            local card = PC.Cards[math.Clamp(ent:GetGateIndex(), 1, 3)]
            local halfHeight = GATE_VISUAL_HEIGHT * 0.5
            local z = -halfHeight + GATE_SIGN_HEIGHT
            if ent:GetGateAxis() == 0 then
                drawGateLabel(ent, card, ent:GetPos() + Vector(PC.GateThickness * 0.5 + 18, 0, z), Angle(0, 90, 90))
                drawGateLabel(ent, card, ent:GetPos() + Vector(-PC.GateThickness * 0.5 - 18, 0, z), Angle(0, -90, 90))
            else
                drawGateLabel(ent, card, ent:GetPos() + Vector(0, PC.GateThickness * 0.5 + 18, z), Angle(0, 180, 90))
                drawGateLabel(ent, card, ent:GetPos() + Vector(0, -PC.GateThickness * 0.5 - 18, z), Angle(0, 0, 90))
            end
        end
    end
end)
