-- LOD-SPOT-01: one player readout, two physical lines, shared semantic colors.
-- The base callback draws its own nickname and health percentage independently.
-- Suppress it even when our custom readout is hidden (menus, death, concealment).
hook.Add("HUDDrawTargetID", "LOD_HideStockPlayerTargetID", function() return false end)

local FONT = "LOD_HUD_Small"
local GLYPH = "[%z\1-\127\194-\244][\128-\191]*"
local ORANGE = Color(255, 165, 80)
local ELLIPSIS = "…"
local cached = {} -- One layout only; no entity references or health snapshots.

local function singleLine(value, fallback)
    local text = tostring(value or ""):gsub("[%c]", " ")
        :gsub("\226\128[\168\169]", " "):match("^%s*(.-)%s*$")
    return text ~= "" and text or fallback
end

local function fit(text, limit)
    if surface.GetTextSize(text) <= limit then return text end
    if surface.GetTextSize(ELLIPSIS) > limit then return "" end
    local result = ""
    for glyph in text:gmatch(GLYPH) do
        if surface.GetTextSize(result .. glyph .. ELLIPSIS) > limit then break end
        result = result .. glyph
    end
    return result .. ELLIPSIS
end

local function identityLayout(nickname, character, width)
    if cached.nickname == nickname and cached.character == character and cached.width == width then
        return cached
    end
    local name = singleLine(nickname, "Player")
    local hero = singleLine(character, "Hero")
    local joinWidth = surface.GetTextSize(" as ")
    local available = math.max(0, width - joinWidth)
    -- Short names donate their unused width to the other span. The connector
    -- never wraps or gets parsed out of a nickname containing its own ' as '.
    local nameBudget = math.min(surface.GetTextSize(name), available * 0.4)
    local heroBudget = math.min(surface.GetTextSize(hero), available - nameBudget)
    name = fit(name, available - heroBudget)
    hero = fit(hero, heroBudget)
    cached = {nickname = nickname, character = character, width = width,
        name = name, hero = hero, nameWidth = surface.GetTextSize(name),
        heroWidth = surface.GetTextSize(hero), joinWidth = joinWidth}
    return cached
end

hook.Add("HUDPaint", "LOD_TeammateIdentity", function()
    local UI = LOD and LOD.UI
    local ply = LocalPlayer()
    if not UI or not IsValid(ply) or not ply:Alive() or UI.ActivePage then return end
    local trace = ply:GetEyeTrace()
    local target = trace and trace.Entity
    if not IsValid(target) or not target:IsPlayer() or target == ply or not target:Alive()
        or target:IsDormant() or target:GetNoDraw()
        or target:GetNW2Float("LOD_VeilUntil", 0) > CurTime() then return end

    -- Human Soldiers keep their Hero progression while occupying a disposable
    -- body. Do not mislabel that body with the stored Hero's procedural name.
    local character
    if target:GetNW2Bool("LOD_IsSoldier", false) then
        character = "Soldier"
    else
        character = singleLine(target:GetNW2String("LOD_HeroName", ""), "")
        if character == "" then character = target:GetNW2String("LOD_Character", "Hero") end
    end
    local roles = UI.HUDRoles or UI.Roles
    surface.SetFont(FONT)
    local row = identityLayout(target:Nick(), character, math.min(640, ScrW() * 0.8))
    local center, y = ScrW() * 0.5, ScrH() * 0.5 + 24
    local x = center - (row.nameWidth + row.joinWidth + row.heroWidth) * 0.5
    UI:HUDText(row.name, FONT, x, y, roles.identity, TEXT_ALIGN_LEFT)
    x = x + row.nameWidth
    UI:HUDText(" as ", FONT, x, y, roles.prose, TEXT_ALIGN_LEFT)
    UI:HUDText(row.hero, FONT, x + row.joinWidth, y, roles.character, TEXT_ALIGN_LEFT)

    local hp = math.max(0, math.floor(tonumber(target:Health()) or 0))
    local maximum = math.floor(tonumber(target:GetMaxHealth()) or 0)
    local fraction = string.format("%d/%s ", hp, maximum > 0 and tostring(maximum) or "?")
    local color = roles.prose
    if maximum > 0 then
        if hp >= maximum then color = roles.resource
        elseif hp / maximum > 0.5 then color = roles.objective
        elseif hp / maximum > 0.25 then color = ORANGE
        else color = roles.danger end
    end
    local fractionWidth = surface.GetTextSize(fraction)
    x = center - (fractionWidth + surface.GetTextSize("HP")) * 0.5
    UI:HUDText(fraction, FONT, x, y + 20, roles.resource, TEXT_ALIGN_LEFT)
    UI:HUDText("HP", FONT, x + fractionWidth, y + 20, color, TEXT_ALIGN_LEFT)
end)
