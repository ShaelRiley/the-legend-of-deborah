LOD = LOD or {}
LOD.RPG = LOD.RPG or {}

local RPG = LOD.RPG
local Catalog = assert(RPG.IdentityCatalog, "Wall Jump requires feat catalog")
local Feats = assert(Catalog.OrdinaryFeats or Catalog.LevelOneOrdinaryFeats, "Wall Jump requires ordinary feat registry")
local Effects = assert(RPG.FeatEffectSystem, "Wall Jump requires feat effects")
local Rules = assert(LOD.RPGAbilityRules, "Wall Jump requires AbilityRules")
local PROBE_DISTANCE, LATERAL_KICK, VERTICAL_NORMAL_LIMIT = 24, 160, 0.20
local DIRECTIONS = {
    {x = 1, y = 0}, {x = 0, y = 1}, {x = -1, y = 0}, {x = 0, y = -1},
    {x = .70710678, y = .70710678}, {x = -.70710678, y = .70710678},
    {x = -.70710678, y = -.70710678}, {x = .70710678, y = -.70710678}
}

assert(Feats.DEX_WALL_JUMP == nil, "duplicate canonical feat DEX_WALL_JUMP")
Feats.DEX_WALL_JUMP = {
    featId = "DEX_WALL_JUMP", displayName = "Wall Jump", featFamilyId = "dex_wall_jump", rankIndex = 1,
    replacesLowerRank = false, repeatableFallback = false, governingAbilities = {"dex"}, abilityRequirements = {dex = 15},
    prerequisiteFeatIds = {}, requiredCapabilityTags = {}, incompatibleFeatIds = {}, allowedActorTypes = {"hero", "human_soldier"},
    requiredSubsystemTags = {"movement"}, synergyTags = {"movement", "jump", "wall"}, oneRank = true,
    effectHandlerId = "wall_jump", effectParams = {probeDistance = PROBE_DISTANCE, lateralKick = LATERAL_KICK,
        verticalNormalLimit = VERTICAL_NORMAL_LIMIT, description = "Once per airborne cycle, a fresh Space press within 24 units of a valid static vertical wall applies the ordinary voluntary-jump vertical impulse and a bounded kick away from that wall. It resets only on legitimate ground contact."},
    directorBaseWeight = 1.0, eligibilityText = "DEX 15", actorText = "Player-controlled Heroes and human Soldiers only"
}
Catalog.OrdinaryFeats = Feats

assert(Feats.INT_CLOUD_STEP == nil, "duplicate canonical feat INT_CLOUD_STEP")
Feats.INT_CLOUD_STEP = {
    featId = "INT_CLOUD_STEP", displayName = "Cloud Step", featFamilyId = "int_cloud_step", rankIndex = 1,
    replacesLowerRank = false, repeatableFallback = false, governingAbilities = {"int"}, abilityRequirements = {int = 13},
    prerequisiteFeatIds = {}, requiredCapabilityTags = {"magic_pool"}, incompatibleFeatIds = {}, allowedActorTypes = {"hero", "human_soldier"},
    requiredSubsystemTags = {"movement", "magic"}, synergyTags = {"movement", "jump", "magic"}, oneRank = true,
    effectHandlerId = "cloud_step", effectParams = {magicCost = 5,
        description = "Once per airborne cycle, a fresh Space press may spend exactly 5 Magic for one additional voluntary jump. A valid unused Wall Jump has priority and leaves Cloud Step unused."},
    directorBaseWeight = 1.0, eligibilityText = "INT 13 / Magic pool", actorText = "Player-controlled Heroes and human Soldiers only"
}

local function owns(state, id)
    for _, value in ipairs(state and state.featIds or {}) do if value == id then return true end end
    return false
end
function Effects:WallJumpProfile(state)
    return {enabled = owns(state, "DEX_WALL_JUMP"), probeDistance = PROBE_DISTANCE, lateralKick = LATERAL_KICK,
        cloudStep = owns(state, "INT_CLOUD_STEP")}
end
if not Effects.LODCheckpointDWallJumpDerivedWrapped then
    Effects.LODCheckpointDWallJumpDerivedWrapped = true
    local base = Effects.ApplyDerived
    function Effects:ApplyDerived(state, derived)
        base(self, state, derived)
        local profile = self:WallJumpProfile(state)
        derived.wallJumpEnabled, derived.wallJumpProbeDistance, derived.wallJumpLateralKick = profile.enabled, profile.probeDistance, profile.lateralKick
        derived.cloudStepEnabled, derived.cloudStepMagicCost = profile.cloudStep, 5
    end
end

local function addSchemaField(name)
    local fields = RPG.Schema and RPG.Schema.DerivedStats
    if not fields then return end
    for _, existing in ipairs(fields) do if existing == name then return end end
    fields[#fields + 1] = name
end
addSchemaField("wallJumpEnabled")
addSchemaField("wallJumpProbeDistance")
addSchemaField("wallJumpLateralKick")
addSchemaField("cloudStepEnabled")
addSchemaField("cloudStepMagicCost")

function Rules:WallJumpVerticalImpulse(actor)
    if not IsValid(actor) then return 0 end
    local base = math.max(0, tonumber(actor.GetJumpPower and actor:GetJumpPower() or 0) or 0)
    return base * math.max(0, tonumber(self:SpringHeelImpulseMultiplier(actor)) or 1)
end
function Effects:ValidWallJumpTrace(trace)
    if type(trace) ~= "table" or trace.Hit ~= true or trace.HitWorld ~= true then return false end
    return math.abs(tonumber((trace.HitNormal or {}).z) or 1) <= VERTICAL_NORMAL_LIMIT
end
function Effects:SelectWallJumpTrace(traces)
    local selected
    for index, trace in ipairs(traces or {}) do
        if self:ValidWallJumpTrace(trace) then
            local fraction = math.max(0, tonumber(trace.Fraction) or 1)
            if not selected or fraction < selected.fraction or (fraction == selected.fraction and index < selected.index) then
                selected = {trace = trace, fraction = fraction, index = index}
            end
        end
    end
    return selected and selected.trace or nil
end
function Rules:FindWallJumpSurface(ply)
    if not util or not util.TraceHull or not IsValid(ply) then return nil end
    local start, mins, maxs = ply:GetPos(), ply:GetHull()
    local derived = self:Derived(ply) or {}
    local probe = math.max(1, tonumber(derived.wallJumpProbeDistance) or PROBE_DISTANCE)
    local traces = {}
    for _, direction in ipairs(DIRECTIONS) do
        traces[#traces + 1] = util.TraceHull({start = start, endpos = start + Vector(direction.x * probe, direction.y * probe, 0),
            mins = mins, maxs = maxs, filter = ply, mask = MASK_PLAYERSOLID_BRUSHONLY or MASK_SOLID_BRUSHONLY or MASK_PLAYERSOLID})
    end
    return Effects:SelectWallJumpTrace(traces)
end
Effects.WallJumpState = Effects.WallJumpState or setmetatable({}, {__mode = "k"})
Effects.CloudStepState = Effects.CloudStepState or setmetatable({}, {__mode = "k"})
function Rules:TryWallJump(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() or ply:OnGround() then return false end
    local derived = self:Derived(ply)
    if not derived or derived.wallJumpEnabled ~= true then return false end
    local state = Effects.WallJumpState[ply] or {}; Effects.WallJumpState[ply] = state
    if state.used then return false end
    local trace = self:FindWallJumpSurface(ply)
    if not trace then return false end
    local vertical = self:WallJumpVerticalImpulse(ply)
    if vertical <= 0 then return false end
    local normal, kick = trace.HitNormal or vector_origin, math.max(0, tonumber(derived.wallJumpLateralKick) or LATERAL_KICK)
    state.used, state.lastSurfaceFraction, state.lastAt = true, tonumber(trace.Fraction) or 1, CurTime()
    ply:SetVelocity(Vector((tonumber(normal.x) or 0) * kick, (tonumber(normal.y) or 0) * kick, vertical))
    return true
end
function Rules:TryCloudStep(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() or ply:OnGround() then return false end
    local derived = self:Derived(ply)
    if not derived or derived.cloudStepEnabled ~= true then return false end
    local state = Effects.CloudStepState[ply] or {}; Effects.CloudStepState[ply] = state
    if state.used then return false end
    local magic = LOD.Magic
    local resource = magic and magic._EnsureState and magic:_EnsureState(ply)
    local cost = math.max(0, tonumber(derived.cloudStepMagicCost) or 5)
    if not resource or (tonumber(resource.magic) or 0) < cost then return false end
    local vertical = self:WallJumpVerticalImpulse(ply)
    if vertical <= 0 then return false end
    resource.magic = math.max(0, (tonumber(resource.magic) or 0) - cost)
    if magic._Sync then magic:_Sync(ply, resource) end
    state.used, state.lastAt = true, CurTime()
    ply:SetVelocity(Vector(0, 0, vertical))
    return true
end
function Rules:HandleAirborneJump(ply)
    if self:TryWallJump(ply) then return true end
    return self:TryCloudStep(ply)
end
hook.Add("KeyPress", "LOD_RPG_CheckpointDMovementJump", function(ply, key) if key == IN_JUMP then Rules:HandleAirborneJump(ply) end end)
hook.Add("Think", "LOD_RPG_CheckpointDWallJumpGroundReset", function()
    for ply, state in pairs(Effects.WallJumpState) do
        if not IsValid(ply) then Effects.WallJumpState[ply] = nil elseif ply:OnGround() then state.used = false end
    end
    for ply, state in pairs(Effects.CloudStepState) do
        if not IsValid(ply) then Effects.CloudStepState[ply] = nil elseif ply:OnGround() then state.used = false end
    end
end)
hook.Add("PlayerDeath", "LOD_RPG_CheckpointDWallJumpDeath", function(ply) Effects.WallJumpState[ply], Effects.CloudStepState[ply] = nil, nil end)
function Rules:ValidateCheckpointDWallJump()
    local errors = {}; local function expect(ok, text) if not ok then errors[#errors + 1] = text end end
    local def = Feats.DEX_WALL_JUMP
    expect(def and def.abilityRequirements.dex == 15, "Wall Jump definition/DEX requirement")
    expect(def and def.allowedActorTypes[1] == "hero" and def.allowedActorTypes[2] == "human_soldier", "Wall Jump actor restriction")
    expect(Effects:ValidWallJumpTrace({Hit = true, HitWorld = true, HitNormal = {z = 0}}), "vertical world wall accepted")
    expect(not Effects:ValidWallJumpTrace({Hit = true, HitWorld = false, HitNormal = {z = 0}}), "non-world wall rejected")
    expect(not Effects:ValidWallJumpTrace({Hit = true, HitWorld = true, HitNormal = {z = 1}}), "floor rejected")
    local chosen = Effects:SelectWallJumpTrace({{Hit = true, HitWorld = true, Fraction = .8, HitNormal = {z = 0}}, {Hit = true, HitWorld = true, Fraction = .2, HitNormal = {z = 0}}})
    expect(chosen and chosen.Fraction == .2, "nearest valid wall selected")
    local cloud = Feats.INT_CLOUD_STEP
    expect(cloud and cloud.abilityRequirements.int == 13 and cloud.effectParams.magicCost == 5,
        "Cloud Step definition/cost")
    return #errors == 0, errors
end
concommand.Add("lod_rpg_validate_wall_jump", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end
    local ok, errors = Rules:ValidateCheckpointDWallJump()
    print("[LOD:WALL-JUMP] " .. (ok and "PASS" or "FAIL") .. (#errors > 0 and (" " .. table.concat(errors, "; ")) or ""))
end)
