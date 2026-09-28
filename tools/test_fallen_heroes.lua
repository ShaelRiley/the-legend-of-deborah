-- Real copy/service/combat authorities; only Source entities, traces and transport
-- are doubled. No event registry/director is loaded: events-off must work.
local env=dofile('tools/test_equipment_economy_runtime.lua')
-- GMod native entities are userdata, never recursive copies of their owners.
local function copy(value,seen)
 if type(value)~='table' or IsValid(value) then return value end
 seen=seen or {};if seen[value] then return seen[value] end
 local out={};seen[value]=out
 for k,v in pairs(value) do out[copy(k,seen)]=copy(v,seen) end
 return setmetatable(out,getmetatable(value))
end
table.Copy=copy
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local Run,E,P,Rules,Status=env.Run,LOD.Equipment,LOD.CharacterProgressionSystem,LOD.RPGAbilityRules,LOD.RPGStatusElements
local V=getmetatable(Vector())
V.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
V.__sub=function(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
V.__mul=function(a,b) return Vector(a.x*b,a.y*b,a.z*b) end
V.__div=function(a,b) return a*(1/b) end
function V:LengthSqr() return self:DistToSqr(Vector()) end
function V:Length() return math.sqrt(self:LengthSqr()) end
function V:GetNormalized() return self/math.max(.001,self:Length()) end
function V:Distance(b) return (self-b):Length() end
function V:Angle() return {p=0,y=0,r=0} end
local now=100;CurTime=function() return now end;SysTime=CurTime
local noop=function() end
net.Broadcast=noop
for _,n in ipairs({'String','UInt','Float','Bool','Entity','Vector'}) do net['Write'..n]=noop end
DMG_CLUB,DMG_BULLET,DMG_ENERGYBEAM,DMG_FALL,DMG_DROWN,DMG_POISON,DMG_RADIATION,MASK_SHOT=1,2,4,8,16,32,64,128
function DamageInfo()
 local d={value=0}
 for _,name in ipairs({'Damage','Attacker','Inflictor','DamagePosition','DamageForce','DamageType'}) do
  d['Set'..name]=function(self,v) self[name]=v end
  d['Get'..name]=function(self) return self[name] end
 end
 function d:IsDamageType(v) return self.DamageType==v end
 return d
end
LOD.NewDamageInfo=DamageInfo
game={GetWorld=function() return nil end}
dofile(root..'sv_combat_rolls.lua')
dofile(root..'sv_combat_feed_semantics.lua')
dofile(root..'sv_magic.lua')
dofile(root..'sv_player_weapon_specials.lua')
dofile(root..'sv_skeleton_hero.lua')
dofile(root..'sv_faction_manager.lua')
dofile(root..'sv_fallen_heroes.lua')
local F=LOD.FallenHeroes
local cell={x=1,y=1,z=0,neighbors={}}
LOD.MazeGenerator={CellKey=function(x,y,z) return x..':'..y..':'..z end}
Run.State.Graph={Cells={['1:1:0']=cell}}
Run.State.BuildReady=true;Run.State.CampaignEpoch=3
LOD.MazeNavigator={WorldToCell=function() return cell end,CellCenter=function() return Vector(128,128,0) end,
 CanTraverse=function() return true end}
local blocked=false
LOD.SafeTeleport={FlatCell=function() return true end,Landing=function(_,probe,g,c,p)
 assert(probe:GetHull());return not blocked and p+Vector(0,0,2) or nil
end}
LOD.StagingRoom={IsPlayerInHut=function(_,p) return p.staging end}
local p=env.actor('hero');p.LODRunSpawnSerial=1
p.GetWeapons=function(self) local out={} for _,w in pairs(self.weapons) do out[#out+1]=w end return out end
p.GetWalkSpeed=function() return 180 end;p.Nick=function() return 'Test Hero' end
p.GetAmmo=function(self) return self.ps.inventory.ammo end
p.Armor=function(self) return self.ps.armor end
p.GetPos=function() return Vector(130,128,2) end
local w=p:Give('weapon_pistol');w.clip=3;p.activeClass='weapon_pistol'
w.GetPrimaryAmmoType=function() return 1 end;w.GetMaxClip1=function() return 18 end
w.GetModel=function() return 'models/weapons/w_pistol.mdl' end
p.ps.inventory={weapons={{class='weapon_pistol',clip1=3}},ammo={[1]=8},activeWeaponClass='weapon_pistol'}
p.ps.equipment=E:Ensure(p.ps)
E:EnsureWeapon(p,'weapon_pistol');E:RefreshDerived(p,p.ps)
p.ps.progressionState.characterIdentityPackage=P:_BuildIdentityPackage({State={RosterSeed=13,PlayerState={}}},{identity='hero',ordinal=1},{presentationSex='male',model='models/player/kleiner.mdl'})
p.ps.progressionState.characterIdentityPackage.fullDisplayName='Rook of the Ashes'
p.ps.progressionState.featIds={'STR_CROWBAR_D12'}
P:_RecomputeProgressionState(p.ps.progressionState)
p.ps.magic=41;p.ps.armor=12
Run.State.PlayerState={hero=p.ps}
player.GetAll=function() return {p} end
local target=env.actor('target');target.GetPos=function() return Vector(160,128,2) end
target.WorldSpaceCenter=function(self) return self:GetPos()+Vector(0,0,40) end
function target:TakeDamageInfo(info)
 self.lastInfo=info;self.hp=self.hp-info:GetDamage()
 E:PostDamage(self,info,info:GetDamage()>0)
end
local nativeCreated=0
ents={Create=function(class)
 assert(class=='lod_hostile');nativeCreated=nativeCreated+1
 local e=env.actor('bones'..nativeCreated,true)
 e.SetPos=function(self,v) self.pos=v end;e.GetPos=function(self) return self.pos end
 e.WorldSpaceCenter=function(self) return self:GetPos()+Vector(0,0,36) end
 e.GetForward=function() return Vector(1,0,0) end
 e.Spawn=function(self) self.hp=8;self.max=8 end;e.Activate=noop
 e.SetModel=function(self,m) self.model=m end;e.SetColor=noop
 e.Remove=function(self) self.valid=false end;e.GetClass=function() return 'lod_hostile' end
 e._RefreshTarget=function(self) self.LODTarget=target end
 e._RefreshRoute=noop;e._AdvanceWaypoint=function() end;e._HasLineOfSight=function() return true end
 e.loco={FaceTowards=noop}
 e.FireBullets=function(self,data)
  self.lastBullet=data
  for _=1,data.Num do data.Callback(self,{Entity=target,HitPos=target:WorldSpaceCenter()},DamageInfo()) end
 end
 return e
end}
LOD.HostileMotionV2={Stop=noop,HoldHitStun=function() return false end,MoveToward=noop}
LOD.HostileAnimation={Apply=function(_,e,activity,force)
 assert(e.model==LOD.SkeletonHero.Model and activity==ACT_IDLE and force,'copy animated before skeleton model swap')
 e.spawnAnimated=true
end,PlayerAttack=function(_,e) e.playerAttacks=(e.playerAttacks or 0)+1 end}
LOD.SkeletonHero.Colors.fighter=Color(255,185,165)
LOD.RPGTestLog=nil
LOD.CombatRolls._Send=noop
local ok,r=F:Capture(p,p.ps)
assert(ok and nativeCreated==0 and #F.Records==1,'Native spawn in lethal callback')
assert(not F:Capture(p,p.ps) and #F.Records==1,'Same life captured twice')
assert(r.profile.classId==p.ps.progressionState.classId and r.profile.level==p.ps.progressionState.level)
assert(r.profile.actorType=='hero' and r.profile.fallenHero and r.profile.usesMagic)
assert(r.name=='Rook of the Ashes' and r.profile.magic==41 and r.armor==12)
assert(r.profile.featIds[1]=='STR_CROWBAR_D12' and r.profile.derivedStats.maxHP==p.ps.progressionState.derivedStats.maxHP)
local oldStat=r.profile.baseAbilities.str
p.ps.progressionState.baseAbilities.str=99;p.ps.inventory.ammo[1]=999;p.ps.magic=100
assert(r.profile.baseAbilities.str==oldStat and r.inventory.ammo[1]==8 and r.profile.magic==41,'Live alias survived capture')
blocked=true;F:Service();assert(nativeCreated==0,'Blocked hull spawned')
blocked=false;now=101;F:Service()
local e=assert(r.entity);assert(nativeCreated==1 and e:Health()==r.maxHP and e:GetMaxHealth()==r.maxHP)
assert(e.spawnAnimated,'fallen copy left native Initialize pose active during rise')
assert(not F:Live(e) and not LOD.SkeletonHero:Live(e),'Rise warning attacked')
now=105;assert(F:Live(e) and LOD.SkeletonHero:Live(e))
-- Player respawn/disconnect/role changes cannot retarget the copied profile.
p.LODRunSpawnSerial=2;p.valid=false
assert(F:Live(e) and e.LODProgressionState==r.profile)
-- A roll observer may replace the world. Never fire native bullets afterwards.
local baseRoll=LOD.CombatRolls.RollPlayerWeapon
local liveGraph=Run.State.Graph
LOD.CombatRolls.RollPlayerWeapon=function(...)
 local rolled=baseRoll(...);Run.State.Graph={Cells=liveGraph.Cells};return rolled
end
assert(not F:FireWeapon(e,target,'weapon_pistol') and not e.lastBullet,'Retired roll reached native fire')
Run.State.Graph=liveGraph;LOD.CombatRolls.RollPlayerWeapon=baseRoll
-- Production ranged resolver copies the actual Pistol, not Soldier d10/d6.
e.LODFallenAim=Vector(1,0,0)
target.hp=1000;target.max=1000
assert(F:FireWeapon(e,target,'weapon_pistol'))
assert(e.playerAttacks==1,'copied firearm did not play a player attack gesture')
assert(r.weapons.weapon_pistol.clip==2 and target.lastInfo:GetDamage()>0)
local tags=Status:DamageContext(target.lastInfo,target)
assert(tags.actorDamageResolved and tags.damageContract.profile.sides==4)
assert(tags.damageContract.equipmentSnapshot.ownerIdentity=='hero')
-- Gear riders have a live copied owner, not an inventory-management exemption.
r.profile.equipmentExtras.proc_bleeding=35
local snapshot=E:CaptureAttack(e,'weapon_pistol')
assert(snapshot.extras.proc_bleeding==35 and snapshot.ownerIdentity=='hero')
r.weapons.weapon_pistol.clip=0
assert(F:FireWeapon(e,target,'weapon_pistol') and r.weapons.weapon_pistol.clip==8 and r.inventory.ammo[1]==0)
assert(r.nextAttack==now+1.5,'Reload did not use finite copied reserve')
-- Crowbar copies the real feat die instead of the ordinary Runner profile.
r.weapons.weapon_lod_crowbar={clip=0}
util.TraceHull=function() return {Entity=target,HitPos=target:WorldSpaceCenter()} end
assert(F:FireWeapon(e,target,'weapon_lod_crowbar'))
assert(Status:DamageContext(target.lastInfo,target).damageContract.profile.sides==12)
-- Shotgun shares one shell contract and consumes one round.
r.weapons.weapon_shotgun={clip=2,clipSize=6,ammoType=2}
assert(F:FireWeapon(e,target,'weapon_shotgun'))
assert(r.weapons.weapon_shotgun.clip==1 and e.lastBullet.Num>=9)
-- AR2 pays per burst, retains its burst-size/cadence authorities and fixed aim.
r.weapons.weapon_ar2={clip=2,clipSize=30,ammoType=3}
assert(F:FireWeapon(e,target,'weapon_ar2') and r.weapons.weapon_ar2.clip==1 and r.burst.remaining==3)
local beforeBurst=target.hp
for _=1,3 do now=now+.1;F:TickAI(e) end
assert(not r.burst and r.weapons.weapon_ar2.clip==1 and target.hp<beforeBurst)
-- Actual copied Beam and Content run the shared geometry, dice and Magic pool.
r.profile.magicFormIds={'beam'};r.profile.selectedMagicFormId='beam'
r.profile.contentIds={'fire'};r.profile.selectedMagicContentId='fire'
r.profile.magic=100;target.hp=1000
util.TraceLine=function(data)
 for _,ignored in ipairs(data.filter or {}) do
  if ignored==target then return {Hit=false,HitPos=data.endpos} end
 end
 return {Hit=true,HitPos=target:WorldSpaceCenter(),Entity=target}
end
local form,content=F:Spell(e)
local cost=Rules:OffensiveMagicCost(e,LOD.MagicForms:TotalBaseCost(form,content))
assert(F:Cast(e,target) and r.profile.magic==100-cost and target.hp<1000)
local context=LOD.MagicForms:_NewContext(e,form,content)
context.fallenHero=true;context.sourceValid=function() return F:Live(e) end
local projectile={LODCastContext=context}
assert(LOD.MagicForms:ProjectileContextValid(projectile))
Run.State.SimulationFrozen=true
assert(not LOD.MagicForms:ProjectileContextValid(projectile),'Paused copy projectile remained armed')
Run.State.SimulationFrozen=false
-- Uninterrupted AI warning commits once; status interruption cancels release.
r.nextAttack=0;r.attack=nil;r.profile.magic=100
now=106;F:TickAI(e);assert(r.attack and r.attack.at==now+.65)
local rounds=r.weapons.weapon_pistol.clip
now=106.7;F:TickAI(e);assert(not r.attack and r.attackSerial==1)
F:TickAI(e);assert(not r.attack,'Same-frame attack replayed')
-- Armor, pause and lifecycle gates are real production methods.
local d=DamageInfo();d:SetDamage(10);d:SetDamageType(DMG_BULLET)
F:AbsorbArmor(e,d);assert(math.abs(d:GetDamage()-2)<.001 and r.armor==8)
Run.State.SimulationFrozen=true;assert(not F:Live(e) and not F:FireWeapon(e,target,'weapon_pistol'))
F:Service();Run.State.SimulationFrozen=false;now=108;F:Service()
assert(F:Live(e))
local oldGraph=Run.State.Graph;Run.State.Graph={Cells=oldGraph.Cells}
assert(not F:Live(e),'Same-seed graph replacement kept old body live')
now=109;F:Service();assert(not IsValid(e) and #F.Records==0)
Run.State.Graph=oldGraph;p.valid=true
assert(F:Capture(p,p.ps));now=110;F:Service();local second=F.Records[1];e=second.entity
now=114;e.hp=0
local kill=DamageInfo();kill:SetAttacker(p)
assert(F:AcceptDeath(e,kill) and not F:AcceptDeath(e,kill),'Death receipt not single-use')
e.LODDead=true
assert(F:ResolveDeath(e) and F:ResolveDeath(e) and second.epitaph)
assert(LOD.CombatAttributionSystem:_Award('hero',999,e)==0)
assert(LOD.CombatAttributionSystem:Settle(e)==false)
assert(LOD.LootDirector:_SpawnEnemyResult(p,e,'weapon',LOD.RNG.New(1))==false)
assert(LOD.LootDirector:OnHostileLootHandoff(e)==nil)
F:Cleanup();assert(not IsValid(e) and #F.Records==0)
-- A human Soldier copies the disposable incarnation, never its dormant Hero.
p.LODRunSpawnSerial=3;p.soldier=true
local soldier=assert(LOD.SoldierProgression:CreateIncarnation(72,35,3))
soldier.magic=27;p.LODHumanSoldierProgressionState=soldier
p.weapons.weapon_ar2=w;p.weapons.weapon_pistol=nil
w.GetClass=function() return 'weapon_ar2' end;w.clip=0;p.activeClass='weapon_ar2'
local soldierOK,s=F:Capture(p,p.ps)
assert(soldierOK and s.soldierCopy and s.profile.actorType=='human_soldier' and s.profile.magic==27)
assert(s.profile~=soldier and s.profile.level==soldier.level and next(s.equipment.items)==nil)
now=115;F:Service();now=119
local bones=s.entity
assert(F:Weapon(bones)=='weapon_ar2' and F:FireWeapon(bones,target,'weapon_ar2'))
assert(s.weapons.weapon_ar2.clip==0 and s.burst.remaining>=3,'Soldier lost its authored infinite AR2')
local summon=env.actor('summon',false);summon.LODSummonedSeeker=true;summon.LODCaster=bones
assert(LOD.FactionManager:IsEnemyCombatant(summon) and LOD.FactionManager:IsOpponent(summon,target))
F:Cleanup();p.LODHumanSoldierProgressionState=nil;p.soldier=false
-- Staging and completed worlds cannot create a combat body.
p.staging=true;assert(not F:Capture(p,p.ps));p.staging=false
Run.State.LevelCleared=true;assert(not F:Capture(p,p.ps));Run.State.LevelCleared=false
print('FALLEN_HERO_PASS: detached Hero/Soldier builds, events-independent creation, safe deferred rise, Pistol/Crowbar/Shotgun/AR2/Beam, finite Hero ammo/armor/Magic, infinite Soldier rifle, hostile summons, duplicate death and stale graph rejection, pause/respawn/disconnect and no reward farming')
