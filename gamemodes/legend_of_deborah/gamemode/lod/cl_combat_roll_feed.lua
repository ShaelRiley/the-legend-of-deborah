LOD = LOD or {}
LOD.CombatRollFeed = LOD.CombatRollFeed or {entries = {}}

local Feed = LOD.CombatRollFeed
Feed.entries = Feed.entries or {}
local MAX_ENTRIES = 8
local HOLD_SECONDS = 5.0
local FADE_SECONDS = 1.0
local EXPLOSION_FX_SECONDS = 0.52

surface.CreateFont("LOD_CombatRoll", {
    font = "DejaVu Sans",
    size = 15,
    weight = 700,
    antialias = true
})

surface.CreateFont("LOD_DiceExplosion", {
    font = "DejaVu Sans",
    size = 28,
    weight = 900,
    antialias = true
})

surface.CreateFont("LOD_DiceExplosionSmall", {
    font = "DejaVu Sans",
    size = 15,
    weight = 800,
    antialias = true
})

local categoryColors = {
    [0] = Color(248, 213, 105), -- player outgoing
    [1] = Color(238, 112, 92),  -- hostile incoming
    [2] = Color(110, 190, 235), -- health/durability rolls
    [3] = Color(205, 205, 210)
}

net.Receive("LOD_CombatRoll", function()
    local entry = {
        category = net.ReadUInt(2),
        text = net.ReadString(),
        created = CurTime()
    }
    Feed.entries[#Feed.entries + 1] = entry
    while #Feed.entries > MAX_ENTRIES do table.remove(Feed.entries, 1) end
end)

net.Receive("LOD_DiceExplosionFX", function()
    local kind = net.ReadUInt(2)
    local count = math.max(1, net.ReadUInt(6))
    local depth = math.max(1, net.ReadUInt(4))
    local now = CurTime()

    -- Pierce bonuses can explode almost simultaneously. Fold events arriving in
    -- one brief beat into the current celebratory flash rather than stacking a
    -- pile of HUD elements or sounds.
    if Feed.diceExplosion and now - (Feed.diceExplosion.created or 0) <= 0.12 then
        Feed.diceExplosion.count = (Feed.diceExplosion.count or 1) + count
        Feed.diceExplosion.depth = math.max(Feed.diceExplosion.depth or 1, depth)
        Feed.diceExplosion.kind = kind ~= 0 and kind or Feed.diceExplosion.kind
        Feed.diceExplosion.created = now
    else
        Feed.diceExplosion = {
            kind = kind,
            count = count,
            depth = depth,
            created = now
        }
    end

    -- A crisp positive UI chirp followed by the familiar HEV confirmation tone
    -- makes an exploding die audible even in a busy firefight. The cue is local
    -- to the player whose die exploded.
    if now >= (Feed.nextExplosionSound or 0) then
        Feed.nextExplosionSound = now + 0.10
        surface.PlaySound("buttons/button15.wav")
        timer.Simple(0.045, function()
            surface.PlaySound("items/suitchargeok1.wav")
        end)
    end
end)

local function drawDiceExplosion(now)
    local fx = Feed.diceExplosion
    if not fx then return end

    local age = now - (fx.created or 0)
    if age >= EXPLOSION_FX_SECONDS then
        Feed.diceExplosion = nil
        return
    end

    local fraction = math.Clamp(age / EXPLOSION_FX_SECONDS, 0, 1)
    local fade = 1 - fraction
    local alpha = math.floor(255 * fade)
    local cx = ScrW() * 0.5
    local cy = ScrH() * 0.43
    local radius = 22 + 62 * fraction

    local base
    if fx.kind == 1 then
        base = Color(255, 185, 70, alpha) -- Magnum: hot gold
    elseif fx.kind == 2 then
        base = Color(255, 225, 135, alpha) -- Shotgun: warm flash
    else
        base = Color(235, 220, 160, alpha)
    end

    surface.SetDrawColor(base)
    surface.DrawCircle(cx, cy, radius, base.r, base.g, base.b, alpha)
    surface.DrawCircle(cx, cy, radius * 0.72, base.r, base.g, base.b, math.floor(alpha * 0.75))

    -- Twelve cheap radial streaks read like a die/critical burst without particles,
    -- client entities, or Think work.
    for i = 0, 11 do
        local angle = (i / 12) * math.pi * 2 + fraction * 0.35
        local inner = radius * 0.78
        local outer = radius * 1.18
        local x1 = cx + math.cos(angle) * inner
        local y1 = cy + math.sin(angle) * inner
        local x2 = cx + math.cos(angle) * outer
        local y2 = cy + math.sin(angle) * outer
        surface.DrawLine(x1, y1, x2, y2)
    end

    local label = (fx.depth or 1) > 1 and "PIERCE DIE EXPLODES!" or "DIE EXPLODES!"
    if (fx.count or 1) > 1 then label = label .. "  x" .. tostring(fx.count) end
    draw.SimpleTextOutlined(label, "LOD_DiceExplosion", cx, cy - 6, base,
        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(20, 12, 5, math.floor(alpha * 0.92)))

    if (fx.depth or 1) > 1 then
        draw.SimpleTextOutlined("MAGNUM PIERCE +1d12", "LOD_DiceExplosionSmall", cx, cy + 22,
            Color(255, 235, 185, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
            1, Color(20, 12, 5, math.floor(alpha * 0.90)))
    end
end

hook.Add("HUDPaint", "LOD_CombatRollFeed", function()
    local now = CurTime()
    while Feed.entries[1] and now - Feed.entries[1].created > HOLD_SECONDS + FADE_SECONDS do
        table.remove(Feed.entries, 1)
    end

    if #Feed.entries > 0 then
        -- Occupy the intentional right-side interstitial band: newest entry sits
        -- immediately above the ammunition HUD, while older rolls stack upward but
        -- remain below the minimap even at Steam Deck's 1280x800-class viewport.
        local right = ScrW() - 24
        local bottom = ScrH() - 102
        local rowHeight = 18

        for index = #Feed.entries, 1, -1 do
            local entry = Feed.entries[index]
            local age = now - entry.created
            local alpha = 255
            if age > HOLD_SECONDS then
                alpha = math.Clamp(255 * (1 - (age - HOLD_SECONDS) / FADE_SECONDS), 0, 255)
            end
            local color = categoryColors[entry.category] or categoryColors[3]
            color = Color(color.r, color.g, color.b, alpha)
            local y = bottom - (#Feed.entries - index) * rowHeight
            draw.SimpleTextOutlined(entry.text, "LOD_CombatRoll", right, y, color,
                TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, 1, Color(5, 7, 8, alpha * 0.90))
        end
    end

    drawDiceExplosion(now)
end)
