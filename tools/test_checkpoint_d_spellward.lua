function IsValid(value) return type(value) == "table" and value.valid ~= false end
function GetConVar() return nil end
concommand = {Add = function() end}
LOD = {RPG = {IdentityCatalog = {OrdinaryFeats = {WIS_SPELLWARD = {}}}, FeatEffectSystem = {}}}
function LOD.RPG.FeatEffectSystem:ApplyDerived() end
dofile("./gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_checkpoint_d_spellward_feats.lua")
local ok, errors = LOD.RPG:ValidateCheckpointDSpellwardFeats()
assert(ok, table.concat(errors or {}, "; "))
print("Checkpoint D Spellward headless PASS")
