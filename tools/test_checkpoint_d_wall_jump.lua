function IsValid(value) return type(value) == "table" and value.valid ~= false end
function math.Clamp(value, low, high) return math.max(low, math.min(high, value)) end
function CurTime() return 1 end
local V={};V.__index=V
function Vector(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},V) end
V.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
function V:GetNormalized() local length=math.sqrt(self.x^2+self.y^2+self.z^2);return Vector(self.x/length,self.y/length,self.z/length) end
vector_origin = Vector(0, 0, 0)
IN_JUMP = 2; MASK_PLAYERSOLID = 1; hook = {handlers={},Add = function(event,id,fn) hook.handlers[id]=fn end}; concommand = {Add = function() end}
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
assert(LOD.RPG.IdentityCatalog.OrdinaryFeats.INT_SIZE_SHIFTER.effectParams.targetScale == .33)
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


local R,E=LOD.RPGAbilityRules,LOD.RPG.FeatEffectSystem
local p={derived={wallJumpEnabled=true,cloudStepEnabled=true},resource={magic=20},velocity=Vector(-250,70,-600)}
function p:IsPlayer() return true end
function p:Alive() return not self.dead end
function p:OnGround() return self.ground or false end
function p:Crouching() return self.duck or false end
function p:GetHull() return Vector(-16,-16,0),Vector(16,16,72) end
function p:GetHullDuck() return Vector(-16,-16,0),Vector(16,16,36) end
function p:GetPos() return Vector() end
function p:GetJumpPower() return 200 end
function p:GetVelocity() return self.velocity end
function p:SetVelocity(delta) self.velocity=self.velocity+delta end
local class='lod_static_box'
local wall={GetClass=function() return class end}
local blocked=false;local scans=0
util={TraceHull=function(args)
    scans=scans+1
    assert(args.mask==MASK_PLAYERSOLID and args.filter==p,'Full player-solid mask must reach generated boxes')
    assert(args.maxs.z==(p.duck and 36 or 72),'Probe follows the real crouched hull')
    return {Hit=not blocked,HitWorld=false,Entity=wall,Fraction=.5,HitNormal=Vector(1,0,0)}
end}
local press=hook.handlers.LOD_RPG_CheckpointDMovementJump
press(p,IN_JUMP)
assert(E.WallJumpState[p].count==1 and p.velocity.z==200 and p.velocity.x==160 and p.velocity.y==70)
assert(p.resource.magic==20 and not E.CloudStepState[p],'Wall Jump must precede Cloud Step')
p.duck=true
for i=2,4 do press(p,IN_JUMP);assert(E.WallJumpState[p].count==i and p.velocity.x==160 and p.velocity.z==200) end
assert(scans==32,'Exactly eight probes per requested kick; no recurring wall scans')
assert(not R:TryWallJump(p),'Fifth wall kick rejected')
press(p,IN_JUMP);assert(p.resource.magic==15 and E.CloudStepState[p].used,'After four kicks Cloud Step remains available once')
assert(not R:HandleAirborneJump(p),'Exhausted airborne actions do not refill')
p.ground=true;hook.handlers.LOD_RPG_CheckpointDWallJumpGroundReset()
assert(E.WallJumpState[p].count==0 and not E.CloudStepState[p].used)
p.ground=false;press(p,IN_JUMP);assert(E.WallJumpState[p].count==1)
for _,invalid in ipairs({'prop_physics','lod_hostile','lod_container_visual'}) do
 class=invalid;assert(not R:TryWallJump(p))
end
assert(E.WallJumpState[p].count==1,'Failed surface checks never spend a kick')
for _,valid in ipairs({'lod_gate','lod_jail_door'}) do class=valid;assert(R:TryWallJump(p)) end
assert(not E:ValidWallJumpTrace({Hit=true,HitWorld=true,StartSolid=true,HitNormal=Vector(1,0,0)}))
assert(not E:ValidWallJumpTrace({Hit=true,HitWorld=true,HitNormal=Vector(0,0,-1)}))
class='lod_static_box';LOD.RPGStatusElements={CanMoveVoluntarily=function() return false end}
assert(not R:TryWallJump(p),'Held cannot spend or execute voluntary wall movement')
LOD.RPGStatusElements=nil
p.dead=true;assert(not R:TryWallJump(p));p.dead=false
hook.handlers.LOD_RPG_CheckpointDWallJumpDeath(p);assert(not E.WallJumpState[p])
p.derived.wallJumpEnabled=false;assert(not R:TryWallJump(p));p.derived.wallJumpEnabled=true
R.SpringHeelImpulseMultiplier=function() return math.sqrt(2) end
assert(R:TryWallJump(p));assert(math.abs(p.velocity.z-200*math.sqrt(2))<.00001 and p.velocity.x==160)
p.ground=true;press(p,IN_JUMP);assert(not E.WallJumpState[p],'Landing press resets even before Think')
print('WALL_JUMP_RUNTIME_PASS: real input/trace/velocity path; generated walls; four kicks; crouch; fall/inward momentum; ground/death reset; Cloud Step priority; Spring Heel; invalid/held guards')
