-- Finite, server-authoritative encounter work. No uncontrolled VPhysics, private
-- status/damage pipeline, per-projectile Think hook or reward authority.
local B=LOD.BossEncounter
local R,N=LOD.RunManager,LOD.MazeNavigator
local copy,alive=B.Copy,B.Alive
local function clamp(v,a,b) return math.Clamp(tonumber(v) or a,a,b) end
local function length(v) return v and v:Length() or 0 end
local function velocity(v,max) if length(v)>max then return v:GetNormalized()*max end;return copy(v) end
function B:Callback(c,work,fn,...)
    if not c.cancelling and (work.committed or work.projectile or work.charge) and work.sourceBinding and not self:SourceLive(c,work.sourceBinding) then return end
    local bindings,source,committed=c.activeBindings,c.activeSourceBinding,c.activeCommitted
    c.activeBindings=work.bindings or bindings;c.activeSourceBinding=work.sourceBinding or source;c.activeCommitted=work.committed or work.projectile or work.charge or committed
    local ok,result=pcall(fn,...)
    c.activeBindings,c.activeSourceBinding,c.activeCommitted=bindings,source,committed
    if not ok then error(result) end
    return result
end
function B:Budget(c)
    local n=0;for _,o in ipairs(c.objects) do if not o.retired then n=n+1 end end
    for _,z in ipairs(c.hazards) do if not z.retired then n=n+1 end end
    return n<clamp(c.def.maxObjects or 32,4,64)
end
function B:ProjectileCount()
    local n=#(LOD.EnemyRoster.Projectiles or {});local c=R.State.Boss
    if c then for _,o in ipairs(c.objects) do if not o.retired and o.projectile then n=n+1 end end end
    return n
end
function B:Warn(c,label,pos,seconds,radius,opts)
    if not self:Current(c) then return end
    c.warnings=c.warnings or {};if #c.warnings>=24 then table.remove(c.warnings,1) end
    local q={label=tostring(label):sub(1,80),pos=copy(pos),start=CurTime(),expires=CurTime()+clamp(seconds,.05,30),radius=clamp(radius or 64,4,1500)}
    for k,v in pairs(opts or {}) do q[k]=v end
    c.warnings[#c.warnings+1]=q;return q
end
function B:Damage(c,target,spec,source)
    source=source or c.actor;spec=spec or {}
    if c.cancelling or not self:Live(c) or not self:Hero(c,target) or not self:Owned(c,source) or not alive(source) then return 0 end
    if spec._sourceBinding and not self:SourceLive(c,spec._sourceBinding) then return 0 end
    if c.activeSourceBinding and not self:SourceLive(c,c.activeSourceBinding) then return 0 end
    local bindings=spec._bindings or c.activeBindings
    if bindings and not self:TargetLive(c,bindings[target]) then return 0 end
    if spec.gate and not spec.gate() then return 0 end
    if not spec._committed and not c.activeCommitted then
        local status=LOD.RPGStatusElements
        if not status:CanInitiateAttack(source) or CurTime()<(source.LODBossStaggerUntil or 0)
            or ((spec.content or spec.kind=='arc') and not status:CanInitiateMagic(source)) then return 0 end
    end
    local binding=self:BindTarget(c,target);local kind=spec.kind or 'melee'
    local dice=spec.dice or {2,4,3};local reference=spec.reference or (dice[1]*(dice[2]+1)/2+dice[3])
    local profile={label=spec.label or string.upper(c.id)..' '..string.upper(kind),source=kind,
        count=math.floor(clamp(dice[1],1,16)),sides=math.floor(clamp(dice[2],2,20)),bonus=clamp(dice[3] or 0,-100,100),reference=reference,
        magicDamage=kind=='arc' or spec.content~=nil}
    local gate=function() return B:Live(c) and B:Owned(c,source) and alive(source) and B:TargetLive(c,binding)
        and (not spec.gate or spec.gate()) end
    local event={roll=spec._event and spec._event.roll,riders=spec._event and spec._event.riders,nativeDamageType=kind=='blast' and DMG_BLAST or kind=='bullet' and DMG_BULLET or kind=='melee' and DMG_CLUB or nil,closeProfile=profile,closeDamage=clamp(spec.damage or reference,0,200),impactOrigin=spec.origin,
        skeletonContent=spec.content and LOD.RPG.MagicContents[spec.content],commitmentGate=gate}
    local actual=LOD.EnemyRoster:Damage(source,target,event,kind) or 0
    if spec._event then spec._event.roll=event.roll;spec._event.riders=event.riders end
    if spec.push and gate() then self:Push(c,target,spec.direction or (target:GetPos()-(spec.origin or source:GetPos())),spec.push,source) end
    return actual
end
function B:Push(c,p,dir,strength,source)
    source=source or c.actor
    if c.cancelling or not self:Live(c) or not self:Hero(c,p) or not self:Owned(c,source) or not alive(source) then return false end
    if c.activeBindings and not self:TargetLive(c,c.activeBindings[p]) then return false end
    if c.activeSourceBinding and not self:SourceLive(c,c.activeSourceBinding) then return false end
    return LOD.Pushback:Apply(p,{attacker=source,origin=source:GetPos(),direction=dir:GetNormalized(),distance=clamp(strength,0,384),source='boss '..c.id})
end
function B:Visible(c,pos,p,source)
    if math.abs(pos.z-p:GetPos().z)>180 then return false end
    local tr=util.TraceLine({start=pos+Vector(0,0,16),endpos=p:WorldSpaceCenter(),mask=MASK_SHOT,
        filter=function(e) return e~=source and not e.LODHostile and not (e.LODBossObject and not e.LODBossObject.spec.solid) end})
    return tr and not tr.StartSolid and (not tr.Hit or tr.Entity==p)
end
function B:Area(c,pos,radius,spec,source)
    local hit={};local shared={};if not self:Live(c) then return hit end
    for _,p in ipairs(self:Targets(c)) do
        if p:GetPos():DistToSqr(pos)<=radius*radius and self:Visible(c,pos,p,source) then
            local s=table.Copy(spec or {});s._bindings=spec and spec._bindings or c.activeBindings;s._sourceBinding=spec and spec._sourceBinding;s._event=shared;s.origin=copy(pos);self:Damage(c,p,s,source);hit[#hit+1]=p
        end
    end
    return hit
end
function B:Objects(c,kind)
    local out={};for _,o in ipairs(c.objects) do if not o.retired and IsValid(o.ent) and (not kind or o.spec.kind==kind) then out[#out+1]=o end end;return out
end
function B:Object(c,spec)
    if c.cancelling or not self:Current(c) or not self:Budget(c) then return end
    if c.activeSourceBinding and not self:SourceLive(c,c.activeSourceBinding) and not spec.cosmetic and spec.role~='key_button' and spec.role~='key_interaction' then return end
    if c.dead and not (spec.cosmetic or spec.role=='key_button' or spec.role=='key_interaction') then return end
    spec=table.Copy(spec)
    local offensive=spec.offensive==true or not spec.permanent and not spec.use and not spec.cosmetic and spec.role~='mandatory_item'
    if offensive and not self:CanInitiate(c,spec.source or c.actor,spec.damage or {}) then return end
    local pos=spec.pos or self:Center(c)
    if not self:Floor(c,pos) and not spec.cosmetic then return end
    if spec.solid and not self:ValidateRoutes(c,{pos},spec.radius or 24) then return end
    if spec.cosmetic then spec.damage=nil;spec.solid=false;spec.use=false;spec.hp=0;spec.fuse=nil;spec.proxRadius=nil;spec.explodeRadius=0 end
    c.objectOrdinal=(c.objectOrdinal or 0)+1
    local e=ents.Create('lod_boss_object');if not IsValid(e) then return end
    local o={id=c.objectOrdinal,committed=offensive,ent=e,pos=copy(pos),velocity=copy(spec.velocity or vector_origin),spec=spec,
        source=spec.source or c.actor,gravity=clamp(spec.gravity or 0,0,1200),created=CurTime(),expires=CurTime()+clamp(spec.life or (spec.permanent and 60 or 8),.1,60),
        health=math.max(0,spec.hp or 0),mass=clamp(spec.mass or 10,1,150),bounces=math.floor(clamp(spec.bounces or 0,0,4)),state=spec.state or 'stable',hits={},owner=c}
    o.bindings=c.activeBindings or self:BindTargets(c);o.sourceBinding=self:BindSource(c,o.source)
    e.LODBossObject=o;e.LODBossEncounter=c;c.objects[#c.objects+1]=o
    e:SetPos(pos);e:SetModel(spec.model or 'models/props_junk/wood_crate001a.mdl');e:Spawn()
    if not IsValid(e) then o.retired=true;return end
    e:SetHealth(o.health);e:SetMaxHealth(math.max(1,o.health));e:SetNW2String('LOD_BossObjectKind',spec.kind or '')
    e:SetNW2String('LOD_BossObjectLabel',spec.useLabel or spec.label or '');e:SetNW2String('LOD_BossObjectState',o.state)
    if spec.scale then e:SetModelScale(clamp(spec.scale,.05,8),0) end
    if spec.color then e:SetColor(spec.color) end
    local r=clamp(spec.radius or 16,4,180);e:SetCollisionBounds(Vector(-r,-r,-r),Vector(r,r,r))
    e:SetSolid((spec.solid or o.health>0) and SOLID_BBOX or SOLID_NONE);e:SetCollisionGroup(spec.solid and COLLISION_GROUP_NONE or COLLISION_GROUP_DEBRIS)
    return o
end
function B:Projectile(c,spec)
    if c.activeSourceBinding and not self:SourceLive(c,c.activeSourceBinding) then return end
    if not self:Live(c) or self:ProjectileCount()>=64 or not self:CanInitiate(c,spec.source or c.actor,spec.damage or {}) then return end
    local o=self:Object(c,spec);if not o then return end
    o.bindings=c.activeBindings or self:BindTargets(c);o.sourceBinding=self:BindSource(c,o.source)
    if o.spec.damage then o.spec.damage._committed=true;o.spec.damage._bindings=o.bindings;o.spec.damage._sourceBinding=o.sourceBinding end
    o.projectile=true;o.velocity=velocity(o.velocity,1400);o.gravity=clamp(spec.gravity or 0,0,1200)
    o.mass=clamp(spec.mass or 10,1,150);o.fuse=spec.fuse and CurTime()+clamp(spec.fuse,.15,15) or nil
    return o
end
function B:ObjectUse(c,o,p)
    if not self:Current(c) or o.retired or not IsValid(o.ent) or not self:Hero(c,p) or not o.spec.use
        or (c.dead and o.spec.role~='key_button' and o.spec.role~='key_interaction') or p:GetPos():DistToSqr(o.ent:GetPos())>110^2 then return false end
    if o.spec.hold and o.spec.hold>0 then
        local h=o.holding
        if not h or not self:TargetLive(c,h.binding) or h.binding.player~=p then
            o.holding={binding=self:BindTarget(c,p),start=CurTime()};return false
        end
        if CurTime()-h.start<o.spec.hold then return false end
        o.holding=nil
    end
    if CurTime()<(o.nextUse or 0) then return false end;o.nextUse=CurTime()+.2
    if o.spec.onUse then o.spec.onUse(c,o,p) end
    if not o.retired and c.def.ObjectEvent then c.def:ObjectEvent(c,o,'use',p) end
    return true
end
function B:ObjectDamage(c,o,info)
    if not self:Live(c) or o.retired or not IsValid(o.ent) then return false end
    local attacker=info:GetAttacker();if IsValid(attacker) and IsValid(attacker.LODOwner) then attacker=attacker.LODOwner end
    if not self:Hero(c,attacker) and not (IsValid(attacker) and attacker.LODBossEncounter==c) then return false end
    if o.spec.onDamage and o.spec.onDamage(c,o,info)==false then return false end
    if c.def.ObjectEvent then c.def:ObjectEvent(c,o,'hit',info) end
    if o.retired then return true end
    if o.spec.pushable and string.lower(o.state)~='critical' then
        local force=info:GetDamageForce();if force and force:Length()>0 then o.velocity=velocity(o.velocity+force/o.mass,600) end
    end
    if o.health<=0 then return false end
    o.health=math.max(0,o.health-math.max(0,info:GetDamage()));o.ent:SetHealth(o.health)
    if o.health==0 then
        if o.destroyed then return false end;o.destroyed=true
        if c.def.ObjectEvent then c.def:ObjectEvent(c,o,'destroy',info) end
        if o.spec.onDestroy then o.spec.onDestroy(c,o,'damage') end
        self:RemoveObject(c,o,'destroyed')
    end
    return true
end
function B:RemoveObject(c,o,why)
    if not o or o.retired or o.owner~=c then return false end
    o.retired=true;o.holding=nil
    if IsValid(o.ent) and o.ent.LODBossObject==o then o.ent:Remove() end
    return true
end
function B:Clear(c,kind)
    if not c then return end
    if type(kind)=='table' then
        if kind.ent then self:RemoveObject(c,kind,'clear') elseif kind.owner==c then kind.retired=true end
        return
    end
    for _,o in ipairs(c.objects or {}) do if not kind or o.spec.kind==kind then self:RemoveObject(c,o,'clear') end end
    for _,z in ipairs(c.hazards or {}) do if not kind or z.kind==kind then z.retired=true end end
end
function B:Zone(c,spec)
    if c.activeSourceBinding and not self:SourceLive(c,c.activeSourceBinding) then return end
    if not self:Live(c) or not self:Budget(c) or not self:CanInitiate(c,spec.source or c.actor,spec.damage or {}) then return end
    local z=table.Copy(spec);z.owner=c;z.committed=true;z.pos=copy(spec.pos or self:Center(c));z.ready=CurTime()+clamp(spec.delay or 0,0,20)
    z.expires=z.ready+clamp(spec.life or 1,.05,30);z.interval=clamp(spec.interval or .6,.15,10)
    z.radius=clamp(spec.radius or 80,4,900);z.source=spec.source or c.actor;z.next=z.ready;z.hits={}
    z.bindings=c.activeBindings or self:BindTargets(c);z.sourceBinding=self:BindSource(c,z.source)
    if z.damage then z.damage._committed=true;z.damage._bindings=z.bindings;z.damage._sourceBinding=z.sourceBinding end
    c.hazards[#c.hazards+1]=z
    self:Warn(c,z.label or z.kind or 'DANGER',z.pos,math.max(.1,z.ready-CurTime()),z.radius,
        {shape=z.shape,finish=z.finish,width=z.width,color=z.color})
    return z
end
local function segmentDistance(p,a,b)
    local d=b-a;local len=d:LengthSqr();local t=len>0 and math.Clamp((p-a):Dot(d)/len,0,1) or 0
    return p:DistToSqr(a+d*t),t
end
function B:ZoneContains(z,p)
    local pos=p:GetPos();if math.abs(pos.z-z.pos.z)>160 then return false end
    if z.shape=='lane' or z.shape=='rect' then
        local finish=z.finish or z.pos+Vector(z.radius*2,0,0)
        local distance=segmentDistance(Vector(pos.x,pos.y,z.pos.z),z.pos,finish)
        return distance<=(z.width and z.width*.5 or z.radius)^2
    end
    return Vector(pos.x,pos.y,z.pos.z):DistToSqr(z.pos)<=z.radius*z.radius
end
function B:ServiceZones(c,now)
    if not self:Current(c) then self:Clear(c);return end
    local kept={};local initial=#c.hazards
    for index=1,initial do local z=c.hazards[index];if not z.retired then
        if not self:SourceLive(c,z.sourceBinding) then z.retired=true
        elseif now>=z.expires then z.retired=true;if z.onExpire then self:Callback(c,z,z.onExpire,c,z) end
        elseif now>=z.ready and now>=z.next then
            z.next=now+z.interval;local targets={};local shared={}
            for _,p in ipairs(self:Targets(c)) do if self:TargetLive(c,z.bindings[p]) and self:ZoneContains(z,p) and self:Visible(c,z.pos,p,z.source) then
                targets[#targets+1]=p
                if z.damage then local spec=table.Copy(z.damage);spec._bindings=z.damage._bindings;spec._sourceBinding=z.damage._sourceBinding;spec._event=shared;spec.origin=z.pos;self:Damage(c,p,spec,z.source) end
                if z.push then self:Push(c,p,z.direction or p:GetPos()-z.pos,z.push,z.source) end
                if z.traction then c.traction=c.traction or {};c.traction[p]={binding=self:BindTarget(c,p),value=clamp(z.traction,.45,1),expires=now+z.interval+.1} end
            end end
            if z.onTick then self:Callback(c,z,z.onTick,c,z,targets) end
        end
        if not z.retired then kept[#kept+1]=z end
    end end
    for index=initial+1,#c.hazards do local z=c.hazards[index];if not z.retired then kept[#kept+1]=z end end
    c.hazards=kept
end
function B:ServiceObjects(c,now,dt)
    if not self:Current(c) then self:Clear(c);return end
    local kept={};local initial=#c.objects
    for index=1,initial do local o=c.objects[index];if not o.retired then
        if o.sourceBinding and not o.spec.cosmetic and (o.projectile or not o.spec.permanent and not o.spec.use) and not self:SourceLive(c,o.sourceBinding) then self:RemoveObject(c,o,'source_life')
        elseif not IsValid(o.ent) then
            o.retired=true;if c.def.ObjectEvent then c.def:ObjectEvent(c,o,'lost') end
        else
            if o.spec.permanent then o.expires=now+60 end
            if o.holding then local p=o.holding.binding.player
                if not self:TargetLive(c,o.holding.binding) or not p:KeyDown(IN_USE) or p:GetPos():DistToSqr(o.pos)>110^2 then o.holding=nil
                elseif now-o.holding.start>=(o.spec.hold or 0) then self:ObjectUse(c,o,p) end
            end
            local explode=o.fuse and now>=o.fuse
            if o.spec.proxRadius and now-o.created>.5 then for _,p in ipairs(self:Targets(c)) do
                if p:GetPos():DistToSqr(o.pos)<=o.spec.proxRadius^2 and self:Visible(c,o.pos,p,o.source) then explode=true;break end
            end end
            if explode then
                if o.spec.explodeRadius and o.spec.explodeRadius>0 then self:Area(c,o.pos,o.spec.explodeRadius,o.spec.damage,o.source) end
                if o.spec.onExpire then self:Callback(c,o,o.spec.onExpire,c,o) end
                if c.def.ObjectEvent then c.def:ObjectEvent(c,o,'fuse') end
                self:RemoveObject(c,o,'fuse')
            elseif now>=o.expires then
                if o.spec.onExpire then self:Callback(c,o,o.spec.onExpire,c,o) end
                if c.def.ObjectEvent then c.def:ObjectEvent(c,o,'expiry') end
                self:RemoveObject(c,o,'expired')
            elseif (self:Live(c) or c.dead and o.spec.cosmetic and self:Current(c)) and (length(o.velocity)>0 or (o.gravity or 0)>0) then
                o.velocity=velocity(o.velocity+Vector(0,0,-(o.gravity or 0)*dt),1400)
                local dest=o.pos+o.velocity*dt;local radius=clamp(o.spec.radius or 12,2,120)
                local tr=util.TraceHull({start=o.pos,endpos=dest,mins=Vector(-radius,-radius,-radius),maxs=Vector(radius,radius,radius),mask=MASK_SHOT,
                    filter=function(e) return e~=o.ent and e~=o.source and not (e.LODBossObject and not e.LODBossObject.spec.solid) end})
                local old=o.pos;o.pos=copy(tr.Hit and tr.HitPos or dest)
                if tr.Hit then
                    local handled=o.spec.onImpact and self:Callback(c,o,o.spec.onImpact,c,o,tr)==true
                    if not handled and not o.retired then
                        if self:Hero(c,tr.Entity) and (not o.bindings or self:TargetLive(c,o.bindings[tr.Entity])) then
                            local binding=self:BindTarget(c,tr.Entity)
                            local prior=o.hits[tr.Entity]
                            if not prior or prior.life~=binding.life then
                                o.hits[tr.Entity]=binding;if o.spec.damage then self:Damage(c,tr.Entity,o.spec.damage,o.source) end
                                if o.spec.onHit then self:Callback(c,o,o.spec.onHit,c,o,tr.Entity) end
                            end
                        end
                        if o.bounces>0 and tr.HitNormal then
                            o.bounces=o.bounces-1;o.velocity=(o.velocity-tr.HitNormal*(2*o.velocity:Dot(tr.HitNormal)))*.72
                            o.pos=o.pos+tr.HitNormal*(radius+2)
                        elseif o.spec.breakOnImpact~=false then
                            if o.spec.explodeRadius and o.spec.explodeRadius>0 then self:Area(c,o.pos,o.spec.explodeRadius,o.spec.damage,o.source) end
                            if o.spec.onDestroy then self:Callback(c,o,o.spec.onDestroy,c,o,'impact') end
                            self:RemoveObject(c,o,'impact')
                        else o.velocity=Vector(0,0,0);o.gravity=0 end
                    end
                end
                if not o.retired and not self:Floor(c,o.pos) then self:RemoveObject(c,o,'bounds') end
                if not o.retired and o.spec.solid and not self:ObjectPositionAllowed(o,o.pos) then o.pos=old;o.velocity=Vector(0,0,0) end
                if not o.retired then o.ent:SetPos(o.pos);if o.spec.spin then local a=o.ent:GetAngles();o.ent:SetAngles(Angle(a.p+o.spec.spin*dt,a.y,a.r)) end end
            end
            if not o.retired then
                o.pos=copy(o.ent:GetPos())
                if o.lastSolid~=o.spec.solid then
                    if o.spec.solid and not self:ObjectPositionAllowed(o,o.pos) then o.spec.solid=false end
                    o.ent:SetSolid((o.spec.solid or o.health>0) and SOLID_BBOX or SOLID_NONE)
                    o.ent:SetCollisionGroup(o.spec.solid and COLLISION_GROUP_NONE or COLLISION_GROUP_DEBRIS);o.lastSolid=o.spec.solid
                end
                o.ent:SetNW2String('LOD_BossObjectState',tostring(o.state));o.ent:SetNW2String('LOD_BossObjectLabel',tostring(o.spec.useLabel or o.spec.label or ''));kept[#kept+1]=o
            end
        end
    end end
    for index=initial+1,#c.objects do local o=c.objects[index];if not o.retired then kept[#kept+1]=o end end
    c.objects=kept
end
function B:Stop(c,e)
    local cancelled=c.moves[e];c.moves[e]=nil
    if cancelled and cancelled.charge and cancelled.spec.onFinish and self:Current(c) and not c.dead then
        local before=c.cancelling;c.cancelling=true
        self:Callback(c,cancelled,cancelled.spec.onFinish,c,false,IsValid(e) and copy(e:GetPos()) or copy(cancelled.start),{cancelled=true,Hit=false})
        c.cancelling=before
    end
    if IsValid(e) then e.LODWaypoints={};e.LODWaypointIndex=1;LOD.HostileMotionV2:Stop(e) end
end
function B:Move(c,e,dest,speed,opts)
    opts=opts or {};if c.cancelling or not self:Live(c) or not self:Owned(c,e) or not alive(e) then return false,true end
    if c.moves[e] and c.moves[e].charge then return false,false end
    if not LOD.RPGStatusElements:CanMoveVoluntarily(e) or CurTime()<math.max(e.LODBossStaggerUntil or 0,e.LODHitStunUntil or 0) then self:Stop(c,e);return false,false end
    local mode=opts.mode or 'ground';local floor=self:Floor(c,dest);if not floor then return false,true end
    if mode~='air' then dest=floor else
        dest=copy(dest);if opts.height and dest.z<=floor.z+4 then dest.z=floor.z+opts.height end
        local low=e.LODBossAirborne and self:Center(c).z+80 or floor.z+20
        dest.z=clamp(dest.z,low,self:Center(c).z+700)
    end
    local now=CurTime();local m=c.moves[e]
    if not m or not m.dest or m.dest:DistToSqr(dest)>64^2 then
        m={dest=copy(dest),speed=clamp(speed or 150,20,1100),mode=mode,opts=opts,last=now,start=copy(e:GetPos()),born=now};c.moves[e]=m
        if mode=='ground' then
            if opts.path then
                m.authored=true;m.waypoints={}
                for _,point in ipairs(opts.path) do local p=point.pos or point;local floor=self:Floor(c,p)
                    if not floor then c.moves[e]=nil;return false,true end
                    m.waypoints[#m.waypoints+1]={pos=copy(floor),tolerance=opts.stopDistance or 25,stair=point.stair==true}
                end
            else
                local from=self:ExactCell(c,e:GetPos());local to=self:ExactCell(c,dest)
                m.path=from and to and N:FindPath(c.graph,from,to,function(cell) return c.arena.court[B.Key(cell)] end)
                m.waypoints=m.path and N:PathToWaypoints(c.graph,m.path) or {}
            end
            m.index=1
        end
    else m.speed=clamp(speed or m.speed,20,1100) end
    return e:GetPos():DistToSqr(dest)<(opts.stopDistance or 30)^2,m.blocked==true
end
function B:Charge(c,e,dest,spec)
    spec=spec or {}
    if not self:CanInitiate(c,e,spec.damage or {}) or not self:Owned(c,e) or c.moves[e] and c.moves[e].charge then
        if self:Current(c) and not c.dead and IsValid(e) and spec.onFinish and not c.cancelling then local before=c.cancelling;c.cancelling=true;spec.onFinish(c,false,copy(e:GetPos()),{cancelled=true,rejected=true,Hit=false});c.cancelling=before end
        return false
    end
    local floor=self:Floor(c,dest);if not floor then return false end
    local start=copy(e:GetPos());dest=spec.mode=='air' and copy(dest) or floor
    local now=CurTime();local m={charge=true,start=start,dest=dest,ready=now+clamp(spec.warning or 1,.25,5),
        speed=clamp(spec.speed or 480,80,1100),spec=spec,hits={},mode=spec.mode or 'ground',last=now}
    m.duration=math.max(.15,spec.minimumDuration or 0,math.sqrt(start:DistToSqr(dest)+(2*math.max(0,spec.arc or 0))^2)/m.speed);m.expires=m.ready+m.duration+.5
    m.bindings=c.activeBindings or self:BindTargets(c);m.sourceBinding=self:BindSource(c,e);m.contextSource=c.activeSourceBinding
    for p,binding in pairs(m.bindings) do if self:TargetLive(c,binding) then m.hits[p]={binding=binding,hit=false} end end
    c.moves[e]=m;self:Warn(c,spec.label or 'CHARGE',start,m.ready-now,spec.width or 64,
        {shape='lane',finish=dest,width=spec.width or 64});return true
end
function B:ServiceMoves(c,now,dt)
    for e,m in pairs(c.moves) do
        if not self:Owned(c,e) or not alive(e) then c.moves[e]=nil
        elseif not LOD.RPGStatusElements:CanMoveVoluntarily(e) or now<math.max(e.LODBossStaggerUntil or 0,e.LODHitStunUntil or 0) then
            self:Stop(c,e) -- retire, never jump forward along expired motion on recovery
        elseif m.charge then
            if not self:SourceLive(c,m.sourceBinding) or m.contextSource and not self:SourceLive(c,m.contextSource) then self:Stop(c,e)
            elseif now>=m.ready then
                local frac=math.Clamp((now-m.ready)/m.duration,0,1);local wanted=m.start+(m.dest-m.start)*frac
                if m.spec.arc then wanted.z=wanted.z+math.sin(math.pi*frac)*clamp(m.spec.arc,0,400) end
                if m.spec.lateralArc then local direction=(m.dest-m.start):GetNormalized();wanted=wanted+Vector(-direction.y,direction.x,0)*math.sin(math.pi*frac)*clamp(m.spec.lateralArc,-120,120) end
                local from=e:GetPos();local lo,hi=self:Hull(e)
                local tr=util.TraceHull({start=from,endpos=wanted,mins=lo,maxs=hi,mask=MASK_NPCSOLID,
                    filter=function(v) return v~=e and not v:IsPlayer() and not v.LODHostile end})
                local pos=tr.Hit and tr.HitPos or wanted;e:SetPos(pos);LOD.HostileMotionV2:FaceToward(e,m.dest)
                for p,h in pairs(m.hits) do if not h.hit and self:TargetLive(c,h.binding) then
                    local dist=segmentDistance(p:WorldSpaceCenter(),from+Vector(0,0,36),pos+Vector(0,0,36))
                    if dist<=((m.spec.width or 128)*.5)^2 and self:Visible(c,pos,p,e) then
                        h.hit=true;m.anyHit=true;if m.spec.damage then self:Damage(c,p,m.spec.damage,e) end
                    end
                end end
                if frac>=1 or tr.Hit or now>=m.expires then
                    c.moves[e]=nil;LOD.HostileMotionV2:Stop(e)
                    if m.spec.recovery then e.LODBossRecoveryUntil=now+clamp(m.spec.recovery,.1,8) end
                    if m.spec.onFinish then self:Callback(c,m,m.spec.onFinish,c,m.anyHit==true,copy(pos),tr.Hit and tr or nil) end
                end
            end
        elseif m.mode=='ground' then
            local wp=m.waypoints[m.index]
            if wp and e:GetPos():DistToSqr(wp.pos)<(wp.tolerance or 25)^2 then m.index=m.index+1;wp=m.waypoints[m.index] end
            if not wp then wp={pos=m.dest,tolerance=20,stair=false} end
            local cfg=e.LODConfig;local old=cfg.speed;cfg.speed=m.speed;LOD.HostileMotionV2:MoveToward(e,wp);cfg.speed=old
            m.blocked=e.LODBossMotionBlocked==true
            if m.blocked and not m.authored and now>=(m.repathAt or 0) then
                m.repathAt=now+1
                local detour=self:GroundDetour(c,e,m.dest,e.LODBossBlockTrace)
                if detour then m.waypoints=detour;m.index=1;m.blocked=false end
            end
            if e:GetPos():DistToSqr(m.dest)<(m.opts.stopDistance or 30)^2 then self:Stop(c,e) end
        else
            local pos=e:GetPos();local delta=m.dest-pos;local dist=delta:Length()
            if dist<(m.opts.stopDistance or 30) then self:Stop(c,e)
            else
                local desired=delta:GetNormalized()*m.speed
                m.velocity=m.velocity or e:GetForward()*math.min(m.speed,80)
                local turn=clamp(m.opts.turnRate or 2,.25,8);m.velocity=m.velocity+(desired-m.velocity)*math.min(1,turn*dt)
                local dest=pos+velocity(m.velocity,m.speed)*dt
                if m.mode=='skate' or m.mode=='bounce' then local floor=self:Floor(c,dest);if floor then
                    dest.z=floor.z
                    if m.mode=='bounce' then dest.z=dest.z+math.abs(math.sin((now-m.born)*math.pi*1.5))*clamp(m.opts.height or 60,0,200) end
                end end
                local lo,hi=self:Hull(e);local tr=util.TraceHull({start=pos,endpos=dest,mins=lo,maxs=hi,mask=MASK_NPCSOLID,
                    filter=function(v) return v~=e and not v:IsPlayer() and not v.LODHostile end})
                m.blocked=tr.Hit==true
                if not tr.StartSolid and self:Floor(c,dest) then e:SetPos(tr.Hit and tr.HitPos or dest) end
                if tr.Hit then m.velocity=m.velocity*.2 end
                LOD.HostileMotionV2:FaceToward(e,pos+m.velocity)
            end
        end
    end
end
function B:Hull(e)
    local d=e.LODBossDefinition;local h=e.LODBossHull or d and d.hull
    return h and (h.mins or h[1]) or Vector(-16,-16,0),h and (h.maxs or h[2]) or Vector(16,16,72)
end
function B:Relocate(c,e,dest,label)
    local p=self:SafePoint(c,dest);if not p or not self:Owned(c,e) or not alive(e) then return false end
    self:Warn(c,label or 'RELOCATING',e:GetPos(),.6,48);self:Warn(c,label or 'ARRIVAL',p,.6,48)
    local life=LOD.RPGStatusElements.ActorLives[e]
    return self:Later(c,.6,'relocate:'..e:EntIndex(),function(owner)
        if B:Owned(owner,e) and alive(e) and LOD.RPGStatusElements.ActorLives[e]==life and B:SafePoint(owner,p) then B:Stop(owner,e);e:SetPos(p) end
    end)
end
function B:Constrain(c,binding,opts)
    if c.cancelling or not self:Live(c) or not self:TargetLive(c,binding) then return false end
    if c.activeBindings and not self:TargetLive(c,c.activeBindings[binding.player]) then return false end
    if c.activeSourceBinding and not self:SourceLive(c,c.activeSourceBinding) then return false end
    c.constraints=c.constraints or {};local now=CurTime();local p=binding.player
    if now<(p.LODBossConstraintGuard or 0) then return false end
    local seconds=clamp(opts.seconds or 2,.2,4);p.LODBossConstraintGuard=now+seconds+4
    c.constraints[opts.key]={binding=binding,center=copy(opts.center or p:GetPos()),radius=clamp(opts.radius or 40,24,100),expires=now+seconds}
    return true
end
function B:ReleaseConstraint(c,k) if c.constraints then c.constraints[k]=nil end end
hook.Add('SetupMove','LOD_BossBoundedMovement',function(p,mv)
    local c=R.State.Boss;if not B:Live(c) then return end
    local now=CurTime()
    local t=c.traction and c.traction[p]
    if t and B:TargetLive(c,t.binding) and now<t.expires and p:OnGround() then
        -- Slipperiness is bounded horizontal inertia, not a speed debuff.
        -- Ordinary engine collision, jump Z and class movement stay authoritative.
        c.sliding=c.sliding or {};local old=c.sliding[p]
        local current=mv:GetVelocity();local previous=old and B:TargetLive(c,old.binding) and old.velocity or p:GetVelocity()
        local dt=math.Clamp(now-(old and old.at or now-.015),.001,.05)
        local delta=Vector(current.x-previous.x,current.y-previous.y,0)
        local maxChange=900*t.value*dt
        if delta:Length()>maxChange then delta=delta:GetNormalized()*maxChange end
        local horizontal=Vector(previous.x,previous.y,0)+delta
        local maxSpeed=math.max(1,mv:GetMaxSpeed())
        if horizontal:Length()>maxSpeed then horizontal=horizontal:GetNormalized()*maxSpeed end
        mv:SetVelocity(Vector(horizontal.x,horizontal.y,current.z))
        c.sliding[p]={binding=t.binding,velocity=Vector(horizontal.x,horizontal.y,0),at=now}
    elseif c.sliding then c.sliding[p]=nil end
    for k,q in pairs(c.constraints or {}) do
        if now>=q.expires or not B:TargetLive(c,q.binding) then c.constraints[k]=nil
        elseif q.binding.player==p then
            local pos=mv:GetOrigin();local delta=pos-q.center;delta.z=0
            if delta:Length()>q.radius then local allowed=q.center+delta:GetNormalized()*q.radius;allowed.z=pos.z;mv:SetOrigin(allowed) end
            local v=mv:GetVelocity();mv:SetVelocity(Vector(v.x*.25,v.y*.25,v.z))
        end
    end
end)
function B:SetHull(c,e,hull)
    if not self:Current(c) or not self:Owned(c,e) or not hull or not hull.mins or not hull.maxs then return false end
    e.LODBossHull={mins=copy(hull.mins),maxs=copy(hull.maxs)}
    e:SetCollisionBounds(e.LODBossHull.mins,e.LODBossHull.maxs);return true
end
function B:ObjectPushAllowed(e)
    local o=IsValid(e) and e.LODBossObject
    return o and not o.retired and self:Live(o.owner) and o.spec.pushable==true and not o.spec.cosmetic
        and string.lower(tostring(o.state))~='critical' and string.lower(tostring(o.state))~='ignited'
end
function B:PushScale(e)
    local o=IsValid(e) and e.LODBossObject
    if o then return self:ObjectPushAllowed(e) and clamp(o.spec.pushScale or 1,0,2.5) or 0 end
    local d=e and e.LODBossDefinition
    return d and clamp(d.pushScale or 1,0,1) or 1
end
function B:PushObjectSettled(e,from,to,result)
    local o=e.LODBossObject;if not o or o.retired then return end
    o.pos=copy(to)
    if (result.moved or 0)>0 then
        local delta=to-from
        o.velocity=velocity(o.velocity+delta:GetNormalized()*math.min(400,result.moved*2),600)
    end
end
function B:StaticRamp(c,spec)
    if not self:Live(c) or not spec.pos then return end
    c.geometry=c.geometry or {};local steps=math.floor(clamp(spec.steps or 4,2,6))
    if #c.geometry+steps>24 then return end
    local width=clamp(spec.width or 160,80,500);local length=clamp(spec.length or 128,64,400)
    local height=clamp(spec.height or 24,4,48);if height/steps>12 then return end
    local yaw=math.floor((spec.yaw or 0)/90+.5)*90;local f=Angle(0,yaw,0):Forward()
    local lo=spec.pos-f*length*.5;local hi=spec.pos+f*length*.5
    if not self:Floor(c,lo) or not self:Floor(c,hi) then return end
    local made={}
    for i=1,steps do
        local pos=spec.pos+f*(-length*.5+(i-.5)*length/steps)
        local e=ents.Create('lod_static_box')
        if not IsValid(e) then for _,v in ipairs(made) do if IsValid(v) then v:Remove() end end;return end
        e.LODBossGeometry=c;e:SetPos(pos);e:SetAngles(Angle(0,yaw,0))
        e:SetBoxMins(Vector(-length/steps*.5,-width*.5,0));e:SetBoxMaxs(Vector(length/steps*.5,width*.5,height*i/steps));e:SetBoxKind(1)
        e:Spawn();if not IsValid(e) then for _,v in ipairs(made) do if IsValid(v) then v:Remove() end end;return end
        made[#made+1]=e
    end
    for _,e in ipairs(made) do c.geometry[#c.geometry+1]=e;LOD.MazeBuilder:_Register(e) end
    return {owner=c,entities=made,pos=copy(spec.pos),yaw=yaw,width=width,length=length,height=height,steps=steps,label=spec.label}
end

function B:GroundDetour(c,e,dest,tr)
    if not self:Live(c) or not self:Owned(c,e) then return end
    local lo,hi=self:Hull(e);local from=e:GetPos()
    if math.abs(from.z-dest.z)>32 then return end
    local entity=tr and tr.Entity;local obstacle=IsValid(entity) and entity:GetPos() or from+(dest-from):GetNormalized()*64
    local omin,omax;if IsValid(entity) then omin,omax=entity:GetCollisionBounds() end
    local extent=omax and math.max(math.abs(omax.x),math.abs(omax.y),math.abs(omin.x),math.abs(omin.y)) or 48
    local body=math.max(math.abs(lo.x),math.abs(lo.y),math.abs(hi.x),math.abs(hi.y));extent=extent+body+28
    local function clear(a,b)
        if not self:Floor(c,b) then return false end
        for i=0,8 do if not self:Floor(c,a+(b-a)*i/8) then return false end end
        local trace=util.TraceHull({start=a,endpos=b,mins=lo,maxs=hi,mask=MASK_NPCSOLID,
            filter=function(v) return v~=e and not v:IsPlayer() and not v.LODHostile end})
        return not trace.Hit and not trace.StartSolid and not trace.AllSolid
    end
    local nodes={copy(from),copy(dest)}
    for _,sx in ipairs({-1,1}) do for _,sy in ipairs({-1,1}) do
        local p=self:Floor(c,Vector(obstacle.x+sx*extent,obstacle.y+sy*extent,from.z))
        if p then nodes[#nodes+1]=p end
    end end
    -- Six-node local visibility graph permits the required TWO-corner bypass
    -- around a centered obstacle. A single-corner shortcut cannot do that.
    local distance,previous,done={[1]=0},{},{}
    for _=1,#nodes do
        local best,cost
        for index=1,#nodes do if not done[index] and distance[index] and (not cost or distance[index]<cost) then best,cost=index,distance[index] end end
        if not best then break end
        if best==2 then
            local reverse={};local at=2
            while at and at~=1 do reverse[#reverse+1]={pos=copy(nodes[at]),tolerance=20,stair=false};at=previous[at] end
            local out={};for i=#reverse,1,-1 do out[#out+1]=reverse[i] end;return out
        end
        done[best]=true
        for index=1,#nodes do if not done[index] and index~=best and clear(nodes[best],nodes[index]) then
            local candidate=cost+nodes[best]:Distance(nodes[index])
            if not distance[index] or candidate<distance[index] then distance[index]=candidate;previous[index]=best end
        end end
    end
end
function B:ObjectPositionAllowed(o,pos)
    if not o or o.retired or not self:Live(o.owner) or not self:Floor(o.owner,pos) then return false end
    if not o.spec.solid then return true end
    local solid=o.spec.solid;o.spec.solid=false
    local ok=self:ValidateRoutes(o.owner,{pos},o.spec.radius or 24)
    o.spec.solid=solid;return ok
end
