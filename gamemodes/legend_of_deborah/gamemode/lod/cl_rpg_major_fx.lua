if SERVER then return end

LOD = LOD or {}
LOD.RPGMajorFX = LOD.RPGMajorFX or {}

local FX = LOD.RPGMajorFX
local NET_NAME = "LOD_RPGMajorFX"
local ACK_NAME = "LOD_RPGMajorFXAck"
local FX_FEEDBACK = 1
local FX_LEVEL_UP = 2
local FX_FEAT_CONFIRM = 3
local LEVEL_UP_FX_SECONDS = 1.80

FX.ClientVersion = 4
FX.active = FX.active or nil

surface.CreateFont("LOD_RPGMajorFXPrimary", {
    font = "DejaVu Sans",
    size = 58,
    weight = 1000,
    antialias = true
})

surface.CreateFont("LOD_RPGMajorFXSecondary", {
    font = "DejaVu Sans",
    size = 22,
    weight = 900,
    antialias = true
})

local function playLevelSound()
    if LOD.AdventurePresentation then LOD.AdventurePresentation:Play(5, false) end
end
local function playFeatSound()
    if LOD.AdventurePresentation then LOD.AdventurePresentation:Play(7, false) end
end

function FX:Trigger(kind, primary, secondary, serial, origin, target)
    kind = math.floor(tonumber(kind) or 0)
    -- Wizard reactions have their own brief layer; a level-up cannot mute them.
    if kind == FX_FEEDBACK or kind == 4 then
        return LOD.WizardFX and LOD.WizardFX:Trigger(kind, primary, secondary, serial, origin, target) or false
    end
    if kind == FX_FEAT_CONFIRM then
        playFeatSound()
        return true
    end

    self.active = {
        kind = kind,
        primary = tostring(primary or ""),
        secondary = tostring(secondary or ""),
        serial = math.floor(tonumber(serial) or 0),
        created = CurTime()
    }

    playLevelSound()
    return true
end

net.Receive(NET_NAME, function()
    local serial = net.ReadUInt(16)
    local kind = net.ReadUInt(3)
    local primary = net.ReadString()
    local secondary = net.ReadString()

    local origin, target
    if kind == FX_FEEDBACK or kind == 4 then origin, target = net.ReadVector(), net.ReadVector() end
    local triggered = FX:Trigger(kind, primary, secondary, serial, origin, target)

    net.Start(ACK_NAME)
    net.WriteUInt(serial, 16)
    net.WriteUInt(kind, 3)
    net.WriteBool(triggered == true)
    net.SendToServer()
end)

local function alphaEnvelope(age, duration)
    local fadeIn = math.Clamp(age / 0.08, 0, 1)
    local fadeOut = math.Clamp((duration - age) / 0.42, 0, 1)
    return math.min(fadeIn, fadeOut)
end

-- Level-up remains intentionally larger and longer than ordinary combat feedback.
-- This is the presentation that passed the current Wizard playtest unchanged.
local function drawLevelUpBurst(fx, now)
    local age = now - (fx.created or 0)
    if age >= LEVEL_UP_FX_SECONDS then
        FX.active = nil
        return
    end

    local fraction = math.Clamp(age / LEVEL_UP_FX_SECONDS, 0, 1)
    local envelope = alphaEnvelope(age, LEVEL_UP_FX_SECONDS)
    local alpha = math.floor(255 * envelope)
    local w, h = ScrW(), ScrH()
    local cx, cy = w * 0.5, h * 0.39
    local expansion = 1 - math.pow(1 - fraction, 3)
    local radius = 46 + 150 * expansion
    local base = Color(255, 205, 70, alpha)
    local bright = Color(255, 248, 205, alpha)
    local dark = Color(32, 20, 3, math.floor(alpha * 0.94))

    local reduced = LOD.AdventurePresentation and LOD.AdventurePresentation:Reduced()
    if reduced then radius = 62 end

    surface.SetDrawColor(base)
    surface.DrawCircle(cx, cy, radius, base.r, base.g, base.b, alpha)
    surface.DrawCircle(cx, cy, radius * 0.72, bright.r, bright.g, bright.b, math.floor(alpha * 0.82))
    surface.DrawCircle(cx, cy, radius * 0.46, base.r, base.g, base.b, math.floor(alpha * 0.62))

    for i = 0, (reduced and 5 or 19) do
        local angle = (i / 20) * math.pi * 2 + fraction * 0.55
        local inner = radius * 0.68
        local outer = radius * (1.08 + ((i % 2) * 0.22))
        surface.DrawLine(
            cx + math.cos(angle) * inner,
            cy + math.sin(angle) * inner,
            cx + math.cos(angle) * outer,
            cy + math.sin(angle) * outer)
    end

    draw.SimpleTextOutlined(
        fx.primary ~= "" and fx.primary or "LEVEL UP!",
        "LOD_RPGMajorFXPrimary",
        cx,
        cy - 15,
        bright,
        TEXT_ALIGN_CENTER,
        TEXT_ALIGN_CENTER,
        4,
        dark)

    if fx.secondary and fx.secondary ~= "" then
        draw.SimpleTextOutlined(
            fx.secondary,
            "LOD_RPGMajorFXSecondary",
            cx,
            cy + 34,
            bright,
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER,
            2,
            dark)
    end
end

-- The rare level-up layer is independent of the Wizard reaction layer.
hook.Add("PostDrawHUD", "LOD_RPGMajorFX", function()
    if not FX.active then return end
    drawLevelUpBurst(FX.active, CurTime())
end)

-- Local presentation-only diagnostic. It does not alter progression or combat.
-- Usage: lod_rpg_major_fx_test level / feedback / diversion
concommand.Add("lod_rpg_major_fx_test", function(_, _, args)
    local mode = string.lower(tostring(args and args[1] or "level"))
    if mode == "feedback" then
        FX:Trigger(FX_FEEDBACK, "FEEDBACK!", "(7) DAMAGE — 2d4+1", 0)
    elseif mode == "diversion" then
        FX:Trigger(4, "ARCANE DIVERSION", "4 HP SAVED / -4 MAGIC", 0)
    else
        FX:Trigger(FX_LEVEL_UP, "LEVEL UP!", "PRESS P TO SEE", 0)
    end
end)
