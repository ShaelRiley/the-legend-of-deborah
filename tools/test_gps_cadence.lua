-- Exercise the production scheduler and actual async voice lifecycle.
local root='gamemodes/legend_of_deborah/gamemode/'
local now, tick, receivers, events=0,nil,{},{}
local function noop() end
function IsValid(e) return type(e)=='table' and e.valid~=false end
function CurTime() return now end
function Color() return {} end
function AddCSLuaFile() end
function include(path) return dofile(root..path) end
math.Clamp=function(v,a,b) return math.max(a,math.min(b,v)) end
math.NormalizeAngle=function(v) return (v+180)%360-180 end
local vec={};vec.__index=vec
local function V(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},vec) end
function vec:LengthSqr() return self.x^2+self.y^2+self.z^2 end
function vec:DistToSqr(v) return (self.x-v.x)^2+(self.y-v.y)^2+(self.z-v.z)^2 end
IN_ATTACK,IN_ATTACK2,OBS_MODE_NONE=1,2,0
local hero={pos=V(),velocity=V(),state={featIds={'WIS_GPS'}}}
function hero:IsPlayer() return true end
function hero:Alive() return not self.dead end
function hero:Health() return self.dead and 0 or 100 end
function hero:GetPos() return self.pos end
function hero:GetVelocity() return self.velocity end
function hero:EyeAngles() return {y=self.yaw or 0} end
function hero:KeyDown() return self.attack end
function hero:GetObserverMode() return self.observer or 0 end
function hero:GetNW2Bool() return self.staged or false end
local foes={}
player={GetHumans=function() return {hero} end}
util={AddNetworkString=noop};resource={AddFile=noop};concommand={Add=noop}
local packet
audio={}
net={Start=function(name) packet={name=name,values={}} end,WriteBool=function(v) table.insert(packet.values,v) end,
 WriteString=function(v) table.insert(packet.values,v) end,Send=function(p) assert(p==hero);events[#events+1]=packet end,
 Receive=function(k,f) receivers[k]=f end}
timer={Create=function(_,_,_,fn) tick=fn end}
local routeCalls=0
LOD={RPG={IdentityCatalog={OrdinaryFeats={}}},RPGAbilityRules={ProgressionState=function(_,p) return p.state end},
 RunManager={State={Graph={}},IsActivePlayer=function() return true end},
 FactionManager={Opponents=function() return foes end},
 MazeNavigator={WorldToCell=function(_,_,p) return {x=math.floor(p.x/100),y=math.floor(p.y/100),z=math.floor(p.z/100)} end,
 FindPath=function() routeCalls=routeCalls+1;if hero.noRoute then return nil end;return {{x=0,y=0,z=0},{x=1,y=0,z=0}} end},
 ProgressionDirector={GetObjectiveGraphTarget=function() return {a={x=1,y=0,z=0}} end}}
include('lod/sv_rpg_checkpoint_d_gps_feat.lua')
local function advance(t) now=t;tick() end
local function barks() local out={};for _,e in ipairs(events) do if e.name=='LOD_RPGWisGPSBark' and e.values[1]~='' then out[#out+1]=e.values[1] end end;return out end
advance(0);advance(.99);assert(#barks()==0)
advance(1);assert(#barks()==1)
local duration=LOD.GPSVoice.Duration('CONTINUE FORWARD')
advance(1+duration+3.99);assert(#barks()==1)
hero.yaw=180;advance(1+duration+4);assert(#barks()==2 and barks()[2]=='TURN AROUND')
foes={{GetPos=function() return V(200,200,0) end}};advance(7)
assert(events[#events].values[1]=='','nearby hidden enemy cancels speech')
advance(20);assert(#barks()==2)
foes={};advance(21);advance(21.99);assert(#barks()==2);advance(22);assert(#barks()==3)
hero.pos=V(5,0,0);advance(22.2);advance(22.4);advance(23.39);assert(#barks()==3);advance(23.4);assert(#barks()==4,'small displacement re-arms')
receivers.LOD_RPGWisGPSToggle(0,hero);advance(40);assert(#barks()==4)
receivers.LOD_RPGWisGPSToggle(0,hero);advance(41);advance(42);assert(#barks()==5)
hero.staged=true;advance(43);advance(60);assert(#barks()==5)
hero.staged=false;hero.dead=true;advance(61);assert(#barks()==5)
hero.dead=false;hero.attack=true;advance(62);advance(64);assert(#barks()==5)
hero.attack=false;hero.velocity=V(0,0,9);advance(65);assert(#barks()==5)
hero.velocity=V();foes={{GetPos=function() return V(0,0,100) end}};advance(66);advance(67);assert(#barks()==6,'other floor permits speech')
hero.noRoute=true;advance(80);local n=routeCalls;advance(80.2);advance(80.8);assert(routeCalls==n);advance(81);assert(routeCalls==n+1)
hero.state={featIds={}};advance(82);assert(events[#events].name=='LOD_RPGWisGPSState' and events[#events].values[1]==false)
hero.state={featIds={'WIS_GPS'}};hero.noRoute=false;advance(83);advance(84);assert(#barks()==7)
local ok,errors=LOD.RPG:ValidateCheckpointDWisGPS();assert(ok,table.concat(errors,';'))

-- Delayed file opens and timer callbacks must never revive canceled speech.
local pending,timers,hooks,notices={},{},{},0
hook={Add=function(id,key,fn) hooks[key]=fn end}
notification={AddLegacy=function() notices=notices+1 end};chat={AddText=noop};surface={PlaySound=noop}
sound={PlayFile=function(_,_,fn) pending[#pending+1]=fn end}
timer.Simple=function(_,fn) timers[#timers+1]=fn end
include('lod/cl_rpg_gps.lua')
local function state(enabled) local i=0;net.ReadBool=function() i=i+1;return i==1 and enabled or false end;receivers.LOD_RPGWisGPSState() end
local function bark(text) net.ReadString=function() return text end;receivers.LOD_RPGWisGPSBark() end
local function channel() local c={plays=0,stops=0};function c:Stop() self.stops=self.stops+1;self.valid=false end;function c:SetTime() assert(self.valid~=false) end;function c:Play() assert(self.valid~=false);self.plays=self.plays+1 end;function c:Pause() assert(self.valid~=false) end;return c end
state(true);bark('TURN LEFT');state(false);local stale=channel();table.remove(pending,1)(stale);assert(stale.stops==1 and stale.plays==0)
state(true);bark('IN 2 SQUARES TURN LEFT');local c=channel();table.remove(pending,1)(c);assert(c.plays==1)
bark('');for _,fn in ipairs(timers) do fn() end;timers={};assert(c.stops==1 and c.plays==1)
bark('TURN LEFT');local last=channel();table.remove(pending,1)(last);last.valid=false;for _,fn in ipairs(timers) do fn() end
hooks.LOD_GPSStopVoice()
print('GPS_CADENCE_PASS: exact idle/repeat timing, near enemies/floors, movement, toggles, staging/death, route retry, ownership and canceled async audio')
