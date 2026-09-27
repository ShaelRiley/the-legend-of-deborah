-- Production status input -> Throwable SecondaryAttack -> inventory/heal/cure.
local env=dofile('tools/test_equipment_economy_runtime.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
dofile(root..'sv_rpg_status_elements.lua')
local E,Status=LOD.Equipment,LOD.RPGStatusElements
local p=env.actor('muted-potion')
env.Run.State.PlayerState[p.id]=p.ps
p.hp=60
assert(E:AddConsumable(E:Ensure(p.ps),'healing_potion',2))
assert(E:Activate(p))
local enemy=env.actor('silencer',true)
assert(Status:Apply(p,'muted',enemy,{direct=true,dc=99,rng={Int=function(_,lo) return lo end}}))
assert(Status:Has(p,'muted') and not Status:CanInitiateMagic(p))
IN_ATTACK,IN_ATTACK2=1,2048
local cmd={keys={[IN_ATTACK]=true,[IN_ATTACK2]=true},
 RemoveKey=function(self,key) self.keys[key]=nil end,
 KeyDown=function(self,key) return self.keys[key]==true end}
env.hooks.LOD_RPG_StatusActionLocks(p,cmd)
assert(cmd:KeyDown(IN_ATTACK2),'Muted incorrectly prevents drinking its own potion cure')
assert(cmd:KeyDown(IN_ATTACK),'Muted must not disable ordinary physical input')
SERVER=true;AddCSLuaFile=function() end
SWEP={}
dofile('gamemodes/legend_of_deborah/entities/weapons/weapon_lod_throwable/shared.lua')
local weapon=setmetatable({GetOwner=function() return p end,
 SetNextSecondaryFire=function(self,t) self.ready=t end},{__index=SWEP})
weapon:SecondaryAttack()
assert(p:Health()==85 and not Status:Has(p,'muted'),'drink failed to heal and cure')
assert(E:Equipped(p.ps.equipment,'throwable').count==1,'drink must consume exactly one unit')
assert(p.ps.magic==100,'nonspell cure spent Magic')
-- Ordinary spell input still obeys Muted; the bottle exception cannot unlock it.
assert(Status:Apply(p,'muted',enemy,{direct=true,dc=99,rng={Int=function(_,lo) return lo end}}))
p:Give('weapon_pistol');p:SelectWeapon('weapon_pistol')
cmd.keys={[IN_ATTACK]=true,[IN_ATTACK2]=true}
env.hooks.LOD_RPG_StatusActionLocks(p,cmd)
assert(not cmd:KeyDown(IN_ATTACK2) and cmd:KeyDown(IN_ATTACK))
assert(not Status:CanInitiateMagic(p),'potion input exception unlocked spell authority')
print('MUTED_POTION_PASS: real input, owned bottle, native secondary callback, one debit, healing/cure, spell denial')
