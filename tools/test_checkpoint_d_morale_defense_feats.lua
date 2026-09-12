function IsValid(value) return type(value) == "table" and value.valid ~= false end
function GetConVar() return nil end
concommand = {Add = function() end}
LOD = {RPG = {IdentityCatalog = {OrdinaryFeats = {}}, FeatEffectSystem = {}}}
function LOD.RPG.FeatEffectSystem:ApplyDerived() end
dofile("./gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_checkpoint_d_morale_defense_feats.lua")
local ok, errors = LOD.RPG:ValidateCheckpointDMoraleDefenseFeats()
assert(ok, table.concat(errors or {}, "; "))
local derived = {}; LOD.RPG.FeatEffectSystem:ApplyDerived({featIds = {"CHA_NERVE_1", "CHA_NERVE_2"}}, derived)
assert(derived.moraleSaveBonus == 4, "highest Nerve rank replaces lower bonus")
print("Checkpoint D morale defense feats headless PASS")
