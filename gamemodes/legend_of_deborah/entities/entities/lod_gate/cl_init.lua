include("shared.lua")

local PC = LOD.Config.Progression
local gateMaterial = CreateMaterial("lod_gate_opaque_v1", "UnlitGeneric", {
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
    local halfHeight = PC.GateBlockerHeight * 0.5
    local visibleBottom = -halfHeight
    local visibleTop = visibleBottom + PC.GateVisibleHeight
    if ent:GetGateAxis() == 0 then
        return Vector(-halfThickness, -halfWidth, visibleBottom), Vector(halfThickness, halfWidth, visibleTop)
    end
    return Vector(-halfWidth, -halfThickness, visibleBottom), Vector(halfWidth, halfThickness, visibleTop)
end

local function openingFraction(ent)
    if not ent:GetOpened() then return 0 end
    local started = ent:GetOpenedAt()
    if started <= 0 then return 1 end
    return math.Clamp((CurTime() - started) / PC.GateOpenSeconds, 0, 1)
end

hook.Add("PostDrawOpaqueRenderables", "LOD_DrawSecurityGates", function()
    render.SetMaterial(gateMaterial)
    render.CullMode(MATERIAL_CULLMODE_NONE)

    for ent in pairs(LOD.ClientGates) do
        if IsValid(ent) then
            local index = math.Clamp(ent:GetGateIndex(), 1, 3)
            local card = PC.Cards[index]
            local mins, maxs = gateLocalBounds(ent)
            local frac = openingFraction(ent)
            if frac < 1 then
                local lift = Vector(0, 0, PC.GateVisibleHeight * frac)
                render.DrawBox(ent:GetPos() + lift, angle_zero, mins, maxs, card.color)
            end

            local locked = not ent:GetOpened()
            local readerColor = locked and card.color or Color(72, 190, 92)
            local halfHeight = PC.GateBlockerHeight * 0.5
            local readerZ = -halfHeight + 72
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
            local z = -halfHeight + math.min(PC.GateVisibleHeight - 52, 164)
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
