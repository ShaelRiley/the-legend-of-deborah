AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local DEATH_BLINK_DURATION = 1.0
local DEATH_BLINK_INTERVAL = 0.125
local DEATH_BLINK_COUNT = math.floor(DEATH_BLINK_DURATION / DEATH_BLINK_INTERVAL + 0.5)
local DEATH_CONVERT_OFFSETS = {1.01, 1.12, 1.25}
local DEATH_SHARED_TIMER = "LOD_HostileDeathPresentationShared"
local PLACEHOLDER_LOOT_MODEL = "models/items/boxsrounds.mdl"
local PLACEHOLDER_LOOT_LIFETIME = 20
local PLACEHOLDER_LOOT_CAP = 24

-- Milestone 4 will replace these inert markers with individualized seeded drops.
-- Until then, keep their presentation bounded: wanderers respawn indefinitely, so
-- registering every marker with MazeBuilder would otherwise grow both the entity
-- population and MazeBuilder's retained entity table for the entire level.
LOD.PlaceholderLoot = LOD.PlaceholderLoot or {Entities = {}}
local PlaceholderLoot = LOD.PlaceholderLoot

local function removeLootAt(index)
    local loot = table.remove(PlaceholderLoot.Entities, index)
    if IsValid(loot) then loot:Remove() end
end

function PlaceholderLoot:Prune()
    local now = CurTime()
    local state = LOD.RunManager and LOD.RunManager.State
    local levelSeed = state and state.LevelSeed or nil

    for index = #self.Entities, 1, -1 do
        local loot = self.Entities[index]
        if not IsValid(loot)
            or (loot.LODPlaceholderLootExpiresAt or 0) <= now
            or (levelSeed and loot.LODPlaceholderLootLevelSeed ~= levelSeed)
        then
            removeLootAt(index)
        end
    end
end

function PlaceholderLoot:Register(loot, levelSeed)
    if not IsValid(loot) then return false end
    self:Prune()

    while #self.Entities >= PLACEHOLDER_LOOT_CAP do
        removeLootAt(1)
    end

    loot.LODPlaceholderLootLevelSeed = levelSeed
    loot.LODPlaceholderLootExpiresAt = CurTime() + PLACEHOLDER_LOOT_LIFETIME
    self.Entities[#self.Entities + 1] = loot
    return true
end

function PlaceholderLoot:Clear()
    for index = #self.Entities, 1, -1 do
        removeLootAt(index)
    end
end

function PlaceholderLoot:Count()
    self:Prune()
    return #self.Entities
end

timer.Create("LOD_PlaceholderLootCleanup", 1, 0, function()
    if LOD.PlaceholderLoot and LOD.PlaceholderLoot.Prune then
        LOD.PlaceholderLoot:Prune()
    end
end)

concommand.Add("lod_placeholder_loot_status", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    print(string.format(
        "[LOD:LOOT] active=%d cap=%d lifetime=%.0fs",
        PlaceholderLoot:Count(), PLACEHOLDER_LOOT_CAP, PLACEHOLDER_LOOT_LIFETIME
    ))
end)

-- One adaptive timer services every concurrent death presentation. The previous
-- path allocated ten timers per hostile (blink, finish, pose, four pulse sounds,
-- and three conversion notes). This queue keeps the same event times but owns
-- only one timer, rescheduling it to the next due event and removing it when idle.
LOD.HostileDeathPresentation = LOD.HostileDeathPresentation or {
    Active = {},
    TotalDeaths = 0,
    SharedTimerStarts = 0,
    SharedTicks = 0
}
local DeathPresentation = LOD.HostileDeathPresentation
DeathPresentation.Active = DeathPresentation.Active or {}

local function deathRecordNextDue(record)
    if not record.finished and record.blinkTick < DEATH_BLINK_COUNT then
        return record.startedAt + (record.blinkTick + 1) * DEATH_BLINK_INTERVAL
    end
    if record.finished and record.convertStep < #DEATH_CONVERT_OFFSETS then
        return record.startedAt + DEATH_CONVERT_OFFSETS[record.convertStep + 1]
    end
end

local function runDeathPresentationTimer()
    DeathPresentation:_RunDue()
end

function DeathPresentation:_ScheduleNext()
    local earliest
    for _, record in ipairs(self.Active) do
        local due = deathRecordNextDue(record)
        if due and (not earliest or due < earliest) then earliest = due end
    end

    if not earliest then
        timer.Remove(DEATH_SHARED_TIMER)
        return
    end

    local delay = math.max(0.001, earliest - CurTime())
    if timer.Exists(DEATH_SHARED_TIMER) then
        timer.Adjust(DEATH_SHARED_TIMER, delay, 0)
    else
        self.SharedTimerStarts = (self.SharedTimerStarts or 0) + 1
        timer.Create(DEATH_SHARED_TIMER, delay, 0, runDeathPresentationTimer)
    end
end

function DeathPresentation:_RunDue()
    self.SharedTicks = (self.SharedTicks or 0) + 1
    local now = CurTime() + 0.001

    for index = #self.Active, 1, -1 do
        local record = self.Active[index]
        local hostile = record.hostile

        if not record.finished and not IsValid(hostile) then
            table.remove(self.Active, index)
        else
            while not record.finished and record.blinkTick < DEATH_BLINK_COUNT
                and now >= record.startedAt + (record.blinkTick + 1) * DEATH_BLINK_INTERVAL
            do
                record.blinkTick = record.blinkTick + 1
                if IsValid(hostile) then hostile:SetNoDraw(not hostile:GetNoDraw()) end

                if record.blinkTick % 2 == 1 then
                    hook.Run("LOD_HostileDeathBlinkPulse", record.origin, record.levelSeed,
                        math.floor(record.blinkTick / 2) + 1)
                end

                if record.blinkTick >= DEATH_BLINK_COUNT then
                    record.finished = true
                    if IsValid(hostile) then hostile:_FinishDeathPresentation() end
                end
            end

            while record.finished and record.convertStep < #DEATH_CONVERT_OFFSETS
                and now >= record.startedAt + DEATH_CONVERT_OFFSETS[record.convertStep + 1]
            do
                record.convertStep = record.convertStep + 1
                hook.Run("LOD_HostileDeathConvertNote", record.origin, record.levelSeed, record.convertStep)
            end

            if record.finished and record.convertStep >= #DEATH_CONVERT_OFFSETS then
                table.remove(self.Active, index)
            end
        end
    end

    self:_ScheduleNext()
end

function DeathPresentation:Add(hostile)
    if not IsValid(hostile) then return false end
    self.TotalDeaths = (self.TotalDeaths or 0) + 1
    self.Active[#self.Active + 1] = {
        hostile = hostile,
        origin = hostile:WorldSpaceCenter(),
        levelSeed = hostile.LODDeathLevelSeed,
        startedAt = CurTime(),
        blinkTick = 0,
        convertStep = 0,
        finished = false
    }

    -- The death activity has already been selected, so the pain-pose module can
    -- supersede it synchronously without allocating a next-tick callback.
    hook.Run("LOD_HostileDeathApplyPose", hostile)
    self:_ScheduleNext()
    return true
end

concommand.Add("lod_death_scheduler_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local deaths = DeathPresentation.TotalDeaths or 0
    local active = #DeathPresentation.Active
    local running = timer.Exists(DEATH_SHARED_TIMER)
    local avoided = deaths * 10
    local passed = deaths > 0 and active == 0 and not running
    local line = string.format(
        "deaths=%d active=%d sharedTimer=%s sharedStarts=%d sharedTicks=%d perDeathTimers=0 legacyTimersAvoided=%d result=%s",
        deaths, active, tostring(running), DeathPresentation.SharedTimerStarts or 0,
        DeathPresentation.SharedTicks or 0, avoided, passed and "PASS" or "FAIL"
    )
    print("[LOD:DEATH-SCHEDULER] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)

local function archetypeConfig(id)
    return LOD.Config.Encounter.Archetypes[id]
end

local function activePartySize()
    if not LOD.RunManager then return 1 end
    return math.Clamp(LOD.RunManager:_ActiveCount(), 1, LOD.Config.MaxActivePlayers)
end

local function healthMultiplier()
    local encounter = LOD.Config.Encounter
    local level = LOD.RunManager and LOD.RunManager.State.Level or 1
    local campaign = math.min(encounter.EnemyHPLevelCap, 1 + encounter.EnemyHPGrowthPerLevel * math.max(0, level - 1))
    local party = encounter.PartyHealthMultiplier[activePartySize()] or 1
    return campaign * party
end

function ENT:_SetActivity(activity, force)
    activity = activity or ACT_IDLE
    if force or self.LODCurrentActivity ~= activity then
        self.LODCurrentActivity = activity
        self:StartActivity(activity)
        self:SetPlaybackRate(1)
    end
end

local function soldierFamily(hostile)
    local archetype = hostile and hostile.LODArchetypeId
    return archetype == "soldier" or archetype == "blitzer"
end

function ENT:_SoldierRunActivity()
    return ACT_RUN_AIM_RIFLE or ACT_RUN
end

function ENT:_SoldierIdleActivity()
    return ACT_IDLE_ANGRY_SMG1 or ACT_IDLE_ANGRY or ACT_IDLE
end

function ENT:_SoldierAttackActivity()
    return ACT_RANGE_ATTACK_SMG1 or ACT_RANGE_ATTACK1
end

function ENT:_CreateSoldierWeaponVisual()
    if not soldierFamily(self) then return end
    local weapon = ents.Create("prop_dynamic")
    if not IsValid(weapon) then return end
    weapon:SetModel("models/weapons/w_irifle.mdl")
    weapon:SetSolid(SOLID_NONE)
    weapon:SetMoveType(MOVETYPE_NONE)
    weapon:SetParent(self)
    weapon:AddEffects(EF_BONEMERGE)
    weapon:Spawn()
    weapon:Activate()
    if self.LODArchetypeId == "blitzer" then
        weapon:SetRenderMode(RENDERMODE_TRANSCOLOR)
        weapon:SetColor(Color(70, 220, 90, 255))
    end
    self.LODWeaponVisual = weapon
end

function ENT:Initialize()
    self.LODHostile = true
    self.LODArchetypeId = self.LODArchetypeId or "shambler"
    self.LODConfig = archetypeConfig(self.LODArchetypeId)
    if not self.LODConfig then
        ErrorNoHalt("[LOD:M3] hostile spawned with unknown archetype " .. tostring(self.LODArchetypeId) .. "\n")
        self:Remove()
        return
    end

    self:SetModel(self.LODConfig.model)
    if self.LODArchetypeId == "blitzer" then
        self:SetRenderMode(RENDERMODE_TRANSCOLOR)
        self:SetColor(Color(70, 220, 90, 255))
    end
    self:SetNW2String("LOD_Archetype", self.LODArchetypeId)
    self:SetNW2Bool("LOD_SoldierTelegraph", false)
    self:SetCollisionGroup(COLLISION_GROUP_NPC)
    self:SetCollisionBounds(Vector(-16, -16, 0), Vector(16, 16, 72))
    self:DrawShadow(true)

    local hp = math.max(1, math.floor(self.LODConfig.baseHP * healthMultiplier() + 0.5))
    self:SetHealth(hp)
    self:SetMaxHealth(hp)

    if self.loco then
        self.loco:SetDesiredSpeed(self.LODConfig.speed)
        self.loco:SetAcceleration(math.max(500, self.LODConfig.speed * 5))
        self.loco:SetDeceleration(math.max(500, self.LODConfig.speed * 6))
        self.loco:SetStepHeight(24)
        self.loco:SetJumpHeight(48)
    end

    self.LODActivated = self.LODActivated ~= false
    self.LODNextTargetRefresh = 0
    self.LODNextRouteRefresh = 0
    self.LODNextAttack = 0
    self.LODWaypointIndex = 1
    self.LODWaypoints = {}
    self.LODTarget = nil
    self.LODReturningHome = false
    self.LODSoldierBurst = nil
    self.LODDead = false

    if soldierFamily(self) then
        self:_CreateSoldierWeaponVisual()
        self:_SetActivity(self:_SoldierRunActivity(), true)
    else
        self:_SetActivity(self.LODConfig.activity or ACT_WALK, true)
    end
end

function ENT:SetLODEncounterContext(archetypeId, homeCellKey, encounterId)
    self.LODArchetypeId = archetypeId or self.LODArchetypeId
    self.LODHomeCellKey = homeCellKey
    self.LODEncounterId = encounterId
end

function ENT:GetLODHomeCell(graph)
    if not graph then return nil end
    if self.LODHomeCellKey and graph.Cells[self.LODHomeCellKey] then return graph.Cells[self.LODHomeCellKey] end
    return LOD.MazeNavigator:WorldToCell(graph, self:GetPos())
end

function ENT:_RouteToCell(graph, destinationCell)
    local navigator = LOD.MazeNavigator
    local currentCell = navigator:WorldToCell(graph, self:GetPos())
    if not currentCell or not destinationCell then
        self.LODWaypoints = {}
        self.LODWaypointIndex = 1
        return false
    end

    local path = navigator:FindPath(graph, currentCell, destinationCell)
    if not path then
        self.LODWaypoints = {}
        self.LODWaypointIndex = 1
        return false
    end

    self.LODWaypoints = navigator:PathToWaypoints(graph, path)
    self.LODWaypointIndex = 1
    return true
end

function ENT:_TargetCell(graph, target)
    return IsValid(target) and LOD.MazeNavigator:WorldToCell(graph, target:GetPos()) or nil
end

function ENT:_RefreshTarget(graph)
    if CurTime() < (self.LODNextTargetRefresh or 0) then return end
    self.LODNextTargetRefresh = CurTime() + LOD.Config.Encounter.TargetRefreshSeconds

    local home = self:GetLODHomeCell(graph)
    local target, homeDistance = LOD.FactionManager:BestTarget(self, graph, home)
    if target and homeDistance <= LOD.Config.Encounter.LeashCells then
        self.LODTarget = target
        self.LODReturningHome = false
    else
        self.LODTarget = nil
        self.LODReturningHome = true
    end
end

function ENT:_RefreshRoute(graph)
    -- A vertical flight is a committed movement sequence. Replanning every
    -- 0.35 seconds while the entity is still geometrically in the lower cell
    -- used to reset it to tread #1 forever. Hold the current route until the
    -- explicit stair waypoints carry the hostile fully off the flight.
    local activeWaypoint = self.LODWaypoints and self.LODWaypoints[self.LODWaypointIndex or 1]
    if activeWaypoint and activeWaypoint.stair then
        self.LODNextRouteRefresh = CurTime() + LOD.Config.Encounter.RouteRefreshSeconds
        return
    end

    if CurTime() < (self.LODNextRouteRefresh or 0) then return end
    self.LODNextRouteRefresh = CurTime() + LOD.Config.Encounter.RouteRefreshSeconds

    local home = self:GetLODHomeCell(graph)
    local current = LOD.MazeNavigator:WorldToCell(graph, self:GetPos())
    if not current or not home then return end

    local currentHomeDistance = LOD.MazeNavigator:Distance(graph, home, current)
    if currentHomeDistance > LOD.Config.Encounter.LeashCells then
        self.LODTarget = nil
        self.LODReturningHome = true
    end

    if self.LODReturningHome or not IsValid(self.LODTarget) then
        self:_RouteToCell(graph, home)
        return
    end

    local targetCell = self:_TargetCell(graph, self.LODTarget)
    if targetCell then
        self:_RouteToCell(graph, targetCell)
        if #self.LODWaypoints == 0 then
            self.LODWaypoints = {{pos = self.LODTarget:GetPos(), tolerance = 54}}
            self.LODWaypointIndex = 1
        end
    end
end

function ENT:_AdvanceWaypoint()
    local waypoint = self.LODWaypoints and self.LODWaypoints[self.LODWaypointIndex or 1]
    if not waypoint then return nil end
    local tolerance = waypoint.tolerance or 40
    if self:GetPos():DistToSqr(waypoint.pos) <= tolerance * tolerance then
        self.LODWaypointIndex = (self.LODWaypointIndex or 1) + 1
        waypoint = self.LODWaypoints[self.LODWaypointIndex]
    end
    return waypoint
end

function ENT:_IgnoredShotEntities()
    local ignored = {self}
    for _, ent in ipairs(ents.FindByClass("lod_hostile")) do
        if IsValid(ent) and ent ~= self then ignored[#ignored + 1] = ent end
    end
    return ignored
end

function ENT:_HasLineOfSight(target)
    if not IsValid(target) then return false end
    local startPos = self:WorldSpaceCenter() + Vector(0, 0, 12)
    local endPos = target:WorldSpaceCenter()
    local tr = util.TraceLine({
        start = startPos,
        endpos = endPos,
        mask = MASK_SHOT,
        filter = self:_IgnoredShotEntities()
    })
    return tr.Entity == target or tr.Fraction >= 0.995
end

function ENT:_MeleeAttack(target)
    local cfg = self.LODConfig
    if not IsValid(target) or CurTime() < (self.LODNextAttack or 0) then return false end
    if self:GetPos():DistToSqr(target:GetPos()) > cfg.meleeRange * cfg.meleeRange then return false end
    if not self:_HasLineOfSight(target) then return false end

    self.LODNextAttack = CurTime() + cfg.meleeCooldown
    target:TakeDamage(cfg.meleeDamage, self, self)
    self:EmitSound(self.LODArchetypeId == "runner" and "NPC_FastZombie.Attack" or "NPC_Zombie.Attack")
    return true
end

function ENT:_SoldierRawMuzzlePos()
    local attachment = self:LookupAttachment("anim_attachment_RH")
    if attachment and attachment > 0 then
        local data = self:GetAttachment(attachment)
        if data and data.Pos then
            -- prop_dynamic's bonemerged w_irifle exposes a nominal muzzle
            -- attachment, but Source reports that child attachment near the
            -- parent's origin. The humanoid hand socket is stable; the rifle
            -- barrel points along the hostile's faced direction during both
            -- warning and burst activities.
            return data.Pos + self:GetForward() * 24
        end
    end
    return self:WorldSpaceCenter() + Vector(0, 0, 12) + self:GetForward() * 24
end

function ENT:_SoldierMuzzlePos()
    local rawPos = self:_SoldierRawMuzzlePos()
    local size = math.Clamp(self:GetNW2Float("LOD_SizeScale", 1), 0.33, 1.33)
    local mins = util.GetModelBounds and select(1, util.GetModelBounds(self:GetModel()))
        or Vector(-16, -16, 0)
    local motionV2 = self:GetNW2Bool("LOD_MotionV2", false)
    local verticalCompensation = motionV2 and -(mins.z * size) or mins.z * (1 - size)
    local localPos = self:WorldToLocal(rawPos) * size
    localPos.z = localPos.z + verticalCompensation
    return self:LocalToWorld(localPos)
end

function ENT:_SoldierTargetAimPos(target)
    if target:IsPlayer() then return target:EyePos() end
    return target:WorldSpaceCenter()
end

function ENT:_SpawnSoldierBolt(aimPos, shotIndex)
    local cfg = self.LODConfig
    local startPos = self:_SoldierMuzzlePos()
    local direction = (aimPos - startPos):GetNormalized()
    local ang = direction:Angle()

    if self.LODArchetypeId == "blitzer" then
        local burst = self.LODSoldierBurst
        local shot = burst and burst.pattern and burst.pattern[shotIndex]
        if shot and shot.veer then
            ang.y = ang.y + shot.yaw
            ang.p = ang.p + shot.pitch
        end
    else
        -- Small deterministic side-to-side variance keeps the disciplined
        -- Soldier's three-bolt burst readable.
        local yawOffsets = {-1.5, 1.5, 0}
        local pitchOffsets = {0.4, -0.4, 0}
        local offsetIndex = ((shotIndex - 1) % 3) + 1
        ang.y = ang.y + yawOffsets[offsetIndex]
        ang.p = ang.p + pitchOffsets[offsetIndex]
    end
    direction = ang:Forward()

    local bolt = ents.Create("lod_soldier_bolt")
    if not IsValid(bolt) then return false end
    bolt.LODOwner = self
    bolt.LODDirection = direction
    bolt.LODSpeed = cfg.projectileSpeed
    bolt.LODDamage = cfg.burstDamage
    bolt.LODLifetime = cfg.projectileLifetime
    bolt:SetPos(startPos)
    bolt:SetAngles(direction:Angle())
    bolt:Spawn()
    bolt:Activate()

    if self.LODArchetypeId == "blitzer" then
        self.LODBlitzerShotsFired = (self.LODBlitzerShotsFired or 0) + 1
        if self.LODSoldierBurst and self.LODSoldierBurst.pattern
            and self.LODSoldierBurst.pattern[shotIndex]
            and self.LODSoldierBurst.pattern[shotIndex].veer
        then
            self.LODBlitzerVeeringShots = (self.LODBlitzerVeeringShots or 0) + 1
        end
        self:EmitSound("Weapon_AR2.Single", 73, 116, 0.88)
    else
        self:EmitSound("Weapon_AR2.Single", 72, 100, 0.85)
    end
    return true
end

function ENT:_BeginSoldierBurst(target)
    local cfg = self.LODConfig
    if self.LODSoldierBurst or not IsValid(target) then return false end
    if CurTime() < (self.LODNextAttack or 0) then return false end
    if self:GetPos():DistToSqr(target:GetPos()) > cfg.fireRange * cfg.fireRange then return false end
    if not self:_HasLineOfSight(target) then return false end

    local shots = cfg.burstShots or 3
    local pattern
    local patternSeed
    if self.LODArchetypeId == "blitzer" then
        self.LODBlitzerAttackOrdinal = (self.LODBlitzerAttackOrdinal or 0) + 1
        local instanceSeed = self.LODInstanceSeed or self:GetNW2Int("LOD_InstanceSeed", 1)
        patternSeed = LOD.Seeds.Derive(instanceSeed, "blitzer-burst:" .. self.LODBlitzerAttackOrdinal)
        local rng = LOD.RNG.New(patternSeed)
        shots = rng:Int(cfg.burstShotsMin or 1, cfg.burstShotsMax or 6)
        pattern = {}
        for i = 1, shots do
            local veer = rng:Chance(cfg.veerChance or 0.50)
            local sign = rng:Chance(0.5) and -1 or 1
            pattern[i] = {
                veer = veer,
                yaw = sign * (cfg.veerDegrees or 2.4),
                pitch = veer and rng:Float(-0.35, 0.35) or 0
            }
        end
        self.LODBlitzerBurstsStarted = (self.LODBlitzerBurstsStarted or 0) + 1
        self.LODBlitzerLastPatternSeed = patternSeed
        self.LODBlitzerLastPatternShots = shots
        self.LODBlitzerLastVeerRolls = #pattern
    end

    local targetAimPos = self:_SoldierTargetAimPos(target)
    self.LODSoldierBurst = {
        target = target,
        windupEnd = CurTime() + cfg.burstTelegraph,
        nextShot = nil,
        shotsRemaining = shots,
        originalShots = shots,
        shotIndex = 0,
        lastAimPos = targetAimPos,
        pattern = pattern,
        patternSeed = patternSeed
    }
    self:SetNW2Bool("LOD_SoldierTelegraph", true)
    self:SetNW2Vector("LOD_SoldierAim", targetAimPos)
    self:_SetActivity(self:_SoldierAttackActivity(), true)
    self:EmitSound("buttons/button17.wav", 64, self.LODArchetypeId == "blitzer" and 136 or 115, 0.72)
    return true
end

function ENT:_CancelSoldierBurst(shortCooldown)
    self.LODSoldierBurst = nil
    self:SetNW2Bool("LOD_SoldierTelegraph", false)
    self.LODNextAttack = CurTime() + (shortCooldown or 0.35)
    self:_SetActivity(self:_SoldierIdleActivity(), true)
end

function ENT:_ProcessSoldierBurst()
    local burst = self.LODSoldierBurst
    if not burst then return false end
    local cfg = self.LODConfig
    local target = burst.target

    if not IsValid(target) or not target:Alive() then
        self:_CancelSoldierBurst(0.2)
        return false
    end

    if self.loco then self.loco:SetDesiredSpeed(0) end
    self.loco:FaceTowards(Vector(target:GetPos().x, target:GetPos().y, self:GetPos().z))

    if CurTime() < burst.windupEnd then
        -- Breaking line of sight during the warning cancels the shot entirely.
        if not self:_HasLineOfSight(target) then
            self:_CancelSoldierBurst(0.25)
            return false
        end
        burst.lastAimPos = self:_SoldierTargetAimPos(target)
        self:SetNW2Vector("LOD_SoldierAim", burst.lastAimPos)
        return true
    end

    self:SetNW2Bool("LOD_SoldierTelegraph", false)
    if not burst.nextShot then burst.nextShot = CurTime() end

    if burst.shotsRemaining > 0 and CurTime() >= burst.nextShot then
        burst.shotIndex = burst.shotIndex + 1
        if self:_HasLineOfSight(target) then
            burst.lastAimPos = self:_SoldierTargetAimPos(target)
        end
        self:_SpawnSoldierBolt(burst.lastAimPos, burst.shotIndex)
        burst.shotsRemaining = burst.shotsRemaining - 1
        burst.nextShot = CurTime() + cfg.burstShotInterval
    end

    if burst.shotsRemaining <= 0 then
        if self.LODArchetypeId == "blitzer" then
            self.LODBlitzerCompletedBursts = (self.LODBlitzerCompletedBursts or 0) + 1
            self.LODBlitzerLastCompletedShots = burst.originalShots or burst.shotIndex
            self.LODBlitzerLastCompletedVeerRolls = #(burst.pattern or {})
            self.LODBlitzerLastCompletedSeed = burst.patternSeed
        end
        self.LODSoldierBurst = nil
        self.LODNextAttack = CurTime() + cfg.burstCooldown
        self:_SetActivity(self:_SoldierIdleActivity(), true)
        return false
    end

    return true
end

function ENT:_TryAttack(target)
    if soldierFamily(self) then return self:_BeginSoldierBurst(target) end
    return self:_MeleeAttack(target)
end

function ENT:_BehaviourTick()
    if self.LODDead or not self.LODActivated then return end
    local state = LOD.RunManager and LOD.RunManager.State
    local graph = state and state.Graph
    if not graph or not state.BuildReady or state.Failed or state.LevelCleared then return end

    self:_RefreshTarget(graph)
    self:_RefreshRoute(graph)

    if soldierFamily(self) and self.LODSoldierBurst then
        self:_ProcessSoldierBurst()
        return
    end

    local target = self.LODTarget
    local waypoint = self:_AdvanceWaypoint()

    if soldierFamily(self) and IsValid(target) and self:_HasLineOfSight(target) then
        local preferred = self.LODConfig.preferredRange or 480
        if self:GetPos():DistToSqr(target:GetPos()) <= preferred * preferred then
            if self.loco then self.loco:SetDesiredSpeed(0) end
            self.loco:FaceTowards(Vector(target:GetPos().x, target:GetPos().y, self:GetPos().z))
            if not self:_TryAttack(target) then self:_SetActivity(self:_SoldierIdleActivity()) end
            return
        end
    end

    if self.loco then self.loco:SetDesiredSpeed(self.LODConfig.speed) end
    if waypoint and self.loco then
        if soldierFamily(self) then
            self:_SetActivity(self:_SoldierRunActivity())
        else
            self:_SetActivity(self.LODConfig.activity or ACT_WALK)
        end
        local face = Vector(waypoint.pos.x, waypoint.pos.y, self:GetPos().z)
        self.loco:FaceTowards(face)
        self.loco:Approach(waypoint.pos, 1)
    elseif IsValid(target) and self.loco then
        if soldierFamily(self) then
            self:_SetActivity(self:_SoldierRunActivity())
        else
            self:_SetActivity(self.LODConfig.activity or ACT_WALK)
        end
        local direct = target:GetPos()
        self.loco:FaceTowards(Vector(direct.x, direct.y, self:GetPos().z))
        self.loco:Approach(direct, 1)
    elseif soldierFamily(self) then
        self:_SetActivity(self:_SoldierIdleActivity())
    end

    if IsValid(target) and not soldierFamily(self) then self:_TryAttack(target) end
end

concommand.Add("lod_blitzer_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local tested = 0
    local passed = 0
    local bursts = 0
    local shots = 0
    local veers = 0
    local lastBurst = 0
    local lastSeed = 0
    for _, hostile in ipairs(LOD.HostileRegistry and LOD.HostileRegistry:List() or {}) do
        if IsValid(hostile) and hostile.LODArchetypeId == "blitzer" then
            tested = tested + 1
            local completed = hostile.LODBlitzerCompletedBursts or 0
            local completedShots = hostile.LODBlitzerLastCompletedShots or 0
            local rolls = hostile.LODBlitzerLastCompletedVeerRolls or 0
            if completed > 0 and completedShots >= 1 and completedShots <= 6 and rolls >= completedShots then
                passed = passed + 1
            end
            bursts = bursts + completed
            shots = shots + (hostile.LODBlitzerShotsFired or 0)
            veers = veers + (hostile.LODBlitzerVeeringShots or 0)
            lastBurst = completedShots
            lastSeed = hostile.LODBlitzerLastCompletedSeed or 0
        end
    end

    local result = tested > 0 and tested == passed and "PASS" or "FAIL"
    local line = string.format(
        "tested=%d passed=%d completedBursts=%d shots=%d veeringShots=%d lastBurst=%d lastSeed=%d result=%s",
        tested, passed, bursts, shots, veers, lastBurst, lastSeed, result
    )
    print("[LOD:BLITZER] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)

function ENT:RunBehaviour()
    while true do
        self:_BehaviourTick()
        coroutine.yield()
    end
end

function ENT:BodyUpdate()
    if self.LODDead then
        self:FrameAdvance()
        return
    end
    if self:GetVelocity():Length2DSqr() > 25 then
        self:BodyMoveXY()
    end
    self:FrameAdvance()
end

function ENT:HandleStuck()
    if self.LODDead then return end
    if self.loco then self.loco:ClearStuck() end
    self.LODNextRouteRefresh = 0
end

function ENT:OnInjured(dmginfo)
    if self.LODDead then return end
    local attacker = dmginfo:GetAttacker()
    if IsValid(attacker) and attacker:IsPlayer() and LOD.FactionManager:IsValidPlayerTarget(attacker) then
        self.LODTarget = attacker
        self.LODReturningHome = false
        self.LODNextTargetRefresh = CurTime() + 0.5
        self.LODNextRouteRefresh = 0
    end
end

function ENT:_SpawnPlaceholderLoot()
    local state = LOD.RunManager and LOD.RunManager.State
    if not state or state.LevelSeed ~= self.LODDeathLevelSeed or state.Failed or state.LevelCleared then return end

    local loot = ents.Create("prop_dynamic")
    if not IsValid(loot) then return end
    loot:SetModel(PLACEHOLDER_LOOT_MODEL)
    loot:SetPos(self:GetPos() + Vector(0, 0, 8))
    loot:SetAngles(Angle(0, self:GetAngles().y, 0))
    loot:SetSolid(SOLID_NONE)
    loot:SetMoveType(MOVETYPE_NONE)
    loot:SetRenderMode(RENDERMODE_TRANSCOLOR)
    loot:SetColor(Color(255, 196, 64, 235))
    loot:SetModelScale(1.15, 0)
    loot.LODPlaceholderLoot = true
    loot:Spawn()
    loot:Activate()
    loot:EmitSound("items/itempickup.wav", 55, 128, 0.45, CHAN_ITEM)

    PlaceholderLoot:Register(loot, self.LODDeathLevelSeed)
end

function ENT:_FinishDeathPresentation()
    if not IsValid(self) then return end
    self:SetNoDraw(true)
    self:_SpawnPlaceholderLoot()
    self:Remove()
end

function ENT:_BeginDeathPresentation()
    if self.LODDead then return end
    self.LODDead = true
    self.LODActivated = false
    self.LODTarget = nil
    self.LODWaypoints = {}
    self.LODSoldierBurst = nil
    self.LODDeathLevelSeed = LOD.RunManager and LOD.RunManager.State.LevelSeed or nil
    self:SetNW2Bool("LOD_SoldierTelegraph", false)

    if self.loco then self.loco:SetDesiredSpeed(0) end
    self:SetVelocity(vector_origin)
    self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
    self:SetSolid(SOLID_NONE)
    self:SetMoveType(MOVETYPE_NONE)
    self:DrawShadow(false)

    if IsValid(self.LODWeaponVisual) then
        self.LODWeaponVisual:Remove()
        self.LODWeaponVisual = nil
    end

    -- Keep the actual enemy model as the corpse instead of creating a Source
    -- ragdoll. Generated upper floors are custom collision geometry, and the
    -- old ragdoll path could fall through them. A death activity gives the body
    -- a readable corpse pose while its origin remains fixed to the valid floor.
    self:_SetActivity(ACT_DIESIMPLE or ACT_DIEBACKWARD or ACT_IDLE, true)

    DeathPresentation:Add(self)
end

function ENT:OnKilled(dmginfo)
    if self.LODDead then return end
    if LOD.EncounterDirector and LOD.EncounterDirector.OnHostileKilled then
        LOD.EncounterDirector:OnHostileKilled(self, dmginfo)
    end
    hook.Run("OnNPCKilled", self, dmginfo:GetAttacker(), dmginfo:GetInflictor())
    self:_BeginDeathPresentation()
end

function ENT:OnRemove()
    self:SetNW2Bool("LOD_SoldierTelegraph", false)
    if IsValid(self.LODWeaponVisual) then self.LODWeaponVisual:Remove() end
end
