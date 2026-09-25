-- B29 production generation and collision-boundary gate. No permissive spawn
-- trace: reuse the actual builder's generated floor/wall AABBs and B28 failures.
local X=dofile('tools/test_bestiary_b28.lua')
local T,H,W,D,R=X.T,X.H,X.W,X.D,X.R
local root='gamemodes/legend_of_deborah/gamemode/lod/'
timer.Create=function() end;hook.Add=function() end
local realPrint=print
local function quiet(f) return T.quiet(f) end
ents.FindByClass=function() return {} end
util.IsValidProp=function() return true end
local N=LOD.MazeNavigator
local function key(c) return LOD.MazeGenerator.CellKey(c.x,c.y,c.z) end
R.IdentityOf=function(_,p) return p.id end
local now=10000
local function time(t) now=t;T.setTime(t) end
local heroes={}
local F=LOD.FactionManager
F.LivingTargets=function() return heroes end
F.CanAcquirePlayerTarget=function(_,p) return IsValid(p) and p:IsPlayer() and p:Alive() and not LOD.EntrySafety:Protected(p) end
F.IsEnemyCombatant=function(_,e) return IsValid(e) and e.LODHostile==true end
dofile(root..'sv_entry_safety.lua')
-- Restore the actual outer physical-build -> encounter-planning wrapper after
-- B28's deliberately isolated geometry compiler loaded its concrete builder.
dofile(root..'sv_m3_run_integration.lua')
local S=LOD.EntrySafety
local function prepare(seed,level)
 heroes={};T.setHeroes({});W:Cleanup();S:Reset()
 R.State={CampaignSeed=seed,CampaignEpoch=1,RunId=1,Level=level,PlayerState={}}
 local g=H.prepare(seed,level);R.State.GatesOpen={false,false,false,false}
 util.TraceHull=X.trace
 local boxes,report
 quiet(function() boxes,report=X.compile(g,true) end);R.State.BuildReport=report
 util.TraceHull=X.trace
 util.TraceLine=function(t) return {Hit=false,StartSolid=false,Fraction=1,HitPos=t.endpos,HitNormal=Vector(0,0,1)} end
 local plan=assert(g.EncounterPlan,'real physical Build omitted encounter planning');R.State.BuildReady=true
 T.init(g);T.bounds(g);H.bounds(plan)
 return g,plan,boxes
end
local samples={};local savedGraph
for i=1,(arg[1]=="--runtime" and 0 or 20) do
 local level=i<=16 and 1 or ({2,5,10,21})[i-16]
 local g,plan,boxes=prepare((i<=16 and i or i-16)*7919,level)
 local data=assert(g.EntrySafety);local safeCount=table.Count(data.cells)
 assert(safeCount>=1 and safeCount<=5,'sanctuary not compact')
 local arrival=N:CellCenter(g.Start)+Vector(0,0,12)
 assert(key(S:ExactCell(g,arrival))==key(g.Start) and S:ProtectedPosition(arrival),'actual builder arrival unprotected')
 assert(not S:ProtectedPosition(arrival+Vector(0,0,LOD.Config.Maze.LevelHeight)),'sanctuary leaks to upper deck')
 local types,early={},{};local deep=0;local optional=0
 for _,enc in ipairs(plan.encounters) do if not enc.objective then
  optional=optional+1;assert(not g.CellTags[enc.cellKey].entryRoamOpening,'optional squad crowds first roaming contacts')
 end end
 for _,e in ipairs(W.Entities) do
  local home=g.Cells[e.LODHomeCellKey];local d=data.depth[key(home)]
  assert(S:SpawnCellAllowed(g,home),'spawn in sanctuary/apron')
  assert(W:_SupportedSpawn(home),'spawn without compiled support')
  assert(S:HomeArchetypeAllowed(g,home,e.LODArchetypeId),'opening complexity escaped')
  types[e.LODArchetypeId]=true
  if d and d<10 then local bin=d<6 and 1 or 2;early[bin]=(early[bin] or 0)+1 end
  if not d or d>=10 then deep=deep+1 end
  for k in pairs(data.cells) do assert(not S:PatrolCellAllowed(g,e,g.Cells[k]),'sanctuary patrol ingress') end
  for k in pairs(home.neighbors) do if S:PatrolCellAllowed(g,e,g.Cells[k]) then
   assert(not g.CellTags[k].entryApron,'patrol apron ingress')
  end end
 end
 assert((early[1] or 0)<=1 and (early[2] or 0)<=1,'crowded opening homes')
 assert(#W.Entities>=12 and table.Count(types)>=6 and deep>=10 and optional>=4,'population erased')
 samples[#samples+1]={seed=(i<=16 and i or i-16)*7919,level=level,boxes=#boxes,
  sanctuary=safeCount,roamers=#W.Entities,types=table.Count(types),deep=deep,optional=optional,
  firstHomes=early[1] or 0,secondHomes=early[2] or 0}
 realPrint('B29_SAMPLE '..H.serial(samples[#samples]))
 savedGraph=g
end
-- Exact former native collision layout with the candidate authority installed.
local g,plan=prepare(1515962883,1)
assert(g.LevelSeed==1756475100 and g.Attempt==2,'recorded generation changed')
local data=g.EntrySafety
local byDepth={}
for k,d in pairs(data.depth) do byDepth[d]=byDepth[d] or {};table.insert(byDepth[d],k) end
for _,keys in pairs(byDepth) do table.sort(keys) end
local function cell(depth) return assert(g.Cells[assert(byDepth[depth], 'no depth '..depth)[1]]) end
local function actor(id,depth,hostile,kind)
 local e=T.entity();e.id=id;e.LODHostile=hostile or false;e.LODArchetypeId=kind or 'shambler';e.nw={}
 function e:IsPlayer() return not self.LODHostile end
 function e:Alive() return self:Health()>0 end
 function e:SetNW2Bool(k,v) self.nw[k]=v end
 e.SetNW2Int=e.SetNW2Bool;e.SetNW2Float=e.SetNW2Bool;e.SetNW2Vector=e.SetNW2Bool
 function e:GetOwner() return self.owner end
 function e:SetParent(v) self.parent=v end
 e:SetPos(N:CellCenter(cell(depth))+Vector(0,0,12))
 return e
end
local pending={};timer.Simple=function(_,fn) pending[#pending+1]=fn end
LOD.CharacterProgressionSystem={IsDeploymentEligible=function(_,ps) return ps.chosen end}
R.GetPlayerState=function(_,p) return R.State.PlayerState[type(p)=='table' and p.id or p] end
R._SyncPlayerVars=function() end
LOD.LootDirector=nil
concommand.Add=function() end
LOD.RPGTestLog=nil
LOD.CampaignTimeout=nil
LOD.StagingDeployment=nil
dofile(root..'sv_staging_deployment.lua')
local a=actor('a',0);heroes={a};T.setHeroes(heroes)
for _,name in ipairs({'SetEyeAngles','SetLocalVelocity','EmitSound','ChatPrint'}) do a[name]=function() end end
R.State.ActiveIdentity={a=true}
R.State.PlayerState.a={identity='a',chosen=true,starterClaimed=true}
-- No arrival clock or pressure record accrues while choosing gear in staging.
a:SetPos(N:CellCenter(g.Start)+Vector(0,0,LOD.Config.Maze.LevelHeight*10))
time(20000);S:Service();assert(next(S.Records)==nil,'staging used arrival allowance')
for j=1,6 do
 time(20000+j*20)
 local old=W.Entities[1];if IsValid(old) then old:Remove() end
 quiet(function() W:_SpawnOne(g,0,'replacement') end)
 for _,e in ipairs(W.Entities) do if IsValid(e) then assert(S:SpawnCellAllowed(g,g.Cells[e.LODHomeCellKey])) end end
end
-- Execute the real public portal admission and deferred native teleport using
-- the actual full production Build report, not an inferred staging position.
time(20199);assert(LOD.StagingDeployment:DeployPlayer(a));assert(not S.Records.a and #pending==1,'queued request consumed arrival')
time(20200);pending[1]();pending={};S:Service()
assert(a:GetPos()==R.State.BuildReport.startPos and R.State.PlayerState.a.deploymentComplete,'production teleport destination mismatch')
local r=S.Records.a
assert(r.safe and r.deployedAt==20200 and not r.exitedAt and #S.Active==0)
local near=actor('near',2,true);near.LODSpawnSource='wanderer'
local ordinary=actor('ordinary',4,true);ordinary.LODSpawnSource='encounter'
LOD.HostileRegistry={List=function() return {near,ordinary} end}
local snapshot=S:Snapshot();assert(snapshot.heroes[1].nearby>=2 and snapshot.heroes[1].nearbySources.encounter==1,'safe-area nearby count hidden')
local function packet(n,source)
 local p={n=n,source=source}
 function p:GetDamage() return self.n end
 function p:SetDamage(v) self.n=v end
 function p:GetAttacker() return self.source end
 function p:SetDamageForce(v) self.force=v end
 return p
end
for _,source in ipairs({near,ordinary}) do local p=packet(10,source);assert(S:DamageGate(a,p) and p.n==0) end
assert(not S:CombatAllowed(ordinary,a),'one-way sanctuary shot')
local proxy={valid=true,owner=a,IsPlayer=function() return false end,GetOwner=function(self)return self.owner end}
assert(not S:CombatAllowed(ordinary,proxy),'owned proxy fires from safety')
assert(not S:MovementAllowed(near,near:GetPos(),a:GetPos()),'native ingress allowed')
assert(not S:MovementAllowed(ordinary,ordinary:GetPos(),a:GetPos()-(ordinary:GetPos()-a:GetPos())),'long sweep skips sanctuary')
assert(not S:EncounterAllowed(g,plan.encounters[1],a),'staged/safe activation')
-- Mixed sources share one quota; spatial advancement alone cannot release a mob.
local actors={};for i=1,9 do
 local e=actor('enemy'..i,4,true,'shambler');e.LODSpawnSource=i%2==0 and 'encounter' or 'wanderer';actors[i]=e
end
LOD.HostileRegistry.List=function() return actors end
local function service(t,depth)
 time(t);if depth then a:SetPos(N:CellCenter(cell(depth))+Vector(0,0,12)) end
 S.NextService=0;S:Service()
end
service(20201,2);assert(r.cap==1 and r.exitedAt==20201)
assert(S:Claim(actors[1])==a)
for i=2,9 do assert(not S:Claim(actors[i]),'first combined load exceeds1') end
local p=packet(10,actors[1]);assert(not S:DamageGate(a,p) and p.n==10)
assert(r.firstAttackAfterDeploy==1 and r.firstAttackAfterExit==0)
assert(S:DamageGate(a,packet(10,actors[2])),'unadmitted hostile damage')
-- Finite cohort, projectile tail, respite. No per-kill refill during the fight.
actors[1].LODDead=true;service(20202);assert(not S:Claim(actors[2]))
service(20205.9);assert(r.completed==0)
service(20206);assert(r.completed==1 and r.restUntil==20210)
assert(not S:Claim(actors[2]));service(20210,6)
for _,e in ipairs(actors) do e.LODDead=nil;e:SetPos(N:CellCenter(cell(6))+Vector(0,0,12)) end
actors[2].LODArchetypeId='reaper';actors[3].LODArchetypeId='drubber'
assert(S:Claim(actors[2])==a);assert(not S:Claim(actors[3]),'two specialists in one introductory contact')
assert(S:Claim(actors[1])==a);assert(not S:Claim(actors[4]),'second combined load exceeds2')
assert(S:Permit(actors[2],a) and S:Permit(actors[1],a))
-- Return toward entry reduces active permission; entering sanctuary cancels all.
service(20210.2,2);assert(r.cap==1)
assert(not S:Permit(actors[1],a),'retreat inherited larger quota')
service(20210.4,0);assert(r.safe and r.completed==1 and not S:Permit(actors[2],a))
service(20210.6,6);assert(r.completed==1,'reentry reset progression')
-- A new nearby teammate cannot open an independent extra swarm; safe teammates
-- are excluded, while an established distant explorer retains ordinary pressure.
local b=actor('b',0);heroes={a,b};T.setHeroes(heroes);assert(S:Deployed(b,R.State));service(20211)
assert(#S.Active==1 and S:Permit(actors[2],a),'safe teammate froze explorer')
b:SetPos(N:CellCenter(cell(6))+Vector(0,0,12));service(20211.2)
assert(not S:Permit(actors[2],a),'staggered arrival inherited advanced volley')
assert(not S:Claim(actors[2]),'first-contact complexity bypass')
b:SetPos(N:CellCenter(cell(0))+Vector(0,0,12));service(20211.4)
-- Actual sequential contacts raise the bound, never refill inside a closed wave.
for e in pairs(r.wave.members) do e.LODDead=true end
service(20212);service(20216);service(20220,10)
assert(r.completed==2 and r.cap==3)
local verified={1,2}
for stage=3,5 do
 local depth=({10,15,20})[stage-2]
 service(now+.2,depth)
 for _,e in ipairs(actors) do e.LODDead=nil;e.LODArchetypeId='shambler';e:SetPos(N:CellCenter(cell(depth))+Vector(0,0,12)) end
 local quota=({3,4,6})[stage-2];assert(r.cap==quota)
 for i,e in ipairs(actors) do assert((S:Claim(e)~=nil)==(i<=quota),'combined stage quota') end
 verified[#verified+1]=quota
 for i=1,quota do actors[i].LODDead=true end
 service(now+1);service(now+4);service(now+4)
end
b:SetPos(N:CellCenter(cell(2))+Vector(0,0,12))
service(now+.2,24);assert(r.completed==5 and not r.limited and S.Records.b.active,'separated explorer or newcomer missing')
for _,e in ipairs(actors) do e.LODDead=nil;e:SetPos(N:CellCenter(cell(24))+Vector(0,0,12));assert(S:Claim(e)==a) end
assert(r.cap==6 and r.highWater>=24)
local completed=r.completed;local previousFirst=r.firstDeploy
local a2=actor('a',0);a.valid=false;heroes={a2,b};T.setHeroes(heroes)
assert(S:Deployed(a2,R.State));service(now+1)
assert(S.Records.a==r and r.completed==completed and r.firstDeploy==previousFirst and not r.firstAttack,'reconnect reset ramp or kept stale per-deploy timing')
local oldOwner=S.Owner;local replacement={};for k,v in pairs(R.State) do replacement[k]=v end;R.State=replacement;S:Context()
assert(S.Owner~=oldOwner and next(S.Records)==nil,'same-seed state replacement retained old work')
print('B29_RUNTIME_PASS long-staging/replacement safety; exact sanctuary; bilateral damage/proxy; long-sweep rejection; combined quotas1/2/3/4/6; tail/respite; progression; staggered/returning/reconnected Heroes; exact owner replacement')
if #samples>0 then print('B29_GENERATED_PASS samples='..#samples..' full production Build AABBs;16 D1 +levels2/5/10/21; populated/varied/optional and unchanged ceilings; native Source acceptance pending') end

return {S=S,X=X,graph=g,actor=actor,cell=cell,time=time}
