-- Exercises the production acquisition/recompute path without a GMod server.
local function noop() end
LOD = {RPGAbilityRules = {HitStunMultiplier = function() return 1 end}, RPGValidation = {}}
util = {AddNetworkString = noop}
net = {Receive = noop}
concommand = {Add = noop}
hook = {Add = noop}
timer = {Simple = noop, Create = noop}
function IsValid() return false end
function GetConVar() return nil end
function ErrorNoHalt(message) error(message) end
function math.Clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end
function table.Copy(t)
    local copy = {}
    for k, v in pairs(t) do copy[k] = type(v) == 'table' and table.Copy(v) or v end
    return copy
end
local root = 'gamemodes/legend_of_deborah/gamemode/lod/'
for _, name in ipairs({'sh_rpg_schema', 'sv_rpg_gate_b_catalog',
    'sv_rpg_gate_c_catalog', 'sv_rpg_gate_e_feats', 'sv_character_progression',
    'sv_rpg_gate_e_charisma'}) do
    assert(loadfile(root .. name .. '.lua'))()
end
local cps = LOD.CharacterProgressionSystem
local effects = LOD.RPG.FeatEffectSystem
local state = cps:NewProgressionState('test', 'hero')
state.classId = 'fighter'
state.primaryAbility = 'str'
state.secondaryAbilities = {'con', 'wis'}
state.baseAbilities = {str = 10, dex = 10, con = 10, int = 11, wis = 10, cha = 17}
state.featAbilityDelta.cha = 2 -- pre-existing fallback gains must survive
state.pendingFeatSlots = {{earnedAtLevel = 1, offerFeatIds = {'CHA_WINNING_PERSONALITY'}, resolved = false}}
LOD.RunManager = {GetPlayerState = function() return {progressionState = state} end}
cps._ApplyPlayerMaxHP = noop
cps.SyncPlayer = noop
cps:_RecomputeProgressionState(state)
assert(state.effectiveAbilities.cha == 19)
assert(cps:CommitFeat({}, 'CHA_WINNING_PERSONALITY', 1))
assert(state.effectiveAbilities.cha == 20 and state.featQualificationAbilities.cha == 20)
assert(state.derivedStats.chaMod == 5)
assert(state.effectiveAbilities.int == 11 and state.derivedStats.intMod == 0)
assert(effects:WinningPersonalityQualificationScore(state) == 20)
assert(cps:PermanentFeatAbilityDelta(state, 'cha') == 3)
assert(state.featAbilityDelta.cha == 2)
assert(not cps:CommitFeat({}, 'CHA_WINNING_PERSONALITY', 1))
for _ = 1, 5 do cps:_RecomputeProgressionState(state) end
assert(state.effectiveAbilities.cha == 20)
state = table.Copy(state) -- campaign reconnect restoration
cps:_RecomputeProgressionState(state)
assert(state.effectiveAbilities.cha == 20)
state.equipmentAbilityDelta.cha = 7
state.temporaryAbilityDelta.cha = 7
cps:_RecomputeProgressionState(state)
assert(state.effectiveAbilities.cha == 30 and state.featQualificationAbilities.cha == 20)
assert(effects:WinningPersonalityQualificationScore(state) == 20)
state.baseAbilities.cha = 30
cps:_RecomputeProgressionState(state)
assert(state.featQualificationAbilities.cha == 30)
state.featIds = {} -- developer reset must not leave an accumulated bonus
assert(cps:PermanentFeatAbilityDelta(state, 'cha') == 2)
local ok, errors = effects:ValidateCharismaFamilies()
assert(ok, table.concat(errors or {}, '; '))
print('winning_personality PASS: acquisition, CHA consumers, INT isolation, fallback composition, repeat/reconnect safety, gear exclusion, cap, reset, family validator')
