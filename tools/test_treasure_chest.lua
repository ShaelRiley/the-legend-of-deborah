-- Production maze -> multi-member event -> finite key/lockpick -> real SQLite
-- settlement. Only native Source entities, transport and trace APIs are doubled.
local equipment=dofile('tools/test_equipment_economy_runtime.lua')
local F=dofile('tools/dungeon_event_fixture.lua')({lod=LOD,run=equipment.Run})
local root,E,Run,D,R,Store=F.root,LOD.Equipment,F.Run,F.D,F.R,F.Store
local CPS=LOD.CharacterProgressionSystem
for i=#F.online,1,-1 do table.remove(F.online,i) end
local function actor(id,class,level)
 local p=equipment.actor(id)
 p.ps.deploymentComplete,p.ps.lives=true,3
 p.ps.progressionState.classId=class or 'fighter'
 p.ps.progressionState.level=level or 1
 CPS:_RecomputeProgressionState(p.ps.progressionState)
 function p:SteamID64() return self.id end
 function p:Nick() return self.id end
 function p:IsAdmin() return true end
 function p:GetPos() return self.pos or Vector() end
 p.EyePos,p.WorldSpaceCenter=p.GetPos,p.GetPos
 function p:KeyDown() return self.pick==true end
 p.ChatPrint=function(self,text) self.lastChat=text end
 F.online[#F.online+1]=p
 return p
end
net.WriteUInt,net.WriteFloat,net.WriteBool=F.noop,F.noop,F.noop
LOD.SnapshotDelivery={Queue=F.noop,Invalidate=F.noop}
dofile(root..'sv_crypto_director.lua')
local C=LOD.CryptoDirector
C.Sync=function(_,p) p.walletSynced=true end -- native delivery; store remains real.
dofile(root..'sv_event_locked_chest.lua')
dofile(root..'sv_event_treasure_chest.lua')
local Chest=assert(LOD.EventTreasureChest)
assert(not R:Select(1),'Three production archetypes still fail the full 1d4 population gate')
local function count(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
local function same(a,b) return WalletJSONEncode(a)==WalletJSONEncode(b) end
local function keyCount(p) local x=E:Ensure(p.ps).items.chest_key;return x and x.count or 0 end
local function putKeys(p,n) assert(E:AddConsumable(E:Ensure(p.ps),'chest_key',n)) end
local function account(p) return assert(Store:Read(p.id)) end
local function near(p,ent) p.pos=ent:GetPos() end
local function build(seed)
 D.NextPreview='treasure_chest'
 assert(Run:BuildCurrentLevel(seed or Run.State.LevelSeed))
 local plan=D.Context.plan
 assert(Run.State.BuildReport.eventMode=='preview')
 assert(#plan.instances>=1 and #plan.instances<=2)
 local cells={}
 for index,instance in ipairs(plan.instances) do
  assert(instance.archetype=='treasure_chest' and instance.contract=='REWARD')
  assert(instance.memberIndex==index and instance.memberCount==#plan.instances)
  local key=F.key(instance.cell);assert(not cells[key]);cells[key]=true
  assert(instance.entities[1] and IsValid(instance.entities[1]))
 end
 assert(LOD.MazeGenerator:Validate(Run.State.Graph) and Run.State.Graph.Progression.Validation.valid)
 return plan.instances[1],plan.instances[1].entities[1],plan.instances
end
-- Distinct campaigns exercise both deterministic 1d2 member results. Generation
-- still validates the real maze, gates, reserved cells and required routes.
local seen,instance,chest,members={}
for seed=1,20 do
 Run.State.RunId='treasure:test:'..seed;Run.State.CampaignSeed=seed;Run.State.CampaignEpoch=seed
 instance,chest,members=build(10000+seed)
 seen[#members]=true
 if seen[1] and seen[2] and #members==2 then break end
end
assert(seen[1] and seen[2] and #members==2,'Actual generation must produce both one and two chests')
local fighter=actor('76561198100000101')
near(fighter,chest)
chest:Use(fighter)
assert(count(account(fighter).tokens)==0 and not Chest.Claim(instance,fighter.id))
putKeys(fighter,2)
WalletSQLFail('SELECT body FROM lod_crypto_ledger')
assert(not D:Interact(chest,fighter) and keyCount(fighter)==2 and count(account(fighter).tokens)==0)
WalletSQLFail('SELECT body FROM lod_crypto_accounts')
assert(not D:Interact(chest,fighter) and keyCount(fighter)==2 and count(account(fighter).tokens)==0)
local predicted=Chest.Reward(instance,fighter.id)
assert(predicted and E:ValidateWearable(predicted.item))
-- Collection limit, not equipment bag capacity, controls DFT admission.
local inventory=E:Ensure(fighter.ps)
for i=1,E:StorageCapacity(inventory) do assert(E:StoreWearable(inventory,E:Generate(8000+i,1,'ring','treasure-bag:'..i))) end
local bagCount=E:StoredEquipmentCount(inventory)
-- Every write phase, including COMMIT after detached inventory application, can
-- fail safely. Retry sees exactly one frozen token and consumes exactly one key.
for _,pattern in ipairs({'INSERT INTO lod_crypto_history','INSERT OR REPLACE INTO lod_crypto_accounts','INSERT INTO lod_crypto_ledger','COMMIT'}) do
 WalletSQLFail(pattern)
 assert(not D:Interact(chest,fighter),'Injected SQLite failure accepted: '..pattern)
 assert(keyCount(fighter)==2 and count(account(fighter).tokens)==0 and not Chest.Claim(instance,fighter.id))
end
assert(D:Interact(chest,fighter))
assert(keyCount(fighter)==1 and count(account(fighter).tokens)==1)
assert(account(fighter).tokens[predicted.id] and E:StoredEquipmentCount(E:Ensure(fighter.ps))==bagCount)
local claimed=table.Copy(account(fighter))
assert(not D:Interact(chest,fighter) and keyCount(fighter)==1 and same(account(fighter),claimed))
-- Member two has a separate entitlement for the same account.
local second=members[2];near(fighter,second.entities[1])
assert(D:Interact(second.entities[1],fighter) and keyCount(fighter)==0 and count(account(fighter).tokens)==2)
assert(Chest.Reward(second,fighter.id).id~=predicted.id)
-- Selling a DFT cannot erase the immutable event receipt or mint it again.
C.CanUseStatue=function() return true end -- unrelated staging proximity boundary.
assert(C:Sell(fighter,predicted.id) and not account(fighter).tokens[predicted.id])
local afterSale=table.Copy(account(fighter))
-- Simulate loss of volatile claims and a database reconnect; the receipt alone
-- must suppress reward replay even after sale.
instance.claims={};Run.State.TreasureChestRecords=nil;WalletSQLReconnect()
local reconnect=actor(fighter.id);near(reconnect,chest);putKeys(reconnect,1)
assert(not D:Interact(chest,reconnect) and keyCount(reconnect)==1 and same(account(reconnect),afterSale))
assert(Chest.Claim(instance,reconnect.id))
-- Full collections spend neither a key nor the Rogue's one lockpick attempt.
local full=actor('76561198100000201','rogue',20);near(full,chest);full.pick=true;putKeys(full,1)
assert(Store:Transaction('fixture:full:'..full.id,'fixture',{full.id},function(accounts)
 for i=1,8 do local token=C:GenerateToken(full.id,'fixture:'..i,'fixture',1);accounts[full.id].tokens[token.id]=token end
 return true,{}
end))
assert(not D:Interact(chest,full) and keyCount(full)==1 and count(account(full).tokens)==8)
assert(not Chest.Record(instance,full.id,false).pick)
local fullBefore=table.Copy(account(full))
assert(not D:Interact(chest,full) and same(account(full),fullBefore))
-- Selling frees one collection slot; the same unspent key can complete the
-- original frozen reward and duplicate retries remain harmless.
local fullReward=table.Copy(Chest.Record(instance,full.id,false).reward)
assert(C:Sell(full,next(account(full).tokens)))
full.pick=false
assert(D:Interact(chest,full) and keyCount(full)==0 and count(account(full).tokens)==8)
assert(same(account(full).tokens[fullReward.id],fullReward))
-- The transaction's final validation rejects changed life, role, account or
-- ownership after preparation and before its durable/volatile commit.
local query=sql.Query
for index,mutate in ipairs({
 function(p) p.ps.equipmentLifeSerial=(p.ps.equipmentLifeSerial or 0)+1 end,
 function(p) p.soldier=true end,
 function(p) p.ps.equipment=table.Copy(p.ps.equipment) end,
 function(p) local replacement={};for k,v in pairs(p.ps) do replacement[k]=v end;p.ps=replacement end,
 function(p) p.ps.deploymentComplete=false end,
 function(p) p.id='76561198109999999' end
}) do
 local p=actor(string.format('76561198103%06d',index));near(p,chest);putKeys(p,1)
 local id,original=p.id,p.ps.equipment
 local changed=false
 sql.Query=function(statement)
  local result=query(statement)
  if not changed and statement:find('INSERT INTO lod_crypto_ledger',1,true) then changed=true;mutate(p) end
  return result
 end
 assert(not D:Interact(chest,p),'Stale participant accepted '..index)
 sql.Query=query
 assert(changed and original.items.chest_key.count==1 and keyCount(p)==1)
 assert(count(assert(Store:Read(id)).tokens)==0 and not Chest.Claim(instance,id))
end
-- Natural low/high Rogue outcomes use the production derived chance and d100.
local failed,successful
for suffix=1,64 do
 local p=actor(string.format('76561198101%06d',suffix),'rogue',suffix%2==0 and 20 or 1)
 near(p,chest)
 local accepted=D:Interact(chest,p)
 local record=assert(Chest.Record(instance,p.id,false))
 assert(record.pick and record.pick.threshold==(suffix%2==0 and 95 or 5))
 if accepted then assert(count(account(p).tokens)==1);successful=successful or p
 else assert(count(account(p).tokens)==0);failed=failed or p end
 if failed and successful then break end
end
assert(failed and successful)
local failure=table.Copy(Chest.Record(instance,failed.id,false))
for _=1,3 do assert(not D:Interact(chest,failed)) end
assert(same(Chest.Record(instance,failed.id,false),failure))
local replacement=actor(failed.id,'rogue',20);near(replacement,chest)
assert(not D:Interact(chest,replacement) and same(Chest.Record(instance,failed.id,false),failure))
putKeys(replacement,1)
assert(D:Interact(chest,replacement) and keyCount(replacement)==0 and count(account(replacement).tokens)==1)
-- Interrupted successful lockpicks retain their outcome and frozen DFT. Sprint
-- deliberately preserves a carried key; changed Hero level cannot reroll odds.
local pending,pendingRecord
local send=LOD.CombatRolls._Send
for suffix=100,120 do
 local p=actor(string.format('76561198102%06d',suffix),'rogue',20);near(p,chest);p.pick=true;putKeys(p,1)
 LOD.CombatRolls._Send=function(self,who,kind,text,family,fields)
  send(self,who,kind,text,family,fields)
  if who==p and fields.event=='chest_lockpick' then
   local ok,reason=D:Interact(chest,p);assert(not ok and reason=='busy')
   p.ps.deploymentComplete=false
  end
 end
 assert(not D:Interact(chest,p) and keyCount(p)==1 and count(account(p).tokens)==0)
 local record=Chest.Record(instance,p.id,false)
 if record.pick.success then pending,pendingRecord=p,record;break end
end
LOD.CombatRolls._Send=send
assert(pending and pendingRecord.pick.threshold==95)
local frozenToken=table.Copy(pendingRecord.reward)
local oldInstance,oldChest=instance,chest
instance,chest,members=build(999117)
assert(not IsValid(oldChest) and not D:IsCurrent(oldInstance))
assert(not Chest.Interact(D,oldInstance,pending,pending.id))
assert(same(Chest.Record(instance,pending.id,false).reward,frozenToken),'Layout seeds cannot reroll pending DFTs')
pending.ps.deploymentComplete=true;pending.ps.progressionState.level=1;CPS:_RecomputeProgressionState(pending.ps.progressionState)
near(pending,chest)
WalletSQLFail('COMMIT')
assert(not D:Interact(chest,pending) and keyCount(pending)==1 and count(account(pending).tokens)==0)
assert(Chest.Record(instance,pending.id,false).pick.success and not Chest.Claim(instance,pending.id))
assert(D:Interact(chest,pending) and keyCount(pending)==1 and count(account(pending).tokens)==1)
assert(same(account(pending).tokens[frozenToken.id],frozenToken))
-- Late joins receive account-specific immutable claims/attempts for both members.
F.hooks.LOD_DungeonEventSnapshot(pending);table.remove(F.timers)()
local packet=F.packets[#F.packets]
assert(packet.recipient==pending and packet.body.events[1].claimed)
local rendered={};LOD.UI={};E.HasSnapshot=false
input={LookupBinding=function(bind) return bind=='+speed' and 'shift' or 'e' end}
draw={SimpleTextOutlined=function(text) rendered[#rendered+1]=text end}
ScrW=function() return 1280 end;ScrH=function() return 720 end
net.ReadTable=function() return table.Copy(F.packets[#F.packets].body) end
dofile(root..'cl_dungeon_events.lua')
local function prompt(p)
 near(p,chest);LocalPlayer=function() return p end;p.GetEyeTrace=function() return {Entity=chest} end
 D:SyncPlayer(p);F.receivers.LOD_DungeonEvents();rendered={};F.hooks.LOD_DungeonEventPrompt()
 assert(rendered[1]=='TREASURE CHEST')
 return table.concat(rendered,' / ')
end
assert(prompt(pending):find('OPENED'))
assert(prompt(actor('76561198100000888','rogue',1)):find('5%% chance'))
-- New levels/campaigns clean all native members and reject retained callbacks.
local staleInstance,staleChest=instance,chest
Run.State.Level=Run.State.Level+1
instance,chest=build(981123)
assert(not IsValid(staleChest) and not Chest.Interact(D,staleInstance,pending,pending.id))
assert(not Chest.Claim(instance,pending.id),'Next dungeon has a new entitlement')
local replacedInstance,replacedChest=instance,chest
Run.State.RunId='treasure:replacement';Run.State.CampaignEpoch=Run.State.CampaignEpoch+1
Run.State.Level=1
instance,chest=build(445912)
assert(not IsValid(replacedChest) and not Chest.Interact(D,replacedInstance,pending,pending.id))
D:Cleanup('treasure test complete')
assert(not IsValid(chest) and not D:IsCurrent(instance))
print('Treasure chest production generation, DFT transactions, finite keys, lockpicks, replay, snapshots and cleanup passed')
