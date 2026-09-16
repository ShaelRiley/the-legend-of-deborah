LOD = LOD or {}
LOD.RuntimeReceipts = LOD.RuntimeReceipts or {}
LOD.RuntimeReceipts["statue"] = "weapon-surfaces-20260916-01"
local C,Store,Run,S=LOD.CryptoDirector,LOD.CryptoStore,LOD.RunManager,LOD.StagingDeployment
util.AddNetworkString('LOD_WalletRequest')
util.AddNetworkString('LOD_WalletSnapshot')
util.AddNetworkString('LOD_WalletOpen')
local nextRequest=setmetatable({}, {__mode='k'})
function C:CanUseStatue(ply)
    if not self:Ranked() or not self:Account(ply) or not ply:Alive() or Run:IsSoldierControl(ply)
        or not Run:IsSlotActivePlayer(ply) or not IsValid(self.Statue) then return false end
    local r=Run.State;local ps=Run:GetPlayerState(ply)
    if not r.BuildReady or r.LevelCleared or r.SimulationFrozen or not ps or ps.deploymentComplete
        or not S:IsPlayerInHut(ply) then return false end
    if ply:GetPos():DistToSqr(self.Statue:GetPos())>128*128 then return false end
    local tr=util.TraceLine({start=ply:EyePos(),endpos=self.Statue:WorldSpaceCenter(),filter=ply,mask=MASK_SOLID})
    return not tr.Hit or tr.Entity==self.Statue
end
function C:EnsureStatue()
    if IsValid(self.Statue) then return true end
    if not S.HutCenter then return false end
    local statue=ents.Create('lod_debbie_statue')
    if not IsValid(statue) then return false end
    -- Beyond the portal, opposite the Hermit. Offset sideways so neither the
    -- statue nor a player using it occupies the pad's central approach lane.
    statue:SetPos(S.HutCenter-S.HutAngles:Forward()*((S.HutHalfForward or 180)-40)
        +S.HutAngles:Right()*math.min(80,(S.HutHalfRight or 130)-40))
    statue:SetAngles(Angle(0,S.HutAngles.y,0))
    statue:Spawn()
    self.Statue=S:_RegisterHutEntity(statue)
    return true
end
local ensure=S.EnsureHut
function S:EnsureHut()
    local ok=ensure(self)
    if ok then C:EnsureStatue() end
    return ok
end
function C:Snapshot(ply)
    local id=self:Account(ply)
    if not id then return {error='Wallet requires a human Steam account.'} end
    local a,err=Store:Read(id)
    if not a then return {error=err} end
    local s=self:LevelState();local allocations,pool=self:Allocations(s,s.level)
    local share=allocations[id]
    local tokens={}
    for _,token in pairs(a.tokens) do
        local copy=table.Copy(token)
        copy.value=LOD.Equipment:Value(copy.item)
        copy.available=token.lastRun~=Run.State.RunId
        tokens[#tokens+1]=copy
    end
    table.sort(tokens,function(a,b) return a.id<b.id end)
    local history={}
    local ok,rows=pcall(Store.Recent,Store,id)
    if ok then for _,row in ipairs(rows) do
        history[#history+1]={kind=row.kind,body=util.JSONToTable(row.body,false,true) or {}}
    end end
    local pending={};for level in pairs(a.pending) do pending[level]=true end
    return {balance=a.balance,score=a.score,tokens=tokens,milestones=a.milestones,pending=pending,
        history=history,ranked=self:Ranked(),pool=pool,run=Run.State.RunId,
        pendingSoldier=(not s.settled and not Run.State.Failed and share and share.role=='soldier') and share.amount or 0,
        atStatue=self:CanUseStatue(ply)}
end
function C:Sync(ply)
    if not IsValid(ply) then return end
    LOD.SnapshotDelivery:Queue(ply,'LOD_WalletSnapshot',function(recipient) return self:Snapshot(recipient) end)
end
function C:OpenStatue(ply,entity)
    if entity~=self.Statue or not self:CanUseStatue(ply) then return false end
    self:CheckMilestones(ply)
    LOD.SnapshotDelivery:Invalidate(ply,'LOD_WalletSnapshot');self:Sync(ply)
    net.Start('LOD_WalletOpen');net.Send(ply)
    return true
end
net.Receive('LOD_WalletRequest',function(bits,ply)
    if bits>4096 or not C:Account(ply) or CurTime()<(nextRequest[ply] or 0) then return end
    nextRequest[ply]=CurTime()+.2
    local action,id=net.ReadString(),net.ReadString()
    if #action>16 or #id>220 then return end
    if action=='snapshot' then
        LOD.SnapshotDelivery:Invalidate(ply,'LOD_WalletSnapshot');C:Sync(ply)
    elseif action=='sell' or action=='recreate' then
        local ok,reason
        if action=='sell' then ok,reason=C:Sell(ply,id) else ok,reason=C:Recreate(ply,id) end
        if not ok then
            local text=reason=='already' and 'This transaction was already completed.'
                or reason=='storage' and 'Wallet storage unavailable. Your entitlement is preserved.'
                or type(reason)=='string' and reason or 'Transaction unavailable.'
            C:Report(ply,text,'wallet_denied')
        end
    end
end)
