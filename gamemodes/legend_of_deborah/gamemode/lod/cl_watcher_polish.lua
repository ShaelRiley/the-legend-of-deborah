LOD = LOD or {}
LOD.WatcherFX = LOD.WatcherFX or {}
LOD.WatcherPolishFX = LOD.WatcherPolishFX or {}

local FX = LOD.WatcherPolishFX
local glowMaterial = Material("sprites/light_glow02_add")
local beamMaterial = Material("cable/blue_elec")
local PULSE_LIFETIME = 0.48
local BLINK_HZ = 10
local LEAN_DEGREES = 9
local WEAVE_UNITS = 6
local MOTION_SAMPLE_GUARD = 180
local WATCHER_MODEL = "models/combine_scanner.mdl"

FX.Pulses = FX.Pulses or setmetatable({}, {__mode = "k"})
FX.Motion = FX.Motion or setmetatable({}, {__mode = "k"})
FX.ScanKick = FX.ScanKick or setmetatable({}, {__mode = "k"})

local function archetype(ent)
    return IsValid(ent) and ent:GetNW2String("LOD_Archetype", "") or ""
end

-- Cloaking is a Watcher-only presentation effect. Do not trust a single NW2
-- field here: entity indexes can be recycled and their client replication may
-- arrive across adjacent frames. Requiring the archetype, explicit Watcher flag,
-- and scanner model prevents a stale Watcher presentation state from ever
-- suppressing an ordinary hostile such as a Runner.
local function isWatcherPresentationTarget(ent)
    if not IsValid(ent) then return false end
    if archetype(ent) ~= "watcher" then return false end
    if not ent:GetNW2Bool("LOD_Watcher", false) then return false end
    return string.lower(ent:GetModel() or "") == WATCHER_MODEL
end

local function watcherVisible(ent, now)
    local blinkUntil = ent:GetNW2Float("LOD_WatcherBlinkUntil", 0)
    local invisibleUntil = ent:GetNW2Float("LOD_WatcherInvisibleUntil", 0)

    if blinkUntil > now then
        return math.floor(now * BLINK_HZ) % 2 == 0
    end
    if invisibleUntil > now then return false end
    return true
end

local function movementPresentation(ent, now)
    local state = FX.Motion[ent]
    if not state then
        state = {
            lastPos = ent:GetPos(),
            moving = 0,
            phase = (ent:EntIndex() % 17) * 0.41
        }
        FX.Motion[ent] = state
    end

    local pos = ent:GetPos()
    local delta = pos - state.lastPos
    delta.z = 0
    state.lastPos = Vector(pos.x, pos.y, pos.z)

    local travelled = delta:Length()
    local movingNow = travelled > 0.01 and travelled <= MOTION_SAMPLE_GUARD and 1 or 0
    state.moving = Lerp(FrameTime() * 8, state.moving or 0, movingNow)

    local wave = math.sin(now * 4.2 + state.phase)
    local lean = wave * LEAN_DEGREES * state.moving
    local weave = -wave * WEAVE_UNITS * state.moving
    local right = ent:GetRight()
    local origin = pos + right * weave

    local kickState = FX.ScanKick[ent]
    local kick = 0
    if kickState then
        local age = now - kickState.startedAt
        if age >= 0 and age <= PULSE_LIFETIME then
            local t = age / PULSE_LIFETIME
            kick = math.sin(t * math.pi) * 11
        else
            FX.ScanKick[ent] = nil
        end
    end

    local base = ent:GetAngles()
    -- Scanner banking is render-only. Yaw remains server-authoritative while roll
    -- and a brief scan-completion pitch kick make the floating model feel alive.
    local renderAngles = Angle(base.p - kick, base.y, base.r + lean)
    return origin, renderAngles
end

local function installDrawPatch()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class or class.LODWatcherPolishDrawInstalled or not class.Draw then return false end
    class.LODWatcherPolishDrawInstalled = true

    local baseDraw = class.Draw
    function class:Draw()
        if not isWatcherPresentationTarget(self) then return baseDraw(self) end

        local now = CurTime()
        if not watcherVisible(self, now) then return end

        local origin, angles = movementPresentation(self, now)
        self:SetRenderOrigin(origin)
        self:SetRenderAngles(angles)
        baseDraw(self)
        self:SetRenderOrigin(nil)
        self:SetRenderAngles(nil)
    end
    return true
end

installDrawPatch()
hook.Add("OnEntityCreated", "LOD_WatcherPolishDrawInstall", function(ent)
    if IsValid(ent) and ent:GetClass() == "lod_hostile" then installDrawPatch() end
end)

local function effectAt(name, pos, scale)
    local data = EffectData()
    data:SetOrigin(pos)
    data:SetScale(scale or 1)
    util.Effect(name, data, true, true)
end

net.Receive("LOD_WatcherScanPulse", function()
    local watcher = net.ReadEntity()
    local target = net.ReadEntity()
    if not IsValid(watcher) or not isWatcherPresentationTarget(watcher) then return end

    local now = CurTime()
    FX.Pulses[watcher] = {
        target = IsValid(target) and target or nil,
        startedAt = now
    }
    FX.ScanKick[watcher] = {startedAt = now}

    local watcherPos = watcher:WorldSpaceCenter() + Vector(0, 0, 24)
    effectAt("StunstickImpact", watcherPos, 1.4)
    effectAt("Sparks", watcherPos, 0.75)
    sound.Play("ambient/energy/zap1.wav", watcherPos, 74, 116, 0.72)

    if IsValid(target) then
        local targetPos = target:IsPlayer() and target:EyePos() or target:WorldSpaceCenter()
        effectAt("StunstickImpact", targetPos, 1.0)
        sound.Play("buttons/button17.wav", targetPos, 68, 128, 0.55)
    end
end)

hook.Add("EntityRemoved", "LOD_WatcherPolishFXCleanup", function(ent)
    FX.Pulses[ent] = nil
    FX.Motion[ent] = nil
    FX.ScanKick[ent] = nil
end)

hook.Add("PostDrawTranslucentRenderables", "LOD_WatcherScanCompletionPulse", function()
    local now = CurTime()
    for watcher, pulse in pairs(FX.Pulses) do
        local age = now - (pulse.startedAt or now)
        if not IsValid(watcher) or not isWatcherPresentationTarget(watcher)
            or age < 0 or age > PULSE_LIFETIME
        then
            FX.Pulses[watcher] = nil
        else
            local t = math.Clamp(age / PULSE_LIFETIME, 0, 1)
            local alpha = math.floor(220 * (1 - t))
            local radius = 12 + 76 * t
            local origin = watcher:WorldSpaceCenter() + Vector(0, 0, 24)
            local color = Color(125, 235, 255, alpha)

            render.SetMaterial(glowMaterial)
            render.DrawSprite(origin, 26 + 46 * (1 - t), 26 + 46 * (1 - t), color)
            render.DrawWireframeSphere(origin, radius, 10, 7, color, true)

            local target = pulse.target
            if IsValid(target) then
                local destination = target:IsPlayer() and target:EyePos() or target:WorldSpaceCenter()
                render.SetMaterial(beamMaterial)
                render.DrawBeam(origin, destination, 5 * (1 - t) + 1, 0, 1,
                    Color(205, 250, 255, alpha))
                render.SetMaterial(glowMaterial)
                render.DrawSprite(destination, 20 + 28 * (1 - t), 20 + 28 * (1 - t), color)
                render.DrawWireframeSphere(destination, radius * 0.55, 8, 6, color, true)
            end

            local light = DynamicLight(watcher:EntIndex())
            if light then
                light.pos = origin
                light.r = 90
                light.g = 220
                light.b = 255
                light.brightness = 2.2 * (1 - t)
                light.Decay = 900
                light.Size = 150
                light.DieTime = now + 0.08
            end
        end
    end
end)