LOD = LOD or {}
LOD.CrowbarFeatFX = LOD.CrowbarFeatFX or {pulses = {}}

local FX = LOD.CrowbarFeatFX
FX.pulses = FX.pulses or {}

-- A hot reload must not strand clientside weapon duplicates in the world.
for _, pulse in ipairs(FX.pulses) do
    if IsValid(pulse.modelEntity) then pulse.modelEntity:Remove() end
end
FX.pulses = {}

local beamMaterial = Material("sprites/physbeam")
local glowMaterial = Material("sprites/light_glow02_add")
local ghostMaterial = Material("models/debug/debugwhite")
local DEFAULT_MODEL = "models/weapons/w_crowbar.mdl"
local MAX_PULSES = 12
local MAX_DRAW_DISTANCE_SQR = 5000 * 5000

local function removePulse(pulse)
    if pulse and IsValid(pulse.modelEntity) then pulse.modelEntity:Remove() end
end

local function createPulseModel(path)
    if not isstring(path) or path == "" or not util.IsValidModel(path) then
        path = DEFAULT_MODEL
    end
    local entity = ClientsideModel(path, RENDERGROUP_TRANSLUCENT)
    if not IsValid(entity) then return nil, path end
    entity:SetNoDraw(true)
    entity:SetIK(false)
    return entity, path
end

net.Receive("LOD_HeroOfLegendPulse", function()
    local attacker = net.ReadEntity()
    local modelPath = net.ReadString()
    local startPos = net.ReadVector()
    local endPos = net.ReadVector()
    local duration = math.max(0.04, net.ReadFloat())
    local hit = net.ReadBool()
    local direction = endPos - startPos
    local modelEntity, resolvedPath = createPulseModel(modelPath)

    FX.pulses[#FX.pulses + 1] = {
        attacker = attacker,
        modelEntity = modelEntity,
        modelPath = resolvedPath,
        startPos = startPos,
        endPos = endPos,
        angles = direction:LengthSqr() > 0.01 and direction:Angle() or angle_zero,
        started = CurTime(),
        duration = duration,
        hit = hit
    }

    while #FX.pulses > MAX_PULSES do
        removePulse(table.remove(FX.pulses, 1))
    end
end)

local function drawPulse(pulse, now)
    local fraction = math.Clamp((now - pulse.started) / pulse.duration, 0, 1)
    if fraction >= 1 then return false end

    local position = LerpVector(fraction, pulse.startPos, pulse.endPos)
    local fade = math.Clamp((1 - fraction) * 1.8, 0.30, 1)
    local localPlayer = LocalPlayer()
    if IsValid(localPlayer)
        and localPlayer:EyePos():DistToSqr(position) > MAX_DRAW_DISTANCE_SQR then
        return true
    end

    render.SetMaterial(beamMaterial)
    render.DrawBeam(pulse.startPos, position, 7 + 5 * fade, 0, 1,
        Color(255, 236, 120, math.floor(225 * fade)))
    render.SetMaterial(glowMaterial)
    render.DrawSprite(position, 34, 34,
        Color(255, 250, 190, math.floor(245 * fade)))

    local model = pulse.modelEntity
    if IsValid(model) then
        model:SetPos(position)
        model:SetAngles(pulse.angles)
        render.SuppressEngineLighting(true)
        render.MaterialOverride(ghostMaterial)
        render.SetColorModulation(1, 0.82, 0.18)
        render.SetBlend(0.82 * fade)
        model:DrawModel()
        render.SetBlend(1)
        render.SetColorModulation(1, 1, 1)
        render.MaterialOverride(nil)
        render.SuppressEngineLighting(false)
    end

    local light = DynamicLight(20000 + (IsValid(model) and model:EntIndex() or 0))
    if light then
        light.pos = position
        light.r = 255
        light.g = 205
        light.b = 72
        light.brightness = 2.3
        light.decay = 900
        light.size = 150
        light.dietime = now + 0.08
    end
    return true
end

hook.Add("PostDrawTranslucentRenderables", "LOD_HeroOfLegendPulseFX", function()
    local now = CurTime()
    for index = #FX.pulses, 1, -1 do
        local pulse = FX.pulses[index]
        if not drawPulse(pulse, now) then
            removePulse(pulse)
            table.remove(FX.pulses, index)
        end
    end
end)

hook.Add("ShutDown", "LOD_HeroOfLegendPulseCleanup", function()
    for _, pulse in ipairs(FX.pulses) do removePulse(pulse) end
    FX.pulses = {}
end)
