-- Engine/framework boundary double; production boss modules are unmodified.
local F={time=0}
local v={};v.__index=v
function Vector(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},v) end
function v.__add(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
function v.__sub(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
function v.__mul(a,b) if type(a)=='number' then a,b=b,a end;return Vector(a.x*b,a.y*b,a.z*b) end
function v.__div(a,b) return a*(1/b) end
function v:LengthSqr() return self.x*self.x+self.y*self.y+self.z*self.z end
function v:Length() return math.sqrt(self:LengthSqr()) end
function v:GetNormalized() local l=self:Length();return l==0 and Vector() or self/l end
function v:Dot(b) return self.x*b.x+self.y*b.y+self.z*b.z end
function v:DistToSqr(b) return (self-b):LengthSqr() end
function math.Clamp(n,a,b) return math.min(b,math.max(a,n)) end
function Color(r,g,b,a) return {r=r,g=g,b=b,a=a or 255} end
function table.Copy(t)
    if type(t)~='table' then return t end
    if getmetatable(t)==v then return Vector(t.x,t.y,t.z) end
    local out={};for k,value in pairs(t) do out[k]=table.Copy(value) end;return out
end
function CurTime() return F.time end
function Angle(p,y,r) return {p=p or 0,y=y or 0,r=r or 0} end
function IsValid(e) return type(e)=='table' and e.valid~=false end
IN_ATTACK=1
local serial=0
function F.actor(pos,hero)
    serial=serial+1
    local e={valid=true,pos=pos or Vector(),hp=800,maxhp=800,id=serial,hero=hero,life=1,nw={}}
    function e:GetPos() return self.pos end
    function e:SetPos(p) self.pos=p end
    function e:Health() return self.hp end
    function e:SetHealth(n) self.hp=n end
    function e:GetMaxHealth() return self.maxhp end
    function e:SetMaxHealth(n) self.maxhp=n end
    function e:GetForward() return Vector(1,0,0) end
    function e:GetAimVector() return self.aim or Vector(1,0,0) end
    function e:GetShootPos() return self.pos+Vector(0,0,50) end
    function e:WorldSpaceCenter() return self:GetShootPos() end
    function e:GetColor() return Color(220,80,40) end
    function e:SetColor(c) self.color=c end
    function e:GetModel() return self.model or 'models/player/group01/male_07.mdl' end
    function e:GetAngles() return Angle() end
    function e:GetNW2String(k,default) local value=self.nw[k];if value==nil then return default end;return value end
    e.GetNW2Bool=e.GetNW2String;e.GetNW2Int=e.GetNW2String;e.GetNW2Float=e.GetNW2String
    function e:SetModel(m) self.model=m end
    function e:SetModelScale(s) self.scale=s end
    function e:GetActiveWeapon() return {GetClass=function() return self.weapon or 'weapon_smg1' end} end
    function e:EntIndex() return self.id end
    function e:Nick() return 'HERO '..self.id end
    function e:IsPlayer() return self.hero==true end
    function e:Alive() return self.hp>0 and not self.LODDead end
    function e:SetNW2String(k,val) self.nw[k]=val end
    e.SetNW2Bool=e.SetNW2String;e.SetNW2Int=e.SetNW2String;e.SetNW2Float=e.SetNW2String
    return e
end
LOD={BossEncounter={Modules={}},RPG={MagicForms={},MagicContents={},IdentityCatalog={OrdinaryFeats={}},FeatEffectSystem={}},
    CharacterProgressionSystem={},CombatRolls={PlayerDamageProfiles={weapon_smg1={count=1,sides=8},weapon_pistol={count=1,sides=4}}},
    RPGAbilityRules={},MagicForms={},Magic={},RPGStatusElements={}}
for _,id in ipairs({'cone','blast','beam','bomb','missile','bolt','watermelon','super_ball','wall'}) do
    LOD.RPG.MagicForms[id]={id=id,damageDice=2,damageSides=6,magicCost=10}
end
for _,id in ipairs({'fire','ice','earth'}) do LOD.RPG.MagicContents[id]={id=id,surcharge=5} end
for _,id in ipairs({'STR_CROWBAR_D6','WIS_TRUE_FAITH','INT_MANA_BARRIER_1','INT_MANA_BARRIER_2','CHA_AGGRESSIVE_PERSONALITY','TIME_MANAGEMENT','DEX_QUICK_DRAW'}) do LOD.RPG.IdentityCatalog.OrdinaryFeats[id]={} end
function LOD.CharacterProgressionSystem:NewProgressionState(id,arch,kind) return {actorId=id,archetypeId=arch,actorType=kind,featIds={},equipmentAbilityDelta={},identityAbilityDelta={}} end
function LOD.CharacterProgressionSystem:_RecomputeProgressionState(p)
    p.derivedStats={maxHP=180,strMod=math.floor((p.baseAbilities.str-10)/2),rogueBackstabEnabled=p.classId=='rogue',
        hpToMagicDiversionFraction=p.classId=='wizard' and .02*p.level or 0}
    for _,id in ipairs(p.featIds) do if id=='INT_MANA_BARRIER_1' then p.derivedStats.hpToMagicDiversionFraction=p.derivedStats.hpToMagicDiversionFraction+.15 end end
end
function LOD.RPGAbilityRules:OffensiveMagicCost(e,cost) return cost end
function LOD.RPGAbilityRules:RateOfFireMultiplier() return 1 end
function LOD.MagicForms:TotalBaseCost(form,content) return form.magicCost+(content and content.surcharge or 0) end
function LOD.Magic:_EnsureState(e) return e.LODProgressionState end
function LOD.Magic:_Sync(e,p) e.magicSynced=p.magic end
function LOD.RPGStatusElements:CanInitiateMagic(e) return not e.muted end
function LOD.RPGStatusElements:DamageContext(info) return info.context or {} end
function LOD.RPG.FeatEffectSystem:CrowbarDamageProfile(e)
    for _,id in ipairs(e.LODProgressionState.featIds) do if id=='STR_CROWBAR_D6' then return {count=1,sides=6} end end
    return {count=1,sides=3}
end
local B=LOD.BossEncounter
function B:Register(id,d) self.Modules[id]=d end
function B:Current(c) return not c.retired and (not c.scope or c.scope.current==c) end
function B:Live(c) return self:Current(c) and not c.dead and not c.frozen end
function B:Hero(c,p) return self:Current(c) and IsValid(p) and p.hero and p:Alive() and not p.soldier end
function B:Targets(c) local a={};for _,p in ipairs(c.targets) do if self:Hero(c,p) then a[#a+1]=p end end;return a end
function B:BindTarget(c,p) return {player=p,life=p.life,encounter=c} end
function B:TargetLive(c,r) return r and r.encounter==c and self:Hero(c,r.player) and r.player.life==r.life end
function B:Random(c,stream,lo,hi) c.rngCalls[stream]=(c.rngCalls[stream] or 0)+1;return math.min(hi,lo+(c.randomOffset or 0)) end
function B:Point(c,i) return c.points[(i-1)%#c.points+1] end
function B:Center() return Vector() end
function B:Floor(c,p) return not c.noFloor and math.abs(p.x)<10000 and Vector(p.x,p.y,0) or nil end
function B:SafePoint(c,p) return not c.unsafe and self:Floor(c,p) or nil end
function B:ValidateRoutes(c) return not c.blockRoutes end
function B:Announce(c,s) c.notices[#c.notices+1]=s end
function B:Log(c,event,data) c.logs[#c.logs+1]={event=event,data=data} end
function B:SetPhase(c,n) if c.phase~=n then c.pending={};c.phase=n;if c.def.Phase then c.def:Phase(c,n) end end end
function B:Later(c,delay,key,callback) c.pending[key]={at=F.time+delay,fn=callback};return true end
function B:Cancel(c,key) c.pending[key]=nil end
function B:Warn(c,label,pos,seconds,radius,opts) c.warnings[#c.warnings+1]={label=label,pos=pos,seconds=seconds};return c.warnings[#c.warnings] end
function B:Object(c,spec)
    local n=0;for _,o in ipairs(c.objects) do if not o.retired then n=n+1 end end
    if c.failObjects or n>=c.def.maxObjects or not self:Current(c) or c.dead and not (spec.cosmetic or spec.role=='key_button') then return nil end
    c.ordinal=c.ordinal+1
    local o={id=c.ordinal,owner=c,spec=spec,ent=F.actor(spec.pos),pos=spec.pos,source=spec.source or c.actor}
    c.objects[#c.objects+1]=o;return o
end
function B:Projectile(c,spec) local o=self:Object(c,spec);if o then o.projectile=true;o.velocity=spec.velocity end;return o end
function B:RemoveObject(c,o) if not o or o.retired then return false end;o.retired=true;o.ent.valid=false;return true end
function B:Objects(c,kind) local out={};for _,o in ipairs(c.objects) do if not o.retired and (not kind or kind==o.spec.kind) then out[#out+1]=o end end;return out end
function B:Clear(c,kind) for _,o in ipairs(c.objects) do if not kind or kind==o.spec.kind then self:RemoveObject(c,o) end end;for _,z in ipairs(c.zones) do if not kind or kind==z.kind then z.retired=true end end end
function B:Zone(c,spec) c.zones[#c.zones+1]=spec;return spec end
function B:Damage(c,p,spec,source)
    if not self:Live(c) or not self:Hero(c,p) or spec.gate and not spec.gate() then return 0 end
    c.damage[#c.damage+1]={target=p,spec=spec,source=source};return 5
end
function B:Area(c,pos,radius,spec,source) for _,p in ipairs(self:Targets(c)) do if p:GetPos():DistToSqr(pos)<radius*radius then self:Damage(c,p,spec,source) end end end
function B:Push(c,p,dir,amount,source) c.pushes[#c.pushes+1]={target=p,amount=amount} end
function B:Visible() return true end
function B:Move(c,e,pos,speed,opts) c.moves[e]={pos=pos,speed=speed};return false,false end
function B:Stop(c,e) c.moves[e]=nil end
function B:Charge(c,e,pos,spec) c.charges[#c.charges+1]={actor=e,pos=pos,spec=spec};return true end
function B:Stagger(c,seconds,e) c.staggers[#c.staggers+1]={actor=e,seconds=seconds} end
function B:SelfDamage(c,amount,reason,e) e:SetHealth(math.max(1,e:Health()-amount));c.reflected=(c.reflected or 0)+1 end
function B:SpawnActor(c,arch,role,pos,opts)
    c.spawnAttempts=(c.spawnAttempts or 0)+1
    if c.partialFailure then
        c.partialFailure=nil
        local failed=F.actor(pos);failed.valid=false;c.lastPartial=failed
        return nil
    end
    if c.failActors or self:CountActors(c)-1>=c.def.maxAdds then return nil end
    local e=F.actor(pos);e.archetype=arch;e.LODArchetypeId=arch;e.role=role;e.opts=opts;c.owned[e]=role;c.actors[#c.actors+1]=e;return e
end
function B:CountActors(c,role) local n=0;for e,r in pairs(c.owned) do if e:Alive() and IsValid(e) and (not role or role==r) then n=n+1 end end;return n end
function B:RetireActor(c,e) e.valid=false;e.retired=true end
function B:QueueAdd(c,id,role,pos,opts) c.queued[#c.queued+1]={id=id,role=role};return true end
function B:ReplacePrimary(c,e) c.actor=e;c.primary=e;c.owned[e]='primary';return true end
function B:EnsureKey(c) if c.dead and c.receipt and c.keyReady and not c.key then c.key={};c.keyCount=c.keyCount+1 end end
function B:UseDamage(c,amount,p,token)
    if c.useReceipts[token] then return false end
    c.useReceipts[token]=true
    local info={};c.useDamage=info
    if c.def:BeforeDamage(c,c.actor,info)~=false then c.actor.hp=c.actor.hp-amount end
    c.useDamage=nil
    if c.actor.hp<=0 then F.kill(c,c.actor) end
    return true
end
function F.kill(c,e)
    e.hp=0;e.LODDead=true
    local handled=c.def.ActorKilled and c.def:ActorKilled(c,e,c.owned[e])
    if e==c.actor and not handled and not c.dead then
        c.dead=true;c.receipt={actor=e};c.pending={};B:Clear(c)
        if c.def.Defeat then c.def:Defeat(c) end
        if not c.def.deferKey then c.keyReady=true;B:EnsureKey(c) end
    end
end
function F.advance(c,seconds,think)
    F.time=F.time+seconds;c.now=F.time
    local jobs={};for k,q in pairs(c.pending) do if q.at<=F.time then c.pending[k]=nil;jobs[#jobs+1]=q end end
    for _,q in ipairs(jobs) do if B:Live(c) then q.fn(c) end end
    if think and B:Live(c) then c.def:Think(c,F.time,seconds,B:Targets(c)) end
end
function F.new(id,party,classes)
    F.time=0
    local c={def=B.Modules[id],id=id,serial=10,party=party or 1,phase=1,data={},owned={},actors={},objects={},zones={},warnings={},
        damage={},pushes={},staggers={},charges={},queued={},pending={},moves={},notices={},logs={},rngCalls={},ordinal=0,
        useReceipts={},keyCount=0,targets={},heroes={},points={},now=0}
    for i=1,15 do c.points[i]=Vector((i-8)*200,i%2*350,0) end
    for i=1,c.party do
        local p=F.actor(Vector(-1600,i*120,0),true);p.weapon=(classes and classes[i]=='fighter') and 'weapon_crowbar' or 'weapon_smg1'
        local ps={classId=classes and classes[i] or 'fighter',level=8,effectiveAbilities={str=16,dex=14,con=12,int=17,wis=16,cha=12},
            featIds={'TIME_MANAGEMENT','STR_CROWBAR_D6','WIS_TRUE_FAITH','CHA_AGGRESSIVE_PERSONALITY'},magicFormIds={'beam','cone','bomb','summon'},contentIds={'fire'},
            characterIdentityPackage={fullDisplayName='NAME '..i},derivedStats={maxHP=120},equipmentShieldEquipped=true,equipmentBlockChanceContribution=.1}
        c.heroes[i]={player=p,identity='identity'..i,progressionState=ps,model=p:GetModel(),color=p:GetColor()};c.targets[i]=p
    end
    c.actor=F.actor();c.primary=c.actor;c.owned[c.actor]='primary';c.actors[1]=c.actor
    c.def:Start(c);return c
end
F.B=B
return F
