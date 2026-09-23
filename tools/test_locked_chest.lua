-- Real equipment acquisition/consumption/RPG derivation with the same native
-- event boundaries and generation pipeline exercised by Dungeon Events.
local equipment=dofile('tools/test_equipment_economy_runtime.lua')
local F=dofile('tools/dungeon_event_fixture.lua')({lod=LOD,run=equipment.Run})
local root,E,Run,D,R=F.root,LOD.Equipment,F.Run,F.D,F.R
local CPS,Rules=LOD.CharacterProgressionSystem,LOD.RPGAbilityRules
local function actor(id,class,level)
 local p=equipment.actor(id)
 p.ps.deploymentComplete,p.ps.lives=true,3
 p.ps.progressionState.classId=class or 'fighter'
 p.ps.progressionState.level=level or 1
 CPS:_RecomputeProgressionState(p.ps.progressionState)
 function p:SteamID64() return self.id end
 function p:IsAdmin() return true end
 function p:GetPos() return self.pos or Vector() end
 p.EyePos,p.WorldSpaceCenter=p.GetPos,p.GetPos
 p.ChatPrint=function(self,text) self.lastChat=text end
 F.online[#F.online+1]=p
 return p
end
-- F's initial simple players are not used by equipment gameplay.
for i=#F.online,1,-1 do table.remove(F.online,i) end
local fighter=actor('76561198000000101','fighter')
-- Shared bag-only consumable semantics, finite stack, and genuine world reward conversion.
local keys=E:Ensure(fighter.ps)
assert(E:AddConsumable(keys,'chest_key',9) and keys.items.chest_key.count==9)
assert(not keys.slots.throwable and not E:Equip(keys,'chest_key','throwable'))
assert(not E:AddConsumable(keys,'chest_key',1) and keys.items.chest_key.count==9)
assert(E:Consume(keys,'chest_key') and keys.items.chest_key.count==8)
assert(E:Discard(keys,'chest_key') and not keys.items.chest_key)
assert(E:AddConsumable(keys,'chest_key',9))
local pickup=ents.Create('lod_loot_pickup')
pickup.LODLootOwnerIdentity,pickup.LODLootLevelSeed=fighter.id,Run.State.LevelSeed
pickup.LODLootStaticId,pickup.LODLootKind='full-key-stack','consumable'
pickup.LODLootPayload={itemId='chest_key'}
assert(not LOD.LootDirector:Collect(pickup,fighter) and not pickup.LODCollected)
assert(not fighter.ps.loot.consumedStatic[pickup.LODLootStaticId] and keys.items.chest_key.count==9)
assert(E:Consume(keys,'chest_key') and LOD.LootDirector:Collect(pickup,fighter))
assert(pickup.LODCollected and fighter.ps.loot.consumedStatic[pickup.LODLootStaticId] and keys.items.chest_key.count==9)
assert(not LOD.LootDirector:Collect(pickup,fighter),'Consumed pickup cannot be claimed twice')
assert(E:Discard(keys,'chest_key'))
local drops={}
for i=1,1024 do
 local source='key-drop-proof-'..i
 local seed=LOD.Seeds.Derive(Run.State.CampaignSeed,E:RewardKey(fighter.id,source))
 local function chance(label,p) return LOD.RNG.New(LOD.Seeds.Derive(seed,label)):Chance(p) end
 local expected
 if chance('summon-card-v1',1/8) then expected='summon_card'
 elseif chance('resurrection-feather-v1',1/8) then expected='resurrection_feather'
 elseif chance('magic-hourglass-v1',1/16) then expected='magic_hourglass'
 else
  local conversion=LOD.RNG.New(LOD.Seeds.Derive(seed,'equipment-conversion-v2'))
  if conversion:Chance(.35) then expected=(not E.BombTypes or conversion:Chance(.35)) and 'stink_bomb' or conversion:Pick(E.BombTypes)
  elseif chance('chest-key-v1',1/16) then expected='chest_key'
  else expected='healing_potion' end
 end
 local kind,payload=E:PrepareReward(fighter.id,'consumable',{itemId='healing_potion'},{equipmentEligible=true,staticId=source})
 assert(kind=='consumable' and payload.itemId==expected,'Named key stream changed an existing special/bomb outcome')
 assert(LOD.LootDirector:_PreparedRewardValid(kind,payload))
 drops[payload.itemId]=(drops[payload.itemId] or 0)+1
 local _,again=E:PrepareReward(fighter.id,'consumable',{itemId='healing_potion'},{equipmentEligible=true,staticId=source})
 assert(again.itemId==payload.itemId)
 local _,fixed=E:PrepareReward(fighter.id,'consumable',{itemId='healing_potion'},{staticId=source})
 assert(fixed.itemId=='healing_potion','Authored non-eligible drops stay fixed')
end
assert((drops.chest_key or 0)>10 and drops.summon_card and drops.resurrection_feather and drops.magic_hourglass)
dofile(root..'sv_event_locked_chest.lua')
local Chest=assert(LOD.EventLockedChest)
assert(not R:Select(1),'Two playable archetypes still cannot satisfy full 1d4 population')
local function keyCount(p) local x=E:Ensure(p.ps).items.chest_key;return x and x.count or 0 end
local function stored(p) return E:StoredEquipmentCount(E:Ensure(p.ps)) end
local function putKeys(p,n) assert(E:AddConsumable(E:Ensure(p.ps),'chest_key',n)) end
local function near(p,ent) p.pos=ent:GetPos();function p:KeyDown() return self.pick==true end end
local function same(a,b) return WalletJSONEncode(a)==WalletJSONEncode(b) end
local function build(seed)
 D.NextPreview='locked_chest'
 assert(Run:BuildCurrentLevel(seed or Run.State.LevelSeed))
 local instance=assert(D.Context.plan.instances[1]);assert(instance.archetype=='locked_chest')
 assert(instance.contract=='REWARD' and Run.State.BuildReport.eventMode=='preview')
 local entity=assert(instance.entities[1]);return instance,entity
end
local instance,chest=build()
near(fighter,chest)
chest:Use(fighter)
assert(stored(fighter)==0 and keyCount(fighter)==0 and not Chest.Claim(instance,fighter.id))
putKeys(fighter,2)
local inventory=E:Ensure(fighter.ps)
local predicted=Chest.Reward(instance,fighter.id)
assert(E:ValidateWearable(predicted),'Chest reward uses real procedural item validation')
-- Full bag: no debit/claim/reward and no silent replacement of existing gear.
local capacity=E:StorageCapacity(inventory)
for i=1,capacity do assert(E:StoreWearable(inventory,E:Generate(5000+i,1,'ring','chest-capacity:'..i))) end
local full=table.Copy(inventory)
assert(not D:Interact(chest,fighter) and same(inventory,full) and not Chest.Claim(instance,fighter.id))
local remove=next(inventory.items)
while remove=='chest_key' do remove=next(inventory.items,remove) end
assert(E:Discard(inventory,remove))
-- Failure after staged key consumption cannot alter the live inventory.
local store=E.StoreWearable
E.StoreWearable=function() return false end
local before=table.Copy(inventory)
assert(not D:Interact(chest,fighter) and same(inventory,before) and keyCount(fighter)==2)
E.StoreWearable=store
-- A consumed staged key followed by an exception also rolls back the entire attempt.
E.StoreWearable=function() error('injected item admission failure') end
assert(not D:Interact(chest,fighter) and same(inventory,before) and not Chest.Claim(instance,fighter.id))
E.StoreWearable=store
local accepted,receipt=D:Interact(chest,fighter)
assert(accepted and keyCount(fighter)==1 and stored(fighter)==capacity)
assert(Chest.Claim(instance,fighter.id) and E:Ensure(fighter.ps).items[predicted.id])
local claimed=table.Copy(E:Ensure(fighter.ps))
assert(not D:Interact(chest,fighter) and same(E:Ensure(fighter.ps),claimed),'Duplicate use cannot debit or award twice')
-- Native feedback must identify the chest, not the Slots implementation.
chest:Use(fighter);assert(not fighter.lastChat or not fighter.lastChat:find('SLOTS'))
-- Rogue success probabilities come from the actual RPG derivation, not a second
-- percentage table. Fresh accounts search deterministic natural success/failure.
local rogueLow=actor('76561198000000201','rogue',1)
local rogueHigh=actor('76561198000000202','rogue',20)
assert(Rules:Derived(rogueLow).arcaneItemUseChance==.05)
assert(Rules:Derived(rogueHigh).arcaneItemUseChance==.95)
local failedRogue,successfulRogue
for suffix=1,64 do
 local id=string.format('7656118%010d',suffix*104729)
 local p=actor(id,'rogue',suffix%2==0 and 20 or 1);near(p,chest)
 local accepted=D:Interact(chest,p)
 if accepted then
  assert(stored(p)==1 and keyCount(p)==0 and Chest.Claim(instance,id))
  successfulRogue=successfulRogue or p
 else
  assert(stored(p)==0 and keyCount(p)==0 and not Chest.Claim(instance,id))
  failedRogue=failedRogue or p
 end
 if failedRogue and successfulRogue then break end
end
assert(failedRogue and successfulRogue,'Natural attempts cover both Rogue outcomes')
local failedRecord=assert(Chest.Record(instance,failedRogue.id,false))
local frozenFailure=table.Copy(failedRecord)
for _=1,3 do assert(not D:Interact(chest,failedRogue)) end
assert(same(Chest.Record(instance,failedRogue.id,false),frozenFailure),'Failed lockpick cannot roll again')
-- Reconnect and replacement Hero see the same account attempt/claim records.
local reconnect=actor(failedRogue.id,'rogue',20);near(reconnect,chest)
assert(not D:Interact(chest,reconnect) and stored(reconnect)==0,'Higher-level replacement cannot restore failed lockpick')
assert(same(Chest.Record(instance,reconnect.id,false),frozenFailure))
local claimedReconnect=actor(fighter.id,'fighter');near(claimedReconnect,chest);putKeys(claimedReconnect,1)
assert(not D:Interact(chest,claimedReconnect) and keyCount(claimedReconnect)==1 and stored(claimedReconnect)==0)
-- Same dungeon, new graph/layout seed: attempt/claim bindings survive; old native
-- entity and deferred callbacks are rejected by the shared lifecycle authority.
local oldInstance,oldChest=instance,chest
instance,chest=build(831993)
assert(not IsValid(oldChest) and not D:IsCurrent(oldInstance))
assert(not Chest.Interact(D,oldInstance,fighter,fighter.id))
near(reconnect,chest);near(claimedReconnect,chest)
assert(not D:Interact(chest,reconnect) and same(Chest.Record(instance,reconnect.id,false),frozenFailure))
assert(not D:Interact(chest,claimedReconnect) and stored(claimedReconnect)==0 and keyCount(claimedReconnect)==1)
-- Failed Rogue attempt does not destroy a key. The later key path remains legal.
putKeys(reconnect,1)
assert(D:Interact(chest,reconnect) and keyCount(reconnect)==0 and stored(reconnect)==1)
assert(not D:Interact(chest,reconnect) and stored(reconnect)==1)
-- Full capacity prevents even a Rogue roll. A staged success retained across a
-- later lifecycle interruption can be claimed without rolling or consuming keys.
local pending
for suffix=100,180 do
 local id=string.format('7656118%010d',suffix*104729)
 local seed=LOD.Seeds.Derive(LOD.Seeds.DeriveLevel(Run.State.CampaignSeed,instance.level),'dungeon-events:locked-chest:lockpick:'..id)
 if LOD.RNG.New(seed):Int(1,100)<=95 then pending=actor(id,'rogue',20);break end
end
assert(pending);near(pending,chest);pending.pick=true;putKeys(pending,1)
local pendingInventory=E:Ensure(pending.ps);pendingInventory.capacityBonus=-E.MaximumStoredEquipment
assert(not D:Interact(chest,pending) and not Chest.Record(instance,pending.id,false).pick and keyCount(pending)==1)
pendingInventory.capacityBonus=0
local send=LOD.CombatRolls._Send
local pickLogs=0
LOD.CombatRolls._Send=function(self,p,kind,text,family,fields)
 send(self,p,kind,text,family,fields)
 if p==pending and fields.event=='chest_lockpick' then
  pickLogs=pickLogs+1
  local accepted,reason=D:Interact(chest,p);assert(not accepted and reason=='busy')
  p.ps.deploymentComplete=false
 end
end
assert(not D:Interact(chest,pending) and keyCount(pending)==1 and stored(pending)==0)
local pendingRecord=Chest.Record(instance,pending.id,false)
assert(pendingRecord.pick.success and not pendingRecord.claimed and pickLogs==1)
LOD.CombatRolls._Send=send;pending.ps.deploymentComplete=true
pending.ps.progressionState.level=1;CPS:_RecomputeProgressionState(pending.ps.progressionState)
assert(D:Interact(chest,pending) and keyCount(pending)==1 and stored(pending)==1)
assert(pendingRecord.result.method=='lockpick' and pendingRecord.pick.threshold==95 and pickLogs==1)
-- Exact ownership and life bindings reject mutation during a staged transaction.
for index,mutate in ipairs({
 function(p) local s={};for k,v in pairs(p.ps) do s[k]=v end;p.ps=s end,
 function(p) p.ps.equipment=table.Copy(p.ps.equipment) end,
 function(p) p.ps.equipmentLifeSerial=(p.ps.equipmentLifeSerial or 0)+1 end,
 function(p) p.ps.equipment.items.chest_key.count=2 end,
 function(p) p.ps.deploymentComplete=false end,
 function(p) p.soldier=true end
}) do
 local p=actor(string.format('765611980000003%02d',index),'fighter');near(p,chest);putKeys(p,1)
 local original=p.ps.equipment
 E.StoreWearable=function(self,staged,item)
  local ok=store(self,staged,item);mutate(p);return ok
 end
 assert(not D:Interact(chest,p) and not Chest.Claim(instance,p.id) and stored(p)==0,'Stale inventory/life swap accepted '..index)
 assert(original.items.chest_key and original.items.chest_key.count>0)
 E.StoreWearable=store
end
-- Failed lockpick can explicitly preserve an available key via sprint+Use.
local keyedFailure
for suffix=190,220 do
 local id=string.format('7656118%010d',suffix*104729)
 local n=LOD.Seeds.Derive(LOD.Seeds.DeriveLevel(Run.State.CampaignSeed,instance.level),'dungeon-events:locked-chest:lockpick:'..id)
 if LOD.RNG.New(n):Int(1,100)>5 then keyedFailure=actor(id,'rogue',1);break end
end
assert(keyedFailure);near(keyedFailure,chest);putKeys(keyedFailure,1);keyedFailure.pick=true
assert(not D:Interact(chest,keyedFailure) and keyCount(keyedFailure)==1 and stored(keyedFailure)==0)
local detail=D:Snapshot(keyedFailure).events[1].details
assert(detail.attempted and not detail.unlocked and detail.keys==1 and detail.threshold==5)
keyedFailure.pick=false
assert(D:Interact(chest,keyedFailure) and keyCount(keyedFailure)==0 and stored(keyedFailure)==1)
local claimedRow=D:Snapshot(keyedFailure).events[1]
assert(claimedRow.claimed and claimedRow.result.method=='key' and claimedRow.details.attempted)
-- Joining/reconnecting clients receive current retained reward/attempt details.
F.hooks.LOD_DungeonEventSnapshot(keyedFailure);table.remove(F.timers)()
assert(F.packets[#F.packets].recipient==keyedFailure and F.packets[#F.packets].body.events[1].claimed)
-- Execute the real receiver and HUD for new, failed, pending and claimed views.
local rendered={}
LOD.UI={};E.HasSnapshot=false
input={LookupBinding=function(bind) return bind=='+speed' and 'shift' or 'e' end}
draw={SimpleTextOutlined=function(text) rendered[#rendered+1]=text end}
ScrW=function() return 1280 end;ScrH=function() return 720 end
net.ReadTable=function() return table.Copy(F.packets[#F.packets].body) end
dofile(root..'cl_dungeon_events.lua')
local function prompt(p)
 near(p,chest);LocalPlayer=function() return p end;p.GetEyeTrace=function() return {Entity=chest} end
 D:SyncPlayer(p);F.receivers.LOD_DungeonEvents();rendered={};F.hooks.LOD_DungeonEventPrompt()
 assert(rendered[1]=='LOCKED CHEST')
 return table.concat(rendered,' / ')
end
assert(prompt(keyedFailure):find('OPENED'))
local freshRogue=actor('76561198000000888','rogue',1)
assert(prompt(freshRogue):find('5%% chance') and prompt(freshRogue):find('PICK LOCK'))
local freshFighter=actor('76561198000000889','fighter')
assert(prompt(freshFighter):find('Find a Chest Key'))
putKeys(freshFighter,1);assert(prompt(freshFighter):find('USE 1 CHEST KEY'))
-- Developer key testkit uses normal Grant and marks the run unranked.
CreateConVar('lod_developer_mode','0')
local kit=actor('76561198000000890','fighter')
F.commands.lod_chest_key_testkit(kit);assert(keyCount(kit)==0)
F.convars.lod_developer_mode.value='1';kit.IsAdmin=function() return false end
F.commands.lod_chest_key_testkit(kit);assert(keyCount(kit)==0)
kit.IsAdmin=function() return true end;Run.State.Ranked=true
F.commands.lod_chest_key_testkit(kit)
assert(keyCount(kit)==1 and not Run.State.Ranked)
F.commands.lod_chest_key_testkit(kit);assert(keyCount(kit)==1,'Testkit does not top up existing keys')
-- New dungeon gets a new entitlement; the preceding dungeon's callbacks die.
local retired=instance
Run.State.Level=Run.State.Level+1
instance,chest=build(19917);near(claimedReconnect,chest)
assert(not Chest.Claim(instance,claimedReconnect.id))
assert(not Chest.Interact(D,retired,claimedReconnect,claimedReconnect.id))
assert(D:Interact(chest,claimedReconnect) and stored(claimedReconnect)==1 and keyCount(claimedReconnect)==0)
D:Cleanup('chest test complete');assert(not IsValid(chest) and not D:IsCurrent(instance))
print('LOCKED_CHEST_PASS: actual generation/REWARD/native Use; key stack/drop compatibility; staged debit+procedural reward rollback/capacity; real Rogue5–95% outcomes, spent/successful attempt retries, replacement/reconnect/regen bindings, exact-life rejection, snapshot/HUD and gated developer key grant')
