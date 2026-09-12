local root = "."

function math.Clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end
function istable(value) return type(value) == "table" end
function isstring(value) return type(value) == "string" end
function IsValid() return false end
function ErrorNoHalt(message) io.stderr:write(message) end
function string.Trim(value) return string.match(value, "^%s*(.-)%s*$") end
function table.Copy(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for key, item in pairs(value) do copy[key] = table.Copy(item) end
    return copy
end

util = {AddNetworkString = function() end, CRC = function(value) return tostring(value) end}
net = {Receive = function() end}
hook = {Add = function() end}
concommand = {Add = function() end}
timer = {Simple = function() end}
player = {GetAll = function() return {} end}

dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sh_rng.lua")
dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sh_rpg_schema.lua")
dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_gate_b_catalog.lua")
dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_gate_c_catalog.lua")

local RPG = LOD.RPG

LOD.CombatRolls = {}
function LOD.CombatRolls:RollProgressionHitDie(seed, sides)
    local value = LOD.RNG.New(seed):Int(1, sides)
    return {seed = seed, sides = sides, formula = "d" .. tostring(sides), values = {value}, total = value}
end

dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sv_character_progression.lua")

local ok, errors = LOD.CharacterProgressionSystem:ValidateActorProgressionCore()
if not ok then
    for _, message in ipairs(errors) do io.stderr:write(message .. "\n") end
    error("actor progression validation failed")
end

for archetypeId, template in pairs(RPG.ArchetypeProgressionTemplates) do
    local state, err = LOD.CharacterProgressionSystem:GenerateMonsterProgression(
        archetypeId, LOD.Seeds.Derive(424242, archetypeId), 25, 40, "ai")
    assert(state, err)
    assert(state.level >= 25 and state.level <= 28, archetypeId .. " assigned Level")
    assert(#state.pendingFeatSlots == #RPG.OrdinaryFeatLevels,
        archetypeId .. " ordinary slot count")
    assert(state.classCapstoneFeatId, archetypeId .. " Level-20 capstone")
    if template.usesMagic ~= true then
        for seed = 1, 50 do
            assert(LOD.CharacterProgressionSystem:_AssignAutomaticClass(template, seed) ~= "wizard",
                archetypeId .. " received unusable Wizard class")
        end
    end
end

local ceilingState = assert(LOD.CharacterProgressionSystem:GenerateMonsterProgression(
    "soldier", 999999, 1000, 40, "ai"))
assert(ceilingState.level == 999, "monster hard cap generation")
assert(#ceilingState.pendingFeatSlots == #RPG.OrdinaryFeatLevels,
    "Level-999 monster gained post-20 feat slots")

local hero = LOD.CharacterProgressionSystem:NewProgressionState("hero", "hero", "hero")
hero.classId = "wizard"
hero.primaryAbility = "int"
hero.secondaryAbilities = {"wis", "dex"}
hero.startingHP = 100
hero.progressionHitDieSides = RPG.Classes.wizard.heroProgressionHitDieSides
hero.level = 20
LOD.CharacterProgressionSystem:_RecomputeProgressionState(hero)
assert(hero.level == 20, "Hero hard cap regression")
assert(hero.progressionHitDieSides == 4, "Wizard progression die regression")

local banked = LOD.CharacterProgressionSystem:NewProgressionState("banked", "hero", "hero")
banked.classId = "wizard"
banked.primaryAbility = "int"
banked.secondaryAbilities = {"wis", "dex"}
banked.baseAbilities = RPG.NewAbilityBlock(10)
banked.startingHP = 100
banked.progressionHitDieSides = 4
LOD.CharacterProgressionSystem:_RecomputeProgressionState(banked)
LOD.RunManager = {
    State = {Level = 1, CampaignSeed = 777, PlayerState = {banked = {identity = "banked", progressionState = banked}}}
}
function LOD.RunManager:GetPlayerState(identity) return self.State.PlayerState[identity] end
assert(LOD.CharacterProgressionSystem:SetHeroXP("banked", 48000))
assert(banked.xp == 48000 and banked.level == 4, "Hero banked-XP ceiling transaction")
LOD.RunManager.State.Level = 17
assert(LOD.CharacterProgressionSystem:ProcessBankedHeroXP(LOD.RunManager) == 16)
assert(banked.level == 20 and banked.xp == 48000, "Hero banked-XP release transaction")

LOD.RPGAbilityRules = {}
function LOD.RPGAbilityRules:ProgressionState(actor)
    return actor and actor.LODProgressionState or nil
end
function LOD.RPGAbilityRules:Derived(actor)
    local state = self:ProgressionState(actor)
    return state and state.derivedStats or nil
end
dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sv_human_soldier_progression.lua")
local soldierOK, soldierErrors = LOD.SoldierProgression:Validate()
assert(soldierOK, "Soldier progression validation failed: "
    .. table.concat(soldierErrors or {}, "; "))

print("actor progression headless validation PASS")
