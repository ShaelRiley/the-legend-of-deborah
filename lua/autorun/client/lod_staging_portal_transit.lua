if engine.ActiveGamemode and engine.ActiveGamemode() ~= "legend_of_deborah" then return end

local glow = Material("sprites/light_glow02_add")
local beam = Material("sprites/physbeam")
local events = {}
local serial = 0
local localTransit
local localArrival

local CYAN = Color(72, 154, 255, 255)
local PALE = Color(190, 232, 255, 255)
local GOLD = Color(255, 205, 78, 255)

local function eventAxes(ev)
    if IsValid(ev.portal) then
        return ev.portal:GetRight():GetNormalized(), Vector(0, 0, 1), ev.portal:GetForward():GetNormalized()
    end
    if IsValid(ev.ply) then
        return ev.ply:GetRight():GetNormalized(), Vector(0, 0, 1), ev.ply:GetForward():GetNormalized()
    end
    return Vector(1, 0, 0), Vector(0, 0, 1), Vector(0, 1, 0)
end

local function addParticle(emitter, material, pos, velocity, color, startSize, endSize, life)
    local p = emitter:Add(material, pos)
    if not p then return end
    p:SetVelocity(velocity)
    p:SetDieTime(life)
    p:SetStartAlpha(color.a or 255)
    p:SetEndAlpha(0)
    p:SetStartSize(startSize)
    p:SetEndSize(endSize)
    p:SetColor(color.r, color.g, color.b)
    p:SetAirResistance(24)
    p:SetGravity(Vector(0, 0, 18))
    p:SetCollide(false)
end

local function spawnSuction(ev)
    local right, up, normal = eventAxes(ev)
    local emitter = ParticleEmitter(ev.pos)
    if not emitter then return end

    for i = 1, 54 do
        local a = ((i - 1) / 54) * math.pi * 2 + math.Rand(-0.10, 0.10)
        local radiusX = math.Rand(44, 72)
        local radiusZ = math.Rand(58, 94)
        local start = ev.pos
            + right * math.cos(a) * radiusX
            + up * math.sin(a) * radiusZ
            + normal * math.Rand(-8, 8)
        local velocity = (ev.pos - start) * math.Rand(2.1, 3.2) + normal * math.Rand(-18, 18)
        local color = (i % 4 == 0) and GOLD or ((i % 3 == 0) and PALE or CYAN)
        addParticle(emitter, "sprites/light_glow02_add", start, velocity, color,
            math.Rand(5, 9), math.Rand(1, 3), math.Rand(0.42, 0.68))
    end

    emitter:Finish()
end

local function spawnArrivalBurst(ev)
    local emitter = ParticleEmitter(ev.pos)
    if not emitter then return end

    for i = 1, 64 do
        local dir = VectorRand()
        dir.z = math.abs(dir.z) * 0.72 + 0.18
        dir:Normalize()
        local start = ev.pos + dir * math.Rand(4, 18)
        local velocity = dir * math.Rand(115, 245)
        local color = (i % 3 == 0) and GOLD or ((i % 4 == 0) and PALE or CYAN)
        addParticle(emitter, "sprites/light_glow02_add", start, velocity, color,
            math.Rand(4, 8), math.Rand(10, 18), math.Rand(0.48, 0.86))
    end

    emitter:Finish()
end

local function squarePoints(center, right, up, radius, rotation)
    local points = {
        {-1, -1}, {1, -1}, {1, 1}, {-1, 1}
    }
    local c, s = math.cos(rotation), math.sin(rotation)
    local out = {}
    for i = 1, 4 do
        local x, y = points[i][1], points[i][2]
        local rx = x * c - y * s
        local ry = x * s + y * c
        out[i] = center + right * rx * radius + up * ry * radius
    end
    return out
end

local function drawSquareRing(center, right, up, radius, rotation, width, color)
    local pts = squarePoints(center, right, up, radius, rotation)
    render.SetMaterial(beam)
    for i = 1, 4 do
        local j = (i % 4) + 1
        render.DrawBeam(pts[i], pts[j], width, 0, 1, color)
    end
end

local function drawTransitEvent(ev)
    local now = CurTime()
    local duration = math.max(0.01, ev.finishes - ev.started)
    local p = math.Clamp((now - ev.started) / duration, 0, 1)
    local right, up = eventAxes(ev)

    if ev.phase == 0 then
        local envelope = math.sin(p * math.pi)
        local collapse = 1 - p * 0.58
        local spin = now * 2.8
        local alpha = math.floor(235 * (0.35 + envelope * 0.65))

        drawSquareRing(ev.pos, right, up, 72 * collapse, spin,
            5.2, Color(CYAN.r, CYAN.g, CYAN.b, alpha))
        drawSquareRing(ev.pos, right, up, 54 * collapse, -spin * 1.25 + 0.42,
            3.8, Color(GOLD.r, GOLD.g, GOLD.b, math.floor(alpha * 0.94)))
        drawSquareRing(ev.pos, right, up, 36 * collapse, spin * 1.7 + 0.78,
            2.4, Color(PALE.r, PALE.g, PALE.b, math.floor(alpha * 0.84)))

        render.SetMaterial(glow)
        render.DrawSprite(ev.pos, 90 + envelope * 48, 118 + envelope * 64,
            Color(68, 142, 255, math.floor(90 + envelope * 115)))
        render.DrawSprite(ev.pos, 34 + envelope * 18, 52 + envelope * 25,
            Color(255, 218, 104, math.floor(115 + envelope * 120)))
    else
        local radius = 18 + 96 * p
        local fade = math.floor(255 * (1 - p))
        local spin = now * 3.4

        drawSquareRing(ev.pos, right, up, radius, spin,
            5.4, Color(GOLD.r, GOLD.g, GOLD.b, fade))
        drawSquareRing(ev.pos, right, up, radius * 0.72, -spin * 1.3,
            4.0, Color(CYAN.r, CYAN.g, CYAN.b, fade))
        drawSquareRing(ev.pos, right, up, radius * 0.46, spin * 1.9 + 0.5,
            2.8, Color(PALE.r, PALE.g, PALE.b, fade))

        render.SetMaterial(glow)
        render.DrawSprite(ev.pos, 136 * (1 - p * 0.45), 136 * (1 - p * 0.45),
            Color(140, 203, 255, math.floor(fade * 0.58)))
    end

    local light = DynamicLight(51000 + (ev.serial % 9000))
    if light then
        light.pos = ev.pos
        if ev.phase == 0 then
            light.r, light.g, light.b = 70, 150, 255
        else
            light.r, light.g, light.b = 255, 205, 85
        end
        light.brightness = 2.7 * (1 - p * 0.45)
        light.decay = 650
        light.size = 240
        light.dietime = now + 0.12
    end
end

net.Receive("LOD_StagingPortalTransit", function()
    local phase = net.ReadUInt(2)
    local ply = net.ReadEntity()
    local portal = net.ReadEntity()
    local pos = net.ReadVector()
    local duration = math.max(0.12, net.ReadFloat())

    serial = serial + 1
    local ev = {
        serial = serial,
        phase = phase,
        ply = ply,
        portal = portal,
        pos = pos,
        started = CurTime(),
        finishes = CurTime() + duration
    }
    events[#events + 1] = ev

    if phase == 0 then
        spawnSuction(ev)
        if ply == LocalPlayer() then
            localTransit = ev
            LocalPlayer():ScreenFade(SCREENFADE.IN, Color(46, 116, 255, 58), 0.16, 0.02)
        end
    else
        spawnArrivalBurst(ev)
        if ply == LocalPlayer() then
            localArrival = ev
            LocalPlayer():ScreenFade(SCREENFADE.IN, Color(255, 218, 104, 92), 0.13, 0.01)
        end
    end
end)

hook.Add("Think", "LOD_StagingPortalTransitLifetime", function()
    local now = CurTime()
    for i = #events, 1, -1 do
        if now >= events[i].finishes then table.remove(events, i) end
    end
    if localTransit and now >= localTransit.finishes then localTransit = nil end
    if localArrival and now >= localArrival.finishes then localArrival = nil end
end)

hook.Add("PostDrawTranslucentRenderables", "LOD_StagingPortalTransitWorldFX", function(depth, sky)
    if depth or sky then return end
    for i = 1, #events do drawTransitEvent(events[i]) end
end)

hook.Add("HUDPaint", "LOD_StagingPortalTransitScreenFX", function()
    local now = CurTime()
    if localTransit and now < localTransit.finishes then
        local duration = math.max(0.01, localTransit.finishes - localTransit.started)
        local p = math.Clamp((now - localTransit.started) / duration, 0, 1)
        local envelope = math.sin(p * math.pi)
        local alpha = math.floor(38 * envelope)
        surface.SetDrawColor(50, 126, 255, alpha)
        surface.DrawRect(0, 0, ScrW(), ScrH())

        local inset = math.floor(28 + 44 * (1 - envelope))
        surface.SetDrawColor(255, 211, 82, math.floor(150 * envelope))
        surface.DrawOutlinedRect(inset, inset, ScrW() - inset * 2, ScrH() - inset * 2, 4)
    end

    if localArrival and now < localArrival.finishes then
        local duration = math.max(0.01, localArrival.finishes - localArrival.started)
        local p = math.Clamp((now - localArrival.started) / duration, 0, 1)
        local alpha = math.floor(58 * (1 - p))
        surface.SetDrawColor(255, 219, 108, alpha)
        surface.DrawRect(0, 0, ScrW(), ScrH())
    end
end)
