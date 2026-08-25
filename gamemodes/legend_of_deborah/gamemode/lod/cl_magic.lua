LOD = LOD or {}
LOD.MagicFX = LOD.MagicFX or {waves = {}}

local FX = LOD.MagicFX
local beamMaterial = Material("sprites/light_glow02_add")
local attack2Held = false
local localCastUntil = 0

local function activePlayer()
    local ply = LocalPlayer()
    return IsValid(ply) and ply:Alive() and ply:GetNW2Bool("LOD_PlayedIdentity", false) and ply or nil
end

hook.Add("CreateMove", "LOD_MagicPredictedInput", function(cmd)
    local ply = activePlayer()
    if not ply then
        attack2Held = false
        return
    end

    local down = cmd:KeyDown(IN_ATTACK2)
    if down and not attack2Held then
        net.Start("LOD_MagicCastRequest")
        net.SendToServer()
    end
    attack2Held = down
    cmd:RemoveKey(IN_ATTACK2)
end)

net.Receive("LOD_MagicShoutFX", function()
    local caster = net.ReadEntity()
    local origin = net.ReadVector()
    local direction = net.ReadVector()
    if direction == vector_origin then return end
    direction = direction:GetNormalized()

    FX.waves[#FX.waves + 1] = {
        caster = caster,
        origin = origin,
        direction = direction,
        started = CurTime(),
        lifetime = 0.55
    }

    if caster == LocalPlayer() then
        localCastUntil = CurTime() + 0.28
        -- Do not force ACT_VM_PRIMARYATTACK on the active weapon here. Stock HL2
        -- SWEPs can retain/replay that sequence after a Magic cast, producing a
        -- phantom firing animation with no shot. The server-authored player
        -- gesture and force-wave FX carry the cast presentation instead.
        surface.PlaySound("ambient/levels/citadel/weapon_disintegrate2.wav")
    end
end)

-- Briefly clear the held first-person viewmodel during the cast. We deliberately
-- do not drive a firearm animation sequence; RMB belongs to Magic, not alt-fire.
hook.Add("PreDrawViewModel", "LOD_MagicHideWeaponDuringCast", function()
    if CurTime() < localCastUntil then return true end
end)

local function ringBasis(direction)
    local ang = direction:Angle()
    return ang:Right(), ang:Up()
end

local function drawRing(origin, direction, distance, alpha, width)
    if distance <= 0 then return end
    local right, up = ringBasis(direction)
    local center = origin + direction * distance
    local radius = math.max(18, distance * math.tan(math.rad(30)))
    local segments = 24
    local previous

    render.SetMaterial(beamMaterial)
    for i = 0, segments do
        local theta = (i / segments) * math.pi * 2
        local point = center + right * math.cos(theta) * radius + up * math.sin(theta) * radius
        if previous then
            render.DrawBeam(previous, point, width, 0, 1, Color(155, 225, 255, alpha))
        end
        previous = point
    end

    render.DrawSprite(center, 22 + distance * 0.018, 22 + distance * 0.018,
        Color(190, 235, 255, math.floor(alpha * 0.6)))
end

hook.Add("PostDrawTranslucentRenderables", "LOD_MagicForceShoutWaves", function()
    local now = CurTime()
    for i = #FX.waves, 1, -1 do
        local wave = FX.waves[i]
        local age = now - wave.started
        local progress = age / wave.lifetime
        if progress >= 1 then
            table.remove(FX.waves, i)
        else
            local fade = math.Clamp(1 - progress, 0, 1)
            local alpha = math.floor(210 * fade)
            local distance = 80 + progress * 980
            drawRing(wave.origin, wave.direction, distance, alpha, 10 * fade + 2)

            local trailing = math.Clamp(progress - 0.14, 0, 1)
            if trailing > 0 then
                drawRing(wave.origin, wave.direction, 50 + trailing * 900,
                    math.floor(120 * fade), 6 * fade + 1)
            end
        end
    end
end)
