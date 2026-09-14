LOD = LOD or {}
local Feed = LOD.CombatRollFeed
local UI = LOD.UI
local FONT, ROW_HEIGHT = "LOD_CombatRoll", 22
local HOLD_SECONDS, FADE_SECONDS, EXPLOSION_FX_SECONDS = 9, 1.4, 0.52
Feed.RowHeight = ROW_HEIGHT

local function textWidth(text)
    surface.SetFont(FONT)
    return surface.GetTextSize(text or "")
end

-- Cache once per entry/width. Break overlong identifiers at UTF-8 code points;
-- never paint outside the bounded paper column or split a continuation away.
function Feed:Layout(entry, maxWidth)
    if entry.layoutWidth == maxWidth and entry.lines then return entry.lines, entry.widths end
    local segments = entry.segments
    if not LOD.DieLogger:ValidSegments(segments, entry.text) then
        segments = LOD.DieLogger:Segments(entry.text, entry.family)
    end
    local lines, widths = {{}}, {0}
    local function append(text, role)
        local i = #lines
        local width = textWidth(text)
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
            if textWidth(token) <= maxWidth then append(token, span.role)
            else
                for char in token:gmatch("[%z\1-\127\194-\244][\128-\191]*") do append(char, span.role) end
            end
        end
        -- A grammar span can consist entirely of spaces.
        if span.text:match("^%s+$") then append(span.text, span.role) end
    end
    entry.layoutWidth, entry.lines, entry.widths = maxWidth, lines, widths
    return lines, widths
end

function Feed:DrawLines(lines, x, y, alpha, first, last)
    first, last = first or 1, last or #lines
    for i = first, last do
        local cursor = x
        for _, span in ipairs(lines[i]) do
            local base = UI.Roles[span.role] or UI.Colors.ink
            draw.SimpleText(span.text, FONT, cursor, y + (i-first)*ROW_HEIGHT,
                Color(base.r,base.g,base.b,alpha or 255))
            cursor = cursor + textWidth(span.text)
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
    local right, bottom = ScrW()-24, ScrH()-102
    local width = math.min(600, math.max(240, ScrW()*0.43))
    local top = math.max(150, ScrH()*0.52)
    for index = #Feed.entries,1,-1 do
        local entry = Feed.entries[index]
        local lines = Feed:Layout(entry,width-24)
        local available = math.floor((bottom-top-18)/ROW_HEIGHT)
        if available < 1 then break end
        local shown = math.min(#lines,available)
        local h = shown*ROW_HEIGHT+16
        local age = now-entry.created
        local alpha = age <= HOLD_SECONDS and 255 or math.Clamp(255*(1-(age-HOLD_SECONDS)/FADE_SECONDS),0,255)
        UI:Paper(right-width,bottom-h,width,h,UI.Roles[entry.family] or UI.Colors.blue,alpha,3)
        Feed:DrawLines(lines,right-width+12,bottom-h+8,alpha,1,shown)
        if shown < #lines then
            -- The complete record remains retained. Explicitly disclose HUD overflow.
            draw.SimpleText("... FULL RECORD: DIE-LOGGER / L", "LOD_SheetKey",right,bottom+1,
                UI.Colors.paper,TEXT_ALIGN_RIGHT)
        end
        if Feed.AckFeedback then Feed:AckFeedback(entry,1,false) end
        bottom = bottom-h-8
        if shown < #lines then break end
    end
    drawDiceExplosion(now)
end)

concommand.Add("lod_dice_feed_qol_test", function()
    local cv = GetConVar("lod_developer_mode")
    if not cv or not cv:GetBool() then return end
    local text = "DIE-LOGGER layout sample: actor dealt 1d10! (27) [rolls 10 > 10 > 7] damage to target, via Magic"
    local entry = {category=0,text=text,created=CurTime(),family="routine"}
    Feed.entries[#Feed.entries+1] = entry
    if Feed.RetainFeedback then Feed:RetainFeedback(entry) end
    while #Feed.entries > 10 do table.remove(Feed.entries,1) end
end)
