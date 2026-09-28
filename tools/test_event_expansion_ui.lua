-- Real client event receiver/prompt and real native entity initialization.
-- Only drawing/network/native engine operations are doubled.
local hooks,receivers,lines={},{},{}
LOD={UI={}}
function Color(...) return {...} end
function Vector(x,y,z) return {x=x,y=y,z=z} end
function IsValid(v) return type(v)=='table' and v.valid~=false end
hook={Add=function(_,name,f) hooks[name]=f end}
local incoming
net={Receive=function(n,f) receivers[n]=f end,ReadTable=function() return incoming end}
input={LookupBinding=function() return 'f' end}
surface={SetFont=function() end,GetTextSize=function(t) return #t*8 end}
draw={SimpleTextOutlined=function(t) lines[#lines+1]=t end}
function ScrW() return 800 end
function ScrH() return 600 end
local pos={DistToSqr=function() return 0 end}
local ent={index=2,archetype='memory_terminal'}
function ent:GetClass() return 'lod_dungeon_event' end
function ent:GetEventID() return 'event:1' end
function ent:EntIndex() return self.index end
function ent:GetPos() return pos end
function ent:GetNW2String(k,default)
 if k=='LOD_EventArchetype' then return self.archetype end
 if k=='LOD_EventName' then return 'Memory Terminal' end
 return default
end
local ply={Alive=function() return true end,GetPos=function() return pos end,GetEyeTrace=function() return {Entity=ent} end}
function LocalPlayer() return ply end
dofile('gamemodes/legend_of_deborah/gamemode/lod/cl_dungeon_events.lua')
local function receive(s) incoming=s;receivers.LOD_DungeonEvents() end
local function render() lines={};hooks.LOD_DungeonEventPrompt();return table.concat(lines,'\n') end
assert(render():find('Synchronizing event',1,true) and not render():find('DEBBIE SLOTS',1,true))
local row={id='event:1',archetype='memory_terminal',entityIndex=1,state='active',details={kind='incident',name='Memory Terminal',
 offer='Watch the lights, then repeat the sequence. Wrong input resets the sequence; there is no resource charge.',
 action='WATCH',endpoints={{entityIndex=1,action='WATCH'},{entityIndex=2,action='CHOOSE LIGHT 2'}}}}
receive({token='2',events={row}})
local shown=render()
assert(shown:find('MEMORY TERMINAL',1,true) and shown:find('[F] CHOOSE LIGHT 2',1,true),'Child interaction prompt missing')
assert(shown:find('resource charge',1,true),'Consequence clipped by narrow prompt')
for _,line in ipairs(lines) do assert(#line*8<=752,'Prompt exceeds narrow display') end
row.claimed=true;assert(render():find('COMPLETED',1,true) and not render():find('CHOOSE LIGHT',1,true))
row.claimed=false;row.claimUnavailable=true
assert(render():find('Unavailable',1,true) and not render():find('CHOOSE LIGHT',1,true))
row.claimUnavailable=false;row.state='resolved';assert(render():find('RESOLVED',1,true))
LOD.UI.ActivePage='equipment';assert(render()=='');LOD.UI.ActivePage=nil
receive({token='1',events={}});assert(#LOD.DungeonEvents.events==1,'Stale snapshot replaced current event generation')
receive({token='3',events={}});assert(render():find('Synchronizing event',1,true),'Empty snapshot retained stale state')

-- Authored metadata reaches the native model/tint/label before interaction.
ENT={};AddCSLuaFile=function() end;include=function() end
MOVETYPE_NONE,SOLID_BBOX,SIMPLE_USE,COLLISION_GROUP_WEAPON=0,1,2,3
LOD.EventRegistry={Definitions={memory_terminal={name='Memory Terminal',presentation={model='models/props_lab/monitor01b.mdl',color={40,170,200},height=42}}}}
dofile('gamemodes/legend_of_deborah/entities/entities/lod_dungeon_event/init.lua')
local native=setmetatable({nw={LOD_EventArchetype='memory_terminal'}},{__index=ENT})
function native:GetNW2String(k,d) return self.nw[k] or d end
function native:SetNW2String(k,v) self.nw[k]=v end
function native:SetModel(m) self.model=m end
function native:SetColor(c) self.color=c end
function native:SetCollisionBounds(a,b) self.bounds={a,b} end
native.SetMoveType,native.SetSolid,native.SetCollisionGroup,native.SetUseType=function() end,function() end,function() end,function() end
native:Initialize()
assert(native.model=='models/props_lab/monitor01b.mdl' and native.color[2]==170 and native.bounds[2].z==42)
assert(native.nw.LOD_EventName=='Memory Terminal')
-- Private in-world clues match only the recipient's current revealed light.
local vm={};vm.__add=function(a,b) return setmetatable({x=a.x+b.x,y=a.y+b.y,z=a.z+b.z},vm) end
function Vector(x,y,z) return setmetatable({x=x,y=y,z=z},vm) end
function Angle(...) return {...} end
ply.EyeAngles=function() return {y=0} end
local starts,ends=0,0
cam={Start3D2D=function() starts=starts+1 end,End3D2D=function() ends=ends+1 end}
ENT={};dofile('gamemodes/legend_of_deborah/entities/entities/lod_dungeon_event/cl_init.lua')
local sign=setmetatable({archetype='memory_terminal',part=2},{__index=ENT})
function sign:GetNW2String() return self.archetype end
function sign:GetNW2Int() return self.part end
function sign:GetEventID() return 'event:1' end
function sign:EntIndex() return 2 end
function sign:GetPos() return Vector(0,0,0) end
function sign:DrawModel() end
row.state='active';row.details.spent=false;row.details.phase='watch';row.details.visibleLight=2
receive({token='4',events={row}});lines={};sign:Draw()
assert(lines[1]=='[2]' and starts==ends,'Current memory light not highlighted or render state leaked')
row.details.phase='answer';row.details.visibleLight=nil;lines={};sign:Draw()
assert(lines[1]=='2','Private clue persisted into answer phase')
sign.archetype='nerve_clock';sign.part=0;row.details.phase='green';lines={};sign:Draw()
assert(lines[1]=='GREEN')
row.details.spent=true;lines={};sign:Draw();assert(#lines==0 and starts==ends)
print('EVENT_EXPANSION_UI_PASS: endpoint prompts, actual cost/consequence, narrow display, spent/unavailable/resolved, stale snapshots, native metadata')
