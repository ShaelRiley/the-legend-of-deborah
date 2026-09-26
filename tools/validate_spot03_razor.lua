-- SPOT-03: actual roster/animation/placement/spawn code; Source boundaries are
-- doubles, not native GMod or ordinary release sightings. Run from repo root.
local env=dofile('tools/test_enemy_update.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local baseline=os.getenv('LOD_SPOT03_BASELINE')
local function source(name) return (baseline and (baseline..'/') or root)..name end
local noop=function() end
local passed,failed=0,0
local function check(name,ok)
    if ok then passed=passed+1;print('PASS '..name)
    else failed=failed+1;print('FAIL '..name) end
end
local v=getmetatable(Vector())
v.__div=function(a,b) return a*(1/b) end
v.__eq=function(a,b) return a.x==b.x and a.y==b.y and a.z==b.z end
function v:Dot(b) return self.x*b.x+self.y*b.y+self.z*b.z end
function v:Length2D() return math.sqrt(self.x*self.x+self.y*self.y) end
function Angle(p,y,r) return {p=p or 0,y=y or 0,r=r or 0,Forward=function(a) return Vector(math.cos(math.rad(a.y)),math.sin(math.rad(a.y)),0) end} end
function math.AngleDifference(a,b) return (a-b+180)%360-180 end
function table.Count(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
ACT_IDLE,ACT_RUN_AIM_RIFLE,ACT_RANGE_ATTACK1,ACT_FLY=4,5,7,8
MASK_SOLID,DMG_ENERGYBEAM,DMG_BURN,DMG_POISON,DMG_SLASH=3,4,5,6,7
net.WriteUInt=noop;net.WriteVector=noop;net.Broadcast=noop
local now=100
local function time(t) now=t;env.setTime(t) end
time(now)
local M=LOD.HostileMotionV2
M.FloorLift=2
M.Stop=function(_,e) e.stopped=true;e.LODMotionSpeed=0 end
M.MoveToward=function(_,e,wp) e.waypoint=wp end
M.HoldHitStun=function(_,e,t) return t<(e.LODHitStunUntil or 0) end
LOD.RPGStatusElements={CanInitiateAttack=function(_,e) return not e.disabled end,
    CanMoveVoluntarily=function(_,e) return not e.held end,Has=function() return false end,
    HandleAIFlee=function() return false end,AttachDamageContext=function(_,info,tags) info.tags=tags end}
LOD.RPGAbilityRules={RateOfFireMultiplier=function() return 1 end}
LOD.NewDamageInfo=function() return {SetAttacker=noop,SetInflictor=noop,SetDamageType=noop,SetDamagePosition=noop,
    SetDamage=function(self,n) self.amount=n end} end
LOD.CombatRolls.RollHostileAttack=function(_,e,p,amount) return {total=amount,scale=1,attackEvent={}} end
LOD.CombatRolls.ResolveActorDamage=function(_,c) return c.total end
LOD.CombatRolls.QueueDamageReport=noop
local heroes={};player.GetAll=function() return heroes end
local hullBlocked=false;local lineBlocked=false;local allSolid=false
util.TraceHull=function(t) return {Hit=hullBlocked,StartSolid=false,AllSolid=allSolid,HitPos=t.endpos} end
util.TraceLine=function(t) return {Hit=lineBlocked,StartSolid=false,HitPos=t.endpos} end
util.DistanceToLine=function(a,b,p) local d=b-a;local f=math.Clamp((p-a):Dot(d)/math.max(.01,d:LengthSqr()),0,1);return (p-(a+d*f)):Length() end
util.Effect=noop;function EffectData() return {SetOrigin=noop} end
LOD.WanderingDirector={Config={ArchetypeWeights={}},GetDeficitReservation=function() return 0 end}
dofile(source('sv_enemy_roster.lua'));dofile(source('sv_hostile_animation.lua'))
dofile(root..'sv_enemy_roster_placement.lua')
local E,A,N,D=LOD.EnemyRoster,LOD.HostileAnimation,LOD.MazeNavigator,LOD.EncounterDirector
local key=LOD.MazeGenerator.CellKey
local function graph()
    hullBlocked=false;lineBlocked=false;allSolid=false
    local g={Width=LOD.Config.Maze.Width,Height=LOD.Config.Maze.Height,Layers=2,Cells={},CellTags={},VerticalEdges={},Progression={Gates={}}}
    for z=0,1 do for x=1,4 do for y=1,3 do
        g.Cells[key(x,y,z)]={x=x,y=y,z=z,neighbors={}}
    end end end
    for _,a in pairs(g.Cells) do for _,b in pairs(g.Cells) do
        if a.z==b.z and math.abs(a.x-b.x)+math.abs(a.y-b.y)==1 then a.neighbors[key(b.x,b.y,b.z)]=true end
    end end
    local s={Graph=g,BuildReady=true,LevelSeed=123,Level=1,GatesOpen={},RunId=1,CampaignEpoch=1,CampaignSeed=123}
    LOD.RunManager.State=s;E.Active={};E.Projectiles={}
    return g,s,g.Cells[key(2,2,0)]
end
local g,s,c=graph()
local function actor(id,pos)
    local e=env.actor(1);e.LODArchetypeId=id;e:SetPos(pos or N:CellCenter(c)+Vector(0,0,2))
    e.LODConfig=table.Copy(LOD.Config.Encounter.Archetypes[id] or {})
    e.LODNextAttack=0;e.health=100;e.body={};e.sets=0
    e.GetAngles=function() return Angle() end
    e.SetNW2Int=e.SetNW2Bool;e.SetNW2Float=e.SetNW2Bool;e.SetNW2String=e.SetNW2Bool
    e.GetNW2Float=function(_,_,default) return default end
    e.GetModel=function(self) return self.LODConfig.model end
    e.GetBodygroupCount=function() return 2 end
    e.GetBodygroup=function(self,i) return self.body[i] or 0 end
    e.SetBodygroup=function(self,i,n) self.body[i]=n;self.sets=self.sets+1 end
    e.GetNoDraw=function() return false end;e.SetColor=noop
    e.Health=function(self) return self.health end
    e.TakeDamageInfo=function(self,info) self.health=self.health-info.amount;self.hits=(self.hits or 0)+1;self.tags=info.tags end
    e._RefreshRoute=function(self) self.routeAsked=true end
    e._AdvanceWaypoint=function(self) return self.testWaypoint end
    return e
end
local function pair()
    g,s,c=graph();time(now+10)
    local e=actor('razor');local p=actor('hero',e:GetPos()+Vector(120,0,0));p.player=true;p.LODHostile=false
    e.LODTarget=p;e.testWaypoint={pos=e:GetPos()+Vector(30,0,0),stair=true};heroes={p}
    return e,p
end
local e,p=pair()
local modelIDs={}
for id,d in pairs(E.Definitions) do if d.model=='models/manhack.mdl' then modelIDs[#modelIDs+1]=id end end
check('only actual Manhack-derived identity is Razor',#modelIDs==1 and modelIDs[1]=='razor')
check('Redliner shares dive behavior but not Manhack model',E.Definitions.redliner.model~='models/manhack.mdl')
check('Razor stock model, stats, warning and recovery preserved',e.LODConfig.model=='models/manhack.mdl' and e.LODConfig.speed==185 and e.LODConfig.burstTelegraph==.65 and e.LODConfig.burstCooldown==1.8)
E:Prepare(e);check('stock blade explicitly deployed',e:GetBodygroup(1)==1)
E:Prepare(e);check('presentation setup is once per actor',e.sets==1)
local prepared=actor('razor');prepared.LODRosterReady=true;E:Prepare(prepared)
check('already-prepared actor adopts blade repair',prepared:GetBodygroup(1)==1)
local other=actor('redliner');E:Prepare(other);check('non-Manhack presentation untouched',other.sets==0)
local absent=actor('razor');absent.GetBodygroupCount=function() return 0 end;E:Prepare(absent)
check('missing bodygroup never receives an invalid write',absent.sets==0)
-- Real model-aware animation resolver with distinguishable packed and fly cycles.
e.GetSequenceName=function(_,n) return ({[1]='idle',[2]='fly'})[n] or '' end
e.SelectWeightedSequence=function(_,act) return act==ACT_FLY and 2 or 1 end
e.LookupSequence=function(_,name) return name=='fly' and 2 or (name=='idle' and 1 or -1) end
check('idle resolves deployed flight, not packed pose',A:Resolve(e,ACT_IDLE)==2)
check('warning resolves deployed flight, not packed pose',A:Resolve(e,ACT_RANGE_ATTACK1)==2)
e.LODAnimationCache={[ACT_IDLE]=1};e.LODAnimationRazor=nil
check('old packed-pose cache is invalidated',A:Resolve(e,ACT_IDLE)==2)
e.LODAnimationCache={};e.SelectWeightedSequence=function() return -1 end
check('missing ACT metadata prefers named fly',A:Resolve(e,ACT_IDLE)==2)
other.GetSequenceName=e.GetSequenceName;other.SelectWeightedSequence=function() return 1 end;other.LookupSequence=e.LookupSequence
check('other archetypes retain their ordinary idle',A:Resolve(other,ACT_IDLE)==1)
-- Actual AI Begin/Tick must choose a canonical approach instead of a doomed dive.
e,p=pair();hullBlocked=true;E:Tick(e)
check('visible target behind low blocking hull does not start dive',e.LODRosterAttack==nil)
check('blocked approach provides diagnostic reason',e.LODRazorApproachReason=='blocked_hull')
time(now+.1);E:Tick(e)
check('blocked approach resumes graph route',e.routeAsked and e.waypoint==e.testWaypoint)
check('retry does not spam charge in the approach window',not e.LODRosterAttack)
e,p=pair();p:SetPos(p:GetPos()+Vector(0,0,LOD.Config.Maze.LevelHeight));E:Tick(e)
check('different deck target does not trigger planar dive',not e.LODRosterAttack)
time(now+.1);E:Tick(e);check('different deck target uses stair route',e.routeAsked and e.waypoint.stair)
e,p=pair();e:SetPos(e:GetPos()+Vector(0,0,40));p:SetPos(p:GetPos()+Vector(0,0,40));E:Tick(e)
check('unfinished stair elevation does not trigger planar dive',not e.LODRosterAttack)
time(now+.1);E:Tick(e);check('unfinished stair elevation keeps stair route',e.routeAsked and e.waypoint.stair)
e,p=pair();allSolid=true;E:Begin(e,p,now);check('AllSolid preflight refuses dive',not e.LODRosterAttack)
e,p=pair();p:SetPos(N:CellCenter(g.Cells[key(3,2,0)]));g.Cells[key(2,2,0)].neighbors[key(3,2,0)]=nil
E:Begin(e,p,now);check('missing graph edge refuses visible direct dive',not e.LODRosterAttack)
e,p=pair();p:SetPos(N:CellCenter(g.Cells[key(3,2,0)]));g.Progression.Gates={{edgeKey=N:EdgeKey(c,g.Cells[key(3,2,0)])}}
E:Begin(e,p,now);check('locked gate refuses visible direct dive',not e.LODRosterAttack)
s.GatesOpen[1]=true;e.LODRazorApproachUntil=nil;E:Begin(e,p,now)
check('opened gate permits otherwise legal dive',e.LODRosterAttack~=nil)
e,p=pair();g.CellTags[key(c.x,c.y,c.z)]={safe=true};E:Begin(e,p,now)
check('protected sanctuary never starts dive',not e.LODRosterAttack)
e,p=pair();p:SetPos(N:CellCenter(g.Cells[key(3,2,0)]));g.CellTags[key(3,2,0)]={entryApron=true};E:Begin(e,p,now)
check('protected apron never starts dive',not e.LODRosterAttack)
-- Canonical shared attack execution, one HP packet, frozen direction and bounds.
e,p=pair();E:Tick(e);local a=e.LODRosterAttack
check('clear legal corridor starts normal warning',a and not a.released and a.ready==now+.65)
local initial=e:GetPos();local direction=a.direction
E:Attack(e,a,now+.3);check('warning does not move or hit',e:GetPos()==initial and not p.hits)
p:SetPos(initial+Vector(120,100,0));time(a.ready);E:Attack(e,a,now);time(now+.05);E:Attack(e,a,now)
check('released dive preserves frozen heading',a.direction==direction and e:GetPos().y==initial.y)
check('sidestepped Hero is not hit',not p.hits)
p:SetPos(e:GetPos()+Vector(25,0,0));time(now+.05);E:Attack(e,a,now)
check('contact uses one real roster HP settlement',p.hits==1 and p:Health()==89)
check('contact retains physical melee damage tags',p.tags and p.tags.physical and p.tags.melee and not p.tags.magic)
time(now+.01);E:Attack(e,a,now);check('same commitment cannot hit Hero twice',p.hits==1)
initial=e:GetPos();time(a.finish+5);E:Attack(e,a,now)
check('expired service cannot move beyond deadline',e:GetPos()==initial)
check('expired dive enters normal recovery',not e.LODRosterAttack and e.LODNextAttack==now+1.8)
e,p=pair();e.held=true;E:Begin(e,p,now);check('Held cannot begin movement attack',not e.LODRosterAttack)
e,p=pair();E:Begin(e,p,now);a=e.LODRosterAttack;time(a.ready);E:Attack(e,a,now);initial=e:GetPos();e.held=true;time(now+.05);E:Attack(e,a,now)
check('Held interrupts a released dive without travel',e:GetPos()==initial and not e.LODRosterAttack)
-- Existing in-flight hull, graph and EntrySafety gates remain authoritative.
e,p=pair();E:Begin(e,p,now);a=e.LODRosterAttack;time(a.ready);E:Attack(e,a,now);initial=e:GetPos();hullBlocked=true;time(now+.05);E:Attack(e,a,now)
check('new obstruction stops released dive',e:GetPos()==initial and not e.LODRosterAttack)
e,p=pair();E:Begin(e,p,now);a=e.LODRosterAttack;time(a.ready);E:Attack(e,a,now);initial=e:GetPos()
LOD.EntrySafety={MovementAllowed=function() return false end};time(now+.05);E:Attack(e,a,now)
check('B29 runtime movement denial cancels dive',e:GetPos()==initial and not e.LODRosterAttack);LOD.EntrySafety=nil
-- A rejected preflight is recoverable, not permanent exclusion.
e,p=pair();hullBlocked=true;E:Tick(e);hullBlocked=false;time(now+.6);E:Tick(e)
check('cleared approach retries normal attack',e.LODRosterAttack~=nil)
-- Directed eligibility and real admission/fallback/unified spawn.
check('Razor directed template excluded from sector one',not table.HasValue(D:_EligibleTemplates(1,'arena'),'razor_cover'))
check('Razor directed template enters sector two',table.HasValue(D:_EligibleTemplates(2,'arena'),'razor_cover'))
e,p=pair();local ec=LOD.Config.Encounter
check('Rotor Cover Break remains one Razor and one Soldier',ec.Templates.razor_cover.composition.razor==1 and ec.Templates.razor_cover.composition.soldier==1)
check('legal Razor placement retains graph floor origin',E:Placement(g,c,'razor','arena').pos==N:CellCenter(c)+Vector(0,0,2))
g.CellTags[key(c.x,c.y,c.z)]={safe=true};check('Razor placement refuses sanctuary',E:Placement(g,c,'razor','arena')==nil)
g.CellTags={};hullBlocked=true;check('blocked Razor placement is rejected',E:Placement(g,c,'razor','arena')==nil)
local savedSpawn=D._SpawnEncounter
-- Reload unified production spawner, then the production placement wrapper.
D.LODUnifiedVarianceSpawner=nil;LOD.EnemyVariance=nil;dofile(root..'sv_encounter_spawn_variance.lua');dofile(root..'sv_enemy_roster_placement.lua')
local made={};ents.Create=function()
 local x=actor('razor');x.Spawn=function(self) self.spawned=true end;x.Activate=noop
 made[#made+1]=x;return x
end
D.GetActiveCount=function(self) return #self.Entities end;M.SnapSpawn=noop
local function encounter() return {id=1,cell=c,cellKey=key(c.x,c.y,c.z),role='arena',composition={razor=1,soldier=1},entities={}} end
D.Entities={};hullBlocked=false;local enc=encounter();D:_SpawnEncounter(enc)
local gotRazor=false;for _,x in ipairs(made) do if x.LODArchetypeId=='razor' and x.spawned then gotRazor=true end end
check('real unified spawner instantiates Razor',gotRazor and #enc.entities==2)
D.Entities={};made={};hullBlocked=true;enc=encounter();D:_SpawnEncounter(enc)
check('rejected Razor substitutes ordinary body without count inflation',not enc.composition.razor and enc.composition.shambler==1 and #enc.entities==2)
-- Diagnostics must work in release mode without mutating any authority.
local cmd=env.commands.lod_razor_status
check('release read-only diagnostic registered',type(cmd)=='function')
if cmd then
 hullBlocked=false;e,p=pair();e.LODWanderer=true;e.LODSpawnSource='wanderer'
 local alternate=actor('shambler');alternate.LODConfig.model='models/manhack.mdl'
 ents.FindByClass=function() return {e,alternate} end
 D.Plan={ecology={theme='hunting'},encounters={{plannedComposition={razor=2},composition={shambler=2},spawned=true},
  {plannedComposition={razor=1},composition={razor=1}}}}
 E.PlacementStats={razor={accepted=2,rejected=1}}
 GetConVar=function() return {GetBool=function() return false end} end
 local lines={};local oldPrint=print;print=function(line) lines[#lines+1]=line end
 LOD.RunManager.unranked=nil
 local before=e:GetPos();local oldRNG=LOD.RNG;local plan=D.Plan
 local oldHull,oldLine=util.TraceHull,util.TraceLine
 util.TraceHull=function() error('diagnostic performed hull query') end;util.TraceLine=function() error('diagnostic performed ray query') end
 local ok,err=pcall(cmd,nil);print=oldPrint;util.TraceHull=oldHull;util.TraceLine=oldLine
 check('diagnostic succeeds with developer mode off',ok)
 local text=table.concat(lines,'\n')
 check('diagnostic separates plan/current/dormant/living',text:find('planned=3 currentComposition=1 dormant=1 living=1',1,true)~=nil)
 check('diagnostic reports roaming and other Manhack model IDs',text:find('roaming=1 otherManhackModels=1',1,true)~=nil)
 check('diagnostic leaves positions, plan, RNG and ranked state unchanged',e:GetPos()==before and D.Plan==plan and LOD.RNG==oldRNG and not LOD.RunManager.unranked)
 p.IsAdmin=function() return false end;lines={};print=function(line) lines[#lines+1]=line end;cmd(p);print=oldPrint
 check('diagnostic rejects non-admin player',#lines==0)
 if not ok then print(tostring(err)) end
else
 for _,name in ipairs({'diagnostic succeeds with developer mode off','diagnostic separates plan/current/dormant/living',
  'diagnostic reports roaming and other Manhack model IDs','diagnostic leaves positions, plan, RNG and ranked state unchanged',
  'diagnostic rejects non-admin player'}) do check(name,false) end
end
print(string.format('SPOT03_RAZOR_RESULT passed=%d failed=%d native=false',passed,failed))
if failed>0 then os.exit(1) end
