LOD = LOD or {}
LOD.CombatRollFeed = LOD.CombatRollFeed or {entries = {}}

local Feed = LOD.CombatRollFeed
if Feed.LODSemanticRendererInstalled then return end

-- Replace only the old single-color paint hook. Its net receivers and explosion
-- sound aggregation remain the event authority populated by cl_combat_roll_feed.
hook.Remove("HUDPaint", "LOD_CombatRollFeed")

local HOLD_SECONDS = 5.0
local FADE_SECONDS = 1.0
local EXPLOSION_FX_SECONDS = 0.52
local FONT = "LOD_CombatRoll"
local ROW_HEIGHT = 18
local ENTRY_GAP = 5
local BACKING_PAD_X = 6
local BACKING_PAD_Y = 2

local COLORS = {
    identity = Color(158, 232, 255), -- GDD: light cyan
    dice = Color(202, 166, 255),     -- GDD: violet
    total = Color(248, 213, 105),    -- GDD: gold
    recipient = Color(255, 143, 122),-- GDD: coral
    source = Color(157, 235, 196),   -- GDD: mint
    prose = Color(214, 218, 224)     -- GDD: light gray
}

local categoryColors = {
    [0] = Color(248, 213, 105),
    [1] = Color(238, 112, 92),
    [2] = Color(110, 190, 235),
    [3] = Color(205, 205, 210)
}

local function semanticDamageSegments(text)
    text = tostring(text or "")
    local dealtStart, dealtEnd = string.find(text, " dealt ", 1, true)
    if not dealtStart then return nil end
    local damageStart, damageEnd = string.find(text, " damage to ", dealtEnd + 1, true)
    if not damageStart then return nil end
    local viaStart, viaEnd = string.find(text, ", via ", damageEnd + 1, true)
    if not viaStart then return nil end

    local identity = string.sub(text, 1, dealtStart - 1)
    local middle = string.sub(text, dealtEnd + 1, damageStart - 1)
    local recipient = string.sub(text, damageEnd + 1, viaStart - 1)
    local source = string.sub(text, viaEnd + 1)

    local open = string.find(middle, "(", 1, true)
    local close = open and string.find(middle, ")", open + 1, true) or nil
    if not open or not close then return nil end

    local formula = string.Trim(string.sub(middle, 1, open - 1))
    local total = string.sub(middle, open + 1, close - 1)
    local detail = string.sub(middle, close + 1)
    if identity == "" or formula == "" or total == "" or recipient == "" or source == "" then return nil end

    return {
        {text = identity, role = "identity"},
        {text = " dealt ", role = "prose"},
        {text = formula, role = "dice"},
        {text = " (", role = "prose"},
        {text = total, role = "total"},
        {text = ")", role = "prose"},
        {text = detail, role = "prose"},
        {text = " damage to ", role = "prose"},
        {text = recipient, role = "recipient"},
        {text = ", via ", role = "prose"},
        {text = source, role = "source"}
    }
end

local function textWidth(text)
    surface.SetFont(FONT)
    local width = surface.GetTextSize(text or "")
    return width
end

local function cloneSegment(segment, text)
    return {text = text, role = segment.role, customColor = segment.customColor}
end

local function appendSegment(lines, widths, segment, maxWidth)
    local text = segment.text or ""
    if text == "" then return end
    local lineIndex = #lines
    local width = textWidth(text)

    if widths[lineIndex] > 0 and widths[lineIndex] + width > maxWidth then
        text = string.gsub(text, "^%s+", "")
        if text == "" then return end
        segment = cloneSegment(segment, text)
        width = textWidth(text)
        lines[#lines + 1] = {}
        widths[#widths + 1] = 0
        lineIndex = #lines
    end

    -- Individual semantic fields are normally much narrower than the feed. For a
    -- pathological long identity with spaces, split at word boundaries. A single
    -- unbroken token is preserved rather than clipped or recursively reprocessed.
    if width > maxWidth and string.find(text, " ", 1, true) then
        local current = ""
        for word, spaces in string.gmatch(text .. " ", "(%S+)(%s+)") do
            local token = word .. (spaces or "")
            local candidate = current .. token
            if current ~= "" and textWidth(candidate) > maxWidth then
                local piece = string.gsub(current, "%s+$", "")
                if piece ~= "" then appendSegment(lines, widths, cloneSegment(segment, piece), maxWidth) end
                current = token
            else
                current = candidate
            end
        end
        current = string.gsub(current, "%s+$", "")
        if current ~= "" then
            if textWidth(current) > maxWidth then
                local index = #lines
                lines[index][#lines[index] + 1] = cloneSegment(segment, current)
                widths[index] = widths[index] + textWidth(current)
            else
                appendSegment(lines, widths, cloneSegment(segment, current), maxWidth)
            end
        end
        return
    end

    lines[lineIndex][#lines[lineIndex] + 1] = segment
    widths[lineIndex] = widths[lineIndex] + width
end

local function layoutSegments(entry, maxWidth)
    local segments = semanticDamageSegments(entry.text)
    if not segments then
        local color = categoryColors[entry.category] or categoryColors[3]
        segments = {{text = tostring(entry.text or ""), customColor = color}}
    end

    local lines = {{}}
    local widths = {0}
    for _, segment in ipairs(segments) do appendSegment(lines, widths, segment, maxWidth) end
    return lines, widths
end

local function withAlpha(base, alpha)
    return Color(base.r, base.g, base.b, alpha)
end

local function entryHeight(lines)
    return math.max(1, #lines) * ROW_HEIGHT
end

local function drawEntry(entry, right, bottomY, maxWidth, alpha, lines, widths)
    lines, widths = lines or layoutSegments(entry, maxWidth)
    local height = entryHeight(lines)
    local firstY = bottomY - (#lines - 1) * ROW_HEIGHT
    local outline = Color(5, 7, 8, math.floor(alpha * 0.92))
    local widest = 0
    for _, width in ipairs(widths) do widest = math.max(widest, width or 0) end

    -- A quiet local backing keeps semantic colors readable against maze textures
    -- without turning the feed into a large opaque HUD panel.
    draw.RoundedBox(3,
        right - widest - BACKING_PAD_X,
        bottomY - height - BACKING_PAD_Y + 2,
        widest + BACKING_PAD_X * 2,
        height + BACKING_PAD_Y * 2,
        Color(5, 7, 9, math.floor(alpha * 0.46)))

    for lineIndex, line in ipairs(lines) do
        local x = right - (widths[lineIndex] or 0)
        local y = firstY + (lineIndex - 1) * ROW_HEIGHT
        for _, segment in ipairs(line) do
            local base = segment.customColor or COLORS[segment.role] or COLORS.prose
            local color = withAlpha(base, alpha)
            draw.SimpleTextOutlined(segment.text, FONT, x, y, color,
                TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM, 1, outline)
            x = x + textWidth(segment.text)
        end
    end

    -- firstY is the baseline of the top rendered row. Move one complete row above
    -- it before applying the inter-entry gap; the previous implementation moved
    -- only ENTRY_GAP pixels and therefore painted successive entries on top of one another.
    return firstY - ROW_HEIGHT - ENTRY_GAP
end

local function drawDiceExplosion(now)
    local fx = Feed.diceExplosion
    if not fx then return end
    local age = now - (fx.created or 0)
    if age >= EXPLOSION_FX_SECONDS then Feed.diceExplosion = nil return end

    local fraction = math.Clamp(age / EXPLOSION_FX_SECONDS, 0, 1)
    local alpha = math.floor(255 * (1 - fraction))
    local cx, cy = ScrW() * 0.5, ScrH() * 0.43
    local radius = 22 + 62 * fraction
    local base
    if fx.kind == 1 then
        base = Color(255, 185, 70, alpha)
    elseif fx.kind == 2 then
        base = Color(255, 225, 135, alpha)
    else
        base = Color(235, 220, 160, alpha)
    end

    surface.SetDrawColor(base)
    surface.DrawCircle(cx, cy, radius, base.r, base.g, base.b, alpha)
    surface.DrawCircle(cx, cy, radius * 0.72, base.r, base.g, base.b, math.floor(alpha * 0.75))
    for index = 0, 11 do
        local angle = (index / 12) * math.pi * 2 + fraction * 0.35
        local inner, outer = radius * 0.78, radius * 1.18
        surface.DrawLine(cx + math.cos(angle) * inner, cy + math.sin(angle) * inner,
            cx + math.cos(angle) * outer, cy + math.sin(angle) * outer)
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
        local right = ScrW() - 24
        local cursorY = ScrH() - 102
        local maxWidth = math.Clamp(ScrW() * 0.55, 420, 720)
        -- Reserve the lower-right combat band. In dense combat, preserve newest
        -- information rather than allowing older wrapped entries to invade the
        -- center/top HUD.
        local topLimit = math.max(150, ScrH() * 0.52)

        for index = #Feed.entries, 1, -1 do
            local entry = Feed.entries[index]
            local lines, widths = layoutSegments(entry, maxWidth)
            local required = entryHeight(lines) + ENTRY_GAP
            if cursorY - required < topLimit then break end

            local age = now - entry.created
            local alpha = 255
            if age > HOLD_SECONDS then
                alpha = math.Clamp(255 * (1 - (age - HOLD_SECONDS) / FADE_SECONDS), 0, 255)
            end
            cursorY = drawEntry(entry, right, cursorY, maxWidth, alpha, lines, widths)
        end
    end

    drawDiceExplosion(now)
end)

concommand.Add("lod_dice_feed_qol_test", function()
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    Feed.entries[#Feed.entries + 1] = {
        category = 0,
        text = "Shael Riley as Jimmy 'The Fly' Mancina dealt 1d12! (27) [rolls 10>11>6] damage to Shambler, via .357 Magnum",
        created = CurTime()
    }
    while #Feed.entries > 8 do table.remove(Feed.entries, 1) end
end)

concommand.Add("lod_dice_feed_qol_burst_test", function()
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    local samples = {
        "Shael Riley as Jimmy 'The Fly' Mancina dealt 1d12! (27) [rolls 10>11>6] damage to Shambler, via .357 Magnum",
        "Runner dealt 2d4 (6) [rolls 2>4] damage to Shael Riley as Jimmy 'The Fly' Mancina, via melee",
        "Shael Riley as Jimmy 'The Fly' Mancina dealt 6d3 (11) [rolls 1>2>2>1>3>2] damage to Soldier, via shotgun",
        "Bio Blaster dealt 1d8 (7) [roll 7] damage to Shael Riley as Jimmy 'The Fly' Mancina, via bio bolt"
    }
    for _, text in ipairs(samples) do
        Feed.entries[#Feed.entries + 1] = {category = 0, text = text, created = CurTime()}
    end
    while #Feed.entries > 8 do table.remove(Feed.entries, 1) end
end)

Feed.LODSemanticRendererInstalled = true
