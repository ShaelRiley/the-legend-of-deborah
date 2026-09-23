-- Ally support shares roster scheduling, status lifetimes, Block and targeting.
-- This module owns commitments and eligibility, never HP/mitigation/status clocks.
LOD.EnemySupport = LOD.EnemySupport or {}
local S = LOD.EnemySupport
local E = LOD.EnemyRoster
local Status = LOD.RPGStatusElements
S.Profiles = {
    recovery={index=1,range=360,warning=1.5,cooldown=6},
    protection={index=2,range=240,warning=1,cooldown=8,duration=6,status="support_guard"},
    rally={index=3,range=420,warning=1,cooldown=8,duration=4,status="support_rally"}
}
S.Pending=S.Pending or setmetatable({}, {__mode="k"})
S.Recipients=S.Recipients or setmetatable({}, {__mode="k"})
S.MaxCandidates=128
local excluded={warden=true,neil=true,brute=true,hector=true}
local function state() return LOD.RunManager and LOD.RunManager.State end
local function liveRun(s) return s and s.BuildReady and not s.Failed and not s.LevelCleared and not s.SimulationFrozen end
local function identity(a) return LOD.RPGAbilityRules:ProgressionState(a) end
local function living(a) return IsValid(a) and not a.LODDead and a:Health()>0 end
function S:Ordinary(a)
    return living(a) and a.LODHostile and a.LODActivated and not a.LODSkeletonHero
        and not a.LODHector and not a.LODWardenClone and not excluded[a.LODArchetypeId]
end
function S:CanSupport(e,kind)
    return self:Ordinary(e) and liveRun(state())
        and (not e.LODRosterContext or E:Live(e.LODRosterContext,state())) and CurTime()>=(e.LODHitStunUntil or 0)
        and Status:CanInitiateAttack(e) and not Status:Has(e,"morale_flee")
        and (kind=="rally" or Status:CanInitiateMagic(e))
end
function S:NearCells(graph,from,to)
    local wanted=E.Key(to);local frontier={from};local seen={[E.Key(from)]=true}
    for depth=0,2 do
        local nextCells={}
        for _,cell in ipairs(frontier) do
            if E.Key(cell)==wanted then return true end
            if depth<2 then
                for key in pairs(cell.neighbors or {}) do
                    local other=graph.Cells[key]
                    if other and other.z==from.z and not seen[key]
                        and LOD.MazeNavigator:CanTraverse(graph,E.Key(cell),key) then
                        seen[key]=true;nextCells[#nextCells+1]=other
                    end
                end
            end
        end
        frontier=nextCells
    end
    return false
end
function S:Eligible(source,target,range)
    if source==target or not self:Ordinary(source) or not self:Ordinary(target)
        or not LOD.FactionManager:IsEnemyCombatant(target) then return false end
    if source:GetPos():DistToSqr(target:GetPos())>range*range then return false end
    local run=state();local graph=run and run.Graph
    if not liveRun(run) or not graph then return false end
    local n=LOD.MazeNavigator
    local from=n:WorldToCell(graph,source:GetPos());local to=n:WorldToCell(graph,target:GetPos())
    if not from or not to or E:Safe(graph,from) or E:Safe(graph,to)
        or from.z~=to.z or not self:NearCells(graph,from,to) then return false end
    return E:Visible(source,target)
end
function S:Select(source,kind)
    local p=self.Profiles[kind];if not p then return {} end
    local candidates={}
    -- HostileRegistry is cached and EntIndex-sorted. No global entity scan.
    for index,target in ipairs(LOD.HostileRegistry:List()) do
        if index>self.MaxCandidates then break end
        if self:Eligible(source,target,p.range)
            and (kind~="recovery" or (target:Health()<target:GetMaxHealth() and not Status:Has(target,"support_mending")))
            and (not p.status or not Status:Has(target,p.status)) then
            candidates[#candidates+1]=target
        end
    end
    table.sort(candidates,function(a,b)
        if kind=="recovery" then
            local ah=a:Health()/math.max(1,a:GetMaxHealth());local bh=b:Health()/math.max(1,b:GetMaxHealth())
            if ah~=bh then return ah<bh end
        end
        local ad=source:GetPos():DistToSqr(a:GetPos());local bd=source:GetPos():DistToSqr(b:GetPos())
        if ad~=bd then return ad<bd end
        return a:EntIndex()<b:EntIndex()
    end)
    local out={}
    for i=1,math.min(kind=="rally" and 3 or 1,#candidates) do out[i]=candidates[i] end
    return out
end
function S:Capture(source,target,kind,hero)
    Status:BindActorLife(source);Status:BindActorLife(target)
    if hero then Status:BindActorLife(hero) end
    return E:Bind({source=source,target=target,kind=kind,hero=hero,
        sourceState=identity(source),targetState=identity(target),heroState=hero and identity(hero),
        sourceLife=Status.ActorLives[source],targetLife=Status.ActorLives[target],heroLife=hero and Status.ActorLives[hero]},state())
end
function S:ValidRecord(r)
    local p=r and self.Profiles[r.kind]
    if not p or not liveRun(state()) or not E:Live(r,state()) or not self:CanSupport(r.source,r.kind)
        or not self:Eligible(r.source,r.target,p.range) then return false end
    if identity(r.source)~=r.sourceState or identity(r.target)~=r.targetState
        or Status.ActorLives[r.source]~=r.sourceLife or Status.ActorLives[r.target]~=r.targetLife then return false end
    if r.kind=="rally" then
        return E:AcquireTarget(r.hero) and identity(r.hero)==r.heroState and Status.ActorLives[r.hero]==r.heroLife
            and r.source:GetPos():DistToSqr(r.hero:GetPos())<=600^2 and E:Visible(r.source,r.hero)
            and E:Visible(r.target,r.hero)
    end
    return true
end
function S:ValidEntry(target,entry)
    return entry and entry.support and entry.support.target==target and self:ValidRecord(entry.support)
end
function S:ClearMending(source,a)
    if not a or a.kind~="recovery" then return end
    for _,record in ipairs(a.records) do
        local entry=Status.Active[record.target] and Status.Active[record.target].support_mending
        if entry and entry.source==source and entry.support==record then Status:Clear(record.target,"support_mending","channel ended") end
    end
end
function S:Cancel(source)
    self:ClearMending(source,self.Pending[source])
    self.Pending[source]=nil
    if IsValid(source) then
        source.LODSupportCast=nil;source:SetNW2Int("LOD_SupportKind",0)
    end
end
function S:Interrupt(source)
    self:Cancel(source)
    for target in pairs(self.Recipients) do
        for _,id in ipairs({"support_guard","support_rally","support_mending"}) do
            local entry=Status.Active[target] and Status.Active[target][id]
            if entry and entry.source==source then Status:Clear(target,id,"source interrupted") end
        end
    end
end
function S:Begin(source,hero,now)
    local d=E.Definitions[source.LODArchetypeId];local kind=d and d.support
    local p=kind and self.Profiles[kind]
    if not p or self.Pending[source] or source.LODRosterAttack or now<(source.LODNextSupport or 0)
        or not self:CanSupport(source,kind) or not E:AcquireTarget(hero) or not E:Visible(source,hero)
        or source:GetPos():DistToSqr(hero:GetPos())>600^2 then return false end
    local selected=self:Select(source,kind);if #selected==0 then return false end
    local records={}
    for _,target in ipairs(selected) do
        local record=self:Capture(source,target,kind,kind=="rally" and hero or nil)
        if self:ValidRecord(record) then records[#records+1]=record end
    end
    if #records==0 then return false end
    local a={kind=kind,records=records,ready=now+p.warning}
    if kind=="recovery" then
        local record=records[1]
        local ok=Status:Apply(record.target,"support_mending",source,{direct=true,duration=p.warning+.2,
            valid=function(actor,entry) return S:ValidEntry(actor,entry) end,support=record})
        if not ok then return false end
        self.Recipients[record.target]=true
    end
    self.Pending[source]=a;source.LODSupportCast=a;source.LODNextSupport=now+p.warning+p.cooldown
    source:SetNW2Int("LOD_SupportKind",p.index);source:SetNW2Float("LOD_SupportReady",a.ready)
    source:SetNW2Entity("LOD_SupportTarget",records[1].target)
    source:EmitSound(kind=="rally" and "npc/metropolice/vo/moveit.wav" or "npc/vort/attack_charge.wav",72,100,.7)
    source:_SetActivity(ACT_RANGE_ATTACK1 or ACT_IDLE,true)
    return true
end
function S:Resolve(source,a,now)
    if self.Pending[source]~=a or now<a.ready then return false end
    -- Claim once before callbacks; stale/reentrant releases cannot restore twice.
    self.Pending[source]=nil
    local p=self.Profiles[a.kind]
    for _,record in ipairs(a.records) do
        if self:ValidRecord(record) then
            local target=record.target
            if a.kind=="recovery" then
                -- Reuse capped restoration without potion cures or crypto rewards.
                local amount=math.min(24,math.max(1,math.ceil(target:GetMaxHealth()*.12)))
                local reserved,entry=Status:Has(target,"support_mending")
                if reserved and entry.support==record and LOD.LootDirector:_GrantHealth(target,amount) then
                    target:EmitSound("items/smallmedkit1.wav",65,100,.65)
                    target:SetNW2Float("LOD_SupportHealedAt",now)
                end
            else
                local ok=Status:Apply(target,p.status,source,{direct=true,duration=p.duration,
                    valid=function(actor,entry) return S:ValidEntry(actor,entry) end,support=record})
                if ok then
                    self.Recipients[target]=true
                    target:SetNW2Entity(a.kind=="rally" and "LOD_SupportRallySource" or "LOD_SupportGuardSource",source)
                    target.LODNextTargetRefresh=0;target.LODNextRouteRefresh=0
                end
            end
        end
    end
    self:ClearMending(source,a)
    self:Cancel(source)
    if IsValid(source) then source.LODNextAttack=math.max(source.LODNextAttack or 0,now+.6) end
    return true
end
function S:Tick(source,now)
    if self.Pending[source] then return true end
    if source.LODRosterAttack or now<(source.LODNextSupportScan or 0) then return false end
    source.LODNextSupportScan=now+.3
    source:_RefreshTarget(state().Graph)
    return self:Begin(source,source.LODTarget,now)
end
function S:Service(now,active)
    if now<(self.NextService or 0) then return end
    self.NextService=now+.1
    for source,a in pairs(self.Pending) do
        if not active or not IsValid(source) or not self:ValidRecord(a.records[1]) then self:Cancel(source)
        elseif now>=a.ready then self:Resolve(source,a,now) end
    end
    for target in pairs(self.Recipients) do
        local guard=Status:Has(target,"support_guard");local rally=Status:Has(target,"support_rally")
        local mending=Status:Has(target,"support_mending")
        if not guard and not rally and not mending then self.Recipients[target]=nil end
    end
end
function S:RallyTarget(actor,graph,home)
    local applied,entry=Status:Has(actor,"support_rally")
    if not applied then return nil end
    local target=entry.support.hero
    local cell=LOD.MazeNavigator:WorldToCell(graph,target:GetPos())
    local distance=cell and home and LOD.MazeNavigator:Distance(graph,home,cell) or math.huge
    if distance<=LOD.Config.Encounter.LeashCells then return target,distance end
end
hook.Add("LODStatusCleared","LOD_EnemySupportClear",function(target,id)
    if not IsValid(target) then return end
    if id=="support_rally" then
        target.LODNextTargetRefresh=0;target.LODNextRouteRefresh=0;target.LODTarget=nil
        target:SetNW2Entity("LOD_SupportRallySource",NULL)
    elseif id=="support_guard" then target:SetNW2Entity("LOD_SupportGuardSource",NULL) end
end)
hook.Add("EntityRemoved","LOD_EnemySupportRemoved",function(source) S:Interrupt(source) end)
hook.Add("OnNPCKilled","LOD_EnemySupportDeath",function(source) S:Interrupt(source) end)
