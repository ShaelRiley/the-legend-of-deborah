LOD = LOD or {}
LOD.RunManager = LOD.RunManager or {}

local RunManager = LOD.RunManager
local CC = LOD.Config

local cvSeed = CreateConVar("lod_campaign_seed", "0", FCVAR_ARCHIVE, "0 = time-derived campaign seed; nonzero = custom unranked seed")
local defaultSeedCounter = 0

local function freshState(campaignEpoch)
    return {
        CampaignEpoch = campaignEpoch or 0,
        CampaignSeed = nil,
        LevelSeed = nil,
        Level = 1,
        Ranked = true,
        BuildReady = false,
        Graph = nil,
        BuildReport = nil,
        CharacterByIdentity = {},
        ActiveIdentity = {},
        PlayedIdentities = {},
        PlayerState = {},
        CharacterOrder = nil,
        WaitingSince = {},
        Cards = {false, false, false},
        GatesOpen = {false, false, false},
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

function RunManager:_SyncPlayerVars(ply)
    if not IsValid(ply) then return end
    local id = self:IdentityOf(ply)
    local ps = id and self.State.PlayerState[id]
    ply:SetNW2Bool("LOD_PlayedIdentity", ps ~= nil)
    ply:SetNW2Int("LOD_Lives", ps and ps.lives or 0)
    ply:SetNW2Bool("LOD_Eliminated", ps and ps.eliminated == true or false)
    ply:SetNW2String("LOD_Character", ps and ps.characterName or "Spectator")
    if LOD.ProgressionDirector then LOD.ProgressionDirector:SyncPlayer(ply) end
end

function RunManager:_AdmitIdentity(ply)
    local id = self:IdentityOf(ply)
    if not id or self.State.PlayedIdentities[id] then return self.State.PlayerState[id] end
    if self:_PlayedCount() >= CC.Campaign.MaxPlayedIdentities then return nil end

    local ordinal = self:_PlayedCount() + 1
    local character = self.State.CharacterOrder and self.State.CharacterOrder[ordinal]
    if not character then return nil end

    local ps = {
        identity = id,
        ordinal = ordinal,
        lives = CC.Lives.StartingLives,
        eliminated = false,
        eliminatedSince = nil,
        respawnAt = nil,
        characterId = character.id,
        characterName = character.name,
        model = character.model,
        inventory = nil,
        armor = 0
    }

    self.State.PlayedIdentities[id] = true
    self.State.PlayerState[id] = ps
    self.State.CharacterByIdentity[id] = character
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
        if self:_PlayedCount() >= CC.Campaign.MaxPlayedIdentities or self.State.WardenStarted then
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

function RunManager:PromoteWaitingSpectators()
    if not self.State.BuildReady or self.State.Failed then return end
    for _, ply in ipairs(self:_SortedConnectedPlayers()) do
        if self:_ActiveCount() >= CC.MaxActivePlayers then break end
        if not self:IsActivePlayer(ply) and self:TryActivatePlayer(ply) then
            local ps = self:GetPlayerState(ply)
            if ps and ps.respawnAt and ps.respawnAt > CurTime() then
                self:PutInRestrictedSpectator(ply)
            else
                ply:UnSpectate()
                ply:Spawn()
            end
        end
    end
end

function RunManager:CaptureInventory(ply, ps)
    ps = ps or self:GetPlayerState(ply)
    if not IsValid(ply) or not ps then return end

    local snapshot = {weapons = {}, ammo = {}}
    for _, wep in ipairs(ply:GetWeapons()) do
        if IsValid(wep) then
            snapshot.weapons[#snapshot.weapons + 1] = {
                class = wep:GetClass(),
                clip1 = wep:Clip1(),
                clip2 = wep:Clip2()
            }
        end
    end
    for ammoID, amount in pairs(ply:GetAmmo()) do snapshot.ammo[ammoID] = amount end
    ps.inventory = snapshot
    ps.armor = ply:Armor()
end

function RunManager:RestoreInventory(ply, ps)
    if not IsValid(ply) or not ps or not ps.inventory then return end
    ply:StripWeapons()
    ply:RemoveAllAmmo()

    for _, weaponState in ipairs(ps.inventory.weapons or {}) do
        local wep = ply:Give(weaponState.class, true)
        if IsValid(wep) then
            if weaponState.clip1 and weaponState.clip1 >= 0 then wep:SetClip1(weaponState.clip1) end
            if weaponState.clip2 and weaponState.clip2 >= 0 then wep:SetClip2(weaponState.clip2) end
        end
    end
    for ammoID, amount in pairs(ps.inventory.ammo or {}) do ply:SetAmmo(amount, ammoID) end
end

function RunManager:HoldPlayersForBuild()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            local ps = self:GetPlayerState(ply)
            if ps and ply:Alive() then self:CaptureInventory(ply, ps) end
            ply:Spectate(OBS_MODE_FIXED)
            ply:SpectateEntity(NULL)
            ply:SetPos(CC.Maze.Origin + Vector(0, 0, 128))
        end
    end
end

function RunManager:NewCampaign()
    local customSeed = cvSeed:GetInt()
    self.CampaignEpoch = self.CampaignEpoch + 1
    self.State = freshState(self.CampaignEpoch)
    self.State.Ranked = customSeed == 0
    self.State.UnrankedReason = customSeed == 0 and nil or "custom campaign seed"
    self.State.CampaignSeed = customSeed ~= 0 and LOD.Seeds.Normalize(customSeed) or self:_DefaultSeed()
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
    if not self.State.BuildReady or not self:IsActivePlayer(ply) then return end
    local ps = self:GetPlayerState(ply)
    if not ps or ps.eliminated or ps.lives <= 0 then
        self:PutInRestrictedSpectator(ply)
        return
    end

    ply:UnSpectate()
    ply:SetTeam(CC.PlayerTeam)
    ply:SetNoCollideWithTeammates(true)
    ply:CollisionRulesChanged()
    if ps.model then ply:SetModel(ps.model) end
    ply:SetPos(self.State.CheckpointPos or self.State.BuildReport.startPos)
    ply:SetEyeAngles(Angle(0, 0, 0))
    ply:SetHealth(100)
    ply:SetArmor(ps.armor or 0)
    self:RestoreInventory(ply, ps)
    ps.respawnAt = nil
    self:_SyncPlayerVars(ply)
end

function RunManager:HandleDeath(ply)
    if not self:IsPlayedIdentity(ply) or not self:IsActivePlayer(ply) or self.State.Failed then return end
    local id = self:IdentityOf(ply)
    local ps = self.State.PlayerState[id]
    if not ps then return end

    self:CaptureInventory(ply, ps)
    ps.armor = 0
    ps.lives = math.max(0, ps.lives - 1)
    ps.respawnAt = nil

    if ps.lives > 0 then
        ps.respawnAt = CurTime() + CC.Lives.RespawnDelay
    else
        ps.eliminated = true
        ps.eliminatedSince = CurTime()
        self.State.ActiveIdentity[id] = nil
    end

    self:_SyncPlayerVars(ply)
    local deathEpoch = self.State.CampaignEpoch
    timer.Simple(0, function()
        if self:IsCampaignEpoch(deathEpoch) and IsValid(ply) and not ply:Alive() then
            self:PutInRestrictedSpectator(ply)
        end
    end)

    if ps.eliminated then self:PromoteWaitingSpectators() end
    self:EvaluateWipe()
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
    if self.State.Failed or self.State.LevelCleared then return false end
    local connected = self:_ConnectedPlayedPlayers()
    if #connected == 0 then
        self:UpdateFreezeState()
        return false
    end

    for _, ply in ipairs(connected) do
        local ps = self:GetPlayerState(ply)
        if ps then
            if self:IsActivePlayer(ply) and ply:Alive() then return false end
            if ps.lives > 0 and not ps.eliminated then return false end
        end
    end

    self:FailCampaign("total party wipe")
    return true
end

function RunManager:FailCampaign(reason)
    if self.State.Failed then return end
    self.State.Failed = true
    self.State.FailureReason = reason or "campaign failure"
    for _, ply in ipairs(player.GetAll()) do self:PutInRestrictedSpectator(ply) end
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

    self.State.LevelCleared = true
    self.State.IntermissionEnd = CurTime() + CC.Progression.IntermissionSeconds
    LOD.ProgressionDirector:Announce(string.format("DEBORAH RESCUED — LEVEL %d CLEAR", self.State.Level))
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

    for _, ps in pairs(self.State.PlayerState) do
        ps.respawnAt = nil
        if ps.lives <= 0 or ps.eliminated then
            ps.lives = 1
            ps.eliminated = false
            ps.eliminatedSince = nil
            ps.armor = 0
        end
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
    timer.Simple(0, function()
        if IsValid(ply) then RunManager:ApplyPlayerState(ply) end
    end)
end)

hook.Add("PlayerDeath", "LOD_PlayerDeathLives", function(victim)
    RunManager:HandleDeath(victim)
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
        if RunManager:IsActivePlayer(ply) and not ply:Alive() then
            local ps = RunManager:GetPlayerState(ply)
            if ps and not ps.eliminated and ps.lives > 0 and ps.respawnAt and CurTime() >= ps.respawnAt then
                ps.respawnAt = nil
                ply:UnSpectate()
                ply:Spawn()
            end
        end
    end
end)

hook.Add("ShutDown", "LOD_Cleanup", function()
    LOD.MazeBuilder:Cleanup()
end)
