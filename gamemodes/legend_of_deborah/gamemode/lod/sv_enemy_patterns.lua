-- B5 is trajectory policy for the existing roster service, never another scheduler.
local E=LOD.EnemyRoster
local radius=Vector(2,2,2)
local function trace(e,from,to,geometry)
    return util.TraceHull({start=from,endpos=to,mins=-radius,maxs=radius,mask=MASK_SOLID,
        filter=function(v) return v~=e and not v.LODHostile and (not geometry or not v:IsPlayer()) end})
end
local function copy(v) return Vector(v.x,v.y,v.z) end
function E:PlanPattern(e,a,kind)
    local origin,dir=a.origin,a.direction
    if dir:LengthSqr()==0 then return false end
    local paths={};local speed=kind=="bank" and 620 or (kind=="return" and 480 or 600)
    if kind=="split" then
        local side=Vector(-dir.y,dir.x,0):GetNormalized()*64
        if side:LengthSqr()==0 then return false end
        for _,sign in ipairs({-1,1}) do
            local start=origin+side*sign
            local tr=trace(e,origin,start,true)
            if tr.Hit or tr.StartSolid then return false end
            local goal=start+dir*640
            local lane=trace(e,start,goal,true)
            if lane.StartSolid then return false end
            if lane.Hit then goal=lane.HitPos-dir*4 end
            if start:Distance(goal)<96 then return false end
            paths[#paths+1]={start=start,goal=goal}
        end
    else
        local length=kind=="bank" and 900 or math.min(640,origin:Distance(a.aim)+96)
        local tr=trace(e,origin,origin+dir*length,true)
        if tr.StartSolid then return false end
        local goal=tr.Hit and tr.HitPos-dir*4 or origin+dir*length
        if origin:Distance(goal)<96 then return false end
        local path={start=origin,goal=goal}
        if kind=="bank" and tr.Hit and tr.HitNormal and math.abs(tr.HitNormal.z)<=.25 then
            local first=origin:Distance(tr.HitPos)
            local reflected=dir-tr.HitNormal*(2*dir:Dot(tr.HitNormal))
            local from=tr.HitPos+tr.HitNormal*4
            local second=trace(e,from,from+reflected*(1100-first),true)
            local finish=second.Hit and second.HitPos-reflected*4 or from+reflected*(1100-first)
            if not second.StartSolid and from:Distance(finish)>=96 then
                path.goal=tr.HitPos;path.bank={pos=copy(tr.HitPos),normal=copy(tr.HitNormal),entity=tr.Entity}
                path.nextStart=from;path.nextGoal=finish
            end
        elseif kind=="return" then
            path.nextStart=goal;path.nextGoal=origin;path.pause=.75
        end
        paths[1]=path
    end
    a.pattern=kind;a.paths=paths;a.speed=speed;a.event.patternHits=setmetatable({}, {__mode="k"})
    -- Fixed vectors are the tell and the actual trajectory. No live target reads after this point.
    e:SetNW2Int("LOD_PatternMode",kind=="bank" and 1 or (kind=="return" and 2 or 3))
    e:SetNW2Vector("LOD_PatternStart",paths[1].start);e:SetNW2Vector("LOD_PatternEnd",paths[1].goal)
    e:SetNW2Vector("LOD_PatternSecondStart",paths[2] and paths[2].start or paths[1].nextStart or paths[1].goal)
    e:SetNW2Vector("LOD_PatternSecondEnd",paths[2] and paths[2].goal or paths[1].nextGoal or paths[1].goal)
    e:SetNW2Float("LOD_PatternUntil",a.ready+.2)
    return true
end
function E:ReleasePattern(e,a,now)
    -- Atomic capacity and offset recheck: no half-volley or launch through new cover.
    if #self.Projectiles+#a.paths>64 then return false end
    for _,path in ipairs(a.paths) do
        local tr=trace(e,a.origin,path.start,true)
        if tr.Hit or tr.StartSolid then return false end
    end
    for _,path in ipairs(a.paths) do
        local length=path.start:Distance(path.goal)+(path.nextGoal and path.nextStart:Distance(path.nextGoal) or 0)
        local q={owner=e,pos=copy(path.start),goal=copy(path.goal),velocity=(path.goal-path.start):GetNormalized()*a.speed,
            speed=a.speed,expires=now+length/a.speed+(path.pause or 0)+.2,kind="bullet",event=a.event,
            pattern=a.pattern,patternLife=a.patternLife,bank=path.bank,nextStart=path.nextStart,
            nextGoal=path.nextGoal,pause=path.pause}
        for _,k in ipairs({"seed","run","graph","progression","epoch","campaignSeed","runId"}) do q[k]=a[k] end
        self.Projectiles[#self.Projectiles+1]=q
    end
    a.shotEmitted=true;return true
end
function E:StepPattern(q,now,dt)
    if q.resume then
        if now<q.resume then return true end
        q.resume=nil;q.goal=q.nextGoal;q.nextGoal=nil;q.velocity=(q.goal-q.pos):GetNormalized()*q.speed
    end
    local from=q.pos;local delta=q.goal-from;local distance=delta:Length()
    local reached=distance<=q.speed*dt
    local finish=reached and q.goal or from+delta:GetNormalized()*q.speed*dt
    -- Probe two units into the expected bank, once, using this tick's single sweep.
    if reached and q.bank then finish=finish+delta:GetNormalized()*2 end
    local tr=trace(q.owner,from,finish,false)
    if tr.StartSolid then return false end
    if tr.Hit then
        if self:Target(tr.Entity) then
            if not q.event.patternHits[tr.Entity] then
                q.event.patternHits[tr.Entity]=true;q.event.impactOrigin=copy(from)
                self:Damage(q.owner,tr.Entity,q.event,"bullet")
            end
            return false
        end
        local bank=q.bank
        if bank and tr.HitNormal and tr.HitPos:DistToSqr(bank.pos)<=8^2
            and tr.Entity==bank.entity and tr.HitNormal:Dot(bank.normal)>.99 then
            q.pos=q.nextStart;q.goal=q.nextGoal;q.bank=nil;q.nextGoal=nil
            q.velocity=(q.goal-q.pos):GetNormalized()*q.speed
            return true
        end
        return false -- unexpected/changed cover or second wall absorbs; never home or tunnel
    end
    q.pos=finish
    if not reached then return true end
    if q.bank then return false end -- the advertised wall disappeared
    if q.nextGoal then
        q.resume=now+(q.pause or 0);q.velocity=Vector(0,0,0);return true
    end
    return false
end
