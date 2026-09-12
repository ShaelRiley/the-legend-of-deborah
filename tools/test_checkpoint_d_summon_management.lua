LOD = {RPG = {IdentityCatalog = {OrdinaryFeats = {}}}, MagicProgression = {}}
function IsValid(value) return type(value) == "table" and value.valid ~= false end
function GetConVar() return nil end
concommand = {Add = function() end}
function LOD.MagicProgression:MaxActiveSummons(state)
    local cap = 1
    for _, id in ipairs(state.featIds or {}) do
        if id == "INT_MIDDLE_MANAGER" then cap = 2 end
        if id == "INT_TASKMASTER" then cap = 3 end
        if id == "INT_OVERLORD" then cap = 4 end
    end
    return cap
end
dofile("./gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_checkpoint_d_summon_feats.lua")
local ok, errors = LOD.RPG:ValidateCheckpointDSummonManagement()
assert(ok, table.concat(errors or {}, "; "))
assert(LOD.RPG.IdentityCatalog.OrdinaryFeats.INT_OVERLORD.effectParams.maxActiveSummons == 4)
print("Checkpoint D summon management headless PASS")
