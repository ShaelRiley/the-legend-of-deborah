-- API-boundary doubles only. Actual production boss modules implement all tested state machines.
local F={root='gamemodes/legend_of_deborah/gamemode/lod/bosses/'}
local V={};V.__index=V
function Vector(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},V) end
function V.__add(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
function V.__sub(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
function V.__mul(a,b) if type(a)=='number' then a,b=b,a end;return Vector(a.x*b,a.y*b,a.z*b) end
function V.__div(a,b) return a*(1/b) end
function V:LengthSqr() return self.x*self.x+self.y*self.y+self.z*self.z end
function V:Length() return math.sqrt(self:LengthSqr()) end
function V:DistToSqr(b) return (self-b):LengthSqr() end
function V:GetNormalized() return self:Length()>0 and self/self:Length() or Vector() end
function V:Distance(b) return (self-b):Length() end
function V:Dot(b) return self.x*b.x+self.y*b.y+self.z*b.z end
function Angle(p,y,r) return {p=p or 0,y=y or 0,r=r or 0} end
function Color(r,g,b,a) return {r=r,g=g,b=b,a=a or 255} end
function IsValid(e) return type(e)=='table' and not e.invalid end
DMG_CLUB,DMG_SLASH=128,4
MASK_NPCSOLID=1
function table.Count(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
util={TraceHull=function() return {Hit=false,StartSolid=false,AllSolid=false} end}
local function copy(v) return Vector(v.x,v.y,v.z) end
function F.actor(pos,hp)
    local e={pos=copy(pos or Vector()),hp=hp or 100,maxhp=hp or 100,nw={},life=1,active=true}
    function e:GetPos() return copy(self.pos) end
    function e:Health() return self.hp end
    function e:GetMaxHealth() return self.maxhp end
    function e:SetNW2String(k,v) self.nw[k]=v end
    function e:SetNW2Bool(k,v) self.nw[k]=v end
    function e:SetNW2Float(k,v) self.nw[k]=v end
    function e:SetNW2Vector(k,v) self.nw[k]=v end
    function e:SetAngles(a) self.angles=a end
    function e:LocalToWorld(p) return self:GetPos()+p end
    function e:IsPlayer() return self.player==true end
    function e:LookupBone() return nil end
    function e:LookupAttachment() return nil end
    return e
end
local B={registry={}};LOD={BossEncounter=B};F.B=B
function B:Register(id,def) self.registry[id]=def end
function B:Current(c) return not c.retired end
function B:Live(c) return self:Current(c) and not c.dead and not c.frozen end
function B:Hero(c,p) return p and IsValid(p) and p.active and p.hp>0 and not p.protected and not p.soldier and p.pos:LengthSqr()<1400^2 end
function B:Targets(c) local a={};for _,p in ipairs(c.heroes) do if self:Hero(c,p) then a[#a+1]=p end end;return a end
function B:BindTarget(c,p) return {player=p,life=p.life} end
function B:TargetLive(c,b) return self:Hero(c,b.player) and b.life==b.player.life end
function B:Point(c,n) return copy(c.points[((n-1)%#c.points)+1]) end
function B:Center() return Vector() end
function B:Floor(c,p) if not p or math.abs(p.x)>1000 or math.abs(p.y)>1000 then return nil end;return Vector(p.x,p.y,0) end
function B:SafePoint(c,p) return not c.unsafe and self:Floor(c,p) or nil end
function B:ValidateRoutes(c,positions,radius)
    c.routeChecks[#c.routeChecks+1]={positions=positions,radius=radius}
    return not c.routeBlocked
end
function B:Random(c,stream,lo,hi) c.rngStreams[stream]=true;return c.randomValue or hi end
function B:Float(c,stream,lo,hi) c.rngStreams[stream]=true;return (lo+hi)/2 end
function B:Announce(c,text) c.announcements[#c.announcements+1]=text end
function B:Log(c,event,data) c.logs[#c.logs+1]={event=event,data=data} end
function B:Warn(c,label,pos,seconds,radius,options)
    local w={label=label,pos=copy(pos),seconds=seconds,radius=radius,options=options};c.warnings[#c.warnings+1]=w;return w
end
function B:Later(c,delay,key,fn) c.pending[key]={at=c.now+delay,phase=c.phase,fn=fn,key=key} end
function B:Cancel(c,key) c.pending[key]=nil end
function B:SetPhase(c,p)
    local old=c.phase;c.phase=p;c.pending={};c.charge=nil;if c.def.Phase then c.def:Phase(c,p,old) end
end
function B:Stagger(c,seconds,actor) c.staggers[#c.staggers+1]={seconds=seconds,actor=actor or c.actor,at=c.now} end
function B:Heal(c,amount,actor) actor=actor or c.actor;actor.hp=math.min(actor.maxhp,actor.hp+amount) end
function B:SelfDamage(c,amount,reason,actor)
    actor=actor or c.actor;local actual=math.max(0,math.min(amount,actor.hp-1));actor.hp=actor.hp-actual
    c.selfDamage[#c.selfDamage+1]={amount=actual,reason=reason};return actual
end
function B:Objects(c,kind)
    local out={};for _,o in ipairs(c.objects) do if not o.retired and (not kind or o.spec.kind==kind) then out[#out+1]=o end end;return out
end
function B:Object(c,spec)
    if (not self:Live(c) and not (spec.cosmetic and self:Current(c))) or #self:Objects(c)>=c.def.maxObjects or c.denyObjects then return nil end
    c.objectSerial=c.objectSerial+1
    local o={id=c.objectSerial,kind=spec.kind,spec=spec,pos=copy(spec.pos),velocity=spec.velocity and copy(spec.velocity),
        ent=F.actor(spec.pos,spec.hp),health=spec.hp or 0,expires=spec.permanent and math.huge or c.now+(spec.life or 5),bounces=0}
    c.objects[#c.objects+1]=o;return o
end
function B:Projectile(c,spec) local o=self:Object(c,spec);if o then o.projectile=true end;return o end
function B:RemoveObject(c,o,reason) if not o or o.retired then return end;o.retired=true;o.retireReason=reason end
function B:Clear(c,kind)
    for _,o in ipairs(self:Objects(c,kind)) do self:RemoveObject(c,o,'cleanup') end
    for _,z in ipairs(c.zones) do if z.spec.kind==kind then z.retired=true end end
end
function B:Damage(c,p,spec,source)
    if not self:Live(c) or not self:Hero(c,p) or p.covered or (spec.gate and not spec.gate()) then return 0 end
    c.damage[#c.damage+1]={player=p,spec=spec,source=source or c.actor};return spec.damage or 10
end
function B:Push(c,p,d,strength,source) c.pushes[#c.pushes+1]={p=p,d=d,strength=strength};return self:Hero(c,p) end
function B:Area(c,pos,radius,spec,source)
    local hits=0;for _,p in ipairs(self:Targets(c)) do if p.pos:DistToSqr(pos)<=radius^2 and self:Damage(c,p,spec,source) then hits=hits+1 end end;return hits
end
local function inZone(p,s)
    if s.shape=='rect' or s.shape=='lane' then
        local v=s.finish-s.pos;local v2=v:LengthSqr();local t=v2>0 and (p-s.pos):Dot(v)/v2 or 0
        if t<0 or t>1 then return false end
        return p:DistToSqr(s.pos+v*t)<=(s.width*.5)^2
    end
    return p:DistToSqr(s.pos)<=(s.radius or 0)^2
end
function B:Zone(c,spec)
    if c.denyZones then return nil end
    local z={spec=spec,expires=c.now+(spec.delay or 0)+spec.life};c.zones[#c.zones+1]=z
    local serial=#c.zones
    self:Later(c,spec.delay or 0,'fixture_zone_tick_'..serial,function(owner)
        if z.retired then return end
        local hit={};for _,p in ipairs(self:Targets(owner)) do
            if inZone(p.pos,spec) and not p.covered then hit[#hit+1]=p;if spec.damage then self:Damage(owner,p,spec.damage,spec.source) end end
        end
        if spec.onTick then spec.onTick(owner,z,hit) end
    end)
    self:Later(c,(spec.delay or 0)+spec.life,'fixture_zone_end_'..serial,function(owner)
        if z.retired then return end;z.retired=true;if spec.onExpire then spec.onExpire(owner,z) end
    end)
    return z
end
function B:Move(c,actor,destination,speed,options)
    c.moves[#c.moves+1]={actor=actor,destination=destination,speed=speed,options=options}
    if c.moveReached then actor.pos=copy(destination) end
    return c.moveReached or false,c.moveBlocked or false
end
function B:Stop(c,actor) c.stops=c.stops+1;c.charge=nil end
function B:Charge(c,actor,destination,spec)
    if c.rejectCharge then if spec.onFinish then spec.onFinish(c,false,actor:GetPos(),{cancelled=true}) end;return false end
    local r={actor=actor,destination=copy(destination),spec=spec};c.charges[#c.charges+1]=r;c.charge=r;return true
end
function F.finishCharge(c,hit,pos,trace)
    local r=assert(c.charge,'expected active charge');c.charge=nil
    r.actor.pos=copy(pos or r.destination)
    if r.spec.onFinish then r.spec.onFinish(c,hit or false,r.actor:GetPos(),trace) end
end
function F.fresh(id)
    local def=assert(B.registry[id]);local c={id=id,def=def,phase=1,now=0,startedAt=0,data={},party=1,points={},arena={ricochetPoints={Vector(-950,0,70),Vector(950,0,70)}},objects={},zones={},pending={},objectSerial=0,
        announcements={},warnings={},logs={},damage={},selfDamage={},pushes={},staggers={},moves={},charges={},routeChecks={},rngStreams={},stops=0}
    for y=-3,3 do for x=-3,3 do c.points[#c.points+1]=Vector(x*250,y*250,0) end end
    c.serial=1;c.constraints={};c.releases={}
    c.actor=F.actor(Vector(),def.baseHP);c.primary=c.actor;c.heroes={F.actor(Vector(300,0,0))}
    def:Start(c);return c
end
function F.advance(c,seconds)
    local finish=c.now+seconds;local safety=0
    while true do
        local nextJob
        for _,job in pairs(c.pending) do if job.at<=finish and (not nextJob or job.at<nextJob.at or (job.at==nextJob.at and job.key<nextJob.key)) then nextJob=job end end
        if not nextJob then break end
        c.pending[nextJob.key]=nil;c.now=nextJob.at
        if B:Current(c) and (B:Live(c) or (c.dead and nextJob.key:sub(1,9)=='cosmetic:')) and nextJob.phase==c.phase then nextJob.fn(c) end
        safety=safety+1;assert(safety<500,'unbounded queue')
    end
    c.now=finish
    local snapshot=B:Objects(c)
    for _,o in ipairs(snapshot) do
        if o.expires<=finish and not o.retired then
            if B:Live(c) and o.spec.onExpire then o.spec.onExpire(c,o) end
            B:RemoveObject(c,o,'expired')
        end
    end
end
function F.think(c,seconds) F.advance(c,seconds or 0);if B:Live(c) then c.def:Think(c,c.now,.1,B:Targets(c)) end end
function F.hitObject(c,o,damage)
    if o.retired then return end
    local info={GetDamage=function() return damage end}
    if c.def.ObjectEvent then c.def:ObjectEvent(c,o,'hit',info) end
    o.health=o.health-damage
    if o.health<=0 then
        if c.def.ObjectEvent then c.def:ObjectEvent(c,o,'destroy',info) end
        if o.spec.onDestroy then o.spec.onDestroy(c,o,'damage') end
        B:RemoveObject(c,o,'damage')
    end
end
function F.impact(c,o,normal)
    local tr={Hit=true,HitWorld=true,HitNormal=normal or Vector(0,0,1),HitPos=o.pos}
    if o.spec.onImpact and o.spec.onImpact(c,o,tr)==true then return end
    if o.bounces<(o.spec.bounces or 0) then
        o.bounces=o.bounces+1;o.velocity=o.velocity-tr.HitNormal*(2*o.velocity:Dot(tr.HitNormal))
    elseif o.spec.breakOnImpact then
        if o.spec.onDestroy then o.spec.onDestroy(c,o,'impact') end;B:RemoveObject(c,o,'impact')
    end
end
function F.pause(c) c.frozen=true;c.pending={};c.charge=nil;c.def:Pause(c,'no_heroes') end
function B:SetHull(c,actor,hull) if not self:Current(c) or not IsValid(actor) then return false end;actor.LODBossHull=hull;return true end
function B:Constrain(c,binding,opts)
    if not self:TargetLive(c,binding) or c.denyConstraint then return false end
    c.constraints[opts.key]={binding=binding,opts=opts,expires=c.now+opts.seconds};return true
end
function B:ReleaseConstraint(c,key) c.constraints[key]=nil;c.releases[#c.releases+1]=key end
function F.damageInfo(kind)
    local i={value=10,kind=kind,pos=Vector()};function i:GetDamagePosition() return self.pos end;function i:IsDamageType(t) return self.kind==t end;function i:ScaleDamage(s) self.value=self.value*s end;return i
end
for _,id in ipairs({'marion','flightmeister','conan','little_mooky'}) do dofile(F.root..'sv_'..id..'.lua') end
return F
