LOD = LOD or {}
LOD.Watcher = LOD.Watcher or {}

local Watcher = LOD.Watcher
local EC = LOD.Config and LOD.Config.Encounter
local Navigator = LOD.MazeNavigator
local Motion = LOD.HostileMotionV2
local WanderingDirector = LOD.WanderingDirector
local EncounterDirector = LOD.EncounterDirector
local Rolls = LOD.CombatRolls
local cellKey = LOD.MazeGenerator and LOD.MazeGenerator.CellKey

if not EC or not Navigator or not cellKey then return end

local SCAN_SECONDS = 1.25
local ALERT_CELLS = 6
local SCAN_RETRY_SECONDS = 0.35
local SCAN_REPEAT_SECONDS = 1.25
local WANDER_WEIGHT = 4
local WATCHER_HEALTH_PROFILE = {count = 3, sides = 4, bonus = 3}

util.AddNetworkString("LOD_WatcherScanState")

-- The live GDD specifies the Watcher's support behavior but does not prescribe
-- a numeric dice-era durability profile. Start it at Runner-class durability so
-- the rare support unit remains a plausible focus-fire target; runtime evidence
-- may tune this profile without changing the scanning contract.
EC.Archetypes.watcher = EC.Archetypes.watcher or {
    class = "lod_hostile_watcher",
    name = "Watcher",
    model = "models/combine_scanner.mdl",
    baseHP = 18,
    speed = 135,
    meleeDamage = 0,
    meleeCooldown = 99,
    meleeRange = 0,
    threat = 1.25,
    activity = ACT_IDLE
}

EC.Templates.surveillance = EC.Templates.surveillance or {
    name = "Surveillance",
    composition = {watcher = 1, shambler = 2}
}

if WanderingDirector and WanderingDirector.Config and WanderingDirector.Config.ArchetypeWeights then
    WanderingDirector.Config.ArchetypeWeights.watcher = WANDER_WEIGHT
end

Watcher.Stats = Watcher.Stats or {
    scansStarted = 0,
    scansCompleted = 0,
    cancelledLOS = 0,
    cancelledStun = 0,
    cancelledTarget = 0,
    wanderersAlerted = 0,
    testSpawns = 0
}
Watcher.TestEntities = Watcher.TestEntities or {}

local function keyOf(cell)
    return cell and cellKey(cell.x, cell.y, cell.z) or nil
end

local function currentState()
    local state = LOD.RunManager and LOD.RunManager.State
    return state, state and state.Graph or nil
end

local function livingPlayer(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return false end
    if LOD.RunManager and LOD.RunManager.IsActivePlayer then
        return LOD.RunManager:IsActivePlayer(ply)
    end
    return true
end

local function safeCell(graph, cell)
    local tag = graph and graph.CellTags and graph.CellTags[keyOf(cell)]
    return tag and tag.safe == true or false
end

local function playerEligible(self, graph, target)
    if not livingPlayer(target) then return false end
    local watcherCell = Navigator:WorldToCell(graph, self:GetPos())
    local targetCell = Navigator:WorldToCell(graph, target:GetPos())
    if not watcherCell or not targetCell or watcherCell.z ~= targetCell.z then return false end
    if safeCell(graph, targetCell) then return false end
    return true
end

-- Match the projectile-authentic hostile LOS convention without rebuilding a
-- hostile list. Other LOD hostiles are transparent to perception; generated and
-- world geometry remain blockers.
local function hasLOS(self, target)
    if not IsValid(self) or not livingPlayer(target) then return false end
    local tr = util.TraceLine({
        start = self:WorldSpaceCenter(),
        endpos = target:EyePos(),
        mask = MASK_SHOT,
        filter = function(ent)
            if ent == self or ent == target then return false end
            if IsValid(ent) and ent.LODHostile then return false end
            if IsValid(ent) and (ent:GetOwner() == target or ent:GetParent() == target) then return false end
            return true
        end
    })
    return not tr.Hit or tr.Fraction >= 0.995
end

local function sendScanState(self, target, active)
    if not IsValid(self) then return end
    net.Start("LOD_WatcherScanState")
    net.WriteEntity(self)
    net.WriteBool(active == true)
    if active then
        net.WriteEntity(IsValid(target) and target or NULL)
        net.WriteFloat(SCAN_SECONDS)
    end
    net.Broadcast()
end

local function emitCue(self, preferred, fallback, level, pitch, volume)
    if not IsValid(self) then return end
    local path = preferred
    if not path or not file.Exists("sound/" .. path, "GAME") then path = fallback end
    if path then self:EmitSound(path, level or 68, pitch or 100, volume or 0.75, CHAN_ITEM) end
end

local function stopAndFace(self, target)
    if Motion and self.LODMotionV2 then
        Motion:Stop(self)
        if IsValid(target) then Motion:FaceToward(self, target:GetPos()) end
        return
    end
    if self.loco then
        self.loco:SetDesiredSpeed(0)
        if IsValid(target) then self.loco:FaceTowards(target:GetPos()) end
    end
end

local function cancelScan(self, reason)
    local scan = self.LODWatcherScan
    if not scan then return false end
    self.LODWatcherScan = nil
    self.LODNextWatcherScan = CurTime() + SCAN_RETRY_SECONDS
    sendScanState(self, nil, false)

    if reason == "los" then
        Watcher.Stats.cancelledLOS = (Watcher.Stats.cancelledLOS or 0) + 1
    elseif reason == "stun" then
        Watcher.Stats.cancelledStun = (Watcher.Stats.cancelledStun or 0) + 1
    else
        Watcher.Stats.cancelledTarget = (Watcher.Stats.cancelledTarget or 0) + 1
    end
    return true
end

local function beginScan(self, target)
    if self.LODWatcherScan or not IsValid(target) then return false end
    if CurTime() < (self.LODNextWatcherScan or 0) then return false end

    local now = CurTime()
    self.LODWatcherScan = {
        target = target,
        startedAt = now,
        midAt = now + SCAN_SECONDS * 0.52,
        completesAt = now + SCAN_SECONDS,
        midCue = false
    }
    Watcher.Stats.scansStarted = (Watcher.Stats.scansStarted or 0) + 1
    sendScanState(self, target, true)
    emitCue(self, "npc/scanner/scanner_scan1.wav", "buttons/blip1.wav", 70, 105, 0.78)
    stopAndFace(self, target)
    return true
end

local function alertWanderers(self, graph, target)
    local watcherCell = Navigator:WorldToCell(graph, self:GetPos())
    local targetCell = Navigator:WorldToCell(graph, target:GetPos())
    if not watcherCell or not targetCell or watcherCell.z ~= targetCell.z or safeCell(graph, targetCell) then return 0 end

    local alerted = 0
    local now = CurTime()
    for _, hostile in ipairs(WanderingDirector and WanderingDirector.Entities or {}) do
        if IsValid(hostile) and hostile ~= self and hostile.LODWanderer == true
            and not hostile.LODDead and hostile.LODWanderFloor == watcherCell.z
        then
            local hostileCell = Navigator:WorldToCell(graph, hostile:GetPos())
            if hostileCell and not safeCell(graph, hostileCell) then
                local distance = Navigator:Distance(graph, watcherCell, hostileCell)
                if distance ~= math.huge and distance <= ALERT_CELLS then
                    hostile.LODTarget = target
                    hostile.LODReturningHome = false
                    hostile.LODWaypoints = {}
                    hostile.LODWaypointIndex = 1
                    hostile.LODNextRouteRefresh = 0
                    -- Give the broadcast a brief reaction window, then the normal
                    -- wandering leash/safe-zone rules regain full authority.
                    hostile.LODNextTargetRefresh = now + 0.55
                    hostile.LODWatcherAlertedAt = now
                    hostile.LODWatcherAlertSource = self
                    alerted = alerted + 1
                end
            end
        end
    end
    return alerted
end

local function completeScan(self, graph, target)
    if not self.LODWatcherScan then return false end
    self.LODWatcherScan = nil
    self.LODNextWatcherScan = CurTime() + SCAN_REPEAT_SECONDS
    sendScanState(self, nil, false)
    emitCue(self, "npc/scanner/scanner_photo1.wav", "buttons/button17.wav", 74, 118, 0.82)

    local alerted = alertWanderers(self, graph, target)
    Watcher.Stats.scansCompleted = (Watcher.Stats.scansCompleted or 0) + 1
    Watcher.Stats.wanderersAlerted = (Watcher.Stats.wanderersAlerted or 0) + alerted
    self.LODWatcherLastAlertCount = alerted
    return true
end

local function processScan(self, graph)
    local scan = self.LODWatcherScan
    if not scan then return false end
    local target = scan.target

    if CurTime() < (self.LODHitStunUntil or 0) then
        cancelScan(self, "stun")
        return false
    end
    if not playerEligible(self, graph, target) then
        cancelScan(self, "target")
        return false
    end
    if not hasLOS(self, target) then
        cancelScan(self, "los")
        return false
    end

    stopAndFace(self, target)
    if not scan.midCue and CurTime() >= scan.midAt then
        scan.midCue = true
        emitCue(self, "npc/scanner/scanner_scan2.wav", "buttons/button15.wav", 72, 118, 0.78)
    end
    if CurTime() >= scan.completesAt then
        completeScan(self, graph, target)
        return false
    end
    return true
end

-- Add Watcher dice-era durability without modifying the central table's private
-- health-profile local. All other archetypes remain delegated to the existing
-- combat-roll authority.
if Rolls and not Rolls.LODWatcherHealthInstalled then
    Rolls.LODWatcherHealthInstalled = true
    local baseRollEnemyHealth = Rolls.RollEnemyHealth
    function Rolls:RollEnemyHealth(archetypeId, instanceSeed)
        if archetypeId ~= "watcher" then return baseRollEnemyHealth(self, archetypeId, instanceSeed) end
        local profile = WATCHER_HEALTH_PROFILE
        local seed = LOD.Seeds.Derive(instanceSeed or 1, "health-dice:watcher")
        local total, values = self:_RollFormula(profile, LOD.RNG.New(seed))
        self.Stats.healthRolls = (self.Stats.healthRolls or 0) + 1
        return {
            profile = profile,
            formula = "3d4+3",
            total = total,
            values = values,
            expected = 10.5,
            seed = seed
        }
    end
end

local function installHostilePatch()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class or class.LODWatcherPatched then return false end
    class.LODWatcherPatched = true

    local baseInitialize = class.Initialize
    function class:Initialize()
        baseInitialize(self)
        if self.LODArchetypeId ~= "watcher" or not self.LODConfig then return end
        self.LODWatcherScan = nil
        self.LODNextWatcherScan = CurTime() + 0.35
        self.LODWatcherLastAlertCount = 0
        self:SetNW2Bool("LOD_Watcher", true)
        if self._SetActivity then self:_SetActivity(ACT_IDLE, true) end
    end

    function class:_RunWatcherTick()
        if self.LODArchetypeId ~= "watcher" then return false end
        local frame = FrameNumber()
        if self.LODWatcherDispatchFrame == frame then return self.LODWatcherScan ~= nil end
        self.LODWatcherDispatchFrame = frame

        if self.LODDead or not self.LODActivated then
            if self.LODWatcherScan then cancelScan(self, "target") end
            return true
        end

        local state, graph = currentState()
        if not state or not graph or not state.BuildReady or state.Failed or state.LevelCleared then
            if self.LODWatcherScan then cancelScan(self, "target") end
            return true
        end

        if self.LODWatcherScan then return processScan(self, graph) end

        local target = self.LODTarget
        if IsValid(target) and playerEligible(self, graph, target)
            and CurTime() >= (self.LODNextWatcherScan or 0) and hasLOS(self, target)
        then
            return beginScan(self, target)
        end

        return false
    end

    local baseBehaviourTick = class._BehaviourTick
    function class:_BehaviourTick()
        if self.LODArchetypeId == "watcher" and self:_RunWatcherTick() then return end
        return baseBehaviourTick(self)
    end

    local baseOnInjured = class.OnInjured
    function class:OnInjured(dmginfo)
        if baseOnInjured then baseOnInjured(self, dmginfo) end
        if self.LODArchetypeId == "watcher" and self.LODWatcherScan
            and CurTime() < (self.LODHitStunUntil or 0)
        then
            cancelScan(self, "stun")
        end
    end

    local baseOnRemove = class.OnRemove
    function class:OnRemove()
        if self.LODWatcherScan then sendScanState(self, nil, false) end
        if baseOnRemove then return baseOnRemove(self) end
    end

    return true
end

installHostilePatch()
hook.Add("OnEntityCreated", "LOD_WatcherInstallBeforeSpawn", function(ent)
    if IsValid(ent) and ent:GetClass() == "lod_hostile" then installHostilePatch() end
end)

-- Production authored encounter integration. The Watcher first appears in the
-- discretionary Surveillance template from Sector 2 onward; its rare roaming
-- presence remains independent of authored encounter budgets.
if EncounterDirector and not EncounterDirector.LODWatcherTemplatesInstalled then
    EncounterDirector.LODWatcherTemplatesInstalled = true
    local baseEligibleTemplates = EncounterDirector._EligibleTemplates
    function EncounterDirector:_EligibleTemplates(sector, role)
        local choices = baseEligibleTemplates(self, sector, role) or {}
        if sector >= 2 then choices[#choices + 1] = "surveillance" end
        return choices
    end

    local baseSpawnEncounter = EncounterDirector._SpawnEncounter
    function EncounterDirector:_SpawnEncounter(encounter)
        local watcherCount = encounter and encounter.composition and (encounter.composition.watcher or 0) or 0
        if watcherCount <= 0 then return baseSpawnEncounter(self, encounter) end
        if encounter.spawned or encounter.cleared then return true end

        local total = 0
        for _, count in pairs(encounter.composition or {}) do total = total + count end
        local reserve = WanderingDirector and WanderingDirector.GetDeficitReservation
            and WanderingDirector:GetDeficitReservation() or 0
        if self:GetActiveCount() + total + reserve > EC.ActiveHostileCeiling then return false end

        encounter.composition.watcher = nil
        local ok = baseSpawnEncounter(self, encounter)
        encounter.composition.watcher = watcherCount
        if not ok then return false end

        local center = Navigator:CellCenter(encounter.cell) + Vector(0, 0, 28)
        for index = 1, watcherCount do
            local ent = ents.Create("lod_hostile")
            if IsValid(ent) then
                ent.LODArchetypeId = "watcher"
                ent.LODHomeCellKey = encounter.cellKey
                ent.LODEncounterId = encounter.id
                ent.LODActivated = true
                ent:SetPos(center + Vector((index - 1) * 42, 48, 0))
                ent:Spawn()
                ent:Activate()
                encounter.entities[#encounter.entities + 1] = ent
                self.Entities[#self.Entities + 1] = ent
            end
        end
        return true
    end
end

local function cleanupTestEntities()
    for _, ent in ipairs(Watcher.TestEntities or {}) do
        if IsValid(ent) then ent:Remove() end
    end
    Watcher.TestEntities = {}
end

local function spawnTestHostile(archetypeId, graph, cell, pos, ordinal)
    local ent = ents.Create("lod_hostile")
    if not IsValid(ent) then return nil end
    local key = keyOf(cell)
    ent.LODArchetypeId = archetypeId
    ent.LODHomeCellKey = key
    ent.LODEncounterId = nil
    ent.LODEncounterOrdinal = ordinal
    ent.LODWanderer = true
    ent.LODWanderFloor = cell.z
    ent.LODWanderAnchorCellKey = key
    ent.LODWanderSeed = LOD.Seeds.Derive((LOD.RunManager.State.LevelSeed or 1), "watcher-test:" .. ordinal)
    ent.LODActivated = true
    ent:SetPos(pos or (Navigator:CellCenter(cell) + Vector(0, 0, 16)))
    ent:Spawn()
    ent:Activate()

    if WanderingDirector then
        WanderingDirector.Entities = WanderingDirector.Entities or {}
        WanderingDirector.Entities[#WanderingDirector.Entities + 1] = ent
    end
    if EncounterDirector then
        EncounterDirector.Entities = EncounterDirector.Entities or {}
        EncounterDirector.Entities[#EncounterDirector.Entities + 1] = ent
    end
    Watcher.TestEntities[#Watcher.TestEntities + 1] = ent
    return ent
end

local function distantTestCell(graph, playerCell)
    local keys = {}
    for key, cell in pairs(graph.Cells or {}) do
        if cell.z == playerCell.z and not safeCell(graph, cell) then keys[#keys + 1] = key end
    end
    table.sort(keys)
    local fallback
    for _, key in ipairs(keys) do
        local cell = graph.Cells[key]
        local distance = Navigator:Distance(graph, playerCell, cell)
        if distance == 5 or distance == 6 then return cell end
        if not fallback and distance > 4 and distance ~= math.huge then fallback = cell end
    end
    return fallback
end

concommand.Add("lod_watcher_test", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if not IsValid(ply) or not ply:IsAdmin() then return end

    local state, graph = currentState()
    if not state or not graph or not state.BuildReady then
        ply:ChatPrint("Watcher test requires an active generated dungeon.")
        return
    end

    local playerCell = Navigator:WorldToCell(graph, ply:GetPos())
    if not playerCell then
        ply:ChatPrint("Watcher test could not resolve your maze cell.")
        return
    end

    cleanupTestEntities()
    local center = Navigator:CellCenter(playerCell)
    local watcher = spawnTestHostile("watcher", graph, playerCell, center + Vector(0, 0, 34), 980001)
    local alertCell = distantTestCell(graph, playerCell)
    local sleeper = alertCell and spawnTestHostile("shambler", graph, alertCell,
        Navigator:CellCenter(alertCell) + Vector(0, 0, 12), 980002) or nil

    if IsValid(watcher) then
        watcher.LODNextTargetRefresh = 0
        watcher.LODNextWatcherScan = 0
    end
    if IsValid(sleeper) then
        sleeper.LODNextTargetRefresh = CurTime() + 0.15
    end

    Watcher.Stats.testSpawns = (Watcher.Stats.testSpawns or 0) + 1
    local sleeperDistance = alertCell and Navigator:Distance(graph, playerCell, alertCell) or math.huge
    local line = string.format("watcher=#%s alertWanderer=#%s naturalAcquireDistance=%s scan=%.2fs alertRadius=%d",
        IsValid(watcher) and watcher:EntIndex() or "FAIL",
        IsValid(sleeper) and sleeper:EntIndex() or "none",
        sleeperDistance ~= math.huge and tostring(sleeperDistance) or "none",
        SCAN_SECONDS, ALERT_CELLS)
    print("[LOD:WATCHER-TEST] " .. line)
    ply:ChatPrint(line)
end)

concommand.Add("lod_watcher_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local live = 0
    local scanning = 0
    local watcherList = LOD.HostileRegistry and LOD.HostileRegistry:List() or {}
    for _, hostile in ipairs(watcherList) do
        if IsValid(hostile) and not hostile.LODDead and hostile.LODArchetypeId == "watcher" then
            live = live + 1
            if hostile.LODWatcherScan then scanning = scanning + 1 end
        end
    end

    local passed = (Watcher.Stats.scansStarted or 0) > 0
        and (Watcher.Stats.scansCompleted or 0) > 0
        and (Watcher.Stats.wanderersAlerted or 0) > 0
    local line = string.format(
        "live=%d scanning=%d started=%d completed=%d cancelLOS=%d cancelStun=%d alerted=%d testSpawns=%d result=%s",
        live, scanning,
        Watcher.Stats.scansStarted or 0,
        Watcher.Stats.scansCompleted or 0,
        Watcher.Stats.cancelledLOS or 0,
        Watcher.Stats.cancelledStun or 0,
        Watcher.Stats.wanderersAlerted or 0,
        Watcher.Stats.testSpawns or 0,
        passed and "PASS" or "WAITING")
    print("[LOD:WATCHER] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
