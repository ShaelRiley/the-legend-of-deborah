LOD = LOD or {}
local Feed = LOD.CombatRollFeed
local UI = LOD.UI
local FONT, ROW_HEIGHT = "LOD_CombatRoll", 22
local HOLD_SECONDS, FADE_SECONDS, EXPLOSION_FX_SECONDS = 9, 1.4, 0.52
Feed.RowHeight = ROW_HEIGHT

local function textWidth(text, font)
    surface.SetFont(font or FONT)
    return surface.GetTextSize(text or "")
end

-- Cache once per entry/width. Break overlong identifiers at UTF-8 code points;
-- never paint outside the bounded paper column or split a continuation away.
function Feed:Layout(entry, maxWidth, hud)
    local font = hud and "ChatFont" or FONT
    if entry.layoutWidth == maxWidth and entry.layoutFont == font and entry.lines then return entry.lines, entry.widths end
    local segments = entry.segments
    if not LOD.DieLogger:ValidSegments(segments, entry.text) then
        segments = LOD.DieLogger:Segments(entry.text, entry.family)
    end
    local lines, widths = {{}}, {0}
    local function append(text, role)
        local i = #lines
        local width = textWidth(text, font)
        if widths[i] + width > maxWidth and widths[i] > 0 then
            lines[#lines+1], widths[#widths+1] = {}, 0; i = #lines
        end
        local line = lines[i]
        local last = line[#line]
        if last and last.role == role then last.text = last.text .. text
        else line[#line+1] = {text = text, role = role} end
        widths[i] = widths[i] + width
    end
    for _, span in ipairs(segments) do
        for token in span.text:gmatch("%s*%S+%s*") do
            if textWidth(token, font) <= maxWidth then append(token, span.role)
            else
                for char in token:gmatch("[%z\1-\127\194-\244][\128-\191]*") do append(char, span.role) end
            end
        end
        -- A grammar span can consist entirely of spaces.
        if span.text:match("^%s+$") then append(span.text, span.role) end
    end
    entry.layoutFont = font
    entry.layoutWidth, entry.lines, entry.widths = maxWidth, lines, widths
    return lines, widths
end

function Feed:DrawLines(lines, x, y, alpha, first, last, hud)
    local font = hud and "ChatFont" or FONT
    local palette = hud and UI.HUDRoles or UI.Roles
    first, last = first or 1, last or #lines
    for i = first, last do
        local cursor = x
        for _, span in ipairs(lines[i]) do
            local base = palette[span.role] or palette.prose
            local color = Color(base.r,base.g,base.b,alpha or 255)
            if hud then UI:HUDText(span.text,font,cursor,y+(i-first)*ROW_HEIGHT,color)
            else draw.SimpleText(span.text,font,cursor,y+(i-first)*ROW_HEIGHT,color) end
            cursor = cursor + textWidth(span.text, font)
        end
    end
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
    local right, bottom = ScrW()-22, ScrH()-math.max(110, ScrH()*0.14)
    local width = math.min(600, ScrW()*0.44)
    local top = bottom - ROW_HEIGHT*6
    for index = #Feed.entries,1,-1 do
        local entry = Feed.entries[index]
        local lines = Feed:Layout(entry,width,true)
        local available = math.floor((bottom-top)/ROW_HEIGHT)
        if available < 1 then break end
        local shown = math.min(#lines,available)
        local h = shown*ROW_HEIGHT
        local age = now-entry.created
        local alpha = age <= HOLD_SECONDS and 255 or math.Clamp(255*(1-(age-HOLD_SECONDS)/FADE_SECONDS),0,255)
        Feed:DrawLines(lines,right-width,bottom-h,alpha,1,shown,true)
        if shown < #lines then
            UI:HUDText("... FULL RECORD: DIE-LOGGER / L", "Default",right,bottom+2,
                UI.HUDColor,TEXT_ALIGN_RIGHT)
        end
        if Feed.AckFeedback then Feed:AckFeedback(entry,1,false) end
        bottom = bottom-h-4
        if shown < #lines then break end
    end
    drawDiceExplosion(now)
end)

concommand.Add("lod_dice_feed_qol_test", function()
    local cv = GetConVar("lod_developer_mode")
    if not cv or not cv:GetBool() then return end
    local text = "(27) DAMAGE — actor → target, via Magic; 1d10! [rolls 10 > 10 > 7 = 27 rolled]"
    local entry = {category=0,text=text,created=CurTime(),family="routine"}
    Feed.entries[#Feed.entries+1] = entry
    if Feed.RetainFeedback then Feed:RetainFeedback(entry) end
    while #Feed.entries > 10 do table.remove(Feed.entries,1) end
end)
