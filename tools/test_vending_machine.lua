-- Real generation, native Use callback, inventory and SQLite settlement.
-- Source entities, transport and traces are the engine boundaries doubled here.
local equipment=dofile('tools/test_equipment_economy_runtime.lua')
local F=dofile('tools/dungeon_event_fixture.lua')({lod=LOD,run=equipment.Run})
local root,E,Run,D,R,Store=F.root,LOD.Equipment,F.Run,F.D,F.R,F.Store
for i=#F.online,1,-1 do table.remove(F.online,i) end
local function actor(id)
 local p=equipment.actor(id)
 p.ps.deploymentComplete,p.ps.lives=true,3
 function p:SteamID64() return self.id end
 function p:Nick() return self.id end
 function p:IsAdmin() return true end
 function p:GetPos() return self.pos or Vector() end
 p.EyePos,p.WorldSpaceCenter=p.GetPos,p.GetPos
 p.ChatPrint=function(self,text) self.lastChat=text end
 F.online[#F.online+1]=p
 return p
end
net.WriteUInt,net.WriteFloat,net.WriteBool=F.noop,F.noop,F.noop
LOD.SnapshotDelivery={Queue=F.noop,Invalidate=F.noop}
dofile(root..'sv_crypto_director.lua')
local C=LOD.CryptoDirector
C.Sync=function(_,p) p.walletSynced=true end
dofile(root..'sv_event_locked_chest.lua')
dofile(root..'sv_event_treasure_chest.lua')
dofile(root..'sv_event_vending_machine.lua')
local V=assert(LOD.EventVendingMachine)
assert(V.Price==10 and V.Item=='healing_potion' and V.Quantity==1)
assert(E.Definitions[V.Item].maxStack==3 and E.Definitions[V.Item].amount==25)
assert(#R:Catalog()==4 and R.PopulationReady==false)
local seen={}
for seed=1,128 do
 local selected,n=R:Select(seed)
 local again,m=R:Select(seed)
 assert(n>=1 and n<=4 and n==#selected and n==m and table.concat(selected,',')==table.concat(again,','))
 local unique={}
 for _,id in ipairs(selected) do assert(not unique[id]);unique[id]=true end
 seen[n]=true
end
for n=1,4 do assert(seen[n],'Four production definitions must exercise exact 1d4 counts') end
local selectedBefore=table.concat(R:Select(92831),',')
for _=1,99 do math.random() end
assert(table.concat(R:Select(92831),',')==selectedBefore,'Selection cannot consume global randomness')
local graphBefore=F.graphSignature(Run.State.Graph)
local ready,reason=D:Plan(Run.State.Graph,{enabled=true})
assert(not ready and reason:find('gated') and F.graphSignature(Run.State.Graph)==graphBefore)
local function account(p) return assert(Store:Read(p.id)) end
local function count(p) local item=E:Ensure(p.ps).items[V.Item];return item and item.count or 0 end
local function same(a,b) return WalletJSONEncode(a)==WalletJSONEncode(b) end
local credits=0
local function credit(p,n)
 credits=credits+1
 assert(Store:Transaction('vending:fixture:'..credits,'fixture',{p.id},function(accounts)
  accounts[p.id].balance=accounts[p.id].balance+n;return true,{}
 end))
end
local function near(p,ent) p.pos=ent:GetPos() end
local function build(seed)
 D.NextPreview='vending_machine'
 assert(Run:BuildCurrentLevel(seed or Run.State.LevelSeed))
 assert(Run.State.BuildReport.eventMode=='preview')
 local plan=D.Context.plan
 assert(plan.selectedCount==1 and #plan.instances==1)
 local instance=plan.instances[1]
 assert(instance.archetype=='vending_machine' and instance.contract=='UTILITY')
 assert(LOD.MazeGenerator:Validate(Run.State.Graph) and Run.State.Graph.Progression.Validation.valid)
 assert(instance.entities[1] and IsValid(instance.entities[1]))
 return instance,instance.entities[1]
end
local instance,machine=build(930117)
local p=actor('76561198200000001');near(p,machine);p.hp=30
-- Native Use reaches the real admission and feedback path. No charge or free
-- reward when funds are missing; topping up allows a later successful retry.
machine:Use(p)
assert(count(p)==0 and account(p).balance==0 and not V.Claim(instance,p.id))
assert(p.lastChat and p.lastChat:find('10'))
credit(p,30)
local original=E:Ensure(p.ps)
local add=E.AddConsumable
for _,kind in ipairs({'false','throw'}) do
 E.AddConsumable=function(self,state,...)
  assert(state~=original,'Reward admission must use detached inventory')
  state.items.injected={definitionId='healing_potion',count=1}
  if kind=='throw' then error('injected consumable failure') end
  return false
 end
 assert(not D:Interact(machine,p) and p.ps.equipment==original and not original.items.injected)
 assert(count(p)==0 and account(p).balance==30 and not V.Claim(instance,p.id))
end
E.AddConsumable=add
-- SQL failures before and after reference application preserve both wallet and
-- the exact original inventory reference, including failed COMMIT.
for _,pattern in ipairs({'SELECT body FROM lod_crypto_ledger','SELECT body FROM lod_crypto_accounts',
 'BEGIN IMMEDIATE','SELECT event FROM lod_crypto_ledger','INSERT INTO lod_crypto_history',
 'INSERT OR REPLACE INTO lod_crypto_accounts','INSERT INTO lod_crypto_ledger','COMMIT'}) do
 WalletSQLFail(pattern)
 assert(not D:Interact(machine,p),'Injected SQL failure accepted: '..pattern)
 assert(p.ps.equipment==original and count(p)==0 and account(p).balance==30 and not V.Claim(instance,p.id),pattern)
end
machine:Use(p)
assert(count(p)==1 and account(p).balance==20 and V.Claim(instance,p.id))
assert(p.hp==30,'Purchase grants an item, never immediate healing')
local committed=table.Copy(account(p));original=p.ps.equipment
assert(not D:Interact(machine,p) and p.ps.equipment==original and count(p)==1 and same(account(p),committed))
-- The purchased unit uses the normal drink/negative-cure authority. Consuming
-- stock does not erase the immutable receipt or permit another purchase.
p:Give(E.WeaponClass);p:SelectWeapon(E.WeaponClass)
assert(E:Equip(p.ps.equipment,V.Item,'throwable'))
local health=p.hp
assert(E:Use(p,'drink') and count(p)==0 and p.hp==math.min(p.max,health+25))
assert(not D:Interact(machine,p) and count(p)==0 and same(account(p),committed))
-- Full potion stack fails without spending. Wearable bag capacity is unrelated.
local full=actor('76561198200000002');near(full,machine);credit(full,20)
local inventory=E:Ensure(full.ps)
assert(E:AddConsumable(inventory,V.Item,3))
for i=1,E:StorageCapacity(inventory) do assert(E:StoreWearable(inventory,E:Generate(31000+i,1,'ring','vending-bag:'..i))) end
assert(not D:Interact(machine,full) and count(full)==3 and account(full).balance==20 and not V.Claim(instance,full.id))
assert(E:Consume(inventory,V.Item))
assert(D:Interact(machine,full) and count(full)==3 and account(full).balance==10)
assert(E:StoredEquipmentCount(full.ps.equipment)==E:StorageCapacity(inventory))
-- A final participant guard must reject stale inventory, Hero, deployment,
-- identity and campaign state after all SQL writes but before COMMIT.
local query=sql.Query
local mutations={
 function(a) a.ps.equipmentLifeSerial=(a.ps.equipmentLifeSerial or 0)+1 end,
 function(a) a.soldier=true end,
 function(a) a.ps.equipment=table.Copy(a.ps.equipment) end,
 function(a) local replacement={};for k,v in pairs(a.ps) do replacement[k]=v end;a.ps=replacement end,
 function(a) a.ps.deploymentComplete=false end,
 function(a) a.id='76561198209999999' end,
 function(a) a.ps.equipment.items.chest_key={definitionId='chest_key',count=1} end,
 function(a) a.active=false end,
 function(a) a.ps.inStaging=true end,
 function(a) a.ps.eliminated=true end,
 function(a) a.ps.lives=0 end,
 function(a) a.hp=0 end,
 function() Run.State.SimulationFrozen=true end,
 function() Run.State.CampaignClock={deadline=F.now-1} end,
 function() machine.valid=false end,
 function() machine.LODEventInstance={} end,
 function() Run.State.BuildReady=false end,
 function() Run.State.CampaignEpoch=Run.State.CampaignEpoch+1 end,
 function() local replacement={};for k,v in pairs(Run.State) do replacement[k]=v end;Run.State=replacement end
}
for index,mutate in ipairs(mutations) do
 local a=actor(string.format('76561198203%06d',index));near(a,machine);credit(a,10)
 local id,old=a.id,E:Ensure(a.ps)
 local run,epoch=Run.State,Run.State.CampaignEpoch
 local changed=false
 sql.Query=function(statement)
  local result=query(statement)
  if not changed and statement:find('INSERT INTO lod_crypto_ledger',1,true) then changed=true;mutate(a) end
  return result
 end
 assert(not D:Interact(machine,a),'Stale vending participant accepted: '..index)
 sql.Query=query
 assert(changed and not old.items[V.Item] and count(a)==0)
 assert(assert(Store:Read(id)).balance==10 and not V.Claim(instance,id))
 Run.State=run;Run.State.CampaignEpoch=epoch;Run.State.BuildReady=true
 Run.State.SimulationFrozen,Run.State.CampaignClock=nil,nil
 machine.valid,machine.LODEventInstance=true,instance
end
-- Postcommit presentation failure and reentrant interactions cannot undo or
-- duplicate a settled purchase. Another account retains its independent stock.
local feedback=actor('76561198200000003');near(feedback,machine);credit(feedback,20)
local sync=C.Sync
C.Sync=function(_,who)
 assert(who==feedback)
 local ok=D:Interact(machine,who);assert(not ok)
 error('injected wallet presentation failure')
end
assert(D:Interact(machine,feedback))
C.Sync=sync
assert(count(feedback)==1 and account(feedback).balance==10 and V.Claim(instance,feedback.id))
assert(not D:Interact(machine,feedback) and count(feedback)==1 and account(feedback).balance==10)
-- Clear volatile claims and reconnect the real database; immutable receipts
-- survive replacement Heroes and different same-dungeon layout seeds.
instance.claims={};WalletSQLReconnect()
local replacement=actor(p.id);near(replacement,machine)
assert(not D:Interact(machine,replacement) and count(replacement)==0 and account(replacement).balance==20)
local oldInstance,oldMachine=instance,machine
instance,machine=build(121817)
assert(not IsValid(oldMachine) and not D:IsCurrent(oldInstance))
assert(not V.Interact(D,oldInstance,replacement,replacement.id))
near(replacement,machine)
assert(not D:Interact(machine,replacement) and V.Claim(instance,replacement.id) and count(replacement)==0)
-- Recipient-specific late join snapshots include price, stack and wallet state.
F.hooks.LOD_DungeonEventSnapshot(replacement);table.remove(F.timers)()
local packet=F.packets[#F.packets]
assert(packet.recipient==replacement and packet.body.events[1].claimed)
local details=packet.body.events[1].details
assert(details.price==10 and details.item==V.Item and details.quantity==1 and details.maxStack==3 and details.held==0 and details.balance==20)
local fresh=actor('76561198200000004');near(fresh,machine);credit(fresh,10)
local snapshot=D:Snapshot(fresh)
assert(not snapshot.events[1].claimed and snapshot.events[1].details.balance==10)
local rendered={};LOD.UI={};E.HasSnapshot=false
input={LookupBinding=function() return 'e' end}
draw={SimpleTextOutlined=function(text) rendered[#rendered+1]=text end}
ScrW=function() return 1280 end;ScrH=function() return 720 end
net.ReadTable=function() return table.Copy(F.packets[#F.packets].body) end
dofile(root..'cl_dungeon_events.lua')
local function prompt(a)
 near(a,machine);LocalPlayer=function() return a end;a.GetEyeTrace=function() return {Entity=machine} end
 D:SyncPlayer(a);F.receivers.LOD_DungeonEvents();rendered={};F.hooks.LOD_DungeonEventPrompt()
 assert(rendered[1]=='DEBBIE VENDING')
 return table.concat(rendered,' / ')
end
assert(prompt(replacement):find('PURCHASED'))
assert(prompt(fresh):find('10') and prompt(fresh):find('BUY'))
assert(E:AddConsumable(E:Ensure(fresh.ps),V.Item,3))
assert(prompt(fresh):lower():find('full'))
assert(prompt(actor('76561198200000005')):find('10'))
-- Current equipment/wallet packets take precedence over the older event row.
E.HasSnapshot=true;E.Snapshot={items={}}
LOD.Wallet={Snapshot={balance=10}}
assert(prompt(fresh):find('BUY'))
E.Snapshot.items.healing_potion={count=3}
assert(prompt(fresh):lower():find('full'))
E.Snapshot.items={};LOD.Wallet.Snapshot.balance=0
assert(prompt(fresh):find('You need 10'))
E.HasSnapshot=false;LOD.Wallet=nil
-- New dungeons/campaigns create new entitlements and remove stale entities.
local staleInstance,staleMachine=instance,machine
Run.State.Level=Run.State.Level+1
instance,machine=build(971231)
assert(not IsValid(staleMachine) and not V.Interact(D,staleInstance,replacement,replacement.id))
assert(not V.Claim(instance,replacement.id))
near(replacement,machine)
assert(D:Interact(machine,replacement) and count(replacement)==1 and account(replacement).balance==10)
local replacedInstance,replacedMachine=instance,machine
Run.State.RunId='vending:replacement';Run.State.CampaignEpoch=Run.State.CampaignEpoch+1;Run.State.Level=1
instance,machine=build(129981)
assert(not IsValid(replacedMachine) and not V.Interact(D,replacedInstance,replacement,replacement.id))
assert(not V.Claim(instance,replacement.id))
D:Cleanup('vending test complete')
assert(not IsValid(machine) and not D:IsCurrent(instance) and not V.Interact(D,instance,replacement,replacement.id))
print('Vending production generation, atomic wallet/item settlement, retries, replay, snapshots and cleanup passed')
