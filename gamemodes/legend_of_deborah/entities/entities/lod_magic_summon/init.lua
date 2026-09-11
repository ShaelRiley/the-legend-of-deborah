AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local WINDUP_SECONDS = 0.85
local CHARGE_SPEED = 560
local CHARGE_SECONDS = 1.20
local CHARGE_RANGE = 760
local MIN_CHARGE_RANGE = 150
local CHARGE_COOLDOWN = 2.80
local CONTACT_DISTANCE = 58
local RETREAT_TARGET_DISTANCE = 320
local SERVICE_STEP = 0.05
local LIFETIME = 20

local Navigator = LOD.MazeNavigator
local Motion = LOD.HostileMotionV2

local function smoke(pos, scale)
    local fx = EffectData()
    fx:SetOrigin(pos)
    fx:SetScale(scale or 1.2)
    util.Effect("Smoke", fx, true, true)
end

local function runState()
    local state = LOD.RunManager and LOD.RunManager.State
    return state, state and state.Graph or nil
end

local function aliveHostile(ent)
    return IsValid(ent) and ent.LODHostile and not ent.LODDead and ent:Health() > 0
end

local function horizontalDistance(a, b)
    local dx, dy = a.x - b.x, a.y - b.y
    return math.sqrt(dx * dx + dy * dy)
end

function ENT:Initialize()
    self.LODSummonedSeeker = true
    self.LODHostile = false
    self:SetModel("models/roller.mdl")
    self:SetRenderMode(RENDERMODE_TRANSCOLOR)
    self:SetColor(Color(245, 195, 55, 255))
    self:SetCollisionGroup(COLLISION_GROUP_NPC)
    self:SetCollisionBounds(Vector(-13, -13, 0), Vector(13, 13, 28))
    self:SetHealth(18)
    self:SetMaxHealth(18)
    self.LODConfig = {speed = 165}
    self.LODExpiresAt = CurTime() + LIFETIME
    self.LODNextTargetRefresh = 0
    self.LODNextRouteRefresh = 0
    self.LODNextCharge = CurTime() + 0.75
    self.LODTarget = nil
    self.LODWaypoints = {}
    self.LODWaypointIndex = 1
    self.LODChargeState = nil
    self.LODRetreat = nil
    self.LODDead = false
    self.LODMotionLastUpdate = CurTime()
    self:SetNW2Bool("LOD_MagicSummon", true)
    smoke(self:GetPos() + Vector(0, 0, 12), 1.5)
    self:EmitSound("ambient/energy/weld1.wav", 72, 118, 0.6, CHAN_ITEM)
end

function ENT:_AcquireTarget(graph)
    if CurTime() < (self.LODNextTargetRefresh or 0) then return self.LODTarget end
    self.LODNextTargetRefresh = CurTime() + 0.20
    local here = Navigator and Navigator:WorldToCell(graph, self:GetPos()) or nil
    local best, bestGraph, bestWorld
    for _, hostile in ipairs(LOD.HostileRegistry and LOD.HostileRegistry:List() or ents.FindByClass("lod_hostile")) do
        if aliveHostile(hostile) then
            local there = Navigator and Navigator:WorldToCell(graph, hostile:GetPos()) or nil
            local graphDistance = here and there and Navigator:Distance(graph, here, there) or math.huge
            local world = self:GetPos():DistToSqr(hostile:GetPos())
            if graphDistance ~= math.huge and (not best or graphDistance < bestGraph
                or (graphDistance == bestGraph and world < bestWorld)) then
                best, bestGraph, bestWorld = hostile, graphDistance, world
            end
        end
    end
    self.LODTarget = best
    return best
end

function ENT:_RouteTo(graph, target)
    if CurTime() < (self.LODNextRouteRefresh or 0) then return end
    self.LODNextRouteRefresh = CurTime() + 0.35
    if not aliveHostile(target) or not Navigator then self.LODWaypoints = {} return end
    local from = Navigator:WorldToCell(graph, self:GetPos())
    local to = Navigator:WorldToCell(graph, target:GetPos())
    if not from or not to then self.LODWaypoints = {} return end
    local path = Navigator:FindPath(graph, from, to)
    self.LODWaypoints = path and Navigator:PathToWaypoints(graph, path) or {}
    self.LODWaypointIndex = 1
end

function ENT:_AdvanceWaypoint()
    local waypoint = self.LODWaypoints[self.LODWaypointIndex or 1]
    if not waypoint then return nil end
    local tolerance = waypoint.tolerance or 18
    if self:GetPos():DistToSqr(waypoint.pos) <= tolerance * tolerance then
        self.LODWaypointIndex = (self.LODWaypointIndex or 1) + 1
        waypoint = self.LODWaypoints[self.LODWaypointIndex]
    end
    return waypoint
end

function ENT:_LineClear(target)
    if not aliveHostile(target) then return false end
    local tr = util.TraceHull({
        start = self:GetPos() + Vector(0, 0, 14),
        endpos = target:WorldSpaceCenter(),
        mins = Vector(-12, -12, -12),
        maxs = Vector(12, 12, 12),
        mask = MASK_SHOT,
        filter = function(ent)
            if ent == self or ent == self.LODCaster then return false end
            if IsValid(ent) and ent:IsPlayer() then return false end
            if IsValid(ent) and ent.LODSummonedSeeker then return false end
            if IsValid(ent) and ent.LODHostile and ent ~= target then return false end
            return true
        end
    })
    return not tr.Hit or tr.Entity == target or tr.Fraction >= 0.995
end

function ENT:_BeginRetreat(graph, target)
    if not aliveHostile(target) or not Motion or not Navigator then return false end
    local here = Navigator:WorldToCell(graph, self:GetPos())
    if not here then return false end
    local away = self:GetPos() - target:GetPos()
    away.z = 0
    if away:LengthSqr() <= 0.01 then away = self:GetForward() * -1 end
    away:Normalize()
    local goal = Motion:CellFloorPoint(here, self:GetPos() + away * RETREAT_TARGET_DISTANCE)
    self.LODRetreat = {target = target, goal = goal}
    self.LODWaypoints = {}
    self.LODWaypointIndex = 1
    return goal ~= nil
end

function ENT:_RunRetreat(graph)
    local retreat = self.LODRetreat
    if not retreat then return false end
    local target = retreat.target
    if not aliveHostile(target) then self.LODRetreat = nil return false end
    if horizontalDistance(self:GetPos(), target:GetPos()) >= RETREAT_TARGET_DISTANCE then
        self.LODRetreat = nil
        self.LODNextRouteRefresh = 0
        return false
    end
    if not retreat.goal or not Motion then return true end
    local reached = Motion:MoveToward(self, {pos = retreat.goal, tolerance = 12, stair = false})
    if reached then
        self.LODRetreat = nil
        self.LODNextRouteRefresh = 0
    end
    return true
end

function ENT:_BeginCharge(target)
    if not aliveHostile(target) or CurTime() < (self.LODNextCharge or 0) then return false end
    local distance = horizontalDistance(self:GetPos(), target:GetPos())
    if distance < MIN_CHARGE_RANGE or distance > CHARGE_RANGE or not self:_LineClear(target) then return false end
    local direction = target:GetPos() - self:GetPos()
    direction.z = 0
    if direction:LengthSqr() <= 0.01 then return false end
    direction:Normalize()
    self.LODChargeState = {
        phase = "windup",
        target = target,
        direction = direction,
        releasesAt = CurTime() + WINDUP_SECONDS,
        endsAt = nil,
        distance = 0
    }
    if Motion then Motion:Stop(self) Motion:FaceToward(self, target:GetPos()) end
    self:EmitSound("buttons/button17.wav", 72, 132, 0.75, CHAN_ITEM)
    return true
end

function ENT:_ResolveChargeHit(target)
    if aliveHostile(target) and LOD.MagicForms and LOD.MagicForms.ResolveSummonAttack then
        LOD.MagicForms:ResolveSummonAttack(self, target)
    end
    self.LODChargeState = nil
    self.LODNextCharge = CurTime() + CHARGE_COOLDOWN
end

function ENT:_RunCharge(graph)
    local state = self.LODChargeState
    if not state then return false end
    local target = state.target
    if not aliveHostile(target) then self.LODChargeState = nil return false end
    if state.phase == "windup" then
        if Motion then Motion:Stop(self) Motion:FaceToward(self, target:GetPos()) end
        if CurTime() >= state.releasesAt then
            state.phase = "charge"
            state.endsAt = CurTime() + CHARGE_SECONDS
            self:EmitSound("ambient/energy/zap5.wav", 78, 108, 0.8, CHAN_WEAPON)
        end
        return true
    end
    if CurTime() >= (state.endsAt or 0) or (state.distance or 0) >= CHARGE_RANGE then
        self.LODChargeState = nil
        self.LODNextCharge = CurTime() + CHARGE_COOLDOWN
        return false
    end
    if horizontalDistance(self:GetPos(), target:GetPos()) <= CONTACT_DISTANCE then
        self:_ResolveChargeHit(target)
        self:_BeginRetreat(graph, target)
        return true
    end

    local start = self:GetPos()
    local probe = start + state.direction * (CHARGE_SPEED * SERVICE_STEP)
    probe.z = start.z
    local tr = util.TraceHull({
        start = start + Vector(0, 0, 14),
        endpos = probe + Vector(0, 0, 14),
        mins = Vector(-13, -13, -13),
        maxs = Vector(13, 13, 13),
        mask = MASK_SHOT,
        filter = function(ent)
            if ent == self or ent == self.LODCaster then return false end
            if IsValid(ent) and ent:IsPlayer() then return false end
            if IsValid(ent) and ent.LODSummonedSeeker then return false end
            if IsValid(ent) and ent.LODHostile and ent ~= target then return false end
            return true
        end
    })
    if tr.Hit then
        if tr.Entity == target then
            self:_ResolveChargeHit(target)
            self:_BeginRetreat(graph, target)
        else
            self.LODChargeState = nil
            self.LODNextCharge = CurTime() + CHARGE_COOLDOWN
            self:EmitSound("physics/metal/metal_solid_impact_hard3.wav", 74, 104, 0.75, CHAN_BODY)
        end
        return true
    end
    if Motion then
        local old = self.LODConfig.speed
        self.LODConfig.speed = CHARGE_SPEED
        Motion:MoveToward(self, {pos = probe, tolerance = 1, stair = false})
        self.LODConfig.speed = old
    else
        self:SetPos(probe)
    end
    state.distance = state.distance + self:GetPos():Distance(start)
    return true
end

function ENT:_BehaviourTick()
    if not IsValid(self.LODCaster) then self:Remove() return end
    local state, graph = runState()
    if not state or not graph or state.Failed or state.LevelCleared or state.SimulationFrozen then
        if Motion then Motion:Stop(self) end
        return
    end
    if CurTime() >= (self.LODExpiresAt or 0) then self:Remove() return end
    if self:_RunCharge(graph) then return end
    if self:_RunRetreat(graph) then return end

    local target = self:_AcquireTarget(graph)
    if not aliveHostile(target) then if Motion then Motion:Stop(self) end return end
    local distance = horizontalDistance(self:GetPos(), target:GetPos())
    if distance < MIN_CHARGE_RANGE then
        self:_BeginRetreat(graph, target)
        self:_RunRetreat(graph)
        return
    end
    if distance <= CHARGE_RANGE and self:_LineClear(target) and CurTime() >= (self.LODNextCharge or 0) then
        if self:_BeginCharge(target) then return end
    end
    self:_RouteTo(graph, target)
    local waypoint = self:_AdvanceWaypoint()
    if waypoint and Motion then
        Motion:MoveToward(self, waypoint)
    elseif Motion then
        local cell = Navigator:WorldToCell(graph, target:GetPos())
        local goal = cell and Motion:CellFloorPoint(cell, target:GetPos()) or target:GetPos()
        Motion:MoveToward(self, {pos = goal, tolerance = 36, stair = false})
    end
end

function ENT:RunBehaviour()
    while true do
        if self.LODDead then return end
        self:_BehaviourTick()
        coroutine.wait(SERVICE_STEP)
    end
end

function ENT:BodyUpdate()
    self:FrameAdvance()
end

function ENT:OnInjured(dmginfo)
    if self.LODDead then dmginfo:SetDamage(0) return end
    if self:Health() - dmginfo:GetDamage() <= 0 then self:OnKilled(dmginfo) end
end

function ENT:OnKilled()
    if self.LODDead then return end
    self.LODDead = true
    self:Remove()
end

function ENT:OnRemove()
    if self.LODRemovedFX then return end
    self.LODRemovedFX = true
    smoke(self:GetPos() + Vector(0, 0, 12), 1.5)
    self:EmitSound("ambient/energy/weld2.wav", 70, 82, 0.5, CHAN_ITEM)
end
