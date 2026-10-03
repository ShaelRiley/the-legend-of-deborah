-- Exactly three individual Cleaner receipts open BDD; player bodies own none.
local B = LOD.BossEncounter
local D = {
    name="Joilette the Toilet", model="models/props_c17/FurnitureToilet001a.mdl",
    baseHP=950, speed=100, size=3, manualPhase=true, maxObjects=22, maxAdds=7,
    phaseNames={"Occupied","Out of Order","EXPOSED"},
    arena={theme="Restroom of Doom",width=6,depth=6,upper=false},
    deathCaption="BATHROOM SECURED",keyLocation="bowl"
}
local function copy(v) return Vector(v.x,v.y,v.z) end
local function living(e) return IsValid(e) and not e.LODDead and e:Health()>0 end
local function at(c) return c.now or CurTime() end
local function liveObject(o) return o and not o.retired and IsValid(o.ent) end
local function receipt(c,r,generation)
    return B:Current(c) and not c.dead and c.data.hits<3 and not r.consumed and r.generation==generation
end
function D:Start(c)
    local d=c.data
    d.hits=0;d.cleaners={};d.cleanerActors={};d.bombActors={};d.attackSerial=0
    d.nextAttack=at(c)+2;d.nextNeil=at(c)+4
    for i=1,3 do d.cleaners[i]={slot=i,generation=1,state="pending",nextAt=at(c)+(i-1)*6} end
    self:EnsureBDD(c)
    c.actor:SetNW2Bool("LOD_BDDActive",true)
    B:Announce(c,"BDD ACTIVE — FIND TOILET CLEANER (0/3)")
end
function D:EnsureBDD(c)
    if c.data.hits>=3 or liveObject(c.data.bdd) then return end
    c.data.bdd=B:Object(c,{kind="joilette_bdd",role="bdd",pos=c.actor:GetPos()+Vector(0,0,58),
        model="models/props_lab/teleportplatform.mdl",scale=.7,solid=true,radius=95,hp=0,
        permanent=true,label="BATHROOM DEFENSE DEVICE — "..c.data.hits.."/3"})
end
function D:BeforeDamage(c,actor)
    if actor~=c.actor then return true end
    if c.data.hits<3 then
        if at(c)>=(c.data.nextNoEffect or 0) then
            c.data.nextNoEffect=at(c)+1;B:Announce(c,"NO EFFECT — BDD ACTIVE")
        end
        return false -- one gate for bullets, penetration, Magic, splash, status and physics
    end
    return true
end
function D:Pending(c,r,delay)
    if r.consumed or c.data.hits>=3 then return end
    r.generation=r.generation+1;r.state="pending";r.nextAt=at(c)+(delay or 1)
    r.actor=nil;r.object=nil;r.carrier=nil;r.binding=nil;r.projectile=nil
    B:Log(c,"cleaner_replaced",{slot=r.slot,generation=r.generation,hits=c.data.hits})
end
function D:DropCleaner(c,r,pos)
    if c.data.hits>=3 or r.consumed then return false end
    local safe=B:SafePoint(c,pos) or B:SafePoint(c,B:Center(c))
    if not safe then self:Pending(c,r);return false end
    local o=B:Object(c,{kind="toilet_cleaner",role="mandatory_item",pos=safe+Vector(0,0,18),
        model="models/props_junk/garbage_plasticbottle003a.mdl",scale=1.5,solid=false,hp=0,
        use=true,useLabel="E: TOILET CLEANER",label="TOILET CLEANER — LMB: THROW AT BDD",permanent=true})
    if not o then self:Pending(c,r);return false end
    r.state="item";r.object=o;r.actor=nil;r.carrier=nil;r.binding=nil
    o.cleaner=r;o.generation=r.generation
    return true
end
function D:SpawnCleanerNeil(c,r)
    if c.data.hits>=3 or r.consumed then return false end
    local pos=B:SafePoint(c,B:Point(c,r.slot*3))
    if not pos then r.nextAt=at(c)+1;return false end
    local e=B:SpawnActor(c,"neil","joilette_cleaner",pos,
        {manual=false,hpFraction=.45,name="CLEANER NEIL — CARRIES TOILET CLEANER"})
    if not IsValid(e) then r.nextAt=at(c)+1;return false end
    r.actor=e;r.state="neil";c.data.cleanerActors[e]=r
    e:SetNW2String("LOD_NeilCargo","TOILET CLEANER")
    e:SetColor(Color(115,245,175))
    B:Warn(c,"CLEANER NEIL — REQUIRED CLEANER",pos,2,62)
    return true
end
function D:FindCarried(c,p)
    for _,r in ipairs(c.data.cleaners) do
        if r.state=="carried" and r.carrier==p and not r.consumed and B:TargetLive(c,r.binding) then return r end
    end
end
function D:ObjectEvent(c,o,event,payload)
    if o==c.data.bdd and event=="hit" then self:BeforeDamage(c,c.actor);return end
    local r=o.cleaner
    if not r or not receipt(c,r,o.generation) or r.object~=o then return end
    if event=="use" then
        local p=payload
        if r.state~="item" or not B:Hero(c,p) or self:FindCarried(c,p) then return end
        -- Revoke the pickup before native removal dispatch can re-enter.
        r.object=nil;r.state="carried";r.carrier=p;r.binding=B:BindTarget(c,p);r.lastPos=copy(p:GetPos())
        B:RemoveObject(c,o,"picked up")
        p:SetNW2String("LOD_BossCarry","TOILET CLEANER — LMB: THROW AT BDD")
        B:Announce(c,"TOILET CLEANER — LMB: THROW AT BDD")
    elseif event=="destroy" or event=="expiry" then
        self:Pending(c,r)
    end
end
function D:ImpactCleaner(c,r,generation,o,tr)
    if not receipt(c,r,generation) or r.state~="projectile" or r.projectile~=o then return false end
    local bdd=c.data.bdd
    if tr.Entity~=c.actor and not (liveObject(bdd) and tr.Entity==bdd.ent) then
        self:Pending(c,r);return false
    end
    -- Atomic individual consumption precedes effects, phase changes and callbacks.
    r.consumed=true;r.state="consumed";r.projectile=nil
    c.data.hits=c.data.hits+1
    B:Log(c,"cleaner_hit",{slot=r.slot,generation=generation,hits=c.data.hits})
    c.actor:SetNW2Int("LOD_BDDHits",c.data.hits)
    if c.data.hits==3 then
        c.actor:SetNW2Bool("LOD_BDDActive",false)
        B:Announce(c,"THIRD FLUSH — BDD DESTROYED")
        B:Clear(c,"joilette_bdd");B:Clear(c,"toilet_cleaner");B:Clear(c,"cleaner_projectile")
        B:SetPhase(c,3);c.data.nextAttack=at(c)+2
        c.data.finalRush=2 -- finite final rush, shared add ceiling still applies
    else
        B:Announce(c,"BDD CRACKED — "..c.data.hits.."/3")
        B:SetPhase(c,2)
        if liveObject(bdd) then bdd.spec.label="BDD CRACKED — "..c.data.hits.."/3" end
    end
    return true
end
function D:PrimaryInput(c,p,key)
    if key~=IN_ATTACK or not B:Live(c) or not B:Hero(c,p) or c.data.hits>=3 then return false end
    local r=self:FindCarried(c,p)
    if not r then return false end
    local generation=r.generation
    local origin=p:GetShootPos();local velocity=p:GetAimVector()*650+Vector(0,0,70)
    local o=B:Projectile(c,{kind="cleaner_projectile",role="mandatory_item",
        model="models/props_junk/garbage_plasticbottle003a.mdl",pos=origin,velocity=velocity,
        gravity=300,radius=8,mass=1,hp=0,life=5,bounces=0,breakOnImpact=true,
        label="TOILET CLEANER",source=p,
        onImpact=function(owner,obj,tr) D:ImpactCleaner(owner,r,generation,obj,tr) end,
        onExpire=function(owner,obj)
            if receipt(owner,r,generation) and r.projectile==obj then D:Pending(owner,r) end
        end,
        onDestroy=function(owner,obj)
            if receipt(owner,r,generation) and r.projectile==obj then D:Pending(owner,r) end
        end})
    if not o then return false end -- budget failure retains the unique carried item
    r.state="projectile";r.projectile=o;r.carrier=nil;r.binding=nil
    p:SetNW2String("LOD_BossCarry","")
    return true
end
function D:ActorKilled(c,actor,role)
    local r=c.data.cleanerActors[actor]
    if r and r.actor==actor and r.state=="neil" and not r.consumed and c.data.hits<3 then
        local pos=copy(actor:GetPos());local generation=r.generation
        r.state="dropping";r.actor=nil;c.data.cleanerActors[actor]=nil
        B:Later(c,0,"cleaner_drop:"..r.slot,function(owner)
            if receipt(owner,r,generation) and r.state=="dropping" then D:DropCleaner(owner,r,pos) end
        end)
    end
    if c.data.bombActors[actor] then
        c.data.bombActors[actor]=nil
        local pos=copy(actor:GetPos())
        B:Later(c,0,"bomb_neil:"..tostring(actor:EntIndex()),function(owner)
            D:Bomb(owner,pos,"BOMB NEIL — DROPPED BOMB",1.5)
        end)
    end
    return false -- ordinary Neil XP/loot/native death is never replaced
end
function D:ServiceCleaners(c,t)
    if c.data.hits>=3 then return end
    for _,r in ipairs(c.data.cleaners) do if not r.consumed then
        if r.state=="pending" and t>=(r.nextAt or 0) then self:SpawnCleanerNeil(c,r)
        elseif r.state=="neil" and not living(r.actor) then
            c.data.cleanerActors[r.actor]=nil;self:Pending(c,r)
        elseif r.state=="item" and (not liveObject(r.object) or not B:Floor(c,r.object.pos)) then
            if liveObject(r.object) then B:RemoveObject(c,r.object,"lost cleaner") end
            self:Pending(c,r)
        elseif r.state=="carried" then
            if not B:TargetLive(c,r.binding) then
                local old=r.carrier
                if IsValid(old) then old:SetNW2String("LOD_BossCarry","") end
                self:DropCleaner(c,r,r.lastPos or B:Center(c))
            else r.lastPos=copy(r.carrier:GetPos()) end
        elseif r.state=="projectile" and not liveObject(r.projectile) then self:Pending(c,r)
        elseif r.state=="dropping" then
            -- Pause cancellation cannot strand an already sealed Neil drop.
            self:DropCleaner(c,r,B:Point(c,r.slot*3))
        end
    end end
end
function D:Bomb(c,pos,label,warning)
    local landing=B:Floor(c,pos)
    if not landing then return end
    B:Warn(c,label,landing,warning or 1.3,100)
    B:Later(c,warning or 1.3,"flush_bomb:"..tostring(c.data.attackSerial)..":"..label,function(owner)
        B:Projectile(owner,{kind="flush_bomb",model="models/Items/grenadeAmmo.mdl",
            pos=landing+Vector(0,0,170),velocity=Vector(0,0,-120),gravity=400,
            radius=10,life=3,fuse=1.3,explodeRadius=100,hp=8,mass=4,bounces=0,
            label=label,damage={kind="blast",dice={2,6,0},reference=7},source=owner.actor})
    end)
end
function D:SpawnNeil(c,bomb)
    if B:CountActors(c,"joilette_neil")+B:CountActors(c,"joilette_cleaner")>=7 then return false end
    local pos=B:SafePoint(c,B:Point(c,2+c.data.attackSerial%5))
    if not pos then return false end
    local e=B:SpawnActor(c,"neil","joilette_neil",pos,{manual=false,hpFraction=.45,
        name=bomb and "BOMB NEIL" or "NEIL"})
    if not IsValid(e) then return false end
    if bomb then c.data.bombActors[e]=true;e:SetColor(Color(255,155,85));e:SetNW2String("LOD_NeilCargo","BOMB") end
    B:Warn(c,bomb and "FLUSH — BOMB NEIL" or "FLUSH — NEIL",pos,1,48)
    return true
end
function D:Attack(c,targets)
    if #targets==0 then return end
    local d=c.data;d.attackSerial=d.attackSerial+1
    local p=targets[(d.attackSerial-1)%#targets+1]
    local pos=copy(p:GetPos());local n=(d.attackSerial-1)%4
    if n==0 then
        self:Bomb(c,pos,c.phase==3 and "RAPID FLUSH" or "FLUSH BOMB",c.phase==3 and 1 or 1.5)
        if c.phase>=2 then
            local other=B:Point(c,d.attackSerial+2)
            self:Bomb(c,other,c.phase==2 and "DOUBLE FLUSH" or "RAPID FLUSH II",1.9)
        end
    elseif n==1 then
        B:Zone(c,{kind="lid_slam",label=c.phase==3 and "LID CHATTER" or "LID SLAM",pos=pos,
            radius=95,delay=1,life=c.phase==3 and 1.1 or .2,interval=.55,
            damage={kind="melee",dice={2,5,0},reference=6,push=95}})
    elseif n==2 and c.phase==2 then
        B:Announce(c,"CLOGGED BOMB — DELAYED EJECTION")
        self:Bomb(c,pos,"CLOGGED BOMB",2.4)
        B:Zone(c,{kind="overflow",label="OVERFLOW",pos=B:Point(c,d.attackSerial),radius=115,
            delay=1.5,life=5,interval=1,traction=.78,push=25,safeGap=200,
            damage={kind="melee",dice={1,3,0},reference=2}})
    elseif n==2 and c.phase==3 then
        B:Charge(c,c.actor,pos,{label="TOILET CHARGE",warning=1.3,speed=320,width=80,
            damage={kind="melee",dice={2,6,0},reference=7,push=110},recovery=2})
    else
        local origin=c.actor:GetPos()
        B:Zone(c,{kind="paper_lash",label="TOILET PAPER LASH",pos=origin,finish=pos,
            shape="lane",width=45,delay=1.2,life=.2,interval=1,
            damage={kind="melee",dice={1,4,0},reference=2.5,push=100},safeGap=160})
    end
end
function D:Think(c,t,dt,targets)
    self:EnsureBDD(c)
    self:ServiceCleaners(c,t)
    local d=c.data
    if t>=(d.nextAttack or 0) then d.nextAttack=t+(c.phase==3 and 2.6 or 4);self:Attack(c,targets) end
    if t>=(d.nextNeil or 0) then
        d.nextNeil=t+(c.phase==3 and 5 or 8)
        local bomb=c.phase==2 and d.attackSerial%2==0
        self:SpawnNeil(c,bomb)
        if c.phase==3 and (d.finalRush or 0)>0 and self:SpawnNeil(c,false) then d.finalRush=d.finalRush-1 end
    end
    if liveObject(d.bdd) then d.bdd.pos=c.actor:GetPos()+Vector(0,0,58) end
end
function D:Pause(c)
    -- Carry progress persists; body-local prompts are revoked until a new valid life.
    for _,r in ipairs(c.data.cleaners or {}) do
        if r.state=="carried" and not B:TargetLive(c,r.binding) and IsValid(r.carrier) then
            r.carrier:SetNW2String("LOD_BossCarry","")
        end
    end
end
function D:Retire(c)
    for _,r in ipairs(c.data.cleaners or {}) do
        if IsValid(r.carrier) then r.carrier:SetNW2String("LOD_BossCarry","") end
        r.carrier=nil;r.binding=nil;r.state="retired"
    end
end
function D:KeyPosition(c)
    -- The authored bowl drop is presented locally, then clamped to a reachable floor.
    local pos=IsValid(c.actor) and c.actor:GetPos() or c.savedPos or B:Center(c)
    return B:SafePoint(c,pos) or B:Center(c)
end
function D:Defeat(c)
    B:Announce(c,"BATHROOM SECURED")
    B:Object(c,{kind="joilette_final_neil",role="cosmetic",pos=self:KeyPosition(c)+Vector(0,0,36),
        model="models/kleiner.mdl",scale=.16,life=.85,solid=false,hp=0,velocity=Vector(0,0,140),gravity=600,breakOnImpact=false,
        label="one last tiny Neil",cosmetic=true})
end
function D:Snapshot(c)
    if c.data.hits>=3 then return "BDD DESTROYED — EXPOSED" end
    return "TOILET CLEANER "..tostring(c.data.hits or 0).."/3 — LMB: THROW AT BDD"
end
B:Register("joilette",D)
