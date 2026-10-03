-- Behavioral contract double for authored modules, not native GMod acceptance.
local F = {}
local Vec = {}; Vec.__index = Vec
function Vector(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},Vec) end
function Vec.__add(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
function Vec.__sub(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
function Vec.__unm(a) return Vector(-a.x,-a.y,-a.z) end
function Vec.__mul(a,b) if type(a)=='number' then a,b=b,a end return Vector(a.x*b,a.y*b,a.z*b) end
function Vec.__div(a,b) return Vector(a.x/b,a.y/b,a.z/b) end
function Vec:LengthSqr() return self.x*self.x+self.y*self.y+self.z*self.z end
function Vec:Length() return math.sqrt(self:LengthSqr()) end
function Vec:GetNormalized() return self:Length()>0 and self/self:Length() or Vector() end
function Vec:DistToSqr(v) return (self-v):LengthSqr() end
function Vec:Distance(v) return (self-v):Length() end
function Vec:Dot(v) return self.x*v.x+self.y*v.y+self.z*v.z end
function Vec:Angle() return Angle() end
function Color(r,g,b,a) return {r=r,g=g,b=b,a=a or 255} end
function IsValid(e) return type(e)=='table' and e.valid==true end
local Ang={};Ang.__index=Ang
function Angle(p,y,r) return setmetatable({p=p or 0,y=y or 0,r=r or 0},Ang) end
function Ang:RotateAroundAxis() end
function Ang:Up() return Vector(0,0,1) end
function Ang:Forward() return Vector(1,0,0) end
local Entity={};Entity.__index=Entity
function F.Entity(pos,hp) return setmetatable({valid=true,pos=pos or Vector(),hp=hp or 100,maxhp=hp or 100,nw={},life=1},Entity) end
function Entity:GetPos() return self.pos end
function Entity:SetPos(p) self.pos=p end
function Entity:GetForward() return Vector(1,0,0) end
function Entity:GetRight() return Vector(0,1,0) end
function Entity:GetUp() return Vector(0,0,1) end
function Entity:GetAngles() return self.angles or Angle() end
function Entity:SetAngles(v) self.angles=v end
function Entity:SetModel(m) self.model=m end
function Entity:GetModel() return self.model end
function Entity:SetColor(v) self.color=v end
function Entity:SetNW2String(k,v) self.nw[k]=v end
function Entity:SetNW2Bool(k,v) self.nw[k]=v end
function Entity:SetNW2Int(k,v) self.nw[k]=v end
function Entity:GetNW2String(k,d) if self.nw[k]~=nil then return self.nw[k] end return d end
Entity.GetNW2Bool=Entity.GetNW2String;Entity.GetNW2Int=Entity.GetNW2String
function Entity:GetMaxHealth() return self.maxhp end
function Entity:Health() return self.hp end
function Entity:SetHealth(h) self.hp=h end
function Entity:SetMaxHealth(h) self.maxhp=h end
function Entity:EmitSound(s) self.sound=s end
function Entity:WorldToLocal(p) return p-self.pos end
function Entity:LocalToWorld(p) return p+self.pos end
function Entity:LookupBone() return nil end
function Entity:Remove() self.valid=false end
DMG_BURN=8;DMG_SLOWBURN=2097152
function F.Info(pos,attacker,fire)
    local o={amount=10,pos=pos or Vector(),attacker=attacker,fire=fire}
    function o:GetDamagePosition() return self.pos end
    function o:GetAttacker() return self.attacker end
    function o:IsDamageType(t) return self.fire and t==DMG_BURN or false end
    function o:ScaleDamage(n) self.amount=self.amount*n end
    return o
end
LOD={BossEncounter={},BossPresentation={Modules={}}}
local B=LOD.BossEncounter
B.Modules={};B.Support={}
function B:Register(id,d) self.Modules[id]=d;d.id=id end
function B:RegisterSupport(id,d) self.Support[id]=d;d.id=id end
function B:Current(c) return not c.retired end
function B:Live(c) return self:Current(c) and not c.dead and not c.paused end
function B:Hero(c,p) return self:Live(c) and IsValid(p) and p.hero and p.hp>0 and not p.protected end
function B:Targets(c) local t={};for _,p in ipairs(c.targets) do if self:Hero(c,p) then t[#t+1]=p end end;return t end
function B:BindTarget(c,p) return {player=p,life=p.life} end
function B:TargetLive(c,b) return b and self:Hero(c,b.player) and b.life==b.player.life end
function B:Random(c,stream,lo,hi)
    c.rng[stream]=((c.rng[stream] or c.seed)+string.len(stream)*127)*48271%2147483647
    return lo+c.rng[stream]%(hi-lo+1)
end
function B:Float(c,stream,lo,hi) return lo+(hi-lo)*self:Random(c,stream,0,100000)/100000 end
function B:Point(c,index) local p=c.points[((index-1)%#c.points)+1];return Vector(p.x,p.y,p.z) end
function B:Center() return Vector() end
function B:Floor(c,p) if c.blockFloor or not p or math.abs(p.x)>2000 or math.abs(p.y)>2000 then return nil end return Vector(p.x,p.y,0) end
function B:SafePoint(c,p) return self:Floor(c,p) end
function B:ValidateRoutes(c,p,r) c.routeChecks=c.routeChecks+1;return not c.blockRoutes end
function B:Announce(c,t) c.announcements[#c.announcements+1]=t end
function B:Log(c,event,data) c.logs[#c.logs+1]={event=event,data=data,time=c.now} end
function B:Later(c,delay,key,fn) if not self:Live(c) then return false end c.pending[key]={at=c.now+delay,fn=fn};return true end
function B:Cancel(c,key) c.pending[key]=nil end
function B:Stagger(c,secs,actor) c.staggers[#c.staggers+1]={actor=actor or c.actor,seconds=secs};return true end
function B:Stop(c,actor) c.moves[actor]=nil end
function B:Move(c,actor,p,speed,opts) c.moves[actor]={pos=p,speed=speed,opts=opts};return false,false end
function B:Charge(c,actor,p,spec) c.charges[#c.charges+1]={actor=actor,pos=p,spec=spec};return true end
function B:Relocate(c,actor,p,label)
    c.relocations[#c.relocations+1]={actor=actor,pos=p,label=label,hp=actor.hp}
    B:Warn(c,label,p,1,40)
    B:Later(c,1,'relocate:'..tostring(actor),function(owner) if IsValid(actor) and owner.owned[actor] then actor:SetPos(p) end end)
end
function B:Damage(c,p,spec,source)
    if not self:Hero(c,p) or spec.gate and not spec.gate() then return end
    source=source or c.actor
    if not c.owned[source] or not IsValid(source) or source:Health()<=0 then return end
    c.damage[#c.damage+1]={target=p,spec=spec,source=source,time=c.now}
end
function B:Area(c,pos,radius,spec,source)
    for _,p in ipairs(self:Targets(c)) do if p:GetPos():DistToSqr(pos)<=radius*radius then self:Damage(c,p,spec,source) end end
end
function B:Push(c,p,dir,strength,source) c.pushes[#c.pushes+1]={target=p,strength=strength} end
function B:SelfDamage(c,amount,reason,actor)
    actor=actor or c.actor
    local applied=math.min(amount,actor.hp-1)
    actor.hp=actor.hp-applied
    c.selfDamage[#c.selfDamage+1]={actor=actor,amount=applied,reason=reason}
end
function B:Objects(c,kind) local a={};for _,o in ipairs(c.objects) do if not o.retired and (not kind or o.spec.kind==kind) then a[#a+1]=o end end;return a end
function B:Budget(c)
    local n=#self:Objects(c)
    for _,z in ipairs(c.hazards) do if not z.retired then n=n+1 end end
    return n<(c.def.maxObjects or 32)
end
function B:Object(c,spec)
    if not self:Live(c) or not self:Budget(c) then return end
    if spec.solid and not self:ValidateRoutes(c,{spec.pos},spec.radius or 20) then return end
    local o={id=#c.objects+1,spec=spec,source=spec.source or c.actor,ent=F.Entity(spec.pos,spec.hp or 0),pos=spec.pos,
        velocity=spec.velocity or Vector(),gravity=spec.gravity or 0,health=spec.hp or 0,expires=c.now+(spec.life or 60),state='stable',bounces=spec.bounces or 0}
    o.ent:SetNW2String('LOD_BossObjectKind',spec.kind)
    c.objects[#c.objects+1]=o
    return o
end
function B:Projectile(c,spec) local o=self:Object(c,spec);if o then o.projectile=true end;return o end
function B:RemoveObject(c,o,reason) if not o or o.retired then return end;o.retired=true;o.reason=reason;o.ent.valid=false end
function B:Clear(c,kind)
    if type(kind)=='table' then kind.retired=true;return end
    for _,o in ipairs(c.objects) do if o.spec.kind==kind then self:RemoveObject(c,o,'clear') end end
    for _,z in ipairs(c.hazards) do if z.kind==kind then z.retired=true end end
end
function B:Zone(c,spec)
    if not self:Live(c) or not self:Budget(c) then return nil end
    local z={}
    for k,v in pairs(spec) do z[k]=v end
    z.ready=c.now+(spec.delay or 0);z.expires=z.ready+(spec.life or 1);z.next=z.ready
    c.hazards[#c.hazards+1]=z
    self:Warn(c,z.label,z.pos,math.max(.1,spec.delay or 0),spec.radius or 80)
    return z
end
function B:Warn(c,label,pos,seconds,radius,opts)
    local w={label=label,pos=pos,seconds=seconds,radius=radius,opts=opts,time=c.now}
    c.warnings[#c.warnings+1]=w;return w
end
function B:CountActors(c,role)
    local n=0;for actor,r in pairs(c.owned) do if IsValid(actor) and actor.hp>0 and (not role or role==r) then n=n+1 end end;return n
end
function B:SpawnActor(c,id,role,pos,opts)
    if c.globalFull or not self:Live(c) or self:CountActors(c)-1>=c.def.maxAdds then return nil end
    local actor=F.Entity(pos,(self.Support[id] and self.Support[id].baseHP or 100)*(opts.hpFraction or 1))
    actor.archetype=id;actor.opts=opts
    c.actors[#c.actors+1]=actor;c.owned[actor]=role
    return actor
end
function B:SetPhase(c,n)
    local old=c.phase;c.phase=n;c.pending={};c.moves={}
    if c.def.Phase then c.def:Phase(c,n,old) end
end
function B:Complete(c) c.completions=c.completions+1 end
function B:ReplacePrimary(c,e) c.primary=e;c.actor=e;c.replacements=c.replacements+1 end
function F.New(id,party)
    local c={id=id,def=B.Modules[id],phase=1,party=party or 1,now=0,seed=17,data={},owned={},objects={},hazards={},actors={},points={},pending={},moves={},rng={},
        warnings={},logs={},damage={},announcements={},staggers={},selfDamage={},pushes={},charges={},relocations={},completions=0,replacements=0,routeChecks=0}
    for i=1,16 do local a=i*math.pi/8;c.points[i]=Vector(math.cos(a)*620,math.sin(a)*620,0) end
    c.actor=F.Entity(Vector(),c.def.baseHP);c.primary=c.actor;c.owned[c.actor]='primary';c.actors={c.actor}
    c.targets={F.Entity(Vector(280,0,0)),F.Entity(Vector(0,280,0))}
    for _,p in ipairs(c.targets) do p.hero=true end
    c.def:Start(c)
    return c
end
function F.Advance(c,seconds,think)
    local finish=c.now+seconds
    while c.now<finish-.000001 do
        c.now=math.min(finish,c.now+.05)
        if B:Live(c) then
            local due={}
            for key,job in pairs(c.pending) do if c.now+.000001>=job.at then due[#due+1]={key=key,job=job} end end
            table.sort(due,function(a,b) if a.job.at==b.job.at then return a.key<b.key end return a.job.at<b.job.at end)
            for _,v in ipairs(due) do if c.pending[v.key]==v.job then c.pending[v.key]=nil;v.job.fn(c) end end
            if think then c.def:Think(c,c.now,.05,B:Targets(c)) end
            for _,z in ipairs(c.hazards) do
                if not z.retired then
                    if c.now>=z.expires then z.retired=true;if z.onExpire then z.onExpire(c,z) end
                    elseif c.now>=z.ready and c.now>=z.next then
                        z.next=c.now+(z.interval or .6)
                        if z.onTick then
                            local targets={}
                            for _,p in ipairs(B:Targets(c)) do if p:GetPos():DistToSqr(z.pos)<=(z.radius or 80)^2 then targets[#targets+1]=p end end
                            z.onTick(c,z,targets)
                        end
                    end
                end
            end
            for _,o in ipairs(c.objects) do if not o.retired and not o.spec.permanent and c.now>=o.expires then
                if o.spec.onExpire then o.spec.onExpire(c,o) end
                if c.def.ObjectEvent then c.def:ObjectEvent(c,o,'expiry') end
                B:RemoveObject(c,o,'expiry')
            end end
        end
    end
end
function F.Destroy(c,o)
    if c.def.ObjectEvent then c.def:ObjectEvent(c,o,'destroy',F.Info(o.pos,c.targets[1])) end
    if o.spec.onDestroy then o.spec.onDestroy(c,o,'damage') end
    B:RemoveObject(c,o,'destroy')
end
function F.Assert(v,msg) if not v then error(msg,2) end end
function F.Count(c,event) local n=0;for _,v in ipairs(c.logs) do if v.event==event then n=n+1 end end;return n end
function F.Load()
    local root='gamemodes/legend_of_deborah/gamemode/lod/bosses/'
    for _,id in ipairs({'chuck','rank_and_file','cornette'}) do dofile(root..'sv_'..id..'.lua') end
end
F.B=B
return F
