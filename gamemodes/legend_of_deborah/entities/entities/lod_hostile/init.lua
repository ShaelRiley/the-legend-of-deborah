AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local DEATH_BLINK_DURATION = 1.0
local DEATH_BLINK_INTERVAL = 0.125
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
    if self.LODArchetypeId ~= "soldier" then return end
    local weapon = ents.Create("prop_dynamic")
    if not IsValid(weapon) then return end
    weapon:SetModel("models/weapons/w_irifle.mdl")
    weapon:SetSolid(SOLID_NONE)
    weapon:SetMoveType(MOVETYPE_NONE)
    weapon:SetParent(self)
    weapon:AddEffects(EF_BONEMERGE)
    weapon:Spawn()
    weapon:Activate()
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

    if self.LODArchetypeId == "soldier" then
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

function ENT:_SoldierMuzzlePos()
    local attachment = self:LookupAttachment("anim_attachment_RH")
    if attachment and attachment > 0 then
        local data = self:GetAttachment(attachment)
        if data and data.Pos then return data.Pos + self:GetForward() * 18 end
    end
    return self:WorldSpaceCenter() + Vector(0, 0, 12) + self:GetForward() * 24
end

function ENT:_SpawnSoldierBolt(aimPos, shotIndex)
    local cfg = self.LODConfig
    local startPos = self:_SoldierMuzzlePos()
    local direction = (aimPos - startPos):GetNormalized()

    -- Small deterministic side-to-side variance keeps the three-bolt burst
    -- readable without turning it into unavoidable perfect tracking.
    local yawOffsets = {-1.5, 1.5, 0}
    local pitchOffsets = {0.4, -0.4, 0}
    local ang = direction:Angle()
    local offsetIndex = ((shotIndex - 1) % 3) + 1
    ang.y = ang.y + yawOffsets[offsetIndex]
    ang.p = ang.p + pitchOffsets[offsetIndex]
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
    self:EmitSound("Weapon_AR2.Single", 72, 100, 0.85)
    return true
end

function ENT:_BeginSoldierBurst(target)
    local cfg = self.LODConfig
    if self.LODSoldierBurst or not IsValid(target) then return false end
    if CurTime() < (self.LODNextAttack or 0) then return false end
    if self:GetPos():DistToSqr(target:GetPos()) > cfg.fireRange * cfg.fireRange then return false end
    if not self:_HasLineOfSight(target) then return false end

    self.LODSoldierBurst = {
        target = target,
        windupEnd = CurTime() + cfg.burstTelegraph,
        nextShot = nil,
        shotsRemaining = cfg.burstShots,
        shotIndex = 0,
        lastAimPos = target:WorldSpaceCenter()
    }
    self:SetNW2Bool("LOD_SoldierTelegraph", true)
    self:SetNW2Vector("LOD_SoldierAim", target:WorldSpaceCenter())
    self:_SetActivity(self:_SoldierAttackActivity(), true)
    self:EmitSound("buttons/button17.wav", 62, 115, 0.65)
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
        burst.lastAimPos = target:WorldSpaceCenter()
        self:SetNW2Vector("LOD_SoldierAim", burst.lastAimPos)
        return true
    end

    self:SetNW2Bool("LOD_SoldierTelegraph", false)
    if not burst.nextShot then burst.nextShot = CurTime() end

    if burst.shotsRemaining > 0 and CurTime() >= burst.nextShot then
        burst.shotIndex = burst.shotIndex + 1
        if self:_HasLineOfSight(target) then
            burst.lastAimPos = target:WorldSpaceCenter()
        end
        self:_SpawnSoldierBolt(burst.lastAimPos, burst.shotIndex)
        burst.shotsRemaining = burst.shotsRemaining - 1
        burst.nextShot = CurTime() + cfg.burstShotInterval
    end

    if burst.shotsRemaining <= 0 then
        self.LODSoldierBurst = nil
        self.LODNextAttack = CurTime() + cfg.burstCooldown
        self:_SetActivity(self:_SoldierIdleActivity(), true)
        return false
    end

    return true
end

function ENT:_TryAttack(target)
    if self.LODArchetypeId == "soldier" then return self:_BeginSoldierBurst(target) end
    return self:_MeleeAttack(target)
end

function ENT:_BehaviourTick()
    if self.LODDead or not self.LODActivated then return end
    local state = LOD.RunManager and LOD.RunManager.State
    local graph = state and state.Graph
    if not graph or not state.BuildReady or state.Failed or state.LevelCleared then return end

    self:_RefreshTarget(graph)
    self:_RefreshRoute(graph)

    if self.LODArchetypeId == "soldier" and self.LODSoldierBurst then
        self:_ProcessSoldierBurst()
        return
    end

    local target = self.LODTarget
    local waypoint = self:_AdvanceWaypoint()

    if self.LODArchetypeId == "soldier" and IsValid(target) and self:_HasLineOfSight(target) then
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
        if self.LODArchetypeId == "soldier" then
            self:_SetActivity(self:_SoldierRunActivity())
        else
            self:_SetActivity(self.LODConfig.activity or ACT_WALK)
        end
        local face = Vector(waypoint.pos.x, waypoint.pos.y, self:GetPos().z)
        self.loco:FaceTowards(face)
        self.loco:Approach(waypoint.pos, 1)
    elseif IsValid(target) and self.loco then
        if self.LODArchetypeId == "soldier" then
            self:_SetActivity(self:_SoldierRunActivity())
        else
            self:_SetActivity(self.LODConfig.activity or ACT_WALK)
        end
        local direct = target:GetPos()
        self.loco:FaceTowards(Vector(direct.x, direct.y, self:GetPos().z))
        self.loco:Approach(direct, 1)
    elseif self.LODArchetypeId == "soldier" then
        self:_SetActivity(self:_SoldierIdleActivity())
    end

    if IsValid(target) and self.LODArchetypeId ~= "soldier" then self:_TryAttack(target) end
end

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

    local blinkName = "LOD_DeathBlink_" .. self:EntIndex()
    local finishName = "LOD_DeathFinish_" .. self:EntIndex()
    self.LODDeathBlinkTimer = blinkName
    self.LODDeathFinishTimer = finishName
    self.LODDeathBlinkTicks = 0

    timer.Create(blinkName, DEATH_BLINK_INTERVAL, 0, function()
        if not IsValid(self) then timer.Remove(blinkName) return end
        self.LODDeathBlinkTicks = (self.LODDeathBlinkTicks or 0) + 1
        self:SetNoDraw(not self:GetNoDraw())

        -- Four restrained retro pulses over the one-second dematerialization.
        if self.LODDeathBlinkTicks % 2 == 1 then
            local pitch = math.min(150, 118 + self.LODDeathBlinkTicks * 4)
            self:EmitSound("buttons/blip1.wav", 56, pitch, 0.42, CHAN_ITEM)
        end
    end)

    timer.Create(finishName, DEATH_BLINK_DURATION, 1, function()
        if not IsValid(self) then return end
        timer.Remove(blinkName)
        self:_FinishDeathPresentation()
    end)
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
    if self.LODDeathBlinkTimer then timer.Remove(self.LODDeathBlinkTimer) end
    if self.LODDeathFinishTimer then timer.Remove(self.LODDeathFinishTimer) end
    if IsValid(self.LODWeaponVisual) then self.LODWeaponVisual:Remove() end
end