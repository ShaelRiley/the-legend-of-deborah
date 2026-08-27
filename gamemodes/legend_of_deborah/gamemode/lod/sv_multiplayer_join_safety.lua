LOD = LOD or {}
LOD.MultiplayerJoinSafety = LOD.MultiplayerJoinSafety or {}

local JoinSafety = LOD.MultiplayerJoinSafety
local RunManager = LOD.RunManager
local Loot = LOD.LootDirector
local Minimap = LOD.MinimapServer
local DeathTetris = LOD.DeathTetris
local CC = LOD.Config

if not RunManager or not CC then return end

JoinSafety.Stats = JoinSafety.Stats or {
    earlyLootMasks = 0,
    joinAudits = 0
}

local function identityOf(ply)
    return IsValid(ply) and RunManager:IdentityOf(ply) or nil
end

-- LootDirector already performs a complete transmission pass after the joining
-- client settles. Add an immediate first-tick mask as well so a newly connected
-- client never receives a brief flash of another identity's already-existing
-- individualized loot before that later catch-up pass runs.
hook.Add("PlayerInitialSpawn", "LOD_MultiplayerEarlyLootTransmissionMask", function(ply)
    timer.Simple(0, function()
        if not IsValid(ply) or not Loot then return end
        local identity = identityOf(ply)
        if not identity then return end

        local masked = 0
        for _, ent in ipairs(Loot.Entities or {}) do
            if IsValid(ent) then
                ent:SetPreventTransmit(ply, ent.LODLootOwnerIdentity ~= identity)
                masked = masked + 1
            end
        end
        JoinSafety.Stats.earlyLootMasks = (JoinSafety.Stats.earlyLootMasks or 0) + masked
    end)
end)

local function connectedByIdentity()
    local out = {}
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            local id = identityOf(ply)
            if id then out[id] = ply end
        end
    end
    return out
end

local function validStaticCount(identity)
    if not Loot or not identity then return 0 end
    local count = 0
    for _, ent in pairs((Loot.StaticByIdentity or {})[identity] or {}) do
        if IsValid(ent) then count = count + 1 end
    end
    return count
end

local function identitySuffix(identity)
    identity = tostring(identity or "none")
    if #identity <= 6 then return identity end
    return "#" .. string.sub(identity, -6)
end

local function entryClass(ps)
    if not ps then return "spectator" end
    if ps.initialLevelOneParticipant == true then return "initial" end
    if ps.catchupGrantedLevel then return "JIP-L" .. tostring(ps.catchupGrantedLevel) end
    if ps.catchupLevel then return "JIP-pending-L" .. tostring(ps.catchupLevel) end
    return "existing"
end

local function hostileTargetCounts()
    local counts = {}
    for _, hostile in ipairs(LOD.HostileRegistry and LOD.HostileRegistry:List() or {}) do
        if IsValid(hostile) and not hostile.LODDead and IsValid(hostile.LODTarget)
            and hostile.LODTarget:IsPlayer()
        then
            local identity = identityOf(hostile.LODTarget)
            if identity then counts[identity] = (counts[identity] or 0) + 1 end
        end
    end
    return counts
end

local function playerCellText(ply, graph)
    if not IsValid(ply) or not graph or not LOD.MazeNavigator then return "-" end
    local cell = LOD.MazeNavigator:WorldToCell(graph, ply:GetPos())
    if not cell then return "-" end
    return string.format("%d:%d:%d/F%d", cell.x, cell.y, cell.z, cell.z + 1)
end

local function rosterAudit()
    local state = RunManager.State or {}
    local connected = connectedByIdentity()
    local failures = {}
    local warnings = {}
    local seenOrdinal = {}
    local seenCharacter = {}

    for identity, ps in pairs(state.PlayerState or {}) do
        if ps then
            local ordinal = tonumber(ps.ordinal)
            if ordinal then
                if seenOrdinal[ordinal] and seenOrdinal[ordinal] ~= identity then
                    failures[#failures + 1] = string.format(
                        "ordinal %d reserved by %s and %s", ordinal,
                        identitySuffix(seenOrdinal[ordinal]), identitySuffix(identity))
                else
                    seenOrdinal[ordinal] = identity
                end

                -- The first identity in a fresh campaign is the bootstrap host on
                -- listen servers where the Level-1 build precedes PlayerInitialSpawn.
                -- It must never receive the late-join catch-up kit.
                if ordinal == 1 and (ps.catchupLevel or ps.catchupGrantedLevel) then
                    failures[#failures + 1] = "ordinal 1 was misclassified as join-in-progress"
                end
            end

            if ps.initialLevelOneParticipant == true and (ps.catchupLevel or ps.catchupGrantedLevel) then
                failures[#failures + 1] = "initial Level-1 participant also owns catch-up state "
                    .. identitySuffix(identity)
            end

            local character = ps.characterId or ps.characterName
            if character then
                if seenCharacter[character] and seenCharacter[character] ~= identity then
                    failures[#failures + 1] = string.format(
                        "character %s reserved by %s and %s", tostring(character),
                        identitySuffix(seenCharacter[character]), identitySuffix(identity))
                else
                    seenCharacter[character] = identity
                end
            end
        end
    end

    local active = 0
    for identity, enabled in pairs(state.ActiveIdentity or {}) do
        if enabled then
            active = active + 1
            if not connected[identity] then
                failures[#failures + 1] = "active disconnected identity " .. identitySuffix(identity)
            end
        end
    end
    if active > (CC.MaxActivePlayers or 4) then
        failures[#failures + 1] = string.format("active=%d exceeds cap", active)
    end

    if table.Count(connected) < 2 then
        warnings[#warnings + 1] = "two-client interaction not yet exercised"
    end

    JoinSafety.Stats.joinAudits = (JoinSafety.Stats.joinAudits or 0) + 1
    return failures, warnings, active
end

concommand.Add("lod_multiplayer_roster_status", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end

    local state = RunManager.State or {}
    local failures, warnings, active = rosterAudit()
    local connected = player.GetAll()
    local targetCounts = hostileTargetCounts()
    local result = #failures == 0 and "PASS" or "FAIL"

    local headline = string.format(
        "connected=%d played=%d active=%d/%d identities=%d earlyLootMasks=%d failures=%d warnings=%d result=%s",
        #connected, table.Count(state.PlayedIdentities or {}), active, CC.MaxActivePlayers or 4,
        table.Count(state.PlayerState or {}), JoinSafety.Stats.earlyLootMasks or 0,
        #failures, #warnings, result)
    print("[LOD:MP-ROSTER] " .. headline)
    if IsValid(ply) then ply:ChatPrint(headline) end

    for _, candidate in ipairs(RunManager:_SortedConnectedPlayers()) do
        if IsValid(candidate) then
            local identity = identityOf(candidate)
            local ps = identity and RunManager:GetPlayerState(identity)
            local activePlayer = RunManager:IsActivePlayer(candidate)
            local waiting = identity and state.WaitingSince and state.WaitingSince[identity] ~= nil or false
            local magic = ps and tonumber(ps.magic) or 0
            local deathRemaining = DeathTetris and DeathTetris.GetMandatoryRemaining
                and DeathTetris:GetMandatoryRemaining(identity) or nil
            local mapAllowed = Minimap and Minimap.CanUse and Minimap:CanUse(candidate) or false
            local line = string.format(
                "%s id=%s ord=%s character=%s entry=%s active=%s alive=%s hp=%d lives=%d eliminated=%s waiting=%s magic=%.1f map=%s mapOpen=%s staticLoot=%d cell=%s targetedBy=%d deathRemaining=%s",
                candidate:Nick(), identitySuffix(identity), tostring(ps and ps.ordinal or "-"),
                tostring(ps and ps.characterName or "Spectator"), entryClass(ps), tostring(activePlayer),
                tostring(candidate:Alive()), math.max(0, candidate:Health()), ps and (ps.lives or 0) or 0,
                tostring(ps and ps.eliminated == true or false), tostring(waiting), magic,
                mapAllowed and "YES" or "NO", candidate:GetNW2Bool("LOD_MapMagicActive", false) and "YES" or "NO",
                validStaticCount(identity), playerCellText(candidate, state.Graph), targetCounts[identity] or 0,
                deathRemaining and string.format("%.1f", deathRemaining) or "-")
            print("[LOD:MP-ROSTER] " .. line)
            if IsValid(ply) then ply:ChatPrint(line) end
        end
    end

    for _, text in ipairs(failures) do print("[LOD:MP-ROSTER] FAIL " .. text) end
    for _, text in ipairs(warnings) do print("[LOD:MP-ROSTER] WARN " .. text) end
end)
