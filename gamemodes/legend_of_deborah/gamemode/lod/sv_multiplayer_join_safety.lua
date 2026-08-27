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
                "%s id=%s ord=%s character=%s active=%s alive=%s lives=%d eliminated=%s waiting=%s magic=%.1f map=%s mapOpen=%s staticLoot=%d catchup=%s deathRemaining=%s",
                candidate:Nick(), identitySuffix(identity), tostring(ps and ps.ordinal or "-"),
                tostring(ps and ps.characterName or "Spectator"), tostring(activePlayer),
                tostring(candidate:Alive()), ps and (ps.lives or 0) or 0,
                tostring(ps and ps.eliminated == true or false), tostring(waiting), magic,
                mapAllowed and "YES" or "NO", candidate:GetNW2Bool("LOD_MapMagicActive", false) and "YES" or "NO",
                validStaticCount(identity), tostring(ps and ps.catchupGrantedLevel or "-"),
                deathRemaining and string.format("%.1f", deathRemaining) or "-")
            print("[LOD:MP-ROSTER] " .. line)
            if IsValid(ply) then ply:ChatPrint(line) end
        end
    end

    for _, text in ipairs(failures) do print("[LOD:MP-ROSTER] FAIL " .. text) end
    for _, text in ipairs(warnings) do print("[LOD:MP-ROSTER] WARN " .. text) end
end)
