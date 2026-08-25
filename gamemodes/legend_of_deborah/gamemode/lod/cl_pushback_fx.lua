LOD = LOD or {}
LOD.PushbackFX = LOD.PushbackFX or {trails = {}, modelCache = {}}

local FX = LOD.PushbackFX
FX.trails = FX.trails or {}
FX.modelCache = FX.modelCache or {}

local trailMaterial = Material("sprites/light_glow02_add")
local ghostMaterial = Material("models/debug/debugwhite")
local dustTexture = "particle/particle_smokegrenade"
local sparkTexture = "effects/spark"
local TRAIL_LIFETIME = 0.30
local MAX_TRAILS = 12
local MAX_GHOST_DISTANCE_SQR = 2200 * 2200
local MIN_GHOST_SAMPLES = 8
local MAX_GHOST_SAMPLES = 16
local GHOST_SAMPLE_SPACING = 22

local function trailColor(source, alpha)
    source = string.lower(tostring(source or ""))
    if string.find(source, "force shout", 1, true) then
        return Color(105, 210, 255, alpha)
    end
    if string.find(source, "shotgun", 1, true) then
        return Color(255, 205, 105, alpha)
    end
    return Color(215, 230, 255, alpha)
end

local function ghostForModel(model)
    if not model or model == "" then return nil end
    local ghost = FX.modelCache[model]
    if IsValid(ghost) then return ghost end

    ghost = ClientsideModel(model, RENDERGROUP_OTHER)
    if not IsValid(ghost) then return nil end
    ghost:SetNoDraw(true)
    ghost:SetIK(false)
    FX.modelCache[model] = ghost
    return ghost
end

local function emitCrushParticles(pos, wallNormal)
    local emitter = ParticleEmitter(pos)
    if not emitter then return end

    wallNormal = wallNormal or vector_origin
    if wallNormal:LengthSqr() > 0.01 then wallNormal = wallNormal:GetNormalized() end

    -- Dense but very short-lived dust/spark burst placed just outside the wall,
    -- so it remains visible instead of spawning inside generated geometry.
    for i = 1, 14 do
        local particle = emitter:Add(dustTexture, pos + VectorRand() * 6)
        if particle then
            local away = wallNormal * math.Rand(38, 90) + VectorRand() * math.Rand(28, 66) + Vector(0, 0, math.Rand(20, 72))
            particle:SetVelocity(away)
            particle:SetDieTime(math.Rand(0.38, 0.72))
            particle:SetStartAlpha(math.random(125, 185))
            particle:SetEndAlpha(0)
            particle:SetStartSize(math.Rand(7, 13))
            particle:SetEndSize(math.Rand(22, 38))
            particle:SetRoll(math.Rand(0, 360))
            particle:SetRollDelta(math.Rand(-1.5, 1.5))
            particle:SetColor(175, 165, 145)
            particle:SetAirResistance(34)
        end
    end

    for i = 1, 12 do
        local particle = emitter:Add(sparkTexture, pos + VectorRand() * 4)
        if particle then
            particle:SetVelocity(wallNormal * math.Rand(70, 145) + VectorRand() * math.Rand(55, 120))
            particle:SetDieTime(math.Rand(0.12, 0.26))
            particle:SetStartAlpha(255)
            particle:SetEndAlpha(0)
            particle:SetStartSize(math.Rand(3, 5))
            particle:SetEndSize(0)
            particle:SetColor(255, 225, 165)
            particle:SetGravity(Vector(0, 0, -300))
        end
    end

    emitter:Finish()
end

net.Receive("LOD_PushbackFX", function()
    local hostile = net.ReadEntity()
    local startPos = net.ReadVector()
    local endPos = net.ReadVector()
    local impactPos = net.ReadVector()
    local impactNormal = net.ReadVector()
    local crushed = net.ReadBool()
    local source = net.ReadString()
    local model = net.ReadString()
    local angles = net.ReadAngle()

    local delta = endPos - startPos
    local moved = delta:Length()
    if moved > 0.05 then
        FX.trails[#FX.trails + 1] = {
            hostile = hostile,
            model = model,
            angles = angles,
            modelScale = IsValid(hostile) and hostile:GetModelScale() or 1,
            sequence = IsValid(hostile) and hostile:GetSequence() or -1,
            cycle = IsValid(hostile) and hostile:GetCycle() or 0,
            startPos = startPos,
            endPos = endPos,
            source = source,
            started = CurTime(),
            lifetime = TRAIL_LIFETIME
        }
        while #FX.trails > MAX_TRAILS do table.remove(FX.trails, 1) end
    end

    if crushed then
        local normal = impactNormal
        if normal:LengthSqr() <= 0.01 and delta:LengthSqr() > 0.01 then normal = -delta:GetNormalized() end
        local visualImpact = impactPos + normal * 8
        emitCrushParticles(visualImpact, normal)

        local effect = EffectData()
        effect:SetOrigin(visualImpact)
        effect:SetNormal(normal)
        effect:SetScale(0.85)
        util.Effect("cball_bounce", effect)

        local dust = EffectData()
        dust:SetOrigin(visualImpact)
        dust:SetNormal(normal)
        dust:SetScale(1.1)
        util.Effect("DustImpact", dust)
    end
end)

local function drawBodyGhost(event, t, alpha)
    local ghost = ghostForModel(event.model)
    if not IsValid(ghost) then return end

    local pos = LerpVector(t, event.startPos, event.endPos)
    local color = trailColor(event.source, alpha)

    ghost:SetPos(pos)
    ghost:SetAngles(event.angles or angle_zero)
    ghost:SetModelScale(math.max(0.05, tonumber(event.modelScale) or 1), 0)
    if (event.sequence or -1) >= 0 then
        ghost:SetSequence(event.sequence)
        ghost:SetCycle(event.cycle or 0)
    end

    -- A cached ClientsideModel can be drawn repeatedly in one frame, but Source
    -- retains its first bone transform unless bones are rebuilt before each draw.
    -- Rebuilding here is the critical part that lets every sampled position render
    -- as a distinct afterimage while still reusing one cached model per archetype.
    ghost:SetupBones()

    render.MaterialOverride(ghostMaterial)
    render.SetColorModulation(color.r / 255, color.g / 255, color.b / 255)
    render.SetBlend(math.Clamp(alpha / 255, 0, 1))
    ghost:DrawModel()
    render.SetBlend(1)
    render.SetColorModulation(1, 1, 1)
    render.MaterialOverride(nil)
end

local function ghostSampleCount(length)
    return math.Clamp(math.ceil(length / GHOST_SAMPLE_SPACING), MIN_GHOST_SAMPLES, MAX_GHOST_SAMPLES)
end

local function drawTrail(event, now)
    local age = now - event.started
    local fraction = math.Clamp(age / event.lifetime, 0, 1)
    local fade = 1 - fraction
    if fade <= 0 then return false end

    local startPos = event.startPos
    local endPos = event.endPos
    local delta = endPos - startPos
    local length = delta:Length()
    if length <= 0.05 then return true end

    local lp = LocalPlayer()
    local nearby = not IsValid(lp) or lp:EyePos():DistToSqr(endPos) <= MAX_GHOST_DISTANCE_SQR

    -- Eight to sixteen translucent snapshots of the creature's own body make the
    -- server-authoritative displacement read as one continuous shove rather than
    -- a teleport. Samples scale with travel distance; earlier ghosts are dimmer
    -- and destination-side ghosts brighter to reinforce direction.
    if nearby then
        local samples = ghostSampleCount(length)
        for i = 1, samples do
            local t = i / (samples + 1)
            local pathBrightness = 0.58 + 0.42 * t
            drawBodyGhost(event, t, math.floor(150 * fade * pathBrightness))
        end
    end

    -- One inexpensive luminous spine keeps tiny archetypes readable between the
    -- body silhouettes and makes push direction unambiguous.
    local color = trailColor(event.source, math.floor(165 * fade))
    render.SetMaterial(trailMaterial)
    render.DrawBeam(startPos + Vector(0, 0, 30), endPos + Vector(0, 0, 30),
        5 * fade + 1, 0, 1, color)

    return true
end

hook.Add("PostDrawTranslucentRenderables", "LOD_PushbackMotionTrails", function()
    local now = CurTime()
    for i = #FX.trails, 1, -1 do
        local event = FX.trails[i]
        if now - event.started >= event.lifetime then
            table.remove(FX.trails, i)
        else
            drawTrail(event, now)
        end
    end
end)

hook.Add("ShutDown", "LOD_PushbackGhostCacheCleanup", function()
    for model, ghost in pairs(FX.modelCache) do
        if IsValid(ghost) then ghost:Remove() end
        FX.modelCache[model] = nil
    end
end)
