LOD = LOD or {}
LOD.RPGSixthSense = LOD.RPGSixthSense or {}
local Sixth = LOD.RPGSixthSense
local NET_SIXTH = "LOD_RPGSixthSenseSnapshot"
local INVISIBLE_COLOR = Color(150, 225, 255, 210)
local NEARBY_COLOR = Color(255, 185, 80, 230)
local WATCHER_LOOP = "npc/scanner/scanner_scan_loop1.wav"
local WATCHER_FALLBACK_LOOP = "ambient/machines/combine_terminal_loop1.wav"

Sixth.Nearby = Sixth.Nearby or {}
Sixth.VisibleInvisible = Sixth.VisibleInvisible or {}
Sixth.WatcherSounds = Sixth.WatcherSounds or setmetatable({}, {__mode = "k"})

local function readEntities()
    local out = {}
    local count = net.ReadUInt(8)
    for _ = 1, count do
        local ent = net.ReadEntity()
        if IsValid(ent) then out[#out + 1] = ent end
    end
    return out
end

local function watcherSoundPath()
    if file.Exists("sound/" .. WATCHER_LOOP, "GAME") then return WATCHER_LOOP end
    return WATCHER_FALLBACK_LOOP
end

local function syncWatcherSounds(authorized)
    local keep = {}
    for _, watcher in ipairs(authorized) do
        if IsValid(watcher) then
            keep[watcher] = true
            if not Sixth.WatcherSounds[watcher] then
                local patch = CreateSound(watcher, watcherSoundPath())
                if patch then
                    patch:PlayEx(0.30, 100)
                    patch:SetSoundLevel(68)
                    Sixth.WatcherSounds[watcher] = patch
                end
            end
        end
    end
    for watcher, patch in pairs(Sixth.WatcherSounds) do
        if not keep[watcher] or not IsValid(watcher) then
            if patch then patch:Stop() end
            Sixth.WatcherSounds[watcher] = nil
        end
    end
end

net.Receive(NET_SIXTH, function()
    Sixth.Nearby = readEntities()
    Sixth.VisibleInvisible = readEntities()
    syncWatcherSounds(readEntities())
end)

hook.Add("PreDrawHalos", "LOD_RPGSixthSenseHalos", function()
    if #Sixth.Nearby > 0 then
        halo.Add(Sixth.Nearby, NEARBY_COLOR, 2, 2, 1, true, true)
    end
    if #Sixth.VisibleInvisible > 0 then
        halo.Add(Sixth.VisibleInvisible, INVISIBLE_COLOR, 2, 2, 1, true, false)
    end
end)

hook.Add("EntityRemoved", "LOD_RPGSixthSenseEntityRemoved", function(ent)
    local patch = Sixth.WatcherSounds[ent]
    if patch then patch:Stop() end
    Sixth.WatcherSounds[ent] = nil
end)

hook.Add("ShutDown", "LOD_RPGSixthSenseStopAudio", function()
    for _, patch in pairs(Sixth.WatcherSounds) do if patch then patch:Stop() end end
    Sixth.WatcherSounds = setmetatable({}, {__mode = "k"})
end)
