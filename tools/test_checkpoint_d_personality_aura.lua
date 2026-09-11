function IsValid(value) return type(value) == "table" and value.valid ~= false end
function GetConVar() return nil end
concommand = {Add = function() end}; hook = {Add = function() end}; player = {GetAll = function() return {} end}
LOD = {RPG = {IdentityCatalog = {OrdinaryFeats = {}}}, RPGAbilityRules = {}, RPGStatusElements = {}, HostileRegistry = {List = function() return {} end}}
dofile("./gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_checkpoint_d_aura_burst_feats.lua")
dofile("./gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_checkpoint_d_personality_aura_feats.lua")
local ok, errors = LOD.RPG:ValidateCheckpointDPersonalityAuraFeats()
assert(ok, table.concat(errors or {}, "; "))
assert(LOD.RPG:CheckpointDPersonalityAuraProfile({featIds = {"CHA_ABRASIVE_PERSONALITY_1", "CHA_NARCISSISM_2"}}) == 1)
print("Checkpoint D Personality Aura headless PASS")
