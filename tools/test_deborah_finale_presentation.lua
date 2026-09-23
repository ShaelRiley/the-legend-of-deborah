-- Production finale receiver, camera/HUD, model rendering and cleanup. Explicit
-- supported Source API doubles expose resource leaks and incompatible calls.
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local now,reduced,created,live,draws,sounds,bursts=100,false,0,0,0,0,0
local hooks,receivers,queue,labels,callbacks={},{},{},{},{}
local failModel,failSetup,failDraw,failTrace=false,false,false,false
local noop=function() end
function CurTime() return now end
function FrameTime() return 1/60 end
function IsValid(e) return type(e)=='table' and not e.removed end
function isstring(v) return type(v)=='string' end
function Color(r,g,b,a) return {r=r,g=g,b=b,a=a or 255} end
function HSVToColor() return Color(100,150,200) end
local vec={};vec.__index=vec
function Vector(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},vec) end
function vec.__add(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
function vec.__sub(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
function vec.__mul(a,b) return Vector(a.x*b,a.y*b,a.z*b) end
function vec:Length() return math.sqrt(self.x^2+self.y^2+self.z^2) end
function vec:GetNormalized() local n=self:Length();return n>0 and self*(1/n) or Vector() end
function Angle(p,y,r) return {p=p or 0,y=y or 0,r=r or 0,
 Forward=function(self) return Vector(math.cos(math.rad(self.y)),math.sin(math.rad(self.y)),0) end,
 Right=function(self) return Vector(-math.sin(math.rad(self.y)),math.cos(math.rad(self.y)),0) end} end
function vec:Angle() return Angle(0,0,0) end
vector_origin=Vector()
math.Clamp=function(x,a,b) return math.max(a,math.min(x,b)) end
math.Rand=function(a,b) return (a+b)/2 end
function Lerp(t,a,b) return a+(b-a)*t end
function LerpVector(t,a,b) return a+(b-a)*t end
function ScrW() return 1280 end
function ScrH() return 720 end
TEXT_ALIGN_CENTER,TEXT_ALIGN_TOP,RENDERGROUP_OPAQUE,MASK_SOLID=1,2,0,1
hook={Add=function(_,id,fn) hooks[id]=fn end}
local function read() assert(#queue>0,'read past finale snapshot');return table.remove(queue,1) end
net={Receive=function(id,fn) receivers[id]=fn end,ReadBool=read,ReadEntity=read,ReadVector=read,ReadFloat=read,ReadUInt=read,ReadString=read}
surface={CreateFont=noop,PlaySound=function() sounds=sounds+1 end}
draw={SimpleText=function(s) labels[#labels+1]=s end,RoundedBox=noop}
file={Exists=function() return true end}
concommand={Add=noop};timer={Simple=function(_,fn) callbacks[#callbacks+1]=fn end}
local errors=0
function ErrorNoHalt() errors=errors+1 end
util={IsValidModel=function() return true end,TraceHull=function(t) if failTrace then error('injected camera trace failure') end;return {HitPos=t.endpos,Hit=false} end}
function ParticleEmitter() bursts=bursts+1;return {Add=function() return nil end,Finish=noop} end
local all={}
function ClientsideModel(model)
 if failModel then return nil end
 created=created+1;live=live+1
 local e={model=model}
 for _,k in ipairs({'SetNoDraw','DrawShadow','SetColor','SetRenderMode','SetModelScale','SetSkin','ResetSequence','SetCycle','SetPlaybackRate','FrameAdvance','SetBodygroup'}) do e[k]=noop end
 function e:LookupSequence() return 1 end
 function e:LookupBone() return nil end
 function e:ManipulateBoneAngles() end
 function e:SetPos(p) self.pos=p end
 function e:SetAngles(a) self.angles=a end
 function e:SetupBones() if failSetup then error('injected model setup error') end end
 function e:DrawModel() draws=draws+1;if failDraw then error('injected model draw error') end end
 function e:Remove() assert(not self.removed,'double remove');self.removed=true;live=live-1 end
 all[#all+1]=e;return e
end
local ply={alive=true,LODRunSpawnSerial=1,Alive=function(self) return self.alive end,GetPos=function() return Vector() end,
 GetNW2Float=function(_,_,d) return d end,GetNW2Int=function(_,_,d) return d end,GetModel=function() return 'models/player/group01/male_01.mdl' end}
function LocalPlayer() return ply end
LOD={Config={Models={Deborah='models/alyx.mdl'}},AdventurePresentation={Reduced=function() return reduced end,Play=function() sounds=sounds+1 end}}
dofile(root..'sh_rng.lua');dofile(root..'sh_damsels.lua')
dofile(root..'cl_victory_celebration.lua')
local C=LOD.VictoryCelebrationClient
local serial,started,ends=1,100,106.5
local hero={Alive=function() return true end,GetNW2Bool=function(_,_,default) return default end}
local previousOverride=function() end
local deborah={RenderOverride=previousOverride}
local function packet(options)
 options=options or {}
 local count=options.heroes or 2
 queue={true,options.opening==true,options.serial or serial,options.started or started,options.ends or ends,Vector(10,20,30),90,41,deborah,count}
 for i=1,count do
  queue[#queue+1]=hero;queue[#queue+1]='hero-'..i;queue[#queue+1]='Hero '..i
  queue[#queue+1]='models/player/group01/male_01.mdl';queue[#queue+1]=options.present~=false
 end
 local damsels=options.damsels or 19;queue[#queue+1]=damsels
 for i=1,damsels do queue[#queue+1]=i end
 receivers.LOD_DeborahFinale();assert(#queue==0,'incomplete finale snapshot read')
end
local function inactive()
 hooks.LOD_DeborahFinaleClientLifecycle()
 assert(not C:FinaleActive(),'finale remained active')
 assert(live==0,'finale models leaked')
 assert(deborah.RenderOverride==previousOverride,'real Deborah render override leaked')
 labels={};hooks.LOD_VictoryCelebrationHUD();assert(#labels==0,'finale HUD leaked')
 assert(not hooks.LOD_VictoryCelebrationThirdPerson(ply,Vector(),Angle(),90),'finale camera leaked')
end
local function fresh(options)
 serial=serial+1;now=now+10;started=now;ends=now+6.5;ply.alive=true
 packet(options);assert(C:FinaleActive())
end
packet({opening=true});assert(C:FinaleActive())
local initialSounds=sounds
local function world()
 assert(hooks.LOD_DeborahFinaleTableau,'production finale world hook missing')
 hooks.LOD_DeborahFinaleTableau(false,false)
end
world();assert(live==22,'expected Deborah, nineteen rescued damsels and two accepted Heroes')
local initialCreated=created
for i=1,3 do now=now+.2;packet();world() end
assert(live==22 and created==initialCreated and sounds==initialSounds,'sync replayed models or cues')
local view=hooks.LOD_VictoryCelebrationThirdPerson(ply,Vector(),Angle(),90)
assert(view and view.origin and view.angles,'finale camera not installed')
labels={};hooks.LOD_VictoryCelebrationHUD();assert(#labels>0,'finale titles missing')
-- Server roster presence updates remove only absent Hero proxies; they do not
-- rewrite the accepted cast or restart the choreography.
packet({present=false});local beforeDraws=draws;world();assert(draws-beforeDraws==20,'absent Hero proxies drawn')
local startedSnapshot=C.finale.startedAt
packet();world();assert(live==22 and C.finale.startedAt==startedSnapshot)
-- Snapshot lease retirement drops render overrides/camera/HUD even if a server
-- teardown packet is lost. A later copy of the retired serial cannot restart it.
now=now+.76;assert(not C:FinaleActive());inactive()
local counts={created,sounds};packet();inactive();assert(created==counts[1] and sounds==counts[2])
-- Joining halfway through starts at the server's existing time and never plays
-- the beginning again. Zero Heroes remains a valid damsel celebration snapshot.
fresh({started=now+7,ends=now+13.5,heroes=0});world()
assert(live==20 and sounds==counts[2],'late join replayed opening cues')
C:DisposeFinale();inactive()
-- Low effects retains the readable title with the ordinary view and no actors.
reduced=true;fresh();world();assert(live==0)
assert(not hooks.LOD_VictoryCelebrationThirdPerson(ply,Vector(),Angle(),90))
now=now+.3;labels={};hooks.LOD_VictoryCelebrationHUD();assert(#labels>0)
C:DisposeFinale();reduced=false
-- Local death suspends visuals immediately, then revival may observe only the
-- existing elapsed phase; the server still permanently retires that Hero slot.
fresh();world();local savedStart=C.finale.startedAt
ply.alive=false;assert(not C:FinaleActive());inactive()
ply.alive=true;counts={created,sounds};now=now+.5;packet({present=false})
hooks.LOD_DeborahFinaleClientLifecycle();world()
assert(C:FinaleActive() and C.finale.startedAt==savedStart and sounds==counts[2],
 'revival restarted finale timing or opening cues')
C:DisposeFinale();inactive()
-- PlayerInitialSpawn can receive the server snapshot before the local player is
-- valid/alive. Becoming available half a second later must preserve the scene.
for _,initial in ipairs({'dead','invalid'}) do
 serial=serial+1;now=now+10;started=now;ends=now+6.5
 if initial=='dead' then ply.alive=false else ply.removed=true end
 counts={created,sounds};packet({opening=false});inactive()
 assert(C.finale and C.finale.serial==serial,'initial spawn retired accepted snapshot')
 now=now+.5;ply.alive=true;ply.removed=nil;packet({opening=false})
 hooks.LOD_DeborahFinaleClientLifecycle();world()
 assert(C:FinaleActive() and live==22 and C.finale.startedAt==started and sounds==counts[2],
  'late local spawn lost current phase or replayed cues')
 C:DisposeFinale();inactive()
end
-- Cosmetic model creation or model-native errors restore ordinary rendering,
-- retaining the same text-only celebration and accepted timeline.
local function textFallback()
 assert(C:FinaleActive() and live==0 and deborah.RenderOverride==previousOverride,
  'cosmetic fault did not preserve text fallback and restore world actors')
 assert(not hooks.LOD_VictoryCelebrationThirdPerson(ply,Vector(),Angle(),90),'fault retained finale camera')
 labels={};hooks.LOD_VictoryCelebrationHUD();assert(#labels>0,'cosmetic fault suppressed finale title')
 local before=created;hooks.LOD_DeborahFinaleClientLifecycle();world()
 assert(created==before and live==0,'fault retried native models every frame')
end
failModel=true;fresh();world();assert(live==0);C:DisposeFinale();failModel=false;inactive()
fresh();failSetup=true;world();failSetup=false;textFallback();C:DisposeFinale();inactive()
fresh();failDraw=true;world();failDraw=false;textFallback();C:DisposeFinale();inactive()
fresh();world();failTrace=true
assert(not hooks.LOD_VictoryCelebrationThirdPerson(ply,Vector(),Angle(),90))
failTrace=false;textFallback();C:DisposeFinale();inactive()
-- Packet bounds include malformed count fields: four Heroes and nineteen unique
-- rescued damsels, plus Deborah, are the absolute native model maximum.
fresh({heroes=7,damsels=31});world();assert(live==24,'snapshot exceeded 24-model bound')
C:DisposeFinale();inactive()
-- A model lost after successful creation restores the real rescue actor.
fresh();world();C.finaleModels.deborah:Remove();hooks.LOD_DeborahFinaleClientLifecycle()
assert(live==0 and deborah.RenderOverride==previousOverride,'removed proxy left real Deborah hidden')
C:DisposeFinale();inactive()
-- Tetris, progression updates and the existing timeout scene all release the
-- view immediately and cannot be overwritten by another same-serial snapshot.
for _,reason in ipairs({'tetris','failure','nextlevel','timeout'}) do
 fresh();world()
 if reason=='tetris' then LOD.IntermissionTetrisClient={active=true}
 elseif reason=='failure' then LOD.ClientState={synchronized=true,level=20,levelCleared=true,failed=true}
 elseif reason=='nextlevel' then LOD.ClientState={synchronized=true,level=21,levelCleared=false}
 else LOD.CampaignTimeout={IsCinematic=function() return true end} end
 inactive()
 LOD.IntermissionTetrisClient=nil;LOD.ClientState=nil;LOD.CampaignTimeout=nil
 packet();inactive()
end
-- A just-connected recipient at the opening timestamp still has opening=false.
counts={created,sounds};fresh({started=now+9.99,ends=now+16.49,opening=false});world()
assert(sounds==counts[2],'immediate late join replayed opening cue')
C:DisposeFinale();inactive()
-- Teardown is idempotent, and delayed ordinary celebration callbacks are unable
-- to revive a retired finale or restore a stale camera.
fresh();world();hooks.LOD_VictoryPresentationReset();inactive()
for _,fn in ipairs(callbacks) do fn() end
inactive();C:DisposeFinale();inactive()
fresh();world();hooks.LOD_DeborahFinaleShutdown();inactive()
fresh();world();dofile(root..'cl_victory_celebration.lua');inactive()
print('DEBORAH_FINALE_CLIENT_PASS: bounded canonical tableau, nonreplaying snapshots, original server timing/late joins, missing actors, partial model faults, reduced effects, death/revival, freshness expiry, reset/hot reload, camera/HUD/resource restoration')
