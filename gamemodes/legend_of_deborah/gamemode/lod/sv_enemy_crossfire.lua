-- B15 physical mistakes retain faction targeting, canonical damage and lifecycle.
local E,F,N=LOD.EnemyRoster,LOD.FactionManager,LOD.MazeNavigator
local Status,Rules=LOD.RPGStatusElements,LOD.RPGAbilityRules
local permits=setmetatable({}, {__mode="k"})
local packets=setmetatable({}, {__mode="k"})
local excluded={neil=true,brute=true,warden=true,hector=true}
local function copy(v) return Vector(v.x,v.y,v.z) end
local function flat(v) return Vector(v.x,v.y,0) end
function E:CrossfireOrdinary(p)
    return IsValid(p) and p.LODHostile and p.LODActivated and not p:IsPlayer()
        and not p.LODDead and p:Health()>0 and not excluded[p.LODArchetypeId]
        and not p.LODSkeletonHero and not p.LODWardenClone and not p.LODHector
        and not p.LODFriendlySummon and not p.LODSummonedSeeker and F:IsEnemyCombatant(p)
end
function E:CrossfireRecipient(a,r)
    local p=r and r.hero
    return r and self:ValidSourceLife(a.life) and IsValid(p) and p~=a.life.source
        and p:Health()>0 and not p.LODDead and (r.ordinary and self:CrossfireOrdinary(p) or not r.ordinary and self:Target(p))
        and Status.ActorLives[p]==r.heroLife and Rules:ProgressionState(p)==r.heroState
        and N:WorldToCell(a.graph,p:GetPos())==a.cell
        and (not p.LODRosterContext or self:Live(p.LODRosterContext,LOD.RunManager.State))
end
function E:CrossfireLive(e,a)
    return IsValid(e) and e.LODRosterAttack==a and self:ValidSourceLife(a.life)
        and CurTime()<=a.deadline and self:CanCast(e) and CurTime()>=(e.LODHitStunUntil or 0)
        and e:GetPos():DistToSqr(a.origin)<=4^2
end
function E:CrossfireInside(a,p)
    local delta=p:GetPos()-a.aim
    return N:WorldToCell(a.graph,p:GetPos())==a.cell and delta.z>=-4 and delta.z<=72
        and flat(delta):LengthSqr()<=72^2
end
function E:CrossfireCover(e,from,to)
    local tr=util.TraceLine({start=from,endpos=to,mask=MASK_SOLID,
        filter=function(v) return v~=e and not v.LODHostile and not v:IsPlayer() end})
    return not tr.Hit and not tr.StartSolid and not tr.AllSolid
end
function E:CrossfireSpace(e,a)
    if not self:MeleeSupported(e,a.graph,a.cell,e:GetPos())
        or not self:MeleeSupported(e,a.graph,a.cell,a.mark) then return false end
    local side=Vector(-a.direction.y,a.direction.x,0)
    for _,r in ipairs(a.endangered) do
        if not IsValid(r.hero) then return false end
        local lo,hi=r.hero:GetCollisionBounds()
        -- Admission positions stay frozen: leaving a blast never cancels bait.
        for _,sign in ipairs({-1,1}) do
            local goal=r.ground+side*(96*sign)
            if a.crossfire==2 and flat(goal-a.aim):LengthSqr()<=72^2 then return false end
            local tr=util.TraceHull({start=r.ground,endpos=goal,mins=lo,maxs=hi,mask=MASK_PLAYERSOLID,
                filter=function(v) return v~=r.hero and not v.LODHostile and not v:IsPlayer() end})
            if tr.Hit or tr.StartSolid or tr.AllSolid then return false end
            for i=0,4 do
                if not self:MeleeSupported(r.hero,a.graph,a.cell,r.ground+(goal-r.ground)*(i/4)) then return false end
            end
        end
    end
    return true
end
function E:BeginCrossfire(e,p,now)
    local d=self.Definitions[e.LODArchetypeId];local s=LOD.RunManager.State
    if e.LODRosterAttack or not d or not d.crossfire or not self:AcquireTarget(p) or p:Health()<=0
        or not self:CanCast(e) or now<(e.LODNextAttack or 0) or now<(e.LODHitStunUntil or 0)
        or not s or not s.Graph or not s.BuildReady or s.Failed or s.LevelCleared or s.SimulationFrozen then return false end
    local function deny() e.LODNextAttack=now+.5;e.LODCrossfireAdvanceUntil=now+.5;return false end
    local life=self:CaptureLife(e,p)
    if not self:ValidLife(life) or not self:Visible(e,p) or e:GetPos():DistToSqr(p:GetPos())>360^2 then return deny() end
    local heroes,hostiles=F:PerceptionHeroes(now),LOD.HostileRegistry:List()
    if #heroes>32 or #hostiles>128 then return deny() end
    local count=0
    for source in pairs(self.Active) do
        local old=IsValid(source) and source.LODRosterAttack
        if old and old.crossfire then count=count+1 end
    end
    if count>=16 then return deny() end
    local origin=copy(e:GetPos());local mark=copy(p:GetPos());local direction=flat(mark-origin):GetNormalized()
    if direction:LengthSqr()<.01 then return deny() end
    local a=self:Bind({crossfire=d.crossfire,kind="bullet",life=life,target=p,origin=origin,mark=mark,
        aim=copy(d.crossfire==1 and p:WorldSpaceCenter() or mark),direction=direction,
        cell=N:WorldToCell(s.Graph,origin),ready=now+d.warning,last=now,recipients={},endangered={},hits={}},s)
    a.deadline=a.ready+.2;a.event={impactOrigin=d.crossfire==1 and origin+Vector(0,0,48) or mark+Vector(0,0,24)}
    for _,list in ipairs({heroes,hostiles}) do
        for _,candidate in ipairs(list) do
            local ordinary=self:CrossfireOrdinary(candidate)
            if candidate~=e and (ordinary or self:AcquireTarget(candidate)) and not a.recipients[candidate]
                and N:WorldToCell(s.Graph,candidate:GetPos())==a.cell
                and candidate:GetPos():DistToSqr(origin)<=(d.crossfire==2 and 432 or 360)^2 then
                local r=self:CaptureLife(e,candidate);r.ordinary=ordinary;a.recipients[candidate]=r
                if not ordinary then
                    r.ground=copy(candidate:GetPos());r.lo,r.hi=candidate:GetCollisionBounds()
                    -- Conservative line danger includes the Hero's actual hull.
                    local offset=flat(r.ground-origin);local side=Vector(-direction.y,direction.x,0)
                    local hx=math.max(math.abs(r.lo.x),math.abs(r.hi.x));local hy=math.max(math.abs(r.lo.y),math.abs(r.hi.y))
                    local radius=math.sqrt(hx*hx+hy*hy)+4
                    if d.crossfire==2 and self:CrossfireInside(a,candidate)
                        or d.crossfire==1 and offset:Dot(direction)>=-radius and offset:Dot(direction)<=flat(mark-origin):Length()+radius
                        and math.abs(offset:Dot(side))<=radius then a.endangered[#a.endangered+1]=r end
                end
            end
        end
    end
    if not a.recipients[p] or not self:CrossfireSpace(e,a) then return deny() end
    self.Active[e]=true;e.LODRosterAttack=a;e.LODCrossfireAdvanceUntil=nil
    LOD.HostileMotionV2:Stop(e)
    e:SetNW2Int("LOD_RosterAttack",1);e:SetNW2Int("LOD_CrossfireMode",a.crossfire)
    e:SetNW2Vector("LOD_CrossfireOrigin",a.origin);e:SetNW2Vector("LOD_CrossfireAim",a.aim)
    e:SetNW2Float("LOD_CrossfireReady",a.ready);e:SetNW2Float("LOD_CrossfireUntil",a.deadline)
    if not self:CrossfireLive(e,a) or not self:ValidLife(a.life) then if e.LODRosterAttack==a then self:Cancel(e) end;return false end
    e:EmitSound("npc/combine_soldier/vo/overwatch.wav",72,100,.75)
    if self:CrossfireLive(e,a) then e:_SetActivity(ACT_RANGE_ATTACK1 or ACT_IDLE,true) end
    return e.LODRosterAttack==a
end
-- The faction hook accepts only this exact, currently settling native packet.
-- Tags/actor flags alone never authorize ordinary allied damage.
function E:AuthorizeCrossfire(info,e,p,a)
    if a.settling and a.hits[p] and self:CrossfireLive(e,a) and self:CrossfireRecipient(a,a.recipients[p]) then
        local record={source=e,target=p,attack=a}
        permits[info]=record;packets[info]=record
    end
end
function E:RevokeCrossfire(info)
    permits[info]=nil
    if packets[info] then packets[info].finished=true end
end
local previousDamage=GM.EntityTakeDamage
local function packetLive(target,info)
    local r=packets[info]
    return not r or not r.finished and target==r.target and info:GetAttacker()==r.source
        and info:GetInflictor()==r.source and E:CrossfireLive(r.source,r.attack)
        and E:CrossfireRecipient(r.attack,r.attack.recipients[r.target])
end
function GM:EntityTakeDamage(target,info)
    local record=packets[info]
    if not packetLive(target,info) or record and record.entered then info:SetDamage(0);return true end
    if record then record.entered=true end -- claim once before mitigation can reenter
    local result=previousDamage and previousDamage(self,target,info)
    -- The actual native HP write follows this seam. Defense/report callbacks
    -- may have replaced an incarnation after the faction hook admitted it.
    if not packetLive(target,info) then info:SetDamage(0);return true end
    return result
end
function E:AllowsCrossfire(info,e,p)
    local permit=permits[info];local a=permit and permit.attack
    permits[info]=nil -- single native admission, even if a hook replays this object
    return permit and permit.source==e and permit.target==p and info:GetInflictor()==e
        and a.settling and self:CrossfireLive(e,a) and self:CrossfireRecipient(a,a.recipients[p])
end
function E:CrossfireDamage(e,a,p)
    local r=a.recipients[p]
    if a.hits[p] or not a.settling or not self:CrossfireLive(e,a) or not self:CrossfireRecipient(a,r) then return end
    a.hits[p]=true
    -- One roll is shared, but every target's own mitigation/context stays native.
    a.event.crossfireAttack=a
    a.event.crossfireGate=function() return self:CrossfireLive(e,a) and self:CrossfireRecipient(a,r) end
    return self:_DamagePacket(e,p,a.event,"bullet")
end
function E:StepCrossfire(e,a,now)
    if not IsValid(e) or e.LODRosterAttack~=a then return end
    if not self:ValidSourceLife(a.life) then self:Cancel(e);return end
    if a.settling then
        if now>a.deadline then self:Finish(e,now) end
        return
    end
    if not self:CrossfireLive(e,a) or not self:ValidLife(a.life) or a.target:Health()<=0
        or not self:AcquireTarget(a.target) or not self:Visible(e,a.target) or now-a.last>.25 then self:Finish(e,now);return end
    a.last=now
    if now>=(a.nextGeometry or 0) or now>=a.ready then
        a.nextGeometry=now+.2
        if not self:CrossfireSpace(e,a) then self:Finish(e,now);return end
    end
    if now<a.ready then return end
    a.settling=true;a.recoveryUntil=now+self.Definitions[e.LODArchetypeId].recovery -- claim before callbacks
    if a.crossfire==1 then
        local tr=util.TraceHull({start=a.origin+Vector(0,0,48),endpos=a.aim,
            mins=Vector(-4,-4,-4),maxs=Vector(4,4,4),mask=MASK_SHOT,filter=e})
        if not tr.StartSolid and not tr.AllSolid and IsValid(tr.Entity) then self:CrossfireDamage(e,a,tr.Entity) end
    elseif self:CrossfireCover(e,a.origin+Vector(0,0,48),a.aim+Vector(0,0,24)) then
        -- Freeze simultaneous area admission before damage callbacks. Native
        -- death of one recipient never changes another recipient's admission.
        local victims={}
        for p,r in pairs(a.recipients) do
            if self:CrossfireRecipient(a,r) and self:CrossfireInside(a,p)
                and self:CrossfireCover(e,a.aim+Vector(0,0,24),p:WorldSpaceCenter()) then victims[#victims+1]=p end
        end
        table.sort(victims,function(x,y) return x:EntIndex()<y:EntIndex() end)
        for _,p in ipairs(victims) do self:CrossfireDamage(e,a,p) end
    end
    if IsValid(e) and e.LODRosterAttack==a then
        if self:ValidSourceLife(a.life) then self:Finish(e,now) else self:Cancel(e) end
    end
end
