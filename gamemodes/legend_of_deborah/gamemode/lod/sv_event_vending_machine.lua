-- A fixed-price, per-account ration. Existing inventory and wallet authorities
-- settle the item and debit together; native presentation follows commitment.
local E,Store,Run=assert(LOD.Equipment),assert(LOD.CryptoStore),assert(LOD.RunManager)
local V={id='vending_machine',contract='UTILITY',production=true,nonblocking=true}
LOD.EventVendingMachine=V
V.Price,V.Item,V.Quantity=10,'healing_potion',1
V.previewNotice='Vending preview spends your actual persistent $DEB balance. One Healing Potion for 10 $DEB per account per dungeon; campaign unranked.'

function V.EventKey(instance,identity)
    return 'dungeon-vending:'..tostring(instance.runId)..':'..tostring(instance.level)..':'..identity
end
function V.Claim(instance,identity)
    return Store:Receipt(V.EventKey(instance,identity))
end
function V.Snapshot(instance,ply,identity)
    local ps=Run:GetPlayerState(ply)
    local item=ps and ps.equipment and ps.equipment.items[V.Item]
    local account=Store:Read(identity)
    return {price=V.Price,item=V.Item,name=E.Definitions[V.Item].name,quantity=V.Quantity,
        held=item and item.count or 0,maxStack=E.Definitions[V.Item].maxStack,
        balance=account and account.balance,unavailable=not account}
end
function V.Create(director,instance,graph)
    local ent=ents.Create('lod_dungeon_event')
    if not IsValid(ent) then return nil,'entity_creation' end
    if not director:Track(instance,ent) then ent:Remove();return nil,'stale' end
    ent:SetNW2String('LOD_EventArchetype',V.id)
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
function V.Interact(director,instance,ply,identity)
    if not director:IsCurrent(instance) or not Store:ValidAccount(identity) then return false,'stale event' end
    local ps=Run:GetPlayerState(ply)
    if not ps then return false,'Hero unavailable' end
    local original=E:Ensure(ps)
    local before,staged=table.Copy(original),table.Copy(original)
    local life,entity=ps.equipmentLifeSerial,instance.entities[1]
    local function current()
        local clock=Run.State.CampaignClock
        return director:IsCurrent(instance) and IsValid(entity) and entity.LODEventInstance==instance
            and IsValid(ply) and ply:IsPlayer() and ply:Alive() and ply:SteamID64()==identity
            and Run:IsActivePlayer(ply) and not Run:IsSoldierControl(ply)
            and Run:GetPlayerState(ply)==ps and ps.equipment==original and ps.equipmentLifeSerial==life
            and ps.deploymentComplete and not ps.inStaging and not ps.eliminated and (ps.lives or 0)>0
            and not Run.State.SimulationFrozen
            and not (clock and (clock.expired or clock.scene or (clock.deadline and SysTime()>=clock.deadline)))
            and equal(original,before)
    end
    if not E:AddConsumable(staged,V.Item,V.Quantity) then
        return false,'Healing Potion stack full (3). Nothing spent; make room and retry.'
    end
    if not current() then return false,'stale event' end
    local event=V.EventKey(instance,identity)
    local ok,receipt=Store:Transaction(event,'dungeon_vending',{identity},function(accounts)
        if not current() then return false,'stale event' end
        local account=accounts[identity]
        if account.balance<V.Price then return false,'You need 10 $DEB. Nothing spent.' end
        account.balance=account.balance-V.Price
        local result={item=V.Item,name=E.Definitions[V.Item].name,quantity=V.Quantity,price=V.Price}
        Store:History(identity,event,'dungeon_vending',result)
        return true,result
    end,{
        validate=current,
        apply=function() ps.equipment=staged end,
        rollback=function() if ps.equipment==staged then ps.equipment=original end end
    })
    if not ok then return false,receipt end
    -- Each feedback channel is isolated; a failed native sync cannot reopen the
    -- durable receipt or remove the already-owned inventory item.
    pcall(E.Sync,E,ply)
    pcall(LOD.CryptoDirector.Sync,LOD.CryptoDirector,ply)
    pcall(function() LOD.Audio:Emit(ply,'confirm') end)
    pcall(LOD.CryptoDirector.Report,LOD.CryptoDirector,ply,
        'DEBBIE VENDING — '..receipt.name..' added to Equipment for '..receipt.price..' $DEB.','dungeon_vending')
    return true,receipt
end
LOD.EventRegistry:Register(V)
