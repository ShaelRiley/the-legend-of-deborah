local fixture=dofile('tools/test_equipment_economy_runtime.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local F,R=LOD.MagicForms,fixture.Run
local V=getmetatable(Vector())
V.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
V.__sub=function(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
V.__mul=function(a,b) return Vector(a.x*b,a.y*b,a.z*b) end
V.__unm=function(a) return a*-1 end
function V:Dot(b) return self.x*b.x+self.y*b.y+self.z*b.z end
function V:LengthSqr() return self:Dot(self) end
function V:Length() return math.sqrt(self:LengthSqr()) end
function V:GetNormalized() return self*(1/math.max(self:Length(),.00001)) end
local now=0;CurTime=function() return now end
local hooks,commands={},{};hook.Add=function(_,id,fn) hooks[id]=fn end
concommand.Add=function(id,fn) commands[id]=fn end
local owner=fixture.actor('wall-owner');owner.ps.progressionState.classId='wizard'
function owner:GetShootPos() return Vector(0,0,64) end
function owner:GetAimVector() return Vector(1,0,0) end
function owner:GetClass() return 'player' end
R.State.PlayerState['wall-owner']=owner.ps
LOD.Magic._EnsureState=function(_,p) return p.ps end
LOD.Magic._Sync=function() end;LOD.Magic.NextCast={};LOD.Magic.Stats={casts=0}
LOD.MagicProgression:GrantForm(owner.ps.progressionState,'wall')
LOD.MagicProgression:SelectForm(owner.ps.progressionState,'wall')
owner.ps.progressionState.contentIds={'fire'};owner.ps.progressionState.selectedMagicContentId='fire'
dofile(root..'sv_magic_wall.lua')
MASK_SOLID=1
-- Actual swept AABB collision with crates/floor/characters, not canned placement.
local boxes={{lo=Vector(-1000,-1000,-30),hi=Vector(1000,1000,0)},
 {lo=Vector(150,-400,0),hi=Vector(350,-130,180)},
 {lo=Vector(150,130,0),hi=Vector(350,400,180)}}
local function trace(d)
 local mins,maxs=d.mins or Vector(),d.maxs or Vector()
 local delta=d.endpos-d.start;local result={Hit=false,Fraction=1,HitPos=d.endpos}
 for _,b in ipairs(boxes) do
  if not b.entity or not d.filter or d.filter(b.entity) then
   local lo,hi=b.lo-maxs,b.hi-mins
   local enter,leave,normal=0,1,Vector();local inside=true;local miss=false
   for _,axis in ipairs({'x','y','z'}) do
    local start,step=d.start[axis],delta[axis]
    if start<=lo[axis] or start>=hi[axis] then inside=false end
    if math.abs(step)<.00001 then if start<lo[axis] or start>hi[axis] then miss=true end
    else
     local a,c=(lo[axis]-start)/step,(hi[axis]-start)/step;local sign=-1
     if a>c then a,c=c,a;sign=1 end
     if a>enter then enter=a;normal=Vector();normal[axis]=sign end
     leave=math.min(leave,c)
    end
   end
   if inside then return {StartSolid=true,Hit=true,HitPos=d.start,Fraction=0} end
   if not miss and enter<=leave and enter>=0 and enter<result.Fraction and leave>0 then
    result={Hit=true,Fraction=enter,HitPos=d.start+delta*enter,HitNormal=normal,Entity=b.entity}
   end
  end
 end
 return result
end
util.TraceLine=trace;util.TraceHull=trace
local context={spatialBonusCells=1}
local p=assert(F:WallPlacement(owner,context));assert(p.maxs.y-p.mins.y<260 and p.maxs.y-p.mins.y>240)
assert(F:WallWidth({spatialBonusCells=4})>F:WallWidth(context) and F:WallWidth({spatialBonusCells=100})==1152)
local hero=fixture.actor('teammate')
boxes[#boxes+1]={entity=hero,lo=Vector(220,-16,0),hi=Vector(260,16,72)}
assert(F:WallPlacement(owner,context),'Hero overlapping the placement is legal')
hero.nw.LOD_IsSoldier=true
local shifted=F:WallPlacement(owner,context)
assert(not shifted or shifted.origin.x+shifted.maxs.x<220,'Enemy occupant cannot be entombed')
table.remove(boxes)
local env=setmetatable({ENT={},AddCSLuaFile=function() end,include=function() end},{__index=_G})
assert(loadfile('gamemodes/legend_of_deborah/entities/entities/lod_magic_wall/init.lua','t',env))()
local spawned={}
ents={Create=function(class)
 assert(class=='lod_magic_wall')
 local e=setmetatable({valid=true},{__index=env.ENT})
 for _,name in ipairs({'SetModel','SetMoveType','SetSolid','SetSolidFlags','SetCustomCollisionCheck','SetCollisionBounds','SetCollisionGroup','DrawShadow','AddEFlags','SetColor','Activate','NextThink'}) do e[name]=function() end end
 for _,name in ipairs({'Pos','WallMins','WallMaxs','ExpiresAt'}) do
  e['Set'..name]=function(self,value) self[name]=value end;e['Get'..name]=function(self) return self[name] end
 end
 function e:Spawn() self:Initialize() end
 function e:Remove() self.valid=false;self:OnRemove() end
 function e:GetOwner() end
 function e:IsPlayer() return false end
 spawned[#spawned+1]=e;return e
end}
local target=fixture.actor('contact',true);target.pos=Vector(265,0,36)
target.WorldSpaceCenter=function(self) return self.pos end
LOD.FactionManager={IsOpponent=function(_,_,t) return IsValid(t) and t.LODHostile and t:Health()>0 end}
ents.FindInBox=function() return {target,owner} end
local hits,riders=0,0
local productionDamage=F._ApplyDamage
F._ApplyDamage=function(_,caster,credit,t,form,content,ctx)
 assert(caster==owner and credit==owner and form.id=='wall' and ctx.equipmentSnapshot)
 hits=hits+1;if content and content.rider then riders=riders+1 end
 t.hp=t.hp-1;return true
end
owner.ps.magic=100;assert(F:CastSelected(owner));assert(owner.ps.magic==50,'35 base + Fire surcharge')
local wall=spawned[#spawned]
local clipped,blocked=F:ConstrainWallMovement(target,Vector(150,0,1),Vector(400,0,1))
assert(blocked and clipped.x<wall.Pos.x+wall.WallMins.x-16,'Swept movement cannot tunnel through Wall')
local around,aroundBlocked=F:ConstrainWallMovement(target,Vector(150,200,1),Vector(400,200,1))
assert(not aroundBlocked and around.x==400,'Enemies can go around a short Wall')
local over,overBlocked=F:ConstrainWallMovement(target,Vector(150,0,130),Vector(400,0,130))
assert(not overBlocked,'Legitimate passage over a Wall stays open')
local heroStep,heroBlocked=F:ConstrainWallMovement(owner,Vector(150,0,1),Vector(400,0,1))
assert(not heroBlocked and heroStep.x==400)
-- Execute the real kinematic mover, not just the clipping helper.
V.__div=function(a,b) return a*(1/b) end
function V:Angle() return {y=0} end
Angle=function(p,y,r) return {p=p,y=y,r=r} end
LOD.MazeGenerator=LOD.MazeGenerator or {CellKey=function() return 'cell' end}
dofile(root..'sv_hostile_motion_v2.lua')
function target:GetPos() return self.motionPos end
function target:SetPos(p) self.motionPos=p end
function target:SetAngles() end
local motion=LOD.HostileMotionV2
local canMove,observe=LOD.RPGStatusElements.CanMoveVoluntarily,LOD.RPGStatusElements.ObserveCell
LOD.RPGStatusElements.CanMoveVoluntarily=function() return true end
LOD.RPGStatusElements.ObserveCell=function() end
local speed=LOD.RPGAbilityRules.RogueMovementMultiplier;LOD.RPGAbilityRules.RogueMovementMultiplier=function() return 1 end
local function move()
 target.motionPos=Vector(150,0,1);target.LODMotionLastUpdate=now-.05;target.LODConfig={speed=10000}
 return motion:MoveToward(target,{pos=Vector(400,0,1)})
end
assert(not move() and target.motionPos.x<wall.Pos.x+wall.WallMins.x-16 and target.LODMotionMode=='magic-wall')
LOD.RPGStatusElements.CanMoveVoluntarily=canMove;LOD.RPGStatusElements.ObserveCell=observe
LOD.RPGAbilityRules.RogueMovementMultiplier=speed
boxes[#boxes+1]={entity=wall,lo=wall.Pos+wall.WallMins,hi=wall.Pos+wall.WallMaxs}
wall:Think();assert(hits==1 and riders==1)
now=.5;wall:Think();assert(hits==1)
now=1;wall:Think();assert(hits==2 and riders==1,'Once per cast rider, repeat contact damage')
target.pos=Vector(215,0,36);now=2;wall:Think();assert(hits==3,'Contact works from either side')
boxes[#boxes+1]={lo=Vector(200,-40,118),hi=Vector(280,40,124)}
target.pos=Vector(215,0,150);now=3;local floorHits=hits;wall:Think();assert(hits==floorHits,'Solid floor rejects vertical contact')
local ceiling=table.remove(boxes);now=3.1;wall:Think();assert(hits==floorHits+1,'Open vertical geometry admits a target overlapping contact bounds')
boxes[#boxes+1]=ceiling
-- Thin solid cover between target and wall face blocks the contact trace.
boxes[#boxes]={lo=Vector(228,-40,0),hi=Vector(230,40,120)}
target.pos=Vector(215,0,36);now=4;local before=hits;wall:Think();assert(hits==before)
table.remove(boxes)
owner.ps.magic=100;LOD.Magic.NextCast[owner]=0
local ok,why=F:CastSelected(owner);assert(not ok and why=='wall_cap' and owner.ps.magic==100)
now=11;wall:Think();assert(not wall.valid and not next(F.ActiveWalls) and owner.nw.LOD_WallRemaining==1)
table.remove(boxes)
local function cast() owner.ps.magic=100;LOD.Magic.NextCast[owner]=0;assert(F:CastSelected(owner));return spawned[#spawned] end
local reset=cast();R.State.LevelSeed=R.State.LevelSeed+1;reset:Think();assert(not reset.valid)
local dead=cast();hooks.LOD_WallDeath(owner);assert(not dead.valid)
local disconnected=cast();hooks.LOD_WallDisconnect(owner);assert(not disconnected.valid)
local failed=cast();R.State.Failed=true;failed:Think();assert(not failed.valid);R.State.Failed=false
local clean=cast();hooks.LOD_WallCleanup();assert(not clean.valid and not next(F.ActiveWalls))
-- Real authoritative damage invokes the canonical stun API with the Form factor.
F._ApplyDamage=productionDamage
local stun
LOD.M3HitFeedback={ApplyHitStun=function(_,victim,ordinary,caster,multiplier) stun={victim,ordinary,caster,multiplier} end}
local roll=F._RollDamage;F._RollDamage=function() return {values={3,3},baseDice=2} end
local resolve=LOD.CombatRolls.ResolveActorDamage;LOD.CombatRolls.ResolveActorDamage=function() return 6 end
DamageInfo=function()
 local out={}
 for _,name in ipairs({'Attacker','Inflictor','Damage','DamageType','DamagePosition','DamageForce'}) do
  out['Set'..name]=function(self,value) self[name]=value end
  out['Get'..name]=function(self) return self[name] end
 end
 return out
end
function target:TakeDamageInfo(info) self.hp=self.hp-info:GetDamage() end
F._ReportDamageRoll=function() end
F:_ApplyDamage(owner,owner,target,LOD.RPG.MagicForms.wall,nil,{damageDiceUsed=0},Vector(1,0,0))
assert(stun and stun[1]==target and stun[2]==1 and stun[3]==owner and stun[4]==2.5)
F._RollDamage=roll;LOD.CombatRolls.ResolveActorDamage=resolve
-- Grant command is class-safe, owner-local, gated, repeatable and unranked.
local dev=false;GetConVar=function() return {GetBool=function() return dev end} end
function owner:IsAdmin() return self.admin end
local unranked=0;R.MarkUnranked=function() unranked=unranked+1 end
local sync=0;LOD.CharacterProgressionSystem.SyncPlayer=function(_,ply) assert(ply==owner);sync=sync+1 end
dofile(root..'sv_magic_testkit.lua')
commands.lod_magic_test_all(owner);assert(unranked==0)
dev=true;commands.lod_magic_test_all(owner);assert(unranked==0)
owner.admin=true;commands.lod_magic_test_all(owner)
assert(#owner.ps.progressionState.magicFormIds==10 and #owner.ps.progressionState.contentIds==6 and owner.ps.magic==100 and sync==1)
commands.lod_magic_test_all(owner);assert(#owner.ps.progressionState.magicFormIds==10)
owner.ps.progressionState.classId='rogue';commands.lod_magic_test_all(owner)
assert(#owner.ps.progressionState.magicFormIds==8)
assert(not LOD.MagicProgression:SelectForm(owner.ps.progressionState,'wall'))
owner.ps.progressionState.selectedMagicFormId='wall';assert(not F:SelectedCastState(owner))
print('MAGIC_WALL_PASS: geometric gap fitting, Wisdom cap, Hero overlap, enemy rejection, cast cost/cap, both-side cover/contact/riders, stun factor, lifecycle, ten-Form dev grant and class enforcement')

-- Production collision rule, in both argument orders, keeps human Soldiers solid.
local file=assert(io.open('gamemodes/legend_of_deborah/gamemode/shared.lua'))
local source=file:read('*a');file:close()
local chunk=assert(source:match('(function GM:ShouldCollide.-)\nif CLIENT then'))
GM={};assert(load(chunk))()
local barrier={valid=true,GetClass=function() return 'lod_magic_wall' end,IsPlayer=function() return false end}
assert(GM:ShouldCollide(barrier,owner)==false and GM:ShouldCollide(owner,barrier)==false)
owner.nw.LOD_IsSoldier=true;assert(GM:ShouldCollide(barrier,owner)==nil)
owner.nw.LOD_IsSoldier=false
-- Ordinary stun tuning stays intact; Wall is an explicit Form multiplier.
dofile(root..'sv_m3_hit_feedback.lua')
function target:SetVelocity() end
LOD.RPGAbilityRules.HitStunMultiplier=function() return 1 end
LOD.M3HitFeedback:ApplyHitStun(target,1,owner,2.5)
assert(math.abs(target.LODHitStunUntil-now-.75)<.0001,'2.5 x 0.30s base stun')
now=now+2;LOD.M3HitFeedback:ApplyHitStun(target,1,owner)
assert(math.abs(target.LODHitStunUntil-now-.30)<.0001,'Ordinary hits keep their original stun')
print('WALL_COLLISION_STUN_PASS: Hero passage, Soldier blocking, actual .75s stun and unchanged ordinary .30s')
