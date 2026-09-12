function IsValid(value) return type(value) == "table" and value.valid ~= false end
function GetConVar() return nil end
concommand = {Add = function() end}
function unpack(values) return table.unpack(values) end
LOD = {RPG = {IdentityCatalog = {OrdinaryFeats = {}}}, CharacterProgressionSystem = {}, MagicProgression = {}, Seeds = {}}
function LOD.Seeds.Derive(seed, label) return tostring(seed) .. ":" .. label end
function LOD.MagicProgression:_GrantDistinct(state, kind, milestone)
    state.magicGrantMilestones = state.magicGrantMilestones or {}
    local key = kind .. ":" .. milestone
    if state.magicGrantMilestones[key] then return false, "already" end
    state.magicGrantMilestones[key] = true
    local owned = kind == "form" and state.magicFormIds or state.contentIds
    owned[#owned + 1] = kind .. "_grant"
    return true, owned[#owned]
end
function LOD.CharacterProgressionSystem:CommitFeat() return true end
function LOD.CharacterProgressionSystem:_CommitAutomaticFeat() end
dofile("./gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_checkpoint_d_magic_grant_feats.lua")
local ok, errors = LOD.RPG:ValidateCheckpointDMagicGrantFeats()
assert(ok, table.concat(errors or {}, "; "))
print("Checkpoint D Magic grant feats headless PASS")
