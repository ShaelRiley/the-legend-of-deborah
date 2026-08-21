LOD = LOD or {}
LOD.Sky = LOD.Sky or {}

local Sky = LOD.Sky

-- gm_flatgrass already supports Garry's Mod's paintable sky, but explicitly
-- reassert the special "painted" skybox name so the production gamemode never
-- falls back to the map's familiar daytime presentation after cleanup/addon
-- interaction. env_skypaint then owns the actual visible sky for every client.
local SKY_NAME = "painted"
local SKY_WATCH_TIMER = "LOD.ProceduralMidnightSky.Watch"
local SKY_INIT_HOOK = "LOD.ProceduralMidnightSky.Init"
local SKY_CLEANUP_HOOK = "LOD.ProceduralMidnightSky.Cleanup"

local currentSky = nil
local appliedSeed = nil

local function normalizeSeed(seed)
    if LOD.Seeds and LOD.Seeds.Normalize then
        return LOD.Seeds.Normalize(seed or 1)
    end
    return math.max(1, math.floor(math.abs(tonumber(seed) or 1)))
end

local function currentLevelSeed()
    local manager = LOD.RunManager
    local state = manager and manager.State
    if state and state.LevelSeed then return normalizeSeed(state.LevelSeed) end
    if state and state.CampaignSeed then return normalizeSeed(state.CampaignSeed) end
    return 1
end

local function makeParams(seed)
    seed = normalizeSeed(seed)
    local rng = LOD.RNG.New(LOD.Seeds.Derive(seed, "procedural-midnight-sky"))

    -- Stay inside a deliberately narrow midnight palette so every level belongs
    -- to the same world while still receiving a reproducible, seed-specific sky.
    local blueLift = rng:Float(0.000, 0.012)
    local violetLift = rng:Float(0.000, 0.009)

    local topColor = Vector(
        rng:Float(0.004, 0.012) + violetLift,
        rng:Float(0.008, 0.018),
        rng:Float(0.030, 0.052) + blueLift
    )

    local bottomColor = Vector(
        rng:Float(0.001, 0.005),
        rng:Float(0.002, 0.008),
        rng:Float(0.010, 0.022) + blueLift * 0.45
    )

    -- A nearly imperceptible indigo horizon prevents the gradient from reading as
    -- a flat black void, while keeping the visible world unambiguously midnight.
    local duskColor = Vector(
        rng:Float(0.010, 0.025) + violetLift * 0.35,
        rng:Float(0.012, 0.030),
        rng:Float(0.035, 0.065) + blueLift * 0.50
    )

    return {
        Seed = seed,
        TopColor = topColor,
        BottomColor = bottomColor,
        FadeBias = rng:Float(0.16, 0.30),
        HDRScale = rng:Float(0.20, 0.32),
        DuskColor = duskColor,
        DuskScale = rng:Float(0.16, 0.30),
        DuskIntensity = rng:Float(0.035, 0.085),

        -- No solar disc: this is starlit midnight, not blue-hour dusk.
        SunColor = Vector(0, 0, 0),
        SunNormal = Vector(0, 0, -1),
        SunSize = 0,

        -- Garry's Mod's g_Sky shader supports layered stars. Use all three layers
        -- and deterministically vary scale/fade/drift per generated level.
        DrawStars = true,
        StarTexture = "skybox/starfield",
        StarLayers = 3,
        StarFade = rng:Float(0.86, 1.00),
        StarScale = rng:Float(0.72, 1.12),
        StarSpeed = rng:Float(0.0010, 0.0045)
    }
end

local function ensurePaintedSkyName()
    local cv = GetConVar("sv_skyname")
    if not cv or cv:GetString() ~= SKY_NAME then
        RunConsoleCommand("sv_skyname", SKY_NAME)
    end
end

local function findOrCreateSkyPaint()
    if IsValid(currentSky) then return currentSky end

    for _, ent in ipairs(ents.FindByClass("env_skypaint")) do
        if IsValid(ent) then
            currentSky = ent
            return currentSky
        end
    end

    local ent = ents.Create("env_skypaint")
    if not IsValid(ent) then return nil end
    ent:SetPos(vector_origin)
    ent:Spawn()
    ent:Activate()
    currentSky = ent
    return currentSky
end

local function setIfAvailable(ent, method, value)
    local fn = ent and ent[method]
    if isfunction(fn) then fn(ent, value) end
end

function Sky.Apply(seed, force)
    seed = normalizeSeed(seed or currentLevelSeed())
    ensurePaintedSkyName()

    local ent = findOrCreateSkyPaint()
    if not IsValid(ent) then
        ErrorNoHalt("[LOD] Procedural midnight sky: unable to create/find env_skypaint\n")
        return false
    end

    if not force and appliedSeed == seed then return true end

    local p = makeParams(seed)
    setIfAvailable(ent, "SetTopColor", p.TopColor)
    setIfAvailable(ent, "SetBottomColor", p.BottomColor)
    setIfAvailable(ent, "SetFadeBias", p.FadeBias)
    setIfAvailable(ent, "SetHDRScale", p.HDRScale)
    setIfAvailable(ent, "SetDuskColor", p.DuskColor)
    setIfAvailable(ent, "SetDuskScale", p.DuskScale)
    setIfAvailable(ent, "SetDuskIntensity", p.DuskIntensity)
    setIfAvailable(ent, "SetSunColor", p.SunColor)
    setIfAvailable(ent, "SetSunNormal", p.SunNormal)
    setIfAvailable(ent, "SetSunSize", p.SunSize)
    setIfAvailable(ent, "SetDrawStars", p.DrawStars)
    setIfAvailable(ent, "SetStarTexture", p.StarTexture)
    setIfAvailable(ent, "SetStarLayers", p.StarLayers)
    setIfAvailable(ent, "SetStarFade", p.StarFade)
    setIfAvailable(ent, "SetStarScale", p.StarScale)
    setIfAvailable(ent, "SetStarSpeed", p.StarSpeed)

    appliedSeed = seed
    Sky.Params = p

    print(string.format(
        "[LOD] Procedural midnight sky applied: seed=%d layers=%d starScale=%.3f starFade=%.3f starSpeed=%.4f",
        seed,
        p.StarLayers,
        p.StarScale,
        p.StarFade,
        p.StarSpeed
    ))
    return true
end

local function reapplySoon(force)
    timer.Simple(0, function()
        if not LOD or not LOD.Sky then return end
        LOD.Sky.Apply(currentLevelSeed(), force == true)
    end)
end

-- Initial map presentation.
hook.Add("InitPostEntity", SKY_INIT_HOOK, function()
    reapplySoon(true)
end)

-- Map cleanup can recreate/delete map-authored environment entities. Forget our
-- cached handle and rebuild/reconfigure against the current deterministic seed.
hook.Add("PostCleanupMap", SKY_CLEANUP_HOOK, function()
    currentSky = nil
    appliedSeed = nil
    reapplySoon(true)
end)

-- RunManager is loaded after this module. A cheap half-second watcher lets the
-- sky become level-seed-specific as soon as RunManager derives a new level seed,
-- without coupling the core generation pipeline to a presentation subsystem.
timer.Create(SKY_WATCH_TIMER, 0.5, 0, function()
    local seed = currentLevelSeed()
    if seed ~= appliedSeed or not IsValid(currentSky) then
        Sky.Apply(seed, true)
    end
end)

-- Cover late Lua initialization on listen servers.
reapplySoon(true)
