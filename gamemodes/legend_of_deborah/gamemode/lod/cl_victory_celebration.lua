LOD = LOD or {}
LOD.VictoryCelebrationClient = LOD.VictoryCelebrationClient or {}

local Client = LOD.VictoryCelebrationClient
local CONFETTI_MATERIALS = {
    "particle/particle_glow_04",
    "sprites/light_glow02_add"
}
local CONFETTI_COLORS = {
    Color(238, 88, 88),
    Color(76, 156, 238),
    Color(244, 205, 76),
    Color(104, 205, 124),
    Color(202, 102, 224),
    Color(245, 137, 61),
    Color(245, 245, 245)
}
local CHEER_SOUNDS = {
    "vo/npc/male01/yeah02.wav",
    "vo/npc/female01/fantastic01.wav",
    "vo/npc/male01/nice.wav"
}

surface.CreateFont("LOD_Victory_Title", {
    font = "DejaVu Sans",
    size = 54,
    weight = 1000,
    antialias = true
})

surface.CreateFont("LOD_Victory_Subtitle", {
    font = "DejaVu Sans",
    size = 21,
    weight = 800,
    antialias = true
})

local function soundExists(path)
    return isstring(path) and file.Exists("sound/" .. path, "GAME")
end

local function playCelebrationAudio()
    -- Garry's Mod itself ships this with its balloon implementation. It gives the
    -- celebration a silly toy-like punctuation before the citizen cheer layer.
    if soundExists("garrysmod/balloon_pop_cute.wav") then
        surface.PlaySound("garrysmod/balloon_pop_cute.wav")
        timer.Simple(0.16, function()
            if soundExists("garrysmod/balloon_pop_cute.wav") then
                surface.PlaySound("garrysmod/balloon_pop_cute.wav")
            end
        end)
    end

    if soundExists("buttons/button9.wav") then surface.PlaySound("buttons/button9.wav") end

    local delay = 0.08
    for _, path in ipairs(CHEER_SOUNDS) do
        local soundPath = path
        if soundExists(soundPath) then
            local scheduledAt = delay
            timer.Simple(scheduledAt, function()
                if soundExists(soundPath) then surface.PlaySound(soundPath) end
            end)
            delay = delay + 0.13
        end
    end
end

local function emitConfettiBurst(center, seedOffset)
    local emitter = ParticleEmitter(center, false)
    if not emitter then return end

    local localPly = LocalPlayer()
    local localCenter = IsValid(localPly) and localPly:GetPos() + Vector(0, 0, 190) or center + Vector(0, 0, 190)
    local count = 90
    for i = 1, count do
        local material = CONFETTI_MATERIALS[((i + (seedOffset or 0)) % #CONFETTI_MATERIALS) + 1]
        local pos = localCenter + Vector(math.Rand(-170, 170), math.Rand(-170, 170), math.Rand(0, 70))
        local p = emitter:Add(material, pos)
        if p then
            local c = CONFETTI_COLORS[((i + (seedOffset or 0)) % #CONFETTI_COLORS) + 1]
            p:SetDieTime(math.Rand(3.6, 5.4))
            p:SetStartAlpha(255)
            p:SetEndAlpha(0)
            p:SetStartSize(math.Rand(1.8, 3.8))
            p:SetEndSize(math.Rand(1.0, 2.5))
            p:SetColor(c.r, c.g, c.b)
            p:SetVelocity(Vector(math.Rand(-42, 42), math.Rand(-42, 42), math.Rand(-75, -30)))
            p:SetGravity(Vector(0, 0, -42))
            p:SetAirResistance(18)
            p:SetRoll(math.Rand(0, 360))
            p:SetRollDelta(math.Rand(-5.5, 5.5))
            p:SetCollide(false)
        end
    end
    emitter:Finish()
end

local function scheduleConfetti(center)
    emitConfettiBurst(center, 0)
    timer.Simple(0.70, function() emitConfettiBurst(center, 17) end)
    timer.Simple(1.40, function() emitConfettiBurst(center, 31) end)
end

net.Receive("LOD_VictoryCelebration", function()
    Client.center = net.ReadVector()
    Client.duration = math.max(0, net.ReadFloat())
    Client.deborah = net.ReadEntity()
    Client.startedAt = CurTime()
    Client.endsAt = Client.startedAt + Client.duration
    playCelebrationAudio()
    scheduleConfetti(Client.center)
end)

local function celebrationActive()
    return Client.endsAt and CurTime() < Client.endsAt
end

-- A short pulled-back Source-style celebration camera gives the real balloon props
-- and confetti room to read. Hull tracing prevents the camera from clipping through
-- the generated container walls.
hook.Add("CalcView", "LOD_VictoryCelebrationThirdPerson", function(ply, origin, angles, fov)
    if not celebrationActive() or not IsValid(ply) or not ply:Alive() then return end

    local wanted = origin - angles:Forward() * 118 + Vector(0, 0, 34)
    local tr = util.TraceHull({
        start = origin,
        endpos = wanted,
        mins = Vector(-6, -6, -6),
        maxs = Vector(6, 6, 6),
        mask = MASK_SOLID,
        filter = ply
    })

    return {
        origin = tr.HitPos,
        angles = angles,
        fov = fov,
        drawviewer = true
    }
end)

hook.Add("HUDPaint", "LOD_VictoryCelebrationHUD", function()
    if not celebrationActive() then return end
    local elapsed = CurTime() - (Client.startedAt or CurTime())
    local remaining = math.max(0, (Client.endsAt or CurTime()) - CurTime())
    local fadeIn = math.Clamp(elapsed / 0.30, 0, 1)
    local fadeOut = math.Clamp(remaining / 0.85, 0, 1)
    local alpha = math.floor(255 * math.min(fadeIn, fadeOut))
    if alpha <= 0 then return end

    local y = math.floor(ScrH() * 0.13)
    draw.SimpleText("CONGRATULATIONS", "LOD_Victory_Title", ScrW() * 0.5, y + 3,
        Color(10, 10, 10, math.floor(alpha * 0.7)), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    draw.SimpleText("CONGRATULATIONS", "LOD_Victory_Title", ScrW() * 0.5, y,
        Color(248, 213, 105, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    draw.SimpleText("DEBORAH IS FREE", "LOD_Victory_Subtitle", ScrW() * 0.5, y + 63,
        Color(238, 238, 238, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end)

concommand.Add("lod_victory_client_status", function()
    print(string.format("[LOD:VICTORY-CLIENT] active=%s remaining=%.1fs center=%s",
        tostring(celebrationActive()),
        math.max(0, (Client.endsAt or 0) - CurTime()),
        tostring(Client.center or vector_origin)))
end)
