-- B11: sensory receipts live in FactionManager; finite movement/attacks remain
-- EnemyRoster commitments. No world scan, camera test or invisible-state override.
local E,F,N=LOD.EnemyRoster,LOD.FactionManager,LOD.MazeNavigator
local function copy(v) return Vector(v.x,v.y,v.z) end
local function flat(v) return Vector(v.x,v.y,0) end
local function running()
    local s=LOD.RunManager and LOD.RunManager.State
    return s and s.BuildReady and not s.Failed and not s.LevelCleared and not s.SimulationFrozen and s
end
F.Footsteps=F.Footsteps or setmetatable({}, {__mode="k"})
function F:RecordFootstep(p,position,volume)
    local s=running();local now=CurTime()
    -- Crouching suppresses this authored hearing signal even if a surface emits
    -- a quiet footstep. Muted is Magic silence, not physical silence.
    if not s or not self:CanAcquirePlayerTarget(p) or (volume or 0)<=0 or p:Crouching() then return end
    local old=self.Footsteps[p]
    if old and E:Live(old,s) and now<old.time+.2 then return end
    local cell=N:WorldToCell(s.Graph,position)
    if not E:MeleeCellLegal(s.Graph,cell) then return end
    local count=0
    for hero,r in pairs(self.Footsteps) do
        if now>=r.expires or not E:Live(r,s) or not self:CanAcquirePlayerTarget(hero) then self.Footsteps[hero]=nil
        else count=count+1 end
    end
    if not self.Footsteps[p] and count>=32 then return end
    LOD.RPGStatusElements:BindActorLife(p)
    self.Footsteps[p]=E:Bind({hero=p,position=copy(position),cell=cell,time=now,expires=now+1.5,
        heroState=LOD.RPGAbilityRules:ProgressionState(p),heroLife=LOD.RPGStatusElements.ActorLives[p]},s)
end
hook.Add("PlayerFootstep","LOD_BestiaryFootstepReceipt",function(p,pos,foot,sound,volume)
    F:RecordFootstep(p,pos,volume) -- never suppress or replace the actual sound
end)
function F:HeardFootstep(e,g)
    local now=CurTime();local cell=N:WorldToCell(g,e:GetPos());local best,dist
    for p,r in pairs(self.Footsteps) do
        if now<r.expires and E:Live(r,LOD.RunManager.State) and self:CanAcquirePlayerTarget(p)
            and r.heroState==LOD.RPGAbilityRules:ProgressionState(p) and r.heroLife==LOD.RPGStatusElements.ActorLives[p]
            and r.cell==cell and r.time>=(e.LODPerceptionBorn or now) and r~=(e.LODConsumedFootstep)
            and r.time>(e.LODPerceptionDiscardBefore or -1) then
            local distance=e:GetPos():DistToSqr(r.position)
            if distance<=320^2 and (not best or distance<dist or distance==dist and p:EntIndex()<best.hero:EntIndex()) then best=r;dist=distance end
        end
    end
    return best
end
function F:PerceptionHeroes(now)
    if now>=(self.NextPerceptionHeroes or 0) then
        self.NextPerceptionHeroes=now+.1;self.PerceptionHeroCache=player.GetAll()
    end
    return self.PerceptionHeroCache or {}
end
function F:ObservedTarget(e,g,now)
    local best,dist;local cell=N:WorldToCell(g,e:GetPos());local heroes=self:PerceptionHeroes(now)
    for i=1,math.min(32,#heroes) do
        local p=heroes[i]
        if self:CanAcquirePlayerTarget(p) and N:WorldToCell(g,p:GetPos())==cell then
            local distance=e:GetPos():DistToSqr(p:GetPos())
            if distance<=320^2 and E:Visible(e,p) and (not best or distance<dist or distance==dist and p:EntIndex()<best:EntIndex()) then best=p;dist=distance end
        end
    end
    return best
end
function F:Witnesses(e,g,now)
    local heroes=self:PerceptionHeroes(now)
    if #heroes>32 then return true end -- bounded fail-closed observation
    local cell=N:WorldToCell(g,e:GetPos())
    for _,p in ipairs(heroes) do
        if self:CanAcquirePlayerTarget(p) then
            local other=N:WorldToCell(g,p:GetPos())
            if cell and other and cell.z==other.z and e:GetPos():DistToSqr(p:GetPos())<=480^2 and E:Visible(e,p) then return true end
        end
    end
    return false
end
function E:ForgetPerception(e,p)
    if e.LODPerceptionMemory and e.LODPerceptionMemory.hero==p then e.LODPerceptionMemory=nil end
    local a=e.LODRosterAttack
    if self.Definitions[e.LODArchetypeId] and self.Definitions[e.LODArchetypeId].perception
        and a and a.target==p then self:Finish(e,CurTime()) end
end
function E:PerceptionRoute(e,a)
    local pos=e:GetPos()
    if not self:MeleeSupported(e,a.graph,a.cell,pos) or not self:MeleeRouteClear(e,pos,a.goal) then return false end
    local steps=math.max(1,math.ceil(pos:Distance(a.goal)/24))
    if steps>8 then return false end
    for i=1,steps do
        if not self:MeleeSupported(e,a.graph,a.cell,pos+(a.goal-pos)*(i/steps)) then return false end
    end
    return true
end
function E:BeginPerception(e,memory,now)
    if not self:ValidLife(memory.life) or not self:AcquireTarget(memory.hero) or not self:CanCast(e)
        or not LOD.RPGStatusElements:CanMoveVoluntarily(e) or now<(e.LODHitStunUntil or 0) then return false end
    local count=0
    for actor in pairs(self.Active) do
        if IsValid(actor) and actor.LODRosterAttack and actor.LODRosterAttack.perception then count=count+1 end
        if count>=16 then return false end
    end
    local start=copy(e:GetPos());local delta=flat(memory.position-start);local distance=delta:Length()
    if distance<32 then return false end
    local d=self.Definitions[e.LODArchetypeId]
    local a=self:Bind({perception=d.perception,kind="melee",target=memory.hero,life=memory.life,
        start=start,goal=start+delta:GetNormalized()*math.min(128,distance),cell=N:WorldToCell(memory.life.graph,start),
        ready=now+.8,expires=now+2.2,lastPos=start},LOD.RunManager.State)
    if not self:PerceptionRoute(e,a) then return false end
    e.LODRosterAttack=a
    e:SetNW2Int("LOD_RosterAttack",1);e:SetNW2Int("LOD_PerceptionMode",d.perception=="sound" and 1 or 2)
    e:SetNW2Vector("LOD_PerceptionStart",start);e:SetNW2Vector("LOD_PerceptionGoal",a.goal)
    e:SetNW2Float("LOD_PerceptionReady",a.ready);e:SetNW2Float("LOD_PerceptionUntil",a.expires)
    e:EmitSound(d.perception=="sound" and "npc/turret_floor/ping.wav" or "npc/fast_zombie/fz_alert_close1.wav",72,100,.7)
    LOD.HostileMotionV2:Stop(e);e:_SetActivity(ACT_IDLE)
    return true
end
function E:TickPerception(e,now)
    local motion=LOD.HostileMotionV2;local d=self.Definitions[e.LODArchetypeId]
    motion:Stop(e);e:_SetActivity(ACT_IDLE)
    e.LODPerceptionBorn=e.LODPerceptionBorn or now
    -- No ordinary omniscient route is used by these identities.
    e.LODTarget=nil
    if not self:CanCast(e) or not LOD.RPGStatusElements:CanMoveVoluntarily(e) then
        e.LODPerceptionMemory=nil;e.LODPerceptionDiscardBefore=now;return true
    end
    if now<(e.LODNextPerception or 0) or now<(e.LODNextAttack or 0) then return true end
    e.LODNextPerception=now+.1
    local s=LOD.RunManager.State;local memory
    if d.perception=="sound" then
        local r=F:HeardFootstep(e,s.Graph)
        if not r then return true end
        e.LODConsumedFootstep=r
        memory={hero=r.hero,position=copy(r.position),life=self:CaptureLife(e,r.hero),expires=now+2}
    else
        local p=F:ObservedTarget(e,s.Graph,now)
        if p then
            memory={hero=p,position=copy(p:GetPos()),life=self:CaptureLife(e,p),expires=now+2}
            e.LODPerceptionMemory=memory
            if flat(p:GetPos()-e:GetPos()):Length()<=d.range then self:BeginMelee(e,p,now) end
            return true
        end
        memory=e.LODPerceptionMemory;e.LODPerceptionMemory=nil
        if not memory or now>=memory.expires or not self:ValidLife(memory.life)
            or not self:AcquireTarget(memory.hero) or F:Witnesses(e,s.Graph,now) then return true end
    end
    -- Hearing allows a close attack only with fresh ordinary sight. Otherwise
    -- investigate the captured location; never read hidden movement to re-aim.
    local p=memory.hero
    if d.perception=="sound" and self:Visible(e,p) and flat(p:GetPos()-e:GetPos()):Length()<=d.range then
        self:BeginMelee(e,p,now)
    elseif not self:BeginPerception(e,memory,now) then e.LODNextAttack=now+.5 end
    return true
end
function E:StepPerception(e,a,now)
    if e.LODRosterAttack~=a then return end
    if not self:ValidLife(a.life) or not self:AcquireTarget(a.target) or not self:CanCast(e)
        or not LOD.RPGStatusElements:CanMoveVoluntarily(e) or now<(e.LODHitStunUntil or 0)
        or now>=a.expires or e:GetPos():DistToSqr(a.lastPos)>4^2
        or not self:PerceptionRoute(e,a) then self:Finish(e,now);return end
    if a.perception=="sight" and now>=(a.nextWitness or 0) then
        a.nextWitness=now+.1
        if F:Witnesses(e,a.graph,now) then self:Finish(e,now);return end
    end
    if not a.released then
        if now>a.ready+.2 then self:Finish(e,now);return end
        if now<a.ready then return end
        a.released=true;a.lastService=now;e.LODMotionLastUpdate=now;e:SetNW2Int("LOD_RosterAttack",2)
    elseif now-a.lastService>.2 then self:Finish(e,now);return end
    a.lastService=now
    LOD.HostileMotionV2:MoveToward(e,{pos=a.goal});a.lastPos=copy(e:GetPos())
    -- Investigation itself is harmless. A later fresh sensory cue and full
    -- ordinary melee warning are required before any damage can be delivered.
    if e:GetPos():DistToSqr(a.goal)<=.05^2 then self:Finish(e,now) end
end
