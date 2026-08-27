LOD = LOD or {}
LOD.MultiplayerContracts = LOD.MultiplayerContracts or {}

local Contracts = LOD.MultiplayerContracts
local RunManager = LOD.RunManager
local Progression = LOD.ProgressionDirector
local Minimap = LOD.MinimapServer
local EncounterDirector = LOD.EncounterDirector
local CC = LOD.Config

if not RunManager or not CC then return end

Contracts.Stats = Contracts.Stats or {
    friendlyFireBlocked = 0,
    invalidGateUsesBlocked = 0,
    mapPolicySyncs = 0
}

local function developerMode()
    local cv = GetConVar("lod_developer_mode")
    return cv and cv:GetBool() or false
end

local function currentLevel()
    local state = RunManager.State
    return state and math.max(0, math.floor(tonumber(state.Level) or 0)) or 0
end

local function productionMapLevelAvailable()
    local level = currentLevel()
    return level >= 1 and level <= 20
end

local function shouldHaveMapAccess(ply)
    local state = RunManager.State
    return IsValid(ply)
        and ply:IsPlayer()
        and ply:Alive()
        and RunManager:IsActivePlayer(ply)
        and state ~= nil
        and state.BuildReady == true
        and state.Failed ~= true
        and state.LevelCleared ~= true
        and (productionMapLevelAvailable() or developerMode())
end

-- The old Map pickup entitlement is retained only as a client-compatibility mirror.
-- It is no longer an authority. Dungeons 1-20 derive map availability from the
-- campaign level and active/living player state; Dungeon 21+ has no production map.
-- Developer mode may temporarily override tier availability for explicit testing.
function Contracts:SyncMapCompatibility(ply)
    if not IsValid(ply) then return end
    local allowed = shouldHaveMapAccess(ply)
    ply:SetNW2Bool("LOD_MapUnlocked", allowed)
    ply:SetNW2Int("LOD_MapUnlockedLevel", allowed and currentLevel() or 0)
    self.Stats.mapPolicySyncs = (self.Stats.mapPolicySyncs or 0) + 1
end

if Minimap then
    function Minimap:CanUse(ply)
        return shouldHaveMapAccess(ply)
    end

    -- These legacy methods now update only the compatibility mirror. Calling
    -- Grant can never create permission that the campaign rules do not allow.
    function Minimap:Grant(ply)
        Contracts:SyncMapCompatibility(ply)
        return shouldHaveMapAccess(ply)
    end

    function Minimap:Revoke(ply)
        if not IsValid(ply) then return end
        ply:SetNW2Bool("LOD_MapUnlocked", false)
        ply:SetNW2Int("LOD_MapUnlockedLevel", 0)
    end
end

if not RunManager.LODMultiplayerMapPolicyWrapped then
    RunManager.LODMultiplayerMapPolicyWrapped = true
    local baseSyncPlayerVars = RunManager._SyncPlayerVars
    function RunManager:_SyncPlayerVars(ply)
        baseSyncPlayerVars(self, ply)
        Contracts:SyncMapCompatibility(ply)
    end
end

hook.Add("PlayerSpawn", "LOD_MultiplayerMapPolicySpawn", function(ply)
    timer.Simple(0.05, function()
        if IsValid(ply) then Contracts:SyncMapCompatibility(ply) end
    end)
end)

hook.Add("PlayerDeath", "LOD_MultiplayerMapPolicyDeath", function(ply)
    timer.Simple(0, function()
        if IsValid(ply) then Contracts:SyncMapCompatibility(ply) end
    end)
end)

-- A level is planned before RunManager repopulates ActiveIdentity. Counting only
-- _ActiveCount() there silently produces one-player authored encounter budgets on
-- every ordinary next-level build. Snapshot the connected cooperative identities
-- that are actually eligible to enter the level, bounded by the four active slots.
function RunManager:_ConnectedPartyCountForBuild()
    local count = 0
    local newAdmissions = 0
    local played = self:_PlayedCount()
    local maxActive = CC.MaxActivePlayers or 4
    local maxPlayed = CC.Campaign and CC.Campaign.MaxPlayedIdentities or 10

    for _, ply in ipairs(self:_SortedConnectedPlayers()) do
        if count >= maxActive then break end
        local ps = self:GetPlayerState(ply)
        if ps then
            if not ps.eliminated and (ps.lives or 0) > 0 then
                count = count + 1
            end
        elseif not self.State.WardenStarted and played + newAdmissions < maxPlayed then
            count = count + 1
            newAdmissions = newAdmissions + 1
        end
    end

    return math.Clamp(count, 1, maxActive)
end

function RunManager:GetPartySizeForScaling()
    local state = self.State or {}
    if state.BuildReady ~= true then
        return math.Clamp(state.PlannedPartySize or self:_ConnectedPartyCountForBuild(),
            1, CC.MaxActivePlayers or 4)
    end
    return math.Clamp(self:_ActiveCount(), 1, CC.MaxActivePlayers or 4)
end

if not RunManager.LODMultiplayerPartyScaleWrapped then
    RunManager.LODMultiplayerPartyScaleWrapped = true
    local baseBuildCurrentLevel = RunManager.BuildCurrentLevel
    function RunManager:BuildCurrentLevel(levelSeedOverride)
        self.State.PlannedPartySize = self:_ConnectedPartyCountForBuild()
        return baseBuildCurrentLevel(self, levelSeedOverride)
    end
end

-- EncounterDirector previously read _ActiveCount() during planning, after that
-- ledger had been cleared for the new level. Use the build snapshot instead.
-- A player who joins after a level was already planned does not retroactively
-- rewrite completed content; subsequent level builds include that connected player.
if EncounterDirector and not EncounterDirector.LODMultiplayerPartyScaleInstalled then
    EncounterDirector.LODMultiplayerPartyScaleInstalled = true
    function EncounterDirector:_ThreatScale()
        local EC = CC.Encounter
        local level = RunManager.State and RunManager.State.Level or 1
        local party = RunManager:GetPartySizeForScaling()
        local partyScale = EC.PartyThreatMultiplier[party] or 1
        local campaignScale = 1 + EC.CampaignThreatGrowthPerLevel * math.max(0, level - 1)
        return partyScale * campaignScale
    end
end

-- Every production gate interaction must come from a living active participant.
-- Other progression interactions already enforce this contract. Developer-mode
-- nil callers remain available for explicit test tooling without weakening play.
if Progression and not Progression.LODMultiplayerGateContractInstalled then
    Progression.LODMultiplayerGateContractInstalled = true
    local baseTryOpenGate = Progression.TryOpenGate
    function Progression:TryOpenGate(index, ply, gateEnt)
        if IsValid(ply) then
            if not ply:IsPlayer() or not ply:Alive() or not RunManager:IsActivePlayer(ply) then
                Contracts.Stats.invalidGateUsesBlocked = (Contracts.Stats.invalidGateUsesBlocked or 0) + 1
                return false
            end
        elseif not developerMode() then
            Contracts.Stats.invalidGateUsesBlocked = (Contracts.Stats.invalidGateUsesBlocked or 0) + 1
            return false
        end
        return baseTryOpenGate(self, index, ply, gateEnt)
    end
end

local function resolvePlayerSource(ent, depth)
    if not IsValid(ent) then return nil end
    if ent:IsPlayer() then return ent end
    depth = depth or 0
    if depth >= 2 or not ent.GetOwner then return nil end
    local owner = ent:GetOwner()
    if not IsValid(owner) or owner == ent then return nil end
    return resolvePlayerSource(owner, depth + 1)
end

local function isFriendlyFire(victim, attacker, inflictor)
    if not IsValid(victim) or not victim:IsPlayer() or not victim:Alive() then return false end
    if not RunManager:IsActivePlayer(victim) then return false end

    local source = resolvePlayerSource(attacker) or resolvePlayerSource(inflictor)
    if not IsValid(source) or source == victim then return false end
    if not RunManager:IsActivePlayer(source) then return false end
    return true
end

-- Direct player damage is rejected at the dedicated player-damage gate.
hook.Add("PlayerShouldTakeDamage", "LOD_MultiplayerFriendlyFire", function(victim, attacker)
    if isFriendlyFire(victim, attacker, attacker) then
        Contracts.Stats.friendlyFireBlocked = (Contracts.Stats.friendlyFireBlocked or 0) + 1
        return false
    end
end)

-- Also zero owned-entity/projectile damage whose attacker arrives as the projectile
-- rather than the owning player. Self-damage remains legal; only teammate damage
-- is suppressed.
hook.Add("EntityTakeDamage", "LOD_MultiplayerFriendlyFireOwnedEntities", function(victim, dmginfo)
    if not IsValid(victim) or not victim:IsPlayer() then return end
    if not isFriendlyFire(victim, dmginfo:GetAttacker(), dmginfo:GetInflictor()) then return end

    Contracts.Stats.friendlyFireBlocked = (Contracts.Stats.friendlyFireBlocked or 0) + 1
    dmginfo:SetDamage(0)
    dmginfo:ScaleDamage(0)
    return true
end)

local function countLivingActive()
    local count = 0
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Alive() and RunManager:IsActivePlayer(ply) then count = count + 1 end
    end
    return count
end

concommand.Add("lod_multiplayer_contract_status", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end

    local state = RunManager.State or {}
    local living = countLivingActive()
    local mapAllowed = 0
    local mapMismatch = 0
    for _, candidate in ipairs(player.GetAll()) do
        if IsValid(candidate) then
            local expected = shouldHaveMapAccess(candidate)
            local mirrored = candidate:GetNW2Bool("LOD_MapUnlocked", false)
                and candidate:GetNW2Int("LOD_MapUnlockedLevel", 0) == currentLevel()
            if expected then mapAllowed = mapAllowed + 1 end
            if expected ~= mirrored then mapMismatch = mapMismatch + 1 end
        end
    end

    local hooks = hook.GetTable()
    local playerDamageHooks = hooks.PlayerShouldTakeDamage or {}
    local entityDamageHooks = hooks.EntityTakeDamage or {}
    local ffArmed = playerDamageHooks["LOD_MultiplayerFriendlyFire"] ~= nil
        and entityDamageHooks["LOD_MultiplayerFriendlyFireOwnedEntities"] ~= nil
    local gateArmed = Progression and Progression.LODMultiplayerGateContractInstalled == true
    local mapArmed = Minimap and Minimap.CanUse ~= nil and RunManager.LODMultiplayerMapPolicyWrapped == true
    local scaleArmed = EncounterDirector and EncounterDirector.LODMultiplayerPartyScaleInstalled == true
        and RunManager.LODMultiplayerPartyScaleWrapped == true
    local plannedParty = math.Clamp(tonumber(state.PlannedPartySize) or 1, 1, CC.MaxActivePlayers or 4)
    local passed = ffArmed and gateArmed and mapArmed and scaleArmed and mapMismatch == 0

    local line = string.format(
        "level=%d livingActive=%d plannedParty=%d mapAllowed=%d mapMismatch=%d mapD1to20=%s friendlyFire=%s gateContract=%s partyScale=%s ffBlocked=%d gateBlocked=%d result=%s",
        currentLevel(), living, plannedParty, mapAllowed, mapMismatch, tostring(productionMapLevelAvailable()),
        ffArmed and "OFF/ARMED" or "UNSAFE", gateArmed and "ARMED" or "MISSING",
        scaleArmed and "ARMED" or "MISSING", Contracts.Stats.friendlyFireBlocked or 0,
        Contracts.Stats.invalidGateUsesBlocked or 0, passed and "PASS" or "FAIL")
    print("[LOD:MULTIPLAYER-CONTRACT] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end

    if state.Level and state.Level >= 21 and not developerMode() and mapAllowed > 0 then
        print("[LOD:MULTIPLAYER-CONTRACT] FAIL Dungeon 21+ exposed production map access")
    end
end)
