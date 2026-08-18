AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

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

    local activity = self.LODConfig.activity or ACT_WALK
    self:StartActivity(activity)
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

function ENT:_SoldierBurst(target)
    local cfg = self.LODConfig
    if not IsValid(target) or CurTime() < (self.LODNextAttack or 0) then return false end
    if self:GetPos():DistToSqr(target:GetPos()) > cfg.fireRange * cfg.fireRange then return false end
    if not self:_HasLineOfSight(target) then return false end

    self.LODNextAttack = CurTime() + cfg.burstCooldown
    self:EmitSound("Weapon_AR2.Single")
    for _ = 1, cfg.burstShots do
        if IsValid(target) and target:Alive() and self:_HasLineOfSight(target) then
            target:TakeDamage(cfg.burstDamage, self, self)
        end
    end
    return true
end

function ENT:_TryAttack(target)
    if self.LODArchetypeId == "soldier" then return self:_SoldierBurst(target) end
    return self:_MeleeAttack(target)
end

function ENT:_BehaviourTick()
    if not self.LODActivated then return end
    local state = LOD.RunManager and LOD.RunManager.State
    local graph = state and state.Graph
    if not graph or not state.BuildReady or state.Failed or state.LevelCleared then return end

    self:_RefreshTarget(graph)
    self:_RefreshRoute(graph)

    local target = self.LODTarget
    local attacked = IsValid(target) and self:_TryAttack(target)
    local waypoint = self:_AdvanceWaypoint()

    if self.LODArchetypeId == "soldier" and IsValid(target) and self:_HasLineOfSight(target) then
        local preferred = self.LODConfig.preferredRange or 480
        if self:GetPos():DistToSqr(target:GetPos()) <= preferred * preferred then
            if self.loco then self.loco:SetDesiredSpeed(0) end
            self.loco:FaceTowards(Vector(target:GetPos().x, target:GetPos().y, self:GetPos().z))
            return
        end
    end

    if self.loco then self.loco:SetDesiredSpeed(self.LODConfig.speed) end
    if waypoint and self.loco then
        local face = Vector(waypoint.pos.x, waypoint.pos.y, self:GetPos().z)
        self.loco:FaceTowards(face)
        self.loco:Approach(waypoint.pos, 1)
    elseif IsValid(target) and not attacked and self.loco then
        local direct = target:GetPos()
        self.loco:FaceTowards(Vector(direct.x, direct.y, self:GetPos().z))
        self.loco:Approach(direct, 1)
    end
end

function ENT:RunBehaviour()
    while true do
        self:_BehaviourTick()
        coroutine.yield()
    end
end

function ENT:BodyUpdate()
    if self:GetVelocity():Length2DSqr() > 25 then
        self:BodyMoveXY()
    end
    self:FrameAdvance()
end

function ENT:HandleStuck()
    if self.loco then self.loco:ClearStuck() end
    self.LODNextRouteRefresh = 0
end

function ENT:OnInjured(dmginfo)
    local attacker = dmginfo:GetAttacker()
    if IsValid(attacker) and attacker:IsPlayer() and LOD.FactionManager:IsValidPlayerTarget(attacker) then
        self.LODTarget = attacker
        self.LODReturningHome = false
        self.LODNextTargetRefresh = CurTime() + 0.5
        self.LODNextRouteRefresh = 0
    end
end

function ENT:OnKilled(dmginfo)
    if LOD.EncounterDirector and LOD.EncounterDirector.OnHostileKilled then
        LOD.EncounterDirector:OnHostileKilled(self, dmginfo)
    end
    hook.Run("OnNPCKilled", self, dmginfo:GetAttacker(), dmginfo:GetInflictor())
    self:BecomeRagdoll(dmginfo)
end
