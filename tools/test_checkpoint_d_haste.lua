local root = "."
local now = 10
function CurTime() return now end
function IsValid(value) return type(value) == "table" and value.valid ~= false end
function math.Clamp(value, low, high) return math.max(low, math.min(high, value)) end
hook, net, util, timer, concommand = {Add = function() end}, {Receive = function() end}, {AddNetworkString = function() end}, {Create = function() end}, {Add = function() end}
function GetConVar() return nil end

LOD = {RPG = {IdentityCatalog = {OrdinaryFeats = {}}, FeatEffectSystem = {}}, RPGAbilityRules = {}, Magic = {}}
function LOD.RPG.FeatEffectSystem:ApplyDerived() end
function LOD.RPGAbilityRules:Derived(actor) return actor.derived end
function LOD.RPGAbilityRules:MapDrainPerSecond(actor, base) return base * (actor.mapMultiplier or 1) end
function LOD.RPGAbilityRules:MovementMultiplier() return 1.5 end
function LOD.Magic:_EnsureState(actor) return actor.resource end
function LOD.Magic:_Sync() end

dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_checkpoint_d_haste.lua")
local Rules, Effects = LOD.RPGAbilityRules, LOD.RPG.FeatEffectSystem
local ok, errors = Rules:ValidateCheckpointDHaste()
assert(ok, table.concat(errors or {}, "; "))
local actor = {derived = {hasteRank = 3, hasteMovementMultiplier = 2, hasteDrainMultiplier = 1 / 3}, resource = {magic = 20}, mapMultiplier = .85}
function actor:IsPlayer() return true end
function actor:Alive() return true end
function actor:SetNW2Bool(_, value) self.hasteNetworked = value end
assert(Rules:SetHasteActive(actor, true), "positive Magic enables Haste")
assert(Rules:IsHasteActive(actor) and actor.hasteNetworked, "Haste state is server owned/networked")
assert(math.abs(Rules:HasteDrainPerSecond(actor) - (100 / 15) * .85 / 3) < .000001, "Haste uses current map-equivalent rate")
assert(Rules:MovementMultiplier(actor) == 3, "Haste doubles resolved ordinary movement")
actor.resource.magic = 0
assert(not Rules:SetHasteActive(actor, true), "zero Magic rejects Haste")
local rank, drain = Effects:HasteProfile({featIds = {"INT_HASTE_1", "INT_HASTE_2", "INT_HASTE_3"}})
assert(rank == 3 and drain == 1 / 3, "highest Haste rank replaces lower drain")
print("Checkpoint D Haste headless PASS")
