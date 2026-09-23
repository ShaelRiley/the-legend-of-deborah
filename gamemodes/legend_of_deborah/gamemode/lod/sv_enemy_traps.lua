-- B6 geometry/commitment policy. EnemyRoster owns scheduling and combat;
-- the hostile itself owns the trap, so killing it uses ordinary XP/loot once.
local E,N=LOD.EnemyRoster,LOD.MazeNavigator
local function copy(v) return Vector(v.x,v.y,v.z) end
local function flat(v) return Vector(v.x,v.y,0) end
local function clear(e,from,to,lo,hi)
    local tr=util.TraceHull({start=from,endpos=to,mins=lo or Vector(-2,-2,-2),maxs=hi or Vector(2,2,2),mask=MASK_SOLID,
        filter=function(v) return v~=e and not v.LODHostile and not v:IsPlayer() end})
    return not tr.Hit and not tr.StartSolid
end
function E:TrapCellLegal(g,c)
    if self:Safe(g,c) or (g.CellTags or {})[self.Key(c)] and g.CellTags[self.Key(c)].objective then return false end
    return not self:IsTransition(g,c)
end
function E:TrapRouteLegal(a)
    local g=a.graph;local c,source=a.cell,a.sourceCell
    if g.Cells[self.Key(c)]~=c or g.Cells[self.Key(source)]~=source
        or not self:TrapCellLegal(g,c) or not self:TrapCellLegal(g,source) or c.z~=source.z then return false end
    return c==source or source.neighbors[self.Key(c)] and N:CanTraverse(g,self.Key(source),self.Key(c))
end
function E:TrapSupported(e,a)
    -- False-floor events can remove native support without changing the graph.
    -- Three fixed probes for a wire, one for circles; no spatial discovery.
    local points=a.trap=="wire" and {a.origin,a.from,a.to} or {a.origin}
    for _,pos in ipairs(points) do
        local tr=util.TraceLine({start=pos+Vector(0,0,16),endpos=pos-Vector(0,0,12),mask=MASK_SOLID,
            filter=function(v) return v~=e and not v.LODHostile and not v:IsPlayer() end})
        if not tr.Hit or tr.StartSolid or tr.AllSolid or not tr.HitNormal or tr.HitNormal.z<.7
            or math.abs(tr.HitPos.z-(a.origin.z-3))>4 then return false end
    end
    return true
end
function E:BeginTrap(e,p,now)
    if e.LODRosterAttack or not self:AcquireTarget(p) or not self:CanCast(e)
        or now<(e.LODHitStunUntil or 0) then return false end
    local count=0
    for actor in pairs(self.Active) do
        if IsValid(actor) and actor.LODRosterAttack and actor.LODRosterAttack.trap then
            count=count+1;if count>=16 then e.LODNextAttack=now+.5;return false end
        end
    end
    local s=LOD.RunManager.State;local g=s and s.Graph
    if not g or not s.BuildReady or s.Failed or s.LevelCleared or s.SimulationFrozen then return false end
    local d=self.Definitions[e.LODArchetypeId];local kind=d.trap
    local source=N:WorldToCell(g,e:GetPos());local c=kind=="ring" and source or N:WorldToCell(g,p:GetPos())
    local a=self:Bind({trap=kind,kind=d.kind,sourceCell=source,cell=c,target=p,
        sourcePos=copy(e:GetPos()),ready=now+e.LODConfig.burstTelegraph,event={},hit={},participants={}},s)
    local function fail() e.LODNextAttack=now+.5;e.LODTrapAdvanceUntil=now+.5;return false end
    if not c or not source or not self:TrapRouteLegal(a) then return fail() end
    local floor=N:CellCenter(c);local sourceFloor=N:CellCenter(source)
    if math.abs(e:GetPos().z-sourceFloor.z)>24 or math.abs(p:GetPos().z-N:CellCenter(N:WorldToCell(g,p:GetPos())).z)>72 then return fail() end
    local center=copy(floor);center.z=center.z+3
    if kind=="snare" then
        center.x=math.Clamp(p:GetPos().x,floor.x-64,floor.x+64)
        center.y=math.Clamp(p:GetPos().y,floor.y-64,floor.y+64)
    elseif kind=="ring" then center=Vector(e:GetPos().x,e:GetPos().y,floor.z+3) end
    local direction=flat(p:GetPos()-e:GetPos()):GetNormalized()
    if direction:LengthSqr()==0 then direction=Vector(1,0,0) end
    local side=Vector(-direction.y,direction.x,0)
    a.origin=center;a.aim=center;a.from=center;a.to=center
    if kind=="wire" then a.from=center-side*112;a.to=center+side*112 end
    -- A visible, supported same-floor cell and open escape pockets are admission
    -- conditions. No remote placement through containers, gates or stair cells.
    if not self:Visible(e,p) or not self:TrapSupported(e,a)
        or not clear(e,self:Origin(e),center+Vector(0,0,24)) then return fail() end
    if kind=="wire" then
        if not clear(e,a.from+Vector(0,0,24),a.to+Vector(0,0,24),Vector(-14,-14,-24),Vector(14,14,24))
            or not clear(e,center,center+direction*64,Vector(-16,-16,2),Vector(16,16,72))
            or not clear(e,center,center-direction*64,Vector(-16,-16,2),Vector(16,16,72)) then return fail() end
    else
        for _,sign in ipairs({-1,1}) do
            if not clear(e,center,center+side*sign*(kind=="snare" and 104 or 100),Vector(-16,-16,2),Vector(16,16,72)) then return fail() end
        end
    end
    a.trapLife=self:CaptureLife(e,p);a.armDeadline=a.ready+.2
    a.expires=a.ready+(kind=="wire" and 5 or (kind=="snare" and 6 or .2))
    -- Freeze eligible incarnations once. A late join/revival cannot inherit an
    -- unseen warning, and service never scans the world for new victims.
    local heroes=player.GetAll()
    for i=1,math.min(#heroes,32) do
        local hero=heroes[i]
        if self:Target(hero) then
            a.participants[#a.participants+1]={life=self:CaptureLife(e,hero),previous=copy(hero:GetPos())}
        end
    end
    e.LODRosterAttack=a;e.LODTrapAdvanceUntil=nil
    e:SetNW2Int("LOD_RosterAttack",1);e:SetNW2Int("LOD_TrapMode",kind=="wire" and 1 or (kind=="snare" and 2 or 3))
    e:SetNW2Vector("LOD_TrapA",a.from);e:SetNW2Vector("LOD_TrapB",a.to)
    e:SetNW2Float("LOD_TrapReady",a.ready);e:SetNW2Float("LOD_TrapUntil",a.expires);e:SetNW2Float("LOD_TrapSnap",0)
    e:EmitSound(kind=="snare" and "npc/vort/attack_charge.wav" or "npc/turret_floor/active.wav",72,100,.75)
    e:_SetActivity(ACT_RANGE_ATTACK1 or ACT_IDLE,true)
    return true
end
-- Closest planar point on a finite segment, including swept crossings between
-- service samples. The fraction also interpolates jump height at the crossing.
local function projection(p,a,b)
    local delta=b-a;local f=math.Clamp((p-a):Dot(delta)/math.max(.001,delta:LengthSqr()),0,1)
    return a+delta*f,f
end
local function cross(a,b) return a.x*b.y-a.y*b.x end
function E:WireContact(a,previous,current)
    local p,q,u,v=flat(previous),flat(current),flat(a.from),flat(a.to)
    local move,wire=q-p,v-u;local den=cross(move,wire)
    local fraction,nearest,distance=1,projection(q,u,v),math.huge
    if math.abs(den)>.001 then
        local f,t=cross(u-p,wire)/den,cross(u-p,move)/den
        if f>=0 and f<=1 and t>=0 and t<=1 then fraction=f;nearest=u+wire*t;distance=0 end
    end
    for _,f in ipairs({0,1}) do
        local point=p+move*f;local near=projection(point,u,v);local dist=point:DistToSqr(near)
        if dist<distance then distance=dist;fraction=f;nearest=near end
    end
    for _,point in ipairs({u,v}) do
        local near,f=projection(point,p,q);local dist=point:DistToSqr(near)
        if dist<distance then distance=dist;fraction=f;nearest=point end
    end
    local height=previous.z+(current.z-previous.z)*fraction-(a.origin.z-3)
    return distance<=14^2 and height>=-4 and height<=48,Vector(nearest.x,nearest.y,a.origin.z+24)
end
function E:StepTrap(e,a,now)
    if e.LODRosterAttack~=a then return end
    if not self:ValidLife(a.trapLife) or now>=a.expires or not self:TrapRouteLegal(a)
        or e:GetPos():DistToSqr(a.sourcePos)>32^2 or not self:CanCast(e) or now<(e.LODHitStunUntil or 0)
        or not self:TrapSupported(e,a) then self:Finish(e,now);return end
    if not a.released then
        if now>a.armDeadline or not self:AcquireTarget(a.target) or not self:Visible(e,a.target) then self:Finish(e,now);return end
        if now<a.ready then
            for _,entry in ipairs(a.participants) do
                if self:ValidLife(entry.life) then entry.previous=copy(entry.life.hero:GetPos()) end
            end
            return
        end
        a.released=true;e:SetNW2Int("LOD_RosterAttack",2)
        -- Do not retroactively damage a crossing made during the warning.
        for _,entry in ipairs(a.participants) do
            if self:ValidLife(entry.life) then entry.previous=copy(entry.life.hero:GetPos()) end
        end
    end
    if a.snap and now>a.snap+.2 then self:Finish(e,now);return end
    local resolve=a.trap=="ring" or a.snap and now>=a.snap
    for _,entry in ipairs(a.participants) do
        local p=entry.life.hero
        if self:ValidLife(entry.life) then
            local pos=p:GetPos();local previous=entry.previous;entry.previous=copy(pos)
            if pos:DistToSqr(previous)>256^2 then previous=pos end
            local inside,origin=false,a.origin+Vector(0,0,24)
            if a.trap=="wire" then inside,origin=self:WireContact(a,previous,pos)
            else
                local distance=flat(pos-a.origin):Length();local height=pos.z-(a.origin.z-3)
                inside=height>=-4 and height<=72 and distance<=(a.trap=="ring" and 160 or 72)
                    and (a.trap~="ring" or distance>=80)
            end
            -- Recheck world cover and the exact physical cell; radius never leaks
            -- into a different floor or through newly closed geometry.
            if inside and N:WorldToCell(a.graph,pos)==a.cell and self:Visible(e,p,origin) then
                if a.trap=="snare" and not a.snap and now+1.25+.2<a.expires then
                    a.snap=now+1.25;e:SetNW2Float("LOD_TrapSnap",a.snap)
                    e:EmitSound("npc/turret_floor/ping.wav",72,110,.8)
                elseif (a.trap=="wire" or resolve) and not a.hit[p] then
                    a.hit[p]=true;a.event.impactOrigin=origin
                    self:Damage(e,p,a.event,a.kind)
                    -- A native damage callback may invalidate the source/context.
                    -- This pulse killing its initial target must not spare the
                    -- other already-admitted Heroes merely due to list order.
                    if e.LODRosterAttack~=a or not self:ValidSourceLife(a.trapLife) then return end
                end
            end
        end
    end
    if resolve then self:Finish(e,now) end
end
