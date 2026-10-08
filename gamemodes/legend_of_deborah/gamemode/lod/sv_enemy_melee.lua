-- B7 commitment geometry. Scheduling/damage and locomotion retain their owners.
local E,N=LOD.EnemyRoster,LOD.MazeNavigator
local function copy(v) return Vector(v.x,v.y,v.z) end
local function flat(v) return Vector(v.x,v.y,0) end

-- Universal last-ditch strike, serviced by EnemyRoster's existing bounded
-- commitment loop. It deliberately has no magic/content or target-cell rule:
-- a creature at an open cell seam must still be able to defend its own body.
E.CloseDefense={range=96,warning=.4,grace=.2,recovery=1.2,
    profile={label="CLOSE DEFENSE",source="melee",count=1,sides=4,bonus=1,reference=3.5}}
function E:CanCloseDefend(e)
    local s=LOD.RunManager and LOD.RunManager.State
    local status=LOD.RPGStatusElements
    if e.LODBossEncounter then return false end
    if not IsValid(e) or not e.LODHostile or e.LODDead or e:Health()<=0 or not e.LODActivated
        or not s or not s.Graph or not s.BuildReady or s.Failed or s.LevelCleared or s.SimulationFrozen
        or not status:CanInitiateAttack(e) or status:Has(e,"morale_flee") then return false end
    local context=e.LODRosterContext
    if context and not self:Live(context,s) then return false end
    if e.LODSkeletonHero and (not LOD.SkeletonHero or not LOD.SkeletonHero:Live(e)) then return false end
    if e.LODWardenTurret and (not LOD.WardenTurrets or not LOD.WardenTurrets:Ready(e)) then return false end
    local archetype=e.LODArchetypeId
    if archetype=="warden" then
        local root=e.LODWardenOwner
        local w=root and (root.cloneStates and root.cloneStates[e] or root)
        if not w or not LOD.Warden or not LOD.Warden:ActorOwner(w,e) or w.phase==1 and
            (not w.phaseOne or w.phaseOne.stage~="attack") then return false end
    elseif archetype=="hector" then
        if not LOD.Hector or not LOD.Hector:Live(e) then return false end
    elseif archetype=="neil" or archetype=="brute" then
        local h=s.NeilHunt
        if not h or h.seed~=s.LevelSeed or e~=h.neil and e~=h.brute then return false end
    end
    return true
end
function E:CloseTarget(e,p,origin)
    if not self:AcquireTarget(p) or LOD.FactionManager.CanDamage and not LOD.FactionManager:CanDamage(e,p)
        or origin:DistToSqr(p:WorldSpaceCenter())>self.CloseDefense.range^2 then return false end
    if e.LODWardenTurret and not LOD.WardenTurrets:Court(e.LODWardenTurret.owner,p) then return false end
    if e.LODArchetypeId=="hector" and not LOD.Hector:Hero(p,e.LODHectorEncounter) then return false end
    if e.LODArchetypeId=="warden" and LOD.Warden:Protected(p) then return false end
    local tr=util.TraceLine({start=origin,endpos=p:WorldSpaceCenter(),mask=MASK_SOLID,
        filter=function(v) return v~=e and not v.LODHostile end})
    return tr and not tr.StartSolid and not tr.AllSolid and (not tr.Hit or tr.Entity==p)
end
function E:BeginCloseDefense(e,p,now)
    if e.LODRosterAttack or now<(e.LODNextCloseDefense or 0) or now<(e.LODHitStunUntil or 0)
        or not self:CanCloseDefend(e) then return false end
    local origin=copy(e:WorldSpaceCenter())
    if not self:CloseTarget(e,p,origin) then return false end
    local cfg=self.CloseDefense
    local dir=flat(p:WorldSpaceCenter()-origin):GetNormalized()
    if dir:LengthSqr()==0 then dir=Angle(0,e:GetAngles().y,0):Forward() end
    local a=self:Bind({closeDefense=true,kind="close_defense",target=p,origin=origin,
        start=copy(e:GetPos()),direction=dir,ready=now+cfg.warning,
        expires=now+cfg.warning+cfg.grace,recoveryUntil=now+cfg.warning+cfg.recovery,
        life=self:CaptureLife(e,p)},LOD.RunManager.State)
    local profile=LOD.CombatRolls.HostileDamageProfiles[e.LODArchetypeId]
    local ordinary=profile and profile.source=="melee" and (e.LODConfig.meleeDamage or 0)>0
    a.event={impactOrigin=origin,closeProfile=ordinary and profile or cfg.profile,
        closeDamage=ordinary and e.LODConfig.meleeDamage or cfg.profile.reference*e:GetNW2Float("LOD_SizeScale",1)}
    -- Claim the one attack and its fixed cooldown before presentation callbacks.
    e.LODRosterAttack=a;self.Active[e]=true;e.LODNextCloseDefense=a.recoveryUntil
    e.LODNextAttack=math.max(e.LODNextAttack or 0,a.recoveryUntil)
    if LOD.EnemySupport then LOD.EnemySupport:Cancel(e) end
    if LOD.EnemyReactions then LOD.EnemyReactions:Cancel(e,true) end
    if LOD.EnemyRemains then LOD.EnemyRemains:Interrupt(e) end
    if LOD.EnemyPursuit then LOD.EnemyPursuit:Cancel(e) end
    if e.LODRosterAttack~=a or not self:ValidLife(a.life) then return false end
    local motion=LOD.HostileMotionV2
    motion:Stop(e);motion:FaceToward(e,e:GetPos()+dir*32)
    e:SetNW2Bool("LOD_RosterAlive",true);e:SetNW2Int("LOD_RosterAttack",1)
    e:SetNW2Int("LOD_MeleeMode",5);e:SetNW2Vector("LOD_MeleeOrigin",origin)
    e:SetNW2Vector("LOD_MeleeDirection",dir);e:SetNW2Float("LOD_MeleeReady",a.ready)
    e:SetNW2Float("LOD_MeleeUntil",a.expires)
    e:SetNW2Float("LOD_CloseDefenseAt",a.ready)
    e:_SetActivity(ACT_MELEE_ATTACK1,true)
    e:EmitSound("npc/zombie/claw_miss1.wav",65,110,.5)
    return e.LODRosterAttack==a
end
function E:StepCloseDefense(e,a,now)
    if e.LODRosterAttack~=a then return end
    if a.settled and now<=a.expires then return end
    local function valid()
        return e.LODRosterAttack==a and not a.settled and self:ValidLife(a.life)
            and self:CanCloseDefend(e) and CurTime()>=(e.LODHitStunUntil or 0)
            and CurTime()<=a.expires and e:GetPos():DistToSqr(a.start)<=4^2
            and self:CloseTarget(e,a.target,a.origin)
    end
    if not valid() then self:Finish(e,now);return end
    LOD.HostileMotionV2:Stop(e)
    if now<a.ready then return end
    a.released=true
    local delta=flat(a.target:WorldSpaceCenter()-a.origin)
    -- Advertised sector is frozen; circling behind/sideways genuinely evades.
    if delta:Dot(a.direction)>=delta:Length()*.5 then
        -- Consume before callbacks; a reentrant service cannot repeat impact.
        a.settled=true
        a.event.commitmentGate=function()
            return e.LODRosterAttack==a and self:ValidLife(a.life) and self:CanCloseDefend(e)
                and CurTime()>=a.ready and CurTime()<=a.expires and CurTime()>=(e.LODHitStunUntil or 0)
                and e:GetPos():DistToSqr(a.start)<=4^2 and self:CloseTarget(e,a.target,a.origin)
                and flat(a.target:WorldSpaceCenter()-a.origin):Dot(a.direction)
                    >=flat(a.target:WorldSpaceCenter()-a.origin):Length()*.5
        end
        self:Damage(e,a.target,a.event,"close_defense")
    end
    if IsValid(e) and e.LODRosterAttack==a then self:Finish(e,now) end
end
function E:TickCloseDefense(e)
    local a=e.LODRosterAttack
    if a and a.closeDefense then
        -- Service owns impact; native controllers cannot replace its animation
        -- or move the body during the warned strike.
        if not self:CanCloseDefend(e) then self:Cancel(e) end
        LOD.HostileMotionV2:Stop(e);return true
    end
    local now=CurTime()
    if now<(e.LODNextCloseDefense or 0) or now<(e.LODHitStunUntil or 0) or not self:CanCloseDefend(e) then return false end
    -- Never preempt an advertised primary attack, attached bite or leap.
    if a or e.LODSoldierBurst or e.LODSniperShot or e.LODBioBlast or e.LODBruteCharge or e.LODBruteAttack
        or e.LODWatcherScan or e.LODSeekerState or e.LODClimberVictim then return false end
    -- Borrow plain Lua fields only across adjacent, callback-free comparisons.
    -- Status, ownership and preparation callbacks still precede fresh reads.
    local deadcrabState=e.LODDeadcrabState
    if deadcrabState=="latched" or deadcrabState=="leaping" then return false end
    local fallen=e.LODFallenHero
    if fallen and (fallen.attack or fallen.burst) then return false end
    local root=e.LODWardenOwner
    if root then
        local w=root.cloneStates and root.cloneStates[e] or root
        if w.swing or w.volley or w.phaseOne and w.phaseOne.stage=="taunt" then return false end
    end
    local h=e.LODHectorEncounter
    if h and (h.pending or h.volley) then return false end
    if self.Definitions[e.LODArchetypeId] then self:Prepare(e) end
    -- These two already possess a reliable close attack. The shared flinch
    -- recovery and native animation repair restore their opportunity to use it.
    local archetype=e.LODArchetypeId
    if archetype=="shambler" or archetype=="runner" then return false end
    e:_RefreshTarget(LOD.RunManager.State.Graph)
    return self:BeginCloseDefense(e,e.LODTarget,now)
end

function E:MeleeCellLegal(g,c)
    return c and g.Cells[self.Key(c)]==c and not self:Safe(g,c)
        and not ((g.CellTags or {})[self.Key(c)] or {}).objective and not self:IsTransition(g,c)
end
function E:MeleeSupported(e,g,c,pos)
    if N:WorldToCell(g,pos)~=c or not self:MeleeCellLegal(g,c) then return false end
    local floor=N:CellCenter(c).z
    if math.abs(pos.z-(floor+2))>4 then return false end
    local tr=util.TraceLine({start=pos+Vector(0,0,16),endpos=pos-Vector(0,0,12),mask=MASK_SOLID,
        filter=function(v) return v~=e and not v.LODHostile and not v:IsPlayer() end})
    return tr.Hit and not tr.StartSolid and not tr.AllSolid and tr.HitNormal and tr.HitNormal.z>=.7
        and math.abs(tr.HitPos.z-floor)<=4
end
function E:MeleeRouteClear(e,from,to)
    local size=math.Clamp(e:GetNW2Float("LOD_SizeScale",1),.33,1.33)
    local tr=util.TraceHull({start=from,endpos=to,mins=Vector(-16*size,-16*size,0),
        maxs=Vector(16*size,16*size,72*size),mask=MASK_NPCSOLID,
        filter=function(v) return v~=e and not v.LODHostile and not v:IsPlayer() end})
    return not tr.Hit and not tr.StartSolid and not tr.AllSolid
end
function E:BeginMelee(e,p,now,spacing)
    if e.LODRosterAttack or not self:AcquireTarget(p) or not self:CanCast(e)
        or now<(e.LODHitStunUntil or 0) or now<(e.LODNextAttack or 0) then return false end
    local d=self.Definitions[e.LODArchetypeId];local s=LOD.RunManager.State;local g=s and s.Graph
    if not g or not s.BuildReady or s.Failed or s.LevelCleared or s.SimulationFrozen then return false end
    local function fail() e.LODNextAttack=now+.5;e.LODMeleeAdvanceUntil=now+.5;return false end
    local start=copy(e:GetPos());local cell=N:WorldToCell(g,start)
    if not self:MeleeSupported(e,g,cell,start) or N:WorldToCell(g,p:GetPos())~=cell
        or flat(p:GetPos()-start):Length()>d.range or not self:Visible(e,p) then return fail() end
    local dir=flat(p:GetPos()-start):GetNormalized()
    if dir:LengthSqr()==0 then dir=Angle(0,e:GetAngles().y,0):Forward() end
    local a=self:Bind({melee=d.melee,kind="melee",target=p,start=start,origin=start,direction=dir,
        cell=cell,ready=now+d.warning,beat=1,participants={}},s)
    if d.melee=="feint" then
        if not LOD.RPGStatusElements:CanMoveVoluntarily(e) then return fail() end
        local goal=LOD.HostileMotionV2:CellFloorPoint(cell,start-dir*80)
        local delta=flat(start-goal);local side=Vector(-dir.y,dir.x,0)
        if delta:Dot(dir)<64 or math.abs(delta:Dot(side))>4
            or not self:MeleeSupported(e,g,cell,goal) or not self:MeleeRouteClear(e,start,goal) then return fail() end
        a.origin=goal;a.retreatEnd=now+.6;a.ready=a.retreatEnd+d.warning
        e.LODMotionLastUpdate=now
    end
    a.second=d.melee=="double" and a.ready+.85 or nil
    a.expires=(a.second or a.ready)+.2;a.life=self:CaptureLife(e,p)
    if spacing then
        a.spacing=spacing.spacing;a.aim=spacing.aim;a.last=now;a.deadline=a.expires
    end
    local heroes=spacing and {p} or player.GetAll()
    for i=1,math.min(32,#heroes) do
        if self:Target(heroes[i]) then a.participants[#a.participants+1]=self:CaptureLife(e,heroes[i]) end
    end
    e.LODRosterAttack=a;e.LODMeleeAdvanceUntil=nil
    if d.perception then e:SetNW2Int("LOD_PerceptionMode",0) end
    e:SetNW2Int("LOD_RosterAttack",1);e:SetNW2Int("LOD_MeleeMode",d.melee=="sweep" and 1 or (d.melee=="double" and 2 or (d.melee=="single" and 4 or 3)))
    e:SetNW2Vector("LOD_MeleeOrigin",a.origin);e:SetNW2Vector("LOD_MeleeStart",a.start)
    e:SetNW2Vector("LOD_MeleeDirection",dir);e:SetNW2Float("LOD_MeleeReady",a.ready)
    e:SetNW2Float("LOD_MeleeSecond",a.second or 0);e:SetNW2Float("LOD_MeleeUntil",a.expires)
    if spacing then self:PublishSpacing(e,a) end
    if spacing and (e.LODRosterAttack~=a or not self:ValidLife(a.life)) then return false end
    e:EmitSound(d.melee=="feint" and "npc/metropolice/gear1.wav" or "npc/zombie/zo_attack1.wav",72,100,.75)
    if not spacing or (e.LODRosterAttack==a and self:ValidLife(a.life)) then e:_SetActivity(ACT_MELEE_ATTACK1 or ACT_IDLE,true) end
    return e.LODRosterAttack==a
end
function E:MeleeContains(a,p,beat)
    local pos=p:GetPos();local delta=flat(pos-a.origin);local height=pos.z-(a.origin.z-2)
    if height< -4 or height>72 or N:WorldToCell(a.graph,pos)~=a.cell then return false end
    local forward=delta:Dot(a.direction)
    if a.melee=="feint" then
        return forward>=0 and forward<=240 and math.abs(delta:Dot(Vector(-a.direction.y,a.direction.x,0)))<=24
    end
    local radius=a.melee=="sweep" and 144 or (beat==1 and 112 or 184)
    local cosine=a.melee=="sweep" and 0 or math.cos(math.rad(30))
    return delta:LengthSqr()<=radius*radius and forward>=delta:Length()*cosine
end
function E:StepMelee(e,a,now)
    if e.LODRosterAttack~=a then return end
    local motion=LOD.HostileMotionV2
    if not self:ValidLife(a.life) or not self:CanCast(e) or now<(e.LODHitStunUntil or 0)
        or now>a.expires or not self:MeleeSupported(e,a.graph,a.cell,e:GetPos()) then self:Finish(e,now);return end
    if a.retreatEnd then
        if not LOD.RPGStatusElements:CanMoveVoluntarily(e)
            or not self:MeleeSupported(e,a.graph,a.cell,a.origin)
            or not self:MeleeRouteClear(e,e:GetPos(),a.origin) then self:Finish(e,now);return end
        -- External displacement cannot be converted into a fresh retreat route.
        local moved=flat(e:GetPos()-a.start);local along=-moved:Dot(a.direction)
        if along< -4 or along>84 or math.abs(moved:Dot(Vector(-a.direction.y,a.direction.x,0)))>4 then self:Finish(e,now);return end
        if now<a.retreatEnd then
            motion:MoveToward(e,{pos=a.origin});motion:FaceToward(e,e:GetPos()+a.direction*32);return
        end
        if e:GetPos():DistToSqr(a.origin)>4^2 then self:Finish(e,now);return end
        a.retreatEnd=nil;motion:Stop(e);e:_SetActivity(ACT_MELEE_ATTACK1 or ACT_IDLE,true)
    end
    if e:GetPos():DistToSqr(a.origin)>4^2 then self:Finish(e,now);return end
    -- Disappearance/cover can abort a charge, never update its frozen geometry.
    if not self:AcquireTarget(a.target) or not self:Visible(e,a.target,a.origin+Vector(0,0,48)) then self:Finish(e,now);return end
    local due=a.beat==1 and a.ready or a.second
    if not due or now>due+.2 then self:Finish(e,now);return end
    if now<due then return end
    local event={impactOrigin=a.origin+Vector(0,0,48)};local beat=a.beat
    -- Advance BEFORE native callbacks; a reentrant service cannot repeat a beat.
    a.beat=a.beat+1
    for _,life in ipairs(a.participants) do
        local p=life.hero
        if self:ValidLife(life) and self:MeleeContains(a,p,beat) and self:Visible(e,p,event.impactOrigin) then
            self:Damage(e,p,event,"melee")
            if e.LODRosterAttack~=a or not self:ValidSourceLife(a.life) then return end
        end
    end
    e:EmitSound("npc/zombie/claw_miss1.wav",72,100,.75)
    if (not a.second or beat==2) and IsValid(e) and e.LODRosterAttack==a and self:ValidSourceLife(a.life) then self:Finish(e,now) end
end
