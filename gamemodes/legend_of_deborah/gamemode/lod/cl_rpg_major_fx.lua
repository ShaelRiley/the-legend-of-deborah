if SERVER then return end

LOD = LOD or {}
LOD.RPGMajorFX = LOD.RPGMajorFX or {}

local FX = LOD.RPGMajorFX
local NET_NAME = "LOD_RPGMajorFX"
local ACK_NAME = "LOD_RPGMajorFXAck"
local FX_FEEDBACK = 1
local FX_LEVEL_UP = 2
local FX_FEAT_CONFIRM = 3
local FEEDBACK_FX_SECONDS = 0.52
local LEVEL_UP_FX_SECONDS = 1.80

FX.ClientVersion = 3
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

-- Feedback deliberately uses the same typography scale as DIE EXPLODES rather
-- than the much larger level-up celebration.
surface.CreateFont("LOD_RPGFeedbackFXPrimary", {
    font = "DejaVu Sans",
    size = 28,
    weight = 900,
    antialias = true
})

surface.CreateFont("LOD_RPGFeedbackFXSecondary", {
    font = "DejaVu Sans",
    size = 15,
    weight = 800,
    antialias = true
})

local function playFeedbackSound()
    surface.PlaySound("ambient/energy/zap1.wav")
    timer.Simple(0.035, function()
        surface.PlaySound("buttons/button15.wav")
    end)
end

local function playLevelSound()
    surface.PlaySound("buttons/button15.wav")
    timer.Simple(0.055, function()
        surface.PlaySound("items/suitchargeok1.wav")
    end)
end

local function playFeatSound()
    if file.Exists("sound/ambient/office/keyboard1_clicks.wav", "GAME") then
        surface.PlaySound("ambient/office/keyboard1_clicks.wav")
    else
        surface.PlaySound("buttons/button14.wav")
    end
end

function FX:Trigger(kind, primary, secondary, serial)
    kind = math.floor(tonumber(kind) or 0)
    if kind == FX_FEAT_CONFIRM then
        playFeatSound()
        return
    end

    self.active = {
        kind = kind,
        primary = tostring(primary or ""),
        secondary = tostring(secondary or ""),
        serial = math.floor(tonumber(serial) or 0),
        created = CurTime()
    }

    if kind == FX_FEEDBACK then
        playFeedbackSound()
    else
        playLevelSound()
    end
end

net.Receive(NET_NAME, function()
    local serial = net.ReadUInt(16)
    local kind = net.ReadUInt(3)
    local primary = net.ReadString()
    local secondary = net.ReadString()

    FX:Trigger(kind, primary, secondary, serial)

    net.Start(ACK_NAME)
    net.WriteUInt(serial, 16)
    net.WriteUInt(kind, 3)
    net.SendToServer()
end)

local function alphaEnvelope(age, duration)
    local fadeIn = math.Clamp(age / 0.08, 0, 1)
    local fadeOut = math.Clamp((duration - age) / 0.42, 0, 1)
    return math.min(fadeIn, fadeOut)
end

-- Feedback is intentionally a cyan recolor of DIE EXPLODES: same 0.52-second
-- lifetime, center point, radius, two rings, twelve radial streaks, and text scale.
-- It does not tint or darken the rest of the screen.
local function drawFeedbackBurst(fx, now)
    local age = now - (fx.created or 0)
    if age >= FEEDBACK_FX_SECONDS then
        FX.active = nil
        return
    end

    local fraction = math.Clamp(age / FEEDBACK_FX_SECONDS, 0, 1)
    local fade = 1 - fraction
    local alpha = math.floor(255 * fade)
    local cx = ScrW() * 0.5
    local cy = ScrH() * 0.43
    local radius = 22 + 62 * fraction
    local base = Color(75, 220, 255, alpha)
    local bright = Color(210, 250, 255, alpha)
    local outline = Color(5, 12, 18, math.floor(alpha * 0.92))

    surface.SetDrawColor(base)
    surface.DrawCircle(cx, cy, radius, base.r, base.g, base.b, alpha)
    surface.DrawCircle(cx, cy, radius * 0.72, base.r, base.g, base.b, math.floor(alpha * 0.75))

    for i = 0, 11 do
        local angle = (i / 12) * math.pi * 2 + fraction * 0.35
        local inner = radius * 0.78
        local outer = radius * 1.18
        surface.DrawLine(
            cx + math.cos(angle) * inner,
            cy + math.sin(angle) * inner,
            cx + math.cos(angle) * outer,
            cy + math.sin(angle) * outer)
    end

    draw.SimpleTextOutlined(
        fx.primary ~= "" and fx.primary or "FEEDBACK!",
        "LOD_RPGFeedbackFXPrimary",
        cx,
        cy - 6,
        base,
        TEXT_ALIGN_CENTER,
        TEXT_ALIGN_CENTER,
        2,
        outline)

    if fx.secondary and fx.secondary ~= "" then
        draw.SimpleTextOutlined(
            fx.secondary,
            "LOD_RPGFeedbackFXSecondary",
            cx,
            cy + 22,
            bright,
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER,
            1,
            outline)
    end
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

    surface.SetDrawColor(base.r, base.g, base.b, math.floor(36 * envelope))
    surface.DrawRect(0, 0, w, h)

    local bandWidth = math.min(w * 0.72, 820)
    local bandHeight = 132
    surface.SetDrawColor(dark.r, dark.g, dark.b, math.floor(154 * envelope))
    surface.DrawRect(cx - bandWidth * 0.5, cy - bandHeight * 0.5, bandWidth, bandHeight)

    surface.SetDrawColor(base)
    surface.DrawCircle(cx, cy, radius, base.r, base.g, base.b, alpha)
    surface.DrawCircle(cx, cy, radius * 0.72, bright.r, bright.g, bright.b, math.floor(alpha * 0.82))
    surface.DrawCircle(cx, cy, radius * 0.46, base.r, base.g, base.b, math.floor(alpha * 0.62))

    for i = 0, 19 do
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

-- PostDrawHUD intentionally renders after ordinary HUDPaint hooks. Major level-up
-- presentation and compact Feedback presentation therefore remain visible above
-- normal HUD layers without competing with the combat-roll feed's own draw order.
hook.Add("PostDrawHUD", "LOD_RPGMajorFX", function()
    if not FX.active then return end
    if FX.active.kind == FX_FEEDBACK then
        drawFeedbackBurst(FX.active, CurTime())
    else
        drawLevelUpBurst(FX.active, CurTime())
    end
end)

-- Local presentation-only diagnostic. It does not alter progression or combat.
-- Usage: lod_rpg_major_fx_test level   OR   lod_rpg_major_fx_test feedback
concommand.Add("lod_rpg_major_fx_test", function(_, _, args)
    local mode = string.lower(tostring(args and args[1] or "level"))
    if mode == "feedback" then
        FX:Trigger(FX_FEEDBACK, "FEEDBACK!", "2d4+1 → 7 DAMAGE", 0)
    else
        FX:Trigger(FX_LEVEL_UP, "LEVEL UP!", "PRESS P TO SEE", 0)
    end
end)
