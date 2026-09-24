-- Real procedural item, class utility roll, Beam combat/riders and finite resource.
local env=dofile('tools/test_equipment_economy_runtime.lua')
-- Native entities are userdata; the boundary double must not recursively copy owners.
local function copy(value,seen)
 if type(value)~='table' or IsValid(value) then return value end
 seen=seen or {};if seen[value] then return seen[value] end
 local out={};seen[value]=out;for k,v in pairs(value) do out[copy(k,seen)]=copy(v,seen) end
 return setmetatable(out,getmetatable(value))
end
table.Copy=copy
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local E,F,R,S,C,Rules,Rolls=LOD.Equipment,LOD.MagicForms,env.Run,LOD.RPGStatusElements,LOD.CharacterProgressionSystem,LOD.RPGAbilityRules,LOD.CombatRolls
local V=getmetatable(Vector())
V.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
V.__sub=function(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
V.__mul=function(a,b) return Vector(a.x*b,a.y*b,a.z*b) end
function V:LengthSqr() return self:DistToSqr(Vector()) end
function V:Distance(b) return math.sqrt(self:DistToSqr(b)) end
function V:GetNormalized() return self*(1/math.max(math.sqrt(self:LengthSqr()),.001)) end
local now=200;CurTime=function() return now end
local p,a,b,ally=env.actor('wand'),env.actor('one',true),env.actor('two',true),env.actor('ally')
local damageOrder,afterHit={},nil
for i,actor in ipairs({p,a,b,ally}) do
 actor.position=Vector((i-1)*100,0,2)
 actor.GetPos=function(self) return self.position end
 actor.GetShootPos=function(self) return self.position+Vector(0,0,36) end
 actor.WorldSpaceCenter=actor.GetShootPos
 actor.GetClass=function(self) return self.LODHostile and 'lod_hostile' or 'player' end
 actor.EntIndex=function() return i end
 actor.TakeDamageInfo=function(self,info)
  if self.cancelDamage then info:SetDamage(0) end
  S:ObserveDamage(self,info)
  self.hp=self.hp-info:GetDamage();self.lastInfo=info
  E:PostDamage(self,info,info:GetDamage()>0)
  damageOrder[#damageOrder+1]=self
  if afterHit then afterHit(self) end
 end
end
p.GetAimVector=function() return Vector(1,0,0) end
R.State.Graph={};R.State.BuildReady=true;R.State.PlayerState.wand=p.ps;p.ps.equipmentLifeSerial=1
LOD.Magic._EnsureState=function(_,actor) return actor.ps end;LOD.Magic._Sync=function() end
LOD.Magic.Stats={targets=0,damage=0}
LOD.FactionManager.IsOpponent=function(_,source,target) return source==p and (target==a or target==b) and target:Health()>0 end
player.GetAll=function() return {p,ally} end
local traces=0;local wall={valid=true,GetClass=function() return 'worldspawn' end,IsPlayer=function() return false end}
local wallFirst=false
util.TraceLine=function(d)
 traces=traces+1
 local ignored={};for _,actor in ipairs(d.filter) do ignored[actor]=true end
 for _,actor in ipairs(wallFirst and {} or {a,ally,b}) do
  if not ignored[actor] then return {Hit=true,HitPos=actor:WorldSpaceCenter(),Entity=actor} end
 end
 return {Hit=true,HitPos=Vector(700,0,38),Entity=wall}
end
MASK_SOLID,DMG_ENERGYBEAM=1,2
net.Broadcast=function() end
for _,name in ipairs({'Entity','String','UInt','Float','Vector'}) do net['Write'..name]=function() end end
local endpoints={};net.WriteVector=function(v) endpoints[#endpoints+1]=v end
DamageInfo=function()
 local info={}
 for _,name in ipairs({'Attacker','Inflictor','Damage','DamageType','DamagePosition','DamageForce'}) do
  info['Set'..name]=function(self,v) self[name]=v end;info['Get'..name]=function(self) return self[name] end
 end
 return info
end
game={GetWorld=function() end}
LOD.Audio={Emit=function() end}
dofile(root..'sv_magic_forms.lua');dofile(root..'sv_equipment_moves.lua');dofile(root..'sv_equipment_wand.lua')
local messages={};E.Report=function(_,_,text) messages[#messages+1]=text end
local utility=1;local utilityRolls=0;local feed={}
Rolls._Send=function(_,_,_,text,_,fields) feed[#feed+1]={text=text,fields=fields} end
Rolls._DamageEventText=function() return 'damage' end
Rolls._RNG=function(_,label)
 if label=='arcane-item-use' then return {Int=function(_,low,high) assert(low==1 and high==100);utilityRolls=utilityRolls+1;return utility end} end
 return {Int=function(_,low) return low end,Float=function() return 1 end,Shuffle=function() end}
end
local function class(id,level)
 local ps=p.ps.progressionState;ps.classId=id;ps.level=level or 1;C:_RecomputeProgressionState(ps)
end
local item=E:NewItem(p,'weapon_lod_wand','proof');local state=E:Ensure(p.ps)
-- Observe the real Wand transaction's settlement boundary without replacing
-- canonical Ace accounting. B18's behavioral suite owns receipt/life validation.
local commitAttack=Rules.CommitAttack
local attackObservations,attackReceipts=0,{}
function Rules:CommitAttack(actor,deferred)
 assert(deferred,'Wand must defer observation until Beam succeeds')
 local primed=commitAttack(self,actor,true)
 local receipt={actor=actor};attackReceipts[receipt]=true
 return primed,receipt
end
function Rules:ObserveCommittedAttack(actor,receipt)
 assert(attackReceipts[receipt] and receipt.actor==actor,'settles original Wand attack receipt')
 attackReceipts[receipt]=nil;attackObservations=attackObservations+1
end
assert(E:ValidateWearable(item) and item.charges==12 and E:Value(item)==item.budget)
assert(E:Description(item):find('CHARGES 12/12',1,true))
for _,n in ipairs({-1,13,1.5,math.huge}) do local bad=table.Copy(item);bad.charges=n;assert(not E:ValidateWearable(bad)) end
local bad=table.Copy(item);bad.charges=nil;assert(not E:ValidateWearable(bad));bad=table.Copy(item);bad.version=1;assert(not E:ValidateWearable(bad))
local seen=false
for seed=1,300 do
 local kind,payload=E:PrepareReward('wand','weapon',{weaponClass='weapon_smg1'},{staticId=seed,equipmentEligible=true})
 if kind=='wearable' and payload.item.definitionId=='weapon_lod_wand' then seen=true;assert(payload.item.charges==12) end
end
assert(seen,'eligible world rewards include Wands')
local _,mandatory=E:PrepareReward('wand','weapon',{weaponClass='weapon_smg1'},{staticId='mandatory'})
assert(mandatory.item.definitionId=='weapon_smg1')
assert(E:AcquireWorldItem(p,item,false,'pickup'));item=state.items[item.id]
assert(not E:Equipped(state,'weapon_lod_wand'),'pickup stores instead of wielding')
assert(E:InventoryWeapon(p,item.id,false));local weapon=p:GetActiveWeapon()
assert(weapon:GetClass()=='weapon_lod_wand' and weapon.nw.LOD_WandCharges==12)
class('fighter');assert(not E:FireWand(p,weapon) and item.charges==12 and utilityRolls==0)
class('wizard');p.ps.magic=47
assert(E:FireWand(p,weapon) and item.charges==11 and p.ps.magic==47 and utilityRolls==0)
assert(attackObservations==1,'one successful Wand commitment observed')
assert(a.hp<100 and b.hp<100 and ally.hp==100 and damageOrder[1]==a and damageOrder[2]==b and #damageOrder==2)
assert(endpoints[#endpoints].x==700,'visible Beam ends at its actual blocker')
local tags=S:DamageContext(a.lastInfo)
assert(tags.wand and tags.magic and not tags.physical and not tags.riderStatusId and a.lastInfo:GetDamageType()==DMG_ENERGYBEAM)
assert(tags.damageContract.baseDice==3 and tags.damageContract.equipmentSnapshot.itemId==item.id)
assert(not E:FireWand(p,weapon) and item.charges==11,'repeated same-tick trigger spends once')
local second=E:NewItem(p,'weapon_lod_wand','second');assert(E:AcquireWearable(state,second,true))
assert(E:InventoryWeapon(p,second.id,false));assert(not E:FireWand(p,weapon) and second.charges==12,'copies share cadence')
assert(E:InventoryWeapon(p,item.id,false));assert(item.charges==11 and weapon.nw.LOD_WandCharges==11)
-- Native entity recreation and serialization retain owned finite resources.
p.weapons.weapon_lod_wand=nil;assert(E:InventoryWeapon(p,item.id,false));weapon=p:GetActiveWeapon()
assert(item.charges==11 and weapon.nw.LOD_WandCharges==11)
local function reset()
 now=now+1;a.hp=100;b.hp=100;ally.hp=100;damageOrder={};afterHit=nil;wallFirst=false
 S:CureNegative(a);S:CureNegative(b)
end
reset();class('rogue',10);utility=51
assert(not E:FireWand(p,weapon) and item.charges==10 and #damageOrder==0 and p.ps.magic==47 and utilityRolls==1)
assert(attackObservations==1,'failed arcane use never triggers Censor')
assert(feed[#feed].fields.event=='arcane_item_use' and not feed[#feed].fields.success)
reset();utility=50;assert(E:FireWand(p,weapon) and item.charges==9 and utilityRolls==2)
for _,row in ipairs({{1,5},{10,50},{19,95},{20,95}}) do
 class('rogue',row[1]);utility=row[2];assert(Rules:TryArcaneItemUse(p))
 utility=row[2]+1;assert(not Rules:TryArcaneItemUse(p))
end
-- Invalid preflight never spends or rolls; muted and intimidated use canonical status.
class('wizard')
for _,status in ipairs({'muted','intimidated'}) do
 reset();S:Apply(p,status,a,{direct=true,duration=10});local before=item.charges
 assert(not E:FireWand(p,weapon) and item.charges==before);S:CureNegative(p)
end
reset();wallFirst=true;local before=item.charges;assert(E:FireWand(p,weapon) and item.charges==before-1 and #damageOrder==0,'wall/miss consumes committed charge')
reset();local aim=p.GetAimVector;p.GetAimVector=function() return Vector() end;before=item.charges
assert(not E:FireWand(p,weapon) and item.charges==before);p.GetAimVector=aim
-- Shared procedural riders execute for charged Magic only, without duplicate Content rider.
reset();local capture=E.CaptureAttack
function E:CaptureAttack(...)
 local snapshot=capture(self,...);snapshot.extras={proc_held=35};snapshot.dc.held=100;return snapshot
end
local rng=Rolls._RNG
Rolls._RNG=function(self,label)
 local r=rng(self,label);if label:find('equipment-riders:',1,true) then r.Float=function() return 0 end end;return r
end
assert(E:FireWand(p,weapon) and S:Has(a,'held') and S:Has(b,'held'))
E.CaptureAttack=capture;Rolls._RNG=rng
reset();a.cancelDamage=true;b.cancelDamage=true;before=item.charges
assert(E:FireWand(p,weapon) and item.charges==before-1 and not S:Has(a,'held'))
a.cancelDamage=nil;b.cancelDamage=nil
-- Stale state cannot continue a pierced shot into a later target.
for _,change in ipairs({'item','weapon','life','graph','role','run'}) do
 reset();item.charges=12 -- test-only independent cases, never a production refill path
 local graph,run=R.State.Graph,R.State
 afterHit=function(victim)
  if victim~=a then return end
  if change=='item' then E:Equip(state,second.id,'weapon_lod_wand')
  elseif change=='weapon' then p.activeClass='weapon_pistol'
  elseif change=='life' then p.ps.equipmentLifeSerial=p.ps.equipmentLifeSerial+1
  elseif change=='graph' then R.State.Graph={}
  elseif change=='role' then p.soldier=true
  else R.State=table.Copy(run) end
 end
 assert(E:FireWand(p,weapon) and a.hp<100 and b.hp==100,change)
 R.State=run;R.State.Graph=graph;p.soldier=false;p.activeClass='weapon_lod_wand';E:Equip(state,item.id,'weapon_lod_wand')
end
reset();item.charges=1;assert(E:FireWand(p,weapon) and item.charges==0)
reset();before=utilityRolls;assert(not E:FireWand(p,weapon) and item.charges==0 and utilityRolls==before)
assert(E:ValidateWearable(item) and E:Description(item):find('CHARGES 0/12',1,true))
local saved=table.Copy(p.ps.equipment);p.ps.equipment=saved;state=saved;item=saved.items[item.id]
E:ClearTransient(p);E:Sync(p);assert(weapon.nw.LOD_WandCharges==0 and not E:FireWand(p,weapon))
-- Reject live charged copies for lifecycle cases; an empty-copy denial would mask bugs.
second=state.items[second.id]
assert(E:InventoryWeapon(p,second.id,false) and second.charges==12)
local owner=weapon.GetOwner;weapon.GetOwner=function() return ally end
assert(not E:FireWand(p,weapon) and second.charges==12);weapon.GetOwner=owner
state.slots.weapon_lod_wand=nil
assert(not E:FireWand(p,weapon) and second.charges==12)
E:Equip(state,second.id,'weapon_lod_wand')
for _,scenario in ipairs({
 {function() p.soldier=true end,function() p.soldier=false end},
 {function() p.active=false end,function() p.active=true end},
 {function() p.hp=0 end,function() p.hp=100 end},
 {function() R.State.BuildReady=false end,function() R.State.BuildReady=true end},
 {function() R.State.SimulationFrozen=true end,function() R.State.SimulationFrozen=false end},
}) do
 reset();scenario[1]();local n=second.charges;assert(not E:FireWand(p,weapon) and second.charges==n);scenario[2]()
end
assert(E:FireWand(p,weapon) and second.charges==11,'restoring valid lifecycle permits activation')
reset();local castBeam=F._CastBeam;local observedBefore=attackObservations
F._CastBeam=function() return false end
assert(not E:FireWand(p,weapon) and attackObservations==observedBefore,'failed native Beam does not settle an attack observation')
F._CastBeam=castBeam
assert(E:InventoryWeapon(p,item.id,false))
assert(p.ps.magic==47 and #p.ps.progressionState.featIds==0)
-- Execute native adapter and HUD boundaries; no native ammunition/reload authority.
SERVER=true;CLIENT=false;AddCSLuaFile=function() end;SWEP={}
dofile('gamemodes/legend_of_deborah/entities/weapons/weapon_lod_wand/shared.lua')
assert(SWEP.Primary.Ammo=='none' and SWEP.Primary.ClipSize==-1 and not SWEP.Primary.Automatic)
local fire=E.FireWand;local native=0
E.FireWand=function(_,owner,w) assert(owner==p and w==weapon);native=native+1 end
weapon.SetNextPrimaryFire=function(_,t) assert(t==now+.65) end
SWEP.PrimaryAttack(weapon);assert(native==1);SWEP.Reload(weapon);assert(item.charges==0);E.FireWand=fire
SERVER=false;CLIENT=true;SWEP={};dofile('gamemodes/legend_of_deborah/entities/weapons/weapon_lod_wand/shared.lua')
LocalPlayer=function() return p end;ScrW=function() return 1280 end;ScrH=function() return 800 end
LOD.UI={HUDColor={}};TEXT_ALIGN_RIGHT=2;local labels={};draw={SimpleText=function(t) labels[#labels+1]=t end}
weapon.GetNW2Int=function(_,key,default) return weapon.nw[key] or default end
SWEP.DrawHUD(weapon);assert(labels[1]=='WAND  0 / 12' and labels[2]:find('DEPLETED',1,true))
print('WAND_PASS: real ownership, generation, class d100, finite per-copy charges, native adapter/HUD, shared ordered Beam and riders, blockers and stale lifecycle rejection')
