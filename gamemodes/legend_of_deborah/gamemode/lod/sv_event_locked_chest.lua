-- Ordinary locked loot: a staged inventory transaction, not a wallet/DFT mint.
local E,Run,Rules=assert(LOD.Equipment),assert(LOD.RunManager),assert(LOD.RPGAbilityRules)
local Chest={id='locked_chest',contract='REWARD',production=true,nonblocking=true}
LOD.EventLockedChest=Chest

function Chest.EventKey(instance,identity)
    return 'locked-chest:'..tostring(instance.runId)..':'..tostring(instance.level)..':'..identity
end

function Chest.Record(instance,identity,create)
    local s=Run.State
    if instance.runId~=s.RunId or instance.level~=s.Level then return nil end
    local records=s.LockedChestRecords
    if not records or records.level~=instance.level then
        if not create then return nil end
        records={level=instance.level,accounts={}}
        s.LockedChestRecords=records
    end
    if create and not records.accounts[identity] then records.accounts[identity]={} end
    return records.accounts[identity]
end

function Chest.Seed(instance,identity,label)
    return LOD.Seeds.Derive(LOD.Seeds.DeriveLevel(Run.State.CampaignSeed,instance.level),
        'dungeon-events:locked-chest:'..label..':'..identity)
end

function Chest.Reward(instance,identity)
    local n=Chest.Seed(instance,identity,'reward')
    return E:Generate(n,instance.level,E:RewardWearableFamily(n),Chest.EventKey(instance,identity))
end

function Chest.Claim(instance,identity)
    local record=Chest.Record(instance,identity)
    return record and record.claimed and record.result or nil
end

function Chest.Chance(ply,ps)
    if not ps or not ps.progressionState or ps.progressionState.classId~='rogue' then return nil end
    local d=Rules:Derived(ply) or {}
    return math.Clamp(math.floor((d.arcaneItemUseChance or 0)*100+.5),0,100)
end

function Chest.Snapshot(instance,ply,identity)
    local ps=Run:GetPlayerState(ply)
    local key=ps and ps.equipment and ps.equipment.items.chest_key
    local record=Chest.Record(instance,identity)
    return {keys=key and key.count or 0,threshold=Chest.Chance(ply,ps),
        attempted=record and record.pick~=nil or false,
        unlocked=record and record.pick and record.pick.success or false}
end

function Chest.Create(director,instance,graph)
    local ent=ents.Create('lod_dungeon_event')
    if not IsValid(ent) then return nil,'entity_creation' end
    if not director:Track(instance,ent) then ent:Remove();return nil,'stale' end
    ent:SetNW2String('LOD_EventArchetype',instance.archetype)
    ent:SetPos(LOD.MazeBuilder:CellCenter(instance.cell)+Vector(0,0,8))
    ent:SetEventID(instance.id)
    ent:Spawn();ent:Activate()
    return ent
end

local function equal(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~='table' then return a==b end
    for k,v in pairs(a) do if not equal(v,b[k]) then return false end end
    for k in pairs(b) do if a[k]==nil then return false end end
    return true
end

-- Shared lock/key admission; each reward authority supplies preparation and settlement.
function Chest.Open(def,director,instance,ply,identity)
    if not director:IsCurrent(instance) then return false,'stale event' end
    local ps=Run:GetPlayerState(ply)
    if not ps then return false,'Hero unavailable' end
    local entity,claim=instance.entities[1],instance.claims[identity]
    if not director:InteractionCurrent(instance,ply,identity,ps,entity) then return false,'stale event' end
    local record=def.Record(instance,identity,true)
    if not record then return false,'stale event' end
    if record.claimed then return false,'already' end
    local original=E:Ensure(ps)
    local threshold=Chest.Chance(ply,ps)
    local key=original.items.chest_key
    local hasKey=key and key.count>0
    local unlocked=record.pick and record.pick.success
    local picking=not unlocked and threshold~=nil and (not hasKey or ply:KeyDown(IN_SPEED))
    if not unlocked and not picking and not hasKey then return false,'A Chest Key is required.' end
    if picking and record.pick then return false,'Your lockpick attempt was spent. A Chest Key can still open this chest.' end

    local before,staged=table.Copy(original),table.Copy(original)
    local life=ps.equipmentLifeSerial
    local function current()
        return director:InteractionCurrent(instance,ply,identity,ps,entity)
            and ps.equipment==original and ps.equipmentLifeSerial==life and instance.claims[identity]==claim
            and (not claim or claim.state=='resolving')
            and def.Record(instance,identity)==record and not record.claimed and equal(original,before)
    end

    record.reward=record.reward or def.Reward(instance,identity)
    if not record.reward then return false,'Reward unavailable; nothing spent.' end
    -- All admission/debit work happens in a detached inventory. The canonical
    -- helpers cannot consume a live key on a full bag or failed native-free grant.
    if not unlocked and not picking and not E:Consume(staged,'chest_key') then return false,'Chest Key unavailable.' end
    local prepared,reason=def.Prepare(instance,identity,record.reward,staged)
    if not prepared then return false,reason end
    if not current() then return false,'stale event' end

    if picking then
        local roll=LOD.RNG.New(def.Seed(instance,identity,'lockpick')):Int(1,100)
        record.pick={roll=roll,threshold=threshold,success=roll<=threshold}
        -- Record before presentation. Reentrant Use sees the director's busy claim.
        pcall(function()
            LOD.CombatRolls:_Send(ply,3,string.format('LOCKPICK — d100 %d / need ≤%d: %s',
                roll,threshold,record.pick.success and 'OPEN' or 'FAILED — Chest Key still works'),
                'resource',{event='chest_lockpick',roll=roll,threshold=threshold,success=record.pick.success})
        end)
        if not record.pick.success then return false,'Lockpick failed. Attempt spent; no key consumed.' end
        if not current() then return false,'Reward pending; retry the same unlocked chest.' end
    end

    local result=def.Result(record.reward,(unlocked or picking) and 'lockpick' or 'key')
    if def.Commit then
        local committed,receipt=def.Commit(instance,ply,identity,ps,record,original,staged,current,result)
        if not committed then return false,receipt end
        result=receipt
    else
        -- No callbacks/yields between inventory replacement and the retained claim.
        ps.equipment=staged
        record.claimed,record.result=true,result
    end
    pcall(E.Sync,E,ply)
    pcall(function() LOD.Audio:Emit(ply,'confirm') end)
    pcall(def.Feedback,ply,result)
    return true,result
end

function Chest.Prepare(instance,identity,reward,staged)
    if not E:ValidateWearable(reward) then return false,'Reward unavailable; nothing spent.' end
    if not E:StoreWearable(staged,reward) then return false,'Make room in Equipment; nothing spent.' end
    return true
end
function Chest.Result(reward,method)
    return {itemId=reward.id,name=E:ItemName(reward),method=method}
end
function Chest.Feedback(ply,result)
    E:Report(ply,'LOCKED CHEST — '..result.name..' added to Equipment.','chest_reward')
end
function Chest.Interact(director,instance,ply,identity)
    return Chest.Open(Chest,director,instance,ply,identity)
end

LOD.EventRegistry:Register(Chest)

concommand.Add('lod_chest_key_testkit',function(ply)
    local dev=GetConVar('lod_developer_mode')
    if not dev or not dev:GetBool() or not IsValid(ply) or not ply:IsAdmin() then return end
    local ps=Run:GetPlayerState(ply)
    if not ps or Run:IsSoldierControl(ply) then return end
    Run:MarkUnranked('Chest Key testkit')
    local key=E:Ensure(ps).items.chest_key
    if not key and not E:Grant(ply,'chest_key',1) then
        E:Report(ply,'CHEST TEST — deploy as a living Hero before requesting a key.','chest_testkit')
        return
    end
    E:Report(ply,'CHEST TEST — one test key available in your bag. Use a locked chest; Rogue sprint + Use attempts lockpicking. Run unranked.','chest_testkit')
end)
