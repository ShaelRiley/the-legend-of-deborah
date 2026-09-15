-- Exercise production timer, canonical failure/new-campaign/restart, and client
-- transport/absolute-time presentation with a deterministic engine boundary.
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local noop=function() end
SERVER=true;CLIENT=false;LOD={};GM={};FCVAR_ARCHIVE=0;OBS_MODE_FIXED=1;OBS_MODE_CHASE=2;NULL={}
local now,gameTime=100,100
SysTime=function() return now end;CurTime=function() return gameTime end;RealTime=SysTime
isstring=function(x) return type(x)=='string' end;istable=function(x) return type(x)=='table' end
IsValid=function(x) return type(x)=='table' and x.valid==true end
math.Clamp=function(x,a,b) return math.max(a,math.min(b,x)) end
local V={};V.__index=V
function Vector(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},V) end
V.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
V.__sub=function(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
V.__mul=function(a,b) return Vector(a.x*b,a.y*b,a.z*b) end
function V:Length() return math.sqrt(self.x^2+self.y^2+self.z^2) end
function V:Normalize() local l=math.max(1,self:Length());self.x=self.x/l;self.y=self.y/l;self.z=self.z/l end
function V:Angle() return Angle() end
Angle=function(p,y,r) return {p=p or 0,y=y or 0,r=r or 0} end
Color=function(r,g,b,a) return {r=r,g=g,b=b,a=a or 255} end
vector_origin=Vector();angle_zero=Angle()
local hooks,receivers,commands,queue={},{},{},{}
hook={Add=function(e,id,f) hooks[e]=hooks[e] or {};hooks[e][id]=f end,GetTable=function() return hooks end}
timer={Simple=function(_,f) queue[#queue+1]=f end}
local function flush() local q=queue;queue={};for _,f in ipairs(q) do f() end end
concommand={Add=function(id,f) commands[id]=f end}
local vars={}
function CreateConVar(id,default) local cv={value=tonumber(default) or 0};function cv:GetBool() return self.value~=0 end;function cv:GetInt() return self.value end;function cv:SetBool(v) self.value=v and 1 or 0 end;vars[id]=cv;return cv end
GetConVar=function(id) return vars[id] end
CreateConVar('lod_developer_mode','1');CreateConVar('sv_hibernate_think','0')
local packet,packets={},{}
local write=function(x) packet[#packet+1]=x end
net={Receive=function(id,f) receivers[id]=f end,Start=function(id) packet={};packets[id]=packet end,
 WriteUInt=write,WriteBool=write,WriteFloat=write,WriteVector=write,Send=noop,Broadcast=noop,SendToServer=noop}
util={AddNetworkString=noop,IsValidModel=function() return true end}
ErrorNoHalt=function(s) error(s) end
game={GetMap=function() return 'gm_flatgrass' end}
table.Count=function(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
local humans={}
player={GetAll=function() return humans end,GetHumans=function() return humans end}
ents={FindByClass=function() return {} end}
local function actor()
 local p={valid=true}
 function p:GetPos() return self.pos or Vector() end;function p:SetPos(v) self.pos=v end
 function p:IsPlayer() return true end;function p:IsAdmin() return true end;function p:Alive() return true end
 p.Spectate=noop;p.SpectateEntity=noop;p.StripWeapons=noop;p.ChatPrint=noop;p.SetNW2Float=noop
 function p:SteamID64() return tostring(self.id or 1) end;function p:EntIndex() return self.id or 1 end
 function p:Remove() self.valid=false end
 return p
end
dofile(root..'sh_config.lua');dofile(root..'sh_rng.lua');dofile(root..'sv_run_manager.lua')
local R=LOD.RunManager
local hero=actor();humans={hero}
local builds,finalized,rescued=0,0,0
LOD.HeroesOfLegend={SubmitRun=function() finalized=finalized+1 end}
LOD.ProgressionDirector={SyncAll=noop,Announce=noop}
LOD.MazeBuilder={Entities={},WorldFloorZ=0}
LOD.MazeNavigator={CellCenter=function(_,c) return Vector(c.x*384,c.y*384,c.z*384) end}
LOD.WallVisuals={Segments={}}
R._SyncPlayerVars=noop;R.RetireSoldier=noop
R.IsDungeonPlayer=function(_,p) return p==hero and p.deployed end
R.IsSoldierControl=function(_,p) return p.soldier==true end
R.BuildCurrentLevel=function(self) builds=builds+1;self.State.BuildReady=true;self.State.Graph={Cells={a={x=0,y=0,z=0},b={x=21,y=21,z=2}}};return true end
-- Preserve real CompleteLevel for the expiry race, but its side effects must
-- never execute once the deadline is reached.
local realComplete=R.CompleteLevel
R.CompleteLevel=function(self,...) rescued=rescued+1;return realComplete(self,...) end
dofile(root..'sv_campaign_restart.lua');dofile(root..'sh_campaign_timeout.lua');dofile(root..'sv_campaign_timeout.lua')
local T=LOD.CampaignTimeout
assert(R:NewCampaign());local s=R.State
s.PlayerState['1']={ordinal=1,characterName='Hero',lastPlayerName='Tester',lives=3};s.PlayedIdentities['1']=true
s.Ranked=true
now=100000;T:Step();assert(not T:Clock().deadline,'staging consumed time')
assert(not T:Start(hero));hero.deployed=true;hero.soldier=true;assert(not T:Start(hero));hero.soldier=false
assert(T:Start(hero));local deadline=T:Clock().deadline
assert(deadline==now+1800 and vars.sv_hibernate_think:GetBool())
assert(not T:Start(hero));assert(T:Clock().deadline==deadline)
now=now+120;s.LevelCleared=true;s.IntermissionEnd=gameTime+60;s.Level=7;s.SimulationFrozen=true
R:BuildCurrentLevel();assert(T:Clock().deadline==deadline and T:Remaining(T:Clock(),now)==1680,'level transition reset clock')
humans={};now=deadline;assert(not R:CompleteLevel(hero));assert(rescued==0,'late rescue got rewards')
assert(s.Failed and s.Finalized and finalized==1 and s.IntermissionEnd==nil)
T:Step();local scene=T:Clock().scene
assert(scene and not scene.started,'empty-server cinematic consumed without viewer')
assert(not R:RestartFailedCampaign(hero),'restart before scene')
T:Expire();T:Step();assert(finalized==1)
assert(not R:BuildCurrentLevel());assert(not R:AdvanceLevel());assert(not R:TryActivatePlayer(hero))
-- Production builds no more than the authored cap from a large manifest.
LOD.WallVisuals.Segments={}
for i=1,400 do LOD.WallVisuals.Segments[i]={i%21+1,math.floor(i/21)%21+1,0,1} end
humans={hero};T:Step();assert(scene.started==now and #scene.samples==T.PhysicsLimit)
assert(not T:BeginScene(scene) and #scene.samples==T.PhysicsLimit,'duplicate scene initialization')
local spawned=0
ents.Create=function()
 spawned=spawned+1;local e=actor();e.SetModel=noop;e.SetAngles=noop;e.Spawn=noop;e.SetMaterial=noop;e.SetColor=noop
 local phys={valid=true,SetMass=noop,EnableMotion=noop,SetVelocity=noop,AddAngleVelocity=noop,Wake=noop,Sleep=noop}
 e.GetPhysicsObject=function() return phys end;return e
end
for i=1,100 do scene.geometry[i]={ent=actor(),at=4} end
now=now+30;T:Step();assert(spawned==2 and scene.nextGeometry==97 and not scene.ready)
for _=1,12 do T:Step() end
assert(scene.ready and #scene.props==24 and spawned==24)
local oldScene=scene
local oldBuilds=builds
assert(R:RestartFailedCampaign(hero));assert(not R:RestartFailedCampaign(actor()),'second client duplicate restart accepted')
flush();assert(builds==oldBuilds+1 and R.State.Level==1 and not R.State.Failed)
assert(not T:Clock().deadline and not T:Clock().scene and not vars.sv_hibernate_think:GetBool())
for _,p in ipairs(oldScene.props) do assert(not IsValid(p),'wreckage leaked') end
assert(finalized==1)
-- Shared transforms produce the same settled ruin after dropped frames/join.
local a,b=T:ContainerPose(Vector(10,20,900),Angle(),Vector(),4000,0,22,13)
local c,d=T:ContainerPose(Vector(10,20,900),Angle(),Vector(),4000,0,200,13)
assert(a.x==c.x and a.y==c.y and a.z==c.z and b.r==d.r)
-- Replay real server serialization through the actual client receiver.
CLIENT=true;SERVER=false
local serverReceivers=receivers;receivers={}
local drawn,sounds,drawCalls=0,0,{}
surface={CreateFont=noop,PlaySound=function() sounds=sounds+1 end,SetDrawColor=noop,DrawRect=noop}
Material=function(x) return x end;render={SetMaterial=noop,DrawSprite=noop}
local function recordDraw(text,font,x,y,_,alignX,alignY)
 drawn=drawn+1;drawCalls[#drawCalls+1]={text=text,font=font,x=x,y=y,alignX=alignX,alignY=alignY}
end
draw={SimpleText=recordDraw,SimpleTextOutlined=recordDraw}
ScrW=function() return 1920 end;ScrH=function() return 1080 end;EyePos=function() return Vector(0,0,300) end
LerpVector=function(f,a,b) return a+(b-a)*f end
TEXT_ALIGN_LEFT=0;TEXT_ALIGN_CENTER=1;TEXT_ALIGN_TOP=2;color_black=Color(0,0,0);color_white=Color(255,255,255)
KEY_E=18;local down=false;input={IsKeyDown=function() return down end};gui={IsGameUIVisible=function() return false end}
local originalHUD=function() return 42 end
hook.Add('HUDPaint','LOD_TestHUD',originalHUD)
LOD.CharacterSheet={Close=noop};LOD.UI={SelectPage=noop}
dofile(root..'cl_campaign_timeout.lua')
local readIndex=0
local function read() readIndex=readIndex+1;return packet[readIndex] end
net.ReadUInt=read;net.ReadBool=read;net.ReadFloat=read;net.ReadVector=read
local function receive() readIndex=0;receivers[T.Message]() end
T:Sync();receive();assert(not T:IsCinematic());assert(hooks.HUDPaint.LOD_TestHUD()==42)
hooks.HUDPaint.LOD_TimeoutHUD()
local timerDraw=drawCalls[#drawCalls]
assert(timerDraw.text=='30:00  •  AWAITING FIRST HERO' and timerDraw.x==22 and timerDraw.y==72,
 'campaign clock has a dedicated row below the upper-left run/card block')
assert(timerDraw.alignX==TEXT_ALIGN_LEFT and timerDraw.alignY==TEXT_ALIGN_TOP,
 'campaign clock grows rightward without occupying the objective anchor')
T:Clock().deadline=now;T:Expire();T:Sync();receive();assert(T:IsCinematic() and hooks.HUDPaint.LOD_TestHUD()==nil)
local clock=T:Clock();clock.scene.started=now-22;clock.scene.ready=true
T:Sync();receive();assert(T:IsCinematic() and T:Elapsed()==22)
local beforeCinematicDraws=drawn
hooks.HUDPaint.LOD_TimeoutHUD();assert(drawn==beforeCinematicDraws+2)
local soundCount=sounds;now=now+1;T:Sync();receive();assert(sounds==soundCount,'snapshot replayed entrance audio')
R:NewCampaign();receive();assert(not T:IsCinematic() and hooks.HUDPaint.LOD_TestHUD==originalHUD)
print('PASS campaign timer layout, expiry race, empty-server reconnect, bounded collapse, idempotent canonical restart, cleanup, client transport and HUD restoration')
