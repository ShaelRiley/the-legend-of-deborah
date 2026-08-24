LOD = LOD or {}
LOD.CombatRollFeed = LOD.CombatRollFeed or {entries = {}}

local Feed = LOD.CombatRollFeed
local MAX_ENTRIES = 8
local HOLD_SECONDS = 5.0
local FADE_SECONDS = 1.0

surface.CreateFont("LOD_CombatRoll", {
    font = "DejaVu Sans",
    size = 15,
    weight = 700,
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

hook.Add("HUDPaint", "LOD_CombatRollFeed", function()
    local now = CurTime()
    while Feed.entries[1] and now - Feed.entries[1].created > HOLD_SECONDS + FADE_SECONDS do
        table.remove(Feed.entries, 1)
    end
    if #Feed.entries == 0 then return end

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
end)
