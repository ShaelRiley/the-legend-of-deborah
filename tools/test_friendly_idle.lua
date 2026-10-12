-- Exercise the production clock, native pose cache and actual event Draw path.
-- Native model geometry/flex orientation still requires a Source observation.
local root='gamemodes/legend_of_deborah/'
local now,frame,low=0,0,false
function CurTime() return now end
function FrameNumber() return frame end
function IsValid(e) return type(e)=='table' and not e.removed end
function Angle(p,y,r) return {p=p or 0,y=y or 0,r=r or 0} end
angle_zero=Angle()
local vec={};vec.__index=vec
function Vector(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},vec) end
function vec:DistToSqr(b) return (self.x-b.x)^2+(self.y-b.y)^2+(self.z-b.z)^2 end
function EyePos() return Vector() end
function GetConVar() return {GetBool=function() return low end} end
math.random=function() error('cosmetic idle consumed gameplay RNG') end
math.Rand=math.random
LOD={}
dofile(root..'gamemode/lod/cl_friendly_idle.lua')
local I=LOD.FriendlyIdle
local function actor(id)
    local e={model='models/player/monk.mdl',id=id or 1,pos=Vector(),sequence=0,
        sequenceLookups=0,boneLookups=0,flexLookups=0,resets=0,cycles=0,boneWrites=0,
        bones={},weights={},boneCount=9,flexCount=5}
    function e:GetModel() return self.model end
    function e:EntIndex() return self.id end
    function e:GetPos() return self.pos end
    function e:LookupSequence(name)
        self.sequenceLookups=self.sequenceLookups+1
        assert(name=='idle_all_01' or name=='idle_all_02' or name=='menu_combine','unsafe sequence lookup')
        if self.unsupported or (self.secondary and name=='idle_all_01') then return -1,0 end
        return 7,2
    end
    function e:ResetSequence(id) assert(id==7);self.sequence=id;self.resets=self.resets+1 end
    function e:GetSequence() return self.sequence end
    function e:SetCycle(c) assert(c>=0 and c<1);self.cycle=c;self.cycles=self.cycles+1 end
    function e:SetAutomaticFrameAdvance(v) self.auto=v end
    function e:SetPlaybackRate(v) self.rate=v end
    local bones={'Spine2','Neck1','Head1','L_UpperArm','L_Forearm','L_Hand','R_UpperArm','R_Forearm','R_Hand'}
    function e:LookupBone(name)
        self.boneLookups=self.boneLookups+1
        for index,bone in ipairs(bones) do if name=='ValveBiped.Bip01_'..bone and index<=self.boneCount then return index-1 end end
    end
    function e:GetBoneCount() return self.boneCount end
    function e:ManipulateBoneAngles(id,a)
        assert(id>=0 and id<self.boneCount,'stale bone index');self.boneWrites=self.boneWrites+1
        self.bones[id]={p=a.p,y=a.y,r=a.r}
    end
    local flexes={'right_corner_puller','left_smile','right_lid_closer','left_lid_closer','cheek_raiser'}
    function e:GetFlexNum() return self.flexCount end
    function e:GetFlexName(id) self.flexLookups=self.flexLookups+1;return flexes[id+1] or 'unused' end
    function e:SetFlexWeight(id,w) assert(id<math.min(96,self.flexCount));assert(w>=0 and w<=1);self.weights[id]=w end
    return e
end
local function advance(t) now=t;frame=frame+1 end
local guide=actor()
assert(I:Apply(guide,'hermit') and guide.sequence==7 and guide.auto==false and guide.rate==0)
local cycle,lookups,writes=guide.cycle,guide.boneLookups,guide.boneWrites
I:Apply(guide,'hermit');assert(guide.cycles==1 and guide.boneWrites==writes,'duplicate render advanced twice')
advance(.01);I:Apply(guide,'hermit');assert(guide.cycle~=cycle and guide.boneWrites==writes,'cadence or clock failure')
advance(.5);I:Apply(guide,'hermit');assert(guide.boneLookups==lookups and guide.resets==1,'redraw rediscovered/reset model')
guide.sequence=0;advance(.6);I:Apply(guide,'hermit');assert(guide.sequence==7,'native sequence update restored gun/default pose')
guide.pos=Vector(2048,0,0);writes=guide.boneWrites;cycle=guide.cycle
advance(100);I:Apply(guide,'hermit');assert(guide.cycle~=cycle and guide.boneWrites==writes,'distance boundary stopped base idle or posed distant face')
I:Apply(guide,'hermit',true);assert(guide.boneWrites==writes,'same-frame portrait bypassed duplicate guard')
advance(100.1);I:Apply(guide,'hermit',true);assert(guide.boneWrites>writes,'visible portrait incorrectly culled')
guide.pos=Vector();guide.LODFriendlyIdle.nextDetail=0;low=true
advance(101);I:Apply(guide,'hermit');writes=guide.boneWrites
advance(101.06);I:Apply(guide,'hermit');assert(guide.boneWrites==writes,'reduced cadence exceeded 10Hz')
advance(101.11);I:Apply(guide,'hermit');assert(guide.boneWrites>writes)
low=false;guide.LODFriendlyIdle.nextBlink=now;guide.LODFriendlyIdle.nextDetail=0
advance(102);I:Apply(guide,'hermit');assert(guide.weights[2]==0)
advance(102.11);I:Apply(guide,'hermit');assert(guide.weights[2]>.99 and guide.weights[3]>.99,'both eyes did not blink')
advance(102.3);I:Apply(guide,'hermit');assert(guide.weights[2]==0 and guide.weights[3]==0,'blink retained closed eyes')
local other=actor(2);I:Apply(other,'hermit');assert(other.cycle~=guide.cycle,'actors synchronized')
local scavenger,surveyor,master=actor(3),actor(4),actor(5)
I:Apply(scavenger,'scavenger');I:Apply(surveyor,'surveyor');I:Apply(master,'game_master')
assert(scavenger.weights[0]==0 and scavenger.bones[7].y==40,'guarded scavenger lost dignity/torso gesture')
assert(surveyor.weights[0]>0 and master.weights[0]>surveyor.weights[0],'roles lost distinct facial tone')
assert(master.bones[2].y~=guide.bones[2].y,'roles lost distinct glance')
local previous=guide.LODFriendlyIdle
advance(103);I:Apply(guide,'scavenger');assert(guide.LODFriendlyIdle~=previous and guide.bones[4].y==0,'role change retained offered hand')
guide.model='models/player/Group03/male_07.mdl';guide.boneCount=1;guide.flexCount=0
advance(104);assert(I:Apply(guide,'surveyor') and guide.LODFriendlyIdle.model==guide.model,'changed model retained cache')
I.Version=I.Version..'-reload';previous=other.LODFriendlyIdle
advance(105);I:Apply(other,'hermit');assert(other.LODFriendlyIdle~=previous,'Lua reload retained prior pose version')
local missing=actor(6);missing.boneCount=0;missing.flexCount=0
assert(I:Apply(missing,'scavenger') and missing.cycles==1,'optional bones/flexes caused failure')
local fallback=actor(7);fallback.secondary=true;assert(I:Apply(fallback,'hermit') and fallback.sequenceLookups==2)
local invalid=actor(8);invalid.unsupported=true;assert(not I:Apply(invalid,'hermit') and invalid.resets==0 and invalid.cycles==0,'invalid sequence guessed zero/default')
-- Real event Draw keeps quiz suppression ahead of animation/model paint.
include=function() end;ENT={}
dofile(root..'entities/entities/lod_dungeon_event/cl_init.lua')
local event=actor(99);local drawn=0
function event:GetNW2String() return self.archetype end
function event:GetEventID() return 'event-one' end
function event:DrawModel() drawn=drawn+1 end
for kind,role in pairs({equipment_quiz='game_master',prisoner_barter='scavenger',prison_surveyor='surveyor'}) do
    event.archetype=kind;advance(now+.2);ENT.Draw(event)
    assert(event.LODFriendlyIdle.role==role)
end
assert(drawn==3)
LOD.DungeonEvents={events={{id='event-one',entityIndex=99,details={spent=true}}}}
event.archetype='equipment_quiz';advance(now+.2);local cycles=event.cycles;ENT.Draw(event)
assert(drawn==3 and event.cycles==cycles,'spent Game Master was drawn/animated')
local machine=actor(100);machine.archetype='vending_machine'
machine.GetNW2String=event.GetNW2String;machine.DrawModel=event.DrawModel
ENT.Draw(machine);assert(drawn==4 and not machine.LODFriendlyIdle,'prop enrolled as person')
-- The actual server entity selects the animated guide mesh without changing
-- its interaction hull or adding a server Think/animation service.
ENT={KIND_GUIDE=1};AddCSLuaFile=function() end
util={IsValidModel=function() return true end,AddNetworkString=function() end};concommand={Add=function() end}
function Color(r,g,b,a) return {r=r,g=g,b=b,a=a} end
MOVETYPE_NONE=0;SOLID_BBOX=1;COLLISION_GROUP_NONE=0;RENDERMODE_TRANSCOLOR=1;SIMPLE_USE=1
local native=actor(101)
function native:GetStageKind() return 1 end
function native:SetModel(model) self.model=model end
function native:SetCollisionBounds(mins,maxs) self.mins,self.maxs=mins,maxs end
local function noop() end
native.SetMoveType=noop;native.SetSolid=noop;native.SetCollisionGroup=noop
native.SetRenderMode=noop;native.SetColor=noop;native.SetUseType=noop;native.DrawShadow=noop
dofile(root..'entities/entities/lod_staging_prop/init.lua')
setmetatable(native,{__index=ENT}) -- native scripted entities inherit their shared constants
ENT.Initialize(native)
assert(native.model=='models/player/monk.mdl' and native.mins.x==-18 and native.maxs.z==74)
assert(not ENT.Think,'guide added a recurring server animation service')
print('FRIENDLY_IDLE_PASS: named unarmed cycles/looping, four roles, blink reopen, native overwrite, unique phase, cached discovery, duplicate/cadence/distance/portrait gates, model/role/reload invalidation, absent optional bones/flexes, spent quiz/props, actual guide model and unchanged hull')
