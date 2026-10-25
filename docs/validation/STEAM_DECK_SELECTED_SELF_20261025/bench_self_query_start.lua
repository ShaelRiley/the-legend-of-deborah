assert(SERVER and not LOD.BenchQueryProfile and not LOD.BenchQueryProfileOriginals)
assert(not (LOD.RuntimeAudit and LOD.RuntimeAudit.CPUProfile),'Other CPU profile active')
local lease={started=SysTime(),bindings={},rows={},sampling=128};LOD.BenchQueryProfile=lease
LOD.BenchQueryProfileOriginals={}
local selected={RPGAbilityRules={'ProgressionState','Derived','RogueMovementMultiplier','HostileDexMovementMultiplier'},CharacterProgressionSystem={'ReconcileFeatOwnership','RepairDuplicateFeatSelections','_RecomputeProgressionState'},IdentityPerkDirector={'EnsureState','EnsurePackage'},RPGStatusElements={'BindActorLife','Has','CanInitiateAttack','CanMoveVoluntarily','LocomotionMultiplier','ObserveCell','HandleAIFlee'},SoldierProgression={'StateFor'},HostileMotionV2={'MoveToward','Stop'},EntrySafety={'BeforeAI'}}
local arm=util.JSONToTable(file.Read('legend_of_deborah/bench_query_profile_arm.json','DATA')or'{}')
if arm and (arm.scope=='managers-v1'or arm.scope=='managers-self-v1')then
 selected.BossEncounter={'TickActor','Owned'}
 selected.Hector={'Tick'};selected.Warden={'Tick'};selected.NeilBrute={'Tick'}
 selected.EnemyRoster={'Tick','CloseDefense','TickCloseDefense'};selected.EnemyUpdate={'Tick'}
 selected.HostileAnimation={'Move','Update'}
 selected.EntrySafety={'BeforeAI','MovementAllowed'}
 selected.MagicForms={'ConstrainWallMovement'}
end
if arm and arm.scope=='navigation-v1'then
 selected={MazeNavigator={'WorldToCell','CellCenterCoordinates','Distance','FindPath','FindHostilePath'},MazeBuilder={'CellCenterCoordinates'},EntrySafety={'ExactCell','ProtectedPosition'}}
end
if arm and arm.scope=='warden-start-v1'then
 selected={Warden={'Commit','SpawnClones'},WardenTurrets={'Admit','Plan','Placement','Supported'},CharacterProgressionSystem={'AttachMonsterProgression','GenerateMonsterProgression','AdvanceAutomaticActor'}}
 lease.sampling=1;lease.events={}
end
if arm and arm.scope=='managers-self-v1'then
 lease.sampling=1;lease.selfmode=true;lease.contexts={};lease.main={};lease.root_seconds=0
 selected.EntrySafety={'BeforeAI','MovementAllowed','ExactCell','ProtectedPosition'}
 selected.MazeNavigator={'WorldToCell','CellCenterCoordinates','Distance','FindHostilePath'}
 selected.MazeBuilder={'CellCenterCoordinates'}
end
local sampleEvery=lease.sampling
for service,methods in pairs(selected)do
 local target=LOD[service]
 if target then for _,key in ipairs(methods)do
  local fn=target[key]
  if type(fn)=='function'then
   local row={name=service..'.'..key,calls=0,samples=0,seconds=0,maximum=0};lease.rows[#lease.rows+1]=row
   local function finish(start,...)
    local dt=math.max(0,SysTime()-start);row.samples=row.samples+1;row.seconds=row.seconds+dt;row.maximum=math.max(row.maximum,dt);if lease.events and dt>=.008 and #lease.events<128 then lease.events[#lease.events+1]={name=row.name,milliseconds=dt*1000,elapsed=SysTime()-lease.started,tick=engine.TickCount()}end;return ...
   end
   local wrapper=function(...)
    if lease.stopped then return fn(...)end
    row.calls=row.calls+1
    if row.calls%sampleEvery~=0 then return fn(...)end
    return finish(SysTime(),fn(...))
   end
   if lease.selfmode then
    row.self_seconds=0
    local function finishSelf(ctx,depth,start,...)
     local dt=math.max(0,SysTime()-start);assert(ctx.depth==depth,'Nested observer depth mismatch')
     local child=ctx.frames[depth].child;ctx.depth=depth-1
     if depth>1 then ctx.frames[depth-1].child=ctx.frames[depth-1].child+dt else lease.root_seconds=lease.root_seconds+dt end
     row.samples=row.samples+1;row.seconds=row.seconds+dt;row.maximum=math.max(row.maximum,dt);row.self_seconds=row.self_seconds+math.max(0,dt-child)
     return ...
    end
    wrapper=function(...)
     if lease.stopped then return fn(...)end
     row.calls=row.calls+1;local key=coroutine.running()or lease.main;local ctx=lease.contexts[key]
     if not ctx then ctx={depth=0,frames={}};lease.contexts[key]=ctx end
     local depth=ctx.depth+1;ctx.depth=depth;local frame=ctx.frames[depth]
     if not frame then frame={};ctx.frames[depth]=frame end;frame.child=0
     return finishSelf(ctx,depth,SysTime(),fn(...))
    end
   end
   local record={service=service,target=target,key=key,fn=fn,own=rawget(target,key)~=nil,previous=rawget(target,key),wrapper=wrapper}
   lease.bindings[#lease.bindings+1]=record;LOD.BenchQueryProfileOriginals[#LOD.BenchQueryProfileOriginals+1]=record;target[key]=wrapper
  end
 end end
end
function lease:Stop(reason)
 if self.stopped then return end;self.stopped=true;timer.Remove('LOD_BenchQueryProfileLease')
 local restored=true;local mismatches={}
 for i=#self.bindings,1,-1 do local b=self.bindings[i]
  if b.target[b.key]==b.wrapper then b.target[b.key]=b.previous
  else restored=false;mismatches[#mismatches+1]=b.service..'.'..b.key end
 end
 local dt=SysTime()-self.started;local rows={};local open=0;local contexts=0;if self.selfmode then for _,ctx in pairs(self.contexts)do contexts=contexts+1;open=open+ctx.depth end end
 for _,row in ipairs(self.rows)do rows[#rows+1]={name=row.name,calls=row.calls,completed_samples=row.samples,sampled_ms=row.seconds*1000,estimated_ms_per_second=row.seconds*sampleEvery*1000/math.max(dt,.001),maximum_sample_ms=row.maximum*1000,self_ms=row.self_seconds and row.self_seconds*1000 or nil,self_ms_per_second=row.self_seconds and row.self_seconds*1000/math.max(dt,.001)or nil}end
 table.sort(rows,function(a,b)return a.estimated_ms_per_second>b.estimated_ms_per_second end)
 LOD.BenchQueryProfile=nil
 file.Write('legend_of_deborah/bench_query_profile.json',util.TableToJSON({seconds=dt,sampling=sampleEvery,self_mode=self.selfmode,open_context_frames=open,context_count=contexts,root_ms=self.root_seconds and self.root_seconds*1000 or nil,events=lease.events,bindings=#self.bindings,restored=restored,mismatches=mismatches,reason=reason,rows=rows,scope='Self-mode subtracts only nested selected-provider wall scopes using per-coroutine reusable frames; not exclusive CPU or complete AI attribution. Instrumented call-shape/JIT/clock overhead and unselected descendants remain. Zero open frames and zero capture Lua errors required. Inclusive wall estimates overlap; when sampling=1 allselectedrareinitializationcalls measured. Events>=8ms capped128; observerchangescallshape/JIT andisnotexclusiveCPU. Sampling128retainsoriginalsparsemode; deterministic sampling can alias. Low sample counts are weak evidence. Maximum is sampled only; errors do not complete samples. Counter/provider observation affects JIT and performance. Not acceptance FPS.'},true))
end
timer.Create('LOD_BenchQueryProfileLease',120,1,function()lease:Stop('lease')end)
file.Write('legend_of_deborah/bench_query_profile_started.json',util.TableToJSON({started=true,bindings=#lease.bindings,sampling=lease.sampling},true))
