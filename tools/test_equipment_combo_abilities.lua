-- Production equipment -> combo -> graph/cover target -> dice/save/damage.
local env=dofile('tools/test_equipment_economy_runtime.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local E,F,R,S,C=LOD.Equipment,LOD.MagicForms,env.Run,LOD.RPGStatusElements,LOD.CharacterProgressionSystem
local V=getmetatable(Vector())
V.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
V.__sub=function(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
V.__mul=function(a,b) return Vector(a.x*b,a.y*b,a.z*b) end
function V:GetNormalized() local d=math.sqrt(self:DistToSqr(Vector()));return self*(1/math.max(d,.001)) end
local now=200;CurTime=function() return now end
local p,a,b,ally=env.actor('crown'),env.actor('far',true),env.actor('near',true),env.actor('ally')
for i,actor in ipairs({p,a,b,ally}) do
 actor.position=Vector((i==1 and 0 or i==2 and 600 or i==3 and 400 or 10),0,2)
 actor.GetPos=function(self) return self.position end
 actor.WorldSpaceCenter=function(self) return self.position+Vector(0,0,36) end
 actor.GetShootPos=actor.WorldSpaceCenter
 actor.GetOwner=function() end
 actor.GetClass=function(self) return self.LODHostile and 'lod_hostile' or 'player' end
 actor.EntIndex=function() return i end
 actor.TakeDamageInfo=function(self,info) self.hp=self.hp-info:GetDamage();self.lastInfo=info end
end
p.ps.progressionState.baseAbilities.wis=20;C:_RecomputeProgressionState(p.ps.progressionState)
LOD.Magic._EnsureState=function(_,actor) return actor.ps end
LOD.Magic._Sync=function() end
LOD.Magic.Stats={targets=0,damage=0}
LOD.MazeGenerator={CellKey=function(x,y,z) return x..':'..y..':'..z end}
LOD.Config.Maze.Width,LOD.Config.Maze.Height=3,1
LOD.Config.Maze.CellSize,LOD.Config.Maze.LevelHeight,LOD.Config.Maze.Origin=384,300,Vector()
function LOD.MazeBuilder:CellCenter(c) return Vector((c.x-2)*384,0,c.z*300) end
LOD.MazeNavigator={};dofile(root..'sv_maze_navigator.lua')
local c0={x=2,y=1,z=0,neighbors={['3:1:0']=true}}
local c1={x=3,y=1,z=0,neighbors={['2:1:0']=true}}
R.State.Graph={Cells={['2:1:0']=c0,['3:1:0']=c1},Width=3,Height=1,Layers=1,
 Progression={Gates={{edgeKey='2:1:0|3:1:0'}}}}
R.State.GatesOpen={true}
LOD.FactionManager.Opponents=function() return {a,b} end
local blocked={}
util.TraceLine=function(d) local hit=blocked[d.endpos.x];return {Hit=hit,Fraction=hit and .5 or 1} end
MASK_SOLID,DMG_ENERGYBEAM=1,2
game={GetWorld=function() return nil end}
net.WriteEntity=function() end;net.WriteString=function() end;net.Broadcast=function() end
DamageInfo=function()
 local out={}
 for _,name in ipairs({'Attacker','Inflictor','Damage','DamageType','DamagePosition','DamageForce'}) do
  out['Set'..name]=function(self,value) self[name]=value end
  out['Get'..name]=function(self) return self[name] end
 end
 return out
end
-- Reload only to bind the real navigator in the shared closure.
dofile(root..'sv_magic_forms.lua')
dofile(root..'sv_equipment_moves.lua')
local crown=E:NewItem(p,'psychic_crown','proof')
assert(crown and crown.rarity>=2 and E:ValidateWearable(crown))
assert(E:InnateValue('psychic_crown',100)==50)
assert(E:Budget(1,'psychic_crown',2,100)==E:Budget(1,'headwear',2,100)+50)
local copy=table.Copy(crown);copy.version=1
assert(not E:ValidateWearable(copy),'Innate items cannot use legacy validation to evade their price/rarity')
for seed=1,300 do
 local item=E:Generate(seed,seed%999+1,'psychic_crown','crown:'..seed)
 assert(E:ValidateWearable(item) and E:Value(item)==item.budget and item.rarity>=2)
end
assert(E:Description(crown):find('↓ ↑ ↓',1,true))
local gear=E:Ensure(p.ps);assert(E:AcquireWearable(gear,crown,false));E:RefreshDerived(p,p.ps)
local _,grants=E:Contributions(gear);assert(grants.psychic_crush and #p.ps.progressionState.featIds==0)
local texts={};LOD.CombatRolls._Send=function(_,_,_,text) texts[#texts+1]=text end
LOD.CombatRolls._DamageEventText=function(_,_,_,amount,target,detail) return target.id..':'..amount..':'..detail end
local die=4
LOD.CombatRolls._RNG=function(_,label)
 return {Int=function(_,lo,hi) return hi==20 and die or lo end,Float=function() return 1 end}
end
local productionRoll=F._RollDamage
F._RollDamage=function(_,attacker,form,context)
 assert(form.damageDice==2 and form.damageSides==8 and context.equipmentSnapshot and context.castSerial)
 return {values={4,4},contributions={4,4},baseDice=2,bonus=0,total=8,attackEvent=context}
end
-- Isolate dice results and inspect the REAL shared WIS/equipment resolver.
local function cast() local ok;for _,t in ipairs({'DOWN','UP','DOWN'}) do now=now+.1;ok=E:DirectionToken(p,t) end;return ok end
assert(cast() and p.ps.magic==82 and b.hp<100 and a.hp==100 and ally.hp==100)
local full=100-b.hp
assert(texts[#texts]:find('near:',1,true) and texts[#texts]:find('FULL DAMAGE',1,true))
assert(not cast() and p.ps.magic==82,'Cooldown cannot double spend')
now=now+5;b.hp=100;die=20
assert(cast() and math.abs((100-b.hp)*2-full)<.00001,'Successful shared WIS save halves resolved damage')
assert(texts[#texts]:find('HALF DAMAGE',1,true))
now=now+5;blocked[400]=true;a.hp=100
assert(cast() and a.hp<100,'Next visible target wins when nearest is behind cover')
now=now+5;blocked[600]=true;local before=p.ps.magic
assert(not cast() and p.ps.magic==before,'No target preserves Magic')
blocked={};R.State.GatesOpen[1]=false
assert(not cast() and p.ps.magic==before,'Unopened progression gate prevents target acquisition')
R.State.GatesOpen[1]=true
assert(S:Apply(p,'muted',p,{direct=true,duration=5}))
assert(not cast() and p.ps.magic==before);S:CureNegative(p)
E:UnequipItem(gear,crown.id);assert(not cast() and p.ps.magic==before)
assert(E:Equip(gear,crown.id,'head'))
E:DirectionToken(p,'DOWN');E:DirectionToken(p,'UP')
E:UnequipItem(gear,crown.id);E:DirectionToken(p,'UP');E:Equip(gear,crown.id,'head')
assert(not E:DirectionToken(p,'DOWN'),'Changed grants invalidate buffered inputs')
local old=E:MoveSession(p);p.ps.equipmentLifeSerial=1
assert(not E:ExecuteMove(p,'psychic_crush',old) and p.ps.magic==before,'Previous life session cannot spend')
-- Ownership-aware collision handling and variable-length suffixes use ONE stream.
local calls={};E.MoveHandlers.probe={prepare=function() return {} end,resolve=function(_,move) calls[#calls+1]=move.id end}
E.SpecialMoves.unowned={id='unowned',recipe={'LEFT','DOWN','RIGHT'},effect='probe',magicCost=1,cooldown=1}
E.SpecialMoves.owned={id='owned',recipe={'LEFT','DOWN','RIGHT'},effect='probe',magicCost=1,cooldown=1}
E.SpecialMoves.long={id='long',recipe={'UP','LEFT','DOWN','UP'},effect='probe',magicCost=1,cooldown=1}
E.MoveOrder={'unowned','owned','long'}
local aggregate=E.Contributions
function E:Contributions() return {},{owned=true,long=true} end
local function tokens(values) local ok;for _,v in ipairs(values) do now=now+.1;ok=E:DirectionToken(p,v) end;return ok end
assert(tokens({'RIGHT','LEFT','DOWN','RIGHT'}) and calls[#calls]=='owned','Unowned same recipe cannot intercept')
assert(tokens({'RIGHT','UP','LEFT','DOWN','UP'}) and calls[#calls]=='long','Four-token suffix executes after leading noise')
E.SpecialMoves.unowned.recipe={};E:DirectionToken(p,'RESET')
assert(not tokens({'RIGHT'}),'Empty recipe never executes')
E.Contributions=aggregate;F._RollDamage=productionRoll
print('EQUIPMENT_COMBO_ABILITIES_PASS: generated Crown; innate price/rarity; effective grants; real gate/cover selection; WIS damage/save feedback; atomic rejection; session lifecycle; unowned collisions and variable recipe suffixes')
