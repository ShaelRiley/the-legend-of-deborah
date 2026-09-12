LOD = LOD or {}; LOD.RPG = LOD.RPG or {}
local RPG = LOD.RPG
local Catalog = assert(RPG.IdentityCatalog, "Sixth Sense requires catalog")
local Feats = assert(Catalog.OrdinaryFeats or Catalog.LevelOneOrdinaryFeats, "Sixth Sense requires ordinary feats")
local Rules = assert(LOD.RPGAbilityRules, "Sixth Sense requires ability rules")

assert(Feats.WIS_SIXTH_SENSE == nil, "duplicate canonical feat WIS_SIXTH_SENSE")
Feats.WIS_SIXTH_SENSE = {
    featId = "WIS_SIXTH_SENSE", displayName = "Sixth Sense", featFamilyId = "wis_sixth_sense", rankIndex = 1,
    replacesLowerRank = false, repeatableFallback = false,
    governingAbilities = {"wis"}, abilityRequirements = {wis = 13},
    prerequisiteFeatIds = {}, requiredCapabilityTags = {}, incompatibleFeatIds = {},
    allowedActorTypes = {"hero"}, requiredSubsystemTags = {},
    synergyTags = {"wisdom", "perception", "information"}, oneRank = true,
    effectHandlerId = "private_sixth_sense_perception",
    effectParams = {
        nearbyCellRadius = 2,
        nearbyDistanceMetric = "chebyshev",
        revealInvisibleWithOrdinaryLOS = true,
        watcherMotionAudio = true
    },
    directorBaseWeight = 1.0, eligibilityText = "WIS 13",
    actorText = "Cooperative Heroes"
}
Catalog.OrdinaryFeats = Feats

-- Reusable authoritative invisibility primitive. Watcher is the first consumer,
-- but any future actor/effect can register permanent or timed invisibility here.
LOD.RPGPerceptionState = LOD.RPGPerceptionState or {}
local Perception = LOD.RPGPerceptionState
Perception.InvisibleEntities = Perception.InvisibleEntities or setmetatable({}, {__mode = "k"})

function Perception:SetInvisible(ent, invisible)
    if not IsValid(ent) then return false end
    ent.LODRPGInvisible = invisible == true
    if ent.LODRPGInvisible then self.InvisibleEntities[ent] = true
    elseif (tonumber(ent.LODRPGInvisibleUntil) or 0) <= CurTime() then self.InvisibleEntities[ent] = nil end
    return true
end

function Perception:SetInvisibleUntil(ent, untilTime)
    if not IsValid(ent) then return false end
    ent.LODRPGInvisibleUntil = math.max(tonumber(ent.LODRPGInvisibleUntil) or 0, tonumber(untilTime) or 0)
    if ent.LODRPGInvisibleUntil > CurTime() then self.InvisibleEntities[ent] = true end
    return true
end

function Perception:IsInvisible(ent, now)
    if not IsValid(ent) then return false end
    now = tonumber(now) or CurTime()
    return ent.LODRPGInvisible == true or (tonumber(ent.LODRPGInvisibleUntil) or 0) > now
end

local NET_SIXTH = "LOD_RPGSixthSenseSnapshot"
util.AddNetworkString(NET_SIXTH)

local function owns(state, id)
    for _, owned in ipairs(state and state.featIds or {}) do if owned == id then return true end end
    return false
end

function RPG:CheckpointDSixthSenseCellDistance(a, b)
    if not a or not b or a.z ~= b.z then return math.huge end
    return math.max(math.abs((a.x or 0) - (b.x or 0)), math.abs((a.y or 0) - (b.y or 0)))
end

function RPG:CheckpointDSixthSenseRevealDecision(invisible, hostile, ownerCell, entityCell, ordinaryVisible)
    local nearby = hostile == true and self:CheckpointDSixthSenseCellDistance(ownerCell, entityCell) <= 2
    local visibleInvisible = invisible == true and ordinaryVisible == true
    return nearby, visibleInvisible
end

function RPG:CheckpointDSixthSenseWatcherAudio(isWatcher, moving, ownerCell, entityCell)
    return isWatcher == true and moving == true
        and ownerCell ~= nil and entityCell ~= nil and ownerCell.z == entityCell.z
end

local function activeGraph()
    local state = LOD.RunManager and LOD.RunManager.State
    return state and state.Graph or nil
end

local function livingHostile(ent)
    return IsValid(ent) and ent.LODHostile == true and ent.LODDead ~= true and ent:Health() > 0
end

local function collectHostiles()
    local out, seen = {}, {}
    local function add(source)
        for _, hostile in ipairs(source or {}) do
            if livingHostile(hostile) and not seen[hostile] then
                seen[hostile] = true
                out[#out + 1] = hostile
            end
        end
    end
    add(LOD.EncounterDirector and LOD.EncounterDirector.Entities)
    add(LOD.WanderingDirector and LOD.WanderingDirector.Entities)
    table.sort(out, function(a, b) return a:EntIndex() < b:EntIndex() end)
    return out
end

local function syncLegacyWatcherInvisibility(hostile, now)
    if not livingHostile(hostile) or hostile.LODArchetypeId ~= "watcher" then return end
    local untilTime = hostile:GetNW2Float("LOD_WatcherInvisibleUntil", 0)
    if untilTime > now then Perception:SetInvisibleUntil(hostile, untilTime) end
end

local function ordinaryVisible(ply, ent)
    if not IsValid(ply) or not IsValid(ent) then return false end
    -- Entity:Visible is the existing Source world-occlusion/LOS authority. It is
    -- intentionally evaluated independently of render-time invisibility.
    return ply:Visible(ent)
end

local function cellOf(graph, ent)
    local navigator = LOD.MazeNavigator
    return navigator and graph and IsValid(ent) and navigator:WorldToCell(graph, ent:GetPos()) or nil
end

local function sendSnapshot(ply, nearby, visibleInvisible, movingWatchers)
    net.Start(NET_SIXTH)
    net.WriteUInt(math.min(#nearby, 255), 8)
    for index = 1, math.min(#nearby, 255) do net.WriteEntity(nearby[index]) end
    net.WriteUInt(math.min(#visibleInvisible, 255), 8)
    for index = 1, math.min(#visibleInvisible, 255) do net.WriteEntity(visibleInvisible[index]) end
    net.WriteUInt(math.min(#movingWatchers, 255), 8)
    for index = 1, math.min(#movingWatchers, 255) do net.WriteEntity(movingWatchers[index]) end
    net.Send(ply)
end

local function clearSnapshot(ply)
    sendSnapshot(ply, {}, {}, {})
end

RPG.CheckpointDSixthSenseStats = RPG.CheckpointDSixthSenseStats or {
    snapshots = 0, nearbyReveals = 0, invisibleReveals = 0, watcherAudioAuthorizations = 0
}

local function buildSnapshot(ply, graph, hostiles, now)
    local ownerCell = cellOf(graph, ply)
    if not ownerCell then return {}, {}, {} end
    local nearby, visibleInvisible, movingWatchers = {}, {}, {}
    local nearbySet = {}

    for _, hostile in ipairs(hostiles) do
        syncLegacyWatcherInvisibility(hostile, now)
        local hostileCell = cellOf(graph, hostile)
        local isInvisible = Perception:IsInvisible(hostile, now)
        local near, visible = RPG:CheckpointDSixthSenseRevealDecision(
            isInvisible, true, ownerCell, hostileCell, isInvisible and ordinaryVisible(ply, hostile))
        if near then
            nearby[#nearby + 1] = hostile
            nearbySet[hostile] = true
        elseif visible then
            visibleInvisible[#visibleInvisible + 1] = hostile
        end
        local moving = (tonumber(hostile.LODMotionSpeed) or 0) > 1
        if RPG:CheckpointDSixthSenseWatcherAudio(
            hostile.LODArchetypeId == "watcher", moving, ownerCell, hostileCell)
        then
            movingWatchers[#movingWatchers + 1] = hostile
        end
    end

    -- Non-hostile invisible entities come from the shared registry rather than a
    -- world scan. Hostiles already authorized above are skipped deterministically.
    for ent in pairs(Perception.InvisibleEntities) do
        if not IsValid(ent) or not Perception:IsInvisible(ent, now) then
            Perception.InvisibleEntities[ent] = nil
        elseif not nearbySet[ent] and not ent.LODHostile and ordinaryVisible(ply, ent) then
            visibleInvisible[#visibleInvisible + 1] = ent
        end
    end

    table.sort(visibleInvisible, function(a, b) return a:EntIndex() < b:EntIndex() end)
    return nearby, visibleInvisible, movingWatchers
end

local hadFeat = setmetatable({}, {__mode = "k"})
timer.Create("LOD_CheckpointDSixthSense", 0.15, 0, function()
    local graph = activeGraph()
    local hostiles = graph and collectHostiles() or {}
    local now = CurTime()
    for _, ply in ipairs(player.GetHumans()) do
        local state = Rules:ProgressionState(ply)
        local active = IsValid(ply) and ply:Alive() and state ~= nil and owns(state, "WIS_SIXTH_SENSE")
        if active and graph then
            local nearby, invisible, watchers = buildSnapshot(ply, graph, hostiles, now)
            sendSnapshot(ply, nearby, invisible, watchers)
            hadFeat[ply] = true
            local stats = RPG.CheckpointDSixthSenseStats
            stats.snapshots = stats.snapshots + 1
            stats.nearbyReveals = stats.nearbyReveals + #nearby
            stats.invisibleReveals = stats.invisibleReveals + #invisible
            stats.watcherAudioAuthorizations = stats.watcherAudioAuthorizations + #watchers
        elseif hadFeat[ply] then
            clearSnapshot(ply)
            hadFeat[ply] = nil
        end
    end
end)

function RPG:ValidateCheckpointDSixthSenseFeat()
    local errors = {}; local function expect(ok, message) if not ok then errors[#errors + 1] = message end end
    local definition = Feats.WIS_SIXTH_SENSE
    expect(definition and definition.abilityRequirements.wis == 13, "Sixth Sense WIS 13 definition")
    expect(definition and #definition.allowedActorTypes == 1 and definition.allowedActorTypes[1] == "hero",
        "Sixth Sense cooperative Hero restriction")
    local center = {x = 4, y = 4, z = 1}
    expect(self:CheckpointDSixthSenseCellDistance(center, {x = 6, y = 2, z = 1}) == 2,
        "Chebyshev 2-cell neighborhood")
    expect(self:CheckpointDSixthSenseCellDistance(center, {x = 7, y = 4, z = 1}) == 3,
        "outside 2-cell neighborhood")
    expect(self:CheckpointDSixthSenseCellDistance(center, {x = 4, y = 4, z = 2}) == math.huge,
        "different floor excluded")
    local near, invisible = self:CheckpointDSixthSenseRevealDecision(false, true, center, {x = 6, y = 6, z = 1}, false)
    expect(near and not invisible, "nearby hostile ignores LOS")
    near, invisible = self:CheckpointDSixthSenseRevealDecision(true, false, center, {x = 9, y = 9, z = 1}, true)
    expect(not near and invisible, "ordinary-LOS invisible entity reveal")
    expect(self:CheckpointDSixthSenseWatcherAudio(true, true, center, {x = 5, y = 4, z = 1}),
        "same-floor moving Watcher audio")
    expect(not self:CheckpointDSixthSenseWatcherAudio(true, true, center, {x = 5, y = 4, z = 2}),
        "different-floor Watcher audio blocked")
    return #errors == 0, errors
end

concommand.Add("lod_rpg_validate_sixth_sense", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end
    local ok, errors = RPG:ValidateCheckpointDSixthSenseFeat()
    print("[LOD:SIXTH-SENSE] " .. (ok and "PASS" or "FAIL")
        .. (#errors > 0 and (" " .. table.concat(errors, "; ")) or ""))
end)
