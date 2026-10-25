-- Gordon's encounter owns only phase scheduling and arena state. Shared RPG
-- rolls, damage defenses, Motion V2 and the ordinary death loop stay authoritative.
LOD.Warden = LOD.Warden or {}
local W=LOD.Warden
local P,N,R=LOD.ProgressionDirector,LOD.MazeNavigator,LOD.RunManager
local C={invisible=3,warning=0.65,visible=2,shotGap=0.22,shotSpeed=460,shotLife=8,
    homing=0.45,bombGap=1.6,bombFuse=3,bombRadius=180,meleeGap=0.85,meleeWarning=0.3,
    meleeRange=95,maxHazards=16,syncGap=0.2,followup=1.2,exposureCap=4,departure=0.45,arrival=0.45,
    tauntDuration=0.8,tauntCooldown=6,contextHorizon=4,maxCues=10,
    tellLease=0.4,winkPeriod=2.4,winkDuration=0.35,fakeRecoil=0.35}
W.Config=C
LOD.Config.Encounter.Archetypes.warden={class="lod_hostile",name="Gordon the Warden",
    model="models/Humans/Group01/male_02.mdl",baseHP=1000,speed=240,meleeDamage=8,meleeCooldown=C.meleeGap,
    meleeRange=C.meleeRange,threat=10,activity=ACT_RUN}
W.Profiles={orb={label="WARDEN ORB",source="magic",count=2,sides=6,bonus=2,reference=9},
    bomb={label="WARDEN BOMB",source="blast",count=3,sides=6,bonus=2,reference=12.5},
    crowbar={label="WARDEN CROWBAR",source="melee",count=2,sides=4,bonus=3,reference=8}}
-- Only citizens shipped with Garry's Mod. A separate seeded stream keeps
-- appearance selection independent of combat rolls and stable for this dungeon.
function W:CitizenModel(seed)
    local rng=LOD.RNG.New(LOD.Seeds.Derive(seed or 1,"warden-citizen-model"))
    return string.format("models/Humans/Group01/male_%02d.mdl",rng:Int(1,9))
end
local baseReserve=LOD.WanderingDirector.GetDeficitReservation
function W:CloneCount(level) return math.min(4,math.max(0,math.floor((tonumber(level) or 1)/4))) end
function LOD.WanderingDirector:GetDeficitReservation(...)
    local w=R.State and R.State.Warden
    local clones=W:CloneCount(R.State and R.State.Level)
    local pending=(w and w.started) and math.max(0,clones-#(w.clones or {})) or 1+clones
    if w and w.dead then
        local h=R.State.Hector
        pending=(R.State.Level==20 and (not h or h.stage~=3 and not IsValid(h.actor))) and 1 or 0
    end
    return baseReserve(self,...) + pending + (LOD.WardenTurrets and LOD.WardenTurrets:Reservation(R.State) or 0)
end
local function key(c) return c and LOD.MazeGenerator.CellKey(c.x,c.y,c.z) end
local function alive(e) return IsValid(e) and not e.LODDead and e:Health()>0 end
local function hero(p) return IsValid(p) and p:IsPlayer() and p:Alive() and R:IsActivePlayer(p) end
local function log(event,data) if LOD.RPGTestLog then LOD.RPGTestLog:Write(event,data) end end
function W:State()
    local s=R.State;local w=s and s.Warden
    if not s or not w or w.seed~=s.LevelSeed or not s.Graph or not s.Graph.Progression then return end
    return s,w,s.Graph.Progression.Warden
end
function W:Actors(w)
    local out={w}
    for _,clone in ipairs(w.clones or {}) do if not clone.dead then out[#out+1]=clone end end
    return out
end
function W:AllHazards(w)
    local out={}
    for _,actorState in ipairs(self:Actors(w)) do
        for _,q in ipairs(actorState.hazards) do out[#out+1]=q end
    end
    return out
end
function W:SpawnClones(s,w,a)
    w.clones=w.clones or {};w.cloneStates=w.cloneStates or {}
    local offsets={{1,-1},{1,1},{0,-1},{0,1}}
    for index=#w.clones+1,self:CloneCount(s.Level) do
        if LOD.EncounterDirector:GetActiveCount()+baseReserve(LOD.WanderingDirector,s.Graph)+1>LOD.Config.Encounter.ActiveHostileCeiling then return false end
        local offset=offsets[index]
        local cell=s.Graph.Cells[key({x=a.center.x+offset[1],y=a.center.y+offset[2],z=a.center.z})]
        if not cell then return false end
        local clone=ents.Create("lod_hostile");if not IsValid(clone) then return false end
        clone.LODArchetypeId="warden";clone.LODEncounterId="warden_clone";clone.LODEncounterOrdinal=910001+index
        clone.LODWardenClone=index;clone.LODWardenParty=w.actor.LODWardenParty;clone.LODWardenOwner=w
        clone.LODHomeCellKey=key(cell);clone.LODActivated=true
        clone:SetPos(N:CellCenter(cell));clone:Spawn()
        if not IsValid(clone) then return false end
        LOD.EnemyVariance:Apply(clone);LOD.HostileMotionV2:SnapSpawn(clone)
        local hp=math.max(1,math.floor(w.actor:GetMaxHealth()/3))
        clone:SetMaxHealth(hp);clone:SetHealth(hp)
        if clone.LODProgressionState then clone.LODProgressionState.derivedStats.maxHP=hp end
        clone:SetNW2String("LOD_MonsterName","Gordon the Warden")
        clone:SetNW2Int("LOD_WardenPhase",1)
        clone:SetNW2Bool("LOD_WardenHidden",true);clone:DrawShadow(false)
        clone.LODBossLastDamage=CurTime()
        local state={actor=clone,phase=1,hazards={},cloneIndex=index,hiddenUntil=CurTime()+C.invisible+index*.2}
        state.visualLife=self:StampVisualLife(clone);state.tellEpoch=CurTime()
        w.clones[index]=state;w.cloneStates[clone]=state
        LOD.EncounterDirector.Entities[#LOD.EncounterDirector.Entities+1]=clone
    end
    return true
end
function W:InCell(p,c) return key(N:WorldToCell(R.State.Graph,p:GetPos()))==key(c) end
function W:Protected(p)
    local s,w,a=self:State()
    return s and (not w.dead or s.Level==20 and not (LOD.Hector and LOD.Hector:RescueAllowed(s))) and hero(p) and self:InCell(p,a.entry)
end
function W:Targets()
    local s,w,a=self:State();local out={}
    if not a then return out end
    for _,p in ipairs(player.GetAll()) do
        if hero(p) and a.court[key(N:WorldToCell(s.Graph,p:GetPos()))] then out[#out+1]=p end
    end
    return out
end
function W:Resupply(p)
    local s,w=self:State();if not s or not hero(p) then return end
    local ps=R:GetPlayerState(p);local id=ps and ps.identity
    if not id or w.resupply[id] then return end
    -- One identity receipt for this dungeon, not one grant per incarnation.
    w.resupply[id]=true
    p:SetHealth(math.min(p:GetMaxHealth(),p:Health()+25))
    LOD.DiceAmmo:GrantWardenResupply(p)
    LOD.Equipment:Grant(p,"healing_potion",1,"warden_resupply")
    p:ChatPrint("Warden resupply: +25 Health, up to 30 reserve rounds per owned ammo type, one Healing Potion if inventory space permits. Once per Hero per dungeon.")
end
function W:Prepare()
    local s=R.State;local a=s and s.Graph and s.Graph.Progression.Warden
    if not a or not s.BuildReady or s.Failed or s.LevelCleared or not s.GatesOpen[4] then return false end
    if s.Warden then return true end
    s.Warden={seed=s.LevelSeed,state=s,graph=s.Graph,epoch=s.CampaignEpoch,campaignSeed=s.CampaignSeed,
        runId=s.RunId,level=s.Level,phase=1,hazards={},resupply={},nextHazard=0}
    return true
end
function W:Join(p,gate)
    local s,w,a=self:State()
    if not s or not hero(p) or gate~=a.lock.entity or not IsValid(gate) then return false end
    if p:GetPos():DistToSqr(gate:GetPos())>(LOD.Config.Maze.CellSize*0.7)^2 then return false end
    if w.dead and (s.Level~=20 or LOD.Hector and LOD.Hector:RescueAllowed(s)) then gate:OpenGate();return true end
    p:SetPos(N:CellCenter(a.entry)+Vector(0,0,12));self:Resupply(p);return true
end
function W:Commit()
    local s,w,a=self:State();if not s or w.started or w.dead then return false end
    local bossCount=1+self:CloneCount(s.Level)
    local reserve=LOD.WanderingDirector:GetDeficitReservation(s.Graph)-bossCount
    if LOD.EncounterDirector:GetActiveCount()+reserve+bossCount>LOD.Config.Encounter.ActiveHostileCeiling then return false end
    local e=ents.Create("lod_hostile");if not IsValid(e) then return false end
    local party=0;for _,p in ipairs(player.GetAll()) do if R:IsActivePlayer(p) then party=party+1 end end
    e.LODWardenParty=math.Clamp(party,1,4)
    e.LODArchetypeId="warden";e.LODEncounterId="warden";e.LODEncounterOrdinal=910001
    e.LODWardenOwner=w;e.LODHectorGordon=s.Level==20
    e.LODHomeCellKey=key(a.center);e.LODActivated=true;e.LODMajorThreat=true;e.majorThreat=true
    local cfg=LOD.Config.Encounter.Archetypes.warden
    cfg.model=self:CitizenModel(s.LevelSeed)
    e:SetPos(N:CellCenter(a.center));e:Spawn()
    if not IsValid(e) then return false end
    LOD.EnemyVariance:Apply(e);LOD.HostileMotionV2:SnapSpawn(e)
    w.actor=e;w.visualLife=self:StampVisualLife(e);w.started=true;w.hiddenUntil=CurTime()+C.invisible
    e.LODBossLastDamage=CurTime()
    s.WardenStarted=true;s.ObjectiveStage=P.Stages.DEFEAT_WARDEN
    s.CheckpointPos=N:CellCenter(a.entry)+Vector(0,0,12)
    LOD.EncounterDirector.Entities[#LOD.EncounterDirector.Entities+1]=e
    self:SpawnClones(s,w,a)
    if LOD.WardenTurrets then LOD.WardenTurrets:Admit(s,w,a) end
    if s.Level==20 and LOD.BossRegistry and (#(w.clones or {})~=4 or not w.turrets or w.turrets.admitted~=4) then
        -- A rejected native allocation is not a smaller authored finale. Roll
        -- back the complete uncommitted group and retry through normal service.
        if LOD.WardenTurrets then LOD.WardenTurrets:Retire(w.turrets);LOD.WardenTurrets:Cleanup(w.turrets) end
        for _,clone in ipairs(w.clones or {}) do if IsValid(clone.actor) then clone.actor:Remove() end end
        if IsValid(e) then e:Remove() end
        w.actor=nil;w.started=nil;w.clones={};w.cloneStates={};w.turrets=nil;w.visualLife=nil
        s.WardenStarted=false;s.ObjectiveStage=P.Stages.ENTER_WARDEN
        log("WARDEN_COMPOSITION_RETRY",{level=20,requiredClones=4,requiredTurrets=4})
        return false
    end
    local gate=a.lock.entity
    if IsValid(gate) then gate:SetOpened(false);gate:SetNotSolid(false);gate:SetSolid(SOLID_BBOX) end
    e:SetNW2Bool("LOD_WardenHidden",true);e:SetNW2Int("LOD_WardenPhase",1);e:DrawShadow(false)
    for _,p in ipairs(player.GetAll()) do if hero(p) then
        if LOD.Audio then LOD.Audio:ToPlayer(p,'boss_arrive') end
        if a.court[key(N:WorldToCell(s.Graph,p:GetPos()))] then self:Resupply(p) end
    end end
    P:Announce("GORDON THE WARDEN");P:SyncAll()
    log("WARDEN_COMMIT",{seed=w.seed,party=e.LODWardenParty,maxHP=e:GetMaxHealth(),phase=1})
    return true
end
function W:SetPhase(w,e,phase,now)
    if w.phase==phase then return end
    self:RetirePhaseOne(w,e)
    w.phase=phase;w.hazards={};w.volley=nil;w.swing=nil;w.hiddenUntil=nil;w.nextBomb=now+1;w.tauntUntil=nil
    e:SetNW2Float("LOD_WardenTauntUntil",0)
    e:SetNW2Bool("LOD_WardenHidden",false);e:SetNW2Int("LOD_WardenPhase",phase)
    e:EmitSound("ambient/energy/weld2.wav",75,phase==2 and 90 or 125,0.7)
    if not w.cloneIndex then
        P:Announce(phase==2 and "GORDON — TOILET BOMBER" or "GORDON — CROWBAR BERSERKER")
    end
    log("WARDEN_PHASE",{phase=phase,health=e:Health(),maximum=e:GetMaxHealth()})
end
function W:RollAttack(e,kind)
    local profile=self.Profiles[kind];local rolls=LOD.CombatRolls
    local damageScale=(e.LODConfig.meleeDamage or 8)/8
    return rolls:RollHostileAttack(e,profile,profile.reference*damageScale)
end
function W:Damage(e,p,kind,shared)
    if not alive(e) or not hero(p) or self:Protected(p) then return end
    local rolls=LOD.CombatRolls
    local contract=not shared and self:RollAttack(e,kind) or nil
    if shared then
        contract={};for k,v in pairs(shared) do contract[k]=v end
    end
    local magical=kind=="orb" or kind=="villain"
    local tags={physical=not magical,magic=magical,melee=kind=="crowbar",element=kind=="villain" and "dark" or (kind=="orb" and "raw" or nil),
        authoredScale=contract.scale,attackEvent=contract.attackEvent,damageContract=contract}
    local amount=rolls:ResolveActorDamage(contract,e,p,tags)
    local info=LOD.NewDamageInfo();info:SetAttacker(e);info:SetInflictor(e);info:SetDamage(amount)
    info:SetDamageType(kind=="crowbar" and DMG_CLUB or (kind=="bomb" and DMG_BLAST or DMG_ENERGYBEAM))
    info:SetDamagePosition(p:WorldSpaceCenter());tags.actorDamageResolved=true
    LOD.RPGStatusElements:AttachDamageContext(info,tags)
    rolls:QueueDamageReport(info,function(final) contract.final=final;rolls:_Send({p,e},1,rolls:_HostileRollText(contract,e,p)) end)
    p:TakeDamageInfo(info)
end
function W:AddHazard(w,kind,pos,velocity,target,now)
    local _,root=self:State();root=root or w
    if #self:AllHazards(root)+(LOD.WardenTurrets and LOD.WardenTurrets:ProjectileCount(root) or 0)>=C.maxHazards then return false end
    root.nextHazard=(root.nextHazard or 0)+1
    w.hazards[#w.hazards+1]={id=root.nextHazard,kind=kind,pos=pos,velocity=velocity,target=target,
        expires=now+(kind=="orb" and C.shotLife or C.bombFuse)}
    return true
end
function W:Hazards(w,e,targets,dt,now)
    local kept={}
    for _,q in ipairs(w.hazards) do
        local expired=now>=q.expires
        if q.kind=="orb" and not expired then
            if hero(q.target) and not (LOD.RPGPerceptionState and LOD.RPGPerceptionState:IsInvisible(q.target)) and not self:Protected(q.target) then
                local desired=(q.target:WorldSpaceCenter()-q.pos):GetNormalized()
                local dir=q.velocity:GetNormalized()
                q.velocity=(dir+(desired-dir)*math.min(1,(q.homing or C.homing)*dt)):GetNormalized()*(q.speed or C.shotSpeed)
            end
            local dest=q.pos+q.velocity*dt
            local tr=util.TraceHull({start=q.pos,endpos=dest,mins=Vector(-10,-10,-10),maxs=Vector(10,10,10),mask=MASK_SHOT,filter=e})
            q.pos=tr.Hit and tr.HitPos or dest
            if tr.Hit then if hero(tr.Entity) then self:Damage(e,tr.Entity,q.damageKind or "orb") end;expired=true end
        elseif q.kind=="bomb" and expired then
            -- One shared damage event per target, no native grenade/explosion
            -- entities and no splash through the gallery floor or jail walls.
            local shared=self:RollAttack(e,q.damageKind or "bomb")
            for _,p in ipairs(targets) do
                if hero(p) and p:WorldSpaceCenter():DistToSqr(q.pos)<=(q.radius or C.bombRadius)^2 then
                    local tr=util.TraceLine({start=q.pos+Vector(0,0,12),endpos=p:WorldSpaceCenter(),mask=MASK_SHOT,filter=e})
                    if not tr.Hit or tr.Entity==p then self:Damage(e,p,q.damageKind or "bomb",shared) end
                end
            end
            local fx=EffectData();fx:SetOrigin(q.pos);util.Effect("Explosion",fx,true,true)
            sound.Play("weapons/explode3.wav",q.pos,78,100,0.65)
        end
        if not expired then kept[#kept+1]=q end
    end
    w.hazards=kept
end
function W:Route(e,a,target,now,roaming)
    local waypoint=e:_AdvanceWaypoint()
    if not roaming and waypoint and not waypoint.stair and now>=(e.LODWardenRetargetAt or 0) then
        e.LODWardenRetargetAt=now+0.5
        e.LODWaypoints={waypoint};e.LODWaypointIndex=1
    end
    if not waypoint and now>=(e.LODWardenRouteAt or 0) then
        e.LODWardenRouteAt=now+0.5
        local g=R.State.Graph;local from=N:WorldToCell(g,e:GetPos());local dest
        if roaming then
            local keys={};for k in pairs(a.court) do keys[#keys+1]=k end;table.sort(keys)
            e.LODWardenRouteOrdinal=(e.LODWardenRouteOrdinal or 0)+1
            local rng=LOD.RNG.New(LOD.Seeds.Derive(R.State.LevelSeed,"warden-route:"..tostring(e.LODEncounterOrdinal)..":"..e.LODWardenRouteOrdinal))
            local _,root=self:State();local best=-1
            for _,cellKey in ipairs(keys) do
                local candidate=g.Cells[cellKey];local position=N:CellCenter(candidate)
                local separation=LOD.Config.Maze.CellSize^2*9
                for _,other in ipairs(self:Actors(root)) do
                    if other.actor~=e and alive(other.actor) then separation=math.min(separation,position:DistToSqr(other.actor:GetPos())) end
                end
                local score=separation+rng:Float(0,LOD.Config.Maze.CellSize^2)
                if score>best then dest=candidate;best=score end
            end
        else dest=target and N:WorldToCell(g,target:GetPos()) end
        if dest then
            e.LODWaypoints=N:PathToWaypoints(g,N:FindPath(g,from,dest)) or {};e.LODWaypointIndex=1
            if not roaming and key(from)==key(dest) then
                e.LODWaypoints={{pos=LOD.HostileMotionV2.SafeEngagementPoint and LOD.HostileMotionV2:SafeEngagementPoint(g,target) or target:GetPos(),tolerance=18,stair=false}}
            end
        end
        waypoint=e:_AdvanceWaypoint()
    end
    if waypoint then e:_SetActivity(ACT_RUN);LOD.HostileMotionV2:MoveToward(e,waypoint)
    else e:_SetActivity(ACT_IDLE);LOD.HostileMotionV2:Stop(e) end
end
-- SPOT-06: finite work inside the existing Warden owner, not another combat or
-- status authority. The independent service also visits this state while native
-- AI wrappers are holding ordinary hit-stun.
function W:ActorOwner(w,e)
    local s,root=self:State()
    if not s or not s.BuildReady or s.Failed or s.LevelCleared or not root.started or root.dead
        or root.state~=s or root.graph~=s.Graph or root.epoch~=s.CampaignEpoch
        or root.campaignSeed~=s.CampaignSeed or root.runId~=s.RunId or root.level~=s.Level
        or not alive(root.actor) or not alive(e) or e.LODWardenOwner~=root or w.dead
        or (e==root.actor and w~=root)
        or (e~=root.actor and (not root.cloneStates or root.cloneStates[e]~=w))
        or w.actor~=e then return false end
    return true,root,s
end
function W:PhaseOwner(w,e,work)
    local ok,root,s=self:ActorOwner(w,e)
    if not ok or w.phase~=1 then return false end
    if work and (w.phaseOne~=work or work.cycle~=w.phaseCycle or work.actor~=e
        or work.owner~=w or work.root~=root or work.state~=s or work.graph~=s.Graph
        or work.epoch~=s.CampaignEpoch or work.campaignSeed~=s.CampaignSeed
        or work.runId~=s.RunId or work.level~=s.Level or work.seed~=s.LevelSeed) then return false end
    return true,root,s
end
function W:RetirePhaseOne(w,e)
    if not w then return end
    w.phaseOne=nil;w.phaseCues=nil;w.tauntUntil=nil;w.tellHit=nil
    if IsValid(e) then e:SetNW2Float("LOD_WardenTauntUntil",0) end
end
function W:RetirePhaseRoot(root)
    if not root then return end
    for _,w in ipairs(self:Actors(root)) do self:RetirePhaseOne(w,w.actor) end
end
function W:PhaseCue(w,kind,pos,now,seconds,caption)
    -- Fixed positions and deadlines; snapshots never renew or play these cues.
    local cues={}
    for _,q in ipairs(w.phaseCues or {}) do if now<q.expires then cues[#cues+1]=q end end
    if #cues>=2 then table.remove(cues,1) end
    cues[#cues+1]={kind=kind,pos=Vector(pos.x,pos.y,pos.z),start=now,
        expires=now+seconds,caption=caption or 0,cycle=w.phaseCycle}
    w.phaseCues=cues
end
function W:BeginHidden(w,e,now,initial)
    local ok,root,s=self:PhaseOwner(w,e)
    if not ok then self:RetirePhaseOne(w,e);return end
    if self.phaseRoot and self.phaseRoot~=root then self:RetirePhaseRoot(self.phaseRoot) end
    self.phaseRoot=root
    w.phaseCycle=(w.phaseCycle or 0)+1
    local work={cycle=w.phaseCycle,actor=e,owner=w,root=root,state=s,graph=s.Graph,
        epoch=s.CampaignEpoch,campaignSeed=s.CampaignSeed,runId=s.RunId,
        level=s.Level,seed=s.LevelSeed,stage="hidden"}
    w.phaseOne=work;w.phaseCues={};w.volley=nil;w.tauntUntil=nil
    w.hiddenUntil=initial and (w.hiddenUntil or now+C.invisible) or now+C.invisible
    work.deadline=w.hiddenUntil
    e:SetNW2Bool("LOD_WardenHidden",true);e:SetNW2Float("LOD_WardenTauntUntil",0)
    e.LODHitStunUntil=math.min(e.LODHitStunUntil or now,now)
    if not initial then
        self:PhaseCue(w,1,e:GetPos(),now,C.departure)
        if LOD.Audio then LOD.Audio:Emit(e,"portal_depart") end
    end
    return work
end
function W:PhaseTargets(targets)
    local out={}
    for _,p in ipairs(targets or self:Targets()) do
        if not (LOD.RPGPerceptionState and LOD.RPGPerceptionState:IsInvisible(p)) then out[#out+1]=p end
    end
    return out
end
function W:TauntCaption(root,now,targets)
    if root.lastIncoming and now-root.lastIncoming<=C.contextHorizon then return 1 end
    if root.lastHeroDamage and now-root.lastHeroDamage<=C.contextHorizon then return 2 end
    for _,p in ipairs(targets) do
        if p.KeyDown and ((IN_ATTACK and p:KeyDown(IN_ATTACK)) or (IN_ATTACK2 and p:KeyDown(IN_ATTACK2))) then return 4 end
    end
    return 3
end
function W:StartArrival(w,e,work,now)
    LOD.HostileMotionV2:Stop(e)
    work.stage="arriving";work.position=Vector(e:GetPos().x,e:GetPos().y,e:GetPos().z)
    work.deadline=now+C.arrival
    w.phaseCues={} -- a displaced arrival replaces, never accumulates warnings
    self:PhaseCue(w,2,work.position,now,C.arrival)
    if LOD.Audio then LOD.Audio:Emit(e,"portal_arrive") end
end
function W:ServicePhaseOne(w,e,now,targets)
    local work=w.phaseOne
    local ok,root,s=self:PhaseOwner(w,e,work)
    if not ok then self:RetirePhaseOne(w,e);w.volley=nil;return end
    targets=self:PhaseTargets(targets)
    if s.SimulationFrozen or #targets==0 then
        self:RetirePhaseOne(w,e);w.volley=nil;w.hazards={};w.hiddenUntil=now+C.invisible
        e:SetNW2Bool("LOD_WardenHidden",true)
        e.LODHitStunUntil=math.min(e.LODHitStunUntil or now,now)
        LOD.HostileMotionV2:Stop(e);return
    end
    work=work or self:BeginHidden(w,e,now,true)
    if work.stage=="hidden" then
        e.LODHitStunUntil=math.min(e.LODHitStunUntil or now,now)
        if now>=work.deadline then self:StartArrival(w,e,work,now) end
    elseif work.stage=="arriving" then
        LOD.HostileMotionV2:Stop(e)
        e.LODHitStunUntil=math.min(e.LODHitStunUntil or now,now)
        if e:GetPos():DistToSqr(work.position)>0 then
            self:StartArrival(w,e,work,now)
        elseif now>=work.deadline then
            work.revealed=now;work.cap=now+C.exposureCap;w.phaseCues={}
            e:SetNW2Bool("LOD_WardenHidden",false)
            if root.attackSinceTaunt and now>=(root.nextTaunt or 0) then
                work.stage="taunt";work.deadline=now+C.tauntDuration
                root.nextTaunt=now+C.tauntCooldown;root.attackSinceTaunt=false
                w.tauntUntil=work.deadline;e:SetNW2Float("LOD_WardenTauntUntil",w.tauntUntil)
                self:PhaseCue(w,3,e:GetPos(),now,C.tauntDuration,self:TauntCaption(root,now,targets))
                if LOD.Audio then LOD.Audio:Emit(e,"boss_taunt") end
            else
                work.stage="attack";work.deadline=now+C.warning+C.visible
                root.attackSinceTaunt=true
                local status=LOD.RPGStatusElements
                if not status or status:CanInitiateAttack(e) and (not status.CanInitiateMagic or status:CanInitiateMagic(e)) then
                    w.volley={count=0,next=now+C.warning,finish=work.deadline,cycle=work.cycle}
                    e:EmitSound("ambient/energy/weld1.wav",72,110,0.65)
                end
            end
        end
    else
        if now>=math.min(work.deadline,work.cap) then return self:BeginHidden(w,e,now) end
        local status=LOD.RPGStatusElements
        if status and (not status:CanInitiateAttack(e)
            or status.CanInitiateMagic and not status:CanInitiateMagic(e)) then w.volley=nil end
        e.LODHitStunUntil=math.min(e.LODHitStunUntil or now,work.followup or work.cap)
    end
    return w.phaseOne
end
function W:HitStunDeadline(e,now)
    local _,root=self:State();local w=root and (root.cloneStates and root.cloneStates[e] or root)
    -- Unowned test actors and later phases retain ordinary hit-stun semantics.
    if not w or e~=w.actor or w.phase~=1 then return end
    local work=self:ServicePhaseOne(w,e,now)
    if not work or (work.stage~="attack" and work.stage~="taunt") then return now end
    return work.followup or math.min(now+C.followup,work.cap)
end
function W:OnEffectiveHit(e,now)
    local _,root=self:State();local w=root and (root.cloneStates and root.cloneStates[e] or root)
    if not w or e~=w.actor or w.phase~=1 then return end
    local work=self:ServicePhaseOne(w,e,now)
    if not work then return end
    root.lastIncoming=now
    if work.stage~="attack" and work.stage~="taunt" then return end
    if not work.followup then
        work.followup=math.min(now+C.followup,work.cap);work.deadline=work.followup
        log("WARDEN_FOLLOWUP",{cycle=work.cycle,untilTime=work.followup,cap=work.cap,clone=w.cloneIndex or 0})
    end
    w.volley=nil;w.tauntUntil=nil;w.phaseCues={}
    e:SetNW2Float("LOD_WardenTauntUntil",0)
    e.LODHitStunUntil=math.min(e.LODHitStunUntil or now,work.followup)
end
function W:Interrupt(e)
    local _,w=self:State();w=w and (w.cloneStates and w.cloneStates[e] or w)
    if not w or e~=w.actor then return end
    w.volley=nil;w.swing=nil
    if w.phase==1 then return end -- positive damage, not stun admission, owns the window
    w.hiddenUntil=CurTime()+C.invisible;w.tauntUntil=nil
    e:SetNW2Float("LOD_WardenTauntUntil",0)
    -- Already released ordnance retains its original fuse and attribution.
end
function W:Cues(now)
    local _,root=self:State();local out={}
    if not root then return out end
    for _,w in ipairs(self:Actors(root)) do
        if self:PhaseOwner(w,w.actor,w.phaseOne) and w.phaseOne then
            for _,q in ipairs(w.phaseCues or {}) do
                if now<q.expires and q.cycle==w.phaseCycle and #out<C.maxCues then out[#out+1]=q end
            end
        end
    end
    return out
end
function W:Tick(e)
    if e.LODArchetypeId~="warden" then return false end
    local s,w,a=self:State();w=w and (w.cloneStates and w.cloneStates[e] or w)
    local now=CurTime();local motion=LOD.HostileMotionV2
    if not s or not w or e~=w.actor or not alive(e) or w.dead or not s.BuildReady or s.Failed or s.LevelCleared then motion:Stop(e);return true end
    local targets=self:Targets()
    if s.SimulationFrozen or #targets==0 then
        -- Preserve health and phase, but retire attacks aimed at a dead party.
        w.hazards={};w.volley=nil;w.swing=nil;w.hiddenUntil=now+C.invisible
        if w.phase==1 then self:ServicePhaseOne(w,e,now,targets) end
        motion:Stop(e);return true
    end
    local fraction=e:Health()/math.max(1,e:GetMaxHealth())
    local phase=fraction<=0.25 and 3 or (fraction<=0.60 and 2 or 1)
    self:SetPhase(w,e,math.max(w.phase,phase),now)
    local visible={}
    for _,p in ipairs(targets) do
        if not (LOD.RPGPerceptionState and LOD.RPGPerceptionState:IsInvisible(p)) then visible[#visible+1]=p end
    end
    targets=visible
    if #targets==0 then
        w.volley=nil;w.swing=nil
        if w.phase==1 then self:ServicePhaseOne(w,e,now,targets) end
        motion:Stop(e);return true
    end
    local target=targets[1]
    for _,p in ipairs(targets) do if e:GetPos():DistToSqr(p:GetPos())<e:GetPos():DistToSqr(target:GetPos()) then target=p end end
    if w.cloneIndex then target=targets[(w.cloneIndex%#targets)+1] end
    local status=LOD.RPGStatusElements
    local canAttack=not status or status:CanInitiateAttack(e)
    local canMove=not status or status:CanMoveVoluntarily(e)
    if w.phase==1 then
        local work=self:ServicePhaseOne(w,e,now,targets)
        if not work then motion:Stop(e);return true end
        if motion:HoldHitStun(e,now) then return true end
        if work.stage=="hidden" then
            if canMove then self:Route(e,a,target,now,true) else motion:Stop(e) end
        else
            motion:Stop(e);e:_SetActivity(ACT_IDLE)
            if not canAttack or status and status.CanInitiateMagic and not status:CanInitiateMagic(e) then w.volley=nil end
            local v=w.volley
            if work.stage=="attack" and not work.followup and v and v.cycle==work.cycle
                and v.count<4 and now>=v.next then
                local aim=targets[((v.count+(w.cloneIndex or 0))%#targets)+1];local pos=e:WorldSpaceCenter()+Vector(0,0,12)
                self:AddHazard(w,"orb",pos,(aim:WorldSpaceCenter()-pos):GetNormalized()*C.shotSpeed,aim,now)
                v.count=v.count+1;v.next=now+C.shotGap
            end
        end
    elseif motion:HoldHitStun(e,now) or not canAttack then
        w.volley=nil;w.swing=nil;w.hiddenUntil=now+C.invisible;motion:Stop(e);return true
    elseif w.phase==2 then
        if canMove then self:Route(e,a,target,now,true) else motion:Stop(e) end
        if now>=(w.nextBomb or 0) then
            w.nextBomb=now+C.bombGap
            local pos=e:GetPos()+Vector(0,0,10)
            self:AddHazard(w,"bomb",pos,vector_origin,nil,now)
            -- Alternating pursuit routes naturally leave a readable bomb wake.
            e:EmitSound("weapons/slam/mine_mode.wav",68,115,0.6)
        end
    else
        local distance=e:GetPos():DistToSqr(target:GetPos())
        local range=(e.LODConfig.meleeRange or C.meleeRange)
        if w.swing then
            motion:Stop(e)
            if now>=w.swing.ready then
                local victim=w.swing.target;w.swing=nil;w.nextSwing=now+(e.LODConfig.meleeCooldown or C.meleeGap)
                if hero(victim) and not (LOD.RPGPerceptionState and LOD.RPGPerceptionState:IsInvisible(victim)) and e:GetPos():DistToSqr(victim:GetPos())<=range^2 then
                    local tr=util.TraceLine({start=e:WorldSpaceCenter(),endpos=victim:WorldSpaceCenter(),mask=MASK_SHOT,filter=e})
                    if not tr.Hit or tr.Entity==victim then self:Damage(e,victim,"crowbar") end
                end
            end
        elseif distance<=range^2 and now>=(w.nextSwing or 0) then
            w.swing={ready=now+C.meleeWarning,target=target}
            e:SetNW2Float("LOD_WardenSwing",now+C.meleeWarning);motion:FaceToward(e,target:GetPos())
            e:EmitSound("weapons/iceaxe/iceaxe_swing1.wav",72,105,0.7)
        elseif canMove then self:Route(e,a,target,now,false) else motion:Stop(e) end
    end
    return true
end
function W:EnsureKey()
    local s,w,a=self:State()
    if not s or not w.dead or s.Failed or s.LevelCleared or s.JailKey then return end
    if s.Level==20 and not (LOD.Hector and LOD.Hector:RescueAllowed(s)) then return end
    return P:SpawnJailKey(N:CellCenter(a.center)+Vector(0,0,LOD.Config.Progression.KeycardHeight),"gordon_warden")
end
function W:Killed(e)
    local s,w,a=self:State()
    local clone=w and w.cloneStates and w.cloneStates[e]
    if clone then clone.dead=true;clone.hazards={};clone.volley=nil;clone.swing=nil
        self:RetirePhaseOne(clone,e);return end
    if not s or e~=w.actor or w.dead then return end
    if s.Level==20 and (w.state~=s or w.graph~=s.Graph or w.epoch~=s.CampaignEpoch
        or w.combatDeath~=e or not IsValid(e) or not e.LODDead or e:Health()>0) then return end
    self:RetirePhaseRoot(w)
    w.dead=true;w.hazards={};w.volley=nil;w.swing=nil
    if LOD.WardenTurrets then LOD.WardenTurrets:Retire(w.turrets) end
    if LOD.DamselRevenge and LOD.DamselRevenge.OnGordonDeath then LOD.DamselRevenge:OnGordonDeath(w,e) end
    for _,other in ipairs(w.clones or {}) do other.dead=true;other.hazards={};other.volley=nil;other.swing=nil end
    if s.Level==20 then
        if not LOD.Hector or not LOD.Hector:OnGordonDefeated(s,w,a,e) then R:FailCampaign("Hector handoff unavailable") end
        return
    end
    s.ObjectiveStage=P.Stages.TAKE_JAIL_KEY
    -- Preserve ordinary end-of-batch wipe precedence. No rescue/level-complete
    -- call, and no model/collision/entity mutation inside the lethal callback.
    timer.Simple(0,function()
        if R.State~=s or s.Warden~=w or s.Failed or s.LevelCleared then return end
        if IsValid(a.lock.entity) then a.lock.entity:OpenGate() end
        for _,other in ipairs(ents.FindByClass("lod_hostile")) do
            if IsValid(other) and other~=e and a.cells[key(N:WorldToCell(s.Graph,other:GetPos()))] then other:Remove() end
        end
        W:EnsureKey();P:Announce("GORDON DEFEATED — TAKE THE JAIL KEY AT THE ARENA CENTER");P:SyncAll()
        for _,p in ipairs(player.GetAll()) do if R:IsActivePlayer(p) then p:EmitSound("legend_of_deborah/adventure/unlock.wav",60,100,0.7) end end
        log("WARDEN_DEFEATED",{seed=w.seed,keyCell=key(a.center)})
    end)
end
hook.Add("OnNPCKilled","LOD_WardenDeath",function(e) W:Killed(e) end)
hook.Add("PostEntityTakeDamage","LOD_BossDamagePresentation",function(e,info,tookDamage)
    if not tookDamage or not IsValid(e) or info:GetDamage()<=0 then return end
    local source=info.GetAttacker and info:GetAttacker()
    local s,root=W:State()
    local owner=root and (root.cloneStates and root.cloneStates[source] or root)
    if s and hero(e) and owner and owner.actor==source and W:PhaseOwner(owner,source,owner.phaseOne) then
        root.lastHeroDamage=CurTime()
    end
    if not alive(e) then return end
    if e.LODArchetypeId=="warden" then
        e.LODBossLastDamage=CurTime();W:OnEffectiveHit(e,CurTime())
    elseif e.LODArchetypeId=="neil" then e:SetNW2Float("LOD_NeilHurtAt",CurTime()) end
end)
hook.Add("EntityTakeDamage","LOD_WardenAlcove",function(target,info)
    local attacker=info:GetAttacker()
    local turret=IsValid(target) and target.LODWardenTurret
    local turretSource=IsValid(attacker) and attacker.LODWardenTurret
    if LOD.WardenTurrets and (turret or turretSource) then
        local source=LOD.EntrySafety and LOD.EntrySafety:Source(attacker) or attacker
        if (turret and (not LOD.WardenTurrets:Body(target) or W:Protected(source)))
            or (turretSource and not LOD.WardenTurrets:Body(attacker)) then info:SetDamage(0);return true end
    end
    if W:Protected(target) or (IsValid(target) and target.LODArchetypeId=="warden" and W:Protected(attacker)) then
        info:SetDamage(0);return true
    end
end)
-- SPOT-07 presentation leases. Generic tokens identify native lifetimes, not
-- real/fake roles; only admitted recipients receive clone-specific records.
function W:NextVisualLife()
    self.visualSerial=((self.visualSerial or 0)%2147483646)+1
    return self.visualSerial
end
function W:StampVisualLife(e)
    local token=self:NextVisualLife()
    e:SetNW2Int("LOD_WardenVisualLife",token)
    return token
end
W.tellObservers=setmetatable({},{__mode="k"})
function W:RetireTellObserver(p)
    if not self.tellObservers[p] then return end
    self.tellObservers[p]=nil
    if IsValid(p) then p:SetNW2Int("LOD_WardenObserverLife",0) end
end
for _,event in ipairs({"PlayerDeath","PlayerSpawn","PlayerDisconnected"}) do
    hook.Add(event,"LOD_WardenTellObserverLife",function(p) W:RetireTellObserver(p) end)
end
function W:TellObserver(p,s)
    if not hero(p) or p:GetNW2Bool("LOD_IsSoldier",false) then return end
    local ps=R:GetPlayerState(p)
    local rules=LOD.RPGAbilityRules
    local derived=rules and rules:Derived(p)
    local profile=rules and rules:ProgressionState(p)
    if not ps or not profile or profile~=ps.progressionState or not derived then return end
    local wisdom=tonumber(derived.wisMod)
    if not wisdom or wisdom~=wisdom or wisdom==math.huge or wisdom==-math.huge then return end
    local range=math.max(0,wisdom/2)*LOD.Config.Maze.CellSize
    if range<=0 or range==math.huge then return end
    local lives=LOD.RPGStatusElements and LOD.RPGStatusElements.ActorLives
    local life=lives and lives[p]
    local old=self.tellObservers[p]
    if not old or old.state~=s or old.ps~=ps or old.profile~=profile or old.life~=life
        or old.epoch~=s.CampaignEpoch or old.graph~=s.Graph or old.seed~=s.LevelSeed
        or old.serial~=(ps.ordinal or 0) then
        old={state=s,ps=ps,profile=profile,life=life,epoch=s.CampaignEpoch,graph=s.Graph,
            seed=s.LevelSeed,serial=ps.ordinal or 0}
    end
    return old,range
end
function W:TellVisible(p,w,range)
    local e=w.actor
    if not self:ActorOwner(w,e) or not w.cloneIndex or not w.visualLife
        or e:GetNW2Int("LOD_WardenVisualLife",0)~=w.visualLife
        or e:GetNW2Bool("LOD_WardenHidden",false) or e:GetNoDraw()
        or p:GetPos():DistToSqr(e:GetPos())>range*range then return false end
    local tr=util.TraceLine({start=p:EyePos(),endpos=e:WorldSpaceCenter(),mask=MASK_VISIBLE,filter=p})
    return tr and not tr.StartSolid and (not tr.Hit or tr.Entity==e)
end
function W:TellEye(w,now)
    local cycle=math.max(0,math.floor((now-w.tellEpoch)/C.winkPeriod))
    local rng=LOD.RNG.New(LOD.Seeds.Derive(R.State.LevelSeed,
        "warden-tell-eye:"..w.cloneIndex..":"..cycle))
    -- Mix adjacent cycle labels before the cosmetic choice; no shared RNG draw.
    rng:NextRaw();rng:NextRaw()
    return rng:Int(0,1),w.tellEpoch+cycle*C.winkPeriod
end
function W:OnTellHitStun(e,now)
    local _,root=self:State();local w=root and root.cloneStates and root.cloneStates[e]
    if not w or not self:ActorOwner(w,e) or e:GetNW2Bool("LOD_WardenHidden",false) then return end
    local expires=math.min(now+C.fakeRecoil,e.LODHitStunUntil or now)
    if expires>now then w.tellHit={start=now,expires=expires,phase=w.phase} end
end
function W:TellRecords(p,now)
    local s,root=self:State()
    if not root or not self:ActorOwner(root,root.actor) or s.SimulationFrozen
        or #self:PhaseTargets()==0 then return {} end
    local observer,range=self:TellObserver(p,s)
    if not observer then return {} end
    local records={}
    for _,w in ipairs(root.clones or {}) do
        if #records<4 and self:TellVisible(p,w,range) then
            local eye,start=self:TellEye(w,now)
            local hit=w.tellHit
            local hurtUntil=hit and hit.phase==w.phase and math.min(hit.expires,w.actor.LODHitStunUntil or now) or now
            records[#records+1]={actor=w.actor,life=w.visualLife,phase=w.phase,eye=eye,wink=start,
                hurt=hit and hurtUntil>now and hit.start or 0,hurtUntil=hurtUntil>now and hurtUntil or 0}
        end
    end
    return records,observer,range,root
end
util.AddNetworkString("LOD_WardenTells")
function W:SyncTells()
    local now=CurTime()
    for _,p in ipairs(player.GetAll()) do
        local records,observer,range,root=self:TellRecords(p,now)
        if #records>0 then
            if not observer.token then
                observer.token=self:NextVisualLife();self.tellObservers[p]=observer
                p:SetNW2Int("LOD_WardenObserverLife",observer.token)
            end
            net.Start("LOD_WardenTells")
            net.WriteUInt(#records,3);net.WriteFloat(now);net.WriteFloat(now+C.tellLease)
            net.WriteEntity(root.actor);net.WriteUInt(root.visualLife,31)
            net.WriteUInt(observer.token,31);net.WriteUInt(observer.serial,32);net.WriteFloat(range)
            for _,q in ipairs(records) do
                net.WriteEntity(q.actor);net.WriteUInt(q.life,31);net.WriteUInt(q.phase,2)
                net.WriteUInt(q.eye,1);net.WriteFloat(q.wink);net.WriteFloat(q.hurt);net.WriteFloat(q.hurtUntil)
            end
            net.Send(p);observer.sent=true
        else
            local old=self.tellObservers[p]
            if old and old.sent then net.Start("LOD_WardenTells");net.WriteUInt(0,3);net.Send(p) end
            self:RetireTellObserver(p)
        end
    end
end

-- Stable health/phase/hazard replication, capped at five small snapshots/second.
util.AddNetworkString("LOD_WardenState")
function W:Sync()
    local s,w,a=self:State();local active=s and w.started and not w.dead and s.BuildReady and not s.Failed and not s.LevelCleared and alive(w.actor)
    net.Start("LOD_WardenState");net.WriteBool(active==true)
    if active then
        net.WriteEntity(w.actor);net.WriteFloat(w.actor:Health());net.WriteFloat(w.actor:GetMaxHealth());net.WriteUInt(w.phase,2)
        local hazards=self:AllHazards(w)
        net.WriteUInt(#hazards,5)
        for _,q in ipairs(hazards) do
            net.WriteUInt(q.id%65536,16);net.WriteBool(q.kind=="bomb");net.WriteVector(q.pos)
            net.WriteVector(q.velocity);net.WriteFloat(q.expires)
        end
    end
    if active then
        local cues=not s.SimulationFrozen and #self:PhaseTargets()>0 and self:Cues(CurTime()) or {}
        net.WriteUInt(#cues,4)
        for _,q in ipairs(cues) do
            net.WriteUInt(q.kind,2);net.WriteVector(q.pos);net.WriteFloat(q.start);net.WriteFloat(q.expires);net.WriteUInt(q.caption,3)
        end
    end
    net.Broadcast()
end
local reset=P.ResetLevelState
function P:ResetLevelState(...)
    if LOD.DamselRevenge and LOD.DamselRevenge.Retire then LOD.DamselRevenge:Retire(LOD.DamselRevenge.current,"reset") end
    if LOD.WardenTurrets then LOD.WardenTurrets:Retire(LOD.WardenTurrets.current) end
    W:RetirePhaseRoot(R.State and R.State.Warden);W.phaseRoot=nil
    local result=reset(self,...);R.State.Warden=nil;R.State.WardenStarted=false;W:Sync();W:SyncTells();return result
end
-- Fuse/travel time belongs to the shared service, not a stunned NextBot's
-- behavior coroutine. Phase-three damage thresholds retire ordnance first.
hook.Add("Think","LOD_WardenOrdnance",function()
    if LOD.DamselRevenge and LOD.DamselRevenge.Service then LOD.DamselRevenge:Service() end
    if LOD.WardenTurrets then LOD.WardenTurrets:Service() end
    local s,w=W:State()
    if W.phaseRoot and (W.phaseRoot~=w or not s or not s.BuildReady or s.Failed or s.LevelCleared or w.dead or not alive(w.actor)) then
        W:RetirePhaseRoot(W.phaseRoot);W.phaseRoot=nil
    end
    if not s or not s.BuildReady or not w.started or w.dead or not alive(w.actor) or s.Failed or s.LevelCleared then return end
    local now=CurTime();local dt=math.Clamp(now-(w.lastHazardTick or now),0,0.1);w.lastHazardTick=now
    local targets=W:Targets()
    for _,actorState in ipairs(W:Actors(w)) do
        local actor=actorState.actor
        if s.SimulationFrozen or #targets==0 or not alive(actor) then
            actorState.hazards={}
            if actorState.phase==1 then W:ServicePhaseOne(actorState,actor,now,targets) end
        else
            local fraction=actor:Health()/math.max(1,actor:GetMaxHealth())
            W:SetPhase(actorState,actor,math.max(actorState.phase,fraction<=0.25 and 3 or (fraction<=0.60 and 2 or 1)),now)
            if actorState.phase==1 then
                W:ServicePhaseOne(actorState,actor,now,targets)
                if not actorState.phaseOne then actorState.hazards={} end
            end
            if #actorState.hazards>0 then W:Hazards(actorState,actor,targets,dt,now) end
        end
    end
end)
local nextThink=0
hook.Add("Think","LOD_WardenService",function()
    local now=CurTime();if now<nextThink then return end;nextThink=now+C.syncGap
    W:SyncTells()
    local s=R.State
    if not s or not s.BuildReady or s.Failed or s.LevelCleared then
        if W.sentActive then W:Sync();W.sentActive=false end;return
    end
    if not s.SimulationFrozen then
        W:Prepare();local _,w,a=W:State()
        if w then
            if not w.dead then
                if w.started and #(w.clones or {})<W:CloneCount(s.Level) and LOD.EncounterDirector:GetActiveCount()<LOD.Config.Encounter.ActiveHostileCeiling then W:SpawnClones(s,w,a) end
                for _,p in ipairs(player.GetAll()) do if hero(p) then
                    if W:InCell(p,a.entry) then W:Resupply(p)
                    elseif a.court[key(N:WorldToCell(s.Graph,p:GetPos()))] and not w.started then W:Commit() end
                end end
            else W:EnsureKey() end
            W:Sync();W.sentActive=w.started and not w.dead
        end
    end
end)
concommand.Add("lod_warden_status",function(p)
    if IsValid(p) and not p:IsAdmin() then return end
    local s,w=W:State()
    print("[LOD WARDEN] started="..tostring(w and w.started).." phase="..tostring(w and w.phase).." dead="..tostring(w and w.dead)
        .." hp="..tostring(w and alive(w.actor) and w.actor:Health()).." hazards="..tostring(w and #w.hazards)
        .." key="..tostring(s and s.JailKey).." phaseOne="..tostring(w and w.phaseOne and w.phaseOne.stage)
        .." deadline="..tostring(w and w.phaseOne and w.phaseOne.deadline).." cues="..#W:Cues(CurTime())..(LOD.WardenTurrets and LOD.WardenTurrets:Status(w) or ""))
end)
concommand.Add("lod_warden_testkit",function(p)
    local cv=GetConVar("lod_developer_mode");local s=R.State
    if not cv or not cv:GetBool() or not hero(p) or not p:IsAdmin() or not LOD.Equipment:CanAct(p)
        or not s.BuildReady or s.Failed or s.LevelCleared or s.SimulationFrozen then return end
    local a=s.Graph.Progression.Warden;if not a then return end
    if s.Warden and (s.Warden.started or s.Warden.dead) then p:ChatPrint("This dungeon's Warden already exists; no reset or duplicate.");return end
    -- This explicit test-only shortcut is unranked; ordinary Black-key law is
    -- unchanged. It removes neither Neil nor his card and cannot award rescue.
    R:MarkUnranked("warden_testkit")
    for i=1,4 do s.Cards[i]=true;s.GatesOpen[i]=true;local e=s.Graph.Progression.Gates[i].entity;if IsValid(e) then e:OpenGate() end end
    s.ObjectiveStage=P.Stages.ENTER_WARDEN;W:Prepare()
    p:SetPos(N:CellCenter(a.entry)+Vector(0,0,12));W:Resupply(p);P:SyncAll()
    p:ChatPrint("Enter the court ahead to commit to Gordon. Ordinary respawn and Jail Key rules remain active.")
end)
