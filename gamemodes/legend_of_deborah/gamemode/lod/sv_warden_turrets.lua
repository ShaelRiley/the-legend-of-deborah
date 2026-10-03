-- SPOT-08: encounter-owned Sentry admission/lifetime, not another combat system.
-- EnemyRoster owns warnings, projectiles, rolls, defenses and native packets.
LOD.WardenTurrets=LOD.WardenTurrets or {}
local T=LOD.WardenTurrets
local W,E,R,N=LOD.Warden,LOD.EnemyRoster,LOD.RunManager,LOD.MazeNavigator
local Status,Rules=LOD.RPGStatusElements,LOD.RPGAbilityRules
local function key(c) return c and LOD.MazeGenerator.CellKey(c.x,c.y,c.z) end
local function copy(v) return Vector(v.x,v.y,v.z) end
local function alive(e) return IsValid(e) and not e.LODDead and e:Health()>0 end
local function clear(tr) return tr and not tr.Hit and not tr.StartSolid and not tr.AllSolid end
local function log(event,data) if LOD.RPGTestLog then LOD.RPGTestLog:Write(event,data) end end
T.Config={warning=.75,arming=1.2,slotGap=.2,drift=4,serviceGap=.25,releaseGrace=.2,maxHeroes=32}
function T:Count(level)
    level=tonumber(level) or 1
    if level~=level then return 0 end
    return math.min(4,math.max(0,math.floor(level/5)))
end
function T:Reservation(s)
    local w=s and s.Warden
    if not s or (w and (w.dead or w.turrets)) then return 0 end
    return self:Count(s.Level)
end
function T:Plan(s,a)
    local all={{dx=-1,dy=-1},{dx=-1,dy=1},{dx=1,dy=-1},{dx=1,dy=1}}
    local rng=LOD.RNG.New(LOD.Seeds.Derive(s.LevelSeed or 1,"warden-turret-corners"))
    for i=4,2,-1 do local j=rng:Int(1,i);all[i],all[j]=all[j],all[i] end
    local out={}
    for i=1,self:Count(s.Level) do
        local o=all[i];local c=s.Graph.Cells[key({x=a.center.x+o.dx,y=a.center.y+o.dy,z=a.center.z})]
        out[i]={index=i,cell=c,dx=o.dx,dy=o.dy,yaw=o.dx<0 and 0 or 180}
        if c then
            local center=N:CellCenter(c)
            out[i].pos=LOD.HostileMotionV2:CellFloorPoint(c,center+Vector(o.dx,o.dy,0)*LOD.Config.Maze.CellSize)
        end
    end
    return out
end
-- Structural and actual native geometry both have to agree. The two west-corner
-- stair cells are not excluded wholesale: their centerline stays clear while a
-- supported side pocket may be occupied. No graph edge or stair is changed.
function T:Placement(s,a,slot,pos,actor)
    local g,c=s.Graph,slot.cell
    if not c or not pos or g.Cells[key(c)]~=c or not a.court[key(c)] or c.z~=a.center.z
        or math.abs(c.x-a.center.x)~=1 or math.abs(c.y-a.center.y)~=1
        or not LOD.EntrySafety or LOD.EntrySafety:ExactCell(g,pos)~=c then return false,"corner" end
    local safety=LOD.EntrySafety
    if safety and (not safety:SpawnCellAllowed(g,c) or not safety:SpawnPositionAllowed(pos)) then return false,"sanctuary" end
    -- The complete 3x3 lower cycle, both vertical links, and the upper ring are
    -- required. Loss of a route refuses placement, never opens a locked boundary.
    for k in pairs(a.court) do
        local cell=g.Cells[k];if not cell then return false,"court" end
        for _,delta in ipairs({{1,0},{0,1}}) do
            local nk=key({x=cell.x+delta[1],y=cell.y+delta[2],z=cell.z})
            if a.court[nk] and (not cell.neighbors[nk] or not g.Cells[nk].neighbors[k]
                or not N:CanTraverse(g,k,nk)) then return false,"route" end
        end
    end
    for _,dy in ipairs({-1,1}) do
        local lo=g.Cells[key({x=a.center.x-1,y=a.center.y+dy,z=a.center.z})]
        local hi=g.Cells[key({x=a.center.x-1,y=a.center.y+dy,z=a.center.z+1})]
        if not lo or not hi or not lo.neighbors[key(hi)] or not N:CanTraverse(g,key(lo),key(hi)) then return false,"stairs" end
        local route={};N:_AppendVerticalWaypoints(g,lo,hi,route)
        local previous
        for _,wp in ipairs(route) do
            local p=wp.pos or wp
            if previous then
                -- Expand the real travel segment by hostile half-hull + Hero
                -- half-hull + eight units. A corner never consumes that lane.
                local d=p-previous;local len=d:LengthSqr()
                local t=len>0 and math.Clamp((pos-previous):Dot(d)/len,0,1) or 0
                local nearest=previous+d*t
                if math.abs(pos.x-nearest.x)<40 and math.abs(pos.y-nearest.y)<40
                    and pos.z+72>nearest.z and pos.z<nearest.z+72 then return false,"stair_lane" end
            end
            previous=p
        end
    end
    local tr=util.TraceHull({start=pos,endpos=pos,mins=Vector(-16,-16,0),maxs=Vector(16,16,72),mask=MASK_NPCSOLID,filter=actor})
    if not clear(tr) then return false,"occupied" end
    if not self:Supported(pos,actor) then return false,"support" end
    return true
end
function T:Supported(pos,actor)
    -- Five native support samples prove the footprint, not merely its center.
    for _,offset in ipairs({{0,0},{-16,-16},{-16,16},{16,-16},{16,16}}) do
        local p=pos+Vector(offset[1],offset[2],0)
        local support=util.TraceLine({start=p+Vector(0,0,4),endpos=p-Vector(0,0,8),mask=MASK_NPCSOLID,filter=actor})
        if not support or not support.Hit or support.StartSolid or support.AllSolid or not support.HitNormal
            or support.HitNormal.z<.7 or not support.HitPos or math.abs(support.HitPos.z-(pos.z-2))>3
            or (IsValid(support.Entity) and (support.Entity.LODHostile or support.Entity:IsPlayer())) then return false end
    end
    return true
end
function T:Scope(group)
    local s=R.State;local w=s and s.Warden
    return group and not group.retired and s==group.run and w==group.warden and w.turrets==group
        and w.started and not w.dead and w.actor==group.root and alive(group.root)
        and group.root.LODActivated and group.root.LODArchetypeId=="warden" and group.root.LODWardenOwner==w and E:Live(group,s) and s.Level==group.level
        and group.rootState~=nil and group.rootLife~=nil and Rules:ProgressionState(group.root)==group.rootState and Status.ActorLives[group.root]==group.rootLife
end
function T:Body(e)
    local slot=IsValid(e) and e.LODWardenTurret
    if not slot or not slot.life or not slot.life.sourceState or not slot.life.sourceLife or slot.actor~=e or slot.retired or slot.dead or not self:Scope(slot.owner)
        or slot.owner.slots[slot.index]~=slot or e.LODArchetypeId~="sentry" or not alive(e)
        or Rules:ProgressionState(e)~=slot.life.sourceState or Status.ActorLives[e]~=slot.life.sourceLife then return end
    return slot
end
function T:Court(group,p)
    return self:Scope(group) and E:Target(p) and p:Health()>0
        and LOD.EntrySafety and group.arena.court[key(LOD.EntrySafety:ExactCell(group.graph,p:GetPos()))]==true and not W:Protected(p)
end
function T:Heroes(group)
    local out={}
    local players=player.GetAll()
    if #players>self.Config.maxHeroes then return out end -- fail closed, no unseen recipient
    for _,p in ipairs(players) do if self:Court(group,p) then out[#out+1]=p end end
    return out
end
function T:Ready(e)
    local slot=self:Body(e);local s=R.State
    return slot and s.BuildReady and not s.Failed and not s.LevelCleared and not s.SimulationFrozen
        and E:ValidSourceLife(slot.life) and #self:Heroes(slot.owner)>0 and slot or nil
end
function T:Sight(e,p,origin)
    local tr=util.TraceLine({start=origin or E:Origin(e),endpos=p:WorldSpaceCenter(),mask=MASK_SOLID,
        filter=function(v) return v~=e and not v.LODHostile end})
    return tr and not tr.StartSolid and not tr.AllSolid and (not tr.Hit or tr.Entity==p)
end
function T:Acquire(e,p)
    local slot=self:Ready(e)
    if not slot or not self:Court(slot.owner,p) or not E:AcquireTarget(p) then return false end
    local origin=E:Origin(e)
    return origin:DistToSqr(p:WorldSpaceCenter())<=e.LODConfig.fireRange^2
        and (p:GetPos()-e:GetPos()):GetNormalized():Dot(Angle(0,e.LODRosterYaw or slot.yaw,0):Forward())>=math.cos(math.rad(55))
        and self:Sight(e,p,origin)
end
function T:Select(e)
    local slot=self:Ready(e);local best,dist
    if slot then for _,p in ipairs(self:Heroes(slot.owner)) do
        local d=e:GetPos():DistToSqr(p:GetPos())
        if (not dist or d<dist) and self:Acquire(e,p) then best,dist=p,d end
    end end
    e.LODTarget=best
    return slot~=nil
end
function T:Admit(s,w,a)
    if w.turrets then return end
    local group=E:Bind({warden=w,root=w.actor,arena=a,level=s.Level,slots={},admitted=0,skipped=0},s)
    w.turrets=group;self.current=group
    Status:BindActorLife(w.actor)
    group.rootState=Rules:ProgressionState(w.actor);group.rootLife=Status.ActorLives[w.actor]
    group.slots=self:Plan(s,a);group.desired=#group.slots
    for _,slot in ipairs(group.slots) do
        slot.owner=group
        local ok,reason=self:Placement(s,a,slot,slot.pos)
        if not ok and s.Level==20 and LOD.BossRegistry and slot.cell then
            -- Four authored Sentries require four safe admissions. Search only
            -- bounded points in each designated corner; never invade a stair lane.
            local center=N:CellCenter(slot.cell)
            for _,offset in ipairs({{72,72},{48,72},{72,48},{96,72},{72,96},{48,48},{96,48},{48,96},{24,72},{72,24}}) do
                local candidate=LOD.HostileMotionV2:CellFloorPoint(slot.cell,center+Vector(slot.dx*offset[1],slot.dy*offset[2],0))
                local legal,why=self:Placement(s,a,slot,candidate)
                if legal then slot.pos=candidate;ok=true;reason=nil;break end
                reason=why
            end
        end
        local reserve=LOD.WanderingDirector:GetDeficitReservation(s.Graph)
        if not self:Scope(group) or s.Failed or s.LevelCleared or s.SimulationFrozen then ok,reason=false,"scope" end
        if LOD.EncounterDirector:GetActiveCount()+reserve+1>LOD.Config.Encounter.ActiveHostileCeiling then ok,reason=false,"capacity" end
        if ok then
            local e=ents.Create("lod_hostile")
            if IsValid(e) then
                slot.actor=e;e.LODWardenTurret=slot;e.LODArchetypeId="sentry";e.LODEncounterId="warden_turret"
                e.LODEncounterOrdinal=920000+slot.index;e.LODHomeCellKey=key(slot.cell);e.LODActivated=true
                e:SetPos(slot.pos);e:SetAngles(Angle(0,slot.yaw,0));e:Spawn()
                if IsValid(e) then
                    LOD.EnemyVariance:Apply(e);LOD.HostileMotionV2:SnapSpawn(e)
                    slot.life=E:CaptureLife(e,e)
                    local seated=e:GetPos():DistToSqr(slot.pos)<=1
                    ok,reason=self:Placement(s,a,slot,e:GetPos(),e)
                    ok=ok and seated and self:Body(e)~=nil
                    if ok then
                        E:Prepare(e);e.LODRosterYaw=slot.yaw;e:SetNW2Bool("LOD_WardenTurret",true)
                        e.LODNextAttack=CurTime()+self.Config.arming+slot.index*self.Config.slotGap
                        LOD.EncounterDirector.Entities[#LOD.EncounterDirector.Entities+1]=e
                        group.admitted=group.admitted+1;slot.admitted=true
                    else slot.retired=true;e:Remove();reason=reason or "settlement" end
                else ok,reason=false,"spawn" end
            else ok,reason=false,"create" end
        end
        if not ok then slot.skipped=reason or "refused";group.skipped=group.skipped+1 end
    end
    log("WARDEN_TURRETS_ADMITTED",{desired=group.desired,admitted=group.admitted,skipped=group.skipped,level=s.Level,seed=s.LevelSeed})
end
function T:ProjectileCount(w)
    local n=0
    for _,q in ipairs(E.Projectiles) do
        if q.turret and q.turret.group.warden==w and self:ProjectileLive(q,CurTime()) then n=n+1 end
    end
    return n
end
function T:Budget(group)
    return #E.Projectiles<64 and #W:AllHazards(group.warden)+self:ProjectileCount(group.warden)<W.Config.maxHazards
end
function T:Begin(e,p,a,now)
    local slot=self:Ready(e)
    if not slot or e.LODRosterAttack or now<(e.LODNextAttack or 0) or not self:Acquire(e,p)
        or now<(e.LODHitStunUntil or 0) or not E:CanCast(e) or Status:Has(e,"morale_flee")
        or not self:Budget(slot.owner) then return false end
    local cell=LOD.EntrySafety:ExactCell(slot.owner.graph,e:GetPos())
    if not cell or not slot.owner.arena.court[key(cell)] or not self:Supported(e:GetPos(),e) then return false end
    local r={slot=slot,group=slot.owner,life=E:CaptureLife(e,p),heroes={},ground=copy(e:GetPos()),last=now}
    for _,hero in ipairs(self:Heroes(slot.owner)) do r.heroes[hero]=E:CaptureLife(e,hero) end
    if not r.heroes[p] or not E:ValidLife(r.life) then return false end
    a.ready=now+math.max(self.Config.warning,a.ready-now);a.deadline=a.ready+self.Config.releaseGrace
    a.turret=r;a.event.turret=r
    return true
end
function T:Charge(e,a,now)
    local r=a.turret
    return r and not r.cancelled and e.LODRosterAttack==a and self:Ready(e)==r.slot
        and E:ValidLife(r.life) and self:Acquire(e,a.target) and self:Sight(e,a.target,a.origin)
        and e:GetPos():DistToSqr(r.ground)<=self.Config.drift^2
        and now-r.last<=self.Config.serviceGap and now<=a.deadline
        and now>=(e.LODHitStunUntil or 0) and E:CanCast(e) and not Status:Has(e,"morale_flee")
        and self:Supported(e:GetPos(),e)
end
function T:Release(e,a,now)
    return not a.released and self:Charge(e,a,now) and now>=a.ready and self:Budget(a.turret.group)
end
function T:Publish(e,a)
    return a.released and e.LODRosterAttack==a and not a.turret.cancelled
        and self:Ready(e)==a.turret.slot and self:Budget(a.turret.group)
end
function T:ProjectileLive(q,now)
    local r=q and q.turret
    return r and r.projectile==q and not r.cancelled and self:Ready(q.owner)==r.slot
        and now<q.expires and now-(q.lastService or now)<=self.Config.serviceGap
end
function T:Damage(e,p,event,kind)
    local r=event.turret;local q=r and r.projectile;local life=r and r.heroes[p]
    if kind~="bullet" or not q or q.owner~=e or r.claimed or not life
        or not self:ProjectileLive(q,CurTime()) or not E:ValidLife(life) or not self:Court(r.group,p) then return end
    -- One first-hit claim before any roll/resource/native callback. The guarded
    -- packet is bound to this recipient and incarnation, not a mutable event flag.
    r.claimed=true;local token={};r.settling=token
    local function gate()
        return r.settling==token and self:ProjectileLive(q,CurTime())
            and E:ValidLife(life) and self:Court(r.group,p)
    end
    local packet={commitmentGate=gate,impactOrigin=copy(q.pos)}
    local ok,result=pcall(E._DamagePacket,E,e,p,packet,kind)
    r.settling=nil
    if not ok then if ErrorNoHalt then ErrorNoHalt("[LOD SPOT08] turret packet retired: "..tostring(result).."\n") end;return end
    return result
end
function T:Quiesce(group)
    for _,slot in ipairs(group.slots) do
        local e=slot.actor
        if IsValid(e) and e.LODWardenTurret==slot then
            local a=e.LODRosterAttack
            if a and a.turret and a.turret.group==group then a.turret.cancelled=true;E:Cancel(e) end
        end
    end
    for _,q in ipairs(E.Projectiles) do if q.turret and q.turret.group==group then q.turret.cancelled=true end end
end
function T:Retire(group)
    if not group or group.retired then return end
    group.retired=true -- logical retirement first; no engine mutation in lethal stack
    for _,slot in ipairs(group.slots) do slot.retired=true end
    if #group.slots>0 then timer.Simple(0,function() T:Cleanup(group) end) end
end
-- Also called INSIDE Hector's existing deferred handoff, before Spawn. Simple
-- timer execution order is not a gameplay authority.
function T:Cleanup(group)
    if not group or not group.retired then return end
    for _,slot in ipairs(group.slots) do
        local e=slot.actor
        if IsValid(e) and e.LODWardenTurret==slot and slot.owner==group and slot.life
            and Rules:ProgressionState(e)==slot.life.sourceState and Status.ActorLives[e]==slot.life.sourceLife then
            E:Cancel(e)
            if alive(e) then e:Remove() end
        end
    end
end

function T:Service()
    local group=self.current;if not group then return end
    if not self:Scope(group) or R.State.Failed or R.State.LevelCleared or not R.State.BuildReady then
        self:Retire(group);if self.current==group then self.current=nil end;return
    end
    if R.State.SimulationFrozen or #self:Heroes(group)==0 then self:Quiesce(group) end
    for _,slot in ipairs(group.slots) do
        if slot.admitted and not slot.dead and not slot.retired and not self:Body(slot.actor) then
            slot.dead=true -- consumed, never re-admitted by phase, resurrection or reconnect
            local e=slot.actor;local a=IsValid(e) and e.LODRosterAttack
            if e and e.LODWardenTurret==slot and a and a.turret and a.turret.slot==slot then E:Cancel(e) end
        end
    end
end
function T:Status(w)
    local group=w and w.turrets;local count=0
    if group then for _,slot in ipairs(group.slots) do if self:Body(slot.actor) then count=count+1 end end end
    return " turrets="..count.."/"..tostring(group and group.desired or self:Count(R.State and R.State.Level))
        .." admitted="..tostring(group and group.admitted or 0).." skipped="..tostring(group and group.skipped or 0)
end
