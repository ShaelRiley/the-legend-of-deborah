LOD = LOD or {}; LOD.RPG = LOD.RPG or {}
local RPG = LOD.RPG
local Catalog = assert(RPG.IdentityCatalog, "WIS defense feats require catalog")
local Feats = assert(Catalog.OrdinaryFeats or Catalog.LevelOneOrdinaryFeats, "WIS defense feats require ordinary feats")
local Rules = assert(LOD.RPGAbilityRules, "WIS defense feats require ability rules")
local Status = assert(LOD.RPGStatusElements, "WIS defense feats require status authority")

local definitions = {
    {id = "WIS_TRUE_FAITH", name = "True Faith", wis = 15, prerequisite = nil},
    {id = "WIS_MIND_OVER_MATTER", name = "Mind Over Matter", wis = 17, prerequisite = "WIS_TRUE_FAITH"}
}
for _, item in ipairs(definitions) do
    assert(Feats[item.id] == nil, "duplicate canonical feat " .. item.id)
    Feats[item.id] = {featId = item.id, displayName = item.name, featFamilyId = item.id:lower(), rankIndex = 1,
        replacesLowerRank = false, repeatableFallback = false, governingAbilities = {"wis"}, abilityRequirements = {wis = item.wis},
        prerequisiteFeatIds = item.prerequisite and {item.prerequisite} or {}, requiredCapabilityTags = {}, incompatibleFeatIds = {},
        allowedActorTypes = {"hero", "human_soldier", "ai"}, requiredSubsystemTags = {"damage_defense"},
        synergyTags = {"wisdom", "defense", item.id == "WIS_TRUE_FAITH" and "magic" or "physical"}, oneRank = true,
        effectHandlerId = item.id == "WIS_TRUE_FAITH" and "incoming_magical_damage_reduction" or "incoming_physical_damage_reduction_cooldown",
        effectParams = item.id == "WIS_TRUE_FAITH" and {description = "Grants MagicalDamageReduction = max(0, WIS_MOD). Whenever this actor receives an incoming damage event tagged magical=true from any source, reduce that event's aggregated magical damage by MagicalDamageReduction after ordinary damage dice/Boom resolution, CON DamageResistancePerDie, source-side scaling, and elemental/identity modifiers, but before Arcane Shield HP-to-Magic diversion, lethal intercepts, and final HP loss. Apply True Faith exactly once per resolved damage event, never once per die, pellet, Boom continuation, or internal sub-hit, and never reduce damage below 0. Physical-only events with magical=false receive no reduction. If an unusual event is tagged both physical=true and magical=true, it qualifies because it is still an explicitly magical damage source. True Faith does not alter MagicSave, Arcane Integrity, elemental resistance/weakness, status saves, Magic cost, or any non-damage effect.", reductionAbility = "wis"}
            or {description = "While this feat is ready, the first incoming damage event tagged physical=true automatically receives PhysicalDamageReduction = max(0, WIS_MOD), applied once to the event's aggregated physical damage after ordinary damage dice/Boom resolution, CON DamageResistancePerDie, source-side scaling, and elemental/identity modifiers, but before Arcane Shield HP-to-Magic diversion, lethal intercepts, and final HP loss. Never reduce damage below 0. After an eligible physical event consumes the ready state, roll MindOverMatterCooldownSeconds = 3d4 seconds and do not apply Mind Over Matter again until that cooldown expires. These three d4 timing dice are sealed, non-damage utility dice and never explode or inherit Rogue damage-die mastery, DEX BoomShift, Wizard magical Boom rules, weapon-specific explosion rules, or other attack-die modifiers. When the cooldown expires, Mind Over Matter becomes ready again. Magical-only events with physical=false do not consume the ready state. A mixed physical=true/magical=true event may receive True Faith's magical reduction and, when Mind Over Matter is ready, Mind Over Matter's physical reduction on the same resolved event; each applies once and final damage is clamped at 0. Mind Over Matter does not alter Push, wall-slam damage, hit-stun, status saves, MagicSave, or any non-damage physical effect.", reductionAbility = "wis", cooldownDice = {3, 4}},
        directorBaseWeight = 1.0, eligibilityText = "WIS " .. item.wis .. (item.prerequisite and " / requires True Faith" or ""),
        actorText = "Heroes, human Soldiers, and AI"}
end
Catalog.OrdinaryFeats = Feats

local function owns(state, id)
    for _, owned in ipairs(state and state.featIds or {}) do if owned == id then return true end end
    return false
end

function RPG:CheckpointDWisDefenseResult(damage, wisMod, hasTrueFaith, hasMindOverMatter, magical, physical, mindReady)
    local total = math.max(0, tonumber(damage) or 0)
    local reduction = math.max(0, math.floor(tonumber(wisMod) or 0))
    local trueFaith = hasTrueFaith and magical == true and reduction or 0
    total = math.max(0, total - trueFaith)
    local consumeMind = hasMindOverMatter and physical == true and mindReady == true
    local mind = consumeMind and reduction or 0
    total = math.max(0, total - mind)
    return total, trueFaith, mind, consumeMind
end

function RPG:CheckpointDMindOverMatterCooldownSeconds(target)
    target.LODMindOverMatterRollSerial = (target.LODMindOverMatterRollSerial or 0) + 1
    local run = LOD.RunManager and LOD.RunManager.State
    local seed = LOD.Seeds.Derive((run and run.LevelSeed) or 1,
        string.format("mind-over-matter:%d:%d", target.EntIndex and target:EntIndex() or 0, target.LODMindOverMatterRollSerial))
    local rng = LOD.RNG.New(seed)
    return rng:Int(1, 4) + rng:Int(1, 4) + rng:Int(1, 4)
end

RPG.CheckpointDWisDefenseStats = RPG.CheckpointDWisDefenseStats or {trueFaithEvents = 0, mindEvents = 0}
function Rules:ApplyWisDefense(target, dmginfo)
    if not IsValid(target) or not dmginfo or dmginfo:GetDamage() <= 0 then return end
        local state = Rules:ProgressionState(target)
        local hasTrueFaith = owns(state, "WIS_TRUE_FAITH")
        local hasMind = owns(state, "WIS_MIND_OVER_MATTER")
        if not hasTrueFaith and not hasMind then return end
        local context = Status:DamageContext(dmginfo, target) or {}
        local magical = context.magic == true or context.magical == true
        local physical = context.physical == true
        local now = CurTime()
        local mindReady = now >= (tonumber(target.LODMindOverMatterReadyAt) or 0)
        local derived = Rules:Derived(target) or {}
        local final, trueFaith, mind, consumeMind = RPG:CheckpointDWisDefenseResult(dmginfo:GetDamage(), derived.wisMod,
            hasTrueFaith, hasMind, magical, physical, mindReady)
        if trueFaith > 0 or mind > 0 then
            dmginfo:SetDamage(final)
            context.trueFaithReduction = trueFaith
            context.mindOverMatterReduction = mind
            Status:AttachDamageContext(dmginfo, context)
            if trueFaith > 0 then RPG.CheckpointDWisDefenseStats.trueFaithEvents = RPG.CheckpointDWisDefenseStats.trueFaithEvents + 1 end
            if mind > 0 then RPG.CheckpointDWisDefenseStats.mindEvents = RPG.CheckpointDWisDefenseStats.mindEvents + 1 end
        end
        if consumeMind then target.LODMindOverMatterReadyAt = now + RPG:CheckpointDMindOverMatterCooldownSeconds(target) end
end

-- Gate D calls ApplyWisDefense after upstream cancellation and before diversion.
-- Register an authority method instead of wrapping the gamemode damage method.

function RPG:ValidateCheckpointDWisDefenseFeats()
    local errors = {}; local function expect(ok, message) if not ok then errors[#errors + 1] = message end end
    local trueFaith, mind = Feats.WIS_TRUE_FAITH, Feats.WIS_MIND_OVER_MATTER
    expect(trueFaith and trueFaith.abilityRequirements.wis == 15, "True Faith definition")
    expect(mind and mind.abilityRequirements.wis == 17 and mind.prerequisiteFeatIds[1] == "WIS_TRUE_FAITH", "Mind Over Matter definition")
    local final, magicalReduction, physicalReduction, consumed = self:CheckpointDWisDefenseResult(12, 3, true, true, true, true, true)
    expect(final == 6 and magicalReduction == 3 and physicalReduction == 3 and consumed, "mixed event receives both reductions")
    final, magicalReduction, physicalReduction, consumed = self:CheckpointDWisDefenseResult(12, 3, true, true, false, true, false)
    expect(final == 12 and magicalReduction == 0 and physicalReduction == 0 and not consumed, "Mind cooldown blocks physical repeat")
    return #errors == 0, errors
end

concommand.Add("lod_rpg_validate_wis_defense", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end
    local ok, errors = RPG:ValidateCheckpointDWisDefenseFeats()
    print("[LOD:WIS-DEFENSE] " .. (ok and "PASS" or "FAIL") .. (#errors > 0 and (" " .. table.concat(errors, "; ")) or ""))
end)
