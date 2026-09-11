LOD = LOD or {}; LOD.RPG = LOD.RPG or {}
local RPG = LOD.RPG
local Catalog = assert(RPG.IdentityCatalog, "Direct CHA damage feats require catalog")
local Feats = assert(Catalog.OrdinaryFeats or Catalog.LevelOneOrdinaryFeats, "Direct CHA damage feats require ordinary feats")
local Rules = assert(LOD.RPGAbilityRules, "Direct CHA damage feats require ability rules")
local Effects = assert(RPG.FeatEffectSystem, "Direct CHA damage feats require effect system")

local definitions = {
    {id = "CHA_SELF_ACTUALIZATION", name = "Self-Actualization", capability = "magic_form_owned", physical = false},
    {id = "CHA_AGGRESSIVE_PERSONALITY", name = "Aggressive Personality", capability = "attributable_damaging_attack", physical = true}
}
for _, item in ipairs(definitions) do
    assert(Feats[item.id] == nil, "duplicate canonical feat " .. item.id)
    Feats[item.id] = {featId = item.id, displayName = item.name, featFamilyId = item.id:lower(), rankIndex = 1,
        replacesLowerRank = false, repeatableFallback = false, governingAbilities = {"cha"}, abilityRequirements = {cha = 15},
        prerequisiteFeatIds = {}, requiredCapabilityTags = {item.capability}, incompatibleFeatIds = {},
        allowedActorTypes = {"hero", "human_soldier", "ai"}, requiredSubsystemTags = {"damage_contract"},
        synergyTags = {"charisma", "flat_damage", item.physical and "physical" or "magic"}, oneRank = true,
        effectHandlerId = item.physical and "aggressive_personality_damage" or "self_actualization_magic_damage",
        effectParams = {flatDamageAbility = "cha", cooldownDice = item.physical and {1, 3} or nil,
            description = item.physical
                and "While ready, the next eligible physical attack adds max(0, CHA_MOD) once per resolved target and begins a sealed non-exploding 1d3-second cooldown."
                or "Each eligible magical target damage event gains max(0, CHA_MOD) once after source-side multipliers."},
        directorBaseWeight = 1.0, eligibilityText = "CHA 15 / eligible " .. (item.physical and "physical attack" or "Magic Form"),
        actorText = "Heroes, human Soldiers, and AI with an eligible attack"}
end
Catalog.OrdinaryFeats = Feats

local function owns(state, id)
    for _, owned in ipairs(state and state.featIds or {}) do if owned == id then return true end end
    return false
end

local function ineligible(tags)
    return tags.statusDamage or tags.statusProcIneligible or tags.feedbackIneligible or tags.passiveDamage
        or tags.auraBurst or tags.personalityAura or tags.reactiveDamage
end

function RPG:CheckpointDDirectChaDamageEligibility(state, tags)
    tags = tags or {}
    if ineligible(tags) then return false, false end
    return owns(state, "CHA_SELF_ACTUALIZATION") and (tags.magic == true or tags.magical == true),
        owns(state, "CHA_AGGRESSIVE_PERSONALITY") and tags.physical == true
end

function RPG:CheckpointDAggressiveCooldownSeconds(actor)
    actor.LODCheckpointDAggressiveSerial = (actor.LODCheckpointDAggressiveSerial or 0) + 1
    local run = LOD.RunManager and LOD.RunManager.State
    local seed = LOD.Seeds.Derive((run and run.LevelSeed) or 1,
        string.format("aggressive-personality:%d:%d", actor.EntIndex and actor:EntIndex() or 0, actor.LODCheckpointDAggressiveSerial))
    return LOD.RNG.New(seed):Int(1, 3)
end

local function aggressiveReadyForContract(contract, actor, now)
    if contract.LODCheckpointDAggressiveActor == actor then return contract.LODCheckpointDAggressiveActive == true end
    if now < (tonumber(actor.LODCheckpointDAggressiveReadyAt) or 0) then return false end
    contract.LODCheckpointDAggressiveActor = actor
    contract.LODCheckpointDAggressiveActive = true
    actor.LODCheckpointDAggressiveReadyAt = now + RPG:CheckpointDAggressiveCooldownSeconds(actor)
    return true
end

Effects:RegisterChaModDamageSource("checkpoint_d_direct_cha_damage", function(state)
    return owns(state, "CHA_SELF_ACTUALIZATION") or owns(state, "CHA_AGGRESSIVE_PERSONALITY")
end)

if not Rules.LODCheckpointDDirectChaDamageWrapped then
    Rules.LODCheckpointDDirectChaDamageWrapped = true
    local baseResolveDamageContract = Rules.ResolveDamageContract
    function Rules:ResolveDamageContract(contract, attacker, target, tags)
        local result, reduced, resistance = baseResolveDamageContract(self, contract, attacker, target, tags)
        local total = math.max(0, tonumber(result) or 0)
        tags = tags or {}
        if total <= 0 or not IsValid(attacker) then return total, reduced, resistance end
        local state = self:ProgressionState(attacker)
        local selfActualization, aggressive = RPG:CheckpointDDirectChaDamageEligibility(state, tags)
        if aggressive then aggressive = aggressiveReadyForContract(contract or {}, attacker, CurTime()) end
        if not selfActualization and not aggressive then return total, reduced, resistance end
        local derived = self:Derived(attacker) or {}
        local chaBonus = math.max(0, math.floor(tonumber(derived.chaMod) or 0))
        if chaBonus <= 0 then return total, reduced, resistance end
        total = total + (selfActualization and chaBonus or 0) + (aggressive and chaBonus or 0)
        -- Glow Up keys off an actual authored CHA_MOD contribution. Even when
        -- both independent feats qualify, it adds CON_MOD only once per event.
        if owns(state, "CON_GLOW_UP") then
            total = total + math.max(0, math.floor(tonumber(derived.conMod) or 0))
        end
        return total, reduced, resistance
    end
end

function RPG:ValidateCheckpointDDirectChaDamageFeats()
    local errors = {}; local function expect(ok, message) if not ok then errors[#errors + 1] = message end end
    for _, item in ipairs(definitions) do
        local definition = Feats[item.id]
        expect(definition and definition.abilityRequirements.cha == 15, item.id .. " CHA requirement")
        expect(definition and definition.requiredCapabilityTags[1] == item.capability, item.id .. " capability")
    end
    local state = {featIds = {"CHA_SELF_ACTUALIZATION", "CHA_AGGRESSIVE_PERSONALITY"}}
    local magic, physical = self:CheckpointDDirectChaDamageEligibility(state, {magic = true, physical = true})
    expect(magic and physical, "mixed attack independently qualifies both feats")
    local blockedMagic, blockedPhysical = self:CheckpointDDirectChaDamageEligibility(state, {magic = true, statusDamage = true})
    expect(not blockedMagic and not blockedPhysical, "status damage is ineligible")
    return #errors == 0, errors
end

concommand.Add("lod_rpg_validate_direct_cha_damage", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end
    local ok, errors = RPG:ValidateCheckpointDDirectChaDamageFeats()
    print("[LOD:DIRECT-CHA-DAMAGE] " .. (ok and "PASS" or "FAIL") .. (#errors > 0 and (" " .. table.concat(errors, "; ")) or ""))
end)
