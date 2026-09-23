-- P9 vertical slice: the shared wallet owns both the wager and its payout.
local Store,Run=assert(LOD.CryptoStore),assert(LOD.RunManager)
local Slot={id='slot_machine',contract='UTILITY',production=true,nonblocking=true}
LOD.EventSlotMachine=Slot
Slot.Stake=5
Slot.Payout=15

function Slot.EventKey(instance,identity)
    -- Deliberately omit generation serial: same-dungeon rebuilding is not a new bet.
    return 'dungeon-slot:'..tostring(instance.runId)..':'..tostring(instance.level)..':'..identity
end

function Slot.Claim(instance,identity)
    return Store:Receipt(Slot.EventKey(instance,identity))
end

function Slot.Create(director,instance,graph)
    local ent=ents.Create('lod_dungeon_event')
    if not IsValid(ent) then return nil,'entity_creation' end
    -- Register before native setup so exception unwinding can remove partial entities.
    if not director:Track(instance,ent) then ent:Remove();return nil,'stale' end
    ent:SetPos(LOD.MazeBuilder:CellCenter(instance.cell)+Vector(0,0,8))
    ent:SetEventID(instance.id)
    ent:Spawn()
    ent:Activate()
    return ent
end

function Slot.Interact(director,instance,ply,identity)
    if not director:IsCurrent(instance) or not Store:ValidAccount(identity) then return false,'stale' end
    local ps=Run:GetPlayerState(ply)
    if not ps then return false,'Hero unavailable' end
    local life,entity,claim=ps.equipmentLifeSerial,instance.entities[1],instance.claims[identity]
    local function current()
        return director:InteractionCurrent(instance,ply,identity,ps,entity)
            and ps.equipmentLifeSerial==life and instance.claims[identity]==claim
            and (not claim or claim.state=='resolving')
    end
    if not current() then return false,'stale' end
    local event=Slot.EventKey(instance,identity)
    local dungeonSeed=LOD.Seeds.DeriveLevel(Run.State.CampaignSeed,instance.level)
    local seed=LOD.Seeds.Derive(dungeonSeed,'dungeon-events:slot-result:'..identity)
    local ok,receipt=Store:Transaction(event,'dungeon_slot',{identity},function(accounts)
        if not current() then return false,'stale' end
        local account=accounts[identity]
        if account.balance<Slot.Stake then return false,'You need 5 $DEB. Nothing spent.' end
        -- Named utility stream is reproducible across storage retries. No combat
        -- dice, explosion modifiers, global random calls or client-supplied odds.
        local face=LOD.RNG.New(seed):Int(1,4)
        local payout=face==4 and Slot.Payout or 0
        account.balance=account.balance-Slot.Stake+payout
        local result={face=face,stake=Slot.Stake,payout=payout,net=payout-Slot.Stake}
        Store:History(identity,event,'dungeon_slot',result)
        return true,result
    end,{
        -- Recheck after all fallible SQL/encoding work, before COMMIT. A slot
        -- has no run-owned inventory to swap, but still belongs to this Hero
        -- and native event throughout its wallet transaction.
        validate=current,apply=function() end,rollback=function() end
    })
    if not ok then return false,receipt end
    -- Presentation must never turn a committed transaction into a retry.
    pcall(function()
        LOD.CryptoDirector:Sync(ply)
        LOD.Audio:Emit(ply,'confirm')
        LOD.CombatRolls:_Send(ply,3,string.format('DEBBIE SLOTS — 1d4 [%d]: paid 5 $DEB; returned %d $DEB (%+d net).',
            receipt.face,receipt.payout,receipt.net),'resource',
            {event='dungeon_slot',face=receipt.face,stake=receipt.stake,payout=receipt.payout,net=receipt.net})
    end)
    return true,receipt
end

LOD.EventRegistry:Register(Slot)
