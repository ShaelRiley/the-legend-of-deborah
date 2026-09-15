-- Complete ordinary roster. Native models only; attacks share RPG authorities.
LOD.EnemyRoster = LOD.EnemyRoster or {}
local E=LOD.EnemyRoster
local EC=LOD.Config.Encounter
E.Definitions={
    nodule={name="Nodule",model="models/barnacle.mdl",baseHP=30,speed=0,damage=3.5,range=384,warning=0,recovery=1,threat=2.5,activity=ACT_IDLE,kind="gas",stationary=true,dice={1,4,1}},
    climber={name="Climber",model="models/zombie/fast.mdl",baseHP=14,speed=205,damage=3.5,range=225,warning=.4,recovery=.75,threat=1.8,activity=ACT_RUN,kind="climber",color=Color(255,35,180),dice={1,4,1}},
    flamer={name="Flamer",model="models/combine_soldier.mdl",baseHP=40,speed=140,damage=13.5,range=280,warning=1,recovery=2.5,threat=3,activity=ACT_RUN_AIM_RIFLE or ACT_RUN,kind="flame",color=Color(240,65,55),dice={3,6,3}},
    bigcrab={name="Big Crab",model="models/headcrabclassic.mdl",baseHP=75,speed=105,damage=13.5,range=280,warning=1,recovery=2.5,threat=4,activity=ACT_RUN,kind="flame",dice={3,6,3}},
    sentry={name="Sentry",model="models/combine_turrets/floor_turret.mdl",baseHP=55,speed=0,damage=9,range=1050,warning=.75,recovery=.7,threat=3.5,activity=ACT_IDLE,kind="bullet",stationary=true,dice={2,6,2}},
    razor={name="Razor",model="models/manhack.mdl",baseHP=22,speed=185,damage=11,range=560,warning=.65,recovery=1.8,threat=2.8,activity=ACT_FLY or ACT_RUN,kind="dive",dice={2,6,4}},
    arccaster={name="Arc Caster",model="models/vortigaunt.mdl",baseHP=40,speed=100,damage=13.5,range=1000,warning=1.25,recovery=2.8,threat=3.5,activity=ACT_WALK,kind="arc",dice={3,6,3}},
    lurker={name="Lurker",model="models/barnacle.mdl",baseHP=24,speed=0,damage=5.5,range=1000,warning=1,recovery=3,threat=2.5,activity=ACT_IDLE,kind="venom",stationary=true,dice={1,4,3}},
    beamsweeper={name="Beam Sweeper",model="models/stalker.mdl",baseHP=50,speed=0,damage=10,range=640,warning=1.4,recovery=3,threat=3.8,activity=ACT_IDLE,kind="beam",stationary=true,dice={2,6,3}}
}
for id,d in pairs(E.Definitions) do
    EC.Archetypes[id]={class="lod_hostile",name=d.name,model=d.model,baseHP=d.baseHP,speed=d.speed,
        meleeDamage=0,meleeRange=0,meleeCooldown=99,burstDamage=d.damage,fireRange=d.range,
        burstTelegraph=d.warning,burstCooldown=d.recovery,activity=d.activity,threat=d.threat}
    LOD.CombatRolls.HostileDamageProfiles[id]={label=string.upper(d.name),source=d.kind,
        count=d.dice[1],sides=d.dice[2],bonus=d.dice[3],reference=d.damage}
end
E.Active=E.Active or setmetatable({}, {__mode="k"})
E.Projectiles=E.Projectiles or {}
local N=LOD.MazeNavigator
local function key(c) return c and LOD.MazeGenerator.CellKey(c.x,c.y,c.z) end
E.Key=key
local function state() return LOD.RunManager and LOD.RunManager.State end
function E:Target(p) return LOD.FactionManager:IsValidPlayerTarget(p) end
function E:Safe(graph,c)
    local tag=graph and c and (graph.CellTags or {})[key(c)]
    return not c or (tag and (tag.safe or tag.role=="boss" or tag.role=="resupply"))
end
function E:Visible(e,p,origin)
    local tr=util.TraceLine({start=origin or e:WorldSpaceCenter(),endpos=p:WorldSpaceCenter(),mask=MASK_SHOT,
        filter=function(v) return v~=e and not v.LODHostile end})
    return not tr.Hit or tr.Entity==p
end
function E:Origin(e)
    if e.LODArchetypeId=="lurker" then return e:GetPos()+Vector(0,0,-22) end
    return e:GetPos()+Vector(0,0,e.LODArchetypeId=="bigcrab" and 32 or 48)
end
function E:Prepare(e)
    if e.LODRosterReady then return end
    e.LODRosterReady=true;self.Active[e]=true;e:SetNW2Bool("LOD_RosterAlive",true)
    local d=self.Definitions[e.LODArchetypeId]
    if d.color then e:SetColor(d.color) end
    if d.stationary then e.LODRosterAnchor=e:GetPos();e.LODRosterYaw=e:GetAngles().y end
end
function E:Cancel(e)
    e.LODRosterAttack=nil;e:SetNW2Int("LOD_RosterAttack",0)
end
function E:Interrupt(e)
    local a=e.LODRosterAttack
    -- A released beam is solved by movement/cover; gunfire only cancels charge.
    if a and not (a.released and a.kind=="beam") then self:Cancel(e) end
    if LOD.Climber then LOD.Climber:Interrupt(e) end
end
function E:Damage(e,p,event,kind)
    if not IsValid(e) or e.LODDead or not self:Target(p) then return end
    local rolls=LOD.CombatRolls
    local profile=rolls.HostileDamageProfiles[e.LODArchetypeId]
    event.roll=event.roll or rolls:RollHostileAttack(e,profile,e.LODConfig.burstDamage)
    local c={};for k,v in pairs(event.roll) do c[k]=v end
    local magic=kind=="arc" or kind=="beam"
    local rider=(kind=="flame" and "immolated") or (kind=="venom" and "poisoned") or nil
    event.riders=event.riders or setmetatable({}, {__mode="k"})
    local tags={physical=not magic,magic=magic,melee=kind=="dive" or kind=="climber",
        element=kind=="flame" and "fire" or (magic and "raw" or nil),
        attackEvent=c.attackEvent,damageContract=c,authoredScale=c.scale,
        riderStatusId=rider,riderConsumedTargets=event.riders}
    if rider then tags.riderDC=LOD.RPGStatusElements:ConditionDC(e,rider=="immolated" and "dex" or "con") end
    local amount=rolls:ResolveActorDamage(c,e,p,tags)
    local info=LOD.NewDamageInfo();info:SetAttacker(e);info:SetInflictor(e);info:SetDamage(amount)
    info:SetDamageType(magic and DMG_ENERGYBEAM or (kind=="flame" and DMG_BURN or ((kind=="venom" or kind=="gas") and DMG_POISON or DMG_SLASH)))
    info:SetDamagePosition(p:WorldSpaceCenter());tags.actorDamageResolved=true
    LOD.RPGStatusElements:AttachDamageContext(info,tags)
    rolls:QueueDamageReport(info,function(final) c.final=final;rolls:_Send(p,1,rolls:_HostileRollText(c,e,p)) end)
    p:TakeDamageInfo(info)
end
local sounds={flame="ambient/fire/ignite.wav",arc="npc/vort/attack_charge.wav",venom="npc/barnacle/barnacle_tongue_pull1.wav",
    beam="npc/stalker/laser_burn.wav",bullet="npc/turret_floor/active.wav",dive="npc/manhack/mh_engine_start1.wav"}
function E:Begin(e,p,now)
    local d=self.Definitions[e.LODArchetypeId];local cfg=e.LODConfig
    local origin=self:Origin(e);local aim=p:WorldSpaceCenter()
    local a={kind=d.kind,target=p,origin=origin,aim=aim,ready=now+cfg.burstTelegraph,
        seed=state().LevelSeed,run=state(),hit={},event={},started=now,direction=(aim-origin):GetNormalized()}
    if d.kind=="arc" then a.aim=Vector(p:GetPos().x,p:GetPos().y,p:GetPos().z+3) end
    if d.kind=="beam" then
        a.origin=e:GetPos()+Vector(0,0,56);a.yaw=e.LODRosterYaw or e:GetAngles().y;a.previous=-45
        a.aim=a.origin+Angle(0,a.yaw,0):Forward()*cfg.fireRange
    end
    e.LODRosterAttack=a
    e:SetNW2Int("LOD_RosterAttack",1);e:SetNW2Vector("LOD_RosterOrigin",a.origin)
    e:SetNW2Vector("LOD_RosterAim",a.aim);e:SetNW2Float("LOD_RosterReady",a.ready)
    e:SetNW2Float("LOD_RosterRange",cfg.fireRange)
    e:EmitSound(sounds[d.kind] or "npc/fast_zombie/leap1.wav",72,100,.75)
    e:_SetActivity(ACT_RANGE_ATTACK1 or ACT_IDLE,true)
end
function E:Finish(e,now)
    self:Cancel(e)
    local rate=LOD.RPGAbilityRules and LOD.RPGAbilityRules:RateOfFireMultiplier(e) or 1
    e.LODNextAttack=now+e.LODConfig.burstCooldown/math.max(.1,rate)
    e:_SetActivity(ACT_IDLE)
end
function E:Release(e,a,now)
    a.released=true;a.finish=now+(a.kind=="beam" and 1.2 or (a.kind=="flame" and .8 or (a.kind=="dive" and .65 or .15)))
    a.last=now;e:SetNW2Int("LOD_RosterAttack",2);e:SetNW2Float("LOD_RosterRelease",now)
    e:SetNW2Float("LOD_RosterFinish",a.finish)
    e:EmitSound(a.kind=="flame" and "ambient/fire/mtov_flame2.wav" or (a.kind=="venom" and "npc/barnacle/barnacle_digesting1.wav" or "ambient/energy/weld2.wav"),74,100,.7)
    if a.kind=="bullet" or a.kind=="venom" then
        if #self.Projectiles<64 then
            self.Projectiles[#self.Projectiles+1]={owner=e,pos=a.origin,velocity=a.direction*(a.kind=="bullet" and 950 or 380),
                expires=now+e.LODConfig.fireRange/(a.kind=="bullet" and 950 or 380),seed=a.seed,run=a.run,kind=a.kind,event=a.event}
        end
    end
end
function E:Attack(e,a,now)
    if not a.released then
        if not self:Target(a.target) or not self:Visible(e,a.target,a.origin)
            or not LOD.RPGStatusElements:CanInitiateAttack(e) then self:Finish(e,now);return end
        if now<a.ready then return end
        self:Release(e,a,now)
    end
    local kind=a.kind;local range=e.LODConfig.fireRange
    if kind=="dive" then
        local dt=math.Clamp(now-a.last,0,.05);a.last=now
        local origin=e:GetPos();local dir=Vector(a.direction.x,a.direction.y,0):GetNormalized()
        local goal=origin+dir*780*dt
        if not self:LegalStep(e,origin,goal) then self:Finish(e,now);return end
        local tr=util.TraceHull({start=origin,endpos=goal,mins=Vector(-16,-16,2),maxs=Vector(16,16,64),mask=MASK_NPCSOLID,
            filter=function(v) return v~=e and not v.LODHostile and not v:IsPlayer() end})
        if tr.Hit or tr.StartSolid then self:Finish(e,now);return end
        e:SetPos(goal);e.LODMotionVelocity=dir*780;e.LODMotionSpeed=780
        for _,p in ipairs(player.GetAll()) do
            if self:Target(p) and not a.hit[p] and util.DistanceToLine(origin,goal,p:GetPos())<=48 and self:Visible(e,p) then
                a.hit[p]=true;self:Damage(e,p,a.event,kind)
            end
        end
    elseif kind=="flame" or kind=="arc" or kind=="beam" then
        local current=kind=="beam" and math.Clamp((now-(a.finish-1.2))/1.2,0,1)*90-45 or 0
        for _,p in ipairs(player.GetAll()) do
            if self:Target(p) and not a.hit[p] then
                local pos=p:WorldSpaceCenter();local delta=pos-a.origin;local inside=false
                if kind=="flame" then inside=delta:Length()<=range and delta:GetNormalized():Dot(a.direction)>=math.cos(math.rad(28))
                elseif kind=="arc" then inside=(pos-a.aim):Length2D()<=112 and pos.z>=a.aim.z-3 and pos.z<=a.aim.z+192
                else
                    local yaw=math.AngleDifference(delta:Angle().y,a.yaw)
                    local lo,hi=p:WorldSpaceAABB()
                    inside=delta:Length2D()<=range and lo.z<=a.origin.z+3 and hi.z>=a.origin.z-3
                        and yaw>=a.previous-1 and yaw<=current+1
                end
                local source=kind=="arc" and a.aim+Vector(0,0,24) or a.origin
                if inside and self:Visible(e,p,source) then a.hit[p]=true;self:Damage(e,p,a.event,kind) end
            end
        end
        if kind=="beam" then a.previous=current end
    end
    if now>=a.finish then self:Finish(e,now) end
end
function E:LegalStep(e,from,to)
    local s=state();local graph=s and s.Graph
    local a=graph and N:WorldToCell(graph,from);local b=graph and N:WorldToCell(graph,to)
    if self:Safe(graph,a) or self:Safe(graph,b) or a.z~=b.z then return false end
    return key(a)==key(b) or (a.neighbors[key(b)] and N:CanTraverse(graph,key(a),key(b)))
end
function E:Tick(e)
    local d=self.Definitions[e.LODArchetypeId];if not d then return false end
    local s=state();local motion=LOD.HostileMotionV2;local now=CurTime()
    if e.LODDead or not e.LODActivated or not s or not s.BuildReady or s.Failed or s.LevelCleared or s.SimulationFrozen then
        self:Cancel(e);if e.LODClimberVictim and LOD.Climber then LOD.Climber:Detach(e) end;motion:Stop(e);return true
    end
    self:Prepare(e)
    if d.kind=="climber" then return LOD.Climber:Tick(e,s,now) end
    if d.kind=="gas" then
        motion:Stop(e);e:_SetActivity(ACT_IDLE)
        if now>=(e.LODNextGas or 0) then
            e.LODNextGas=now+1
            local cell=N:WorldToCell(s.Graph,e:GetPos());local event={}
            for _,p in ipairs(player.GetAll()) do
                if self:Target(p) and key(N:WorldToCell(s.Graph,p:GetPos()))==key(cell) then self:Damage(e,p,event,"gas") end
            end
        end
        return true
    end
    local a=e.LODRosterAttack
    if a then motion:Stop(e);return true end -- shared service owns attacks, even committed sweeps during stun
    if motion:HoldHitStun(e,now) then return true end
    local statuses=LOD.RPGStatusElements
    if d.stationary then
        motion:Stop(e)
        if not statuses:CanInitiateAttack(e) or statuses:Has(e,"morale_flee") then return true end
    elseif statuses:HandleAIFlee(e,s.Graph,motion) then return true end
    e:_RefreshTarget(s.Graph);local p=e.LODTarget
    local can=self:Target(p) and statuses:CanInitiateAttack(e)
        and self:Origin(e):DistToSqr(p:WorldSpaceCenter())<=e.LODConfig.fireRange^2 and self:Visible(e,p,self:Origin(e))
    if can and (d.kind=="bullet" or d.kind=="beam") then
        local direction=(p:GetPos()-e:GetPos()):GetNormalized()
        can=direction:Dot(Angle(0,e.LODRosterYaw or 0,0):Forward())>=math.cos(math.rad(d.kind=="beam" and 45 or 55))
    end
    if can then
        motion:Stop(e)
        if not d.stationary then motion:FaceToward(e,p:GetPos()) end
        if now>=(e.LODNextAttack or 0) then self:Begin(e,p,now) end
    elseif not d.stationary then
        e:_RefreshRoute(s.Graph);local wp=e:_AdvanceWaypoint()
        if wp then motion:MoveToward(e,wp) else motion:Stop(e);e:_SetActivity(ACT_IDLE) end
    end
    return true
end
-- One bounded projectile/attack service, independent of outer AI stun wrappers.
hook.Add("Think","LOD_EnemyRosterAttacks",function()
    local s=state();local now=CurTime()
    if now<(E.NextService or 0) then return end
    local dt=math.Clamp(now-(E.LastService or now),0,.05);E.LastService=now;E.NextService=now+.025
    local active=s and s.BuildReady and not s.Failed and not s.LevelCleared and not s.SimulationFrozen
    for e in pairs(E.Active) do
        if not IsValid(e) or e.LODDead then E.Active[e]=nil
        elseif not active then E:Cancel(e)
        elseif e.LODRosterAttack then
            local a=e.LODRosterAttack
            if a.seed~=s.LevelSeed or a.run~=s then E:Cancel(e)
            elseif not (a.released and a.kind=="beam") and (now<(e.LODHitStunUntil or 0) or not LOD.RPGStatusElements:CanInitiateAttack(e)) then E:Finish(e,now)
            else E:Attack(e,a,now) end
        end
    end
    local kept={}
    for _,q in ipairs(E.Projectiles) do
        if active and q.seed==s.LevelSeed and q.run==s and IsValid(q.owner) and not q.owner.LODDead and now<q.expires then
            local finish=q.pos+q.velocity*dt
            local radius=q.kind=="venom" and 7 or 2
            local tr=util.TraceHull({start=q.pos,endpos=finish,mins=Vector(-radius,-radius,-radius),maxs=Vector(radius,radius,radius),mask=MASK_SHOT,
                filter=function(v) return v~=q.owner and not v.LODHostile end})
            if tr.Hit then
                if E:Target(tr.Entity) then E:Damage(q.owner,tr.Entity,q.event,q.kind) end
                local fx=EffectData();fx:SetOrigin(tr.HitPos);util.Effect(q.kind=="venom" and "cball_explode" or "Sparks",fx,true,true)
            else q.pos=finish;kept[#kept+1]=q end
        end
    end
    E.Projectiles=kept
    if active and (#kept>0 or E.HadProjectiles) and now>=(E.NextSync or 0) then
        E.HadProjectiles=#kept>0
        E.NextSync=now+.1;net.Start("LOD_RosterProjectiles");net.WriteUInt(#kept,7)
        for _,q in ipairs(kept) do net.WriteVector(q.pos);net.WriteVector(q.velocity);net.WriteBool(q.kind=="venom") end
        net.Broadcast()
    end
end)
util.AddNetworkString("LOD_RosterProjectiles")

-- Register spatial pain/death/step cues in the existing audio authority.
if LOD.CombatAudio and LOD.CombatAudio.RegisterHostileProfile then
    local banks={
        climber={"npc/fast_zombie/fz_pain1.wav","npc/fast_zombie/fz_die1.wav","npc/fast_zombie/foot1.wav"},
        flamer={"npc/combine_soldier/pain2.wav","npc/combine_soldier/die2.wav","npc/combine_soldier/gear2.wav"},
        bigcrab={"npc/headcrab/pain1.wav","npc/headcrab/die1.wav","npc/headcrab/alert1.wav"},
        sentry={"npc/turret_floor/ping.wav","npc/turret_floor/die.wav"},
        razor={"npc/manhack/grind1.wav","npc/manhack/gib.wav","npc/manhack/mh_engine_start1.wav"},
        arccaster={"npc/vort/vort_pain1.wav","npc/vort/vort_die1.wav","npc/vort/vort_foot1.wav"},
        nodule={"npc/barnacle/barnacle_tongue_pull1.wav","npc/barnacle/barnacle_die1.wav"},
        lurker={"npc/barnacle/barnacle_tongue_pull1.wav","npc/barnacle/barnacle_die1.wav"},
        beamsweeper={"npc/stalker/stalker_pain1.wav","npc/stalker/stalker_die1.wav"}
    }
    for id,b in pairs(banks) do LOD.CombatAudio:RegisterHostileProfile(id,{pain={b[1]},death={b[2]},
        footsteps=b[3] and {b[3]} or {},footDistance=60,footInterval=.5,footVolume=.5,footPitch=100,activation={b[1]}}) end
end
function E:CombatBounds(e)
    local pos=e:GetPos();local size=math.Clamp(e:GetNW2Float("LOD_SizeScale",1),.33,1.33)
    local id=e.LODArchetypeId
    if id=="climber" then return pos+Vector(-14,-14,-8),pos+Vector(14,14,38*size) end
    if id=="lurker" then return pos+Vector(-18,-18,-64*size),pos+Vector(18,18,0) end
    if id=="bigcrab" then local scale=2.4+size-.33;return pos+Vector(-18*scale,-18*scale,0),pos+Vector(18*scale,18*scale,24*scale) end
    if id=="razor" then return pos+Vector(-14,-14,42),pos+Vector(14,14,68) end
end
hook.Add("ShouldCollide","LOD_ClimberLatchNoPush",function(a,b)
    if IsValid(a) and IsValid(b) and (a.LODClimberVictim==b or b.LODClimberVictim==a
        or (a.LODArchetypeId=="lurker" and b:IsPlayer()) or (b.LODArchetypeId=="lurker" and a:IsPlayer())) then return false end
end)

hook.Add("OnNPCKilled","LOD_RosterDeath",function(e)
    if IsValid(e) and E.Definitions[e.LODArchetypeId] then
        E:Cancel(e);e:SetNW2Bool("LOD_RosterAlive",false)
        if e.LODClimberVictim then LOD.Climber:Detach(e) end
    end
end)
