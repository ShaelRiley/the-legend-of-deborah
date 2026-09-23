-- B8 receipts belong to actual corpses, never to living attack contracts.
-- Native death/presentation owns admission, lifetime, removal and rewards.
LOD.EnemyRemains=LOD.EnemyRemains or {}
local R,E,N=LOD.EnemyRemains,LOD.EnemyRoster,LOD.MazeNavigator
local Status,Rules=LOD.RPGStatusElements,LOD.RPGAbilityRules
R.Active=R.Active or {};R.Pending=R.Pending or {};R.Count=R.Count or 0
local excluded={neil=true,brute=true,warden=true,hector=true}
local function state() return LOD.RunManager and LOD.RunManager.State end
local function active(s) return s and s.BuildReady and not s.Failed and not s.LevelCleared and not s.SimulationFrozen end
local function copy(p) return Vector(p.x,p.y,p.z) end
function R:Seal(e)
    if e.LODRemainsReceipt or not IsValid(e) or not e.LODDead or e:Health()>0 or not e.LODHostile
        or e:IsPlayer() or excluded[e.LODArchetypeId] or e.LODSkeletonHero or e.LODWardenClone or e.LODHector
        or not LOD.Config.Encounter.Archetypes[e.LODArchetypeId] or not active(state())
        or e.LODRosterContext and not E:Live(e.LODRosterContext,state()) or self.Count>=96 then return end
    local r=E:Bind({source=e,sourceState=Rules:ProgressionState(e),livingLife=Status.ActorLives[e],
        sealedAt=CurTime(),origin=copy(e:GetPos())},state())
    e.LODRemainsReceipt=r;self.Active[r]=true;self.Count=self.Count+1
    return r
end
function R:Retire(r)
    if not r or not self.Active[r] then return end
    self.Active[r]=nil;self.Count=self.Count-1;r.retired=true
    if r.claim then self:Interrupt(r.claim) end
    if IsValid(r.source) then r.source:SetNW2Float("LOD_RemainsBurstUntil",0) end
end
-- Reward eligibility outlives the gameplay warning, not the defeated identity.
-- Consumption/interruption/ordinary expiry cannot mint or revoke another drop.
function R:RewardOwned(e)
    local r=e.LODRemainsReceipt
    return r and IsValid(e) and r.source==e and E:Live(r,state()) and e.LODDead and e:Health()<=0
        and Rules:ProgressionState(e)==r.sourceState
        and (not r.corpseLife or Status.ActorLives[e]==r.corpseLife)
end
function R:CorpseLive(r)
    local e=r and r.source
    return r and self.Active[r] and not r.retired and active(state()) and E:Live(r,state())
        and IsValid(e) and e.LODRemainsReceipt==r and e.LODDead and e:Health()<=0
        and Rules:ProgressionState(e)==r.sourceState and r.record and r.record.hostile==e and not r.record.finished
        and Status.ActorLives[e]==r.corpseLife and CurTime()<r.expires
        and e:GetPos():DistToSqr(r.origin)<=4^2 and E:MeleeSupported(e,r.graph,r.cell,r.origin)
end
function R:Open(e,record)
    local r=e.LODRemainsReceipt
    if not r or not self.Active[r] or r.record then return end
    if not active(state()) or not E:Live(r,state()) or not e.LODDead or e:Health()>0
        or Rules:ProgressionState(e)~=r.sourceState or CurTime()>r.sealedAt+.1
        or Status.ActorLives[e] and Status.ActorLives[e]~=r.livingLife then self:Retire(r);return end
    -- A dying status actor may already have been retired by the status service.
    -- Clear it now, once, before creating the distinct post-defeat incarnation.
    Status:ResetActorLife(e);Status:BindActorLife(e);r.corpseLife=Status.ActorLives[e]
    r.record=record;r.expires=record.startedAt+1;r.cell=N:WorldToCell(r.graph,r.origin)
    if not self:CorpseLive(r) then self:Retire(r);return end
    if e.LODArchetypeId=="afterburst" then
        r.ready=record.startedAt+.8;r.deadline=r.ready+.1;r.participants={}
        local heroes=player.GetAll()
        for i=1,math.min(32,#heroes) do
            local p=heroes[i]
            if E:Target(p) then
                Status:BindActorLife(p)
                r.participants[#r.participants+1]={hero=p,life=Status.ActorLives[p],progression=Rules:ProgressionState(p)}
            end
        end
        e:SetNW2Vector("LOD_RemainsOrigin",r.origin);e:SetNW2Float("LOD_RemainsBurstReady",r.ready)
        e:SetNW2Float("LOD_RemainsBurstUntil",r.deadline)
        e:EmitSound("npc/roller/mine/rmine_blades_out1.wav",75,85,.8)
    end
    self:Offer(r)
end
function R:CanFeed(e,r)
    return IsValid(e) and e.LODArchetypeId=="carrion" and e.LODActivated and not e.LODDead and e:Health()>0
        and e:Health()<e:GetMaxHealth() and LOD.FactionManager:IsEnemyCombatant(e)
        and not e.LODSkeletonHero and not e.LODWardenClone and not e:IsPlayer()
        and self:CorpseLive(r) and not r.consumed and e:GetPos():DistToSqr(r.origin)<=240^2
        and E:MeleeSupported(e,r.graph,r.cell,e:GetPos()) and E:Visible(e,r.source,e:WorldSpaceCenter())
        and CurTime()>=(e.LODHitStunUntil or 0) and Status:CanInitiateAttack(e) and not Status:Has(e,"morale_flee")
end
function R:Offer(r)
    if r.claimed or not self:CorpseLive(r) then return end
    local candidates={};local now=CurTime()
    for i,e in ipairs(LOD.HostileRegistry:List()) do
        if i>128 then break end
        if not self.Pending[e] and not e.LODRosterAttack and now>=(e.LODNextFeed or 0) and self:CanFeed(e,r) then
            candidates[#candidates+1]=e
        end
    end
    table.sort(candidates,function(a,b)
        local ad,bd=a:GetPos():DistToSqr(r.origin),b:GetPos():DistToSqr(r.origin)
        if ad~=bd then return ad<bd end
        return a:EntIndex()<b:EntIndex()
    end)
    for _,e in ipairs(candidates) do
        e:_RefreshTarget(r.graph);local hero=e.LODTarget
        if E:AcquireTarget(hero) and e:GetPos():DistToSqr(hero:GetPos())<=600^2 and E:Visible(e,hero) then
            local a={corpse=r,life=E:CaptureLife(e,hero),origin=copy(e:GetPos()),ready=now+.6}
            r.claimed=true;r.claim=e;self.Pending[e]=a;e.LODNextFeed=now+6
            e:SetNW2Entity("LOD_RemainsTarget",r.source);e:SetNW2Vector("LOD_RemainsFeedOrigin",a.origin)
            e:SetNW2Vector("LOD_RemainsFeedAim",r.origin);e:SetNW2Float("LOD_RemainsFeedReady",a.ready)
            e:SetNW2Float("LOD_RemainsFeedUntil",a.ready+.1)
            LOD.HostileMotionV2:Stop(e);e:_SetActivity(ACT_RANGE_ATTACK1 or ACT_IDLE,true)
            e:EmitSound("npc/barnacle/barnacle_pull1.wav",72,90,.7)
            return
        end
    end
end
function R:Interrupt(e)
    if not self.Pending[e] then return end
    self.Pending[e]=nil
    if IsValid(e) then
        e:SetNW2Float("LOD_RemainsFeedUntil",0);e:SetNW2Entity("LOD_RemainsTarget",NULL)
        e.LODNextAttack=math.max(e.LODNextAttack or 0,CurTime()+.6)
    end
end
function R:FeedLive(e,a)
    return self.Pending[e]==a and E:ValidLife(a.life) and self:CanFeed(e,a.corpse)
        and a.corpse.claim==e and e:GetPos():DistToSqr(a.origin)<=4^2
        and E:AcquireTarget(a.life.hero) and E:Visible(e,a.life.hero)
        and e:GetPos():DistToSqr(a.life.hero:GetPos())<=600^2
end
function R:Feed(e,a,now)
    if not self:FeedLive(e,a) or now<a.ready or now>a.ready+.1 then return false end
    local r=a.corpse
    -- Claim before callbacks. Neither interruptions nor a second scavenger can
    -- recycle the corpse, HP grant, XP or the ordinary deferred loot handoff.
    r.consumed=true;self:Interrupt(e)
    r.source:SetNW2Float("LOD_RemainsBurstUntil",0);r.source:SetNoDraw(true)
    if LOD.LootDirector:_GrantHealth(e,math.min(30,math.max(1,math.ceil(e:GetMaxHealth()*.20)))) then
        e:EmitSound("npc/barnacle/barnacle_gulp1.wav",70,100,.7)
    end
    return true
end
function R:Burst(r,now)
    if not self:CorpseLive(r) or r.consumed or r.released or not r.ready or now<r.ready or now>r.deadline then return false end
    r.released=true;r.source:SetNW2Float("LOD_RemainsBurstUntil",0)
    local event={impactOrigin=r.origin+Vector(0,0,40)}
    for _,life in ipairs(r.participants) do
        local p=life.hero
        if not self:CorpseLive(r) or r.consumed then break end
        if E:Target(p) and p:Health()>0 and Status.ActorLives[p]==life.life and Rules:ProgressionState(p)==life.progression then
            local delta=p:GetPos()-r.origin;local height=delta.z+2
            if N:WorldToCell(r.graph,p:GetPos())==r.cell and height>=-4 and height<=72
                and delta.x^2+delta.y^2<=128^2 and E:Visible(r.source,p,event.impactOrigin) then
                -- Only this receipt-owned seam may call the shared packet builder
                -- for a dead actor. E:Damage and ValidSourceLife stay unchanged.
                E:_DamagePacket(r.source,p,event,"burst")
            end
        end
    end
    if IsValid(r.source) then r.source:EmitSound("ambient/explosions/explode_4.wav",78,120,.6) end
    return true
end
function R:Service(now,enabled)
    for r in pairs(self.Active) do
        if not enabled or (r.record and not self:CorpseLive(r)) or (not r.record and now>r.sealedAt+.1) then self:Retire(r) end
    end
    for e,a in pairs(self.Pending) do
        if not enabled or not self:FeedLive(e,a) or now>a.ready+.1 then self:Interrupt(e)
        elseif now>=a.ready then self:Feed(e,a,now) end
    end
    for r in pairs(self.Active) do
        if r.ready and not r.released and not r.consumed and now>=r.ready then
            if now>r.deadline then r.released=true;r.source:SetNW2Float("LOD_RemainsBurstUntil",0)
            else self:Burst(r,now) end
        end
    end
end
hook.Add("EntityRemoved","LOD_EnemyRemainsRemoved",function(e) R:Interrupt(e);R:Retire(e.LODRemainsReceipt) end)
