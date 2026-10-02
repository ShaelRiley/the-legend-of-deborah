local root = "."
local now = 10

function math.Clamp(value, low, high) return math.max(low, math.min(high, value)) end
function CurTime() return now end
function IsValid(value) return type(value) == "table" and value.valid ~= false end
function table.Copy(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for key, item in pairs(value) do out[key] = table.Copy(item) end
    return out
end

LOD = {
    RPG = {IdentityCatalog = {OrdinaryFeats = {}}, FeatEffectSystem = {}},
    RPGAbilityRules = {},
    CharacterProgressionSystem = {},
    RunManager = {State = {Level = 3}}
}

function LOD.RPG.FeatEffectSystem:ApplyDerived(_, derived) derived.meleeReachMultiplier = 1 end
function LOD.RPGAbilityRules:ProgressionState(actor) return actor.LODProgressionState end
function LOD.RPGAbilityRules:Derived(actor)
    local state = self:ProgressionState(actor)
    return state and state.derivedStats or nil
end
function LOD.RPGAbilityRules:SyncPlayer() end
function LOD.CharacterProgressionSystem:_HasCapability(_, _, tag) return tag ~= "cha_mod_damage" end

dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_checkpoint_d_core_feats.lua")

local Rules = LOD.RPGAbilityRules
local ok, errors = Rules:ValidateCheckpointDCoreFeats()
assert(ok, table.concat(errors or {}, "; "))

local littleDerived = {}
LOD.RPG.FeatEffectSystem:ApplyDerived({featIds = {"DEX_SHRINK"}}, littleDerived)
assert(littleDerived.playerTargetScale == .70 and littleDerived.littleGuyEnabled,
    "Little Guy applies its presentation target scale")
assert(LOD.RPG.IdentityCatalog.OrdinaryFeats.DEX_SHRINK.incompatibleFeatIds[1] == "CON_BIG_GUY",
    "Little Guy cannot coexist with Big Guy")

local caps = {personalLifeCapBonus = 2}
LOD.RPG.FeatEffectSystem:ApplyDerived({featIds = {"CON_NOT_YET"}}, caps)
assert(caps.personalLifeCapBonus == 3 and Rules:ResolvePersonalLifeCap(4, caps) == 7,
    "Not Yet composes additively with hypothetical +2 cap source")
assert(Rules:ResolvePersonalLifeCap(4, {}) == 4, "ordinary cap remains four")
assert(Rules.ApplyNotYetDefense == nil and Rules.NotYetImmunityActive == nil,
    "Not Yet no longer intercepts damage or grants immunity")

local glowActor = {LODProgressionState = {featIds = {"CON_GLOW_UP"}, derivedStats = {
    chaMod = 3, conMod = 4
}}}
local contract = {bonus = 2}
local cha, con = Rules:AddChaModDerivedDamage(contract, glowActor, "test_cha_source")
assert(cha == 3 and con == 4 and contract.bonus == 9, "Glow Up joins CHA damage once")
Rules:AddChaModDerivedDamage(contract, glowActor, "second_cha_source")
assert(contract.bonus == 12 and contract.LODGlowUpApplied,
    "Glow Up does not duplicate within a resolved damage event")

LOD.RPG.FeatEffectSystem:RegisterChaModDamageSource("test_cha_source", function(state)
    for _, id in ipairs(state.featIds or {}) do if id == "CHA_DAMAGE" then return true end end
    return false
end)
assert(LOD.CharacterProgressionSystem:_HasCapability({}, {featIds = {"CHA_DAMAGE"}}, "cha_mod_damage"),
    "Glow Up draft gate observes usable CHA source")
assert(not LOD.CharacterProgressionSystem:_HasCapability({}, {featIds = {}}, "cha_mod_damage"),
    "Glow Up draft gate rejects absent CHA source")

print("Checkpoint D core feats headless PASS")
