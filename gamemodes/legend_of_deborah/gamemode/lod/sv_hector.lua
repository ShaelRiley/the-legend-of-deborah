-- Hector owns encounter choreography, never another HP, reward or rescue system.
LOD.Hector=LOD.Hector or {}
local H=LOD.Hector
local R,P,W,N=LOD.RunManager,LOD.ProgressionDirector,LOD.Warden,LOD.MazeNavigator
local C={reveal=3,warning=1,crowbarWarning=1.5,bombFuse=3,radius=180,maxHazards=12,
    syncGap=.2,shotGap=.25,recovery={2.2,1.6,1}}
H.Config=C
H.Profiles={orb={label="HECTOR MISSILE",source="magic",magicDamage=true,count=2,sides=6,bonus=2,reference=9},
    bomb={label="HECTOR BOMB",source="blast",count=3,sides=6,bonus=2,reference=12.5},
    crowbar={label="TITANIC CROWBAR",source="melee",count=2,sides=4,bonus=3,reference=8},
    villain={label="VILLAIN OF LORE",source="magic",magicDamage=true,count=2,sides=6,bonus=2,reference=9}}
LOD.Config.Encounter.Archetypes.hector={class="lod_hostile",name="Hector — Director's Heart",
    model="models/monk.mdl",baseHP=420,speed=0,meleeDamage=8,meleeCooldown=1,
    meleeRange=95,threat=10,activity=ACT_IDLE}
local function key(c) return c and LOD.MazeGenerator.CellKey(c.x,c.y,c.z) end
local function clockLive(s)
    local c=s.CampaignClock
    return not c or not (c.expired or c.scene or c.deadline and SysTime()>=c.deadline)
end
local function log(event,data) if LOD.RPGTestLog then LOD.RPGTestLog:Write(event,data) end end
function H:Current(h)
    local s=R.State
    return h and not h.retired and s==h.state and s.Hector==h and s.Level==20
        and s.Graph==h.graph and s.Graph.Progression==h.progression
        and s.Graph.Progression.Warden==h.arena and s.Warden==h.warden
        and h.warden.actor==h.gordon and h.warden.dead==true
        and s.CampaignEpoch==h.epoch and s.CampaignSeed==h.campaignSeed and s.RunId==h.runId
        and s.LevelSeed==h.seed and s.BuildReady and not s.Failed and not s.LevelCleared
        and clockLive(s)
end
function H:State()
    local s=R.State;local h=s and s.Hector
    if self:Current(h) then return s,h,h.arena end
end
function H:Owned(e)
    local h=e and e.LODHectorEncounter
    return self:Current(h) and h.actor==e and IsValid(e) and e.LODHector==true
        and e.LODArchetypeId=="hector" and h.owned[e]==true
end
function H:Resources(h)
    return IsValid(h.lock) and h.arena.lock.entity==h.lock
        and IsValid(h.jail) and h.progression.JailEdge.entity==h.jail
        and IsValid(h.rescue) and h.state.RescueEntity==h.rescue
end
function H:Live(e)
    local h=e and e.LODHectorEncounter
    return self:Owned(e) and self:Resources(h) and h.stage==2 and not h.death and not e.LODDead
        and not h.state.SimulationFrozen
end
function H:Hero(p,h)
    if not self:Current(h) or h.state.SimulationFrozen or not IsValid(p) or not p:IsPlayer()
        or not p:Alive() or not R:IsActivePlayer(p) or R:IsSoldierControl(p) then return false end
    local ps=R:GetPlayerState(p)
    if not ps or ps.eliminated or ps.deploymentComplete~=true or (ps.lives or 0)<=0 then return false end
    return self:CombatCell(p,h)~=nil
end
function H:CombatCell(p,h)
    -- WorldToCell intentionally falls back to the nearest graph cell. Admission
    -- cannot use that fallback: an outside body must not masquerade as a Hero
    -- in the court. Preserve ordinary jumping over the center's open shaft.
    local pos=p:GetPos();local mc=LOD.Config.Maze
    local x=math.floor((pos.x-mc.Origin.x)/mc.CellSize+(mc.Width+1)*.5+.5)
    local y=math.floor((pos.y-mc.Origin.y)/mc.CellSize+(mc.Height+1)*.5+.5)
    for z=h.arena.center.z+1,h.arena.center.z,-1 do
        local k=LOD.MazeGenerator.CellKey(x,y,z);local c=h.graph.Cells[k]
        if c and h.arena.court[k] and pos.z>=N:CellCenter(c).z-24 then return c end
    end
end
function H:Targets()
    local _,h=self:State();local out={};if not h then return out end
    for _,p in ipairs(player.GetAll()) do
        if self:Hero(p,h) and not (LOD.RPGPerceptionState and LOD.RPGPerceptionState:IsInvisible(p)) then out[#out+1]=p end
    end
    table.sort(out,function(a,b) return a:EntIndex()<b:EntIndex() end)
    return out
end
function H:BindTarget(p)
    local ps=R:GetPlayerState(p)
    return {player=p,ps=ps,identity=ps.identity,spawn=p.LODRunSpawnSerial,life=ps.equipmentLifeSerial}
end
function H:TargetLive(binding,h)
    local p=binding and binding.player
    return binding and self:Hero(p,h) and R:GetPlayerState(p)==binding.ps
        and binding.ps.identity==binding.identity and p.LODRunSpawnSerial==binding.spawn
        and binding.ps.equipmentLifeSerial==binding.life
        and not (LOD.RPGPerceptionState and LOD.RPGPerceptionState:IsInvisible(p))
end
function H:CanDamage(e,info)
    if not self:Live(e) or #self:Targets()==0 then return false end
    local attacker=info:GetAttacker()
    -- The existing combat authority installs this field for credited effects.
    local attribution=e.LODPendingDamageAttribution
    if attribution and IsValid(attribution.attacker) then attacker=attribution.attacker end
    if IsValid(attacker) and not attacker:IsPlayer() and IsValid(attacker.LODOwner) then attacker=attacker.LODOwner end
    return self:Hero(attacker,e.LODHectorEncounter)
end
function H:Protected(p) local _,h=self:State();return not h or not self:Hero(p,h) end
function H:RollAttack(e,kind)
    local profile=self.Profiles[kind]
    return LOD.CombatRolls:RollHostileAttack(e,profile,profile.reference*(e.LODConfig.meleeDamage or 8)/8)
end
function H:Damage(e,p,kind,shared)
    if not self:Live(e) or not self:Hero(p,e.LODHectorEncounter) then return end
    return W.Damage(self,e,p,kind,shared)
end
function H:AllHazards(h) return h.hazards end
function H:AddHazard(h,kind,pos,velocity,target,now,options)
    if not self:Live(h.actor) or #h.hazards>=C.maxHazards then return false end
    if not W.AddHazard(self,h,kind,pos,velocity,target,now) then return false end
    local q=h.hazards[#h.hazards]
    q.encounter=h;q.binding=target and self:BindTarget(target) or nil
    for k,v in pairs(options or {}) do q[k]=v end
    return true
end
function H:ClearAttacks(h)
    h.hazards={};h.pending=nil;h.volley=nil
end
function H:Fail(h,why)
    if not self:Current(h) then return false end
    h.fault=why;self:Cleanup(h)
    R:FailCampaign("Hector encounter unavailable: "..why)
    return false
end
function H:Cleanup(h)
    h=h or (R.State and R.State.Hector);if not h or h.retired then return end
    h.retired=true;self:ClearAttacks(h)
    for e in pairs(h.owned) do if IsValid(e) and e.LODHectorEncounter==h then e:Remove() end end
    if R.State and R.State.Hector==h then R.State.Hector=nil end
    self:Sync()
end
function H:Spawn(h)
    if not self:Current(h) or h.actor or h.spawning then return false end
    h.spawning=true
    local ok,err=pcall(function()
        if not self:Resources(h) then error("arena or rescue entity replaced") end
        local reserve=LOD.WanderingDirector:GetDeficitReservation(h.graph)
        if LOD.EncounterDirector:GetActiveCount()+math.max(0,reserve-1)+1>LOD.Config.Encounter.ActiveHostileCeiling then error("hostile ceiling") end
        local e=ents.Create("lod_hostile")
        if not IsValid(e) then error("core creation failed") end
        h.actor=e;h.owned[e]=true;e.LODHector=true;e.LODHectorEncounter=h
        e.LODHectorParty=h.party;e.LODPushImmune=true
        e.LODArchetypeId="hector";e.LODEncounterId="hector";e.LODEncounterOrdinal=920001
        e.LODHomeCellKey=key(h.arena.center);e.LODActivated=true;e.LODMajorThreat=true;e.majorThreat=true
        e:SetPos(N:CellCenter(h.arena.center));e:Spawn()
        if not self:Owned(e) then error("core replaced during Spawn") end
        LOD.EnemyVariance:Apply(e);LOD.HostileMotionV2:SnapSpawn(e)
        if not self:Owned(e) or e.LODDead or e:Health()<=0 or not e.LODProgressionState then error("core initialization failed") end
        e:SetNW2Bool("LOD_PushImmune",true);e:SetNW2String("LOD_MonsterName","Hector — Director's Heart")
        e:SetColor(Color(210,55,65));e:DrawShadow(false)
        LOD.EncounterDirector.Entities[#LOD.EncounterDirector.Entities+1]=e
        h.stage=1;h.revealUntil=CurTime()+C.reveal;h.nextAttack=h.revealUntil
        P:Announce("HECTOR THE DIRECTOR — ATTACK THE DIRECTOR'S HEART IN THE COURT")
        P:SyncAll();self:Sync()
        hook.Run("LOD_EncounterMusicPressure","warden",3)
        log("HECTOR_REVEAL",{seed=h.seed,party=h.party,maxHP=e:GetMaxHealth()})
    end)
    h.spawning=nil
    if not ok then
        if self:Current(h) then return self:Fail(h,tostring(err)) end
        self:Cleanup(h);return false
    end
    return true
end
function H:AcceptGordonDeath(e)
    local s=R.State;local w=s and s.Warden
    if not s or s.Level~=20 or not s.BuildReady or s.Failed or s.LevelCleared or s.SimulationFrozen
        or not clockLive(s) or not w or w.state~=s or w.graph~=s.Graph or w.epoch~=s.CampaignEpoch
        or w.campaignSeed~=s.CampaignSeed or w.runId~=s.RunId
        or w.seed~=s.LevelSeed or w.actor~=e or w.dead or w.combatDeath or s.Hector
        or not IsValid(e) or e.LODDead or e:Health()>0 then return false end
    w.combatDeath=e
    return true
end
function H:GordonRewardOwned(e)
    local s=R.State;local w=e and e.LODWardenOwner
    return IsValid(e) and e.LODHectorGordon and w and s==w.state and s.Warden==w
        and s.Level==20 and s.Graph==w.graph and s.CampaignEpoch==w.epoch and s.LevelSeed==w.seed
        and s.CampaignSeed==w.campaignSeed and s.RunId==w.runId
        and s.BuildReady and not s.Failed and not s.LevelCleared and clockLive(s)
        and w.actor==e and w.combatDeath==e and e.LODDead and e:Health()<=0
end
function H:OnGordonDefeated(s,w,a,e)
    if s~=R.State or s.Level~=20 or s.Hector or not w.dead or w.actor~=e
        or w.combatDeath~=e or not IsValid(e) or not e.LODDead or e:Health()>0 or w.graph~=s.Graph or w.state~=s then return false end
    local party=0;for _,p in ipairs(player.GetAll()) do if R:IsActivePlayer(p) then party=party+1 end end
    local h={state=s,graph=s.Graph,progression=s.Graph.Progression,arena=a,warden=w,gordon=e,
        epoch=s.CampaignEpoch,campaignSeed=s.CampaignSeed,runId=s.RunId,seed=s.LevelSeed,
        lock=a.lock.entity,jail=s.Graph.Progression.JailEdge.entity,rescue=s.RescueEntity,
        owned={},hazards={},stage=0,phase=1,ordinal=0,party=math.Clamp(party,1,4)}
    s.Hector=h;s.ObjectiveStage=P.Stages.DEFEAT_HECTOR
    timer.Simple(0,function()
        if not H:Current(h) then return end
        -- Only Gordon's exact owned clones are retired; no broad arena purge.
        for _,clone in ipairs(w.clones or {}) do
            local actor=clone.actor
            if IsValid(actor) and actor.LODWardenOwner==w and w.cloneStates[actor]==clone
                and actor.LODWardenClone==clone.cloneIndex then actor:Remove() end
        end
        H:Spawn(h)
    end)
    return true
end
function H:AcceptDeath(e)
    if not self:Live(e) or e:Health()>0 then return false end
    local h=e.LODHectorEncounter
    h.death={actor=e,encounter=h};self:ClearAttacks(h)
    return true
end
function H:RewardOwned(e)
    local h=e and e.LODHectorEncounter
    return self:Owned(e) and self:Resources(h) and h.death and h.death.actor==e and h.death.encounter==h
        and e.LODDead==true and e:Health()<=0 and not h.fault
end
function H:RescueAllowed(s)
    if s and s.Level~=20 then return true end
    local h=s and s.Hector
    -- Native corpse retirement does not destroy the sealed encounter receipt.
    return self:Current(h) and self:Resources(h) and h.stage==3 and h.death and h.death.encounter==h
        and h.death.actor==h.actor and h.rescueReceipt==h.death and not h.fault
end
function H:ResolveDeath(e)
    if not self:RewardOwned(e) then return false end
    local h=e.LODHectorEncounter
    if h.stage==3 then return true end
    h.stage=3;h.rescueReceipt=h.death
    h.state.ObjectiveStage=P.Stages.TAKE_JAIL_KEY
    local ok=pcall(h.lock.OpenGate,h.lock)
    if not ok or not self:RewardOwned(e) then return self:Fail(h,"owned arena lock could not open") end
    W:EnsureKey();P:Announce("HECTOR DEFEATED — TAKE THE JAIL KEY AT THE ARENA CENTER");P:SyncAll();self:Sync()
    hook.Run("LOD_EncounterMusicPressure","warden",0)
    log("HECTOR_DEFEATED",{seed=h.seed})
    return self:RewardOwned(e)
end
function H:Tick(e)
    if e.LODArchetypeId~="hector" then return false end
    LOD.HostileMotionV2:Stop(e)
    return true -- orchestration uses the existing Think clock, independent of AI coroutines
end
function H:BeginAttack(h,targets,now)
    local patterns={{"orb","crowbar"},{"orb","bomb","villain","crowbar"},{"villain","bomb","orb","crowbar"}}
    h.ordinal=h.ordinal+1
    local pattern=patterns[h.phase];local kind=pattern[(h.ordinal-1)%#pattern+1]
    local status=LOD.RPGStatusElements
    if (kind=="orb" or kind=="villain") and status and not status:CanInitiateMagic(h.actor) then
        h.nextAttack=now+C.syncGap;return
    end
    local count=(kind=="bomb" or kind=="crowbar") and (h.phase==3 and math.min(4,#targets) or 1) or 1
    local marks,bindings={},{}
    for i=1,count do
        local p=targets[(h.ordinal+i-2)%#targets+1]
        -- Snap the mark to its actual graph floor, never to the player's jump height.
        local c=self:CombatCell(p,h);if not c then return end
        local floor=N:CellCenter(c)
        marks[i]=Vector(p:GetPos().x,p:GetPos().y,floor.z+8);bindings[i]=self:BindTarget(p)
    end
    h.pending={kind=kind,ready=now+(kind=="crowbar" and C.crowbarWarning or kind=="bomb" and C.bombFuse or C.warning),
        marks=marks,bindings=bindings}
    h.actor:EmitSound(kind=="crowbar" and "weapons/iceaxe/iceaxe_swing1.wav" or "ambient/energy/weld1.wav",75,80,.7)
end
function H:Release(h,now)
    local pending=h.pending;h.pending=nil
    if not pending then return end
    for _,binding in ipairs(pending.bindings) do if not self:TargetLive(binding,h) then h.nextAttack=now+C.recovery[h.phase];return end end
    if pending.kind=="orb" or pending.kind=="villain" then
        h.volley={kind=pending.kind,binding=pending.bindings[1],remaining=4,next=now}
    else
        for _,pos in ipairs(pending.marks) do
            self:AddHazard(h,"bomb",pos,vector_origin,nil,now,{damageKind=pending.kind,radius=C.radius,expires=now,
                groundBindings=pending.bindings})
        end
    end
    h.nextAttack=now+C.recovery[h.phase]+(h.volley and 3*C.shotGap or 0)
end
function H:Step(now)
    local s,h=self:State();if not h then return end
    if h.stage==0 then return end -- deferred creation owns this phase
    if not self:Resources(h) then self:Fail(h,"arena or rescue entity lost");return end
    if h.stage==3 then return end
    if not self:Owned(h.actor) then self:Fail(h,"owned core lost");return end
    if h.death then return end -- shared native corpse service resolves the receipt
    if h.actor.LODDead or h.actor:Health()<=0 then self:Fail(h,"unreceipted core death");return end
    local targets=self:Targets()
    local dt=math.Clamp(now-(h.lastTick or now),0,.1);h.lastTick=now
    if s.SimulationFrozen or #targets==0 then self:ClearAttacks(h);h.nextAttack=now+C.warning;return end
    if h.stage==1 then
        if now<h.revealUntil then return end
        h.stage=2;h.nextAttack=now+C.warning
    end
    local fraction=h.actor:Health()/math.max(1,h.actor:GetMaxHealth())
    local phase=fraction<=.25 and 3 or fraction<=.6 and 2 or 1
    if phase>h.phase then h.phase=phase;self:ClearAttacks(h);h.nextAttack=now+C.warning end
    local kept={}
    for _,q in ipairs(h.hazards) do
        local valid=q.encounter==h and (not q.binding or self:TargetLive(q.binding,h))
        for _,binding in ipairs(q.groundBindings or {}) do valid=valid and self:TargetLive(binding,h) end
        if valid then kept[#kept+1]=q end
    end
    h.hazards=kept
    W.Hazards(self,h,h.actor,targets,dt,now)
    if not self:Live(h.actor) then return end
    local status=LOD.RPGStatusElements
    -- Wind-up is the attack commitment. Shared hit feedback/control prevents
    -- another commitment, but cannot permanently erase every telegraph under
    -- ordinary automatic fire. Already committed ordnance keeps its deadline.
    local interrupted=LOD.HostileMotionV2:HoldHitStun(h.actor,now)
        or (status and not status:CanInitiateAttack(h.actor))
    if h.pending then
        for _,binding in ipairs(h.pending.bindings) do
            if not self:TargetLive(binding,h) then h.pending=nil;h.nextAttack=now+C.warning;break end
        end
    end
    if h.pending and now>=h.pending.ready then self:Release(h,now) end
    local v=h.volley
    if v and not self:TargetLive(v.binding,h) then h.volley=nil;v=nil end
    if v and now>=v.next then
        local target=v.binding.player;local pos=h.actor:WorldSpaceCenter()+Vector(0,0,12)
        local villain=v.kind=="villain";local speed=villain and 620 or 460
        self:AddHazard(h,"orb",pos,(target:WorldSpaceCenter()-pos):GetNormalized()*speed,target,now,
            {damageKind=v.kind,speed=speed,homing=villain and 0 or .45,expires=now+(villain and 3 or 8)})
        v.remaining=v.remaining-1;v.next=now+C.shotGap;if v.remaining<=0 then h.volley=nil end
    end
    if not interrupted and not h.pending and not h.volley and now>=(h.nextAttack or 0) then self:BeginAttack(h,targets,now) end
end
util.AddNetworkString("LOD_HectorState")
local kinds={orb=1,bomb=2,crowbar=3,villain=4}
function H:Sync(recipient)
    local _,h=self:State();local active=h and h.stage>0
    self.sentActive=active==true
    net.Start("LOD_HectorState");net.WriteBool(active==true)
    if active then
        local e=h.actor;net.WriteEntity(IsValid(e) and e or NULL);net.WriteVector(N:CellCenter(h.arena.center))
        net.WriteUInt(h.stage,2);net.WriteFloat(IsValid(e) and e:Health() or 0);net.WriteFloat(IsValid(e) and e:GetMaxHealth() or 1)
        net.WriteUInt(h.phase,2);net.WriteFloat(h.revealUntil or 0)
        local pending=h.pending;net.WriteUInt(pending and kinds[pending.kind] or 0,3);net.WriteFloat(pending and pending.ready or 0)
        net.WriteUInt(pending and #pending.marks or 0,3);for _,pos in ipairs(pending and pending.marks or {}) do net.WriteVector(pos) end
        net.WriteUInt(#h.hazards,4)
        for _,q in ipairs(h.hazards) do
            net.WriteUInt(kinds[q.damageKind or q.kind],3);net.WriteVector(q.pos);net.WriteVector(q.velocity)
            net.WriteFloat(q.expires);net.WriteFloat(q.radius or C.radius)
        end
    end
    if IsValid(recipient) then net.Send(recipient) else net.Broadcast() end
end
local nextSync=0
hook.Add("Think","LOD_HectorService",function()
    local s=R.State;local h=s and s.Hector
    if h and not H:Current(h) then H:Cleanup(h) end
    local now=CurTime();H:Step(now)
    if now>=nextSync then
        nextSync=now+C.syncGap
        if R.State.Hector or H.sentActive then H:Sync() end
    end
end)
hook.Add("PlayerInitialSpawn","LOD_HectorLateJoin",function(p) H:Sync(p) end)
local cleanup=LOD.MazeBuilder.Cleanup
function LOD.MazeBuilder:Cleanup(...) H:Cleanup();return cleanup(self,...) end
local reset=P.ResetLevelState
function P:ResetLevelState(...) H:Cleanup();return reset(self,...) end
local build=R.BuildCurrentLevel
function R:BuildCurrentLevel(...) H:Cleanup();return build(self,...) end
local fail=R.FailCampaign
function R:FailCampaign(...) H:Cleanup();return fail(self,...) end
