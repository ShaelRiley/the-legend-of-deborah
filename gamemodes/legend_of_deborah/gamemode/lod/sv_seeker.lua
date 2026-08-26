LOD = LOD or {}
LOD.Seeker = LOD.Seeker or {}

local Seeker = LOD.Seeker
local EC = LOD.Config and LOD.Config.Encounter
local Navigator = LOD.MazeNavigator
local Motion = LOD.HostileMotionV2
local WanderingDirector = LOD.WanderingDirector
local EncounterDirector = LOD.EncounterDirector
local Rolls = LOD.CombatRolls
local cellKey = LOD.MazeGenerator and LOD.MazeGenerator.CellKey

if not EC or not Navigator or not Motion or not cellKey then return end

local SERVICE_NAME = "LOD_SeekerChargeService"
local SERVICE_INTERVAL = 0.05
local WINDUP_SECONDS = 0.65
local CHARGE_SPEED = 560
local CHARGE_SECONDS = 1.20
local CHARGE_RANGE = 760
local MIN_CHARGE_RANGE = 150
local CHARGE_COOLDOWN = 2.80
local IMPACT_STUN_SECONDS = 1.10
local WANDER_WEIGHT = 4
local SEEKER_HEALTH_PROFILE = {count = 3, sides = 4, bonus = 3}
local SEEKER_DAMAGE_PROFILE = {
    label = "SEEKER",
    source = "charge",
    count = 2,
    sides = 6,
    bonus = 4,
    reference = 11
}

util.AddNetworkString("LOD_SeekerState")

EC.Archetypes.seeker = EC.Archetypes.seeker or {
    class = "lod_hostile_seeker",
    name = "Seeker",
    model = "models/roller.mdl",
    baseHP = 18,
    speed = 165,
    meleeDamage = 0,
    meleeCooldown = 99,
    meleeRange = 0,
    threat = 1.9,
    activity = ACT_IDLE
}

EC.Templates.incoming = EC.Templates.incoming or {
    name = "Incoming",
    composition = {seeker = 1, shambler = 1}
}

if WanderingDirector and WanderingDirector.Config and WanderingDirector.Config.ArchetypeWeights then
    WanderingDirector.Config.ArchetypeWeights.seeker = WANDER_WEIGHT
end

Seeker.Stats = Seeker.Stats or {
    windups = 0,
    charges = 0,
    playerHits = 0,
    wallImpacts = 0,
    impactStuns = 0,
    testSpawns = 0,
    serviceTicks = 0
}
Seeker.TestEntities = Seeker.TestEntities or {}

local function keyOf(cell)
    return cell and cellKey(cell.x, cell.y, cell.z) or nil
end

local function currentState()
    local state = LOD.RunManager and LOD.RunManager.State
    return state, state and state.Graph or nil
end

local function safeCell(graph, cell)
    local tag = graph and graph.CellTags and graph.CellTags[keyOf(cell)]
    return tag and (tag.safe == true or tag.role == "boss") or false
end

local function livingPlayer(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return false end
    if LOD.RunManager and LOD.RunManager.IsActivePlayer then
        return LOD.RunManager:IsActivePlayer(ply)
    end
    return true
end

local function targetEligible(seeker, graph, target)
    if not livingPlayer(target) then return false end
    local from = Navigator:WorldToCell(graph, seeker:GetPos())
    local to = Navigator:WorldToCell(graph, target:GetPos())
    if not from or not to or from.z ~= to.z then return false end
    if safeCell(graph, to) then return false end
    return true
end

local function traceFilter(seeker, target)
    return function(ent)
        if ent == seeker then return false end
        if IsValid(ent) and ent.LODHostile then return false end
        if IsValid(ent) and target and (ent:GetOwner() == target or ent:GetParent() == target) then return false end
        return true
    end
end

local function lineGraphClear(seeker, graph, target)
    if not targetEligible(seeker, graph, target) then return false end

    local startPos = seeker:GetPos() + Vector(0, 0, 14)
    local endPos = target:WorldSpaceCenter()
    local delta = endPos - startPos
    delta.z = 0
    local distance = delta:Length()
    if distance < MIN_CHARGE_RANGE or distance > CHARGE_RANGE then return false end

    local tr = util.TraceHull({
        start = startPos,
        endpos = Vector(endPos.x, endPos.y, startPos.z),
        mins = Vector(-10, -10, -10),
        maxs = Vector(10, 10, 10),
        mask = MASK_SHOT,
        filter = traceFilter(seeker, target)
    })
    if tr.Hit and tr.Entity ~= target then return false end

    local steps = math.max(1, math.ceil(distance / 48))
    local previous = Navigator:WorldToCell(graph, seeker:GetPos())
    if not previous then return false end
    local previousKey = keyOf(previous)

    for i = 1, steps do
        local t = i / steps
        local point = seeker:GetPos() + delta * t
        local cell = Navigator:WorldToCell(graph, point)
        if not cell or cell.z ~= previous.z then return false end
        local k = keyOf(cell)
        if k ~= previousKey then
            if not Navigator:CanTraverse(graph, previousKey, k) then return false end
            previous, previousKey = cell, k
        end
    end

    return true
end

local function sendState(seeker, phase, duration)
    if not IsValid(seeker) then return end
    net.Start("LOD_SeekerState")
    net.WriteEntity(seeker)
    net.WriteUInt(math.Clamp(phase or 0, 0, 3), 2)
    net.WriteFloat(math.max(0, duration or 0))
    net.Broadcast()
end

local function emitCue(seeker, preferred, fallback, level, pitch, volume)
    if not IsValid(seeker) then return end
    local path = preferred
    if not path or not file.Exists("sound/" .. path, "GAME") then path = fallback end
    if path then seeker:EmitSound(path, level or 68, pitch or 100, volume or 0.8, CHAN_ITEM) end
end

local function clearSpecialState(seeker, cooldown)
    if not IsValid(seeker) then return end
    local state = seeker.LODSeekerState
    local target = state and state.target
    seeker.LODSeekerState = nil
    seeker.LODNextSeekerCharge = CurTime() + (cooldown or CHARGE_COOLDOWN)
    seeker.LODMotionMode = "ground"
    sendState(seeker, 0, 0)

    if livingPlayer(target) then
        seeker.LODTarget = target
        seeker.LODReturningHome = false
        seeker.LODNextTargetRefresh = CurTime() + 0.20
        seeker.LODNextRouteRefresh = 0
    end
end

local function beginWindup(seeker, graph, target)
    if seeker.LODSeekerState or CurTime() < (seeker.LODNextSeekerCharge or 0) then return false end
    if not lineGraphClear(seeker, graph, target) then return false end

    local origin = seeker:GetPos()
    local aim = target:GetPos()
    local direction = Vector(aim.x - origin.x, aim.y - origin.y, 0)
    if direction:LengthSqr() <= 0.01 then return false end
    direction:Normalize()

    seeker.LODSeekerState = {
        phase = "windup",
        target = target,
        direction = direction,
        aimPos = aim,
        releasesAt = CurTime() + WINDUP_SECONDS,
        distance = 0
    }
    seeker.LODTarget = nil
    seeker.LODWaypoints = {}
    seeker.LODWaypointIndex = 1
    seeker.LODNextRouteRefresh = CurTime() + WINDUP_SECONDS + CHARGE_SECONDS
    seeker.LODNextTargetRefresh = CurTime() + WINDUP_SECONDS + CHARGE_SECONDS
    Motion:Stop(seeker)
    Motion:FaceToward(seeker, aim)
    Seeker.Stats.windups = (Seeker.Stats.windups or 0) + 1
    sendState(seeker, 1, WINDUP_SECONDS)
    emitCue(seeker, "npc/roller/mine/rmine_blip3.wav", "buttons/button17.wav", 72, 120, 0.9)
    return true
end

local function beginCharge(seeker)
    local state = seeker.LODSeekerState
    if not state or state.phase ~= "windup" then return false end
    state.phase = "charge"
    state.endsAt = CurTime() + CHARGE_SECONDS
    state.distance = 0
    Seeker.Stats.charges = (Seeker.Stats.charges or 0) + 1
    sendState(seeker, 2, CHARGE_SECONDS)
    emitCue(seeker, "npc/roller/mine/rmine_seek_loop2.wav", "ambient/energy/zap1.wav", 76, 106, 0.85)
    return true
end

local function impactStun(seeker, hitPos)
    if not IsValid(seeker) then return end
    seeker.LODHitStunUntil = math.max(seeker.LODHitStunUntil or 0, CurTime() + IMPACT_STUN_SECONDS)
    Motion:Stop(seeker)
    seeker.LODMotionMode = "seeker-impact-stun"
    Seeker.Stats.wallImpacts = (Seeker.Stats.wallImpacts or 0) + 1
    Seeker.Stats.impactStuns = (Seeker.Stats.impactStuns or 0) + 1
    sendState(seeker, 3, IMPACT_STUN_SECONDS)
    emitCue(seeker, "npc/roller/mine/rmine_explode_shock1.wav", "physics/metal/metal_solid_impact_hard3.wav", 78, 92, 0.95)

    local effect = EffectData()
    effect:SetOrigin(hitPos or seeker:WorldSpaceCenter())
    effect:SetMagnitude(1)
    effect:SetScale(1)
    util.Effect("StunstickImpact", effect, true, true)

    clearSpecialState(seeker, CHARGE_COOLDOWN)
end

local function damagePlayer(seeker, target)
    if not livingPlayer(target) then return false end
    local size = math.Clamp(seeker:GetNW2Float("LOD_SizeScale", 1), 0.33, 1.33)
    local contract = Rolls and Rolls:RollHostileAttack(seeker, SEEKER_DAMAGE_PROFILE,
        SEEKER_DAMAGE_PROFILE.reference * size) or nil
    local amount = contract and contract.final or math.max(1, math.floor(SEEKER_DAMAGE_PROFILE.reference * size + 0.5))

    local info = DamageInfo()
    info:SetAttacker(seeker)
    info:SetInflictor(seeker)
    info:SetDamage(amount)
    info:SetDamageType(DMG_CLUB)
    info:SetDamagePosition(target:WorldSpaceCenter())
    target:TakeDamageInfo(info)

    if contract and Rolls and Rolls._Send and Rolls._HostileRollText then
        Rolls:_Send(target, 1, Rolls:_HostileRollText(contract, seeker, target))
    end

    -- Deliberately do not set player velocity. The Seeker damages rather than
    -- launching players, avoiding physics/collision exploits in narrow corridors.
    Seeker.Stats.playerHits = (Seeker.Stats.playerHits or 0) + 1
    return true
end

local function stepGraphValid(graph, fromPos, toPos)
    local from = Navigator:WorldToCell(graph, fromPos)
    local to = Navigator:WorldToCell(graph, toPos)
    if not from or not to or from.z ~= to.z then return false end
    local a, b = keyOf(from), keyOf(to)
    if a == b then return true end
    return Navigator:CanTraverse(graph, a, b)
end

local function runChargeStep(seeker, graph)
    local state = seeker.LODSeekerState
    if not state or state.phase ~= "charge" then return false end

    if CurTime() < (seeker.LODHitStunUntil or 0) then
        clearSpecialState(seeker, CHARGE_COOLDOWN)
        return true
    end

    if CurTime() >= (state.endsAt or 0) or (state.distance or 0) >= CHARGE_RANGE then
        clearSpecialState(seeker, CHARGE_COOLDOWN)
        return true
    end

    local pos = seeker:GetPos()
    local direction = state.direction
    local probeDistance = math.max(20, CHARGE_SPEED * (SERVICE_INTERVAL + 0.015))
    local probeEnd = pos + direction * probeDistance
    probeEnd.z = pos.z

    local tr = util.TraceHull({
        start = pos + Vector(0, 0, 14),
        endpos = probeEnd + Vector(0, 0, 14),
        mins = Vector(-11, -11, -11),
        maxs = Vector(11, 11, 11),
        mask = MASK_SHOT,
        filter = traceFilter(seeker, state.target)
    })

    if tr.Hit then
        if IsValid(tr.Entity) and tr.Entity:IsPlayer() and tr.Entity:Alive() then
            damagePlayer(seeker, tr.Entity)
            clearSpecialState(seeker, CHARGE_COOLDOWN)
        else
            impactStun(seeker, tr.HitPos)
        end
        return true
    end

    if not stepGraphValid(graph, pos, probeEnd) then
        impactStun(seeker, probeEnd)
        return true
    end

    local cfg = seeker.LODConfig or {}
    local oldSpeed = cfg.speed
    cfg.speed = CHARGE_SPEED
    local before = seeker:GetPos()
    Motion:MoveToward(seeker, {pos = probeEnd, tolerance = 1, stair = false, seekerCharge = true})
    cfg.speed = oldSpeed
    local travelled = seeker:GetPos():Distance(before)
    state.distance = (state.distance or 0) + travelled
    seeker.LODMotionMode = "seeker-charge"
    return true
end

local function serviceSeeker(seeker, graph)
    if not IsValid(seeker) or seeker.LODDead or seeker.LODActivated == false then return end
    if CurTime() < (seeker.LODHitStunUntil or 0) and not seeker.LODSeekerState then return end

    local state = seeker.LODSeekerState
    if state then
        if state.phase == "windup" then
            Motion:Stop(seeker)
            Motion:FaceToward(seeker, state.aimPos)
            if CurTime() >= (state.releasesAt or 0) then beginCharge(seeker) end
            return
        end
        if state.phase == "charge" then
            runChargeStep(seeker, graph)
            return
        end
    end

    if CurTime() < (seeker.LODNextSeekerCharge or 0) then return end
    seeker:_RefreshTarget(graph)
    local target = seeker.LODTarget
    if IsValid(target) then beginWindup(seeker, graph, target) end
end

timer.Create(SERVICE_NAME, SERVICE_INTERVAL, 0, function()
    local state, graph = currentState()
    if not state or not graph or not state.BuildReady or state.Failed or state.LevelCleared or state.SimulationFrozen then return end
    Seeker.Stats.serviceTicks = (Seeker.Stats.serviceTicks or 0) + 1
    for _, hostile in ipairs(LOD.HostileRegistry and LOD.HostileRegistry:List() or {}) do
        if IsValid(hostile) and hostile.LODArchetypeId == "seeker" and not hostile.LODDead then
            serviceSeeker(hostile, graph)
        end
    end
end)

if Rolls and not Rolls.LODSeekerHealthInstalled then
    Rolls.LODSeekerHealthInstalled = true
    local baseRollEnemyHealth = Rolls.RollEnemyHealth
    function Rolls:RollEnemyHealth(archetypeId, instanceSeed)
        if archetypeId ~= "seeker" then return baseRollEnemyHealth(self, archetypeId, instanceSeed) end
        local seed = LOD.Seeds.Derive(instanceSeed or 1, "health-dice:seeker")
        local total, values = self:_RollFormula(SEEKER_HEALTH_PROFILE, LOD.RNG.New(seed))
        self.Stats.healthRolls = (self.Stats.healthRolls or 0) + 1
        return {
            profile = SEEKER_HEALTH_PROFILE,
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
    if not class or class.LODSeekerPatched then return false end
    class.LODSeekerPatched = true

    local baseInitialize = class.Initialize
    function class:Initialize()
        baseInitialize(self)
        if self.LODArchetypeId ~= "seeker" or not self.LODConfig then return end
        self.LODSeekerState = nil
        self.LODNextSeekerCharge = CurTime() + 0.75
        self:SetNW2Bool("LOD_Seeker", true)
        self:SetCollisionBounds(Vector(-13, -13, 0), Vector(13, 13, 28))
    end

    local baseTryAttack = class._TryAttack
    function class:_TryAttack(target)
        if self.LODArchetypeId == "seeker" then return false end
        return baseTryAttack(self, target)
    end

    local baseOnRemove = class.OnRemove
    function class:OnRemove()
        if self.LODArchetypeId == "seeker" then sendState(self, 0, 0) end
        if baseOnRemove then return baseOnRemove(self) end
    end

    return true
end

installHostilePatch()
hook.Add("OnEntityCreated", "LOD_SeekerInstallBeforeSpawn", function(ent)
    if IsValid(ent) and ent:GetClass() == "lod_hostile" then installHostilePatch() end
end)

if EncounterDirector and not EncounterDirector.LODSeekerTemplatesInstalled then
    EncounterDirector.LODSeekerTemplatesInstalled = true
    local baseEligibleTemplates = EncounterDirector._EligibleTemplates
    function EncounterDirector:_EligibleTemplates(sector, role)
        local choices = baseEligibleTemplates(self, sector, role) or {}
        if sector >= 2 then choices[#choices + 1] = "incoming" end
        return choices
    end
end

local function cleanupTestEntities()
    for _, ent in ipairs(Seeker.TestEntities or {}) do
        if IsValid(ent) then ent:Remove() end
    end
    Seeker.TestEntities = {}
end

local function testSpawnCell(graph, playerCell, ply)
    local playerKey = keyOf(playerCell)
    local keys = {}
    for neighborKey in pairs(playerCell.neighbors or {}) do keys[#keys + 1] = neighborKey end
    table.sort(keys)
    for _, neighborKey in ipairs(keys) do
        local cell = graph.Cells[neighborKey]
        if cell and cell.z == playerCell.z and not safeCell(graph, cell)
            and Navigator:CanTraverse(graph, playerKey, neighborKey)
        then
            local probe = ents.Create("lod_hostile")
            if IsValid(probe) then probe:Remove() end
            local center = Navigator:CellCenter(cell) + Vector(0, 0, 2)
            local tr = util.TraceHull({
                start = center + Vector(0, 0, 14),
                endpos = ply:WorldSpaceCenter(),
                mins = Vector(-10, -10, -10),
                maxs = Vector(10, 10, 10),
                mask = MASK_SHOT,
                filter = function(ent)
                    if ent == ply then return true end
                    if IsValid(ent) and ent.LODHostile then return false end
                    return true
                end
            })
            if not tr.Hit or tr.Entity == ply then return cell end
        end
    end
    return nil
end

concommand.Add("lod_seeker_test", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if not IsValid(ply) or not ply:IsAdmin() then return end

    local state, graph = currentState()
    if not state or not graph or not state.BuildReady then
        ply:ChatPrint("Seeker test requires an active generated dungeon.")
        return
    end

    local playerCell = Navigator:WorldToCell(graph, ply:GetPos())
    if not playerCell or safeCell(graph, playerCell) then
        ply:ChatPrint("Move into an ordinary non-safe corridor before running lod_seeker_test.")
        return
    end

    local spawnCell = testSpawnCell(graph, playerCell, ply)
    if not spawnCell then
        ply:ChatPrint("No clear adjacent Seeker test lane from this cell; move to another corridor cell.")
        return
    end

    cleanupTestEntities()
    local ent = ents.Create("lod_hostile")
    if not IsValid(ent) then return end
    ent.LODArchetypeId = "seeker"
    ent.LODHomeCellKey = keyOf(spawnCell)
    ent.LODEncounterId = nil
    ent.LODEncounterOrdinal = 981001
    ent.LODActivated = true
    ent:SetPos(Navigator:CellCenter(spawnCell) + Vector(0, 0, 2))
    ent:Spawn()
    ent:Activate()
    ent.LODTarget = ply
    ent.LODReturningHome = false
    ent.LODNextTargetRefresh = CurTime() + 1.0
    ent.LODNextSeekerCharge = 0
    Seeker.TestEntities[#Seeker.TestEntities + 1] = ent
    Seeker.Stats.testSpawns = (Seeker.Stats.testSpawns or 0) + 1

    local line = string.format("seeker=#%d lane=%s->%s windup=%.2fs chargeSpeed=%d damage=2d6+4",
        ent:EntIndex(), keyOf(spawnCell), keyOf(playerCell), WINDUP_SECONDS, CHARGE_SPEED)
    print("[LOD:SEEKER-TEST] " .. line)
    ply:ChatPrint(line)
end)

concommand.Add("lod_seeker_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local live, windup, charging = 0, 0, 0
    for _, hostile in ipairs(LOD.HostileRegistry and LOD.HostileRegistry:List() or {}) do
        if IsValid(hostile) and not hostile.LODDead and hostile.LODArchetypeId == "seeker" then
            live = live + 1
            local phase = hostile.LODSeekerState and hostile.LODSeekerState.phase
            if phase == "windup" then windup = windup + 1 end
            if phase == "charge" then charging = charging + 1 end
        end
    end

    local resolved = (Seeker.Stats.playerHits or 0) + (Seeker.Stats.wallImpacts or 0)
    local pass = (Seeker.Stats.windups or 0) > 0 and (Seeker.Stats.charges or 0) > 0 and resolved > 0
    local line = string.format(
        "live=%d windup=%d charging=%d windups=%d charges=%d playerHits=%d wallImpacts=%d impactStuns=%d tests=%d result=%s",
        live, windup, charging,
        Seeker.Stats.windups or 0,
        Seeker.Stats.charges or 0,
        Seeker.Stats.playerHits or 0,
        Seeker.Stats.wallImpacts or 0,
        Seeker.Stats.impactStuns or 0,
        Seeker.Stats.testSpawns or 0,
        pass and "PASS" or "WAITING")
    print("[LOD:SEEKER] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
