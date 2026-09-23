-- Production event assertions share only Source boundaries with the chest suite.
local F=dofile('tools/dungeon_event_fixture.lua')()
local root,noop,G,key,Run,Store=F.root,F.noop,F.G,F.key,F.Run,F.Store
local D,R,Slot,graph=F.D,F.R,F.Slot,F.graph
local a,b,actor,online=F.a,F.b,F.actor,F.online
local created,feedback,commands,hooks,timers=F.created,F.feedback,F.commands,F.hooks,F.timers
local packets,receivers,convars=F.packets,F.receivers,F.convars
local graphSignature,originalGraph,generate=F.graphSignature,F.originalGraph,F.generate
assert(not R:Select(1),'One playable archetype cannot silently cap production count')
convars.lod_events_enabled.value='0' -- Explicit operator opt-out remains supported.
local ok,disabled=D:Plan(graph);assert(ok and disabled.mode=='disabled' and #disabled.instances==0)
assert(R.PopulationReady==true,'Approved population release gate is enabled')
R.PopulationReady=false
local gated,gateReason=D:Plan(graph,{enabled=true})
assert(not gated and gateReason:find('catalog activation and rarity tuning pending'))
R.PopulationReady=true
assert(not D:Plan(graph,{enabled=true}),'Explicit enable cannot bypass incomplete catalog gate')
R.PopulationReady=false
local lifecycle={Create=function(_,instance) local e=ents.Create('fixture_event');e:SetPos(LOD.MazeBuilder:CellCenter(instance.cell));return e end,Interact=function() return true,{fixture=true} end}
local defs={}
for _,entry in ipairs({{'fixture_reward','REWARD'},{'fixture_blockade','BLOCKADE'},{'fixture_hazard','HAZARD'},{'fixture_utility','UTILITY'}}) do
 local def={id=entry[1],contract=entry[2],production=true,nonblocking=true,reversible=true,
  Create=lifecycle.Create,Interact=lifecycle.Interact,CanResolve=function() return true end}
 defs[def.contract]=R:Register(def)
end
assert(not D:Plan(graph,{enabled=true}),'Registering a complete catalog must not activate production population')
local seen={}
for seed=1,256 do
 local selected,n=R:Select(seed)
 local again,m=R:Select(seed)
 assert(n==m and n>=1 and n<=4 and #selected==n and table.concat(selected,',')==table.concat(again,','))
 assert(n==LOD.RNG.New(LOD.Seeds.Derive(seed,'dungeon-events:count:v1')):Int(1,4),'Exactly one authoritative utility d4')
 local legacy=R:Catalog();LOD.RNG.New(LOD.Seeds.Derive(seed,'dungeon-events:catalog:v1')):Shuffle(legacy)
 for i=1,n do assert(selected[i]==legacy[i],'Non-rare catalog preserves existing named selection stream') end
 local unique={};for _,id in ipairs(selected) do assert(not unique[id]);unique[id]=true end
 seen[n]=true
end
for n=1,4 do assert(seen[n],'Every d4 count must occur') end
local selectedBefore,nBefore=R:Select(73)
-- Registration order must not alter named streams.
local catalog=R.Definitions;R.Definitions={}
local ids={};for id in pairs(catalog) do ids[#ids+1]=id end;table.sort(ids)
for i=#ids,1,-1 do R:Register(catalog[ids[i]]) end
local selectedAfter,nAfter=R:Select(73)
assert(nBefore==nAfter and table.concat(selectedBefore,',')==table.concat(selectedAfter,','))
assert(not pcall(function() R:Register(catalog.slot_machine) end),'Duplicate archetypes rejected')
-- Validate every contract against the generated graph, not a mirrored planner.
local utility,reward,blockade
for k in pairs(graph.Cells) do
 if not utility and D:ValidatePlacement(graph,defs.UTILITY,{cellKey=k}) then utility={cellKey=k} end
 if not reward and D:ValidatePlacement(graph,defs.REWARD,{cellKey=k}) then reward={cellKey=k} end
end
assert(utility and reward)
for ek,e in pairs(graph.Edges) do
 local p={cellKey=key(e.a),edgeKey=ek}
 if D:ValidatePlacement(graph,defs.BLOCKADE,p) then blockade=p;break end
end
assert(blockade,'Real generated dungeon has an approachable required-route blockade edge')
assert(D:ValidatePlacement(graph,defs.HAZARD,{cellKey=utility.cellKey,blockedCells={}}))
for _,def in pairs(defs) do
 assert(not D:ValidatePlacement(graph,def,{cellKey=key(graph.Start)}),'Start must remain safe')
 assert(not D:ValidatePlacement(graph,def,{cellKey='missing'}))
end
for protected in pairs(D:ProtectedCells(graph)) do
 assert(not D:ValidatePlacement(graph,defs.UTILITY,{cellKey=protected}),'Objectives/gates/stairs must be protected')
end
assert(not D:ValidatePlacement(graph,defs.UTILITY,utility,{[utility.cellKey]=true}))
assert(not D:ValidatePlacement(graph,defs.UTILITY,{cellKey=utility.cellKey,addedEdges={}}))
assert(not D:ValidatePlacement(graph,defs.UTILITY,{cellKey=utility.cellKey,blockedCells={[utility.cellKey]=true}}))
assert(not D:ValidatePlacement(graph,defs.HAZARD,{cellKey=utility.cellKey,blockedCells={[key(graph.Goal)]=true}}))
assert(not D:ValidatePlacement(graph,defs.HAZARD,{cellKey=utility.cellKey,blockedEdges={[blockade.edgeKey]=true}}),'Hazard cannot cut required route')
defs.BLOCKADE.CanResolve=function() return false end
assert(not D:ValidatePlacement(graph,defs.BLOCKADE,blockade),'Unresolvable blockade rejected')
defs.BLOCKADE.CanResolve=function() return true end
assert(not D:ValidatePlacement(graph,defs.BLOCKADE,{cellKey=utility.cellKey,edgeKey=graph.Progression.Gates[1].edgeKey}))
assert(D:ValidateRoutes(graph) and G:Validate(graph))
-- A rejected definition is bounded and cannot silently produce fewer events.
local calls=0
defs.UTILITY.Place=function() calls=calls+1;return {cellKey='missing'} end
assert(not D:Plan(graph,{preview=defs.UTILITY.id}) and calls==D.MaxPlacementAttempts)
defs.UTILITY.Place=nil
assert(graphSignature(graph)==originalGraph,'Planning cannot alter unrelated maze/progression generation')
for _,callback in ipairs({'Place','Validate','CanResolve'}) do
 local def=callback=='CanResolve' and defs.BLOCKADE or defs.UTILITY
 local previous=def[callback]
 if callback=='Place' then
  def.Place=function(_,_,g) g.Progression.CoreCell.x=999;return table.Copy(utility) end
 else
  def[callback]=function(_,g) g.Cells[key(g.Start)].neighbors={};return true end
 end
 local accepted
 if callback=='CanResolve' then accepted=D:ValidatePlacement(graph,def,blockade)
 else accepted=D:Plan(graph,{preview=def.id}) end
 assert(not accepted and graphSignature(graph)==originalGraph,'Mutating '..callback..' must reject without touching canonical topology')
 def[callback]=function() error('injected '..callback..' failure') end
 if callback=='CanResolve' then accepted=D:ValidatePlacement(graph,def,blockade)
 else accepted=D:Plan(graph,{preview=def.id}) end
 assert(not accepted and graphSignature(graph)==originalGraph,'Throwing '..callback..' must reject cleanly')
 def[callback]=previous
end
local plannedCounts={}
defs.BLOCKADE.Place=function() return table.Copy(blockade) end
Slot.production=false
R.PopulationReady=true -- Exercise approved population with all four placement contracts.
for seed=1,64 do
 graph.MasterLevelSeed=seed
 local accepted,plan=D:Plan(graph,{enabled=true})
 if accepted then
  assert(#plan.instances==plan.selectedCount)
  local archetypes,placements={},{}
  for _,instance in ipairs(plan.instances) do
   assert(not archetypes[instance.archetype] and not placements[instance.cellKey])
   archetypes[instance.archetype],placements[instance.cellKey]=true,true
  end
  plannedCounts[plan.selectedCount]=true
 end
end
for n=1,4 do assert(plannedCounts[n],'Real full event plan supports count '..n) end
R.PopulationReady=false
assert(not D:Plan(graph,{enabled=true}),'Reset release gate must reject even the validated complete fixture catalog')
Slot.production=true;graph.MasterLevelSeed=Run.State.LevelSeed
-- Retire the representative catalog: production still has exactly one playable archetype.
for _,def in pairs(defs) do R.Definitions[def.id]=nil end
-- Admin preview traverses real Regenerate -> BuildCurrentLevel -> Generate ->
-- Progression Plan -> MazeBuilder wrapper -> Event Plan/Create -> native Use.
CreateConVar('lod_developer_mode','0')
commands.lod_event_preview_generate(a,nil,{'slot_machine'})
assert(F.nativeBuilds==0,'Developer mode required')
convars.lod_developer_mode.value='1';a.IsAdmin=function() return false end
commands.lod_event_preview_generate(a,nil,{'slot_machine'})
assert(F.nativeBuilds==0,'Admin required')
a.IsAdmin=function() return true end
commands.lod_event_preview_generate(a,nil,{'slot_machine'})
assert(F.nativeBuilds==1 and D.Context and not Run.State.Ranked)
assert(Run.State.BuildReport.eventMode=='preview' and Run.State.BuildReport.eventCount==1)
assert(Run.State.Graph.EventPlan==D.Context.plan and D.Context.plan.selectedCount==1)
local instance=D.Context.plan.instances[1]
local machine=assert(instance.entities[1]);a.pos,b.pos=machine:GetPos(),machine:GetPos()
assert(instance.state=='active' and D:IsCurrent(instance))
local function balance(p) return assert(Store:Read(p.id)).balance end
local function grant(p,amount,label)
 assert(Store:Transaction('fixture-funding:'..label,'test',{p.id},function(accounts) accounts[p.id].balance=accounts[p.id].balance+amount;return true end))
end
machine:Use(a)
assert(balance(a)==0 and not instance.claims[a.id] and a.lastChat:find('need 5'),'Insufficient funds neither spends nor claims')
grant(a,40,'a');grant(b,40,'b')
-- Inject failure after balance update, before ledger completion: actual SQLite
-- rolls back account/history, and deterministic retry produces the same face.
local expectedFace=LOD.RNG.New(LOD.Seeds.Derive(LOD.Seeds.DeriveLevel(Run.State.CampaignSeed,instance.level),'dungeon-events:slot-result:'..a.id)):Int(1,4)
WalletSQLFail('INSERT INTO lod_crypto_ledger')
F.now=F.now+2;machine:Use(a)
assert(balance(a)==40 and not instance.claims[a.id] and not Store:Receipt(Slot.EventKey(instance,a.id)))
assert(#Store:Recent(a.id)==0,'Failure rolls back account history too')
F.now=F.now+2;machine:Use(a)
local claim=assert(instance.claims[a.id]);local receipt=assert(claim.result)
assert(claim.state=='resolved' and receipt.face==expectedFace and receipt.stake==5)
assert(receipt.payout==(expectedFace==4 and 15 or 0) and balance(a)==40+receipt.net)
assert(a.walletSynced and feedback[#feedback].face==expectedFace)
local after=balance(a);machine:Use(a);assert(balance(a)==after and #Store:Recent(a.id)==1)
-- Reentrant interaction is locked before invoking definition code.
WalletSQLFail('COMMIT')
assert(not D:Interact(machine,b) and balance(b)==40 and not instance.claims[b.id])
assert(#Store:Recent(b.id)==0,'COMMIT failure rolls back debit, payout and history')
local originalInteract=Slot.Interact
Slot.Interact=function(d,i,p,id)
 local accepted,reason=d:Interact(machine,p);assert(not accepted and reason=='busy')
 return originalInteract(d,i,p,id)
end
assert(D:Interact(machine,b));Slot.Interact=originalInteract
assert(instance.claims[b.id].state=='resolved' and #Store:Recent(b.id)==1)
-- Each client gets only their receipt; unclaimed account gets an actionable row.
local newcomer=actor('76561198000000003');newcomer.SteamID64=function(self) return self.id end
newcomer.pos=machine:GetPos()
assert(D:Snapshot(a).events[1].claimed and D:Snapshot(a).events[1].result.face==expectedFace)
assert(not D:Snapshot(newcomer).events[1].claimed and not D:Snapshot(newcomer).events[1].result)
local reconnect=actor(a.id);reconnect.SteamID64=function(self) return self.id end;reconnect.pos=machine:GetPos()
hooks.LOD_DungeonEventSnapshot(reconnect);assert(#timers>0);table.remove(timers)()
assert(packets[#packets].recipient==reconnect and packets[#packets].body.events[1].claimed)
-- Clear volatile claim memory to reproduce reconnect/cache-loss receipt hydration.
instance.claims={}
assert(D:Snapshot(reconnect).events[1].claimed and not D:Interact(machine,reconnect) and balance(a)==after)
-- Server-owned identity, distance, role, life and tracked entity checks.
for _,mutate in ipairs({
 function() newcomer.active=false end,function() newcomer.soldier=true end,
 function() newcomer.dead=true end,function() newcomer.pos=Vector(900000,0,0) end
}) do
 newcomer.active=true;newcomer.soldier=false;newcomer.dead=false;newcomer.pos=machine:GetPos()
 mutate();assert(not D:Interact(machine,newcomer) and not instance.claims[newcomer.id])
end
newcomer.active=true;newcomer.soldier=false;newcomer.dead=false;newcomer.pos=machine:GetPos()
F.traceBlocked=true;assert(not D:Interact(machine,newcomer));F.traceBlocked=false
for _,field in ipairs({'deploymentComplete','inStaging','eliminated','lives'}) do
 local before=newcomer.ps[field]
 newcomer.ps[field]=field=='deploymentComplete' and false or field=='lives' and 0 or true
 -- Lua's and/or idiom cannot retain false.
 if field=='deploymentComplete' then newcomer.ps[field]=false end
 assert(not D:Interact(machine,newcomer));newcomer.ps[field]=before
end
Run.State.SimulationFrozen=true;assert(not D:Interact(machine,newcomer));Run.State.SimulationFrozen=false
Run.State.CampaignClock={deadline=F.now-1};assert(not D:Interact(machine,newcomer));Run.State.CampaignClock=nil
local forged=ents.Create('fixture_event');forged.LODEventInstance=instance;forged:SetPos(machine:GetPos())
assert(not D:Interact(forged,newcomer))
-- Prove both the winning payout and losing debit through the actual transaction.
local covered={}
for suffix=10,80 do
 local id=string.format('7656119%010d',suffix*104729)
 local face=LOD.RNG.New(LOD.Seeds.Derive(LOD.Seeds.DeriveLevel(Run.State.CampaignSeed,instance.level),'dungeon-events:slot-result:'..id)):Int(1,4)
 local kind=face==4 and 'win' or 'loss'
 if not covered[kind] then
  local p=actor(id);p.SteamID64=function(self) return self.id end;p.pos=machine:GetPos()
  grant(p,10,id);local accepted,result=D:Interact(machine,p)
  assert(accepted and result.face==face and balance(p)==(kind=='win' and 20 or 5))
  covered[kind]=true
 end
 if covered.win and covered.loss then break end
end
assert(covered.win and covered.loss)
-- Receiver and actual prompt distinguish available, settled and replacement state.
local texts={}
LOD.UI={};LocalPlayer=function() return reconnect end
reconnect.GetEyeTrace=function() return {Entity=machine} end
input={LookupBinding=function() return 'e' end}
draw={SimpleTextOutlined=function(text) texts[#texts+1]=text end}
ScrW=function() return 1280 end;ScrH=function() return 720 end
net.ReadTable=function() return table.Copy(packets[#packets].body) end
dofile(root..'cl_dungeon_events.lua')
D:SyncPlayer(reconnect);receivers.LOD_DungeonEvents();hooks.LOD_DungeonEventPrompt()
assert(texts[#texts]:find('PLAYED') and texts[2]:find('1d4'))
LocalPlayer=function() return newcomer end;newcomer.GetEyeTrace=reconnect.GetEyeTrace
D:SyncPlayer(newcomer);receivers.LOD_DungeonEvents();texts={};hooks.LOD_DungeonEventPrompt()
assert(texts[#texts]:find('WAGER 5'))
-- Same-dungeon rebuilding creates new entities, while durable account ledger
-- prevents a second bet. Stale callback/entity access is rejected immediately.
local oldInstance,oldMachine=instance,machine
D.NextPreview='slot_machine';assert(Run:BuildCurrentLevel(Run.State.LevelSeed))
assert(oldInstance.state=='cleaned' and not IsValid(oldMachine) and not D:IsCurrent(oldInstance))
assert(not D:Interact(oldMachine,a))
instance=D.Context.plan.instances[1];machine=instance.entities[1];a.pos=machine:GetPos()
assert(D:Snapshot(a).events[1].claimed and not D:Interact(machine,a) and balance(a)==after)
-- The actual generation callback handles native Create failure by clearing every
-- partial entity and refusing BuildReady. A subsequent fresh attempt succeeds.
local create=Slot.Create
Slot.Create=function(d,i,g) create(d,i,g);error('injected native setup failure') end
local createdBefore=#created
D.NextPreview='slot_machine';assert(not Run:BuildCurrentLevel(Run.State.LevelSeed))
assert(not D.Context and not Run.State.BuildReady and F.nativeCleanups>0)
for i=createdBefore+1,#created do assert(not IsValid(created[i]),'Partial native entity leaked') end
Slot.Create=create
D.NextPreview='slot_machine';assert(Run:BuildCurrentLevel(Run.State.LevelSeed))
instance=D.Context.plan.instances[1];machine=instance.entities[1]
-- Invalidating the state/graph or any dungeon/campaign identity rejects callbacks.
local state=Run.State
for _,field in ipairs({'Graph','RunId','Level','LevelSeed','CampaignEpoch'}) do
 local before=state[field];state[field]=field=='Graph' and {} or tostring(before)..':replacement'
 assert(not D:IsCurrent(instance),'Stale '..field..' binding accepted')
 assert(not Slot.Interact(D,instance,a,a.id),'Direct deferred reward callback accepted stale '..field)
 state[field]=before
end
Run.State={};for k,v in pairs(state) do Run.State[k]=v end
assert(not D:IsCurrent(instance));Run.State=state
assert(D:Resolve(instance) and instance.state=='resolved')
assert(not D:Resolve(instance) and not D:Interact(machine,a),'Shared resolution and interaction are idempotent')
D:Cleanup('test teardown');D:Cleanup('duplicate teardown')
assert(instance.state=='cleaned' and not IsValid(machine) and not D:Interact(machine,a))
D:SyncPlayer(a);receivers.LOD_DungeonEvents();assert(#LOD.DungeonEvents.events==0,'Client teardown clears old dungeon rows')
local token=LOD.DungeonEvents.token
net.ReadTable=function() return {token=tostring(tonumber(token)-1),events={{id='old-dungeon'}}} end
receivers.LOD_DungeonEvents();assert(LOD.DungeonEvents.token==token and #LOD.DungeonEvents.events==0,'Delayed old snapshot cannot resurrect cleared dungeon')
-- One selected reward archetype can own two independently validated children.
-- Registration bounds reject truncation/coercion and unsupported blocker groups.
for _,value in ipairs({0,3,1.5,'2',false}) do
 assert(not pcall(function() R:Register({id='bad_members',contract='REWARD',nonblocking=true,maxInstances=value,Create=lifecycle.Create,Interact=lifecycle.Interact}) end))
end
for _,contract in ipairs({'UTILITY','BLOCKADE','HAZARD'}) do
 assert(not pcall(function() R:Register({id='bad_members',contract=contract,nonblocking=true,maxInstances=2,Create=lifecycle.Create,Interact=lifecycle.Interact}) end))
end
assert(not pcall(function() R:Register({id='bad_members',contract='REWARD',maxInstances=2,Create=lifecycle.Create,Interact=lifecycle.Interact}) end))
local multi=R:Register({id='fixture_multi',contract='REWARD',nonblocking=true,maxInstances=2,Create=lifecycle.Create,Interact=lifecycle.Interact})
local one,two,twoSeed
local originalMemberSeed=graph.MasterLevelSeed
local singletonBefore=select(2,D:Plan(graph,{preview='slot_machine'}))
for seed=1,32 do
 graph.MasterLevelSeed=seed
 local accepted,plan=D:Plan(graph,{preview=multi.id});assert(accepted)
 local expected=LOD.RNG.New(LOD.Seeds.Derive(LOD.Seeds.Derive(seed,'dungeon-events:archetype:'..multi.id..':v1'),'instance-count:v1')):Int(1,2)
 assert(plan.selectedCount==1 and #plan.instances==expected)
 local acceptedAgain,again=D:Plan(graph,{preview=multi.id});assert(acceptedAgain)
 for index,child in ipairs(plan.instances) do
  assert(child.id=='1:fixture_multi:'..index and child.memberIndex==index and child.memberCount==expected)
  assert(child.id==again.instances[index].id and child.cellKey==again.instances[index].cellKey and child.seed==again.instances[index].seed)
  assert(D:ValidatePlacement(graph,multi,child.placement) and D:ValidateRoutes(graph))
 end
 if expected==1 then one=plan else
  two,twoSeed=plan,seed
  assert(plan.instances[1].cellKey~=plan.instances[2].cellKey and plan.instances[1].seed~=plan.instances[2].seed)
 end
end
assert(one and two,'Both finite member counts must occur')
graph.MasterLevelSeed=originalMemberSeed
local singletonAfter=select(2,D:Plan(graph,{preview='slot_machine'}))
assert(singletonBefore.instances[1].id=='1:slot_machine' and singletonBefore.instances[1].id==singletonAfter.instances[1].id
 and singletonBefore.instances[1].cellKey==singletonAfter.instances[1].cellKey and singletonBefore.instances[1].seed==singletonAfter.instances[1].seed,
 'Member count and placement streams must preserve existing singleton identities and placements')
graph.MasterLevelSeed=twoSeed
local placementCalls=0
multi.Place=function() placementCalls=placementCalls+1;return table.Copy(two.instances[1].placement) end
assert(not D:Plan(graph,{preview=multi.id}) and placementCalls==1+D.MaxPlacementAttempts,
 'Rejecting second child exhausts its finite budget and rejects the whole archetype; never truncate to one')
multi.Place=nil
Run.State.Graph=graph;Run.State.BuildReady=true
local createCalls=0
multi.Create=function(d,i)
 createCalls=createCalls+1
 local entity=lifecycle.Create(d,i);assert(d:Track(i,entity))
 if i.memberIndex==2 then error('injected second-member creation failure') end
 return entity
end
local priorEntities=#created
assert(not D:Activate(graph,two) and createCalls==2 and not D.Context)
for index=priorEntities+1,#created do assert(not IsValid(created[index]),'Second-member failure leaked child entity') end
multi.Create=lifecycle.Create
local accepted,retry=D:Plan(graph,{preview=multi.id});assert(accepted and #retry.instances==2 and D:Activate(graph,retry))
local rows=D:Snapshot(a)
assert(rows.selectedCount==1 and #rows.events==2)
for index,row in ipairs(rows.events) do assert(row.memberIndex==index and row.memberCount==2 and row.id==retry.instances[index].id) end
local first,second=retry.instances[1],retry.instances[2]
local firstEntity,secondEntity=first.entities[1],second.entities[1]
a.pos=first.entities[1]:GetPos();assert(D:Interact(first.entities[1],a))
assert(D:Snapshot(a).events[1].claimed and not D:Snapshot(a).events[2].claimed,'Child claims must remain independent')
a.pos=second.entities[1]:GetPos();assert(D:Interact(second.entities[1],a))
assert(#D:Snapshot(newcomer).events==2 and not D:Snapshot(newcomer).events[1].claimed and not D:Snapshot(newcomer).events[2].claimed)
assert(D:Snapshot(reconnect).events[1].claimed and D:Snapshot(reconnect).events[2].claimed,'Reconnect must preserve each independent child claim')
D:Cleanup('multi test teardown')
assert(first.state=='cleaned' and second.state=='cleaned' and not IsValid(firstEntity) and not IsValid(secondEntity) and not D:IsCurrent(second))
R.Definitions[multi.id]=nil
graph.MasterLevelSeed=Run.State.LevelSeed
assert(graphSignature(graph)==originalGraph,'Multi placements must preserve real maze/progression topology')
print('DUNGEON_EVENTS_PASS: exact deterministic 1d4/unique four-contract catalog, bounded multi-member REWARD identity/placement/rejection/cleanup/snapshots, real full plans, graph/route/placement rejection and bounds; real generation/native Use/SQLite rollback-retry/replay; lifecycle identity/cleanup, reconnect snapshots and client prompts')
