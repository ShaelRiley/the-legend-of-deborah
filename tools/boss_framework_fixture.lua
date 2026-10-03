-- Production integration fixture: only GMod engine services are emulated.
-- All BossEncounter methods, modules, progression, rolls, variance, movement,
-- status life binding, native OnKilled and object dispatch are loaded unchanged.
local F={root='gamemodes/legend_of_deborah/gamemode/lod/',clock=100,created={},players={},packets={},logs={},hooks={},queued={},damage={}}
local noop=function() end
SERVER,CLIENT=true,false;GM={};LOD={};NULL={valid=false};unpack=unpack or table.unpack
function CurTime() return F.clock end
SysTime,RealTime=CurTime,CurTime
function IsValid(v) return type(v)=='table' and v.valid==true end
function isnumber(v) return type(v)=='number' end
function isstring(v) return type(v)=='string' end
function istable(v) return type(v)=='table' end
function isfunction(v) return type(v)=='function' end
function Color(r,g,b,a) return {r=r,g=g,b=b,a=a or 255} end
function math.Clamp(v,a,b) return math.max(a,math.min(b,v)) end
function math.Round(n) return math.floor(n+.5) end
function math.AngleDifference(a,b) return (a-b+180)%360-180 end
function math.Approach(a,b,n) return a<b and math.min(a+n,b) or math.max(a-n,b) end
function table.Copy(t,seen)
 if type(t)~='table' then return t end
 if t.valid~=nil then return t end -- engine Entity userdata has identity, never deep-copied
 seen=seen or {};if seen[t] then return seen[t] end
 local r=setmetatable({},getmetatable(t));seen[t]=r;for k,v in pairs(t) do r[table.Copy(k,seen)]=table.Copy(v,seen) end;return r
end
function table.Count(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
function table.HasValue(t,v) for _,x in pairs(t) do if x==v then return true end end;return false end
function string.Trim(s) return s:match('^%s*(.-)%s*$') end
local V={};V.__index=V
function Vector(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},V) end
V.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
V.__sub=function(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
V.__unm=function(a) return Vector(-a.x,-a.y,-a.z) end
V.__mul=function(a,b) if type(a)=='number' then a,b=b,a end;return Vector(a.x*b,a.y*b,a.z*b) end
V.__div=function(a,b) return a*(1/b) end
function V:LengthSqr() return self.x*self.x+self.y*self.y+self.z*self.z end
function V:Length() return math.sqrt(self:LengthSqr()) end
function V:Length2D() return math.sqrt(self.x*self.x+self.y*self.y) end
function V:DistToSqr(b) return (self-b):LengthSqr() end
function V:Distance(b) return math.sqrt(self:DistToSqr(b)) end
function V:GetNormalized() local n=self:Length();return n>0 and self/n or Vector() end
function V:Normalize() local n=self:GetNormalized();self.x,self.y,self.z=n.x,n.y,n.z end
function V:Dot(b) return self.x*b.x+self.y*b.y+self.z*b.z end
function V:Cross(b) return Vector(self.y*b.z-self.z*b.y,self.z*b.x-self.x*b.z,self.x*b.y-self.y*b.x) end
local A={};A.__index=A
function Angle(p,y,r) return setmetatable({p=p or 0,y=y or 0,r=r or 0},A) end
function A:Forward() local y=math.rad(self.y);return Vector(math.cos(y),math.sin(y),0) end
function A:Right() local y=math.rad(self.y);return Vector(-math.sin(y),math.cos(y),0) end
function A:Up() return Vector(0,0,1) end
function V:Angle() return Angle(0,math.deg(math.atan(self.y,self.x)),0) end
vector_origin=Vector();angle_zero=Angle()
for i,name in ipairs({'ACT_RUN','ACT_WALK','ACT_IDLE_ANGRY','ACT_IDLE','ACT_DIESIMPLE','ACT_RUN_AIM_RIFLE','ACT_FLY','ACT_RANGE_ATTACK1','ACT_IDLE_ANGRY_SMG1','MASK_SHOT','MASK_NPCSOLID','MASK_SOLID','MOVETYPE_NONE','SOLID_NONE','SOLID_BBOX','COLLISION_GROUP_NONE','COLLISION_GROUP_PROJECTILE','COLLISION_GROUP_DEBRIS','DMG_GENERIC','DMG_BULLET','DMG_CLUB','DMG_SLASH','DMG_BLAST','DMG_ENERGYBEAM','DMG_BURN','DMG_POISON','DMG_FALL','DMG_CRUSH','DMG_BUCKSHOT','IN_USE','IN_ATTACK','IN_DUCK','IN_JUMP'}) do _G[name]=2^(i%25) end
DMG_SONIC=2^30;MASK_PLAYERSOLID=7;COLLISION_GROUP_NPC=9;EF_BONEMERGE=1;EFL_FORCE_CHECK_TRANSMIT=1;TRANSMIT_ALWAYS=2
local function bitop(a,b,which) local n,p=0,1;while a>0 or b>0 do local x,y=a%2,b%2;if which(x,y) then n=n+p end;a,b,p=math.floor(a/2),math.floor(b/2),p*2 end;return n end
bit={band=function(a,b) return bitop(a,b,function(x,y) return x==1 and y==1 end) end,bor=function(a,b) return bitop(a,b,function(x,y) return x==1 or y==1 end) end}
function AddCSLuaFile() end
function include() end
function DeriveGamemode() end
function ErrorNoHalt(s) F.logs[#F.logs+1]={error=s} end
function CreateConVar(_,default) return {GetBool=function() return default=='1' end,GetInt=function() return tonumber(default) or 0 end,GetFloat=function() return tonumber(default) or 0 end,GetString=function() return default end} end
function GetConVar() return CreateConVar('', '1') end
concommand={Add=noop};scripted_ents={GetStored=function() return F.nativeClass and {t=F.nativeClass} end}
hook={Add=function(event,id,fn) F.hooks[event]=F.hooks[event] or {};F.hooks[event][id]=fn end,Remove=function(event,id) if F.hooks[event] then F.hooks[event][id]=nil end end}
function hook.Run(event,...) local order={};for id in pairs(F.hooks[event] or {}) do order[#order+1]=id end;table.sort(order);for _,id in ipairs(order) do local r=F.hooks[event][id](...);if r~=nil then return r end end end
function hook.GetTable() return F.hooks end
timer={Simple=function(delay,fn) F.queued[#F.queued+1]={at=F.clock+delay,fn=fn} end,Create=noop,Remove=noop,Exists=function() return false end}
local packet
net={Start=function(id) packet={id=id,values={}};F.packets[#F.packets+1]=packet end,Receive=noop,Broadcast=noop,Send=noop}
for _,k in ipairs({'WriteBool','WriteUInt','WriteInt','WriteFloat','WriteDouble','WriteVector','WriteEntity','WriteString','WriteData','WriteTable','WriteAngle'}) do net[k]=function(v) if packet then packet.values[#packet.values+1]=v end end end
function F.clearTrace(t) return {Hit=false,HitPos=t.endpos,Fraction=1,StartSolid=false,AllSolid=false,Entity=NULL} end
util={AddNetworkString=noop,TraceLine=F.clearTrace,TraceHull=F.clearTrace,Effect=noop,IsValidModel=function() return true end,IsValidProp=function() return true end,TableToJSON=function() return '{}' end,Compress=function(s) return s end}
sound={Play=noop};game={GetWorld=function() return NULL end,GetMap=function() return 'boss_fixture' end};player={GetAll=function() return F.players end,GetHumans=function() return F.players end}
function EffectData() return {SetOrigin=noop,SetNormal=noop,SetScale=noop,SetMagnitude=noop} end
function DamageInfo()
 local d={amount=0,force=Vector(),position=Vector(),kind=DMG_GENERIC}
 for _,q in ipairs({'Attacker','Inflictor','Damage','DamageType','DamagePosition','DamageForce'}) do local k=({Damage='amount',DamageType='kind',DamagePosition='position',DamageForce='force'})[q] or q:lower();d['Get'..q]=function(self) return self[k] end;d['Set'..q]=function(self,v) self[k]=v end end
 function d:ScaleDamage(s) self.amount=self.amount*s end
 function d:IsDamageType(k) return bit.band(self.kind,k)~=0 end
 return d
end
local function load(name) return dofile(F.root..name..'.lua') end
load('sh_config');load('sv_m3_enemy_config');load('sh_rng');load('sh_die_logger');load('sh_rpg_schema');load('sh_damsels')
load('sv_run_manager');load('sv_maze_generator');load('sv_maze_navigator')
LOD.MazeBuilder={CellCenter=function(_,c) local m=LOD.Config.Maze;return Vector((c.x-(m.Width+1)*.5)*m.CellSize+m.Origin.x,(c.y-(m.Height+1)*.5)*m.CellSize+m.Origin.y,c.z*m.LevelHeight+m.Origin.z) end,_Register=noop,_BuildProgressionEntities=noop,Cleanup=noop}
LOD.CombatRolls={HostileDamageProfiles={}}
load('sv_progression_director');load('sv_neil_brute');load('sv_warden_arena')
load('sv_damage_info');load('sv_rpg_gate_b_catalog');load('sv_rpg_gate_c_catalog');load('sv_snapshot_delivery');load('sv_combat_rolls');load('sv_combat_feed_semantics');load('sv_character_progression')
load('sv_rpg_gate_d');load('sv_rpg_status_elements');load('sv_rpg_gate_e_feats');load('sv_rpg_gate_e_rate_of_fire');load('sv_rpg_dodge')
load('sh_equipment');load('sh_equipment_catalog');load('sv_rpg_block');load('sv_faction_manager');load('sv_encounter_director');load('sv_loot_director')
load('sv_wandering_director');load('sv_warden');load('sv_enemy_roster');load('sv_enemy_crossfire');load('sv_enemy_variance');load('sv_hostile_motion_v2');load('sv_warden_turrets');load('sv_hector')
load('sv_pushback');load('sv_rpg_gate_e_pusher');load('sv_magic');load('sv_magic_progression');load('sv_magic_forms')
LOD.RPGTestLog={Write=function(_,event,data) F.logs[#F.logs+1]={event=event,data=data} end}
LOD.Audio={Emit=noop,At=noop,ToPlayer=noop}
local nativeObject,nativeStatic
function F.actor(class)
 assert(not F.insideDeath,'native entity creation inside lethal callback')
 if class=='lod_hostile' then F.hostileAttempts=(F.hostileAttempts or 0)+1;if F.failHostileAt==F.hostileAttempts then return NULL end end
 if F.failClass==class then return NULL end
 local e={valid=true,class=class or 'lod_hostile',index=#F.created+1,pos=Vector(),angles=Angle(),nw={},hp=100,maximum=100,alive=true,model='models/player/group01/male_01.mdl',color=Color(255,255,255),LODActivated=true}
 function e:GetPos() return Vector(self.pos.x,self.pos.y,self.pos.z) end
 function e:SetPos(p) assert(not F.insideDeath,'native SetPos inside lethal callback');self.pos=Vector(p.x,p.y,p.z) end
 function e:GetClass() return self.class end
 function e:WorldSpaceCenter() return self:GetPos()+Vector(0,0,36) end
 function e:NearestPoint() return self:GetPos() end
 function e:SetNW2Bool(k,v) if F.failNWKey==k then error('injected native network setter failure') end;self.nw[k]=v end
 function e:GetNW2Bool(k,d) local v=self.nw[k];if v==nil then return d end;return v end
 for _,k in ipairs({'String','Int','Float','Vector','Entity'}) do e['SetNW2'..k]=e.SetNW2Bool;e['GetNW2'..k]=e.GetNW2Bool end
 function e:EntIndex() return self.index end
 function e:IsPlayer() return self.class=='player' end
 function e:IsNPC() return self.class=='lod_hostile' end
 function e:IsNextBot() return self.class=='lod_hostile' end
 function e:IsAdmin() return true end
 function e:Alive() return self.alive and self.hp>0 end
 function e:Health() return self.hp end
 function e:SetHealth(v) self.hp=v end
 function e:GetMaxHealth() return self.maximum end
 function e:SetMaxHealth(v) self.maximum=v end
 function e:GetAngles() return self.angles end
 function e:SetAngles(v) self.angles=v end
 function e:GetForward() return self.angles:Forward() end
 function e:GetRight() return self.angles:Right() end
 function e:GetUp() return Vector(0,0,1) end
 function e:SetModel(m) self.model=m end
 function e:GetModel() return self.model end
 function e:SetColor(c) self.color=c end
 function e:GetColor() return self.color end
 function e:GetParent() return NULL end
 function e:GetOwner() return self.owner or NULL end
 function e:SetKeySource(s) self.source=s end
 function e:GetVelocity() return self.velocity or Vector() end
 function e:SetVelocity(v) self.velocity=v end
 function e:SetOpened(v) assert(not F.insideDeath,'native gate mutation inside lethal callback');self.opened=v end
 function e:OpenGate() self:SetOpened(true) end
 function e:OpenDoor() self:SetOpened(true) end
 function e:SetNoDraw(v) self.noDraw=v end
 function e:GetNoDraw() return self.noDraw end
 function e:Remove() assert(not F.insideDeath,'native entity removal inside lethal callback');self.valid=false end
 function e:SteamID64() return self.id or '0' end
 function e:Nick() return self.id or 'fixture' end
 function e:Armor() return self.armor or 0 end
 function e:SetArmor(n) self.armor=n end
 function e:LookupSequence() return -1 end
 function e:KeyDown(k) return self.keys and self.keys[k] or false end
 function e:GetWeapons() return {} end
 function e:GetAmmo() return {} end
 function e:GetShootPos() return self:WorldSpaceCenter() end
 function e:EyePos() return self:WorldSpaceCenter() end
 function e:GetAimVector() return self.aim or self:GetForward() end
 function e:GetActiveWeapon() return NULL end
 function e:OnGround() return true end
 function e:GetMoveType() return MOVETYPE_NONE end
 for _,n in ipairs({'SetModelScale','SetCollisionBounds','SetSolid','SetNotSolid','SetMoveType','SetCollisionGroup','SetUseType','DrawShadow','SetPlaybackRate','SetCycle','ResetSequence','EmitSound','StopSound','NextThink','Activate','ChatPrint','SetBloodColor','SetRenderMode','StartActivity','AddEffects','SetSolidFlags','AddEFlags','ConCommand','Freeze','SetEyeAngles'}) do e[n]=noop end
 function e:SetOwner(owner) self.owner=owner end
 function e:SetParent(parent) self.parent=parent end
 function e:Spawn()
  assert(not F.insideDeath,'native Spawn inside lethal callback')
  if F.failHostileSpawn and self.class=='lod_hostile' then error('injected native Spawn failure') end
  if self.class=='lod_hostile' then setmetatable(self,{__index=F.nativeClass});self:Initialize()
  elseif self.class=='lod_static_box' then setmetatable(self,{__index=nativeStatic});self:Initialize()
  elseif self.class=='lod_boss_object' then setmetatable(self,{__index=nativeObject});if self.Initialize then self:Initialize() end end
 end
 function e:TakeDamageInfo(info)
  if self.LODBossObject then return self:OnTakeDamage(info) end
  if GM.EntityTakeDamage and GM:EntityTakeDamage(self,info)==true then return end
  local amount=math.max(0,info:GetDamage());self.hp=math.max(0,self.hp-amount);F.damage[#F.damage+1]={target=self,amount=amount,source=info:GetAttacker(),kind=info:GetDamageType()}
  if self.hp<=0 and self.OnKilled then local old=F.insideDeath;F.insideDeath=true;local ok,err=pcall(self.OnKilled,self,info);F.insideDeath=old;if not ok then error(err) end end
  hook.Run('PostEntityTakeDamage',self,info,amount>0);if GM.PostEntityTakeDamage then GM:PostEntityTakeDamage(self,info,amount>0) end
 end
 function e:SetCollisionBounds(lo,hi) assert(not F.insideDeath,'native collision bounds mutation inside lethal callback');self.collisionMins=lo;self.collisionMaxs=hi end
 function e:SetSolid(v) assert(not F.insideDeath,'native solid mutation inside lethal callback');self.solid=v end
 function e:GetCollisionBounds() return self.collisionMins or Vector(-16,-16,0),self.collisionMaxs or Vector(16,16,72) end
 function e:NetworkVar(_,_,name) self['Get'..name]=function(self) return self['nv_'..name] end;self['Set'..name]=function(self,v) self['nv_'..name]=v end end
 if class=='lod_static_box' and nativeStatic then setmetatable(e,{__index=nativeStatic});e:SetupDataTables() end
 F.created[#F.created+1]=e;return e
end
ents={Create=F.actor,FindAlongRay=function() return {} end,FindByClass=function(class) local t={};for _,e in ipairs(F.created) do if IsValid(e) and e.class==class then t[#t+1]=e end end;return t end}
ENT={};dofile('gamemodes/legend_of_deborah/entities/entities/lod_hostile/init.lua');F.nativeClass=ENT
ENT={};local f=io.open('gamemodes/legend_of_deborah/entities/entities/lod_boss_object/init.lua');if f then f:close();dofile('gamemodes/legend_of_deborah/entities/entities/lod_boss_object/init.lua') end;nativeObject=ENT
ENT={};dofile('gamemodes/legend_of_deborah/entities/entities/lod_static_box/shared.lua');dofile('gamemodes/legend_of_deborah/entities/entities/lod_static_box/init.lua');nativeStatic=ENT
load('sh_boss_registry');load('sv_boss_encounter');load('sv_boss_hazards');load('sv_boss_arena')
F.missing={};for _,id in ipairs(LOD.BossRegistry.Modules) do local p=F.root..'bosses/sv_'..id..'.lua';local f=io.open(p);if f then f:close();dofile(p) else F.missing[#F.missing+1]=id end end
F.B,F.R,F.P,F.N=LOD.BossEncounter,LOD.RunManager,LOD.ProgressionDirector,LOD.MazeNavigator
function F.hero(id)
 local e=F.actor('player');e.id=id;e.LODRunSpawnSerial=1;e.hp=10000;e.maximum=10000
 local profile=LOD.CharacterProgressionSystem:NewProgressionState(id,'hero','hero');profile.baseAbilities=LOD.RPG.NewAbilityBlock(10);profile.startingHP=10000;profile.classId='fighter';LOD.CharacterProgressionSystem:_RecomputeProgressionState(profile)
 e.ps={identity=id,lives=3,deploymentComplete=true,deployedDungeonLevel=2,equipmentLifeSerial=1,progressionState=profile}
 F.players[#F.players+1]=e;return e
end
F.p=F.hero('hero-a');F.q=F.hero('hero-b')
function F.flush()
 local due,keep={},{};for _,q in ipairs(F.queued) do if q.at<=F.clock then due[#due+1]=q else keep[#keep+1]=q end end;F.queued=keep;for _,q in ipairs(due) do q.fn() end
end
function F.at(t,service) F.clock=t;if service then F.B:Service(t) end;F.flush() end
function F.step(seconds,quantum)
 local finish=F.clock+seconds;while F.clock<finish-.000001 do F.at(math.min(finish,F.clock+(quantum or .1)),true) end
end
function F.lookAt(p,pos) p.aim=(pos-p:EyePos()):GetNormalized() end
function F.info(source,amount,kind,pos,force)
 local d=DamageInfo();d:SetAttacker(source or F.p);d:SetInflictor(source or F.p);d:SetDamage(amount or 10);d:SetDamageType(kind or DMG_BULLET);d:SetDamagePosition(pos or Vector());d:SetDamageForce(force or Vector());return d
end
function F.kill(e)
 e:SetHealth(0);F.insideDeath=true;local ok,err=pcall(e.OnKilled,e,F.info(F.p,100000));F.insideDeath=false;if not ok then error(err) end
end
function F.errors() local t={};for _,q in ipairs(F.logs) do if q.data and q.data.error then t[#t+1]=q.data.error end end;return table.concat(t,' | ') end
function F.setup(level,commit)
 if F.R.State.Boss then F.B:Cleanup(F.R.State.Boss,'fixture_reset') end
 F.queued={};F.damage={};F.logs={};F.failClass=nil;F.failHostileSpawn=nil;F.failNWKey=nil;F.failHostileAt=nil;F.hostileAttempts=0;F.clock=F.clock+100;util.TraceHull=F.clearTrace;util.TraceLine=F.clearTrace
 LOD.EncounterDirector.Entities={};LOD.EnemyRoster.Projectiles={};LOD.HostileDeathPresentation.Pending={};LOD.HostileDeathPresentation.Active={}
 F.R.State={Level=level or 2,LevelSeed=12345,CampaignSeed=71,CampaignEpoch=3,RunId='boss:production:fixture',BuildReady=true,PlayerState={},ActiveIdentity={},PlayedIdentities={},Cards={},GatesOpen={},RescuedDamsels={}}
 local s=F.R.State
 for _,p in ipairs(F.players) do p.valid=true;p.alive=true;p.hp=p.maximum;p.LODDead=nil;p.LODRunSpawnSerial=p.LODRunSpawnSerial+1;p.ps.lives=3;p.ps.eliminated=false;p.ps.deploymentComplete=true;p.ps.deployedDungeonLevel=s.Level;p.aim=nil;p.keys={};LOD.RPGStatusElements:ResetActorLife(p);s.PlayerState[p.id]=p.ps;s.ActiveIdentity[p.id]=true;s.PlayedIdentities[p.id]=true end
 local graph,reason
 for seed=100,220 do local g=assert(LOD.MazeGenerator:Generate(seed));local ok,why=F.P:Plan(g,seed);if ok then graph=g;break end;reason=why end
 assert(graph,'production arena Plan: '..tostring(reason));s.Graph=graph;F.P:ResetLevelState(graph);s.BuildReady=true;s.GatesOpen={true,true,true,true};s.NeilHunt={started=true};s.RescueTarget=LOD.Damsels:Target(s.Level)
 local a=graph.Progression.Warden;a.lock.entity=F.actor('lod_gate');a.lock.entity:SetPos(F.N:CellCenter(a.entry));graph.Progression.JailEdge.entity=F.actor('lod_jail_door');s.RescueEntity=F.actor('lod_deborah')
 for i,p in ipairs(F.players) do p:SetPos(F.N:CellCenter(a.center)+Vector(160*i,0,2)) end
 if commit~=false then assert(F.B:Prepare(),'production Prepare rejected level '..s.Level);local ok=F.B:Commit(s.Boss);if not ok then for _,q in ipairs(F.logs) do if q.data and q.data.error then print('FIXTURE_MODULE_ERROR '..tostring(q.data.error)) end end end;assert(ok,'production Commit rejected '..tostring(s.Boss and s.Boss.id)) end
 return s,s.Boss,graph,a
end
return F
