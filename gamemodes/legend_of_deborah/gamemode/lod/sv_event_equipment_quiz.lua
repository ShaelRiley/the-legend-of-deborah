-- Optional Game Master challenge. Equipment owns items; CryptoStore owns DFTs;
-- this module owns only ephemeral choices and dungeon-scoped attempt receipts.
local E,Run,C,Store=assert(LOD.Equipment),assert(LOD.RunManager),assert(LOD.CryptoDirector),assert(LOD.CryptoStore)
local Q={id='equipment_quiz',contract='REWARD',production=true,nonblocking=true,
    optionalAlcove=true,repeatable=true,OfferSeconds=30,AnswerSeconds=30,DecoyAttempts=32,MaintenanceSeconds=.25}
LOD.EventEquipmentQuiz=Q
Q.Sessions=setmetatable({}, {__mode='k'})
Q.Serial=0
Q.Slots={'head','body','legs','feet','left_hand','right_hand','left_arm'}
Q.previewNotice='Game Master preview risks one actual equipped wearable and awards a persistent DFT. One accepted attempt per account per dungeon; campaign unranked.'
util.AddNetworkString('LOD_MinigameState')
util.AddNetworkString('LOD_MinigameAction')
local function equal(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~='table' then return a==b end
    for k,v in pairs(a) do if not equal(v,b[k]) then return false end end
    for k in pairs(b) do if a[k]==nil then return false end end
    return true
end
function Q.Record(instance,identity,create)
    local s=Run.State
    if instance.runId~=s.RunId or instance.level~=s.Level then return nil end
    local records=s.GameMasterRecords
    if not records or records.run~=s.RunId or records.level~=s.Level then
        if not create then return nil end
        records={run=s.RunId,level=s.Level,accounts={}};s.GameMasterRecords=records
    end
    if create and not records.accounts[identity] then records.accounts[identity]={} end
    return records.accounts[identity]
end
function Q.IsLocked(ply)
    local session=Q.Sessions[ply]
    return session~=nil and session.phase=='playing'
end
function E:InventoryLocked(ply) return Q.IsLocked(ply) end
function Q.Eligible(state,slot)
    local allowed=false
    for _,value in ipairs(Q.Slots) do if value==slot then allowed=true;break end end
    local item,id=E:Equipped(state,slot)
    local def=E:Definition(item)
    return allowed and item~=nil and item.id==id and def~=nil and def.wearable==true and not def.weapon
        and E:ValidateWearable(item) and E:JunkEligible(state,id) or false
end
function Q.Seed(instance,identity,label)
    return LOD.Seeds.Derive(LOD.Seeds.DeriveLevel(Run.State.CampaignSeed,instance.level),
        'equipment-quiz:'..identity..':'..label)
end
local function card(item,slot)
    local description=E:Description(item):gsub(' · Dungeon %d+','')
    return {name=E:ItemName(item),slot=E.SlotLabels[slot],description=description}
end
local function cardKey(value) return value.name..'\n'..value.slot..'\n'..value.description end
function Q.Cards(instance,identity,item,slot)
    local real=card(item,slot)
    local cards,seen={real},{[cardKey(real)]=true}
    for trial=1,Q.DecoyAttempts do
        local seed=Q.Seed(instance,identity,'decoy:'..trial)
        local decoy=E:Generate(seed,item.dungeonLevel,item.definitionId,'quiz-decoy:'..trial)
        if E:ValidateWearable(decoy) then
            local value=card(decoy,slot);local key=cardKey(value)
            if not seen[key] then seen[key]=true;cards[#cards+1]=value end
        end
        if #cards==3 then break end
    end
    if #cards~=3 then return nil end
    local rng=LOD.RNG.New(Q.Seed(instance,identity,'card-order'))
    for i=#cards,2,-1 do local j=rng:Int(1,i);cards[i],cards[j]=cards[j],cards[i] end
    for i,value in ipairs(cards) do if value==real then return cards,i end end
end
function Q.Source(instance) return 'equipment-quiz:'..tostring(instance.runId)..':'..tostring(instance.level) end
function Q.Claim(instance,identity)
    local source=Q.Source(instance)
    local receipt,err=Store:Receipt('mint:'..identity..':'..source)
    if err then return nil,err end
    if receipt and receipt.token==identity..':'..source and receipt.source==source then
        local record=Q.Record(instance,identity,true)
        if record then record.accepted=true end
        return {completed=true}
    end
end
function Q.Send(ply,session,phase,message,success)
    if not IsValid(ply) then return end
    -- Explicit projection: no item IDs, seeds, ownership metadata or answer key.
    local payload={session=session.id,phase=phase,title='THE GAME MASTER',message=message,
        expiresAt=(phase=='offer' or phase=='playing') and session.expires or nil}
    if phase=='playing' then payload.cards=table.Copy(session.cards) end
    if phase=='result' then payload.success=success==true end
    net.Start('LOD_MinigameState');net.WriteTable(payload);net.Send(ply)
end
function Q.Finish(ply,session,message,success)
    if Q.Sessions[ply]~=session then return false end
    Q.Sessions[ply]=nil -- release before fallible/native feedback
    if session.record then session.record.session=nil;session.record.finished=true end
    pcall(Q.Send,ply,session,'result',message,success)
    pcall(E.Sync,E,ply)
    pcall(session.director.SyncPlayer,session.director,ply)
    return true
end
local function exact(session,ply)
    if Q.Sessions[ply]~=session or not IsValid(ply) or not ply:IsPlayer() or not ply:Alive()
        or ply:SteamID64()~=session.identity or not Store:ValidAccount(session.identity)
        or Run:GetPlayerState(ply)~=session.ps or session.ps.identity~=session.psIdentity
        or session.ps.equipmentLifeSerial~=session.life or ply.LODRunSpawnSerial~=session.spawn
        or session.instance.entities[1]~=session.entity or not IsValid(session.entity)
        or session.entity.LODEventInstance~=session.instance or not session.director:IsCurrent(session.instance)
        or session.instance.state~='active' or not Run:IsActivePlayer(ply) or Run:IsSoldierControl(ply)
        or not session.ps.deploymentComplete or session.ps.inStaging or session.ps.eliminated
        or (session.ps.lives or 0)<=0 or Run.State.SimulationFrozen
        or ply:GetPos():DistToSqr(session.entity:GetPos())>160*160 then return false end
    local clock=Run.State.CampaignClock
    if clock and (clock.expired or clock.scene or clock.deadline and SysTime()>=clock.deadline) then return false end
    if session.phase~='pending' and CurTime()>=session.expires then return false end
    if session.item then
        local state=session.ps.equipment
        if state~=session.original or state.items~=session.itemTable or state.slots~=session.slotTable
            or state.items[session.item.id]~=session.item or state.slots[session.slot]~=session.item.id
            or not equal(session.item,session.before) or not Q.Eligible(state,session.slot)
            or Q.Record(session.instance,session.identity)~=session.record
            or session.record.session~=session then return false end
        -- Paired gloves remain the exact same item in every occupied hand.
        for slot,id in pairs(state.slots) do
            if (id==session.item.id)~=not not session.occupied[slot] then return false end
        end
        for slot in pairs(session.occupied) do if state.slots[slot]~=session.item.id then return false end end
    end
    return true
end
function Q.Current(session,ply)
    if not exact(session,ply) then return false end
    local current=session.director:InteractionCurrent(session.instance,ply,session.identity,session.ps,session.entity)
    -- Trace/native callbacks can reenter or replace an owner; check both sides.
    return current and exact(session,ply)
end
function Q.Snapshot(instance,ply,identity)
    local record=Q.Record(instance,identity)
    local session=Q.Sessions[ply]
    local active=session and session.instance==instance and session.identity==identity
    return {spent=record and record.accepted and not active or false,pending=active and session.phase=='pending' or false}
end
function Q.Create(director,instance)
    local ent=ents.Create('lod_dungeon_event')
    if not IsValid(ent) then return nil,'entity_creation' end
    if not director:Track(instance,ent) then ent:Remove();return nil,'stale' end
    ent:SetNW2String('LOD_EventArchetype',Q.id)
    ent:SetPos(LOD.MazeBuilder:CellCenter(instance.cell))
    ent:SetEventID(instance.id);ent:Spawn();ent:Activate()
    if not IsValid(ent) or not director:Track(instance,ent) then return nil,'entity_lost' end
    return ent
end
local function capacity(identity)
    local ok,reason=C:TreasureCapacity(identity)
    return ok,reason=='full' and 'Your DFT collection is full (8). No attempt spent.'
        or 'Wallet storage unavailable. No attempt spent.'
end
function Q.Interact(director,instance,ply,identity,entity)
    local active=Q.Sessions[ply]
    if active then
        if active.instance~=instance then return false,'Finish your current challenge first.' end
        if active.phase=='pending' then return Q.Retry(ply,active.id) end
        return false,'Your challenge is already open.'
    end
    local _,claimError=Q.Claim(instance,identity)
    if claimError then return false,'Wallet storage unavailable. No attempt spent.' end
    local record=Q.Record(instance,identity)
    if record and record.accepted then return false,'The Game Master has vanished for you in this dungeon.' end
    local ps=Run:GetPlayerState(ply)
    if not ps or not director:InteractionCurrent(instance,ply,identity,ps,entity) then return false,'Challenge unavailable.' end
    local state=E:Ensure(ps);local eligible=false
    for _,slot in ipairs(Q.Slots) do if Q.Eligible(state,slot) then eligible=true;break end end
    if not eligible then return false,'Wear ordinary procedural equipment to play. Protected, starting and DFT-created items are excluded. No attempt spent.' end
    local room,reason=capacity(identity);if not room then return false,reason end
    Q.Serial=Q.Serial%4294967295+1
    local session={id=Q.Serial,phase='offer',expires=CurTime()+Q.OfferSeconds,director=director,instance=instance,
        entity=entity,identity=identity,ps=ps,psIdentity=ps.identity,life=ps.equipmentLifeSerial,spawn=ply.LODRunSpawnSerial}
    Q.Sessions[ply]=session
    if not Q.Current(session,ply) then Q.Sessions[ply]=nil;return false,'Challenge unavailable.' end
    Q.Send(ply,session,'offer','One attempt this dungeon. Identify the piece you are wearing among three cards: win one DFT, or lose that exact equipped item. Equipment and inventory views close during the 30-second quiz. Cancel, timeout, death, disconnect or leaving spends the attempt without theft. Decline now freely.')
    return true,'Challenge offered; no attempt spent until acceptance.'
end
function Q.Accept(ply,id)
    local session=Q.Sessions[ply]
    if not session or session.id~=id or session.phase~='offer' or session.busy then return false,'Offer unavailable.' end
    session.busy=true
    local ok,accepted,result=pcall(function()
        if not Q.Current(session,ply) then return false,'Offer expired or changed; no attempt spent.' end
        local record=Q.Record(session.instance,session.identity)
        if record and record.accepted then return false,'Attempt already spent.' end
        local room,reason=capacity(session.identity);if not room then return false,reason end
        local original=E:Ensure(session.ps);local eligible,seen={},{}
        for _,slot in ipairs(Q.Slots) do
            if Q.Eligible(original,slot) then
                local item=E:Equipped(original,slot)
                if not seen[item.id] then eligible[#eligible+1]={item=item,slot=slot};seen[item.id]=true end
            end
        end
        if #eligible==0 then return false,'No eligible equipped item. No attempt spent.' end
        local rng=LOD.RNG.New(Q.Seed(session.instance,session.identity,'item-choice'))
        local selected=eligible[rng:Int(1,#eligible)]
        local before=table.Copy(selected.item)
        local cards,correct=Q.Cards(session.instance,session.identity,selected.item,selected.slot)
        local reward=C:GenerateToken(session.identity,Q.Source(session.instance),'Game Master Equipment Quiz',session.instance.level)
        if not cards or not reward or not E:ValidateWearable(reward.item) then return false,'Challenge unavailable. No attempt spent.' end
        if not Q.Current(session,ply) or session.ps.equipment~=original
            or E:Equipped(original,selected.slot)~=selected.item or not equal(selected.item,before)
            or not Q.Eligible(original,selected.slot) then return false,'Equipment changed. No attempt spent.' end
        record=Q.Record(session.instance,session.identity,true)
        if not record or record.accepted then return false,'Attempt unavailable.' end
        session.original,session.itemTable,session.slotTable=original,original.items,original.slots
        session.item,session.slot,session.before=selected.item,selected.slot,before
        session.occupied={}
        for slot,itemId in pairs(original.slots) do if itemId==selected.item.id then session.occupied[slot]=true end end
        session.cards,session.correct,session.reward,session.record=cards,correct,reward,record
        session.phase,session.expires='playing',CurTime()+Q.AnswerSeconds
        record.accepted,record.session=true,session
        return true,'Choose the item you are wearing.'
    end)
    session.busy=nil
    if not ok or not accepted then
        Q.Finish(ply,session,ok and result or 'Challenge unavailable. No attempt spent.',false)
        return false,ok and result or 'Challenge unavailable.'
    end
    pcall(Q.Send,ply,session,'playing',result)
    pcall(session.director.SyncPlayer,session.director,ply)
    return true,result
end
local function settle(ply,session)
    local record=session.record
    local previousResult=record.result
    local applied
    local called,ok,result=pcall(C.SettleDungeonToken,C,session.identity,session.reward,{
        validate=function() return Q.Current(session,ply) end,
        apply=function(receipt) record.result=receipt;applied=receipt end,
        rollback=function() if applied and record.result==applied then record.result=previousResult end end
    },'equipment_quiz')
    if not called then ok,result=false,'storage' end
    if not ok then
        -- A transport/native exception can follow a committed transaction.
        -- Recover only this exact frozen token and its durable mint receipt;
        -- never reopen answer submission or infer success from an error string.
        local recovered,receipt=pcall(function()
            local value=Store:Receipt('mint:'..session.reward.id)
            local account=Store:Read(session.identity)
            if value and value.token==session.reward.id and value.source==session.reward.source
                and account and equal(account.tokens[session.reward.id],session.reward)
                and Q.Current(session,ply) then return value end
        end)
        if recovered and receipt then ok,result=true,receipt;record.result=receipt end
    end
    if ok then
        Q.Finish(ply,session,'Correct! DFT collected: '..result.name..'. View it in Wallet.',true)
        pcall(C.Sync,C,ply)
        return true,result
    end
    if not Q.Current(session,ply) then
        Q.Finish(ply,session,'Challenge ended; no DFT awarded and no item taken.',false)
        return false,'Challenge ended.'
    end
    session.phase='pending'
    pcall(Q.Send,ply,session,'pending','Correct, but DFT collection is not yet confirmed. Retry while this Hero, item and Game Master remain available; cancel forfeits any uncommitted reward.')
    return false,result
end
function Q.Answer(ply,id,choice)
    local session=Q.Sessions[ply]
    if not session or session.id~=id or session.phase~='playing' or session.busy then return false,'Answer unavailable.' end
    if type(choice)~='number' or choice%1~=0 or choice<1 or choice>3 then return false,'Invalid choice.' end
    session.busy=true
    local ok,accepted,result=pcall(function()
        if not Q.Current(session,ply) then
            Q.Finish(ply,session,'Challenge ended; your attempt is spent, with no theft or reward.',false)
            return false,'Challenge ended.'
        end
        if choice==session.correct then return settle(ply,session) end
        local before=table.Copy(session.original)
        local owners={}
        for itemId,item in pairs(session.original.items) do owners[itemId]=item end
        local staged=table.Copy(session.original)
        E:UnequipItem(staged,session.item.id)
        local removed=E:Discard(staged,session.item.id)
        local current=Q.Current(session,ply) and equal(session.original,before)
        for itemId,item in pairs(owners) do if session.original.items[itemId]~=item then current=false end end
        if not removed or not current then
            Q.Finish(ply,session,'Equipment changed; no item taken and no reward.',false)
            return false,'Equipment unavailable.'
        end
        -- Both assignments are callback-free; duplicate submissions cannot
        -- observe an unsealed theft. Canonical Sync recalculates derived effects.
        session.ps.equipment=staged
        session.record.result={stolen=true}
        Q.Finish(ply,session,'Incorrect. The Game Master takes '..E:ItemName(session.item)..' and vanishes.',false)
        return true,{stolen=true}
    end)
    session.busy=nil
    if not ok then
        Q.Finish(ply,session,'Challenge unavailable; attempt spent.',false)
        return false,'Challenge unavailable.'
    end
    return accepted,result
end
function Q.Retry(ply,id)
    local session=Q.Sessions[ply]
    if not session or session.id~=id or session.phase~='pending' or session.busy then return false,'No pending reward.' end
    session.busy=true
    local ok,accepted,result=pcall(function()
        if not Q.Current(session,ply) then
            Q.Finish(ply,session,'Pending reward forfeited; the Hero, item or encounter changed.',false)
            return false,'Pending reward forfeited.'
        end
        return settle(ply,session)
    end)
    session.busy=nil
    if not ok then return false,'Wallet unavailable; retry this Game Master.' end
    return accepted,result
end
function Q.Cancel(ply,id)
    local session=Q.Sessions[ply]
    if not session or session.id~=id or session.busy then return false,'Challenge unavailable.' end
    local message=session.phase=='offer' and 'Declined. No attempt spent.' or 'Challenge forfeited. Attempt spent; no item taken or reward awarded.'
    Q.Finish(ply,session,message,false)
    return true,message
end
function Q.Tick(director,instance)
    if CurTime()<(instance.nextQuizMaintenance or 0) then return end
    instance.nextQuizMaintenance=CurTime()+Q.MaintenanceSeconds
    for ply,session in pairs(Q.Sessions) do
        if session.instance==instance and not session.busy and not Q.Current(session,ply) then
            Q.Finish(ply,session,session.phase=='offer' and 'Offer expired; no attempt spent.'
                or 'Challenge ended; attempt spent, with no theft or reward.',false)
        end
    end
end
function Q.Cleanup(director,instance)
    for ply,session in pairs(Q.Sessions) do
        if session.instance==instance then Q.Finish(ply,session,'The Game Master encounter has ended.',false) end
    end
end
net.Receive('LOD_MinigameAction',function(bits,ply)
    if bits<35 or bits>40 or not IsValid(ply) then return end
    local id,action=net.ReadUInt(32),net.ReadUInt(3)
    if action==0 then Q.Cancel(ply,id)
    elseif action==1 then Q.Accept(ply,id)
    elseif action==2 then if bits>=37 then Q.Answer(ply,id,net.ReadUInt(2)) end
    elseif action==3 then Q.Retry(ply,id) end
end)
local function lost(ply)
    local session=Q.Sessions[ply]
    if session then Q.Finish(ply,session,'Challenge ended; no item taken or reward awarded.',false) end
end
hook.Add('PlayerDeath','LOD_EquipmentQuizDeath',lost)
hook.Add('PlayerDisconnected','LOD_EquipmentQuizDisconnect',lost)
LOD.EventRegistry:Register(Q)
