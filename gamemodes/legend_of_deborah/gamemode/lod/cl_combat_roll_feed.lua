LOD = LOD or {}
LOD.CombatRollFeed = LOD.CombatRollFeed or {entries = {}}

local Feed = LOD.CombatRollFeed
Feed.entries = Feed.entries or {}
local MAX_ENTRIES = 10

surface.CreateFont("LOD_CombatRoll", {
    font = "Georgia",
    size = 17,
    weight = 500,
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

local function addEntry(category, text, serial, family, tracked, segments)
    local entry = {
        category = category, segments = segments,
        text = tostring(text or ""),
        created = CurTime(), serial = serial, family = family, tracked = tracked
    }
    Feed.entries[#Feed.entries + 1] = entry
    while #Feed.entries > MAX_ENTRIES do table.remove(Feed.entries, 1) end
    if Feed.RetainFeedback then Feed:RetainFeedback(entry) end
end

net.Receive("LOD_CombatRoll", function()
    local category, text = net.ReadUInt(2), net.ReadString()
    local serial, family, tracked = net.ReadUInt(32), net.ReadString(), net.ReadBool()
    local segments = util.JSONToTable(net.ReadString())
    if not LOD.DieLogger:ValidSegments(segments, text) then
        segments = LOD.DieLogger:Segments(text, family)
    end
    -- Reliable transport serials are unique within this connection. Ignore replay
    -- without letting delayed older records overwrite newer presentation.
    Feed.seenSerials = Feed.seenSerials or {}
    Feed.serialOrder = Feed.serialOrder or {}
    if Feed.seenSerials[serial] then return end
    Feed.seenSerials[serial] = true
    Feed.serialOrder[#Feed.serialOrder + 1] = serial
    if #Feed.serialOrder > 1024 then Feed.seenSerials[table.remove(Feed.serialOrder, 1)] = nil end
    addEntry(category, text, serial, family, tracked, segments)
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

    -- A short mechanical click marks a real continuation; progression retains
    -- the longer HEV confirmation cadence. Sound remains shooter-local.
    if now >= (Feed.nextExplosionSound or 0) then
        Feed.nextExplosionSound = now + 0.10
        surface.PlaySound("buttons/button9.wav")
    end
end)
