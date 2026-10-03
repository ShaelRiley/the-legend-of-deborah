-- Deterministic module-level service double. Native traces/status/rewards are NOT simulated.
local F={checks=0}
local v={};v.__index=v
function Vector(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},v) end
function v.__add(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
function v.__sub(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
function v.__mul(a,b) if type(a)=='number' then return b*a end return Vector(a.x*b,a.y*b,a.z*b) end
function v:Dot(b) return self.x*b.x+self.y*b.y+self.z*b.z end
function v:Length() return math.sqrt(self:Dot(self)) end
function v:GetNormalized() local n=self:Length();return n==0 and Vector() or self*(1/n) end
function v:DistToSqr(b) local x=self-b;return x:Dot(x) end
function Color(r,g,b,a) return {r=r,g=g,b=b,a=a or 255} end
function IsValid(e) return type(e)=='table' and not e.invalid end
local now=0
function CurTime() return now end
local entity={};entity.__index=entity
function F.entity(pos)
    return setmetatable({pos=pos or Vector(),health=1000,maxHealth=1000,nw={},sounds={},spawn=1},entity)
end
function entity:GetPos() return Vector(self.pos.x,self.pos.y,self.pos.z) end
function entity:SetPos(pos) self.pos=pos end
function entity:GetForward() return Vector(1,0,0) end
function entity:GetMaxHealth() return self.maxHealth end
function entity:Health() return self.health end
function entity:SetHealth(h) self.health=h end
function entity:SetNW2String(k,x) self.nw[k]=x end
entity.SetNW2Int=entity.SetNW2String;entity.SetNW2Bool=entity.SetNW2String;entity.SetNW2Vector=entity.SetNW2String
function entity:EmitSound(s) self.sounds[#self.sounds+1]=s end
LOD={BossEncounter={Modules={}}}
local B=LOD.BossEncounter
function B:Register(id,d) d.id=id;self.Modules[id]=d end
function B:Current(c) return not c.retired end
function B:Live(c) return self:Current(c) and not c.dead and not c.frozen end
function B:Hero(c,p) return self:Live(c) and IsValid(p) and p.hero and p.health>0 end
function B:BindTarget(c,p) return {player=p,spawn=p.spawn,encounter=c} end
function B:TargetLive(c,b) return b and b.encounter==c and self:Hero(c,b.player) and b.spawn==b.player.spawn end
function B:Targets(c) return self:Hero(c,c.hero) and {c.hero} or {} end
function B:Point(c,i) local p=c.points[(math.floor(i or 1)-1)%#c.points+1];return Vector(p.x,p.y,p.z) end
function B:Center() return Vector() end
function B:Floor(c,p) if math.abs(p.x)>2000 or math.abs(p.y)>2000 then return nil end return Vector(p.x,p.y,0) end
B.SafePoint=B.Floor
function B:Random(c,stream,lo,hi)
    c.rng[stream]=(c.rng[stream] or c.seed)%2147483647*48271%2147483647
    return lo+c.rng[stream]%(hi-lo+1)
end
function B:Float(c,stream,lo,hi) return lo+(hi-lo)*self:Random(c,stream,0,10000)/10000 end
function B:Announce(c,text) c.announcements[#c.announcements+1]=text end
function B:Log(c,event,data) c.logs[#c.logs+1]={event=event,data=data} end
function B:Warn(c,label,pos,seconds,radius,opts) c.warnings[#c.warnings+1]={label=label,pos=pos,seconds=seconds,radius=radius,options=opts} end
function B:Later(c,delay,key,cb)
    if not self:Current(c) or (c.dead and key:sub(1,9)~='cosmetic:') then return false end
    c.pending[key]={at=c.now+delay,cb=cb,cosmetic=key:sub(1,9)=='cosmetic:'};return true
end
function B:Cancel(c,key) c.pending[key]=nil end
function B:Stagger(c,duration) if self:Live(c) then c.staggers[#c.staggers+1]=duration end end
function B:Heal(c,amount,a) if self:Live(c) then a=a or c.actor;a.health=math.min(a.maxHealth,a.health+amount);c.healed=c.healed+amount end end
function B:SelfDamage(c,amount) if self:Live(c) then c.actor.health=math.max(1,c.actor.health-amount) end end
function B:Move(c,a,pos,speed,opts)
    c.moves[#c.moves+1]={pos=pos,speed=speed,options=opts}
    if c.moveReached then a.pos=pos;return true,false end
    return false,c.moveBlocked or false
end
function B:Stop(c) c.stops=c.stops+1 end
function B:Charge(c,a,destination,spec)
    if not self:Live(c) then return false end
    c.charges[#c.charges+1]={pos=destination,spec=spec};return true
end
function B:CountActors(c,role) return c.addCounts[role] or 0 end
function B:QueueAdd(c,id,role,pos,options)
    c.adds[#c.adds+1]={id=id,role=role,pos=pos,options=options}
    c.addCounts[role]=(c.addCounts[role] or 0)+1
end
function B:ValidateRoutes(c,points,radius) c.routeChecks=c.routeChecks+1;return c.routesValid~=false end
function B:StaticRamp(c,spec)
    if not self:Live(c) or c.denyGeometry then return end
    c.geometry=c.geometry or {};if #c.geometry+spec.steps>24 then return end
    local ramp={spec=spec,pos=spec.pos,width=spec.width,length=spec.length,height=spec.height,steps=spec.steps,entities={}}
    for i=1,spec.steps do
        local block={height=spec.height*i/spec.steps,width=spec.width,length=spec.length/spec.steps}
        c.geometry[#c.geometry+1]=block;ramp.entities[#ramp.entities+1]=block
    end
    return ramp
end
function B:Object(c,spec)
    if not self:Current(c) or (not self:Live(c) and not (c.dead and spec.cosmetic)) then return nil end
    if c.denyObjects or #self:Objects(c)>=c.def.maxObjects then return nil end
    c.serial=c.serial+1
    local o={id=c.serial,spec=spec,kind=spec.kind,pos=spec.pos,velocity=spec.velocity,ent=F.entity(spec.pos),health=spec.hp,
        expires=spec.permanent and math.huge or c.now+(spec.life or 5)}
    c.objects[#c.objects+1]=o
    return o
end
function B:Projectile(c,spec) local o=self:Object(c,spec);if o then o.projectile=true end return o end
function B:Objects(c,kind)
    local out={};for _,o in ipairs(c.objects) do if not o.retired and (not kind or o.spec.kind==kind) then out[#out+1]=o end end;return out
end
function B:RemoveObject(c,o,reason) if o then o.retired=true;o.reason=reason end end
function B:Clear(c,what)
    if type(what)=='table' then what.retired=true;return end
    for _,o in ipairs(c.objects) do if o.spec.kind==what then o.retired=true end end
    for _,z in ipairs(c.hazards) do if z.spec.kind==what then z.retired=true end end
end
function B:Zone(c,spec)
    if not self:Live(c) or c.denyObjects then return end
    local count=0;for _,z in ipairs(c.hazards) do if not z.retired then count=count+1 end end
    if count>=24 then return end
    local z={spec=spec,pos=spec.pos,expires=c.now+(spec.delay or 0)+(spec.life or 5)}
    c.hazards[#c.hazards+1]=z;return z
end
function B:Area(c,pos,radius,spec) if self:Live(c) then c.areas[#c.areas+1]={pos=pos,radius=radius,spec=spec} end end
function B:Push(c,p,dir,strength) if self:Hero(c,p) then c.pushes[#c.pushes+1]={player=p,direction=dir,strength=strength} end end
function B:SetPhase(c,phase)
    local old=c.phase;c.phase=phase
    for key,job in pairs(c.pending) do if not job.cosmetic then c.pending[key]=nil end end
    if c.def.Phase then c.def:Phase(c,phase,old) end
end
function F.new(id,opts)
    local c={id=id,def=assert(B.Modules[id]),phase=1,data={},now=100,seed=883,rng={},serial=0,objects={},hazards={},pending={},
        points={},logs={},warnings={},announcements={},staggers={},moves={},charges={},areas={},pushes={},adds={},addCounts={},stops=0,healed=0,routeChecks=0}
    for i=1,12 do local t=(i-1)*math.pi/6;c.points[i]=Vector(math.cos(t)*650,math.sin(t)*650,0) end
    c.actor=F.entity();c.actor.maxHealth=c.def.baseHP;c.actor.health=c.def.baseHP;c.hero=F.entity(Vector(350,0,0));c.hero.hero=true
    for k,value in pairs(opts or {}) do c[k]=value end
    now=c.now;c.def:Start(c);return c
end
function F.advance(c,seconds)
    local stop=c.now+seconds
    while true do
        local picked,job
        for key,x in pairs(c.pending) do if x.at<=stop and (not job or x.at<job.at or (x.at==job.at and key<picked)) then picked,job=key,x end end
        if not job then break end
        c.now,now=job.at,job.at;c.pending[picked]=nil
        if B:Current(c) and ((B:Live(c) and not c.paused) or (c.dead and job.cosmetic)) then job.cb(c) end
    end
    c.now,now=stop,stop
    for _,o in ipairs(c.objects) do if not o.retired and c.now>=o.expires then o.retired=true end end
    for _,z in ipairs(c.hazards) do if not z.retired and c.now>=z.expires then z.retired=true end end
end
function F.check(value,message) F.checks=F.checks+1;assert(value,message) end
function F.event(c,o,event,payload) if not o then error('missing event object') end;c.def:ObjectEvent(c,o,event,payload);if event=='destroy' then B:RemoveObject(c,o,'destroyed') end end
function F.damageInfo(amount,pos) return {amount=amount,position=pos or Vector(),ScaleDamage=function(s,n)s.amount=s.amount*n end,GetDamagePosition=function(s)return s.position end} end
function F.log(c,event) local out={};for _,log in ipairs(c.logs) do if log.event==event then out[#out+1]=log end end;return out end
for _,id in ipairs({'ollie','crystal_bepis','ray','moshi'}) do dofile('gamemodes/legend_of_deborah/gamemode/lod/bosses/sv_'..id..'.lua') end
F.B=B
return F
