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
CreateConVar('lod_developer_mode','1')
-- Engine-owned ConVars reject Lua setters. The old permissive mock hid a real
-- deployment-aborting exception; match the native API and command boundary.
vars.sv_hibernate_think={value=0,GetBool=function(self) return self.value~=0 end,
 SetBool=function() error('attempted to modify ConVar not created by Lua') end}
RunConsoleCommand=function(id,value)
 assert(id=='sv_hibernate_think' and (value=='0' or value=='1'))
 vars[id].value=tonumber(value)
end
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
 p.GetWeapons=function() return {} end;p.GetAmmo=function() return {} end;p.GetActiveWeapon=noop;p.Armor=function() return 0 end;p.Nick=function() return 'Hero' end
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
R.IsActivePlayer=function(_,p) return p==hero end
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
now=now+120;s.SimulationFrozen=true
R:BuildCurrentLevel();assert(T:Clock().deadline==deadline and T:Remaining(T:Clock(),now)==1680,'regeneration reset active clock')
T:Clock().warned={ [600]=true }
assert(R:CompleteLevel(hero) and rescued==1)
assert(not T:Clock().deadline and not T:Clock().warned and T:Remaining(T:Clock(),now)==1800)
assert(not vars.sv_hibernate_think:GetBool(),'rescue did not release hibernation override')
assert(not T:Start(hero),'intermission restarted clock')
assert(not R:CompleteLevel(hero),'duplicate rescue accepted')
now=now+4000;T:Step();assert(not s.Failed and T:Remaining(T:Clock(),now)==1800,'intermission consumed time')
assert(R:AdvanceLevel());hero.deployed=false
now=now+4000;T:Step();assert(not T:Start(hero) and not T:Clock().deadline,'return staging consumed time')
hero.deployed=true;assert(T:Start(hero));deadline=T:Clock().deadline
assert(deadline==now+1800 and not T:Start(hero),'next dungeon start not exactly once')
local beforeLateRescue=rescued
humans={};now=deadline;assert(not R:CompleteLevel(hero));assert(rescued==beforeLateRescue,'late rescue got rewards')
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
assert(not R:RestartFailedCampaign(hero),'manual restart skipped post-collapse wait')
now=scene.readyAt+4.99;assert(not R:RestartFailedCampaign(hero))
now=scene.readyAt+5;assert(R:RestartFailedCampaign(hero));assert(not R:RestartFailedCampaign(actor()),'second client duplicate restart accepted')
flush();assert(builds==oldBuilds+1 and R.State.Level==1 and not R.State.Failed)
assert(not T:Clock().deadline and not T:Clock().scene and not vars.sv_hibernate_think:GetBool())
for _,p in ipairs(oldScene.props) do assert(not IsValid(p),'wreckage leaked') end
assert(finalized==1)
-- Nobody presses E: a large tick gap and an empty server must still restart
-- once, through the same deferred campaign transaction, exactly after 20s.
T:Clock().deadline=now;T:Expire();T:Step();local automatic=T:Clock().scene
now=automatic.started+T.Settle
for _=1,13 do T:Step() end
assert(automatic.ready and automatic.readyAt==now)
humans={};local autoBuilds=builds
now=automatic.readyAt+19.99;T:Step();flush();assert(builds==autoBuilds)
now=automatic.readyAt+20;T:Step();T:Step();flush()
assert(builds==autoBuilds+1 and not R.State.Failed and not T:Clock().scene)
assert(not vars.sv_hibernate_think:GetBool(),'automatic restart leaked hibernation ownership')
humans={hero}
-- Shared transforms produce the same settled ruin after dropped frames/join.
local a,b=T:ContainerPose(Vector(10,20,900),Angle(),Vector(),4000,0,22,13)
local c,d=T:ContainerPose(Vector(10,20,900),Angle(),Vector(),4000,0,200,13)
assert(a.x==c.x and a.y==c.y and a.z==c.z and b.r==d.r)
-- Native-map camera contract: opposite Flattywood, oblique rather than
-- overhead, sign and prison inside the visible 4:3 letterboxed projection.
for _,radius in ipairs({5700,6500}) do
 local center=Vector(0,0,-11500);local camera=T:Camera(center,radius)
 local dx,dy,dz=camera.x-center.x,camera.y-center.y,camera.z-center.z
 local horizontal=math.sqrt(dx*dx+dy*dy)
 local pitch=math.atan(dz/horizontal)
 assert(math.abs(math.deg(pitch)-40)<.01 and dx>0)
 local sign=T.FlattywoodSign-center
 assert(dx*sign.x+dy*sign.y<0,'camera on same side as Flattywood')
 local forward=(center-camera);forward:Normalize()
 local right=Vector(-forward.y,forward.x,0);right:Normalize()
 local up=Vector(-forward.z*right.y,forward.z*right.x,forward.x*right.y-forward.y*right.x)
 local tanH=math.tan(math.rad(T.CameraFOV/2));local tanV=tanH/(4/3)
 local function project(p)
  local v=p-camera
  local depth=v.x*forward.x+v.y*forward.y+v.z*forward.z
  return (v.x*right.x+v.y*right.y+v.z*right.z)/(depth*tanH),
   .5-(v.x*up.x+v.y*up.y+v.z*up.z)/(depth*tanV)*.5
 end
 for _,z in ipairs({-8704,-3840}) do
  local x,y=project(Vector(T.FlattywoodSign.x,T.FlattywoodSign.y,z))
  assert(math.abs(x)<1 and y>.105 and y<.87,'Flattywood clipped by frame/letterbox')
 end
 for _,x in ipairs({-4032,4032}) do for _,y in ipairs({-4032,4032}) do
  local px,py=project(Vector(x,y,-12000))
  assert(math.abs(px)<1 and py>.105 and py<.87,'prison footprint clipped')
 end end
end
-- Replay real server serialization through the actual client receiver.
CLIENT=true;SERVER=false
assert(T.Settle>=5 and T.Settle<=7.5)
local positions={}
for _,at in ipairs({.6,2,3.3,4.8,6.8}) do
 local origin,focus,fov=T:CinematicView(Vector(0,0,-11500),4000,-12200,at,Vector(0,0,-12000))
 assert((origin-Vector(0,0,-12200)):Length()<4100,'Camera made prison distant')
 positions[#positions+1]=origin
 if at>5.5 then assert(focus==T.FlattywoodSign,'Final shot lost sign') end
end
for i=2,#positions do assert((positions[i]-positions[i-1]):Length()>100,'Repeated static cinematic composition') end
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
local clock=T:Clock();clock.scene.started=now-T.Settle;clock.scene.ready=true;clock.scene.readyAt=now
T:Sync();receive();assert(T:IsCinematic() and T:Elapsed()==T.Settle)
local view=hooks.CalcView.LOD_TimeoutCamera(nil,EyePos())
assert(view.fov>=80 and view.fov<=95 and view.zfar>(view.origin-T.FlattywoodSign):Length(),'camera clips distant Flattywood')
local beforeCinematicDraws=drawn
hooks.HUDPaint.LOD_TimeoutHUD();assert(drawn==beforeCinematicDraws+3)
local soundCount=sounds;now=now+1;T:Sync();receive();assert(sounds==soundCount,'snapshot replayed entrance audio')
local sent=0;net.SendToServer=function() sent=sent+1 end
down=true;hooks.Think.LOD_TimeoutRestartKey();assert(sent==0)
now=clock.scene.readyAt+5;T:Sync();receive();hooks.Think.LOD_TimeoutRestartKey();assert(sent==0,'held E skipped fresh press')
down=false;hooks.Think.LOD_TimeoutRestartKey();down=true;hooks.Think.LOD_TimeoutRestartKey()
assert(sent==1 and T.Client.scene.manualRemaining==0 and T.Client.scene.autoRemaining==15)
hooks.HUDPaint.LOD_TimeoutHUD();assert(drawCalls[#drawCalls].text:find('AUTO RESTART IN 15s',1,true))
R:NewCampaign();receive();assert(not T:IsCinematic() and hooks.HUDPaint.LOD_TestHUD==originalHUD)
print('PASS campaign timer layout, expiry race, empty-server reconnect, bounded collapse, idempotent canonical restart, cleanup, client transport and HUD restoration')
