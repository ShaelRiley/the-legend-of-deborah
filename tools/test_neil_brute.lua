local env=dofile('tools/test_enemy_update.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local function noop() end
function table.Count(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
math.Round=function(n) return math.floor(n+0.5) end
net.WriteUInt=noop;net.WriteBool=noop;net.WriteVector=noop;net.WriteString=noop;net.Broadcast=noop
function Angle() return {} end
function ErrorNoHalt(s) error(s) end
local queued={};timer.Simple=function(_,fn) queued[#queued+1]=fn end
local function flush() local q=queued;queued={};for _,fn in ipairs(q) do fn() end end
player.GetAll=function() return {env.hero} end
LOD.RunManager.IsActivePlayer=function(_,p) return p==env.hero and p.alive end
LOD.MazeBuilder._Register=noop
LOD.WanderingDirector={GetDeficitReservation=function() return 3 end}
dofile(root..'sh_rng.lua');dofile(root..'sv_maze_generator.lua');dofile(root..'sv_progression_director.lua')
dofile(root..'sv_neil_brute.lua')
local H,P,N,R,D=LOD.NeilBrute,LOD.ProgressionDirector,LOD.MazeNavigator,LOD.RunManager,LOD.EncounterDirector
assert(H:SelectAttack(80,true,true,true)=='melee')
assert(H:SelectAttack(400,true,true,true)=='charge')
assert(H:SelectAttack(400,true,false,true)=='ranged')
assert(H:SelectAttack(1200,true,true,true)=='ranged')
assert(H:SelectAttack(1200,false,true,true)==nil)
assert(H:SelectAttack(400,true,false,false)==nil)
local function key(c) return LOD.MazeGenerator.CellKey(c.x,c.y,c.z) end
local function edge(a,b) return a<b and a..'|'..b or b..'|'..a end
local graphs={}
for seed=1,10 do
 local g=assert(LOD.MazeGenerator:Generate(seed*1297))
 local ok,err=P:Plan(g,seed*1297);assert(ok,err)
 assert(#g.Progression.Gates==4 and #g.Progression.Keycards==3)
 local meta=g.Progression
 assert(meta.Hunt.neilCell.z==0 and meta.Gates[4].pathIndex>meta.Gates[3].pathIndex)
 assert(meta.Gates[4].pathIndex<meta.JailEdge.pathIndex)
 local blocked=H:Blocked(g)
 local reach=H:Walk(g,{key(g.Start)},blocked)
 assert(not reach[key(meta.CoreCell)] and not reach[key(meta.DeborahCell)])
 local floors={};for k in pairs(reach) do floors[g.Cells[k].z]=true end
 for _,c in pairs(g.Cells) do assert(floors[c.z],'hunt cannot reach a floor') end
 local escort=H:Walk(g,{key(meta.Hunt.neilCell)},blocked)
 assert(escort[key(meta.Hunt.bruteCell)]==2)
 local g2=assert(LOD.MazeGenerator:Generate(seed*1297));assert(P:Plan(g2,seed*1297))
 assert(key(g2.Progression.Hunt.neilCell)==key(meta.Hunt.neilCell))
 graphs[#graphs+1]=g
end
local g=graphs[1]
g.CellTags={}
P:ResetLevelState(g);local s=R.State;s.Level=3;s.LevelSeed=1297;s.BuildReady=true
D.activeCount=0;D.Entities={}
local made,failAt,mutations=0,nil,0
ents.Create=function(class)
 made=made+1;if failAt==made then return nil end
 local e=env.actor(1);e.class=class;e.valid=true
 e.SetNW2String=e.SetNW2Bool;e.SetNW2Float=e.SetNW2Bool
 function e:SetCardIndex(v) self.cardIndex=v end
 function e:Spawn() self.LODConfig=table.Copy(LOD.Config.Encounter.Archetypes[self.LODArchetypeId] or {}) end
 function e:SetColor(v) self.color=v end
 function e:GetMaxHealth() return self.hp or 1 end
 function e:Health() return self.hp or 100 end
 function e:EmitSound() end
 function e:GetPos() return self.pos end
 return e
end
LOD.EnemyVariance={Apply=function(_,e) assert(e.LODEncounterOrdinal and e.LODArchetypeId);mutations=mutations+1 end}
assert(not H:Start() and made==0,'early spawn')
s.GatesOpen={true,true,true,false};s.ObjectiveStage=P.Stages.FIND_NEIL
D.activeCount=LOD.Config.Encounter.ActiveHostileCeiling-4
assert(not H:Start() and made==0,'wanderer reserve stolen')
D.activeCount=0;failAt=2
assert(not H:Start() and not s.NeilHunt,'partial pair committed')
failAt=nil;assert(H:Start());local h=s.NeilHunt
assert(h.started and mutations==3 and #D.Entities==2)
local n=made;assert(H:Start() and made==n,'pair duplicated')
assert(LOD.WanderingDirector:GetDeficitReservation()==3)

-- Effective damage re-plans escape and asks the living escort for the exact
-- victim cell; Brute death alone never releases the card.
H:NeilDamaged(h.neil,0);assert(not h.defendCell)
H:NeilDamaged(h.neil,2);assert(h.defendCell==key(h.neilCell))
H:NeilKilled(h.brute);assert(not h.dead and not s.Cards[4])
env.hero:SetPos(h.neil:GetPos())
function env.hero:NearestPoint(p) return self:GetPos() end
local heroes,threats=H:Threats(g)
local destination=H:Escape(h.neil,g,threats)
assert(destination and threats[destination]>threats[key(h.neilCell)])
local path=N:FindPath(g,h.neilCell,g.Cells[destination]);assert(path)
for i=2,#path do assert(N:CanTraverse(g,key(path[i-1]),key(path[i]))) end
local black=g.Progression.Gates[4]
assert(not N:CanTraverse(g,key(black.beforeCell),key(black.afterCell)))

-- Real routing produces explicit stair waypoints for legal floor changes.
local route=N:PathToWaypoints(g,path)
local upper
local reachable=H:Walk(g,{key(h.neilCell)},H:Blocked(g),true)
for k in pairs(reachable) do if g.Cells[k].z>h.neilCell.z then upper=k;break end end
h.neil.LODWaypoints={};H:Route(h.neil,g,upper)
local stair=false;for _,w in ipairs(h.neil.LODWaypoints) do if w.stair then stair=true end end
assert(stair,'cross-floor escape omitted validated stair waypoints')
-- Holding the two-cell escort band does not rebuild a graph search per tick.
h.defendCell=nil;h.brute.LODNextAttack=10000
local baseWalk=H.Walk;local walks=0
H.Walk=function(self,...) walks=walks+1;return baseWalk(self,...) end
H:Tick(h.brute);local once=walks
for i=1,20 do H:Tick(h.brute) end
assert(walks==once and h.brute.LODBrutePhase=='escort','escort graph rebuilt every frame')
H.Walk=baseWalk

-- Neil can die while his Brute lives. Drop occurs only after the callback,
-- at the death position; forged, remote and duplicate pickups are rejected.
local before=made;H:NeilKilled(h.neil);H:NeilKilled(h.neil)
assert(h.dead and made==before and #queued==1 and s.ObjectiveStage==P.Stages.TAKE_BLACK_KEYCARD)
flush();assert(made==before+1 and h.card.cardIndex==4)
assert(h.card:GetPos().z==h.dropPos.z+LOD.Config.Progression.KeycardHeight)
assert(not P:CollectCard(4,env.hero,{}))
env.hero:SetPos(h.dropPos+Vector(10000,0,0));assert(not P:CollectCard(4,env.hero,h.card))
env.hero:SetPos(h.dropPos);assert(P:CollectCard(4,env.hero,h.card))
assert(not P:CollectCard(4,env.hero,h.card) and s.ObjectiveStage==P.Stages.OPEN_BLACK_GATE)
local keys=0;P.EnsureCoreJailKey=function() keys=keys+1;return {} end
assert(P:TryOpenGate(4,env.hero,{OpenGate=noop}))
assert(s.GatesOpen[4] and s.CheckpointIndex==4 and keys==1)
assert(N:CanTraverse(g,key(black.beforeCell),key(black.afterCell)))
assert(P:TryOpenGate(4,env.hero,{OpenGate=noop}) and keys==1)

-- A new level invalidates delayed card creation from the old death.
s.Cards[4]=false;h.dead=false;h.card=nil;H:NeilKilled(h.neil)
local old=made;R.State={LevelSeed=999,Graph=g,Cards={},GatesOpen={}}
flush();assert(made==old)
R.State=s

-- Committed charge cannot turn into a cross-floor hop or pass a blocked graph
-- edge. Native wall impact creates a finite stun; one target gets one hit.
local brute=h.brute
brute.LODBruteCharge={direction=Vector(1,0,0),ready=10,finish=20,last=10,hit={}}
local origin=brute:GetPos();env.setTime(11)
util.TraceHull=function() return {Hit=true,HitPos=origin+Vector(0,0,4)} end
H:ChargeTick(brute,g,{},11)
assert(brute.LODBrutePhase=='stunned' and brute.LODBruteStunUntil==13 and not brute.LODBruteCharge)
assert(brute:GetPos():DistToSqr(origin)==0)

-- Exercise the ordinary Tick dispatcher, not just BeginCharge directly.
-- Damaging Neil must trigger an armed defender; repeated damage to Neil must
-- not cancel the Brute's committed warning, and Neil's death must not leave a
-- permanent attack veto on the surviving Brute.
local liveH={seed=s.LevelSeed,neil=h.neil,brute=brute,heroes={env.hero},threats={},nextThreat=1000}
s.NeilHunt=liveH
brute.LODBruteStunUntil=nil;brute.LODHitStunUntil=nil;brute.LODNextAttack=0
brute.LODWaypoints={};brute:SetPos(N:CellCenter(g.Cells[key(h.neilCell)]))
env.hero:SetPos(brute:GetPos()+Vector(180,0,0))
util.TraceLine=function() return {Hit=false} end
util.TraceHull=function(opts)
 if opts.mask==MASK_NPCSOLID then return {Hit=false} end
 return {Hit=true,Entity=env.hero}
end
local defendedHits=0;local damageBeforeDefense=H.Damage
H.Damage=function(_,e,p) assert(e==brute and p==env.hero);defendedHits=defendedHits+1 end
env.setTime(20);H:NeilDamaged(h.neil,2)
assert(liveH.defendCell,'missing defense request')
H:Tick(brute)
assert(brute.LODBruteCharge and brute.LODBrutePhase=='windup','defense route disabled the Brute attack')
local committed=brute.LODBruteCharge
H:NeilDamaged(h.neil,2)
assert(brute.LODBruteCharge==committed,'shooting Neil cancelled the Brute warning')
env.setTime(committed.ready-.01);H:Tick(brute);assert(defendedHits==0)
env.setTime(committed.ready);H:Tick(brute)
env.setTime(committed.ready+.05);H:Tick(brute)
assert(defendedHits==1,'ordinary defense Tick failed to deal exactly one charge hit')
H:Impact(brute,22,false)
h.neil.LODDead=true;H:NeilKilled(h.neil)
assert(not liveH.defendCell,'Neil death stranded a defense order')
env.setTime(brute.LODNextAttack-.01);H:Tick(brute);assert(not brute.LODBruteCharge,'cooldown bypassed')
env.setTime(brute.LODNextAttack);H:Tick(brute)
assert(brute.LODBruteCharge or brute.LODBruteAttack,'surviving Brute pursued without attacking')
H:CancelCharge(brute);H.Damage=damageBeforeDefense
h.neil.LODDead=nil;s.NeilHunt=h
flush() -- stale test-hunt key callback cannot affect the authoritative hunt

-- Sighting commits a direction and never steals control from a stair route.
brute.LODBruteStunUntil=nil;brute:SetPos(N:CellCenter(g.Cells[key(h.neilCell)]))
brute.LODWaypoints={{pos=brute:GetPos(),stair=true}};brute.LODWaypointIndex=1
util.TraceLine=function() return {Hit=false} end
env.hero:SetPos(brute:GetPos()+Vector(180,0,0))
assert(not H:BeginCharge(brute,env.hero,g,30),'charge interrupted stairs')
brute.LODWaypoints={};assert(H:BeginCharge(brute,env.hero,g,30),'point-blank threat became harmless')
local q=brute.LODBruteCharge;local direction=q.direction
local hits=0;local baseDamage=H.Damage
H.Damage=function(_,e,p) assert(e==brute and p==env.hero);hits=hits+1 end
util.TraceHull=function(opts)
 if opts.mask==MASK_NPCSOLID then return {Hit=false} end
 return {Hit=true,Entity=env.hero}
end
local start=brute:GetPos();H:ChargeTick(brute,g,{env.hero},q.ready-.01)
assert(hits==0 and brute:GetPos():DistToSqr(start)==0,'windup dealt damage/moved')
env.hero:SetPos(env.hero:GetPos()+Vector(0,50,0))
H:ChargeTick(brute,g,{env.hero},q.ready);H:ChargeTick(brute,g,{env.hero},q.ready+.05)
assert(hits==1 and q.direction==direction and brute:GetPos().y==start.y,'charge turned or hit twice')
H.Damage=baseDamage
-- Shared hit-stun must cancel synchronously, before the outer AI hold returns.
env.setTime(32);brute.LODNextHitStun=nil
assert(LOD.M3HitFeedback:ApplyHitStun(brute))
assert(not brute.LODBruteCharge and brute.nw.LOD_BrutePhase=='escort')
-- Fixed-direction charge cannot cross the Black gate even if the trace misses it.
brute.LODHitStunUntil=nil;s.GatesOpen[4]=false
local a,b=N:CellCenter(black.beforeCell),N:CellCenter(black.afterCell)
local dir=(b-a):GetNormalized();brute:SetPos((a+b)*.5-dir*2)
brute.LODBruteCharge={direction=dir,ready=40,finish=50,last=40,hit={}}
brute.LODBrutePhase='charge';local beforeGate=brute:GetPos()
H:ChargeTick(brute,g,{},40.1)
assert(brute.LODBrutePhase=='stunned' and brute:GetPos():DistToSqr(beforeGate)==0)
-- Solo absence freezes both actors and clears committed attacks.
s.NeilHunt=h;s.SimulationFrozen=true;assert(H:Tick(brute) and not brute.LODBruteCharge)
s.SimulationFrozen=false

-- Production developer command uses the ordinary three card/gate transitions,
-- marks the run unranked, and cannot duplicate the unique pair on repeated use.
P:ResetLevelState(g);s=R.State;s.Level=3;s.LevelSeed=1297;s.BuildReady=true
local gates={};for i=1,4 do
 local e=env.actor(1);function e:GetGateIndex() return i end;e.OpenGate=noop;gates[i]=e
end
ents.FindByClass=function(class) return class=='lod_gate' and gates or {} end
D.activeCount=0;D.Entities={};R.unranked=false
local n=made;env.commands.lod_neil_brute_testkit(env.hero)
assert(R.unranked and s.ObjectiveStage==P.Stages.FIND_NEIL and s.NeilHunt.started)
assert(made==n+2 and not s.Cards[4] and not s.GatesOpen[4] and not s.JailKey)
env.commands.lod_neil_brute_testkit(env.hero);assert(made==n+2)
s.ObjectiveStage=P.Stages.RESCUE_DEBORAH;s.JailKey=true;s.JailDoorOpen=true
assert(not P:CanRescueDeborah());s.GatesOpen[4]=true;assert(P:CanRescueDeborah())

-- Real server topology packets through BOTH real client decoders: all four
-- gate codes survive serialization without corrupting the adjacent fields.
bit={band=function(a,b) return a & b end,bor=function(a,b) return a | b end,
 lshift=function(a,b) return a << b end,rshift=function(a,b) return a >> b end}
GetRenderTarget=function() return {GetName=function() return 'test' end} end
CreateMaterial=function() return {} end;surface={CreateFont=noop}
local receivers,packets={},{};local packet,readAt
net.Receive=function(id,fn) receivers[id]=fn end
net.Start=function(id) packet={id=id,values={}} end
local function write(v,kind) packet.values[#packet.values+1]={v,kind} end
net.WriteUInt=function(v,bits) assert(v>=0 and v<2^bits);write(v,bits) end
net.WriteDouble=function(v) write(v,'double') end
net.WriteBool=function(v) write(v,'bool') end;net.WriteFloat=function(v) write(v,'float') end
net.Send=function() packets[#packets+1]=packet end
local function read(kind) local row=packet.values[readAt];readAt=readAt+1;assert(row[2]==kind,'wire field width mismatch');return row[1] end
net.ReadDouble=function() return read('double') end
net.ReadUInt=read;net.ReadBool=function() return read('bool') end;net.ReadFloat=function() return read('float') end
dofile(root..'sv_minimap.lua');dofile(root..'cl_minimap.lua')
local function roundTrip()
 packets={};assert(LOD.MinimapServer:Send(env.hero))
 for _,p in ipairs(packets) do packet=p;readAt=1;receivers[p.id]();assert(readAt==#packet.values+1) end
 assert(#LOD.Minimap.cells==table.Count(g.Cells))
 local codes={};for _,floor in pairs(LOD.Minimap.cache.floorGates) do for _,gate in ipairs(floor) do codes[gate.gate]=(codes[gate.gate] or 0)+1 end end
 for i=1,4 do assert(codes[i]==1,'gate vanished/corrupted in client topology') end
end
s.Level=2^20+21 -- campaign transport must not wrap at the former 20-bit boundary
roundTrip();assert(LOD.Minimap.level==s.Level)
dofile(root..'cl_minimap_reliability.lua');roundTrip();assert(LOD.Minimap.level==s.Level)
print('NEIL_BRUTE_PASS: seeded multi-floor progression, pair/reserve, armed defense/repeated Neil hits/survivor attacks/cooldown, death-only key, Black checkpoint, stale callbacks, charge/hit-stun/stairs, testkit, both minimap decoders')
