LOD = LOD or {}
LOD.EnemyVariance = LOD.EnemyVariance or {}

local EnemyVariance = LOD.EnemyVariance
local EC = LOD.Config.Encounter
local V = EC.InstanceVariance

local DAMAGE_FIELDS = {
    "meleeDamage", "burstDamage", "blastDamage", "explosionDamage"
}
local TIMER_FIELDS = {
    "meleeCooldown", "burstCooldown", "burstTelegraph", "burstShotInterval",
    "leapCooldown", "blastInterval", "blastTelegraph"
}
local RANGE_FIELDS = {
    "meleeRange", "fireRange", "preferredRange", "leapRange", "latchDistance", "explosionRadius"
}

-- Tiny per-movement-update pace variation prevents enemies with similar routes
-- from phase-locking into an unnaturally tight clump. The mean remains 1.0, so
-- archetype tuning does not drift; only the length of individual movement
-- updates varies by up to +/-2.5 percent.
local STRIDE_VARIANCE = 0.025

local function subFloat(seed, label, minimum, maximum)
    local subSeed = LOD.Seeds.Derive(seed, label)
    return LOD.RNG.New(subSeed):Float(minimum, maximum)
end

local function jitter(seed, label, amount)
    amount = amount or 0
    return subFloat(seed, label, 1 - amount, 1 + amount)
end

local function stableSpawnIdentity(hostile)
    if hostile.LODEncounterOrdinal then return "ordinal:" .. tostring(hostile.LODEncounterOrdinal) end

    -- Existing encounter spawners place each unit at a deterministic offset from
    -- its encounter cell. Use that position instead of EntIndex so activating
    -- encounters in a different order does not perturb the same-seed enemy roll.
    if hostile.LODEncounterId then
        local pos = hostile:GetPos()
        return string.format("pos:%d:%d:%d",
            math.floor(pos.x * 10 + 0.5),
            math.floor(pos.y * 10 + 0.5),
            math.floor(pos.z * 10 + 0.5))
    end

    -- Developer-only ad-hoc spawns are not part of ranked seed reproduction.
    return "debug:" .. tostring(hostile:EntIndex())
end

local function instanceSeed(hostile)
    if hostile.LODInstanceSeed then return hostile.LODInstanceSeed end

    local state = LOD.RunManager and LOD.RunManager.State
    local levelSeed = state and state.LevelSeed or 1
    local encounter = hostile.LODEncounterId or "debug"
    local identity = stableSpawnIdentity(hostile)
    local home = hostile.LODHomeCellKey or "none"
    local archetype = hostile.LODArchetypeId or "unknown"
    local label = string.format("enemy:%s:%s:%s:%s", tostring(encounter), identity, tostring(home), tostring(archetype))
    hostile.LODInstanceSeed = LOD.Seeds.Derive(levelSeed, label)
    return hostile.LODInstanceSeed
end

local function scaleCollision(hostile, size)
    if not hostile.GetCollisionBounds or not hostile.SetCollisionBounds then return end
    local mins, maxs = hostile:GetCollisionBounds()
    if not mins or not maxs then return end
    hostile:SetCollisionBounds(mins * size, maxs * size)
end

local function scaledValue(base, sizeFactor, randomFactor)
    return base * sizeFactor * randomFactor
end

function EnemyVariance:Apply(hostile)
    if not V or not IsValid(hostile) or not hostile.LODHostile or not hostile.LODConfig then return end
    if hostile.LODVarianceApplied then return end
    hostile.LODVarianceApplied = true

    local seed = instanceSeed(hostile)
    local size = subFloat(seed, "size", V.SizeMin or 0.33, V.SizeMax or 1.33)
    local originalConfig = hostile.LODConfig
    local cfg = table.Copy(originalConfig)
    hostile.LODConfig = cfg

    local hpJitter = jitter(seed, "health", V.HealthJitter)
    local damageScale = size
    local hpScale = size * hpJitter
    local speedScale = math.pow(size, V.SpeedSizeExponent or -0.18)
    local timerScale = math.pow(size, V.TimerSizeExponent or 0.10)
    local rangeScale = math.pow(size, V.RangeSizeExponent or 0.55)

    -- Model and hull vary together so what the player sees remains congruent
    -- with what bullets/movement collide against.
    hostile:SetModelScale(size, 0)
    scaleCollision(hostile, size)

    -- Preserve campaign/party health scaling already applied by the base entity,
    -- then layer the deterministic individual scale on top.
    local currentMax = math.max(1, hostile:GetMaxHealth())
    local variedMax = math.max(1, math.floor(currentMax * hpScale + 0.5))
    hostile:SetMaxHealth(variedMax)
    hostile:SetHealth(variedMax)
    if cfg.baseHP then cfg.baseHP = scaledValue(cfg.baseHP, size, hpJitter) end

    if cfg.speed then
        cfg.speed = scaledValue(cfg.speed, speedScale, jitter(seed, "speed", V.SpeedJitter))
    end
    if cfg.leapSpeed then
        cfg.leapSpeed = scaledValue(cfg.leapSpeed, speedScale, jitter(seed, "leapSpeed", V.SpeedJitter))
    end

    for _, field in ipairs(DAMAGE_FIELDS) do
        if cfg[field] then
            cfg[field] = scaledValue(cfg[field], damageScale, jitter(seed, "damage:" .. field, V.DamageJitter))
        end
    end

    for _, field in ipairs(TIMER_FIELDS) do
        if cfg[field] then
            cfg[field] = math.max(0.03, scaledValue(cfg[field], timerScale, jitter(seed, "timer:" .. field, V.TimerJitter)))
        end
    end

    for _, field in ipairs(RANGE_FIELDS) do
        if cfg[field] then
            cfg[field] = math.max(1, scaledValue(cfg[field], rangeScale, jitter(seed, "range:" .. field, V.RangeJitter)))
        end
    end

    if cfg.projectileSpeed then
        cfg.projectileSpeed = math.max(120, cfg.projectileSpeed * jitter(seed, "projectileSpeed", V.ProjectileSpeedJitter))
    end

    -- The Deadcrab's 0.75-second latched fuse is a signature readability rule,
    -- not part of the cadence randomization. Likewise navigation step/jump
    -- allowances remain fixed so visual variety cannot break maze solvability.
    if hostile.loco and cfg.speed then
        hostile.loco:SetDesiredSpeed(cfg.speed)
        hostile.loco:SetAcceleration(math.max(500, cfg.speed * 5))
        hostile.loco:SetDeceleration(math.max(500, cfg.speed * 6))
    end

    -- This stream advances independently of every other enemy and of all other
    -- procedural systems. Same seed + same hostile identity therefore produces
    -- the same movement micro-variation sequence without uncontrolled math.random.
    hostile.LODStrideRNG = LOD.RNG.New(LOD.Seeds.Derive(seed, "micro-stride"))
    hostile.LODStrideFactor = 1.0

    hostile.LODVariance = {
        seed = seed,
        size = size,
        hpScale = hpScale,
        speedScale = cfg.speed and (cfg.speed / (originalConfig.speed or cfg.speed)) or 1
    }
    hostile:SetNW2Float("LOD_SizeScale", size)
    hostile:SetNW2Int("LOD_InstanceSeed", seed)
end

local function installHostilePatch()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class or class.LODEnemyVariancePatched then return false end
    class.LODEnemyVariancePatched = true

    local baseInitialize = class.Initialize
    function class:Initialize()
        baseInitialize(self)
        if not IsValid(self) or not self.LODConfig then return end
        EnemyVariance:Apply(self)
    end

    local baseBehaviourTick = class._BehaviourTick
    function class:_BehaviourTick()
        local cfg = self.LODConfig
        local rng = self.LODStrideRNG

        -- Temporarily perturb the desired movement speed for this one movement
        -- update. The underlying per-instance speed remains unchanged afterward.
        -- Because displacement per update is speed * frame time, this is the
        -- requested +/-2.5% variation in movement-step length.
        if cfg and cfg.speed and rng and not self.LODDead and self.LODActivated ~= false then
            local baseSpeed = cfg.speed
            local factor = rng:Float(1 - STRIDE_VARIANCE, 1 + STRIDE_VARIANCE)
            self.LODStrideFactor = factor
            cfg.speed = baseSpeed * factor
            local result = baseBehaviourTick(self)
            cfg.speed = baseSpeed
            return result
        end

        return baseBehaviourTick(self)
    end
    return true
end

installHostilePatch()
hook.Add("OnEntityCreated", "LOD_EnemyVarianceInstallBeforeSpawn", function(ent)
    if IsValid(ent) and ent:GetClass() == "lod_hostile" then installHostilePatch() end
end)

local function mainDamage(cfg)
    if not cfg then return 0 end
    if cfg.blastDamage then return cfg.blastDamage end
    if cfg.explosionDamage then return cfg.explosionDamage end
    if cfg.burstDamage then return cfg.burstDamage end
    return cfg.meleeDamage or 0
end

local function mainTimer(cfg)
    if not cfg then return 0 end
    if cfg.blastInterval then return cfg.blastInterval end
    if cfg.leapCooldown then return cfg.leapCooldown end
    if cfg.burstCooldown then return cfg.burstCooldown end
    return cfg.meleeCooldown or 0
end

concommand.Add("lod_m3_variance", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local found = 0
    for _, hostile in ipairs(ents.FindByClass("lod_hostile")) do
        if IsValid(hostile) and hostile.LODVariance then
            found = found + 1
            local cfg = hostile.LODConfig
            local text = string.format(
                "#%d %-10s size=%.3f hp=%d speed=%.1f stride=%.3f damage=%.1f timer=%.2f seed=%d",
                hostile:EntIndex(), tostring(hostile.LODArchetypeId), hostile.LODVariance.size,
                hostile:Health(), cfg.speed or 0, hostile.LODStrideFactor or 1,
                mainDamage(cfg), mainTimer(cfg), hostile.LODVariance.seed
            )
            print("[LOD:VARIANCE] " .. text)
            if IsValid(ply) then ply:ChatPrint(text) end
        end
    end
    if found == 0 then
        print("[LOD:VARIANCE] no active varied hostiles")
        if IsValid(ply) then ply:ChatPrint("no active varied hostiles") end
    end
end)
