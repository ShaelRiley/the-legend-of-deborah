-- Production reward preparation, campaign receipts and pickup admission. The
-- fixture preserves the real final wrapper order; no selector is reimplemented.
local env=dofile('tools/big_loot_test_fixture.lua')(false)
local E,L,Run=LOD.Equipment,LOD.LootDirector,env.Run
local X=L.Ecology
local originalCapacity=E.MaximumStoredEquipment
local function serial(t)
    if type(t)~='table' then return tostring(t) end
    local keys,parts={},{}
    for k in pairs(t) do keys[#keys+1]=k end
    table.sort(keys,function(a,b) return tostring(a)<tostring(b) end)
    for _,k in ipairs(keys) do parts[#parts+1]=tostring(k)..'='..serial(t[k]) end
    return '{'..table.concat(parts,',')..'}'
end
local function finite(t)
    for _,v in pairs(t) do
        if type(v)=='number' then assert(v==v and math.abs(v)<math.huge,'non-finite generated field')
        elseif type(v)=='table' then finite(v) end
    end
end
env:setRun({RunId='big-loot-receipts',CampaignEpoch=1,CampaignSeed=7919,LevelSeed=711,Level=8,PlayerState={}})
local owner=env:player('owner','wizard')
local other=env:player('other','rogue')
player.GetAll=function() return {owner,other} end
owner.hp=20
assert(X:PlayerContext(owner.ps,{}).lowHealth,'current player HP did not influence medical support context')
owner.hp=100
assert(not X:PlayerContext(owner.ps,{}).lowHealth,'stale low-health context survived recovery')
local previous={}
for level=1,80 do
    local plan=X:MotifPlan(Run.State.CampaignSeed,level)
    for _,row in ipairs(plan) do
        for _,id in ipairs(previous) do assert(row.id~=id,'motif repeated within three sectors') end
        previous[#previous+1]=row.id
        if #previous>3 then table.remove(previous,1) end
    end
    X:MotifPlan(Run.State.CampaignSeed,999)
    assert(serial(plan)==serial(X:MotifPlan(Run.State.CampaignSeed,level)),
        'out-of-order motif lookup changed same-level reconstruction')
end
local options={staticId='stable-source',equipmentEligible=true,ecologyContext={motif='occult',reward=true}}
local kind,payload=E:PrepareReward(owner.id,'wearable',{},options)
assert(kind=='wearable' and E:ValidateWearable(payload.item));finite(payload.item)
local frozen=serial(payload.item)
local memory=X:Memory(owner.id)
assert(memory.serial==1 and memory.receiptCount==1 and #memory.recent==1)
for i=1,36 do
    local k,p=E:PrepareReward(owner.id,'wearable',{},
        {staticId='later:'..i,equipmentEligible=true,ecologyContext={motif='military'}})
    assert(k=='wearable' and E:ValidateWearable(p.item));finite(p.item)
end
local n=memory.serial
owner.ps.magic=0;owner.ps.progressionState.classId='fighter'
local _,again=E:PrepareReward(owner.id,'wearable',{},options)
assert(serial(again.item)==frozen and memory.serial==n,'history or class change rerolled an existing source')
assert(#memory.recent==X.historyLimit,'campaign history is not bounded')
local saved=owner.ps
owner.valid=false
local rejoined=env.actor(owner.id);rejoined.ps=saved
Run.State.PlayerState[rejoined.id]=saved
local _,afterReconnect=E:PrepareReward(rejoined.id,'wearable',{},options)
assert(serial(afterReconnect.item)==frozen and X:Memory(rejoined.id)==memory,'reconnect lost source receipt')
local _,foreign=E:PrepareReward(other.id,'wearable',{},options)
assert(foreign.item.id~=payload.item.id and X:Memory(other.id)~=memory,'individualized identity or history leaked')
assert(not saved.equipment,'reward generation silently granted inventory')
local function pickup(item)
    return {valid=true,LODLootOwnerIdentity=rejoined.id,LODLootLevelSeed=Run.State.LevelSeed,
        LODLootStaticId=options.staticId,LODLootKind='wearable',LODLootPayload={item=item}}
end
local ent=pickup(payload.item)
assert(not L:Collect(ent,other,true) and not ent.LODCollected,'foreign Hero stole individualized loot')
local bag=E:Ensure(saved)
for i=1,E:StorageCapacity(bag) do
    local item=E:GenerateArchetype(i*17,8,'surveyors_lantern','capacity:'..i)
    assert(E:StoreWearable(bag,item))
end
assert(E:StoredEquipmentCount(bag)==E:StorageCapacity(bag))
assert(not L:Collect(ent,rejoined,false) and not ent.LODCollected and not ent.LODCollecting,
    'full bag consumed source or bypassed mechanical capacity')
local spare=next(bag.items);assert(E:Discard(bag,spare))
assert(L:Collect(ent,rejoined,false) and ent.LODCollected and bag.items[payload.item.id],
    'same untouched pickup could not retry after freeing capacity')
assert(not L:Collect(pickup(payload.item),rejoined,false),'consumed source duplicated after reconnect')
assert(E:DiscardOwned(rejoined,payload.item.id))
assert(not L:Collect(pickup(payload.item),rejoined,false) and not bag.items[payload.item.id],
    'destroyed item resurrected from its source')

-- Every package obeys canonical slot occupancy, and generated values stay valid
-- at the extremes used by the economy's existing dungeon scaling clamp.
for i,id in ipairs(E.ArchetypeOrder) do
    local a=E.Archetypes[id]
    for _,depth in ipairs({a.minLevel,999}) do
        local item=E:GenerateArchetype(i*73,depth,id,'slot:'..id..':'..depth)
        assert(item.archetypeId==id and E:ValidateWearable(item),'archetype generator silently fell back: '..id);finite(item)
        local state={items={[item.id]=item},slots={}}
        assert(E:Equip(state,item.id,a.slot),'valid authored slot rejected '..id)
        assert(not E:Equip(state,item.id,'throwable'),'equipment accepted illegal Throwable slot '..id)
        assert(E:Value(item)>0 and E:Value(item)<=E:Budget(depth,a.base)*2,'unbounded archetype value '..id)
    end
end

-- Filling the ledger must not evict a previously admitted source. Beyond the
-- ceiling decisions are seed-only and remain stable as inventory state changes.
for i=memory.receiptCount+1,X.receiptLimit do
    local key='ledger:'..i
    assert(X:Generate(rejoined.id,i*193,8,'headwear',key,{motif='scavenged'}))
end
assert(memory.receiptCount==X.receiptLimit)
local fullSerial=memory.serial
local overflow=X:Generate(rejoined.id,98317,8,'ring','overflow',{motif='occult'})
saved.magic=100;saved.progressionState.classId='wizard'
local overflowAgain=X:Generate(rejoined.id,98317,8,'ring','overflow',
    {motif='military',reward=true,phrase='cache',vertical=true,risk=9,preBoss=true})
assert(serial(overflow)==serial(overflowAgain) and memory.serial==fullSerial and memory.receiptCount==X.receiptLimit)
local _,original=E:PrepareReward(rejoined.id,'wearable',{},options)
assert(serial(original.item)==frozen,'receipt ceiling evicted an earlier source')
local remembered=serial(memory.counts)
Run.State.LevelSeed=712;Run.State.Level=9
local continued=X:Memory(rejoined.id)
assert(continued==memory and continued.receiptCount==0 and serial(continued.counts)==remembered,
    'level succession erased campaign exposure or kept obsolete level receipts')
Run.State.CampaignEpoch=2
local reset=X:Memory(rejoined.id)
assert(reset~=memory and reset.serial==0 and #reset.recent==0,'new campaign inherited exposure')

-- Inventory pressure only suppresses equipment categories. Actual low-health
-- support and the existing useful-drop band remain available at all depths.
E.MaximumStoredEquipment=E:StoredEquipmentCount(bag)
rejoined.hp=20
rejoined:Give('weapon_pistol');rejoined.ammo.Pistol=0
for _,depth in ipairs({1,6,11,20}) do
    Run.State.Level=depth
    local counts={}
    for seed=1,2000 do
        local category=L:_DropCategory(rejoined,{dryKills=5},LOD.RNG.New(seed*7919+depth),false)
        counts[category or 'none']=(counts[category or 'none'] or 0)+1
    end
    assert(not counts.weapon and not counts.wearable,'full inventory still generated equipment decisions')
    assert((counts.health or 0)>200 and (counts.ammo or 0)>100,'full inventory suppressed essential support')
    assert((counts.none or 0)>50 and counts.none<900,'useful-drop/resource band escaped bounds')
end
E.MaximumStoredEquipment=originalCapacity

-- Source-bound DFT templates, direct grants and rescued-damsel slot gifts use
-- the same expanded vocabulary without advancing ordinary loot memory. Existing
-- SQLite tests own settlement/rollback; these calls exercise real item producers.
local root='gamemodes/legend_of_deborah/gamemode/lod/'
dofile(root..'sv_crypto_director.lua');dofile(root..'sv_debbie_junk.lua');dofile(root..'sv_damsels.lua')
local C,D=LOD.CryptoDirector,LOD.Damsels
local beforeContext=serial(X:Memory(rejoined.id))
local tokens,grants=0,0
for i=1,96 do
    local token=C:GenerateToken(rejoined.id,'big-loot:'..i,'test',20)
    local replay=C:GenerateToken(rejoined.id,'big-loot:'..i,'test',20)
    assert(E:ValidateWearable(token.item) and serial(token)==serial(replay),'DFT template failed valid immutable replay')
    if token.item.archetypeId then tokens=tokens+1 end
    local item=E:NewItem(rejoined,'ring','explicit:'..i)
    assert(E:ValidateWearable(item))
    if item.archetypeId then grants=grants+1 end
end
assert(tokens>60 and grants>60,'expanded DFT/direct-grant hooks were not reached')
assert(serial(X:Memory(rejoined.id))==beforeContext,'source-only gifts polluted ordinary loot history')
local recipient=env:player('damsel-recipient')
local giftCount,expanded=0,0
for _,def in ipairs(D.Definitions) do
    if def.reward=='equipment' then
        local countBefore=E:StoredEquipmentCount(recipient.ps.equipment)
        assert(D:Grant(recipient,def,'gift:'..def.level),'real damsel slot gift failed')
        local bag=recipient.ps.equipment
        assert(E:StoredEquipmentCount(bag)==countBefore+1,'damsel gift bypassed the single-item admission')
        for _,item in pairs(bag.items) do
            if item.definitionId==def.parameter then
                assert(item.economyExcluded and E:ValidateWearable(item),'damsel reward lost its economy exclusion')
                if item.archetypeId then expanded=expanded+1 end
            end
        end
        giftCount=giftCount+1
    end
end
assert(giftCount==7 and expanded>=4,'rescued-damsel equipment did not reach expanded slot families')
for i=1,8 do
    local a=E:GenerateArchetype(i*73,20,'surveyors_lantern','fuse-a:'..i)
    local b=E:GenerateArchetype(i*97,20,'bulkhead_buckler','fuse-b:'..i)
    local value=E:Value(a)+E:Value(b)
    local item=E:FusionResult(i*7919,value,'fusion:'..i)
    assert(item and item.archetypeId and E:ValidateWearable(item),'expanded fusion candidate was unreachable')
    assert(E:Value(item)>=value*.85 and E:Value(item)<=value,'fusion escaped retained 85–100% value window')
    assert(serial(item)==serial(E:FusionResult(i*7919,value,'fusion:'..i)),'same fusion inputs rerolled')
end
print('BIG_LOOT_ECOLOGY_PASS: real PrepareReward receipts; history/class/reconnect replay; owner isolation; capacity retry; consumed/trash finality; all archetype slots/finite values; bounded ledger; campaign succession/reset; full-inventory sustain')
print('BIG_LOOT_CONTEXT_PASS: immutable DFT templates; explicit grants; seven actual damsel slot gifts; expanded deterministic fusion within the retained value window')
