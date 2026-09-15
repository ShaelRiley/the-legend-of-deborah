-- Unique post-Yellow hunt. ProgressionDirector owns gates/cards; Motion V2
-- executes graph paths; the shared combat/variance pipeline owns RPG effects.
LOD.NeilBrute = LOD.NeilBrute or {}
local H = LOD.NeilBrute
local P, N, R = LOD.ProgressionDirector, LOD.MazeNavigator, LOD.RunManager
local EC, PC = LOD.Config.Encounter, LOD.Config.Progression
local S = P.Stages
H.Config = {windup=1.25, chargeSpeed=560, chargeSeconds=1.2, cooldown=3,
    wallStun=2, chargeRange=760, minimumChargeRange=1}
local C = H.Config
EC.Archetypes.neil = {class="lod_hostile", name="Neil", model="models/gman_high.mdl",
    baseHP=150, speed=220, meleeDamage=0, meleeCooldown=3, meleeRange=0, threat=3, activity=ACT_RUN}
EC.Archetypes.brute = {class="lod_hostile", name="The Brute", model="models/antlion_guard.mdl",
    baseHP=250, speed=140, meleeDamage=20, meleeCooldown=3, meleeRange=90,
    burstTelegraph=C.windup, fireRange=C.chargeRange, threat=5, activity=ACT_RUN}
LOD.CombatRolls.HostileDamageProfiles.brute = {label="BRUTE", source="charge",
    count=4, sides=6, bonus=6, reference=20}

local function key(c) return c and LOD.MazeGenerator.CellKey(c.x,c.y,c.z) end
local function edge(a,b) return a<b and a.."|"..b or b.."|"..a end
local function sorted(t)
    local a={};for k in pairs(t or {}) do a[#a+1]=k end;table.sort(a);return a
end
local function living(e) return IsValid(e) and not e.LODDead and e:Health()>0 end
local function activeHero(p) return IsValid(p) and p:IsPlayer() and p:Alive() and R:IsActivePlayer(p) end
local function currentCell(e,g) return N:WorldToCell(g,e:GetPos()) end
local function log(event, data)
    if LOD.RPGTestLog and LOD.RPGTestLog.Write then LOD.RPGTestLog:Write(event,data) end
end

-- Also used before a graph commits, when the previous dungeon's gate state
-- must not influence validation. No new topology or arbitrary vertical edges.
function H:Walk(g, starts, blocked, live)
    local dist, prev, q = {}, {}, {}
    for _,k in ipairs(starts) do if g.Cells[k] and dist[k]==nil then dist[k]=0;q[#q+1]=k end end
    local head=1
    while q[head] do
        local k=q[head];head=head+1
        for _,n in ipairs(sorted(g.Cells[k].neighbors)) do
            if g.Cells[n] and dist[n]==nil and not (blocked and blocked[edge(k,n)])
                and (not live or N:CanTraverse(g,k,n)) then
                dist[n]=dist[k]+1;prev[n]=k;q[#q+1]=n
            end
        end
    end
    return dist,prev
end

function H:Plan(g,seed)
    local p=g.Progression
    local jail=p.JailEdge
    local stair={}
    for _,e in ipairs(g.VerticalEdges or {}) do stair[key(e.a)]=true;stair[key(e.b)]=true end
    local floors={};for _,c in pairs(g.Cells) do floors[c.z]=true end
    -- Latest compatible pre-jail bridge reserves the existing Core beyond Black.
    -- Gordon's arena expansion can replace that destination without changing hunt law.
    local black, reach
    for i=jail.pathIndex-1,p.Gates[3].pathIndex+1,-1 do
        local a,b=g.CriticalPath[i],g.CriticalPath[i+1]
        if a and b and a.z==b.z and not stair[key(a)] and not stair[key(b)] then
            local ek=edge(key(a),key(b))
            local d=self:Walk(g,{key(g.Start)},{[ek]=true,[jail.edgeKey]=true})
            local seen={};for k in pairs(d) do seen[g.Cells[k].z]=true end
            local all=true;for z in pairs(floors) do if not seen[z] then all=false end end
            if g.Edges[ek] and not d[key(p.CoreCell)] and all then
                black={index=4,id="black",edgeKey=ek,pathIndex=i,beforeCell=table.Copy(a),afterCell=table.Copy(b)}
                reach=d;break
            end
        end
    end
    if not black then return false,"no Black Gate bridge preserving every hunt floor" end
    local firstFloor=math.huge;for z in pairs(floors) do firstFloor=math.min(firstFloor,z) end
    local candidates={}
    for _,k in ipairs(sorted(reach)) do
        local c=g.Cells[k]
        if c.z==firstFloor and k~=key(g.Start) and not stair[k] then candidates[#candidates+1]=k end
    end
    if #candidates==0 then return false,"no legal first-floor Neil spawn" end
    local rng=LOD.RNG.New(LOD.Seeds.Derive(seed or g.LevelSeed or 1,"neil-brute-hunt"))
    local neilKey=rng:Pick(candidates)
    local d=self:Walk(g,{neilKey},{[black.edgeKey]=true,[jail.edgeKey]=true})
    local escort
    for _,k in ipairs(sorted(d)) do if d[k]==2 and not stair[k] then escort=k;break end end
    if not escort then return false,"no two-cell Brute escort spawn" end
    p.Gates[4]=black
    p.Hunt={neilCell=table.Copy(g.Cells[neilKey]),bruteCell=table.Copy(g.Cells[escort]),seed=seed}
    p.Validation.blackGate=true;p.Validation.huntFloors=true
    p.Validation.orderedRoute="Start>Red>Blue>Yellow>Neil>Black Keycard>Black Gate>Temporary Core Jail Key>Jail Door>Deborah"
    return true,p
end
local basePlan=P.Plan
function P:Plan(g,seed)
    local ok,err=basePlan(self,g,seed);if not ok then return ok,err end
    return H:Plan(g,seed)
end

-- Protect two unique actors within the existing global ceiling; do not consume
-- any of the 16-per-floor wanderer replacement reservations.
local W=LOD.WanderingDirector
local baseReserve=W and W.GetDeficitReservation
if baseReserve then
    function W:GetDeficitReservation(...)
        local h=R.State and R.State.NeilHunt
        return baseReserve(self,...) + ((h and h.started) and 0 or 2)
    end
end
function H:Start()
    local s=R.State;local g=s and s.Graph
    if not g or not s.BuildReady or s.Failed or s.LevelCleared or not s.GatesOpen[3] then return false end
    local meta=g.Progression.Hunt;if not meta then return false end
    local h=s.NeilHunt
    if h and h.started then return true end
    local reserve=W and W.GetDeficitReservation and math.max(0,W:GetDeficitReservation()-2) or 0
    if LOD.EncounterDirector:GetActiveCount()+reserve+2>EC.ActiveHostileCeiling then return false end
    h={seed=s.LevelSeed,neilCell=meta.neilCell,started=false}
    local pair={}
    for i,id in ipairs({"neil","brute"}) do
        local ent=ents.Create("lod_hostile")
        if not IsValid(ent) then for _,v in ipairs(pair) do if IsValid(v) then v:Remove() end end;return false end
        local c=i==1 and meta.neilCell or meta.bruteCell
        ent.LODArchetypeId=id;ent.LODHomeCellKey=key(c)
        ent.LODEncounterId="neil_hunt";ent.LODEncounterOrdinal=900000+i
        ent.LODActivated=true;ent.LODMajorThreat=true;ent.majorThreat=true
        ent:SetPos(N:CellCenter(c));ent:Spawn()
        if not IsValid(ent) then for _,v in ipairs(pair) do if IsValid(v) then v:Remove() end end;return false end
        LOD.EnemyVariance:Apply(ent)
        LOD.HostileMotionV2:SnapSpawn(ent)
        if id=="neil" then ent:SetColor(Color(70,220,95)) end
        pair[#pair+1]=ent
    end
    h.neil,h.brute=pair[1],pair[2];h.started=true;s.NeilHunt=h
    for _,e in ipairs(pair) do LOD.EncounterDirector.Entities[#LOD.EncounterDirector.Entities+1]=e end
    P:Announce("FIND NEIL AND THE BLACK KEYCARD — THE BRUTE IS HIS BODYGUARD")
    P:SyncAll();log("NEIL_HUNT_START",{seed=h.seed,neil=h.neil:EntIndex(),brute=h.brute:EntIndex()})
    return true
end

function H:Blocked(g)
    -- Hunt never enters the boss reservation, even after Black opens while a
    -- surviving Brute is still alive. Checkpoint cells remain legal transit.
    return {[g.Progression.Gates[4].edgeKey]=true,[g.Progression.JailEdge.edgeKey]=true}
end
function H:Threats(g)
    local heroes,starts={},{}
    for _,p in ipairs(player.GetAll()) do if activeHero(p) then
        local c=currentCell(p,g)
        if c and g.Cells[key(c)] then heroes[#heroes+1]=p;starts[#starts+1]=key(c) end
    end end
    return heroes,self:Walk(g,starts,self:Blocked(g),true)
end
function H:Escape(ent,g,threats)
    local c=currentCell(ent,g);if not c then return nil end
    local d=self:Walk(g,{key(c)},self:Blocked(g),true)
    local best,score,other,travel
    for _,k in ipairs(sorted(d)) do
        local v=threats[k]
        local different=g.Cells[k].z~=c.z and 1 or 0
        if v and (not score or v>score or (v==score and different>other)
            or (v==score and different==other and d[k]<travel)) then
            best,score,other,travel=k,v,different,d[k]
        end
    end
    return best
end
function H:Route(ent,g,destination)
    if not destination then return end
    local waypoint=ent:_AdvanceWaypoint()
    -- Finish the current canonical edge (especially stairs) before recompiling;
    -- repeatedly recentering a partially travelled cell causes oscillation.
    if waypoint then
        if ent.LODHuntPathDestination~=destination and not waypoint.stair then
            ent.LODWaypoints={waypoint};ent.LODWaypointIndex=1
        end
        return
    end
    local c=currentCell(ent,g);if not c then return end
    if key(c)==destination then ent.LODWaypoints={};ent.LODWaypointIndex=1;return end
    local d,prev=self:Walk(g,{key(c)},self:Blocked(g),true)
    if not d[destination] then return end
    local path,k={},destination
    while k do table.insert(path,1,g.Cells[k]);k=prev[k] end
    ent.LODWaypoints=N:PathToWaypoints(g,path);ent.LODWaypointIndex=1;ent.LODHuntPathDestination=destination
end
function H:SetPhase(ent,phase)
    if ent.LODBrutePhase==phase then return end
    ent.LODBrutePhase=phase;ent:SetNW2String("LOD_BrutePhase",phase)
    log("BRUTE_PHASE",{phase=phase,entity=ent:EntIndex()})
end
function H:CancelCharge(ent)
    ent.LODBruteCharge=nil;self:SetPhase(ent,"escort")
end
function H:Impact(ent,now,wall)
    ent.LODBruteCharge=nil;ent.LODNextAttack=now+(ent.LODConfig.meleeCooldown or C.cooldown)
    if wall then
        ent.LODBruteStunUntil=now+C.wallStun
        self:SetPhase(ent,"stunned");ent:EmitSound("physics/concrete/boulder_impact_hard1.wav")
    else self:SetPhase(ent,"recover") end
    LOD.HostileMotionV2:Stop(ent)
end
function H:Damage(ent,target)
    if not living(ent) or not activeHero(target) then return end
    local rolls=LOD.CombatRolls
    local profile=rolls.HostileDamageProfiles.brute
    local contract=rolls:RollHostileAttack(ent,profile,ent.LODConfig.meleeDamage)
    local amount=rolls:ResolveActorDamage(contract,ent,target,{physical=true,melee=true,authoredScale=contract.scale})
    local info=LOD.NewDamageInfo();info:SetAttacker(ent);info:SetInflictor(ent)
    info:SetDamage(amount);info:SetDamageType(DMG_CLUB);info:SetDamagePosition(target:WorldSpaceCenter())
    LOD.RPGStatusElements:AttachDamageContext(info,{physical=true,melee=true,attackEvent=contract.attackEvent,
        damageContract=contract,actorDamageResolved=true})
    rolls:QueueDamageReport(info,function(final)
        contract.final=final;rolls:_Send(target,1,rolls:_HostileRollText(contract,ent,target))
    end)
    target:TakeDamageInfo(info)
end
function H:BeginCharge(ent,target,g,now)
    local waypoint=ent.LODWaypoints and ent.LODWaypoints[ent.LODWaypointIndex or 1]
    if waypoint and waypoint.stair then return false end
    local a,b=currentCell(ent,g),currentCell(target,g)
    if not a or not b or a.z~=b.z or (g.CellTags[key(b)] or {}).safe then return false end
    if math.abs(ent:GetPos().z-N:CellCenter(a).z)>12 then return false end
    local direction=target:GetPos()-ent:GetPos();direction.z=0
    local distance=direction:Length()
    if distance<C.minimumChargeRange or distance>(ent.LODConfig.fireRange or C.chargeRange) then return false end
    local tr=util.TraceLine({start=ent:WorldSpaceCenter(),endpos=target:WorldSpaceCenter(),mask=MASK_SHOT,filter=ent})
    if tr.Hit and tr.Entity~=target then return false end
    local windup=ent.LODConfig.burstTelegraph or C.windup
    local speed=C.chargeSpeed*(ent.LODVariance and ent.LODVariance.speedScale or 1)
    ent.LODBruteCharge={direction=direction:GetNormalized(),ready=now+windup,
        finish=now+windup+C.chargeSeconds,last=now,hit={},speed=speed}
    -- A charge can end midway along a corridor. Recompile from its actual end
    -- cell instead of resuming an obsolete route across walls or gates.
    ent.LODWaypoints={};ent.LODWaypointIndex=1;ent.LODHuntPathDestination=nil
    ent:SetNW2Vector("LOD_BruteDirection",ent.LODBruteCharge.direction)
    ent:SetNW2Float("LOD_BruteReady",now+windup)
    ent:SetNW2Float("LOD_BruteTravel",speed*C.chargeSeconds)
    self:SetPhase(ent,"windup");ent:EmitSound("NPC_AntlionGuard.Anger")
    return true
end
function H:ChargeTick(ent,g,heroes,now)
    local q=ent.LODBruteCharge;if not q then return false end
    local motion=LOD.HostileMotionV2
    if now<q.ready then motion:Stop(ent);return true end
    if now>=q.finish then self:Impact(ent,now,false);return true end
    if ent.LODBrutePhase~="charge" then q.last=now;self:SetPhase(ent,"charge");ent:EmitSound("NPC_AntlionGuard.Roar") end
    local dt=math.Clamp(now-q.last,0,0.1);q.last=now
    local speed=q.speed or C.chargeSpeed
    local from=ent:GetPos();local to=from+q.direction*speed*dt
    local a,b=currentCell(ent,g),N:WorldToCell(g,to)
    if not a or not b or a.z~=b.z or (key(a)~=key(b) and
        (not a.neighbors[key(b)] or self:Blocked(g)[edge(key(a),key(b))] or not N:CanTraverse(g,key(a),key(b)))) then
        self:Impact(ent,now,true);return true
    end
    -- Swept, fixed locomotion hull. Never rebuild physics or alter wall geometry.
    local tr=util.TraceHull({start=from+Vector(0,0,4),endpos=to+Vector(0,0,4),
        mins=Vector(-16,-16,0),maxs=Vector(16,16,68),mask=MASK_NPCSOLID,
        filter=function(e) return e~=ent and not e.LODHostile and not e:IsPlayer() end})
    local finish=tr.Hit and (tr.HitPos-Vector(0,0,4)) or to
    ent:SetPos(finish);motion:FaceToward(ent,finish+q.direction*100)
    ent.LODMotionLastUpdate=now;ent.LODMotionMode="charge"
    ent.LODMotionVelocity=q.direction*speed;ent.LODMotionSpeed=speed
    local size=ent.LODVariance and ent.LODVariance.size or 1
    local width,height=math.max(8,24*size),math.max(24,64*size)
    for _,p in ipairs(heroes) do
        local pc=currentCell(p,g)
        if activeHero(p) and pc and pc.z==a.z and not (g.CellTags[key(pc)] or {}).safe and not q.hit[p] then
            local hit=util.TraceHull({start=from+Vector(0,0,height/2+4),endpos=finish+Vector(0,0,height/2+4),
                mins=Vector(-width,-width,-height/2),maxs=Vector(width,width,height/2),mask=MASK_SHOT,
                filter=function(e) return e==p or (not e.LODHostile and not e:IsPlayer()) end})
            if hit.Entity==p then
                q.hit[p]=true;self:Damage(ent,p)
                if not living(ent) then return true end
            end
        end
    end
    if tr.Hit then self:Impact(ent,now,true) end
    return true
end

function H:Tick(ent)
    if ent.LODArchetypeId~="neil" and ent.LODArchetypeId~="brute" then return false end
    local s=R.State;local g=s and s.Graph;local h=s and s.NeilHunt
    local motion,now=LOD.HostileMotionV2,CurTime()
    if not living(ent) or not h or (ent~=h.neil and ent~=h.brute) or h.seed~=s.LevelSeed
        or s.Failed or s.LevelCleared or s.SimulationFrozen then
        self:CancelCharge(ent);motion:Stop(ent);return true
    end
    local status=LOD.RPGStatusElements
    if motion:HoldHitStun(ent,now) or (status and not status:CanMoveVoluntarily(ent)) then
        self:CancelCharge(ent);motion:Stop(ent);return true
    end
    if ent==h.brute and status and status.HandleAIFlee and status:HandleAIFlee(ent,g,motion) then
        self:CancelCharge(ent);return true
    end
    local heroes,threats
    if not h.nextThreat or now>=h.nextThreat then
        h.heroes,h.threats=self:Threats(g);h.nextThreat=now+EC.TargetRefreshSeconds
    end
    heroes,threats=h.heroes,h.threats
    if #heroes==0 then self:CancelCharge(ent);motion:Stop(ent);return true end
    local c=currentCell(ent,g);if not c then motion:Stop(ent);return true end
    if ent==h.neil then
        h.neilCell={x=c.x,y=c.y,z=c.z}
        if h.lastObjective~=key(c) and now>=(h.nextSync or 0) then
            h.lastObjective=key(c);h.nextSync=now+0.5;P:SyncAll()
        end
        if now>=(ent.LODHuntRouteAt or 0) then
            ent.LODHuntRouteAt=now+EC.RouteRefreshSeconds
            ent.LODHuntDestination=self:Escape(ent,g,threats)
        end
        self:Route(ent,g,ent.LODHuntDestination)
    else
        if now<(ent.LODBruteStunUntil or 0) then motion:Stop(ent);return true end
        if status and not status:CanInitiateAttack(ent) then self:CancelCharge(ent) end
        if self:ChargeTick(ent,g,heroes,now) then return true end
        local target
        for _,p in ipairs(heroes) do if activeHero(p) and (not target or ent:GetPos():DistToSqr(p:GetPos())<ent:GetPos():DistToSqr(target:GetPos())) then target=p end end
        if target and not h.defendCell and now>=(ent.LODNextAttack or 0) and (not status or status:CanInitiateAttack(ent))
            and self:BeginCharge(ent,target,g,now) then motion:Stop(ent);return true end
        local destination=ent.LODHuntDestination
        if now>=(ent.LODHuntRouteAt or 0) then
            ent.LODHuntRouteAt=now+EC.RouteRefreshSeconds
            destination=nil
            if living(h.neil) then
                local nc=currentCell(h.neil,g);local nk=key(nc)
                if h.defendCell then
                    destination=h.defendCell;self:SetPhase(ent,"defend")
                    if key(c)==destination then h.defendCell=nil end
                elseif nk then
                    self:SetPhase(ent,"escort")
                    local band=self:Walk(g,{nk},self:Blocked(g),true)
                    if band[key(c)] and band[key(c)]>=1 and band[key(c)]<=2 then destination=key(c)
                    else
                        local own=self:Walk(g,{key(c)},self:Blocked(g),true);local best
                        for _,k in ipairs(sorted(band)) do if band[k]>=1 and band[k]<=2 and own[k] and (not best or own[k]<best) then destination=k;best=own[k] end end
                    end
                end
            elseif target then destination=key(currentCell(target,g));self:SetPhase(ent,"pursue") end
            ent.LODHuntDestination=destination
        end
        self:Route(ent,g,destination)
    end
    local waypoint=ent:_AdvanceWaypoint()
    if waypoint then ent:_SetActivity(ACT_RUN);motion:MoveToward(ent,waypoint)
    else ent:_SetActivity(ACT_IDLE);motion:Stop(ent) end
    return true
end

function H:NeilDamaged(ent,amount)
    local s=R.State;local h=s and s.NeilHunt
    if not h or h.dead or ent~=h.neil or amount<=0 or h.seed~=s.LevelSeed then return end
    h.nextThreat=0;ent.LODHuntRouteAt=0
    local c=currentCell(ent,s.Graph);h.defendCell=key(c)
    if living(h.brute) then self:CancelCharge(h.brute);h.brute.LODHuntRouteAt=0 end
    log("NEIL_DEFENSE_TRIGGER",{cell=h.defendCell,damage=amount})
end
hook.Add("PostEntityTakeDamage","LOD_NeilDefense",function(ent,info,took)
    if took then H:NeilDamaged(ent,info:GetDamage()) end
end)
function H:NeilKilled(ent)
    local s=R.State;local h=s and s.NeilHunt
    if not h or ent~=h.neil or h.dead or h.seed~=s.LevelSeed or s.Failed or s.LevelCleared then return end
    h.dead=true;h.dropPos=Vector(ent:GetPos().x,ent:GetPos().y,ent:GetPos().z)
    h.dropCell=table.Copy(currentCell(ent,s.Graph) or h.neilCell)
    s.ObjectiveStage=S.TAKE_BLACK_KEYCARD
    -- No native creation/removal inside the engine damage callback.
    timer.Simple(0,function() if R.State==s and s.NeilHunt==h then H:EnsureBlackCard() end end)
    P:Announce("NEIL DEFEATED — TAKE THE BLACK KEYCARD");P:SyncAll()
end
hook.Add("OnNPCKilled","LOD_NeilBlackCard",function(ent)
    if ent.LODArchetypeId=="brute" then H:CancelCharge(ent) end
    H:NeilKilled(ent)
end)
function H:EnsureBlackCard()
    local s=R.State;local h=s and s.NeilHunt
    if not h or not h.dead or h.seed~=s.LevelSeed or s.Failed or s.LevelCleared or s.Cards[4] then return end
    if IsValid(h.card) then return h.card end
    local e=ents.Create("lod_keycard");if not IsValid(e) then return end
    e:SetCardIndex(4);e.LODNeilDeathSeed=h.seed
    e:SetPos(h.dropPos+Vector(0,0,PC.KeycardHeight));e:Spawn()
    if not IsValid(e) then return end
    h.card=e;LOD.MazeBuilder:_Register(e)
    log("NEIL_BLACK_CARD_DROP",{seed=h.seed,entity=e:EntIndex()});return e
end
function H:CollectBlackCard(ply,ent)
    local s=R.State;local h=s and s.NeilHunt
    if not h or not h.dead or not IsValid(ent) or ent~=h.card or ent.LODNeilDeathSeed~=s.LevelSeed
        or h.seed~=s.LevelSeed or s.Failed or s.LevelCleared or s.Cards[4]
        or s.ObjectiveStage~=S.TAKE_BLACK_KEYCARD or not activeHero(ply) then return false end
    if ply:NearestPoint(ent:GetPos()):DistToSqr(ent:GetPos())>PC.KeycardTriggerRadius^2 then return false end
    s.Cards[4]=true;s.ObjectiveStage=S.OPEN_BLACK_GATE
    P:Announce("BLACK KEYCARD ACQUIRED — K / KEY");P:SyncAll();return true
end
local nextService=0
hook.Add("Think","LOD_NeilHuntService",function()
    if CurTime()<nextService then return end;nextService=CurTime()+0.25
    local s=R.State
    if not s or s.Failed or s.LevelCleared or s.SimulationFrozen or not s.BuildReady then return end
    if s.ObjectiveStage==S.FIND_NEIL then H:Start() end
    if s.ObjectiveStage==S.TAKE_BLACK_KEYCARD then H:EnsureBlackCard() end
end)
concommand.Add("lod_neil_brute_status",function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local s=R.State;local h=s and s.NeilHunt
    print("[LOD HUNT] stage="..tostring(s and s.ObjectiveStage).." started="..tostring(h and h.started)
        .." neilAlive="..tostring(h and living(h.neil)).." bruteAlive="..tostring(h and living(h.brute))
        .." card="..tostring(s and s.Cards[4]).." blackGate="..tostring(s and s.GatesOpen[4]))
end)

-- Explicit developer shortcut through the three existing security stages.
-- Uses production collection/gate transitions and never grants Black or Jail.
concommand.Add("lod_neil_brute_testkit",function(ply)
    local cv=GetConVar("lod_developer_mode")
    if not cv or not cv:GetBool() or not activeHero(ply) or not ply:IsAdmin()
        or not LOD.Equipment:CanAct(ply) then return end
    local s=R.State
    if not s.Graph or not s.BuildReady or s.Failed or s.LevelCleared or s.SimulationFrozen then return end
    if s.ObjectiveStage==S.FIND_NEIL then
        H:Start();ply:ChatPrint("Follow the objective to Neil; the original hunt is still active.");return
    end
    if s.ObjectiveStage>6 then ply:ChatPrint("This dungeon's hunt has already progressed; no replacement pair is spawned.");return end
    local gates={}
    for _,e in ipairs(ents.FindByClass("lod_gate")) do gates[e:GetGateIndex()]=e end
    for i=1,3 do if not IsValid(gates[i]) then ply:ChatPrint("Gate entities are not ready.");return end end
    R:MarkUnranked("neil_brute_testkit")
    for i=1,3 do
        if not s.Cards[i] and not P:CollectCard(i,ply) then return end
        if not s.GatesOpen[i] and not P:TryOpenGate(i,ply,gates[i]) then return end
    end
    for _,e in ipairs(ents.FindByClass("lod_keycard")) do
        if e:GetCardIndex()<=3 then e:Remove() end
    end
    ply:ChatPrint("Neil/Brute hunt opened. Follow the minimap objective; kill Neil and collect his Black Keycard. Hostile reserves remain enforced.")
end)
