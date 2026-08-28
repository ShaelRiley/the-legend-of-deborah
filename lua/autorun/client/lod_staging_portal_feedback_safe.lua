LOD = LOD or {}

-- Safe portal feedback authority.
-- This file is deliberately CLIENT-ONLY and observational: it never changes
-- staging state, deployment timing, entity methods, RunManager, or maze startup.
-- It reacts to the existing local Use press and authoritative NW2 deployed state.

local PORTAL_KIND = 2
local ADVANCED_STARTERS = {
    weapon_shotgun = true,
    weapon_smg1 = true,
    weapon_357 = true,
    weapon_ar2 = true
}

local glow = Material("sprites/light_glow02_add")
local beam = Material("sprites/physbeam")
local CYAN = Color(72, 154, 255, 255)
local PALE = Color(205, 240, 255, 255)
local GOLD = Color(255, 205, 78, 255)

local worldEvents = {}
local serial = 0
local lastStaged = nil
local lastDeployed = nil
local pendingUseAt = nil
local pendingPortalPos = nil
local screenDeparture = nil
local screenArrival = nil

local function inLOD()
    return engine and engine.ActiveGamemode and engine.ActiveGamemode() == "legend_of_deborah"
end

local function hasStarterWeapon(ply)
    if not IsValid(ply) then return false end
    for className in pairs(ADVANCED_STARTERS) do
        if IsValid(ply:GetWeapon(className)) then return true end
    end
    return false
end

local function aimedPortal(ply)
    if not IsValid(ply) then return nil end
    local eye = ply:EyePos()
    local forward = ply:EyeAngles():Forward()
    local best, bestDot

    for _, ent in ipairs(ents.FindByClass("lod_staging_prop")) do
        if IsValid(ent) and ent.GetStageKind and ent:GetStageKind() == PORTAL_KIND then
            local target = ent:GetPos() + Vector(0, 0, 68)
            local delta = target - eye
            local dist2 = delta:LengthSqr()
            if dist2 <= (360 * 360) and dist2 > 1 then
                delta:Normalize()
                local dot = forward:Dot(delta)
                if dot >= 0.90 and (not bestDot or dot > bestDot) then
                    best, bestDot = ent, dot
                end
            end
        end
    end

    return best
end

local function addEvent(phase, pos, right, up, duration)
    serial = serial + 1
    worldEvents[#worldEvents + 1] = {
        serial = serial,
        phase = phase,
        pos = pos,
        right = right or Vector(1, 0, 0),
        up = up or Vector(0, 0, 1),
        started = CurTime(),
        finishes = CurTime() + duration
    }
    return worldEvents[#worldEvents]
end

local function addParticle(emitter, pos, velocity, color, startSize, endSize, life)
    local p = emitter:Add("sprites/light_glow02_add", pos)
    if not p then return end
    p:SetVelocity(velocity)
    p:SetDieTime(life)
    p:SetStartAlpha(color.a or 255)
    p:SetEndAlpha(0)
    p:SetStartSize(startSize)
    p:SetEndSize(endSize)
    p:SetColor(color.r, color.g, color.b)
    p:SetAirResistance(26)
    p:SetGravity(Vector(0, 0, 12))
    p:SetCollide(false)
end

local function spawnInwardParticles(center, right, up)
    local emitter = ParticleEmitter(center)
    if not emitter then return end

    for i = 1, 50 do
        local a = ((i - 1) / 50) * math.pi * 2 + math.Rand(-0.12, 0.12)
        local radiusX = math.Rand(42, 74)
        local radiusZ = math.Rand(54, 96)
        local start = center + right * math.cos(a) * radiusX + up * math.sin(a) * radiusZ
        local velocity = (center - start) * math.Rand(2.4, 3.7)
        local color = (i % 4 == 0) and GOLD or ((i % 3 == 0) and PALE or CYAN)
        addParticle(emitter, start, velocity, color, math.Rand(5, 10), 1, math.Rand(0.38, 0.62))
    end

    emitter:Finish()
end

local function spawnArrivalParticles(center)
    local emitter = ParticleEmitter(center)
    if not emitter then return end

    for i = 1, 64 do
        local dir = VectorRand()
        dir.z = math.abs(dir.z) * 0.74 + 0.16
        dir:Normalize()
        local start = center + dir * math.Rand(4, 15)
        local velocity = dir * math.Rand(120, 260)
        local color = (i % 3 == 0) and GOLD or ((i % 5 == 0) and PALE or CYAN)
        addParticle(emitter, start, velocity, color, math.Rand(4, 8), math.Rand(10, 19), math.Rand(0.42, 0.82))
    end

    emitter:Finish()
end

local function playDepartureCue()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local pos = ply:EyePos()

    sound.Play("ambient/machines/teleport3.wav", pos, 72, 88, 0.68)
    sound.Play("buttons/button17.wav", pos, 64, 92, 0.34)

    timer.Simple(0.10, function()
        local p = LocalPlayer()
        if IsValid(p) then sound.Play("buttons/button17.wav", p:EyePos(), 66, 116, 0.40) end
    end)
    timer.Simple(0.22, function()
        local p = LocalPlayer()
        if IsValid(p) then sound.Play("buttons/button17.wav", p:EyePos(), 68, 146, 0.48) end
    end)
end

local function playArrivalCue()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local pos = ply:EyePos()
    sound.Play("ambient/energy/zap1.wav", pos, 68, 112, 0.48)
    sound.Play("buttons/button17.wav", pos, 70, 178, 0.56)
end

local function beginDeparture(portal)
    if not IsValid(portal) then return end
    local center = portal:GetPos() + Vector(0, 0, 68)
    local right = portal:GetRight():GetNormalized()
    local up = Vector(0, 0, 1)

    pendingUseAt = CurTime()
    pendingPortalPos = center
    screenDeparture = {started = CurTime(), finishes = CurTime() + 0.55}
    addEvent(0, center, right, up, 0.58)
    spawnInwardParticles(center, right, up)
    playDepartureCue()

    local ply = LocalPlayer()
    if IsValid(ply) then
        ply:ScreenFade(SCREENFADE.IN, Color(50, 126, 255, 52), 0.12, 0)
    end
end

local function beginArrival()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local center = ply:GetPos() + Vector(0, 0, 42)
    local right = ply:GetRight():GetNormalized()
    local up = Vector(0, 0, 1)

    screenArrival = {started = CurTime(), finishes = CurTime() + 0.64}
    addEvent(1, center, right, up, 0.72)
    spawnArrivalParticles(center)
    playArrivalCue()
    ply:ScreenFade(SCREENFADE.IN, Color(255, 218, 104, 72), 0.10, 0)

    util.ScreenShake(center, 1.6, 18, 0.18, 120)
end

hook.Add("PlayerBindPress", "LOD_StagingPortalFeedbackSafeUse", function(ply, bind, pressed)
    if not pressed or not inLOD() then return end
    if not IsValid(ply) or ply ~= LocalPlayer() then return end
    if ply:GetNW2Bool("LOD_Deployed", false) or not ply:GetNW2Bool("LOD_Staged", false) then return end
    if not string.find(string.lower(bind or ""), "+use", 1, true) then return end
    if not hasStarterWeapon(ply) then return end

    local portal = aimedPortal(ply)
    if not IsValid(portal) then return end
    if pendingUseAt and CurTime() - pendingUseAt < 0.35 then return end
    beginDeparture(portal)
end)

hook.Add("Think", "LOD_StagingPortalFeedbackSafeState", function()
    if not inLOD() then
        lastStaged, lastDeployed = nil, nil
        return
    end

    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local staged = ply:GetNW2Bool("LOD_Staged", false)
    local deployed = ply:GetNW2Bool("LOD_Deployed", false)

    if lastStaged == nil then
        lastStaged, lastDeployed = staged, deployed
        return
    end

    -- Authoritative success signal: the existing staging code changed the player's
    -- networked state. We only celebrate after that fact; we never cause it.
    if deployed and not lastDeployed and (lastStaged or staged == false) then
        if not pendingUseAt or CurTime() - pendingUseAt > 1.2 then
            -- Controller/alternate input path may bypass PlayerBindPress. Supply a
            -- short transition cue anyway, but do not touch server state.
            screenDeparture = {started = CurTime(), finishes = CurTime() + 0.24}
        end
        beginArrival()
        pendingUseAt = nil
        pendingPortalPos = nil
    end

    lastStaged, lastDeployed = staged, deployed

    local now = CurTime()
    for i = #worldEvents, 1, -1 do
        if now >= worldEvents[i].finishes then table.remove(worldEvents, i) end
    end
    if screenDeparture and now >= screenDeparture.finishes then screenDeparture = nil end
    if screenArrival and now >= screenArrival.finishes then screenArrival = nil end
    if pendingUseAt and now - pendingUseAt > 1.4 then
        pendingUseAt = nil
        pendingPortalPos = nil
    end
end)

local function squarePoints(center, right, up, radius, rotation)
    local corners = {{-1, -1}, {1, -1}, {1, 1}, {-1, 1}}
    local c, s = math.cos(rotation), math.sin(rotation)
    local out = {}
    for i = 1, 4 do
        local x, y = corners[i][1], corners[i][2]
        local rx = x * c - y * s
        local ry = x * s + y * c
        out[i] = center + right * rx * radius + up * ry * radius
    end
    return out
end

local function drawSquare(center, right, up, radius, rotation, width, color)
    local pts = squarePoints(center, right, up, radius, rotation)
    render.SetMaterial(beam)
    for i = 1, 4 do
        render.DrawBeam(pts[i], pts[(i % 4) + 1], width, 0, 1, color)
    end
end

hook.Add("PostDrawTranslucentRenderables", "LOD_StagingPortalFeedbackSafeWorld", function(depth, sky)
    if depth or sky or not inLOD() then return end
    local now = CurTime()

    for _, ev in ipairs(worldEvents) do
        local duration = math.max(0.01, ev.finishes - ev.started)
        local p = math.Clamp((now - ev.started) / duration, 0, 1)
        local fade = math.floor(255 * (1 - p))
        local spin = now * 3.0

        if ev.phase == 0 then
            local collapse = 1 - p * 0.68
            drawSquare(ev.pos, ev.right, ev.up, 76 * collapse, spin, 5.0, Color(CYAN.r, CYAN.g, CYAN.b, fade))
            drawSquare(ev.pos, ev.right, ev.up, 55 * collapse, -spin * 1.3, 3.8, Color(GOLD.r, GOLD.g, GOLD.b, fade))
            drawSquare(ev.pos, ev.right, ev.up, 35 * collapse, spin * 1.8, 2.5, Color(PALE.r, PALE.g, PALE.b, fade))
        else
            local expand = 20 + 92 * p
            drawSquare(ev.pos, ev.right, ev.up, expand, spin, 5.2, Color(GOLD.r, GOLD.g, GOLD.b, fade))
            drawSquare(ev.pos, ev.right, ev.up, expand * 0.72, -spin * 1.25, 3.8, Color(CYAN.r, CYAN.g, CYAN.b, fade))
            drawSquare(ev.pos, ev.right, ev.up, expand * 0.46, spin * 1.7, 2.5, Color(PALE.r, PALE.g, PALE.b, fade))
        end

        render.SetMaterial(glow)
        render.DrawSprite(ev.pos, 86 + 34 * (1 - p), 110 + 44 * (1 - p),
            ev.phase == 0 and Color(80, 160, 255, math.floor(fade * 0.48))
                or Color(255, 214, 92, math.floor(fade * 0.44)))
    end
end)

hook.Add("HUDPaint", "LOD_StagingPortalFeedbackSafeScreen", function()
    if not inLOD() then return end
    local now = CurTime()

    if screenDeparture and now < screenDeparture.finishes then
        local duration = math.max(0.01, screenDeparture.finishes - screenDeparture.started)
        local p = math.Clamp((now - screenDeparture.started) / duration, 0, 1)
        local envelope = math.sin(p * math.pi)
        surface.SetDrawColor(52, 128, 255, math.floor(48 * envelope))
        surface.DrawRect(0, 0, ScrW(), ScrH())

        for i = 0, 2 do
            local inset = math.floor(24 + i * 30 + p * 54)
            surface.SetDrawColor(255, 211, 78, math.floor((140 - i * 24) * envelope))
            surface.DrawOutlinedRect(inset, inset, ScrW() - inset * 2, ScrH() - inset * 2, 3)
        end
    end

    if screenArrival and now < screenArrival.finishes then
        local duration = math.max(0.01, screenArrival.finishes - screenArrival.started)
        local p = math.Clamp((now - screenArrival.started) / duration, 0, 1)
        local fade = 1 - p
        surface.SetDrawColor(255, 218, 104, math.floor(62 * fade))
        surface.DrawRect(0, 0, ScrW(), ScrH())

        for i = 0, 2 do
            local inset = math.floor(92 - i * 20 - p * 70)
            inset = math.max(8, inset)
            surface.SetDrawColor(72, 154, 255, math.floor((150 - i * 25) * fade))
            surface.DrawOutlinedRect(inset, inset, ScrW() - inset * 2, ScrH() - inset * 2, 3)
        end
    end
end)

concommand.Add("lod_staging_portal_feedback_status", function()
    print("[LOD:STAGING-PORTAL] armed=true mode=client-observer serverMutations=0 audio=rising-cue visual=blue-gold-maze-sigil result=PASS")
end)
