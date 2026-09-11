LOD = LOD or {}
LOD.RPG = LOD.RPG or {}

local RPG = LOD.RPG
local Catalog = assert(RPG.IdentityCatalog, "Haste requires feat catalog")
local Feats = assert(Catalog.OrdinaryFeats or Catalog.LevelOneOrdinaryFeats, "Haste requires ordinary feats")
local Effects = assert(RPG.FeatEffectSystem, "Haste requires feat effects")
local Rules = assert(LOD.RPGAbilityRules, "Haste requires AbilityRules")
local Magic = assert(LOD.Magic, "Haste requires Magic")
local BASE_MAP_DRAIN, TICK = 100 / 15, 0.10
local IDS = {"INT_HASTE_1", "INT_HASTE_2", "INT_HASTE_3"}
local NAMES = {"Haste", "Mana Rush", "Aether Drive"}
local DRAINS = {1, 2 / 3, 1 / 3}

for rank, id in ipairs(IDS) do
    assert(Feats[id] == nil, "duplicate canonical feat " .. id)
    Feats[id] = {
        featId = id, displayName = NAMES[rank], featFamilyId = "int_haste", rankIndex = rank,
        replacesLowerRank = rank > 1, repeatableFallback = false, governingAbilities = {"int"},
        abilityRequirements = {int = 11 + rank * 2}, prerequisiteFeatIds = rank > 1 and {IDS[rank - 1]} or {},
        requiredCapabilityTags = {"magic_pool"}, incompatibleFeatIds = {}, allowedActorTypes = {"hero", "human_soldier"},
        requiredSubsystemTags = {"movement", "magic"}, synergyTags = {"movement", "magic", "sustained"}, oneRank = true,
        effectHandlerId = "haste_sustained_movement", effectParams = {movementMultiplier = 2.0, drainMultiplier = DRAINS[rank],
            description = "A rebindable Haste toggle doubles ordinary voluntary walking and sprinting while draining the current WIS-scaled map-equivalent Magic rate. Highest rank replaces the drain multiplier."},
        directorBaseWeight = 1.0, eligibilityText = "INT " .. tostring(11 + rank * 2) .. (rank > 1 and " / requires " .. IDS[rank - 1] or " / Magic pool"),
        actorText = "Player-controlled Heroes and human Soldiers only"
    }
end
Catalog.OrdinaryFeats = Feats

function Effects:HasteProfile(state)
    local rank = 0
    for _, id in ipairs(state and state.featIds or {}) do
        for index, candidate in ipairs(IDS) do if id == candidate then rank = math.max(rank, index) end end
    end
    return rank, rank > 0 and DRAINS[rank] or 1
end
if not Effects.LODCheckpointDHasteDerivedWrapped then
    Effects.LODCheckpointDHasteDerivedWrapped = true
    local base = Effects.ApplyDerived
    function Effects:ApplyDerived(state, derived)
        base(self, state, derived)
        local rank, drain = self:HasteProfile(state)
        derived.hasteRank, derived.hasteMovementMultiplier, derived.hasteDrainMultiplier = rank, rank > 0 and 2 or 1, drain
    end
end

Effects.HasteState = Effects.HasteState or setmetatable({}, {__mode = "k"})
local function usable(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return false end
    local derived = Rules:Derived(ply) or {}
    return (tonumber(derived.hasteRank) or 0) > 0
end
function Rules:IsHasteActive(ply)
    local state = Effects.HasteState[ply]
    return state and state.active == true and usable(ply) or false
end
function Rules:SetHasteActive(ply, active)
    local state = Effects.HasteState[ply] or {}; Effects.HasteState[ply] = state
    if active then
        local ps = Magic:_EnsureState(ply)
        active = usable(ply) and ps and (tonumber(ps.magic) or 0) > 0
    end
    state.active, state.lastAt = active == true, CurTime()
    if IsValid(ply) then ply:SetNW2Bool("LOD_HasteActive", state.active) end
    return state.active
end
function Rules:HasteDrainPerSecond(ply)
    local derived = self:Derived(ply) or {}
    local mapRate = self:MapDrainPerSecond(ply, BASE_MAP_DRAIN)
    return mapRate * math.max(0, tonumber(derived.hasteDrainMultiplier) or 1)
end

if not Rules.LODCheckpointDHasteMovementWrapped then
    Rules.LODCheckpointDHasteMovementWrapped = true
    local base = Rules.MovementMultiplier
    function Rules:MovementMultiplier(actor)
        local ordinary = base(self, actor)
        local derived = self:Derived(actor) or {}
        return ordinary * (self:IsHasteActive(actor) and (tonumber(derived.hasteMovementMultiplier) or 1) or 1)
    end
end
hook.Add("LODMagicRegenerationSuppressed", "LOD_RPG_CheckpointDHaste", function(ply)
    return Rules:IsHasteActive(ply) or nil
end)

util.AddNetworkString("LOD_HasteToggle")
net.Receive("LOD_HasteToggle", function(_, ply)
    Rules:SetHasteActive(ply, not Rules:IsHasteActive(ply))
end)
timer.Create("LOD_RPG_CheckpointDHasteDrain", TICK, 0, function()
    for ply, state in pairs(Effects.HasteState) do
        if not Rules:IsHasteActive(ply) then
            if IsValid(ply) then Rules:SetHasteActive(ply, false) end
        else
            local now, dt = CurTime(), math.Clamp(CurTime() - (state.lastAt or CurTime()), 0, .35)
            state.lastAt = now
            local ps = Magic:_EnsureState(ply)
            ps.magic = math.max(0, (tonumber(ps.magic) or 0) - Rules:HasteDrainPerSecond(ply) * dt)
            Magic:_Sync(ply, ps)
            if ps.magic <= 0 then Rules:SetHasteActive(ply, false) end
        end
    end
end)
hook.Add("PlayerDeath", "LOD_RPG_CheckpointDHasteDeath", function(ply) Rules:SetHasteActive(ply, false) end)
hook.Add("PlayerDisconnected", "LOD_RPG_CheckpointDHasteDisconnect", function(ply) Effects.HasteState[ply] = nil end)

function Rules:ValidateCheckpointDHaste()
    local errors = {}; local function expect(ok, message) if not ok then errors[#errors + 1] = message end end
    for rank, id in ipairs(IDS) do
        local def, actual, drain = Feats[id], Effects:HasteProfile({featIds = {id}})
        expect(def and def.abilityRequirements.int == 11 + rank * 2 and def.effectParams.movementMultiplier == 2,
            id .. " definition")
        expect(actual == rank and math.abs(drain - DRAINS[rank]) < .000001, id .. " rank/drain")
        if rank > 1 then expect(def.prerequisiteFeatIds[1] == IDS[rank - 1], id .. " prerequisite") end
    end
    return #errors == 0, errors
end
concommand.Add("lod_rpg_validate_haste", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end
    local ok, errors = Rules:ValidateCheckpointDHaste()
    print("[LOD:HASTE] " .. (ok and "PASS" or "FAIL") .. (#errors > 0 and (" " .. table.concat(errors, "; ")) or ""))
end)
