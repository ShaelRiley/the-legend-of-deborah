LOD = LOD or {}
LOD.PushbackFX = LOD.PushbackFX or {trails = {}}

local FX = LOD.PushbackFX
local trailMaterial = Material("sprites/light_glow02_add")
local dustTexture = "particle/particle_smokegrenade"
local sparkTexture = "effects/spark"
local TRAIL_LIFETIME = 0.26
local MAX_TRAILS = 24

local function trailColor(source, alpha)
    source = string.lower(tostring(source or ""))
    if string.find(source, "force shout", 1, true) then
        return Color(150, 225, 255, alpha)
    end
    if string.find(source, "shotgun", 1, true) then
        return Color(255, 220, 150, alpha)
    end
    return Color(225, 235, 245, alpha)
end

local function emitCrushParticles(pos, direction)
    local emitter = ParticleEmitter(pos)
    if not emitter then return end

    direction = direction or vector_origin
    if direction:LengthSqr() > 0.01 then direction = direction:GetNormalized() end

    for i = 1, 10 do
        local particle = emitter:Add(dustTexture, pos + VectorRand() * 5)
        if particle then
            local away = (-direction * math.Rand(30, 75)) + VectorRand() * math.Rand(24, 58) + Vector(0, 0, math.Rand(18, 62))
            particle:SetVelocity(away)
            particle:SetDieTime(math.Rand(0.35, 0.65))
            particle:SetStartAlpha(math.random(95, 155))
            particle:SetEndAlpha(0)
            particle:SetStartSize(math.Rand(5, 10))
            particle:SetEndSize(math.Rand(18, 30))
            particle:SetRoll(math.Rand(0, 360))
            particle:SetRollDelta(math.Rand(-1.4, 1.4))
            particle:SetColor(150, 145, 135)
            particle:SetAirResistance(30)
        end
    end

    for i = 1, 8 do
        local particle = emitter:Add(sparkTexture, pos + VectorRand() * 3)
        if particle then
            particle:SetVelocity((-direction * math.Rand(55, 110)) + VectorRand() * math.Rand(45, 95))
            particle:SetDieTime(math.Rand(0.10, 0.22))
            particle:SetStartAlpha(230)
            particle:SetEndAlpha(0)
            particle:SetStartSize(math.Rand(2, 4))
            particle:SetEndSize(0)
            particle:SetColor(255, 225, 170)
            particle:SetGravity(Vector(0, 0, -260))
        end
    end

    emitter:Finish()
end

net.Receive("LOD_PushbackFX", function()
    local hostile = net.ReadEntity()
    local startPos = net.ReadVector()
    local endPos = net.ReadVector()
    local impactPos = net.ReadVector()
    local crushed = net.ReadBool()
    local source = net.ReadString()

    local delta = endPos - startPos
    local moved = delta:Length()
    if moved > 0.05 then
        FX.trails[#FX.trails + 1] = {
            hostile = hostile,
            startPos = startPos,
            endPos = endPos,
            source = source,
            started = CurTime(),
            lifetime = TRAIL_LIFETIME
        }
        while #FX.trails > MAX_TRAILS do table.remove(FX.trails, 1) end
    end

    if crushed then
        emitCrushParticles(impactPos, delta)

        local effect = EffectData()
        effect:SetOrigin(impactPos)
        effect:SetScale(0.45)
        util.Effect("cball_bounce", effect)
    end
end)

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

    local alpha = math.floor(190 * fade)
    local color = trailColor(event.source, alpha)
    render.SetMaterial(trailMaterial)

    -- Three longitudinal streaks make the instantaneous server-authoritative
    -- displacement read as continuous motion rather than a teleport.
    for _, z in ipairs({14, 36, 58}) do
        render.DrawBeam(startPos + Vector(0, 0, z), endPos + Vector(0, 0, z),
            7 * fade + 1, 0, 1, color)
    end

    -- Ghost points along the entire resolved path leave a short afterimage of the
    -- enemy's travel volume without creating temporary clientside model entities.
    local samples = math.Clamp(math.ceil(length / 38), 4, 9)
    for i = 1, samples - 1 do
        local t = i / samples
        local pos = LerpVector(t, startPos, endPos) + Vector(0, 0, 34)
        local pointAlpha = math.floor(alpha * (0.45 + 0.35 * t))
        local pointColor = trailColor(event.source, pointAlpha)
        render.DrawSprite(pos, 14 + 10 * fade, 28 + 18 * fade, pointColor)
    end

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
