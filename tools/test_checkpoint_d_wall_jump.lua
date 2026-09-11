function IsValid(value) return type(value) == "table" and value.valid ~= false end
function CurTime() return 1 end
function Vector(x, y, z) return {x = x, y = y, z = z} end
vector_origin = Vector(0, 0, 0)
IN_JUMP = 2; MASK_PLAYERSOLID = 1; hook = {Add = function() end}; concommand = {Add = function() end}
function GetConVar() return nil end
LOD = {RPG = {IdentityCatalog = {OrdinaryFeats = {}}, FeatEffectSystem = {}, Schema = {DerivedStats = {}}}, RPGAbilityRules = {}}
function LOD.RPG.FeatEffectSystem:ApplyDerived() end
function LOD.RPGAbilityRules:Derived(actor) return actor and actor.derived or nil end
function LOD.RPGAbilityRules:SpringHeelImpulseMultiplier() return 1 end
dofile("./gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_checkpoint_d_movement_feats.lua")
local ok, errors = LOD.RPGAbilityRules:ValidateCheckpointDWallJump()
assert(ok, table.concat(errors or {}, "; "))
assert(LOD.RPG.IdentityCatalog.OrdinaryFeats.DEX_WALL_JUMP.effectParams.probeDistance == 24)
assert(LOD.RPG.IdentityCatalog.OrdinaryFeats.INT_CLOUD_STEP.effectParams.magicCost == 5)
assert(LOD.RPG.IdentityCatalog.OrdinaryFeats.INT_FLOAT_ON.effectParams.maximumSeconds == 3)
local floater = {derived = {floatOnEnabled = true, cloudStepEnabled = false}, resource = {magic = 20}, velocity = {z = 0}}
function floater:IsPlayer() return true end
function floater:Alive() return true end
function floater:OnGround() return false end
function floater:KeyDown() return true end
function floater:GetVelocity() return self.velocity end
function floater:SetVelocity() end
LOD.Magic = { _EnsureState = function(_, ply) return ply.resource end, _Sync = function() end }
assert(LOD.RPGAbilityRules:TryStartFloatOn(floater, 0), "Float On starts at apex")
assert(LOD.RPGAbilityRules:TickFloatOn(floater, 3), "Float On full duration tick")
assert(floater.resource.magic == 5, "Float On full 3 seconds costs exactly 15 Magic")
print("Checkpoint D Wall Jump headless PASS")
