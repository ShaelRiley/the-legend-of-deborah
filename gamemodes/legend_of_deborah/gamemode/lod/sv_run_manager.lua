LOD = LOD or {}
LOD.RunManager = LOD.RunManager or {}

local RunManager = LOD.RunManager
local CC = LOD.Config

local cvSeed = CreateConVar("lod_campaign_seed", "0", FCVAR_ARCHIVE, "0 = time-derived campaign seed; nonzero = custom unranked seed")
local defaultSeedCounter = 0

RunManager.State = RunManager.State or {
    CampaignSeed = nil,
    LevelSeed = nil,
    Level = 1,
    Ranked = true,
    BuildReady = false,
    Graph = nil,
    BuildReport = nil,
    CharacterByIdentity = {},
    ActiveIdentity = {},
    CharacterOrder = nil
}

local function identityOf(ply)
    if not IsValid(ply) then return nil end
    return ply:SteamID64() ~= "0" and ply:SteamID64() or ("bot:" .. ply:EntIndex())
end

function RunManager:MarkUnranked(reason)
    self.State.Ranked = false
    self.State.UnrankedReason = self.State.UnrankedReason or reason
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

function RunManager:NewCampaign()
    local customSeed = cvSeed:GetInt()
    self.State.Level = 1
    self.State.Ranked = customSeed == 0
    self.State.UnrankedReason = customSeed == 0 and nil or "custom campaign seed"
    self.State.CampaignSeed = customSeed ~= 0 and LOD.Seeds.Normalize(customSeed) or self:_DefaultSeed()
    self.State.CharacterByIdentity = {}
    self.State.ActiveIdentity = {}
    self:_PrepareCharacterOrder()
    self:_ValidateConfiguredModels()
    return self:BuildCurrentLevel()
end

function RunManager:BuildCurrentLevel(levelSeedOverride)
    if game.GetMap() ~= "gm_flatgrass" then
        self.State.BuildReady = false
        return false, "The Legend of Deborah v1 requires gm_flatgrass"
    end

    self.State.BuildReady = false
    local levelSeed = levelSeedOverride or LOD.Seeds.DeriveLevel(self.State.CampaignSeed, self.State.Level)
    if levelSeedOverride then self:MarkUnranked("debug level-seed override") end
    self.State.LevelSeed = LOD.Seeds.Normalize(levelSeed)

    local graph, err = LOD.MazeGenerator:Generate(self.State.LevelSeed)
    if not graph then return false, err end
    local ok, buildReport = LOD.MazeBuilder:Build(graph)
    if not ok then return false, buildReport end

    self.State.Graph = graph
    self.State.BuildReport = buildReport
    self.State.BuildReady = true

    for _, ply in ipairs(player.GetAll()) do
        self:TryActivatePlayer(ply)
        if self:IsActivePlayer(ply) then ply:Spawn() end
    end

    print(string.format(
        "[LOD] Level %d ready. campaign=%d levelSeed=%d cells=%d entities=%d vertical=%d attempt=%d",
        self.State.Level,
        self.State.CampaignSeed,
        self.State.LevelSeed,
        graph.Validation.cellCount,
        buildReport.entityCount,
        graph.Validation.criticalVerticalTransitions,
        graph.Attempt
    ))
    return true, graph
end

function RunManager:IsActivePlayer(ply)
    local id = identityOf(ply)
    return id and self.State.ActiveIdentity[id] == true
end

function RunManager:_ActiveCount()
    local count = 0
    for _, active in pairs(self.State.ActiveIdentity) do if active then count = count + 1 end end
    return count
end

function RunManager:PutInRestrictedSpectator(ply)
    if not IsValid(ply) then return end

    ply:StripWeapons()

    local target
    for _, candidate in ipairs(player.GetAll()) do
        if candidate ~= ply and self:IsActivePlayer(candidate) and candidate:Alive() then
            target = candidate
            break
        end
    end

    if IsValid(target) then
        ply:Spectate(OBS_MODE_CHASE)
        ply:SpectateEntity(target)
        return
    end

    ply:Spectate(OBS_MODE_FIXED)
    if self.State.BuildReport and self.State.BuildReport.startPos then
        ply:SetPos(self.State.BuildReport.startPos)
    end
end

function RunManager:TryActivatePlayer(ply)
    if not IsValid(ply) then return false end
    local id = identityOf(ply)
    if not id then return false end

    if self.State.ActiveIdentity[id] then return true end
    if self:_ActiveCount() >= CC.MaxActivePlayers then
        self:PutInRestrictedSpectator(ply)
        return false
    end

    self.State.ActiveIdentity[id] = true
    if not self.State.CharacterByIdentity[id] then
        local used = table.Count(self.State.CharacterByIdentity)
        self.State.CharacterByIdentity[id] = self.State.CharacterOrder[used + 1] or CC.Models.Characters[1]
    end
    return true
end

function RunManager:ReleasePlayer(ply)
    local id = identityOf(ply)
    if id then self.State.ActiveIdentity[id] = nil end
end

function RunManager:ApplyPlayerState(ply)
    if not self.State.BuildReady or not self:IsActivePlayer(ply) then return end
    local id = identityOf(ply)
    local character = self.State.CharacterByIdentity[id]
    ply:SetTeam(CC.PlayerTeam)
    ply:SetNoCollideWithTeammates(true)
    ply:CollisionRulesChanged()
    if character then ply:SetModel(character.model) end
    ply:SetPos(self.State.BuildReport.startPos)
    ply:SetEyeAngles(Angle(0, 0, 0))
    ply:SetHealth(100)
    ply:SetArmor(0)
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
    timer.Simple(0, function()
        if not IsValid(ply) then return end
        RunManager:TryActivatePlayer(ply)
        if RunManager:IsActivePlayer(ply) and RunManager.State.BuildReady then
            ply:Spawn()
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

hook.Add("PlayerDisconnected", "LOD_PlayerDisconnected", function(ply)
    RunManager:ReleasePlayer(ply)
end)

hook.Add("ShutDown", "LOD_Cleanup", function()
    LOD.MazeBuilder:Cleanup()
end)
