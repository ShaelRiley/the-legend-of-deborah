-- Run equipment exchanges use immutable server records, no client prices/items.
local C,E,Store,Run=LOD.CryptoDirector,LOD.Equipment,LOD.CryptoStore,LOD.RunManager
local busy=setmetatable({}, {__mode='k'})
function E:JunkRejection(state,id)
    local item=state and state.items[id];local def=self:Definition(item)
    if not def then return 'Item unavailable.' end
    if item.recreatedFrom or tostring(id):sub(1,10)=='recreated:' then return 'DFT-created equipment cannot be sold or fused.' end
    if def.essential or def.protected or item.bound or item.economyExcluded or tostring(id):find(':initial:',1,true) then
        return 'Protected or free starting equipment cannot be exchanged.'
    end
    if not (def.weapon or def.wearable or def.throwable) or self:Value(item)<=0 then return 'This item has no exchange value.' end
end
function E:JunkEligible(state,id)
    return self:JunkRejection(state,id)==nil
end
-- Pick a valid existing-generator item close to the input value. Binary search
-- its legal progression budget; never forge affix magnitudes or mint free power.
function E:FusionResult(seed,value,context)
    local best,difference
    for trial=1,24 do
        local candidateSeed=LOD.Seeds.Derive(seed,'fusion:'..trial)
        local low,high=1,self.ScalingDungeonCap
        while low<=high do
            local depth=math.floor((low+high)/2)
            local item=self:Generate(candidateSeed,depth,nil,context)
            local cost=self:Value(item)
            if cost<=value then
                local delta=value-cost
                if not difference or delta<difference then best,difference=item,delta end
                low=depth+1
            else high=depth-1 end
        end
    end
    if best and difference<=value*.15 and self:ValidateWearable(best) then return best end
end
function C:ExchangeJunk(ply,action,ids)
    if busy[ply] or not self:CanUseStatue(ply) then return false,'Use Debbie in staging.' end
    if action~='sell_items' and action~='fuse_items' then return false,'Invalid exchange.' end
    if type(ids)~='table' or #ids<1 or #ids>8 or (action=='fuse_items' and #ids<2) then return false,'Select 2–8 items to fuse, or 1–8 to sell.' end
    local ps=Run:GetPlayerState(ply);local current=E:Ensure(ps)
    local seen,value={},0
    for _,id in ipairs(ids) do
        if type(id)~='string' or #id>220 or seen[id] then return false,'Invalid or duplicate item.' end
        local rejection=E:JunkRejection(current,id)
        if rejection then return false,rejection end
        seen[id]=true;value=value+E:Value(current.items[id])
    end
    table.sort(ids)
    local nextState=table.Copy(current)
    for _,id in ipairs(ids) do E:UnequipItem(nextState,id);nextState.items[id]=nil end
    local event=action..':'..Run.State.RunId..':'..self:Account(ply)..':'..util.CRC(table.concat(ids,'|'))
    local result
    if action=='fuse_items' then
        result=E:FusionResult(LOD.Seeds.Derive(Run.State.CampaignSeed,event),value,'fused:'..util.CRC(event))
        if not result then return false,'No legal equipment fits this pile’s combined value. Try a different combination.' end
        if current.items[result.id] then return false,'This fusion was already completed.' end
        nextState.items[result.id]=result
    end
    busy[ply]=true
    local id=self:Account(ply)
    local ok,receipt=Store:Transaction(event,action,{id},function(accounts)
        if ps.equipment~=current then return false,'Inventory changed.' end
        if action=='sell_items' then accounts[id].balance=accounts[id].balance+value end
        local record={amount=action=='sell_items' and value or 0,inputValue=value,item=result and result.id,items=ids}
        Store:History(id,event,action,record)
        return true,record
    end)
    -- No yielding or native grants inside this operation. Failed database writes
    -- leave the original bag untouched; success swaps the prepared bag once.
    busy[ply]=nil
    if ok then
        ps.equipment=nextState
        for class,def in pairs(E.Definitions) do
            if def.weapon then
                local kept=false
                for _,item in pairs(nextState.items) do if item.definitionId==class then kept=true;break end end
                if not kept and ply:HasWeapon(class) then ply:StripWeapon(class) end
            end
        end
        self:Report(ply,result and ('FUSED — '..E:ItemName(result)..' / '..E:Value(result)..' value')
            or ('SOLD — '..value..' $DEB'),action)
    end
    busy[ply]=nil
    E:Sync(ply);self:Sync(ply)
    return ok,receipt
end
util.AddNetworkString('LOD_JunkExchange')
util.AddNetworkString('LOD_JunkResult')
local times=setmetatable({}, {__mode='k'})
net.Receive('LOD_JunkExchange',function(bits,ply)
    if bits>15000 or not IsValid(ply) or CurTime()<(times[ply] or 0) then return end
    times[ply]=CurTime()+.5
    local action,count=net.ReadString(),net.ReadUInt(4)
    if count>8 then return end
    local ids={};for i=1,count do ids[i]=net.ReadString() end
    local request=net.ReadUInt(16)
    local ok,reason=C:ExchangeJunk(ply,action,ids)
    local message=ok and (action=='sell_items' and ('Sold for '..reason.amount..' $DEB.') or 'Fusion complete. Your new equipment is in your inventory.')
        or (type(reason)=='string' and reason or 'Exchange failed; inventory preserved.')
    if not ok then C:Report(ply,message,'junk_denied') end
    net.Start('LOD_JunkResult');net.WriteTable({request=request,ok=ok==true,message=message});net.Send(ply)
    LOD.SnapshotDelivery:Invalidate(ply,'LOD_WalletSnapshot');C:Sync(ply)
end)
-- Snapshot inventory choices only to their owner; price is recomputed on commit.
local snapshot=C.Snapshot
function C:Snapshot(ply)
    local s=snapshot(self,ply)
    s.junk={};s.equipment={}
    local ps=Run:GetPlayerState(ply);local state=ps and E:Ensure(ps)
    for id,item in pairs(state and state.items or {}) do
        local reason=E:JunkRejection(state,id)
        local equipped=false;for _,value in pairs(state.slots) do if value==id then equipped=true;break end end
        local row={id=id,name=E:ItemName(item),value=E:Value(item),reason=reason,equipped=equipped,
            description=E:Description(item),definitionId=item.definitionId,count=item.count}
        s.equipment[#s.equipment+1]=row
        if not reason then s.junk[#s.junk+1]={id=id,name=row.name,value=row.value} end
    end
    table.sort(s.junk,function(a,b) return a.id<b.id end)
    table.sort(s.equipment,function(a,b) if (a.reason==nil)~=(b.reason==nil) then return a.reason==nil end;return a.id<b.id end)
    return s
end

util.AddNetworkString("LOD_Stakeholders")
function C:StakeholderRows(players)
    local rows={}
    for _,ply in ipairs(players) do
        local id=self:Account(ply)
        local account=id and Store:Read(id)
        if account then
            local value=account.balance
            for _,token in pairs(account.tokens) do value=value+E:Value(token.item) end
            if value>0 then rows[#rows+1]={id=id,name=ply:Nick(),value=value} end
        end
    end
    table.sort(rows,function(a,b) if a.value~=b.value then return a.value>b.value end return a.id<b.id end)
    local cap=math.max(1,math.ceil(#players/2))
    while #rows>cap do table.remove(rows) end
    return rows
end
local nextBoard=0
hook.Add("Think","LOD_StakeholdersUpdate",function()
    if CurTime()<nextBoard then return end;nextBoard=CurTime()+2
    local rows=C:StakeholderRows(player.GetHumans())
    local fingerprint=util.TableToJSON(rows)
    if fingerprint==C.StakeholderFingerprint then return end
    C.StakeholderFingerprint=fingerprint;C.Stakeholders=rows
    net.Start("LOD_Stakeholders");net.WriteTable(rows);net.Broadcast()
end)
hook.Add("PlayerInitialSpawn","LOD_StakeholdersJoin",function(ply)
    timer.Simple(2,function()
        if not IsValid(ply) then return end
        net.Start("LOD_Stakeholders");net.WriteTable(C.Stakeholders or {});net.Send(ply)
    end)
end)
