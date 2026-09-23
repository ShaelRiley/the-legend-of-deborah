LOD = LOD or {}
LOD.RunManager = LOD.RunManager or {}

local RunManager = LOD.RunManager
local CC = LOD.Config

local cvSeed = CreateConVar("lod_campaign_seed", "0", FCVAR_ARCHIVE, "0 = time-derived campaign seed; nonzero = custom unranked seed")
local cvRosterSeed = CreateConVar("lod_roster_seed", "0", FCVAR_ARCHIVE,
    "0 = independently generated roster seed; nonzero = reproducible custom unranked roster")
local defaultSeedCounter = 0
local defaultRosterSeedCounter = 0

local function freshState(campaignEpoch)
    return {
        CampaignEpoch = campaignEpoch or 0,
        CampaignSeed = nil,
        RosterSeed = nil,
        LevelSeed = nil,
        Level = 1,
        HighestLevel = 1,
        RescuedDamsels = {},
        DamselClaims = {},
        CashRecovered = 0,
        Ranked = true,
        BuildReady = false,
        Graph = nil,
        BuildReport = nil,
        CharacterByIdentity = {},
        ActiveIdentity = {},
        PlayedIdentities = {},
        RetiredPartyMembers = {},
        PlayerState = {},
        RPGAllocation = nil,
        CharacterOrder = nil,
        WaitingSince = {},
        Cards = {false, false, false, false},
        GatesOpen = {false, false, false, false},
        JailKey = false,
        JailDoorOpen = false,
        ObjectiveStage = 1,
        CheckpointIndex = 0,
        CheckpointPos = nil,
        Failed = false,
        LevelCleared = false,
        IntermissionEnd = nil,
        SimulationFrozen = false,
        FreezeStarted = nil,
        WardenStarted = false
    }
end

RunManager.CampaignEpoch = RunManager.CampaignEpoch or 0
RunManager.State = RunManager.State or freshState(RunManager.CampaignEpoch)

function RunManager:IsCampaignEpoch(epoch)
    return self.State and self.State.CampaignEpoch == epoch
end

function RunManager:IdentityOf(ply)
    if not IsValid(ply) then return nil end
    local steamID = ply:SteamID64()
    return steamID ~= "0" and steamID or ("bot:" .. ply:EntIndex())
end

function RunManager:GetPlayerState(plyOrIdentity)
    local id = isstring(plyOrIdentity) and plyOrIdentity or self:IdentityOf(plyOrIdentity)
    return id and self.State.PlayerState[id] or nil
end

function RunManager:MarkUnranked(reason)
    self.State.Ranked = false
    self.State.UnrankedReason = self.State.UnrankedReason or reason
    if LOD.ProgressionDirector and LOD.ProgressionDirector.SyncAll then LOD.ProgressionDirector:SyncAll() end
end

function RunManager:_DefaultSeed()
    defaultSeedCounter = defaultSeedCounter + 1
    return LOD.Seeds.Normalize(os.time() * 1000 + defaultSeedCounter)
end

function RunManager:_DefaultRosterSeed()
    defaultRosterSeedCounter = defaultRosterSeedCounter + 1
    -- Deliberately independent from CampaignSeed: the roster remains fresh even
    -- when an administrator reproduces a maze with lod_campaign_seed.
    return LOD.Seeds.Normalize(os.time() * 1000 + defaultRosterSeedCounter * 104729 + 7919)
end

function RunManager:_PrepareCharacterOrder()
    local order = {}
    for i, character in ipairs(CC.Models.Characters) do order[i] = character end
    local rng = LOD.RNG.New(LOD.Seeds.Derive(self.State.CampaignSeed, "characters"))
    rng:Shuffle(order)
    self.State.CharacterOrder = order
end

function RunManager:_ValidateConfiguredModels()
    local invalid = {}
    if not util.IsValidModel(CC.Models.Deborah) then invalid[#invalid + 1] = CC.Models.Deborah end
    if LOD.Damsels then
        for _,model in ipairs(LOD.Damsels.Models) do if not util.IsValidModel(model) then invalid[#invalid+1]=model end end
        if not util.IsValidModel(LOD.Damsels.CashModel) then invalid[#invalid+1]=LOD.Damsels.CashModel end
    end
    for _, character in ipairs(CC.Models.Characters) do
        if not util.IsValidModel(character.model) then invalid[#invalid + 1] = character.model end
    end
    if #invalid > 0 then
        ErrorNoHalt("[LOD] Invalid configured model path(s): " .. table.concat(invalid, ", ") .. "\n")
    end
end

function RunManager:_PlayedCount()
    return table.Count(self.State.PlayedIdentities or {})
end

function RunManager:_ActiveCount()
    local count = 0
    for _, active in pairs(self.State.ActiveIdentity or {}) do if active then count = count + 1 end end
    return count
end

function RunManager:IsSoldierControl(ply)
    if not IsValid(ply) then return false end
    local system = LOD.SoldierProgression
    return system and system:StateFor(ply) ~= nil or false
end

function RunManager:IsHeroRevivalQueueEligible(plyOrIdentity)
    local id = isstring(plyOrIdentity) and plyOrIdentity or self:IdentityOf(plyOrIdentity)
    if not id then return false end
    local ps = self.State and self.State.PlayerState and self.State.PlayerState[id]
    if not ps or not ps.eliminated or (ps.lives or 0) > 0 then
        return false
    end

    local ply = self.ConnectedPlayerForIdentity and self:ConnectedPlayerForIdentity(id)
    if not ply then
        for _, p in ipairs(player.GetAll()) do
            if self:IdentityOf(p) == id then ply = p break end
        end
    end

    if IsValid(ply) then
        if self:IsSoldierControl(ply) then
            return false
        end
    end

    if ps.queue == "soldier" or ps.soldierRespawnWait == true then
        return false
    end

    if ps.respawnAt and ps.respawnAt > CurTime() then
        return false
    end

    return true
end

function RunManager:AttachSoldier(ply, seed, hp, level)
    local system = LOD.SoldierProgression
    if not system or not IsValid(ply) then return nil end
    local archetype = CC.Encounter and CC.Encounter.Archetypes and CC.Encounter.Archetypes.soldier
    local baseHp = hp or (archetype and archetype.baseHP) or 35
    level = level or math.max(1, math.floor(tonumber(self.State and self.State.Level) or 1))
    seed = seed or LOD.Seeds.Derive(self.State.LevelSeed or 1, "soldier:" .. (self:IdentityOf(ply) or "0") .. ":" .. math.floor(CurTime()))
    return system:Attach(ply, seed, baseHp, level)
end

function RunManager:RetireSoldier(target)
    local system = LOD.SoldierProgression
    if not system then return false end
    return system:Retire(target)
end

function RunManager:_SyncPlayerVars(ply)
    if not IsValid(ply) then return end
    local id = self:IdentityOf(ply)
    local ps = id and self.State.PlayerState[id]
    local isSoldier = self:IsSoldierControl(ply)
    ply:SetNW2Bool("LOD_PlayedIdentity", ps ~= nil)
    ply:SetNW2Int("LOD_Lives", ps and ps.lives or 0)
    ply:SetNW2Bool("LOD_Eliminated", ps and ps.eliminated == true or false)
    ply:SetNW2Int("LOD_HeroSerial", ps and ps.ordinal or 0)
    ply:SetNW2Bool("LOD_SoldierWaiting", ps and ps.soldierRespawnWait == true or false)
    local previousSoldier=ply.LODWallCollisionSoldier
    ply.LODWallCollisionSoldier=isSoldier
    ply:SetNW2Bool("LOD_IsSoldier", isSoldier)
    if previousSoldier~=isSoldier and ply.CollisionRulesChanged then ply:CollisionRulesChanged() end
    local package = ps and ps.progressionState and ps.progressionState.characterIdentityPackage
    ply:SetNW2String("LOD_HeroName", package and package.fullDisplayName or ps and ps.characterName or "Spectator")
    if isSoldier then
        ply:SetNW2String("LOD_Character", "Human Soldier")
    else
        ply:SetNW2String("LOD_Character", ps and ps.characterName or "Spectator")
    end
    if LOD.CharacterProgressionSystem and LOD.CharacterProgressionSystem.SyncPlayer then
        LOD.CharacterProgressionSystem:SyncPlayer(ply)
    end
    if LOD.ProgressionDirector then LOD.ProgressionDirector:SyncPlayer(ply) end
end

function RunManager:_AdmitIdentity(ply, generation)
    local id = self:IdentityOf(ply)
    if not id or self.State.PlayedIdentities[id] then return self.State.PlayerState[id] end

    local ordinal = (self.State.HeroSerial or self:_PlayedCount()) + 1
    self.State.HeroSerial = ordinal
    local order = self.State.CharacterOrder or {}
    local character = #order > 0 and order[(ordinal - 1) % #order + 1]
    if not character then return nil end

    local ps = {
        identity = id,
        ordinal = ordinal,
        heroGeneration = generation or 1,
        lives = CC.Lives.StartingLives,
        eliminated = false,
        eliminatedSince = nil,
        respawnAt = nil,
        characterId = character.id,
        characterName = character.name,
        model = character.model,
        inventory = nil,
        armor = 0,
        lastPlayerName = IsValid(ply) and ply:Nick() or nil
    }

    self.State.PlayedIdentities[id] = true
    self.State.PlayerState[id] = ps
    self.State.CharacterByIdentity[id] = character
    if LOD.CharacterProgressionSystem and LOD.CharacterProgressionSystem.InitializeHero then
        LOD.CharacterProgressionSystem:InitializeHero(self, ps, character)
    end
    self:_SyncPlayerVars(ply)
    return ps
end

function RunManager:IsPlayedIdentity(ply)
    local id = self:IdentityOf(ply)
    return id and self.State.PlayedIdentities[id] == true
end

function RunManager:IsActivePlayer(ply)
    local id = self:IdentityOf(ply)
    return id and self.State.ActiveIdentity[id] == true
end

function RunManager:_FindLivingSpectateTarget(ply)
    for _, candidate in ipairs(player.GetAll()) do
        if candidate ~= ply and self:IsActivePlayer(candidate) and candidate:Alive() then return candidate end
    end
end

function RunManager:PutInRestrictedSpectator(ply)
    if not IsValid(ply) then return end
    local target = self:_FindLivingSpectateTarget(ply)
    if IsValid(target) then
        ply:Spectate(OBS_MODE_CHASE)
        ply:SpectateEntity(target)
    else
        ply:Spectate(OBS_MODE_FIXED)
        ply:SpectateEntity(NULL)
        local pos = self.State.CheckpointPos or (self.State.BuildReport and self.State.BuildReport.startPos)
        if pos then ply:SetPos(pos) end
    end
    self:_SyncPlayerVars(ply)
end

function RunManager:TryActivatePlayer(ply)
    if not IsValid(ply) or self.State.Failed then return false end
    if not self.State.CampaignSeed or not self.State.CharacterOrder then return false end

    local id = self:IdentityOf(ply)
    if not id then return false end
    if self.State.ActiveIdentity[id] then return true end

    local ps = self.State.PlayerState[id]
    if ps and (ps.eliminated or ps.lives <= 0) then
        self.State.WaitingSince[id] = self.State.WaitingSince[id] or CurTime()
        self:PutInRestrictedSpectator(ply)
        return false
    end

    if self:_ActiveCount() >= CC.MaxActivePlayers then
        self.State.WaitingSince[id] = self.State.WaitingSince[id] or CurTime()
        self:PutInRestrictedSpectator(ply)
        return false
    end

    if not ps then
        if not self.State.BuildReady then
            self.State.WaitingSince[id] = self.State.WaitingSince[id] or CurTime()
            self:PutInRestrictedSpectator(ply)
            return false
        end
        ps = self:_AdmitIdentity(ply)
        if not ps then
            self:PutInRestrictedSpectator(ply)
            return false
        end
    end

    self.State.ActiveIdentity[id] = true
    self.State.WaitingSince[id] = nil
    self:_SyncPlayerVars(ply)
    return true
end

function RunManager:ReleasePlayer(ply)
    local id = self:IdentityOf(ply)
    if id then self.State.ActiveIdentity[id] = nil end
end

function RunManager:_SortedConnectedPlayers()
    local list = player.GetAll()
    table.sort(list, function(a, b)
        local pa = self:GetPlayerState(a)
        local pb = self:GetPlayerState(b)
        local oa = pa and pa.ordinal or 100000 + a:EntIndex()
        local ob = pb and pb.ordinal or 100000 + b:EntIndex()
        return oa < ob
    end)
    return list
end

function RunManager:_SortedHeroQueueCandidates()
    local candidates = {}
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            local id = self:IdentityOf(ply)
            local ps = id and self.State.PlayerState[id]
            if not self:IsActivePlayer(ply) then
                local isEliminatedHero = ps and ps.eliminated == true and (ps.lives or 0) <= 0
                local eliminatedSince = isEliminatedHero and (ps.eliminatedSince or math.huge) or math.huge
                local waitingSince = self.State.WaitingSince[id] or math.huge
                table.insert(candidates, {
                    ply = ply,
                    id = id,
                    ps = ps,
                    isEliminatedHero = isEliminatedHero,
                    eliminatedSince = eliminatedSince,
                    waitingSince = waitingSince,
                    ordinal = ps and ps.ordinal or (100000 + ply:EntIndex())
                })
            end
        end
    end
    table.sort(candidates, function(a, b)
        if a.isEliminatedHero ~= b.isEliminatedHero then
            return a.isEliminatedHero
        end
        if a.isEliminatedHero then
            if a.eliminatedSince ~= b.eliminatedSince then
                return a.eliminatedSince < b.eliminatedSince
            end
        else
            if a.waitingSince ~= b.waitingSince then
                return a.waitingSince < b.waitingSince
            end
        end
        return a.ordinal < b.ordinal
    end)
    return candidates
end

function RunManager:_ActiveSoldierCount()
    local count = 0
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and self:IsSoldierControl(ply) then
            count = count + 1
        end
    end
    return count
end

function RunManager:JoinSoldierRole(ply)
    if not IsValid(ply) or not self.State.BuildReady or self.State.Failed then return false, "invalid state" end
    local id = self:IdentityOf(ply)
    local ps = id and self.State.PlayerState[id]
    if not ps or not ps.eliminated or (ps.lives or 0) > 0 then
        return false, "only eliminated heroes can join soldier role"
    end
    if self:IsSoldierControl(ply) then
        return true, "already controlling soldier"
    end
    if ps.respawnAt and ps.respawnAt > CurTime() then
        return false, "soldier respawn delay active"
    end
    local maxSoldiers = CC.MaxActiveSoldiers or 6
    if self:_ActiveSoldierCount() >= maxSoldiers then
        return false, "soldier slots full"
    end

    local soldierState, err = self:AttachSoldier(ply)
    if not soldierState then return false, err or "failed to attach soldier" end

    ps.queue = "soldier"
    ps.soldierRespawnWait = nil
    ply:UnSpectate()
    ply:Spawn()
    return true
end

function RunManager:ReturnToHeroQueue(ply)
    if not IsValid(ply) then return false, "invalid player" end
    local id = self:IdentityOf(ply)
    local ps = id and self.State and self.State.PlayerState and self.State.PlayerState[id]
    if not ps then return false, "no player state" end

    local isSol = self:IsSoldierControl(ply)
    local inWait = ps.soldierRespawnWait == true or (ps.respawnAt and ps.respawnAt > CurTime() and ps.eliminated == true)

    if not isSol and not inWait and (not ps.eliminated and (ps.lives or 0) > 0) then
        return false, "active hero cannot return to hero queue"
    end

    if isSol then
        self:RetireSoldier(ply)
    end

    if isSol and ply.StripWeapons then ply:StripWeapons() end
    ply.LODRunInventoryReady = false
    ps.queue = "hero"
    ps.soldierRespawnWait = nil
    ps.respawnAt = nil
    ps.eliminated = true
    ps.lives = 0

    self:PutInRestrictedSpectator(ply)
    self:_SyncPlayerVars(ply)
    return true
end

function RunManager:BeginNewHero(ply)
    local state, old = self.State, self:GetPlayerState(ply)
    if not IsValid(ply) or not old or not old.eliminated or (old.lives or 0) > 0
        or not state.BuildReady or state.Failed or state.LevelCleared then
        return false, "Only an eliminated Hero can begin again."
    end
    if self:_ActiveCount() >= CC.MaxActivePlayers then return false, "All Hero slots are occupied." end
    if LOD.CampaignTimeout and LOD.CampaignTimeout:Expire() then return false, "Time over." end
    local id = old.identity
    self:RetireSoldier(ply)
    if LOD.Equipment and LOD.Equipment.ClearTransient then LOD.Equipment:ClearTransient(ply) end
    if LOD.RPGStatusElements then LOD.RPGStatusElements:ResetActorLife(ply) end
    ply.LODRunInventoryReady = false
    ply:StripWeapons()
    if ply.RemoveAllAmmo then ply:RemoveAllAmmo() end
    local staging = LOD.StagingDeployment
    local starter = staging and staging.StarterEntities and staging.StarterEntities[id]
    if IsValid(starter) then starter:Remove() end
    if staging and staging.StarterEntities then staging.StarterEntities[id] = nil end
    state.ActiveIdentity[id], state.PlayedIdentities[id], state.PlayerState[id] = nil, nil, nil
    local ps = self:_AdmitIdentity(ply, (old.heroGeneration or 1) + 1)
    if not ps then
        state.PlayerState[id], state.PlayedIdentities[id] = old, true
        self:PutInRestrictedSpectator(ply)
        return false, "Hero creation unavailable."
    end
    -- Keep the retired identity in this party run without retaining its usable
    -- inventory, lives or progression. Failed/replayed replacements add nothing.
    state.RetiredPartyMembers = state.RetiredPartyMembers or {}
    state.RetiredPartyMembers[#state.RetiredPartyMembers + 1] = {
        text = self:PartyMemberText(old), ordinal = old.ordinal or 0,
        identity = old.identity, generation = old.heroGeneration or 1
    }
    -- Account-bound damsel/DFT/crypto claims are deliberately outside ps.
    ps.queue = "hero"
    self:TryActivatePlayer(ply)
    ply:UnSpectate()
    ply:Spawn()
    return true
end

function RunManager:PromoteWaitingSpectators()
    if not self.State.BuildReady or self.State.Failed then return 0 end
    local promotedCount = 0
    local candidates = self:_SortedHeroQueueCandidates()
    for _, item in ipairs(candidates) do
        if self:_ActiveCount() >= CC.MaxActivePlayers then break end
        local ply = item.ply
        if IsValid(ply) and not self:IsActivePlayer(ply) then
            local ps = item.ps
            if ps and not ps.eliminated and (ps.lives or 0) > 0 then
                if self:TryActivatePlayer(ply) then
                    promotedCount = promotedCount + 1
                    if self:IsSoldierControl(ply) then
                        self:RetireSoldier(ply)
                    end
                    if ps.respawnAt and ps.respawnAt > CurTime() then
                        self:PutInRestrictedSpectator(ply)
                    else
                        ply:UnSpectate()
                        ply:Spawn()
                    end
                end
            elseif not ps then
                if self:TryActivatePlayer(ply) then
                    promotedCount = promotedCount + 1
                    ply:UnSpectate()
                    ply:Spawn()
                end
            end
        end
    end
    return promotedCount
end

function RunManager:CaptureInventory(ply, ps, allowDead)
    ps = ps or self:GetPlayerState(ply)
    if not IsValid(ply) or not ps or self:IsSoldierControl(ply)
        or ply.LODRunInventoryReady == false then return end

    -- PlayerDeath runs after Alive() becomes false, while the player's weapon
    -- entities still hold the authoritative magazines. Only that hook opts in;
    -- a later disconnect must never replace a good snapshot with an empty body.
    if not allowDead and not ply:Alive() then return end
    local snapshot = {weapons = {}, ammo = {}}
    local activeWeapon = ply:GetActiveWeapon()
    for _, wep in ipairs(ply:GetWeapons()) do
        if IsValid(wep) and wep:GetClass() ~= "weapon_frag"
            and wep:GetClass() ~= "weapon_lod_throwable" and wep:GetClass() ~= "weapon_lod_empty_hands" then
            local class = wep:GetClass()
            snapshot.weapons[#snapshot.weapons + 1] = {
                class = class,
                clip1 = wep:Clip1(),
                clip2 = wep:Clip2()
            }
            if wep == activeWeapon then snapshot.activeWeaponClass = class end
        end
    end
    for ammoID, amount in pairs(ply:GetAmmo()) do
        if game.GetAmmoName(ammoID) ~= "Grenade" then snapshot.ammo[ammoID] = amount end
    end
    ps.inventory = snapshot
    ps.armor = ply:Armor()
end

function RunManager:RestoreInventory(ply, ps)
    if not IsValid(ply) or not ps or not ps.inventory then return end
    ply:StripWeapons()
    ply:RemoveAllAmmo()

    for _, weaponState in ipairs(ps.inventory.weapons or {}) do
        local allowed = weaponState.class ~= "weapon_frag" and weaponState.class ~= "weapon_lod_throwable" and weaponState.class ~= "weapon_lod_empty_hands"
        local wep
        if allowed then
            -- Reconstruct an owned weapon, without admitting another bag item or
            -- inspecting a half-constructed native entity in the pickup hook.
            ply.LODInventoryNativeRestore = weaponState.class
            local ok, result = pcall(ply.Give, ply, weaponState.class, true)
            ply.LODInventoryNativeRestore = nil
            if not ok then error(result) end
            wep = result
        end
        if IsValid(wep) then
            if weaponState.clip1 and weaponState.clip1 >= 0 then wep:SetClip1(weaponState.clip1) end
            if weaponState.clip2 and weaponState.clip2 >= 0 then wep:SetClip2(weaponState.clip2) end
        end
    end
    for ammoID, amount in pairs(ps.inventory.ammo or {}) do
        if game.GetAmmoName(ammoID) ~= "Grenade" then ply:SetAmmo(amount, ammoID) end
    end
    local activeClass = ps.inventory.activeWeaponClass
    if activeClass and ply:HasWeapon(activeClass) then ply:SelectWeapon(activeClass) end
end

function RunManager:HoldPlayersForBuild()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            local ps = self:GetPlayerState(ply)
            if ps and ply:Alive() then self:CaptureInventory(ply, ps) end
            ply.LODRunInventoryReady = false
            ply:Spectate(OBS_MODE_FIXED)
            ply:SpectateEntity(NULL)
            ply:SetPos(CC.Maze.Origin + Vector(0, 0, 128))
        end
    end
end

function RunManager:NewCampaign()
    local customSeed = cvSeed:GetInt()
    local customRosterSeed = cvRosterSeed:GetInt()
    local developerMode = GetConVar("lod_developer_mode")
    local customRosterAllowed = customRosterSeed ~= 0 and developerMode and developerMode:GetBool()
    self.CampaignEpoch = self.CampaignEpoch + 1
    self.State = freshState(self.CampaignEpoch)
    self.State.Ranked = customSeed == 0
    self.State.UnrankedReason = customSeed == 0 and nil or "custom campaign seed"
    self.State.CampaignSeed = customSeed ~= 0 and LOD.Seeds.Normalize(customSeed) or self:_DefaultSeed()
    self.State.RosterSeed = customRosterAllowed
        and LOD.Seeds.Normalize(customRosterSeed) or self:_DefaultRosterSeed()
    self.State.RescueCount = 0
    self.State.RunId = "run_" .. tostring(self.State.CampaignSeed) .. "_epoch_" .. tostring(self.CampaignEpoch)
    if LOD.CryptoStore and LOD.CryptoStore.Ready then
        local ok,id=pcall(LOD.CryptoStore.NextRunID,LOD.CryptoStore)
        if ok then self.State.RunId=id else
            self:MarkUnranked("wallet run identity unavailable")
            ErrorNoHalt("[LOD:WALLET] "..tostring(id).."\n")
        end
    end
    if customRosterAllowed then
        self.State.Ranked = false
        self.State.UnrankedReason = self.State.UnrankedReason or "custom roster seed"
    elseif customRosterSeed ~= 0 then
        ErrorNoHalt("[LOD:RPG] lod_roster_seed ignored because developer mode is disabled.\n")
    end
    if LOD.CharacterProgressionSystem and LOD.CharacterProgressionSystem.PrepareCampaignState then
        LOD.CharacterProgressionSystem:PrepareCampaignState(self.State)
    end
    self:_PrepareCharacterOrder()
    self:_ValidateConfiguredModels()
    return self:BuildCurrentLevel()
end

function RunManager:_GenerateProgressionLevel(masterLevelSeed)
    local lastErr = "unknown progression planning failure"
    for layoutAttempt = 1, CC.Progression.LayoutAttempts do
        local layoutSeed = layoutAttempt == 1 and masterLevelSeed or
            LOD.Seeds.Derive(masterLevelSeed, "progression-layout:" .. layoutAttempt)
        local graph, mazeErr = LOD.MazeGenerator:Generate(layoutSeed)
        if graph then
            graph.MasterLevelSeed = masterLevelSeed
            graph.ProgressionLayoutAttempt = layoutAttempt
            local planned, planErr = LOD.ProgressionDirector:Plan(graph, masterLevelSeed)
            if planned then return graph end
            lastErr = planErr
        else
            lastErr = mazeErr
        end
    end
    return nil, "failed to produce progression-safe level: " .. tostring(lastErr)
end

function RunManager:BuildCurrentLevel(levelSeedOverride)
    if game.GetMap() ~= "gm_flatgrass" then
        self.State.BuildReady = false
        return false, "The Legend of Deborah v1 requires gm_flatgrass"
    end

    self.State.BuildReady = false
    if LOD.Damsels then self.State.RescueTarget = LOD.Damsels:Target(self.State.Level) end
    self.State.HighestLevel = math.max(self.State.HighestLevel or 1, self.State.Level)
    self:HoldPlayersForBuild()
    local levelSeed = levelSeedOverride or LOD.Seeds.DeriveLevel(self.State.CampaignSeed, self.State.Level)
    if levelSeedOverride then self:MarkUnranked("debug level-seed override") end
    self.State.LevelSeed = LOD.Seeds.Normalize(levelSeed)

    local totalStarted = SysTime()
    local generationStarted = SysTime()
    local graph, err = self:_GenerateProgressionLevel(self.State.LevelSeed)
    local generationSeconds = SysTime() - generationStarted
    if not graph then return false, err end

    LOD.ProgressionDirector:ResetLevelState(graph)
    local buildStarted = SysTime()
    local ok, buildReport = LOD.MazeBuilder:Build(graph)
    local buildSeconds = SysTime() - buildStarted
    if not ok then return false, buildReport end

    buildReport.generationSeconds = generationSeconds
    buildReport.buildSeconds = buildSeconds
    buildReport.totalSeconds = SysTime() - totalStarted

    self.State.Graph = graph
    self.State.BuildReport = buildReport
    self.State.BuildReady = true
    for _, ps in pairs(self.State.PlayerState or {}) do
        local progression = ps.progressionState
        if progression then
            progression.dungeonEntryLevel = progression.level
            progression.replacementXpEarnedThisDungeon = 0
        end
    end
    LOD.ProgressionDirector:CommitBuiltLevel(buildReport)

    for _, ply in ipairs(self:_SortedConnectedPlayers()) do
        local active = self:TryActivatePlayer(ply)
        local ps = self:GetPlayerState(ply)
        if active and ps and not ps.eliminated then
            if ps.respawnAt and ps.respawnAt > CurTime() then
                self:PutInRestrictedSpectator(ply)
            else
                ply:UnSpectate()
                ply:Spawn()
            end
        else
            self:PutInRestrictedSpectator(ply)
        end
    end
    self:PromoteWaitingSpectators()

    print(string.format(
        "[LOD] Level %d ready. campaign=%d levelSeed=%d layoutAttempt=%d cells=%d entities=%d vertical=%d mazeAttempt=%d gen+progression=%.3fs build=%.3fs total=%.3fs",
        self.State.Level,
        self.State.CampaignSeed,
        self.State.LevelSeed,
        graph.ProgressionLayoutAttempt or 1,
        graph.Validation.cellCount,
        buildReport.entityCount,
        graph.Validation.criticalVerticalTransitions,
        graph.Attempt,
        buildReport.generationSeconds,
        buildReport.buildSeconds,
        buildReport.totalSeconds
    ))
    return true, graph
end

function RunManager:ApplyPlayerState(ply)
    if not IsValid(ply) or not ply:Alive() or not self.State.BuildReady then return end
    local slotActive = self.IsSlotActivePlayer
        and self:IsSlotActivePlayer(ply) or self:IsActivePlayer(ply)
    local ps = self:GetPlayerState(ply)

    if self:IsSoldierControl(ply) then
        ply:UnSpectate()
        ply:SetTeam(CC.PlayerTeam)
        ply:SetNoCollideWithTeammates(true)
        ply:CollisionRulesChanged()

        local soldierModel = "models/player/combine_soldier.mdl"
        if not util.IsValidModel(soldierModel) then
            soldierModel = "models/combine_soldier.mdl"
        end
        if util.IsValidModel(soldierModel) then
            ply:SetModel(soldierModel)
        end

        local soldierState = LOD.SoldierProgression and LOD.SoldierProgression:StateFor(ply)
        local baseFallback = CC.Encounter and CC.Encounter.Archetypes and CC.Encounter.Archetypes.soldier and CC.Encounter.Archetypes.soldier.baseHP or 35
        local maxHP = math.max(1, soldierState and soldierState.derivedStats and soldierState.derivedStats.maxHP or baseFallback)
        ply:SetMaxHealth(maxHP)
        ply:SetHealth(maxHP)
        ply:SetArmor(0)

        ply:StripWeapons()
        ply:RemoveAllAmmo()
        local wep = ply:Give("weapon_smg1", true)
        if IsValid(wep) then
            ply:SetAmmo(90, wep:GetPrimaryAmmoType())
        end

        ps.respawnAt = nil
        ps.soldierRespawnWait = nil
        self:_SyncPlayerVars(ply)
        ply:SetNW2Bool("LOD_Staged", false)
        ply:SetNW2Bool("LOD_Deployed", true)
        ply:SetPos(self.State.CheckpointPos or (self.State.BuildReport and self.State.BuildReport.startPos) or Vector(0, 0, 0))
        ply:SetEyeAngles(Angle(0, 0, 0))
        return
    end

    if not slotActive or not ps or ps.eliminated or (ps.lives or 0) <= 0 then
        self:PutInRestrictedSpectator(ply)
        return
    end

    if self:IsSoldierControl(ply) then
        self:RetireSoldier(ply)
    end

    ply:UnSpectate()
    ply:SetTeam(CC.PlayerTeam)
    ply:SetNoCollideWithTeammates(true)
    ply:CollisionRulesChanged()
    if ps.model then ply:SetModel(ps.model) end
    local progression = ps.progressionState
    local maximumHealth = math.max(1, progression and progression.derivedStats
        and progression.derivedStats.maxHP or 100)
    ply:SetMaxHealth(maximumHealth)
    -- Respawn health and earned temporary overfill commit together. A delayed
    -- Tetris callback must not overwrite RPG MaxHP or a later Soldier body.
    local overfill = math.max(0, math.floor(tonumber(ps.nextLifeHPBonus) or 0))
    ps.nextLifeHPBonus = 0
    ply:SetHealth(maximumHealth + overfill)
    ply:SetNW2Int("LOD_TetrisNextLifeBonus", 0)
    ply:SetArmor(ps.armor or 0)
    if ps.deploymentComplete then ps.deployedDungeonLevel = self.State.Level end
    self:RestoreInventory(ply, ps)
    ply.LODRunInventoryReady = true
    ps.respawnAt = nil
    self:_SyncPlayerVars(ply)

    if ps.deploymentComplete ~= true then
        local staging = LOD.StagingDeployment
        if staging and staging.PlacePlayerInHut
            and staging:PlacePlayerInHut(ply, true)
        then
            return
        end

        ErrorNoHalt("[LOD:STAGING] Undeployed player placement failed; maze checkpoint withheld.\n")
        return
    end

    ply:SetNW2Bool("LOD_Staged", false)
    ply:SetNW2Bool("LOD_Deployed", true)
    ply:SetPos(self.State.CheckpointPos or self.State.BuildReport.startPos)
    ply:SetEyeAngles(Angle(0, 0, 0))
end

function RunManager:HandleDeath(ply, attacker)
    if not IsValid(ply) or self.State.Failed then return end
    if ply.LODHandledRunDeath then return end

    local id = self:IdentityOf(ply)
    local ps = id and self.State.PlayerState[id]

    if self:IsSoldierControl(ply) then
        ply.LODHandledRunDeath = true
        self:RetireSoldier(ply)
        if ps then
            ps.respawnAt = CurTime() + CC.Lives.RespawnDelay
            ps.soldierRespawnWait = true
        end
        self:_SyncPlayerVars(ply)
        local deathEpoch = self.State.CampaignEpoch
        timer.Simple(0, function()
            if self:IsCampaignEpoch(deathEpoch) and IsValid(ply) and not ply:Alive() then
                self:PutInRestrictedSpectator(ply)
            end
        end)
        self:PromoteWaitingSpectators()
        self:RequestWipeEvaluation()
        return
    end

    if not self:IsPlayedIdentity(ply) or not self:IsActivePlayer(ply) or not ps then return end
    ply.LODHandledRunDeath = true

    ps.lives = math.max(0, ps.lives - 1)
    if LOD.CryptoDirector then LOD.CryptoDirector:HeroLifeConsumed(ply, attacker) end
    if LOD.SoldierProgression and LOD.SoldierProgression.ObserveHeroLifeConsumed then
        LOD.SoldierProgression:ObserveHeroLifeConsumed(attacker, ply)
    end
    ps.respawnAt = nil

    if ps.lives > 0 then
        ps.respawnAt = CurTime() + CC.Lives.RespawnDelay
    else
        ps.eliminated = true
        ps.queue = "hero"
        ps.eliminatedSince = ps.eliminatedSince or CurTime()
        self.State.ActiveIdentity[id] = nil
        ps.respawnAt = nil
        ps.soldierRespawnWait = nil
    end

    self:_SyncPlayerVars(ply)
    local deathEpoch = self.State.CampaignEpoch
    timer.Simple(0, function()
        if self:IsCampaignEpoch(deathEpoch) and IsValid(ply) and not ply:Alive() then
            self:PutInRestrictedSpectator(ply)
        end
    end)

    if ps.eliminated then self:PromoteWaitingSpectators() end
    self:RequestWipeEvaluation()
end

function RunManager:RequestWipeEvaluation()
    local state = self.State
    if state.WipeEvaluationPending or state.Failed then return end
    state.WipeEvaluationPending = true
    timer.Simple(0, function()
        state.WipeEvaluationPending = nil
        if self.State == state then self:EvaluateWipe() end
    end)
end

function RunManager:_ConnectedPlayedPlayers()
    local connected = {}
    for _, ply in ipairs(player.GetAll()) do
        if self:IsPlayedIdentity(ply) then connected[#connected + 1] = ply end
    end
    return connected
end

function RunManager:UpdateFreezeState()
    local connected = self:_ConnectedPlayedPlayers()
    if #connected == 0 then
        if not self.State.SimulationFrozen then
            self.State.SimulationFrozen = true
            self.State.FreezeStarted = CurTime()
        end
        return true
    end

    if self.State.SimulationFrozen then
        local delta = math.max(0, CurTime() - (self.State.FreezeStarted or CurTime()))
        for _, ps in pairs(self.State.PlayerState) do
            if ps.respawnAt then ps.respawnAt = ps.respawnAt + delta end
        end
        if self.State.IntermissionEnd then self.State.IntermissionEnd = self.State.IntermissionEnd + delta end
        self.State.SimulationFrozen = false
        self.State.FreezeStarted = nil
    end
    return false
end

function RunManager:EvaluateWipe()
    -- Retain this shared seam for death/disconnect callers. Only the dungeon
    -- clock can fail a campaign; an empty Hero queue is recoverable.
    self:UpdateFreezeState()
    return false
end

function RunManager:PartyMemberText(ps)
    local progression = LOD.CharacterProgressionSystem
    if progression and progression.PlayerCharacterText then
        return progression:PlayerCharacterText(ps)
    end
    return (ps.lastPlayerName or "Unknown Player") .. " as " .. (ps.characterName or "Hero")
end

-- One participant projection for live rankings and immutable completed runs.
function RunManager:PartyRunMembers()
    local state = self.State or {}
    local members = {}
    for _, member in ipairs(state.RetiredPartyMembers or {}) do
        members[#members + 1] = member
    end
    for id, played in pairs(state.PlayedIdentities or {}) do
        local ps = played and state.PlayerState and state.PlayerState[id]
        if ps then
            members[#members + 1] = {text = self:PartyMemberText(ps),
                ordinal = ps.ordinal or 0, identity = id, generation = ps.heroGeneration or 1}
        end
    end
    table.sort(members, function(a, b)
        if a.ordinal ~= b.ordinal then return a.ordinal < b.ordinal end
        if a.identity ~= b.identity then return a.identity < b.identity end
        return a.generation < b.generation
    end)
    local party = {}
    for _, member in ipairs(members) do party[#party + 1] = member.text end
    return party
end

function RunManager:FinalizeCampaignRun()
    if not self.State or self.State.Finalized then return false end
    self.State.Finalized = true

    if self.State.Ranked ~= true then
        return false
    end

    if not LOD.HeroesOfLegend or not LOD.HeroesOfLegend.SubmitRun then
        return false
    end

    local partyMembers = self:PartyRunMembers()

    if #partyMembers == 0 then
        return false
    end

    local runId = self.State.RunId or ("run_" .. tostring(self.State.CampaignSeed or 1000) .. "_epoch_" .. tostring(self.CampaignEpoch or 1))
    LOD.HeroesOfLegend:SubmitRun({
        runId = runId,
        rescueCount = self.State.RescueCount or 0,
        highestLevel = self.State.HighestLevel or self.State.Level,
        cashRecovered = self.State.CashRecovered or 0,
        partyMembers = partyMembers
    })

    return true
end

function RunManager:FailCampaign(reason)
    if self.State.Failed then return end
    self.State.Failed = true
    self.State.FailureReason = reason or "campaign failure"
    self:FinalizeCampaignRun()
    if self.State.CampaignClock and self.State.CampaignClock.scene then
        -- Expiry may be detected by a rescue Touch/Use callback. The timeout
        -- service performs native player/entity changes on Think after this
        -- authoritative failure/finalization has committed.
    else
        for _, ply in ipairs(player.GetAll()) do self:PutInRestrictedSpectator(ply) end
    end
    if LOD.ProgressionDirector then
        LOD.ProgressionDirector:Announce("CAMPAIGN FAILED — " .. string.upper(self.State.FailureReason))
        LOD.ProgressionDirector:SyncAll()
    end
    print(string.format("[LOD] Campaign failed at Level %d. seed=%s reason=%s", self.State.Level, tostring(self.State.CampaignSeed), self.State.FailureReason))
end

function RunManager:CompleteLevel(ply)
    if self.State.Failed or self.State.LevelCleared or not self.State.BuildReady then return false end
    if not IsValid(ply) or not ply:Alive() or not self:IsActivePlayer(ply) then return false end

    for _, candidate in ipairs(player.GetAll()) do
        local ps = self:GetPlayerState(candidate)
        if ps and candidate:Alive() then self:CaptureInventory(candidate, ps) end
    end

    local rescueXP = 500 + 100 * math.min(self.State.Level or 1, 20)
    local progression = LOD.CharacterProgressionSystem
    for identity, ps in pairs(self.State.PlayerState or {}) do
        local deployed = ps.deployedDungeonLevel == self.State.Level
            or ps.deployedAtLevel == self.State.Level
        if deployed and progression and progression.AwardHeroXP then
            progression:AwardHeroXP(identity, rescueXP)
        end
    end

    if LOD.Damsels then
        self.State.RescueTarget = LOD.Damsels:Target(self.State.Level)
        if self.State.RescueTarget.type == "damsel" then
            self.State.RescuedDamsels = self.State.RescuedDamsels or {}
            self.State.RescuedDamsels[self.State.Level] = true
            self.State.RescueCount = table.Count(self.State.RescuedDamsels)
            if self.State.Level == 20 then self.State.Abundance = true end
        else self.State.CashRecovered = (self.State.CashRecovered or 0) + 1 end
    else self.State.RescueCount = (self.State.RescueCount or 0) + 1 end
    self.State.LevelCleared = true
    self.State.IntermissionEnd = CurTime() + CC.Progression.IntermissionSeconds

    LOD.ProgressionDirector:Announce(string.format("%s — LEVEL %d CLEAR",
        self.State.RescueTarget and self.State.RescueTarget.victory or "OBJECTIVE SECURED", self.State.Level))
    LOD.ProgressionDirector:SyncAll()
    print(string.format("[LOD] Level %d cleared by %s; advancing in %d seconds", self.State.Level, ply:Nick(), CC.Progression.IntermissionSeconds))
    return true
end

function RunManager:AdvanceLevel()
    if not self.State.LevelCleared or self.State.Failed then return false end

    self.State.Level = self.State.Level + 1
    self.State.IntermissionEnd = nil
    self.State.LevelCleared = false
    self.State.ActiveIdentity = {}

    for _, ply in ipairs(player.GetAll()) do
        -- Retirement removes the role marker before HoldPlayersForBuild. Keep
        -- that Soldier body's weapons away from the dormant Hero snapshot.
        if self:IsSoldierControl(ply) then ply.LODRunInventoryReady = false end
        self:RetireSoldier(ply)
    end

    for _, ps in pairs(self.State.PlayerState) do
        -- Every successful maze returns through the shared hut. Preserve the
        -- identity-bound starter claim and inventory; require a new portal use.
        ps.deploymentComplete = false
        ps.stagingIntroShown = false
        ps.queue = "hero"
        ps.soldierRespawnWait = nil
        ps.respawnAt = nil
        if ps.lives <= 0 or ps.eliminated then
            ps.lives = 1
            ps.eliminated = false
            ps.eliminatedSince = nil
            ps.armor = 0
        end
    end

    local progression = LOD.CharacterProgressionSystem
    if progression and progression.ProcessBankedHeroXP then
        progression:ProcessBankedHeroXP(self)
    end

    local ok, result = self:BuildCurrentLevel()
    if not ok then
        ErrorNoHalt("[LOD] Next-level build failed: " .. tostring(result) .. "\n")
        return false
    end
    return true
end

function RunManager:Regenerate(levelSeedOverride)
    self:MarkUnranked("forced regeneration")
    local ok, result = self:BuildCurrentLevel(levelSeedOverride)
    if not ok then ErrorNoHalt("[LOD] Regeneration failed: " .. tostring(result) .. "\n") end
    return ok, result
end

hook.Add("InitPostEntity", "LOD_BeginCampaign", function()
    timer.Simple(0, function()
        local ok, err = RunManager:NewCampaign()
        if not ok then ErrorNoHalt("[LOD] Campaign startup failed: " .. tostring(err) .. "\n") end
    end)
end)

hook.Add("PlayerInitialSpawn", "LOD_PlayerInitialSpawn", function(ply)
    timer.Simple(0.25, function()
        if not IsValid(ply) then return end
        RunManager:UpdateFreezeState()
        if not RunManager.State.CampaignSeed then
            timer.Simple(0.75, function()
                if IsValid(ply) then
                    if RunManager:TryActivatePlayer(ply) and RunManager.State.BuildReady then ply:Spawn() else RunManager:PutInRestrictedSpectator(ply) end
                end
            end)
            return
        end

        if RunManager:TryActivatePlayer(ply) and RunManager.State.BuildReady then
            local ps = RunManager:GetPlayerState(ply)
            if ps and ps.respawnAt and ps.respawnAt > CurTime() then
                RunManager:PutInRestrictedSpectator(ply)
            else
                ply:Spawn()
            end
        else
            RunManager:PutInRestrictedSpectator(ply)
        end
    end)
end)

hook.Add("PlayerSpawn", "LOD_PlayerSpawn", function(ply)
    ply.LODHandledRunDeath = nil
    ply.LODRunInventoryReady = false
    ply.LODRunSpawnSerial = (ply.LODRunSpawnSerial or 0) + 1
    local serial, state, graph = ply.LODRunSpawnSerial, RunManager.State, RunManager.State.Graph
    timer.Simple(0, function()
        if IsValid(ply) and ply:Alive() and ply.LODRunSpawnSerial == serial
            and RunManager.State == state and state.Graph == graph then RunManager:ApplyPlayerState(ply) end
    end)
end)

hook.Add("PlayerDeath", "LOD_PlayerDeathLives", function(victim, inflictor, attacker)
    local ps = RunManager:GetPlayerState(victim)
    if ps and not RunManager:IsSoldierControl(victim)
        and RunManager:IsPlayedIdentity(victim) and RunManager:IsActivePlayer(victim)
    then
        RunManager:CaptureInventory(victim, ps, true)
    end
    RunManager:HandleDeath(victim, attacker)
end)

hook.Add("PlayerDisconnected", "LOD_PlayerDisconnected", function(ply)
    local ps = RunManager:GetPlayerState(ply)
    if ps and IsValid(ply) then RunManager:CaptureInventory(ply, ps) end
    RunManager:ReleasePlayer(ply)
    timer.Simple(0, function()
        RunManager:UpdateFreezeState()
        RunManager:PromoteWaitingSpectators()
        RunManager:EvaluateWipe()
    end)
end)

hook.Add("Think", "LOD_RunStateThink", function()
    if not RunManager.State.CampaignSeed or RunManager.State.Failed then return end
    if RunManager:UpdateFreezeState() or not RunManager.State.BuildReady then return end

    if RunManager.State.LevelCleared then
        if RunManager.State.IntermissionEnd and CurTime() >= RunManager.State.IntermissionEnd then RunManager:AdvanceLevel() end
        return
    end

    for _, ply in ipairs(player.GetAll()) do
        local ps = RunManager:GetPlayerState(ply)
        if ps and not ply:Alive() then
            if ps.respawnAt and CurTime() >= ps.respawnAt then
                ps.respawnAt = nil
                if ps.soldierRespawnWait then
                    ps.soldierRespawnWait = nil
                    RunManager:JoinSoldierRole(ply)
                elseif RunManager:IsActivePlayer(ply) then
                    ply:UnSpectate()
                    ply:Spawn()
                end
            end
        end
    end
end)

concommand.Add("lod_join_human_soldier", function(ply)
    if IsValid(ply) then
        local ok, err = RunManager:JoinSoldierRole(ply)
        if not ok then
            print("[LOD] JoinSoldierRole failed: " .. tostring(err))
        end
    end
end)

concommand.Add("lod_return_to_hero_queue", function(ply)
    if IsValid(ply) then
        local ok, err = RunManager:ReturnToHeroQueue(ply)
        if not ok then
            print("[LOD] ReturnToHeroQueue failed: " .. tostring(err))
        end
    end
end)

concommand.Add("lod_begin_new_hero", function(ply)
    if not IsValid(ply) then return end
    local ok, err = RunManager:BeginNewHero(ply)
    if not ok and ply.ChatPrint then ply:ChatPrint(err) end
end)

hook.Add("ShutDown", "LOD_Cleanup", function()
    LOD.MazeBuilder:Cleanup()
end)
