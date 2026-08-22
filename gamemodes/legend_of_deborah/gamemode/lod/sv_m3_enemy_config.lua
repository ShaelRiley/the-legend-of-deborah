LOD = LOD or {}

local EC = LOD.Config.Encounter

-- BLITZER ----------------------------------------------------------------
-- Soldier-derived close/mid-range suppression. Burst length and per-shot veer
-- are rolled later from stable instance + attack identity.
EC.Archetypes.blitzer = {
    class = "lod_hostile_blitzer",
    name = "Blitzer",
    model = "models/combine_soldier.mdl",
    baseHP = 35,
    speed = 145,
    burstDamage = 5,
    burstShotsMin = 1,
    burstShotsMax = 6,
    burstCooldown = 1.45,
    burstTelegraph = 0.85,
    burstShotInterval = 0.10,
    projectileSpeed = 950,
    projectileLifetime = 1.35,
    fireRange = 900,
    preferredRange = 520,
    veerChance = 0.50,
    veerDegrees = 2.4,
    threat = 2.7,
    activity = ACT_RUN
}

-- Universal per-instance enemy individuality. Values are deterministic from the
-- level seed + encounter identity, so the same seed still reproduces the same
-- enemies. Size is the dominant variation; small stat jitter prevents two
-- otherwise similar instances from being exact clones.
EC.InstanceVariance = {
    SizeMin = 0.33,
    SizeMax = 1.33,
    HealthJitter = 0.08,
    DamageJitter = 0.08,
    SpeedJitter = 0.07,
    TimerJitter = 0.06,
    RangeJitter = 0.05,
    ProjectileSpeedJitter = 0.05,
    -- Larger bodies are stronger but a little slower/heavier. Tiny enemies are
    -- more fragile and hit less hard, but gain a modest speed/cadence advantage.
    SpeedSizeExponent = -0.18,
    TimerSizeExponent = 0.10,
    RangeSizeExponent = 0.55
}

-- BIO BLASTER -------------------------------------------------------------
-- A ranged mutation of the Shambler silhouette. It never performs ordinary
-- melee; its danger comes from a slow, huge, high-damage mouth projectile with
-- a readable full-body opening/charge tell.
EC.Archetypes.bioblaster = {
    class = "lod_hostile_bioblaster",
    name = "Bio Blaster",
    model = "models/zombie/classic.mdl",
    baseHP = 30,
    speed = 105,
    meleeDamage = 0,
    meleeCooldown = 99,
    meleeRange = 0,
    blastDamage = 45,
    blastInterval = 3.0,
    blastTelegraph = 0.82,
    projectileSpeed = 620,
    projectileLifetime = 1.80,
    fireRange = 900,
    preferredRange = 560,
    attackSounds = {
        "npc/zombie_poison/pz_warn1.wav",
        "npc/zombie_poison/pz_throw2.wav"
    },
    threat = 2.4,
    activity = ACT_WALK
}

EC.Templates.bio_pressure = {
    name = "Bio Pressure",
    composition = {shambler = 2, bioblaster = 1}
}
