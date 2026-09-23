-- One archetype, up to two separately owned DFT discoveries. Locks use the same
-- admission path as ordinary chests; CryptoStore owns persistent settlement.
local Lock,Run,E,C,Store=assert(LOD.EventLockedChest),assert(LOD.RunManager),
    assert(LOD.Equipment),assert(LOD.CryptoDirector),assert(LOD.CryptoStore)
local Chest={id='treasure_chest',contract='REWARD',production=true,rare=true,nonblocking=true,maxInstances=2}
LOD.EventTreasureChest=Chest
Chest.previewNotice='Treasure preview spends actual Chest Keys and awards persistent server-local DFTs. The campaign is unranked.'

function Chest.Source(instance)
    return 'treasure-chest:'..tostring(instance.runId)..':'..tostring(instance.level)..':'..tostring(instance.memberIndex or 1)
end
function Chest.EventKey(instance,identity)
    return 'mint:'..identity..':'..Chest.Source(instance)
end
function Chest.Record(instance,identity,create)
    local s=Run.State
    if instance.runId~=s.RunId or instance.level~=s.Level then return nil end
    local records=s.TreasureChestRecords
    if not records or records.level~=instance.level then
        if not create then return nil end
        records={level=instance.level,accounts={}};s.TreasureChestRecords=records
    end
    if create and not records.accounts[identity] then records.accounts[identity]={} end
    local account=records.accounts[identity]
    if not account then return nil end
    local member=instance.memberIndex or 1
    if create and not account[member] then account[member]={} end
    return account[member]
end
function Chest.Seed(instance,identity,label)
    return LOD.Seeds.Derive(LOD.Seeds.DeriveLevel(Run.State.CampaignSeed,instance.level),
        'dungeon-events:treasure-chest:'..tostring(instance.memberIndex or 1)..':'..label..':'..identity)
end
function Chest.Reward(instance,identity)
    return C:GenerateToken(identity,Chest.Source(instance),'Dungeon treasure chest',instance.level)
end
function Chest.Claim(instance,identity)
    return Store:Receipt(Chest.EventKey(instance,identity))
end
function Chest.Snapshot(instance,ply,identity)
    local ps=Run:GetPlayerState(ply)
    local key=ps and ps.equipment and ps.equipment.items.chest_key
    local record=Chest.Record(instance,identity)
    local space,reason=C:TreasureCapacity(identity)
    return {keys=key and key.count or 0,threshold=Lock.Chance(ply,ps),
        attempted=record and record.pick~=nil or false,
        unlocked=record and record.pick and record.pick.success or false,
        collectionFull=not space and reason=='full',unavailable=not space and reason~='full'}
end
Chest.Create=Lock.Create
function Chest.Prepare(instance,identity,reward,staged)
    if not E:ValidateWearable(reward.item) then return false,'DFT reward unavailable; nothing spent.' end
    local space,reason=C:TreasureCapacity(identity)
    if not space then return false,reason=='full' and 'Your DFT collection is full (8). Nothing spent; sell a token in staging and retry.'
        or 'Wallet storage unavailable; nothing spent.' end
    return true
end
function Chest.Result(reward,method)
    return {token=reward.id,name=E:ItemName(reward.item),method=method}
end
function Chest.Commit(instance,ply,identity,ps,record,original,staged,current,result)
    local oldClaim,oldResult=record.claimed,record.result
    local applied
    local ok,receipt=C:SettleTreasureChest(identity,record.reward,{
        validate=current,
        apply=function(value)
            -- Reference assignments only: no entity/native/network callbacks.
            ps.equipment=staged
            record.claimed,record.result=true,value
            applied=value
        end,
        rollback=function()
            if ps.equipment==staged then ps.equipment=original end
            if applied and record.result==applied then record.claimed,record.result=oldClaim,oldResult end
        end
    })
    if not ok then
        return false,receipt=='full' and 'Your DFT collection is full. Nothing spent; retry after making room.'
            or receipt=='storage' and 'Wallet storage unavailable; nothing spent. Retry this chest.'
            or receipt
    end
    return true,receipt
end
function Chest.Feedback(ply,result)
    C:Sync(ply)
    C:Report(ply,'TREASURE CHEST — DFT collected: '..result.name..'. View it in Wallet.','treasure_dft')
end
function Chest.Interact(director,instance,ply,identity)
    return Lock.Open(Chest,director,instance,ply,identity)
end
LOD.EventRegistry:Register(Chest)
