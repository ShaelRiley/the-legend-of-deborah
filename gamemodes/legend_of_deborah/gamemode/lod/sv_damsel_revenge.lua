-- Encounter-owned support, using the existing item transaction, physical dice,
-- faction/native damage and individualized LootDirector settlement authorities.
local D,E,R,W=LOD.DamselRevenge,LOD.Equipment,LOD.RunManager,LOD.Warden
local Rules,Status,Rolls=LOD.RPGAbilityRules,LOD.RPGStatusElements,LOD.CombatRolls
local C=D.Config
if D.Retire then D:Retire(D.current,'module reload') end
D.cleanup=D.cleanup or {}
D.Packets=setmetatable({},{__mode='k'})
local function copy(v) return Vector(v.x,v.y,v.z) end
local function key(c) return c and LOD.MazeGenerator.CellKey(c.x,c.y,c.z) end
local function log(event,fields)
    if LOD.RPGTestLog then pcall(LOD.RPGTestLog.Write,LOD.RPGTestLog,event,fields) end
end
local function exact(s,e)
    return IsValid(e) and LOD.EntrySafety and LOD.EntrySafety:ExactCell(s.Graph,e:GetPos())
end
local function hero(p)
    local ps=IsValid(p) and p:IsPlayer() and R:GetPlayerState(p)
    return ps and p:Alive() and R:IsActivePlayer(p) and not R:IsSoldierControl(p)
        and ps.deploymentComplete and not ps.eliminated and (ps.lives or 0)>0
end
function D:ClockReady(s,expire)
    local c=s and s.CampaignClock
    if not c or c.scene or not c.deadline then return false end
    if SysTime()>=c.deadline then
        if expire and LOD.CampaignTimeout then LOD.CampaignTimeout:Expire() end
        return false
    end
    return true
end
function D:InCourt(s,a,e) return a and a.court[key(exact(s,e))] == true end
function D:CourtPresent(r)
    for _,p in ipairs(W:Targets()) do
        if hero(p) and self:InCourt(r.state,r.arena,p) then return true end
    end
    return false
end
function D:Encounter(p)
    local s,w,a=W:State()
    local target=s and s.RescueTarget
    local d=s and s.RescueEntity
    local pg=s and s.Graph and s.Graph.Progression
    local jail=pg and pg.JailEdge and pg.JailEdge.entity
    if not s or not a or s.Level<1 or s.Level>20 or not s.BuildReady or s.Failed or s.LevelCleared
        or s.SimulationFrozen or not w.started or w.dead or w.revenge
        or not W:ActorOwner(w,w.actor) or not self:ClockReady(s,true)
        or not hero(p) or not self:InCourt(s,a,p) or W:Protected(p)
        or not target or target.type~='damsel' or target.definition~=s.Level
        or not IsValid(d) or d:GetClass()~='lod_deborah' or d.LODRescueTarget~=target
        or d.LODHostile or IsValid(d:GetOwner()) or not IsValid(jail) or jail:GetClass()~='lod_jail_door'
        or s.JailDoorOpen or jail:GetOpened() or key(exact(s,d))~=key(pg.DeborahCell) then return end
    return s,w,a,d,jail
end
function D:SourceValid(p,context)
    local b=context and context.moveBinding
    return b and context.clock and E:MoveAttackValid(p,context) and hero(p) and E:IsActive(p)
        and IsValid(context.weapon) and p:GetActiveWeapon()==context.weapon
        and context.weapon:GetOwner()==p and context.weapon:GetClass()==E.WeaponClass
        and R.State.CampaignClock==context.clock and context.clock.deadline==context.deadline
        and b.slot=='throwable' and b.source.definitionId=='damsel_revenge'
        and CurTime()>=(E.NextUse[p] or 0)
end
function D:Scope(r,allowClear)
    local s=R.State
    return r and not r.retired and self.current==r and s==r.state and s.BuildReady and not s.Failed
        and s.Graph==r.graph and s.Graph.Progression==r.progression and r.progression.Warden==r.arena
        and s.CampaignEpoch==r.epoch and s.CampaignSeed==r.campaignSeed and s.RunId==r.runId
        and s.Level==r.level and s.LevelSeed==r.seed and s.Warden==r.warden and r.warden.revenge==r
        and r.warden.actor==r.boss and r.warden.state==s and r.warden.graph==r.graph
        and r.warden.epoch==r.epoch and r.warden.runId==r.runId and r.warden.campaignSeed==r.campaignSeed
        and r.warden.seed==r.seed and r.warden.level==r.level
        and (r.defeated or IsValid(r.boss) and r.boss.LODWardenOwner==r.warden)
        and (not r.defeated or not IsValid(r.boss) or r.boss.LODDead and r.boss:Health()<=0)
        and s.RescueEntity==r.damsel and IsValid(r.damsel) and r.damsel.LODRevengeOwner==r
        and r.damsel.LODRescueTarget==r.target and r.target.type=='damsel' and r.target.definition==r.level
        and s.RescueTarget and s.RescueTarget.type=='damsel' and s.RescueTarget.definition==r.level
        and not r.damsel.LODHostile and not IsValid(r.damsel:GetOwner())
        and Rules:ProgressionState(r.damsel)==r.sourceState and Status.ActorLives[r.damsel]==r.sourceLife
        and r.damsel:GetPos():DistToSqr(r.origin)<=C.drift^2
        and key(exact(s,r.damsel))==key(r.progression.DeborahCell)
        and r.progression.JailEdge==r.jailMeta and r.jailMeta.entity==r.jail and IsValid(r.jail)
        and r.jail.LODRevengeOwner==r and r.jail:GetPos():DistToSqr(r.jailPos)<=1 and r.jail:GetDoorAxis()==r.axis
        and (not s.LevelCleared or r.rescued==true or allowClear==true)
end
function D:Ready(r)
    return self:Scope(r) and r.active and not r.defeated and not r.rescued and not r.state.SimulationFrozen
        and not r.state.LevelCleared and not r.state.JailDoorOpen and not r.jail:GetOpened()
        and self:ClockReady(r.state) and W:ActorOwner(r.warden,r.boss)
        and Rules:ProgressionState(r.boss)==r.bossState and Status.ActorLives[r.boss]==r.bossLife
        and not r.boss:GetNW2Bool('LOD_WardenHidden',false)
        and self:InCourt(r.state,r.arena,r.boss) and self:CourtPresent(r)
        and LOD.FactionManager:IsOpponent(r.damsel,r.boss)
end
-- A line must pass both faces of this exact closed slab inside the visible slit.
-- Ignoring the slab alone without this proof would also ignore its tall header.
function D:ThroughPort(r,from,to)
    local pc=LOD.Config.Progression
    local axis,side=r.axis==0 and 'x' or 'y',r.axis==0 and 'y' or 'x'
    local delta=to[axis]-from[axis]
    if math.abs(delta)<.001 then return false end
    local width,height=self:PortSize()
    local middle=r.jailPos.z-pc.GateBlockerHeight*.5+C.muzzle
    for _,face in ipairs({-.5,.5}) do
        local t=(r.jailPos[axis]+face*pc.GateThickness-from[axis])/delta
        if t<=0 or t>=1 then return false end
        local cross=from+(to-from)*t
        if math.abs(cross[side]-r.jailPos[side])>width*.5-C.inset
            or math.abs(cross.z-middle)>height*.5-C.inset then return false end
    end
    return true
end
function D:Path(r)
    if not self:Ready(r) then return end
    local from=r.damsel:GetPos()+Vector(0,0,C.muzzle)
    local to=r.boss:WorldSpaceCenter()
    if from:DistToSqr(to)>(C.rangeCells*LOD.Config.Maze.CellSize)^2 or not self:ThroughPort(r,from,to) then return end
    local tr=util.TraceLine({start=from,endpos=to,mask=MASK_SHOT,filter={r.damsel,r.jail}})
    if not tr or tr.StartSolid or tr.AllSolid or (tr.Hit and tr.Entity~=r.boss) or not self:Ready(r) then return end
    return from,to
end
function D:PrepareGun(s,w)
    if w.revengeChoice then return w.revengeChoice end
    local id=table.concat({'damsel-revenge',tostring(s.CampaignEpoch),tostring(s.CampaignSeed),
        tostring(s.RunId),tostring(s.Level),tostring(s.LevelSeed)},':')
    local seed=LOD.Seeds.Derive(s.CampaignSeed or 1,id)
    local spec=self.Firearms[LOD.RNG.New(LOD.Seeds.Derive(seed,'gun-choice-v1')):Int(1,#self.Firearms)]
    local item=E:Generate(LOD.Seeds.Derive(seed,'gun-record-v1'),s.Level,spec.class,id)
    if not item or not E:ValidateWearable(item) or item.definitionId~=spec.class then return end
    w.revengeChoice={item=item,spec=spec}
    return w.revengeChoice
end
function D:SameEncounter(p,s,w,a,d,jail)
    local ss,ww,aa,dd,jj=self:Encounter(p)
    return ss==s and ww==w and aa==a and dd==d and jj==jail
end
function D:ActivateBound(p,context,s,w,a,d,jail)
    local choice=self:PrepareGun(s,w)
    if not choice or not self:SourceValid(p,context) or not self:SameEncounter(p,s,w,a,d,jail) then return false end
    local b=context.moveBinding
    -- Stage the canonical debit; a failed/stale/reentrant adapter cannot charge
    -- a Hero and then leave an unowned gun. Commit only this item and slot map.
    local staged={items={[b.itemId]=table.Copy(b.source)},slots=table.Copy(b.state.slots)}
    if not E:Consume(staged,b.itemId) or not self:SourceValid(p,context) or not self:SameEncounter(p,s,w,a,d,jail) then return false end
    Status:BindActorLife(d);Status:BindActorLife(w.actor)
    if not self:SourceValid(p,context) or not self:SameEncounter(p,s,w,a,d,jail) then return false end
    local r={state=s,graph=s.Graph,progression=s.Graph.Progression,warden=w,arena=a,
        epoch=s.CampaignEpoch,campaignSeed=s.CampaignSeed,runId=s.RunId,level=s.Level,seed=s.LevelSeed,
        damsel=d,target=s.RescueTarget,sourceState=Rules:ProgressionState(d),sourceLife=Status.ActorLives[d],origin=copy(d:GetPos()),
        boss=w.actor,bossState=Rules:ProgressionState(w.actor),bossLife=Status.ActorLives[w.actor],
        jail=jail,jailMeta=s.Graph.Progression.JailEdge,jailPos=copy(jail:GetPos()),axis=jail:GetDoorAxis(),
        owner=b.identity,ownerState=b.session.ps,item=table.Copy(choice.item),spec=choice.spec,active=true,nextShot=CurTime()+C.arming,shots=0}
    b.state.items[b.itemId]=staged.items[b.itemId];b.state.slots=staged.slots
    E.NextUse[p]=CurTime()+E.UseCooldown
    w.revenge=r;d.LODRevengeOwner=r;jail.LODRevengeOwner=r;self.current=r
    log('DAMSEL_REVENGE_ARMED',{level=s.Level,owner=r.owner,gun=r.spec.class,item=r.item.id})
    return true
end
function E:UseDamselRevenge(p)
    if D.busy or not self:CanAct(p) or not self:IsActive(p) then return false end
    local context={moveBinding=self:BindMoveSource(p,{family='damsel_revenge'}),weapon=p:GetActiveWeapon()}
    local s,w,a,d,jail=D:Encounter(p)
    context.clock=s and s.CampaignClock;context.deadline=context.clock and context.clock.deadline
    if not s or not D:SourceValid(p,context) then
        self:Report(p,"DAMSEL'S REVENGE — needs an unarmed Damsel and a live Gordon fight; use from the court.",'damsel_revenge_denied');return false
    end
    D.busy=true
    local ok,result=pcall(D.ActivateBound,D,p,context,s,w,a,d,jail)
    D.busy=nil
    if not ok then log('DAMSEL_REVENGE_USE_ERROR',{error=tostring(result)});return false end
    if not result then return false end
    -- A presentation failure must not turn a committed payment into a reported failure.
    pcall(self.Sync,self,p)
    pcall(self.Report,self,p,"DAMSEL'S REVENGE — armed! Your gun drops at her feet after rescue.",'damsel_revenge_armed')
    return true
end
function D:PacketValid(info,target)
    local q=self.Packets[info]
    return q and target==q.r.boss and info:GetAttacker()==q.r.damsel and info:GetInflictor()==q.r.damsel
        and self:Ready(q.r) and q.r.damsel:GetPos():DistToSqr(q.source)<=C.drift^2
        and q.r.boss:WorldSpaceCenter():DistToSqr(q.target)<=C.drift^2
end
function D:IsSupportPacket(info)
    local a,i=info:GetAttacker(),info:GetInflictor()
    return self.Packets[info]~=nil or IsValid(a) and a:GetClass()=='lod_deborah'
        or IsValid(i) and i:GetClass()=='lod_deborah'
end
hook.Add('EntityTakeDamage','LOD_DamselRevengePacket',function(target,info)
    if D:IsSupportPacket(info) and not D:PacketValid(info,target) then info:SetDamage(0);return true end
end)
-- Keep the receipt around the complete existing mitigation chain. Ordinary
-- hooks are unordered; a later defense/native adapter may replace an owner.
if not D.PacketSeamInstalled then
    D.PacketSeamInstalled=true
    local previous=GM.EntityTakeDamage
    function GM:EntityTakeDamage(target,info)
        local q=D.Packets[info]
        if D:IsSupportPacket(info) and (not q or q.entered or not D:PacketValid(info,target)) then info:SetDamage(0);return true end
        if q then q.entered=true end
        local result=previous and previous(self,target,info)
        if q and (D.Packets[info]~=q or not D:PacketValid(info,target)) then info:SetDamage(0);return true end
        return result
    end
end
function D:Fire(r,now)
    local from,to=self:Path(r)
    if not from then return false end
    r.nextShot=now+r.spec.gap -- no catch-up, even after a blocked native packet
    local profile=table.Copy(Rolls.PlayerDamageProfiles[r.spec.class])
    profile.attackEvent={damselRevenge=true};profile.label="DAMSEL'S REVENGE"
    local contract=Rolls:RollActorDamage(r.damsel,profile,Rolls:_RNG('damsel-revenge:'..r.spec.class),0)
    local tags={physical=true,actorDamageResolved=true,damageContract=contract,attackEvent=contract.attackEvent,damselRevenge=true}
    local amount=Rolls:ResolveActorDamage(contract,r.damsel,r.boss,tags)
    -- Rolls, defenses and trace adapters may invalidate work. Re-check physical
    -- admission after them and the exact packet again in EntityTakeDamage.
    from,to=self:Path(r)
    if not from then return false end
    local info=LOD.NewDamageInfo()
    info:SetAttacker(r.damsel);info:SetInflictor(r.damsel);info:SetDamage(math.max(0,amount))
    info:SetDamageType(DMG_BULLET);info:SetDamagePosition(to);info:SetDamageForce(vector_origin)
    Status:AttachDamageContext(info,tags)
    self.Packets[info]={r=r,source=copy(r.damsel:GetPos()),target=copy(to)}
    if not self:PacketValid(info,r.boss) then self.Packets[info]=nil;return false end
    Rolls:QueueDamageReport(info,function(final)
        Rolls:_Send({r.damsel,r.boss},0,Rolls:_DamageEventText(r.damsel,LOD.DieLogger:DamageFormula(contract),
            final,r.boss,Rolls:_PlayerRollDetail(contract),nil,'Gordon',"Damsel's Revenge"))
    end)
    local ok,err=pcall(r.boss.TakeDamageInfo,r.boss,info)
    self.Packets[info]=nil
    -- Shared report hooks normally drain this. An exception must not retain it.
    if Rolls.PendingDamageReports then Rolls.PendingDamageReports[info]=nil end
    if not ok then self:Retire(r,'native packet exception');log('DAMSEL_REVENGE_PACKET_ERROR',{error=tostring(err)});return false end
    r.shots=r.shots+1
    if self:Scope(r) then
        r.damsel:SetNW2Float('LOD_RevengeShot',now)
        r.damsel:SetNW2Vector('LOD_RevengeAim',to)
        r.damsel:EmitSound(r.spec.sound,68,100,.7)
        local fx=EffectData();fx:SetStart(from);fx:SetOrigin(to);util.Effect('Tracer',fx,true,true)
    end
    return true
end
-- Pure ownership transition: no body/model/pickup mutation in a lethal stack.
function D:OnGordonDeath(w,e)
    local r=w and w.revenge
    if not self:Scope(r) or r.boss~=e or not w.dead or not IsValid(e) or not e.LODDead or e:Health()>0
        or (r.level==20 and w.combatDeath~=e) then return end
    r.active=false;r.defeated=true
end
function D:Retire(r,why)
    if not r or r.retired then return end
    r.active=false;r.retired=true;r.reason=why
    self.cleanup[#self.cleanup+1]=r
    if self.current==r then self.current=nil end
end
function D:FlushCleanup()
    for _,r in ipairs(self.cleanup) do
        if IsValid(r.damsel) and r.damsel.LODRevengeOwner==r then
            r.damsel.LODRevengeOwner=nil;r.damsel:SetNW2String('LOD_RevengeGun','');r.damsel:SetNW2Float('LOD_RevengeUntil',0)
        end
        if IsValid(r.jail) and r.jail.LODRevengeOwner==r then r.jail.LODRevengeOwner=nil;r.jail:SetNW2Float('LOD_RevengePortUntil',0) end
        if IsValid(r.drop) and r.drop.LODRevengeReceipt==r then r.drop:Remove() end
        if IsValid(r.dropCandidate) and r.dropCandidate.LODRevengeReceipt==r then r.dropCandidate:Remove() end
        r.item=nil;r.drop=nil
    end
    self.cleanup={}
end
function D:AcceptedRescue(r)
    if not self:Scope(r,true) or not r.defeated or r.rescued or not r.state.LevelCleared
        or not (r.state.RescuedDamsels and r.state.RescuedDamsels[r.level]) then return false end
    r.active=false;r.rescued=true;r.dropTries=0
    return true
end
function D:CanCreateDrop(r,owner,pos,kind,payload)
    return self:Scope(r) and r.rescued and r.spawning and not r.dropped and not IsValid(r.dropCandidate)
        and owner==r.owner and kind=='wearable' and payload and payload.item==r.item
        and pos:DistToSqr(r.origin+Vector(0,0,6))==0
end
function D:Drop(r,now)
    if r.dropped or r.dropTries>=C.dropAttempts or now<(r.nextDrop or 0)
        or now>=(r.state.IntermissionEnd or 0) then return end
    r.dropTries=r.dropTries+1;r.nextDrop=now+C.service
    r.spawning=true
    local ok,ent=pcall(LOD.LootDirector.SpawnPickup,LOD.LootDirector,r.owner,
        r.origin+Vector(0,0,6),'wearable',{item=r.item},{equipmentEligible=false,damselRevenge=r})
    r.spawning=nil
    local candidate=r.dropCandidate;r.dropCandidate=nil
    if IsValid(candidate) and candidate.LODRevengeReceipt==r and (not ok or ent~=candidate or not self:Scope(r)) then candidate:Remove() end
    if not ok then
        r.dropTries=C.dropAttempts;log('DAMSEL_REVENGE_DROP_ERROR',{error=tostring(ent)});return
    end
    if not self:Scope(r) or not r.rescued then
        if IsValid(ent) then ent:Remove() end;return
    end
    if IsValid(ent) then
        r.dropped=true;r.drop=ent;ent.LODRevengeReceipt=r;r.pickupItem=ent.LODLootPayload.item
        log('DAMSEL_REVENGE_DROPPED',{owner=r.owner,item=r.item.id,attempt=r.dropTries})
    elseif r.dropTries==C.dropAttempts then log('DAMSEL_REVENGE_DROP_FAILED',{owner=r.owner,item=r.item.id,attempts=r.dropTries}) end
end
function D:CanCollect(ent,p)
    local r=IsValid(ent) and ent.LODRevengeReceipt
    return self:Scope(r) and r.rescued and r.dropped and r.drop==ent and not ent.LODCollected
        and r.state.LevelCleared and not r.state.SimulationFrozen and CurTime()<(r.state.IntermissionEnd or 0)
        and r.state.RescuedDamsels and r.state.RescuedDamsels[r.level] and hero(p)
        and R:GetPlayerState(p)==r.ownerState and R:IdentityOf(p)==r.owner and ent.LODLootOwnerIdentity==r.owner and ent.LODLootRegistered
        and ent.LODLootKind=='wearable' and ent.LODLootPayload and ent.LODLootPayload.item
        and ent.LODLootPayload.item==r.pickupItem and r.item and r.pickupItem.id==r.item.id and p:GetPos():DistToSqr(ent:GetPos())<=C.collectRange^2
end
-- The stationary rescue hull can cover the at-feet pickup. Forward its
-- native Touch/Use to the SAME deferred pickup claim, never grant directly.
function D:CollectAtFeet(d,p)
    local r=self.current
    if r and d==r.damsel and self:CanCollect(r.drop,p) and r.drop._TryCollect then
        r.drop:_TryCollect(p,true)
    end
end
function D:Service()
    self:FlushCleanup()
    local r=self.current
    if not r then return end
    if not self:Scope(r) then self:Retire(r,'scope');self:FlushCleanup();return end
    local now=CurTime()
    if now<(r.nextService or 0) then return end
    r.nextService=now+C.service
    if r.rescued then
        r.damsel:SetNW2String('LOD_RevengeGun','');r.damsel:SetNW2Float('LOD_RevengeUntil',0)
        r.jail:SetNW2Float('LOD_RevengePortUntil',0)
        self:Drop(r,now);return
    end
    if not r.defeated and (r.warden.dead or not IsValid(r.boss) or r.boss.LODDead
        or Rules:ProgressionState(r.boss)~=r.bossState or Status.ActorLives[r.boss]~=r.bossLife) then
        self:Retire(r,'Gordon life');self:FlushCleanup();return
    end
    if not self:ClockReady(r.state) then self:Retire(r,'clock');self:FlushCleanup();return end
    r.damsel:SetNW2Entity('LOD_RevengeJail',r.jail);r.jail:SetNW2Entity('LOD_RevengeDamsel',r.damsel)
    r.damsel:SetNW2String('LOD_RevengeGun',r.spec.class);r.damsel:SetNW2Float('LOD_RevengeUntil',now+C.lease)
    r.jail:SetNW2Float('LOD_RevengePortUntil',now+C.lease)
    if r.active and now>=r.nextShot then self:Fire(r,now) end
end
if not R.LODDamselRevengeWrapped then
    R.LODDamselRevengeWrapped=true
    local complete=R.CompleteLevel
    function R:CompleteLevel(p,...)
        local r=D.current
        local ready=D:Scope(r) and r.defeated and not r.rescued and LOD.ProgressionDirector:CanRescueTarget()
        local ok,why=complete(self,p,...)
        if ok and ready and not D:AcceptedRescue(r) then D:Retire(r,'rescue scope') end
        return ok,why
    end
end
hook.Add('PreCleanupMap','LOD_DamselRevengeCleanup',function() D:Retire(D.current,'map cleanup');D:FlushCleanup() end)
hook.Add('ShutDown','LOD_DamselRevengeShutdown',function() D:Retire(D.current,'shutdown');D:FlushCleanup() end)
concommand.Add('lod_damsel_revenge_testkit',function(p)
    local cv=GetConVar('lod_developer_mode')
    if not cv or not cv:GetBool() or not IsValid(p) or not p:IsAdmin() or not E:CanAct(p) then return end
    R:MarkUnranked('damsel_revenge_testkit')
    local state=E:Ensure(R:GetPlayerState(p));local item=state.items.damsel_revenge
    local n=item and item.count or 0
    if n<3 then E:Grant(p,'damsel_revenge',3-n) end
    E:Equip(state,'damsel_revenge','throwable');E:Activate(p)
    E:Report(p,"DAMSEL'S REVENGE TEST — use in a live Gordon court. Normal key/rescue/timer rules remain.",'damsel_revenge_testkit')
end)
