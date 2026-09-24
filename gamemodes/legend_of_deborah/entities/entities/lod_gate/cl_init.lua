include("shared.lua")

local PC = LOD.Config.Progression
local MC = LOD.Config.Maze
local GC = LOD.Config.Geometry or {}
local GATE_VISUAL_HEIGHT = PC.GateBlockerHeight
local GATE_METAL_COLOR = Color(92, 96, 98, 255)
local GATE_RIB_COLOR = Color(38, 41, 43, 255)
local READER_HOUSING_COLOR = Color(28, 31, 33, 255)
local READER_SLOT_COLOR = Color(10, 12, 13, 255)
local GATE_SIGN_HEIGHT = 126
local GATE_READER_HEIGHT = 62
local GATE_TEXTURE_TILE = GC.GateTextureTile or 128
local GATE_BODY_DISTANCE_SQR = (MC and MC.CellSize or 384) ^ 2 * 64
local PROGRESSION_LABEL_DISTANCE_SQR = (MC and MC.CellSize or 384) ^ 2 * 16

LOD.ProgressionRenderStats = LOD.ProgressionRenderStats or {}
local RenderStats = LOD.ProgressionRenderStats

-- Dedicated stock metal is used only if the native blast-door model cannot load.
-- Never ask the deck material resolver: its successful result is concrete.
local function gateMetalMaterial()
    return Material(GC.GateMaterial or "models/props_c17/FurnitureMetal001a")
end

-- One reusable presentation model for every gate, not one entity per gate/frame.
-- Server blockers, readers and all progression/event ownership remain untouched.
LOD.GatePresentation = LOD.GatePresentation or {}
local GateVisual = LOD.GatePresentation
if GateVisual.Clear then GateVisual.Clear() end
local gateModel, modelScale, modelCenter, thinY
local retryAt = 0
function GateVisual.Clear()
    if IsValid(gateModel) then gateModel:Remove() end
    gateModel, modelScale, modelCenter, thinY = nil, nil, nil, nil
    retryAt = 0
end
hook.Add("PostCleanupMap", "LOD_GatePresentation", GateVisual.Clear)
hook.Add("ShutDown", "LOD_GatePresentation", GateVisual.Clear)

local function stockGateModel()
    if IsValid(gateModel) then return gateModel end
    if CurTime() < retryAt then return nil end
    retryAt = CurTime() + 2
    -- Also permits headless registry checks without pretending a native model exists.
    if not ClientsideModel then return nil end
    if util and util.IsValidModel and not util.IsValidModel(GC.GateModel) then return nil end
    local model = ClientsideModel(GC.GateModel, RENDERGROUP_OPAQUE)
    if not IsValid(model) then return nil end
    model:SetNoDraw(true)
    model:DrawShadow(false)
    local mins, maxs = model:GetModelBounds()
    local span = maxs - mins
    if span.x <= 0 or span.y <= 0 or span.z <= 0 then model:Remove(); return nil end
    thinY = span.y < span.x
    modelScale = Vector((thinY and PC.GateWidth or PC.GateThickness) / span.x,
        (thinY and PC.GateThickness or PC.GateWidth) / span.y, GATE_VISUAL_HEIGHT / span.z)
    modelCenter = Vector((mins.x + maxs.x) * 0.5 * modelScale.x,
        (mins.y + maxs.y) * 0.5 * modelScale.y, (mins.z + maxs.z) * 0.5 * modelScale.z)
    local matrix = Matrix(); matrix:Scale(modelScale)
    model:EnableMatrix("RenderMultiply", matrix)
    model:SetRenderBounds(Vector(mins.x*modelScale.x,mins.y*modelScale.y,mins.z*modelScale.z),
        Vector(maxs.x*modelScale.x,maxs.y*modelScale.y,maxs.z*modelScale.z))
    gateModel = model
    return model
end

function GateVisual.Draw(center, axis)
    local model = stockGateModel()
    if not model then return false end
    local yaw = (axis == 0 and 0 or 90) + (thinY and 90 or 0)
    local ang = Angle(0, yaw, 0)
    local offset = ang:Forward()*modelCenter.x - ang:Right()*modelCenter.y + ang:Up()*modelCenter.z
    model:SetPos(center - offset); model:SetAngles(ang)
    model:SetColor(color_white)
    model:SetupBones()
    model:DrawModel()
    return true
end
function GateVisual.Summary()
    return {model=GC.GateModel, loaded=IsValid(gateModel), fallbackMaterial=GC.GateMaterial,
        stockBodies=RenderStats.gateStockBodies or 0, fallbackBodies=RenderStats.gateFallbackBodies or 0}
end

local solidMaterial = CreateMaterial("lod_gate_solid_v3", "UnlitGeneric", {
    ["$basetexture"] = "color/white",
    ["$vertexcolor"] = "1",
    ["$vertexalpha"] = "1"
})

LOD.ClientGates = LOD.ClientGates or setmetatable({}, {__mode = "k"})

-- Transmission can resume before SetupDataTables installs the accessors.
-- Keep registry membership while waiting so the next ready frame recovers.
local function networkReady(ent)
    return ent.GetGateAxis and ent.GetGateIndex and ent.GetOpened and ent.GetOpenedAt
end

function ENT:Initialize()
    LOD.ClientGates[self] = true
end

function ENT:OnRemove(fullUpdate)
    -- Source may retain this entity across cl_fullupdate without Initialize.
    if not fullUpdate then LOD.ClientGates[self] = nil end
end

hook.Add("NotifyShouldTransmit", "LOD_Recover_lod_gate", function(ent, transmitting)
    if transmitting and IsValid(ent) and ent:GetClass() == "lod_gate" then
        LOD.ClientGates[ent] = true
    end
end)

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

local function gateCard(ent)
    if ent:GetNW2String("LOD_EventArchetype", "")=="skeleton_blockade" then
        return {letter="DEFEAT",symbol="SKELETON",color=Color(205,175,235)}
    end
    if ent:GetGateIndex()==0 then return {letter="TOLL",symbol="50 $DEB",color=Color(220,180,65)} end
    return PC.Cards[math.Clamp(ent:GetGateIndex(),1,4)]
end

hook.Add("PostDrawOpaqueRenderables", "LOD_DrawSecurityGates", function(depth, sky, sky3d)
    if depth or sky or sky3d then return end
    local eyePos = EyePos()
    local registered, drawn, culled = 0, 0, 0
    local stockBodies, fallbackBodies = 0, 0
    for ent in pairs(LOD.ClientGates) do
        if IsValid(ent) and networkReady(ent) then
            registered = registered + 1
            if ent:GetPos():DistToSqr(eyePos) <= GATE_BODY_DISTANCE_SQR then
                drawn = drawn + 1
                local card = gateCard(ent)
                local mins, maxs = gateLocalBounds(ent)
                local frac = openingFraction(ent)

                if frac < 1 then
                    local center = ent:GetPos() + Vector(0, 0, GATE_VISUAL_HEIGHT * frac)
                    if GateVisual.Draw(center, ent:GetGateAxis()) then
                        stockBodies = stockBodies + 1
                    else
                        fallbackBodies = fallbackBodies + 1
                        local material = gateMetalMaterial()
                        if LOD.TexturedBox and LOD.TexturedBox.Draw then
                            LOD.TexturedBox:Draw(center, angle_zero, mins, maxs, material, GATE_METAL_COLOR, GATE_TEXTURE_TILE)
                        else
                            render.SetMaterial(material)
                            render.DrawBox(center, angle_zero, mins, maxs, GATE_METAL_COLOR)
                        end
                        drawReinforcement(ent, center)
                    end
                    drawColorBand(ent, center, card.color)
                end

                drawReader(ent, card, not ent:GetOpened())
            else
                culled = culled + 1
            end
        end
    end
    RenderStats.gateStockBodies, RenderStats.gateFallbackBodies = stockBodies, fallbackBodies
    RenderStats.gates = registered
    RenderStats.gateBodiesDrawn = drawn
    RenderStats.gateBodiesCulled = culled
end)

local function drawGateLabel(ent, card, pos, ang)
    cam.Start3D2D(pos, ang, 0.12)
        draw.RoundedBox(4, -180, -36, 360, 72, Color(18, 20, 22, 242))
        draw.SimpleText(card.letter .. " / " .. card.symbol, "DermaLarge", 0, -9, card.color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        local prompt=card.symbol=="SKELETON" and "DEFEAT THE SKELETON ON THIS SIDE"
            or (ent:GetGateIndex()==0 and "USE TOLL TERMINAL" or "USE READER WITH KEYCARD")
        draw.SimpleText(ent:GetOpened() and "UNLOCKED" or prompt, "DermaDefaultBold", 0, 21,
            ent:GetOpened() and Color(100, 230, 120) or Color(245, 245, 245), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end

hook.Add("PostDrawTranslucentRenderables", "LOD_DrawSecurityGateLabels", function()
    local eyePos = EyePos()
    local drawn, culled = 0, 0
    for ent in pairs(LOD.ClientGates) do
        if IsValid(ent) and networkReady(ent) then
            if ent:GetPos():DistToSqr(eyePos) <= PROGRESSION_LABEL_DISTANCE_SQR then
                drawn = drawn + 1
                local card = gateCard(ent)
                local halfHeight = GATE_VISUAL_HEIGHT * 0.5
                local z = -halfHeight + GATE_SIGN_HEIGHT
                if ent:GetGateAxis() == 0 then
                    drawGateLabel(ent, card, ent:GetPos() + Vector(PC.GateThickness * 0.5 + 18, 0, z), Angle(0, 90, 90))
                    drawGateLabel(ent, card, ent:GetPos() + Vector(-PC.GateThickness * 0.5 - 18, 0, z), Angle(0, -90, 90))
                else
                    drawGateLabel(ent, card, ent:GetPos() + Vector(0, PC.GateThickness * 0.5 + 18, z), Angle(0, 180, 90))
                    drawGateLabel(ent, card, ent:GetPos() + Vector(0, -PC.GateThickness * 0.5 - 18, z), Angle(0, 0, 90))
                end
            else
                culled = culled + 1
            end
        end
    end
    RenderStats.gateLabelsDrawn = drawn
    RenderStats.gateLabelsCulled = culled
end)

concommand.Add("lod_progression_render_status", function()
    print("[LOD:GATE-ASSET] " .. util.TableToJSON(GateVisual.Summary()))
    local stats = LOD.ProgressionRenderStats or {}
    local gates = stats.gates or 0
    local keycards = stats.keycards or 0
    local gateBodies = (stats.gateBodiesDrawn or 0) + (stats.gateBodiesCulled or 0)
    local gateLabels = (stats.gateLabelsDrawn or 0) + (stats.gateLabelsCulled or 0)
    local keycardBodies = (stats.keycardBodiesDrawn or 0) + (stats.keycardBodiesCulled or 0)
    local keycardLabels = (stats.keycardLabelsDrawn or 0) + (stats.keycardLabelsCulled or 0)
    -- Source may not transmit distant progression entities until they enter the
    -- client's PVS. Validate every entity currently known to this client without
    -- falsely failing merely because an unseen gate or card has not arrived yet.
    local gateReady = gates == 0 or (gateBodies == gates and gateLabels == gates)
    local keycardReady = keycards == 0 or (keycardBodies == keycards and keycardLabels == keycards)
    local passed = gates + keycards > 0 and gateReady and keycardReady
    print(string.format(
        "[LOD:PROGRESSION-RENDER] gates=%d bodies=%d/%d labels=%d/%d keycards=%d bodies=%d/%d labels=%d/%d result=%s",
        gates, stats.gateBodiesDrawn or 0, stats.gateBodiesCulled or 0,
        stats.gateLabelsDrawn or 0, stats.gateLabelsCulled or 0,
        keycards, stats.keycardBodiesDrawn or 0, stats.keycardBodiesCulled or 0,
        stats.keycardLabelsDrawn or 0, stats.keycardLabelsCulled or 0,
        passed and "PASS" or "FAIL"
    ))
end)
