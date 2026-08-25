LOD = LOD or {}
LOD.PushbackFX = LOD.PushbackFX or {trails = {}, modelPools = {}}

local FX = LOD.PushbackFX
FX.trails = FX.trails or {}
FX.modelPools = FX.modelPools or {}

-- Retire the old single-model cache on hot reload. A single ClientsideModel cannot
-- reliably represent several different world transforms in the same render frame.
if FX.modelCache then
    for _, cached in pairs(FX.modelCache) do
        if IsValid(cached) then cached:Remove() end
    end
    FX.modelCache = nil
end

local trailMaterial = Material("sprites/light_glow02_add")
local ghostMaterial = Material("models/debug/debugwhite")
local dustTexture = "particle/particle_smokegrenade"
local sparkTexture = "effects/spark"
local TRAIL_LIFETIME = 0.30
local MAX_TRAILS = 12
local MAX_GHOST_DISTANCE_SQR = 2200 * 2200
local MIN_GHOST_SAMPLES = 4
local MAX_GHOST_SAMPLES = 16
local GHOST_SAMPLE_SPACING = 28
local MAX_FREE_GHOSTS_PER_MODEL = 32

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

local function poolForModel(model)
    if not model or model == "" then return nil end
    local pool = FX.modelPools[model]
    if pool then return pool end
    pool = {free = {}}
    FX.modelPools[model] = pool
    return pool
end

local function createGhost(model)
    local ghost = ClientsideModel(model, RENDERGROUP_OTHER)
    if not IsValid(ghost) then return nil end
    ghost:SetNoDraw(true)
    ghost:SetIK(false)
    return ghost
end

local function acquireGhost(model)
    local pool = poolForModel(model)
    if not pool then return nil end

    while #pool.free > 0 do
        local ghost = table.remove(pool.free)
        if IsValid(ghost) then return ghost end
    end
    return createGhost(model)
end

local function releaseGhost(model, ghost)
    if not IsValid(ghost) then return end
    local pool = poolForModel(model)
    if not pool or #pool.free >= MAX_FREE_GHOSTS_PER_MODEL then
        ghost:Remove()
        return
    end

    ghost:SetNoDraw(true)
    ghost:SetPos(vector_origin)
    ghost:SetAngles(angle_zero)
    ghost:SetModelScale(1, 0)
    pool.free[#pool.free + 1] = ghost
end

local function releaseTrailGhosts(event)
    if not event or not event.ghosts then return end
    for _, ghost in ipairs(event.ghosts) do
        releaseGhost(event.model, ghost)
    end
    event.ghosts = nil
end

local function ghostSampleCount(length)
    return math.Clamp(math.ceil(length / GHOST_SAMPLE_SPACING), MIN_GHOST_SAMPLES, MAX_GHOST_SAMPLES)
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
        local sampleCount = ghostSampleCount(moved)
        local ghosts = {}
        for i = 1, sampleCount do
            local ghost = acquireGhost(model)
            if IsValid(ghost) then ghosts[#ghosts + 1] = ghost end
        end

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
            lifetime = TRAIL_LIFETIME,
            sampleCount = sampleCount,
            ghosts = ghosts
        }

        while #FX.trails > MAX_TRAILS do
            local retired = table.remove(FX.trails, 1)
            releaseTrailGhosts(retired)
        end
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

local function drawBodyGhost(event, ghost, t, alpha)
    if not IsValid(ghost) then return end

    local pos = LerpVector(t, event.startPos, event.endPos)
    local color = trailColor(event.source, alpha)

    -- Each simultaneous silhouette owns a distinct cached CSEnt for the 0.30 s
    -- event. That avoids Source's same-entity/same-frame transform cache entirely:
    -- no SetupBones gymnastics and no per-frame ClientsideModel allocation.
    ghost:SetPos(pos)
    ghost:SetAngles(event.angles or angle_zero)
    ghost:SetModelScale(math.max(0.05, tonumber(event.modelScale) or 1), 0)
    if (event.sequence or -1) >= 0 then
        ghost:SetSequence(event.sequence)
        ghost:SetCycle(event.cycle or 0)
    end

    render.MaterialOverride(ghostMaterial)
    render.SetColorModulation(color.r / 255, color.g / 255, color.b / 255)
    render.SetBlend(math.Clamp(alpha / 255, 0, 1))
    ghost:DrawModel()
    render.SetBlend(1)
    render.SetColorModulation(1, 1, 1)
    render.MaterialOverride(nil)
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

    -- Four to sixteen body snapshots scale with travel distance. The typical
    -- Shotgun push gets several readable silhouettes while very long Force Shout
    -- throws can use the full sixteen without making every ordinary push noisy.
    if nearby then
        local samples = math.max(1, tonumber(event.sampleCount) or #event.ghosts)
        for i, ghost in ipairs(event.ghosts or {}) do
            local t = i / (samples + 1)
            local pathBrightness = 0.58 + 0.42 * t
            drawBodyGhost(event, ghost, t, math.floor(150 * fade * pathBrightness))
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
            releaseTrailGhosts(event)
            table.remove(FX.trails, i)
        else
            drawTrail(event, now)
        end
    end
end)

hook.Add("ShutDown", "LOD_PushbackGhostCacheCleanup", function()
    for _, event in ipairs(FX.trails) do
        if event.ghosts then
            for _, ghost in ipairs(event.ghosts) do
                if IsValid(ghost) then ghost:Remove() end
            end
        end
    end
    FX.trails = {}

    for model, pool in pairs(FX.modelPools) do
        for _, ghost in ipairs(pool.free or {}) do
            if IsValid(ghost) then ghost:Remove() end
        end
        FX.modelPools[model] = nil
    end
end)
