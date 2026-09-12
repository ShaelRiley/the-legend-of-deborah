function IsValid(value) return type(value) == "table" and value.valid ~= false end
function GetConVar() return nil end
concommand = {Add = function() end}
LOD = {RPG = {IdentityCatalog = {OrdinaryFeats = {CHA_MENACE_1 = {}}}, FeatEffectSystem = {}}}
function LOD.RPG.FeatEffectSystem:ApplyDerived() end
dofile("./gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_checkpoint_d_menace_feats.lua")
local ok, errors = LOD.RPG:ValidateCheckpointDMenaceFeats()
assert(ok, table.concat(errors or {}, "; "))
local derived = {}; LOD.RPG.FeatEffectSystem:ApplyDerived({featIds = {"CHA_MENACE_1", "CHA_MENACE_2", "CHA_MENACE_3"}}, derived)
assert(derived.moraleDCBonus == 4 and derived.humanMoraleTraumaFraction == .20 and derived.terrifyingFirstSaveDisadvantage)
print("Checkpoint D Menace feats headless PASS")
