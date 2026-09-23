-- Real equipment/progression, event ownership and SQLite token transactions.
-- Only Source actors/entities, traces and network transport are engine doubles.
local equipment=dofile('tools/test_equipment_economy_runtime.lua')
local F=dofile('tools/dungeon_event_fixture.lua')({lod=LOD,run=equipment.Run})
local root,E,D,Run,Store=F.root,LOD.Equipment,F.D,F.Run,F.Store
net.WriteUInt,net.WriteFloat,net.WriteBool=F.noop,F.noop,F.noop
LOD.SnapshotDelivery={Queue=F.noop,Invalidate=F.noop}
dofile(root..'sv_crypto_director.lua')
dofile(root..'sv_debbie_junk.lua')
dofile(root..'sv_event_equipment_quiz.lua')
local Q,C=LOD.EventEquipmentQuiz,LOD.CryptoDirector
local p,q,generation,serial
local function count(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
local function same(a,b) return WalletJSONEncode(a)==WalletJSONEncode(b) end
local function freshActor(id)
 local a=equipment.actor(id)
 a.SteamID64=function(self) return self.id end
 a.pos=Vector();a.GetPos=function(self) return self.pos end
 a.EyePos,a.WorldSpaceCenter=a.GetPos,a.GetPos
 a.ps.deploymentComplete,a.ps.lives,a.ps.equipmentLifeSerial=true,3,1
 a.ps.equipment={items={},slots={}}
 return a
end
generation,serial=0,0
local function build(retain)
 generation=generation+1
 local old=Run.State
 F.traceBlocked=false
 local graph=F.graph
 Run.State={RunId=retain and old.RunId or 'quiz-life:'..generation,CampaignSeed=41,CampaignEpoch=generation,
  Level=1,LevelSeed=graph.MasterLevelSeed,Graph=graph,BuildReady=true,Ranked=false,
  GameMasterRecords=retain and old.GameMasterRecords or nil}
 if not retain then
  p=freshActor(tostring(76561198000001000+generation*2))
  q=freshActor(tostring(76561198000001001+generation*2))
 end
 F.online[1],F.online[2]=p,q
 Run.State.PlayerState={[p.id]=p.ps,[q.id]=q.ps}
 local cellKey,cell=next(graph.Cells)
 local i={id='quiz-test:'..generation,archetype=Q.id,contract='REWARD',cell=cell,
  cellKey=cellKey,seed=81373,placement={cellKey=cellKey},claims={},entities={}}
 assert(D:Activate(graph,{mode='preview',selectedCount=1,instances={i}}))
 p.pos,q.pos=i.entities[1]:GetPos(),i.entities[1]:GetPos()
 return i
end
local function item(actor,definition,slot,strength)
 serial=serial+1
 local it
 for n=1,strength and 512 or 1 do
  it=assert(E:Generate(91811+serial+n,1,definition or 'ring','quiz-life-item:'..serial))
  if not strength then break end
  local found=false;for _,property in ipairs(it.properties) do if property.id=='ability_str' and property.amount>0 then found=true end end
  if found then break end
  assert(n<512,'No positive Strength equipment fixture')
 end
 assert(E:StoreWearable(E:Ensure(actor.ps),it))
 assert(E:Equip(actor.ps.equipment,it.id,slot or 'left_hand'))
 E:RefreshDerived(actor,actor.ps)
 return actor.ps.equipment.items[it.id]
end
local function offer(i,a)
 a=a or p;a.pos=i.entities[1]:GetPos()
 assert(Q.Interact(D,i,a,a.id,i.entities[1]))
 local s=assert(Q.Sessions[a]);assert(s.phase=='offer');return s
end
local function accept(i,a)
 a=a or p;local s=offer(i,a)
 assert(Q.Accept(a,s.id));s=assert(Q.Sessions[a]);assert(s.phase=='playing')
 return s
end
local function tokenCount(a) local account=assert(Store:Read(a.id));return count(account.tokens) end
local function wrong(s) return s.correct%3+1 end
local function fillTokens(a)
 assert(Store:Transaction('quiz-fill:'..a.id,'test',{a.id},function(accounts)
  for n=1,8 do
   local id=a.id..':quiz-fixture:'..n
   accounts[a.id].tokens[id]={id=id,source='quiz-fixture:'..n,reason='test',run=Run.State.RunId,depth=1,
    item=E:Generate(4411+n,1,'ring','quiz-fixture:'..a.id..':'..n)}
  end
  return true
 end))
end

-- No eligible gear, protected gear and capacity/storage refusal do not consume
-- the per-account attempt. Declining the informed offer is likewise free.
local i=build()
assert(not Q.Interact(D,i,p,p.id,i.entities[1]) and not Q.Sessions[p])
local gear=item(p);assert(Q.Eligible(p.ps.equipment,'left_hand'))
for _,field in ipairs({'bound','economyExcluded','recreatedFrom'}) do
 gear[field]=true;assert(not Q.Eligible(p.ps.equipment,'left_hand'),field);gear[field]=nil
end
local def=E:Definition(gear)
for _,field in ipairs({'protected','essential'}) do
 def[field]=true;assert(not Q.Eligible(p.ps.equipment,'left_hand'),field);def[field]=nil
end
E:UnequipItem(p.ps.equipment,gear.id);assert(not Q.Eligible(p.ps.equipment,'left_hand'))
assert(E:Equip(p.ps.equipment,gear.id,'left_hand'))
local weapon=item(p,'weapon_pistol','weapon_pistol')
assert(not Q.Eligible(p.ps.equipment,'weapon_pistol'))
assert(E:AddConsumable(p.ps.equipment,'healing_potion',1))
assert(not Q.Eligible(p.ps.equipment,'throwable'))
assert(E:Equip(p.ps.equipment,gear.id,'left_hand'))
local s=offer(i);assert(not Q.IsLocked(p));assert(Q.Cancel(p,s.id));assert(not Q.Sessions[p])
item(q);fillTokens(q);assert(not Q.Interact(D,i,q,q.id,i.entities[1]) and not Q.Sessions[q], 'Full DFT collection admitted an offer')
local ready=Store.Ready;Store.Ready=false
assert(not Q.Interact(D,i,p,p.id,i.entities[1]));Store.Ready=ready
s=offer(i);F.now=F.now+31;Q.Tick(D,i);assert(not Q.Sessions[p]);s=offer(i);Q.Cancel(p,s.id)

-- Choice cards have a deterministic, distinct same-family presentation and
-- contain no durable identity, seed, correct-answer marker or full item record.
local generate=E.Generate
local generatedDecoys=0
E.Generate=function(self,seed,depth,family,context)
 if tostring(context):find('quiz-decoy:',1,true) then
  assert(family==gear.definitionId and depth==gear.dungeonLevel,'Decoy changed item family or level')
  generatedDecoys=generatedDecoys+1
 end
 return generate(self,seed,depth,family,context)
end
local cards,correct=Q.Cards(i,p.id,gear,'left_hand')
E.Generate=generate
assert(generatedDecoys>=2 and generatedDecoys<=Q.DecoyAttempts)
local again,againCorrect=Q.Cards(i,p.id,gear,'left_hand')
assert(#cards==3 and correct>=1 and correct<=3 and same(cards,again) and correct==againCorrect)
local seen={}
for _,card in ipairs(cards) do
 local encoded=WalletJSONEncode(card);assert(not seen[encoded]);seen[encoded]=true
 for _,secret in ipairs({'correct','seed','id','item','definitionId','source','context'}) do assert(card[secret]==nil,secret) end
end
local originalItems=count(p.ps.equipment.items)
s=accept(i);assert(Q.IsLocked(p) and E:CanAct(p) and not E:CanManageInventory(p))
assert(count(p.ps.equipment.items)==originalItems,'Decoys became persistent items')
for _,packet in ipairs(F.packets) do
 if packet.recipient==p and type(packet.body)=='table' then
  assert(packet.body.correct==nil and packet.body.item==nil,'Private answer leaked in network payload')
 end
end
assert(not Q.Answer(p,s.id,0) and not Q.Answer(p,s.id,4))
assert(Q.Answer(p,s.id,s.correct));assert(tokenCount(p)==1 and not Q.IsLocked(p))
assert(not Q.Answer(p,s.id,s.correct) and tokenCount(p)==1)
assert(not Q.Interact(D,i,p,p.id,i.entities[1]),'A completed Hero replayed the encounter')
assert(p.ps.equipment.items[gear.id]==gear,'Winning stole the item')

-- Simultaneous Heroes retain independent sessions. Wrong answers use the real
-- equipment removal/refresh authority and preserve every other owned item.
i=build();gear=item(p,nil,nil,true);local other=item(p,'boots','feet');E:UnequipItem(p.ps.equipment,other.id);local qgear=item(q)
p.ps.progressionState.equipmentKey=nil;E:RefreshDerived(p,p.ps)
local beforeStrength=p.ps.progressionState.effectiveAbilities.str
local ps,qs=accept(i,p),accept(i,q)
local beforeQ=q.ps.equipment
assert(Q.Answer(p,ps.id,wrong(ps)))
assert(ps.item.id==gear.id and not p.ps.equipment.items[gear.id] and p.ps.equipment.items[other.id])
assert(q.ps.equipment==beforeQ and q.ps.equipment.items[qgear.id] and Q.IsLocked(q))
assert(p.ps.progressionState.effectiveAbilities.str<beforeStrength,'Theft left stale derived stats')
assert(tokenCount(p)==0 and not Q.IsLocked(p))
assert(Q.Answer(q,qs.id,qs.correct) and tokenCount(q)==1)

-- Accepted voluntary cancellation, timeout and lifecycle cancellation consume
-- the attempt without theft/reward and clear all input locks.
local invalidations={
 {'cancel',function(a,session) Q.Cancel(a,session.id) end},
 {'timeout',function() F.now=F.now+31 end},
 {'death',function(a) a.hp=0 end},
 {'range',function(a) a.pos=Vector(999999,999999,999999) end},
 {'LOS',function() F.traceBlocked=true end},
 {'deadline',function() Run.State.CampaignClock={deadline=F.now-1} end},
 {'frozen',function() Run.State.SimulationFrozen=true end},
 {'disconnect',function(a) a.valid=false end},
 {'life',function(a) a.ps.equipmentLifeSerial=a.ps.equipmentLifeSerial+1 end},
 {'spawn',function(a) a.LODRunSpawnSerial=(a.LODRunSpawnSerial or 0)+1 end},
 {'identity',function(a) a.ps.identity='replacement Hero' end},
 {'account',function(a) a.id='76561198999999999' end},
 {'Hero object',function(a) a.ps=table.Copy(a.ps) end},
 {'inventory',function(a) a.ps.equipment=table.Copy(a.ps.equipment) end},
 {'slots',function(a) a.ps.equipment.slots=table.Copy(a.ps.equipment.slots) end},
 {'items',function(a) a.ps.equipment.items=table.Copy(a.ps.equipment.items) end},
 {'item object',function(a,session) a.ps.equipment.items[session.item.id]=table.Copy(session.item) end},
 {'item mutation',function(_,session) session.item.name='Forged after acceptance' end},
 {'entity owner',function(_,_,inst) inst.entities[1].LODEventInstance={} end},
 {'epoch',function() Run.State.CampaignEpoch=Run.State.CampaignEpoch+1 end},
 {'state',function() local replacement={};for k,v in pairs(Run.State) do replacement[k]=v end;Run.State=replacement end},
 {'graph',function() Run.State.Graph={} end},
 {'cleanup',function() D:Cleanup('quiz lifecycle test') end}
}
for _,case in ipairs(invalidations) do
 i=build();gear=item(p);s=accept(i);local original=p.ps.equipment;local id=p.id
 case[2](p,s,i);Q.Tick(D,i)
 assert(not Q.Sessions[p] and not Q.IsLocked(p),case[1]..' retained lock')
 assert(not Q.Answer(p,s.id,s.correct),case[1]..' accepted stale answer')
 assert(original.items[gear.id],case[1]..' stole without an incorrect answer')
 assert(count(Store:Read(id).tokens)==0,case[1]..' minted stale reward')
end

-- Failed ledger/commit writes roll back both receipt and participation; retry
-- remains bound to the accepted exact life/item and never reports success early.
for _,pattern in ipairs({'INSERT INTO lod_crypto_ledger','COMMIT'}) do
 i=build();gear=item(p);s=accept(i)
 WalletSQLFail(pattern)
 assert(not Q.Answer(p,s.id,s.correct) and tokenCount(p)==0,pattern)
 assert(Q.Sessions[p] and Q.Sessions[p].phase=='pending' and not Q.IsLocked(p),pattern)
 assert(p.ps.equipment.items[gear.id]==gear)
 assert(Q.Retry(p,s.id) and tokenCount(p)==1 and not Q.IsLocked(p),pattern)
 assert(not Q.Retry(p,s.id) and tokenCount(p)==1)
end

-- Canonical reward exceptions before commit retain a retryable frozen result;
-- exceptions or duplicate-receipt responses after commit recover that exact
-- durable award, without minting twice or showing a false failure/success.
for _,mode in ipairs({'before','after','already'}) do
 i=build();gear=item(p);s=accept(i)
 local settle=C.SettleDungeonToken
 C.SettleDungeonToken=function(self,...)
  if mode=='before' then error('injected precommit exception') end
  local ok,receipt=settle(self,...);assert(ok)
  if mode=='after' then error('injected postcommit exception') end
  return false,'already'
 end
 local accepted=Q.Answer(p,s.id,s.correct)
 C.SettleDungeonToken=settle
 if mode=='before' then
  assert(not accepted and tokenCount(p)==0 and Q.Sessions[p].phase=='pending' and not Q.IsLocked(p))
  assert(Q.Retry(p,s.id))
 else assert(accepted and not Q.Sessions[p],mode..' failed durable receipt recovery') end
 assert(tokenCount(p)==1 and not Q.Retry(p,s.id))
 -- Durable receipts still prevent a replay if ephemeral account claims vanish.
 Run.State.GameMasterRecords=nil;i.claims={}
 assert(not Q.Interact(D,i,p,p.id,i.entities[1]) and tokenCount(p)==1)
end

-- Canonical equipment removal failures mutate only the detached proposal;
-- callback owner changes are revalidated before touching live equipment.
for _,mode in ipairs({'reject','throw','owner_change'}) do
 i=build();gear=item(p);s=accept(i)
 local original=p.ps.equipment;local before=table.Copy(original)
 local discard=E.Discard
 E.Discard=function(self,staged,id)
  assert(staged~=original,'Theft edited live equipment before validation')
  discard(self,staged,id)
  if mode=='throw' then error('injected detached discard failure') end
  if mode=='owner_change' then p.ps.equipmentLifeSerial=p.ps.equipmentLifeSerial+1;return true end
  return false
 end
 assert(not Q.Answer(p,s.id,wrong(s)),mode)
 E.Discard=discard
 assert(p.ps.equipment==original and same(original.items,before.items) and same(original.slots,before.slots),mode..' partially stole equipment')
 assert(not Q.Sessions[p] and not Q.IsLocked(p) and tokenCount(p)==0)
end

-- If bounded generation cannot produce two distinct plausible alternatives,
-- accepting remains free and never leaves a challenge/input lock behind.
i=build();gear=item(p);s=offer(i)
E.Generate=function(self,seed,depth,family,context)
 if tostring(context):find('quiz-decoy:',1,true) then return table.Copy(gear) end
 return generate(self,seed,depth,family,context)
end
assert(not Q.Accept(p,s.id) and not Q.Sessions[p] and not Q.IsLocked(p))
E.Generate=generate
s=accept(i);assert(Q.Cancel(p,s.id))

-- Reentrant answer delivery within the canonical transaction cannot duplicate
-- awards; another Hero may settle independently after the first completes.
i=build();gear=item(p);s=accept(i)
local settle=C.SettleDungeonToken
C.SettleDungeonToken=function(self,...)
 assert(not Q.Answer(p,s.id,s.correct),'Reentrant answer bypassed settlement lock')
 return settle(self,...)
end
assert(Q.Answer(p,s.id,s.correct) and tokenCount(p)==1)
C.SettleDungeonToken=settle

-- A collection filled after admission cannot silently mint a ninth token or
-- report success. A pending receipt never outlives its exact Hero life.
i=build();gear=item(p);s=accept(i);fillTokens(p)
assert(not Q.Answer(p,s.id,s.correct) and tokenCount(p)==8)
assert(Q.Sessions[p] and Q.Sessions[p].phase=='pending' and not Q.IsLocked(p))
p.ps.equipmentLifeSerial=p.ps.equipmentLifeSerial+1;Q.Tick(D,i)
assert(not Q.Sessions[p] and not Q.Retry(p,s.id) and tokenCount(p)==8)

-- Paired gloves vacate both hands; reentrant submissions inside canonical
-- removal/refresh helpers cannot repeat theft or steal the other Hero's item.
i=build();gear=item(p,'gloves','left_hand');s=accept(i)
assert(p.ps.equipment.slots.left_hand==gear.id and p.ps.equipment.slots.right_hand==gear.id)
local discard,refresh=E.Discard,E.RefreshDerived
local removals,refreshes=0,0
E.Discard=function(self,state,id)
 removals=removals+1
 assert(not Q.Answer(p,s.id,wrong(s)),'Reentrant removal bypassed the answer lock')
 return discard(self,state,id)
end
E.RefreshDerived=function(self,a,ps)
 refreshes=refreshes+1
 assert(not Q.Answer(p,s.id,wrong(s)),'Derived-stat refresh reopened settlement')
 return refresh(self,a,ps)
end
assert(Q.Answer(p,s.id,wrong(s)))
E.Discard,E.RefreshDerived=discard,refresh
assert(removals==1 and refreshes>=1 and not p.ps.equipment.items[gear.id])
assert(not p.ps.equipment.slots.left_hand and not p.ps.equipment.slots.right_hand)
assert(not Q.Answer(p,s.id,wrong(s)) and not Q.IsLocked(p))

-- Same-dungeon regeneration/reconnect retains the spent account attempt;
-- late joins see their own availability, and teardown removes native entities.
i=build();gear=item(p);s=accept(i);assert(Q.Cancel(p,s.id))
local spentId=p.id
i=build(true);assert(not Q.Interact(D,i,p,p.id,i.entities[1]))
p=freshActor(spentId);F.online[1]=p;Run.State.PlayerState[p.id]=p.ps;gear=item(p);p.pos=i.entities[1]:GetPos()
assert(not Q.Interact(D,i,p,p.id,i.entities[1]),'Reconnect reset the accepted attempt')
local late=freshActor('76561198999888777');late.pos=i.entities[1]:GetPos();item(late)
assert(type(D:Snapshot(late))=='table' and Q.Interact(D,i,late,late.id,i.entities[1]))
D:Cleanup('quiz test complete');assert(not Q.Sessions[late] and not Q.IsLocked(late))
for _,entity in ipairs(i.entities) do assert(not IsValid(entity)) end
print('EQUIPMENT_QUIZ_PASS: canonical eligibility/protection; deterministic secret-free decoys; UI authority locks; independent Heroes; exactly-once rewards/theft/derived refresh; SQLite rollback/retry; lifecycle cancellation; account replay/regeneration/reconnect; late join and cleanup')
