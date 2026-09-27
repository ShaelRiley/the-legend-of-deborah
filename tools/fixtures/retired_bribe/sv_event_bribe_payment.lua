-- Item-value settlement belongs to the current Hero inventory and event instance.
-- Reviews reserve nothing. All item removal is staged until native opening and
-- exact ownership have been revalidated; the final swap has no callbacks.
local B,E,Run=assert(LOD.EventBribeBlockade),assert(LOD.Equipment),assert(LOD.RunManager)
B.Reviews=setmetatable({}, {__mode='k'})
B.ReviewSerial=0
B.ReviewSeconds=45
util.AddNetworkString('LOD_BribeReview')
util.AddNetworkString('LOD_BribeDecision')

local function equal(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~='table' then return a==b end
    for k,v in pairs(a) do if not equal(v,b[k]) then return false end end
    for k in pairs(b) do if a[k]==nil then return false end end
    return true
end
function B.PaymentEligible(state,id)
    local item=state and state.items[id]
    local def=E:Definition(item)
    if not def or not def.wearable or def.weapon or item.id~=id
        or not E:ValidateWearable(item) or not E:JunkEligible(state,id) then return false end
    for _,equipped in pairs(state.slots) do if equipped==id then return false end end
    return true
end
function B.PaymentCleanup(instance)
    for ply,review in pairs(B.Reviews) do
        if review.instance==instance then B.Reviews[ply]=nil end
    end
end
local function exact(review,ply)
    local instance,ps,original=review.instance,review.ps,review.original
    if B.Reviews[ply]~=review or CurTime()>review.expires
        or not review.director:IsCurrent(instance) or not B.Owned(review.director,instance)
        or instance.state~='active' or instance.entities[1]~=review.terminal
        or instance.entities[2]~=review.cache or instance.barrier~=review.barrier
        or instance.collateral~=review.collateral or not equal(instance.collateral,review.collateralBefore)
        or instance.recovered~=review.recovered or B.price~=review.price
        or not IsValid(ply) or not ply:IsPlayer() or not ply:Alive()
        or ply:SteamID64()~=review.identity or ps.identity~=review.psIdentity
        or not LOD.CryptoStore:ValidAccount(review.identity)
        or not Run:IsActivePlayer(ply) or Run:IsSoldierControl(ply)
        or Run:GetPlayerState(ply)~=ps or ps.equipment~=original
        or ps.equipmentLifeSerial~=review.life or original.items~=review.itemTable
        or original.slots~=review.slotTable or not equal(original,review.before)
        or not ps.deploymentComplete or ps.inStaging or ps.eliminated or (ps.lives or 0)<=0
        or ply:GetPos():DistToSqr(review.terminal:GetPos())>160*160
        or Run.State.SimulationFrozen then return false end
    local clock=Run.State.CampaignClock
    if clock and (clock.expired or clock.scene or clock.deadline and SysTime()>=clock.deadline) then return false end
    for id,item in pairs(review.itemOwners) do if original.items[id]~=item then return false end end
    return true
end
local function interaction(review,ply)
    return review.director:InteractionCurrent(review.instance,ply,review.identity,review.ps,review.terminal)
        and exact(review,ply)
end
function B.Review(director,instance,ply,identity,entity)
    if instance.settling or not B.Owned(director,instance) then return false,'Blockade unavailable; nothing spent.' end
    local ps=Run:GetPlayerState(ply)
    local life=ps and ps.equipmentLifeSerial
    local terminal,cache,barrier=instance.entities[1],instance.entities[2],instance.barrier
    if not ps or not director:InteractionCurrent(instance,ply,identity,ps,entity)
        or not B.Owned(director,instance) or Run:GetPlayerState(ply)~=ps
        or instance.entities[1]~=terminal or instance.entities[2]~=cache or instance.barrier~=barrier
        or not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() or ply:SteamID64()~=identity
        or not LOD.CryptoStore:ValidAccount(identity) or ps.equipmentLifeSerial~=life
        or not Run:IsActivePlayer(ply) or Run:IsSoldierControl(ply) or not ps.deploymentComplete
        or ps.inStaging or ps.eliminated or (ps.lives or 0)<=0 or Run.State.SimulationFrozen
        or not IsValid(entity) or entity.LODEventInstance~=instance
        or ply:GetPos():DistToSqr(entity:GetPos())>160*160 then return false,'stale event' end
    local clock=Run.State.CampaignClock
    if clock and (clock.expired or clock.scene or clock.deadline and SysTime()>=clock.deadline) then return false,'stale event' end
    if entity==instance.entities[2] then
        instance.recovered=true
        pcall(director.SyncAll,director)
        return true,'Lost-property ring recovered as shared collateral. Review the toll at the blockade; nothing spent.'
    end
    if entity~=instance.entities[1] then return false,'stale entity' end
    local original=E:Ensure(ps)
    B.ReviewSerial=B.ReviewSerial%4294967295+1
    local review={id=B.ReviewSerial,instance=instance,director=director,ps=ps,psIdentity=ps.identity,
        identity=identity,life=ps.equipmentLifeSerial,original=original,before=table.Copy(original),
        itemTable=original.items,slotTable=original.slots,itemOwners={},terminal=entity,cache=instance.entities[2],
        barrier=instance.barrier,collateral=instance.collateral,collateralBefore=table.Copy(instance.collateral),
        recovered=instance.recovered,price=B.price,expires=CurTime()+B.ReviewSeconds}
    for id,item in pairs(original.items) do review.itemOwners[id]=item end
    B.Reviews[ply]=review
    local choices={}
    for id,item in pairs(original.items) do
        if B.PaymentEligible(original,id) then
            choices[#choices+1]={id=id,name=E:ItemName(item),value=E:Value(item)}
        end
    end
    table.sort(choices,function(a,b) if a.value~=b.value then return a.value<b.value end;return a.id<b.id end)
    if not exact(review,ply) then B.Reviews[ply]=nil;return false,'Inventory changed; review again. Nothing spent.' end
    local collateral=review.collateral
    net.Start('LOD_BribeReview')
    net.WriteTable({id=review.id,price=review.price,seconds=B.ReviewSeconds,items=choices,
        collateral=review.recovered and {name=E:ItemName(collateral),value=E:Value(collateral)} or nil})
    net.Send(ply)
    return true,'Review opened. No items are reserved or spent until confirmation.'
end
function B.Cancel(ply,id)
    local review=B.Reviews[ply]
    if not review or review.id~=id then return false,'Review expired; nothing spent.' end
    B.Reviews[ply]=nil
    return true,'Cancelled. All equipment and shared collateral remain unspent.'
end
function B.Confirm(ply,id,mode,ids)
    local review=B.Reviews[ply]
    if not review or review.id~=id then return false,'Review expired; nothing spent.' end
    local instance=review.instance
    if instance.settling then return false,'Another Hero is settling this blockade.' end
    instance.settling=true
    local attempted,committed=false,false
    local ok,accepted,result=pcall(function()
        if not interaction(review,ply) then return false,'Review changed or expired. Use the blockade again; nothing spent.' end
        local staged=table.Copy(review.original)
        local amount,selected=0,{}
        if mode=='collateral' then
            if not review.recovered or instance.collateralSpent or not E:ValidateWearable(review.collateral)
                or not E:JunkEligible({items={[review.collateral.id]=review.collateral},slots={}},review.collateral.id) then
                return false,'Recover the lost-property ring first. Nothing spent.'
            end
            -- A transaction-local canonical inventory proves admission/removal.
            -- It never becomes a Hero inventory and needs no free bag slot.
            local transient={items={},slots={}}
            if not E:StoreWearable(transient,review.collateral) or not E:Discard(transient,review.collateral.id) then
                return false,'Collateral unavailable; nothing spent.'
            end
            amount=E:Value(review.collateral)
            selected[1]=review.collateral.id
        elseif mode=='items' then
            if type(ids)~='table' or #ids<1 or #ids>8 then return false,'Select 1–8 unequipped wearable items.' end
            local seen={}
            for _,itemId in ipairs(ids) do
                if type(itemId)~='string' or #itemId>220 or seen[itemId]
                    or not B.PaymentEligible(review.original,itemId) then return false,'Equipment changed or is ineligible; nothing spent.' end
                seen[itemId]=true
                amount=amount+E:Value(review.original.items[itemId])
                selected[#selected+1]=itemId
                if not E:Discard(staged,itemId) then return false,'Item unavailable; nothing spent.' end
            end
            table.sort(selected)
        else return false,'Invalid payment choice; nothing spent.' end
        if amount<review.price then return false,'Selected equipment is worth less than '..review.price..' $DEB; nothing spent.' end
        if not interaction(review,ply) then return false,'Review changed; nothing spent.' end
        attempted=true
        if not B.PrepareOpen(instance) then return false,'Blockade could not open; nothing spent.' end
        -- Native collision and LOS work may reenter gameplay. Recheck the exact
        -- reviewed item tables, Hero/life, collateral and native owners afterward.
        if not interaction(review,ply) or not review.barrier:GetOpened() or review.barrier:IsSolid() then
            return false,'Blockade changed; nothing spent.'
        end
        local receipt={identity=review.identity,mode=mode,items=selected,value=amount,price=review.price}
        -- No callbacks between the inventory swap and the shared resolved seal.
        review.ps.equipment=staged
        instance.result=receipt
        instance.collateralSpent=mode=='collateral'
        instance.state='resolved'
        committed=true
        B.PaymentCleanup(instance)
        return true,receipt
    end)
    if not committed and attempted then pcall(B.RestoreClosed,instance,review.barrier) end
    instance.settling=nil
    if not ok then return false,'Payment unavailable; nothing spent. Review and retry.' end
    if not accepted then return false,result end
    pcall(E.Sync,E,ply)
    pcall(review.director.SyncAll,review.director)
    pcall(function() LOD.Audio:Emit(ply,'confirm') end)
    return true,result
end
local nextRequest=setmetatable({}, {__mode='k'})
net.Receive('LOD_BribeDecision',function(bits,ply)
    if bits>16000 or not IsValid(ply) or CurTime()<(nextRequest[ply] or 0) then return end
    nextRequest[ply]=CurTime()+.2
    local id,action=net.ReadUInt(32),net.ReadUInt(2)
    local accepted,result
    if action==0 then accepted,result=B.Cancel(ply,id)
    elseif action==1 then accepted,result=B.Confirm(ply,id,'collateral')
    elseif action==2 then
        local count=net.ReadUInt(4)
        if count<1 or count>8 then return end
        local ids={}
        for i=1,count do ids[i]=net.ReadString();if #ids[i]>220 then return end end
        accepted,result=B.Confirm(ply,id,'items',ids)
    else return end
    if IsValid(ply) then
        local message=accepted and type(result)=='table' and ('OPEN — '..result.value..' $DEB of item value surrendered. Passage open for all Heroes.')
            or type(result)=='string' and result or 'Payment unavailable; nothing spent.'
        ply:ChatPrint('BRIBE BLOCKADE — '..message)
    end
end)
hook.Add('PlayerDisconnected','LOD_BribeReviewDisconnect',function(ply) B.Reviews[ply]=nil;nextRequest[ply]=nil end)
