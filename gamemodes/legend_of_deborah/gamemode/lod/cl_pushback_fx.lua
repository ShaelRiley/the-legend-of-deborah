LOD = LOD or {}
LOD.PushbackFX = LOD.PushbackFX or {trails = {}}

local FX = LOD.PushbackFX
local trailMaterial = Material("sprites/light_glow02_add")
local ghostMaterial = Material("models/debug/debugwhite")
local dustTexture = "particle/particle_smokegrenade"
local sparkTexture = "effects/spark"
local TRAIL_LIFETIME = 0.30
local MAX_TRAILS = 12
local MAX_GHOST_DISTANCE_SQR = 2200 * 2200
local GHOST_SAMPLES = {0.16, 0.36, 0.56, 0.76}

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
    if not event.model or event.model == "" then return end

    local pos = LerpVector(t, event.startPos, event.endPos)
    local color = trailColor(event.source, alpha)

    render.MaterialOverride(ghostMaterial)
    render.SetColorModulation(color.r / 255, color.g / 255, color.b / 255)
    render.SetBlend(math.Clamp(alpha / 255, 0, 1))
    render.Model({
        model = event.model,
        pos = pos,
        angle = event.angles or angle_zero
    })
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

    -- Render-only silhouettes of the hostile's own body make the entire resolved
    -- displacement path legible at a glance. Four model draws exist for only
    -- 0.30 s, create no entities, run no Think/physics, and are distance culled.
    if nearby then
        for i, t in ipairs(GHOST_SAMPLES) do
            local stagger = 1 - ((i - 1) / (#GHOST_SAMPLES + 1)) * 0.35
            drawBodyGhost(event, t, math.floor(125 * fade * stagger))
        end
    end

    -- Keep one inexpensive luminous spine underneath the body ghosts so even
    -- tiny archetypes retain a readable direction of travel.
    local color = trailColor(event.source, math.floor(155 * fade))
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
