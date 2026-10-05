-- A single exact-lifetime owner for authored bosses. Combat/progression remains
-- the existing RPG, native death, loot, Motion V2 and rescue pipeline.
LOD.BossEncounter=LOD.BossEncounter or {}
local B=LOD.BossEncounter
B.Modules=B.Modules or {};B.Support=B.Support or {};B.Serial=B.Serial or 0
local R,P,N=LOD.RunManager,LOD.ProgressionDirector,LOD.MazeNavigator
local function key(c) return c and LOD.MazeGenerator.CellKey(c.x,c.y,c.z) end
local function copy(p) return Vector(p.x,p.y,p.z) end
local function alive(e) return IsValid(e) and not e.LODDead and e:Health()>0 end
B.Alive=alive;B.Copy=copy;B.Key=key
function B:Register(id,d)
    assert(LOD.BossRegistry.Primary[id] and id~='warden','unregistered primary boss '..id)
    d.id=id;d.name=d.name or LOD.BossRegistry.Names[id];d.deathDuration=d.deathDuration or 4;self.Modules[id]=d;self:RegisterArchetype(id,d,true)
end
function B:RegisterSupport(id,d) d.id=id;self.Support[id]=d;self:RegisterArchetype(id,d,false) end
function B:RegisterArchetype(id,d,primary)
    LOD.Config.Encounter.Archetypes[id]={class='lod_hostile',name=d.name or LOD.BossRegistry.Names[id] or id,
        model=d.model or 'models/Humans/Group01/male_02.mdl',baseHP=d.baseHP or 700,speed=d.speed or 150,
        meleeDamage=d.damage or 8,meleeCooldown=1.4,meleeRange=96,burstDamage=d.damage or 8,threat=10,activity=ACT_RUN}
    local template=table.Copy(LOD.RPG.ArchetypeProgressionTemplates.warden)
    template.archetypeId=id;template.baseXp=primary and 500 or 80;template.boss=primary;template.externalHealthProfileId=id
    LOD.RPG.ArchetypeProgressionTemplates[id]=template
    LOD.CombatRolls.HostileDamageProfiles[id]={label=string.upper(d.name or id),source='melee',count=2,sides=4,bonus=3,reference=8}
end
function B:Current(c)
    local s=R.State
    local clock=s and s.CampaignClock
    if clock and (clock.expired or clock.scene or clock.deadline and SysTime()>=clock.deadline) then return false end
    return c and not c.retired and s==c.run and s.Boss==c and s.Graph==c.graph
        and s.Graph.Progression==c.progression and s.Graph.Progression.Warden==c.arena
        and s.Level==c.level and s.LevelSeed==c.seed and s.CampaignEpoch==c.epoch
        and s.CampaignSeed==c.campaignSeed and s.RunId==c.runId and s.BuildReady
        and not s.Failed and not s.LevelCleared
        and (not c.lock or c.arena.lock.entity==c.lock and IsValid(c.lock))
        and (not c.jail or c.progression.JailEdge.entity==c.jail and IsValid(c.jail))
        and (not c.rescue or s.RescueEntity==c.rescue and IsValid(c.rescue))
end
function B:Live(c) return self:Current(c) and not c.dead and not c.run.SimulationFrozen end
function B:ExactCell(c,pos)
    local mc=LOD.Config.Maze
    local x=math.floor((pos.x-mc.Origin.x)/mc.CellSize+(mc.Width+1)*.5+.5)
    local y=math.floor((pos.y-mc.Origin.y)/mc.CellSize+(mc.Height+1)*.5+.5)
    for z=c.arena.center.z+1,c.arena.center.z,-1 do
        local cell=c.graph.Cells[LOD.MazeGenerator.CellKey(x,y,z)]
        if cell and pos.z>=N:CellCenter(cell).z-24 then return cell end
    end
end
function B:Hero(c,p)
    if not self:Current(c) or not IsValid(p) or not p:IsPlayer() or not p:Alive() or not R:IsActivePlayer(p)
        or R:IsSoldierControl(p) then return false end
    local ps=R:GetPlayerState(p)
    local cell=self:ExactCell(c,p:GetPos())
    return ps and not ps.eliminated and (ps.lives or 0)>0 and ps.deploymentComplete==true
        and cell and c.arena.court[key(cell)]==true
end
function B:Targets(c)
    local out={};for _,p in ipairs(player.GetAll()) do
        if self:Hero(c,p) and not (LOD.RPGPerceptionState and LOD.RPGPerceptionState:IsInvisible(p)) then out[#out+1]=p end
    end
    table.sort(out,function(a,b) local x,y=R:GetPlayerState(a),R:GetPlayerState(b)
        return tostring(x.identity)<tostring(y.identity) end);return out
end
function B:BindSource(c,e)
    if not IsValid(e) then return end
    if e:IsPlayer() then return {actor=e,encounter=c,hero=self:BindTarget(c,e)} end
    LOD.RPGStatusElements:BindActorLife(e)
    return {actor=e,encounter=c,profile=e.LODProgressionState,life=LOD.RPGStatusElements.ActorLives[e]}
end
function B:SourceLive(c,b)
    if b and b.hero then return b.encounter==c and self:Live(c) and self:TargetLive(c,b.hero) end
    return b and b.encounter==c and self:Live(c) and self:Owned(c,b.actor) and alive(b.actor)
        and b.actor.LODProgressionState==b.profile and LOD.RPGStatusElements.ActorLives[b.actor]==b.life
end
function B:BindTargets(c)
    local out={};for _,p in ipairs(self:Targets(c)) do out[p]=self:BindTarget(c,p) end;return out
end
function B:BindTarget(c,p)
    local ps=R:GetPlayerState(p);if not ps then return end
    LOD.RPGStatusElements:BindActorLife(p)
    return {player=p,identity=ps.identity,ps=ps,profile=ps.progressionState,spawn=p.LODRunSpawnSerial,
        life=LOD.RPGStatusElements.ActorLives[p],encounter=c}
end
function B:TargetLive(c,t)
    return t and t.encounter==c and self:Hero(c,t.player) and R:GetPlayerState(t.player)==t.ps
        and t.ps.identity==t.identity and t.ps.progressionState==t.profile and t.player.LODRunSpawnSerial==t.spawn
        and LOD.RPGStatusElements.ActorLives[t.player]==t.life
end
function B:Owned(c,e)
    return self:Current(c) and IsValid(e) and e.LODBossEncounter==c and c.owned[e]~=nil
end
function B:Random(c,stream,lo,hi)
    c.rng=c.rng or {};local r=c.rng[stream]
    if not r then r=LOD.RNG.New(LOD.Seeds.Derive(c.seed,'boss:'..c.id..':'..stream));c.rng[stream]=r end
    return r:Int(lo,hi)
end
function B:Float(c,stream,lo,hi)
    c.rng=c.rng or {};if not c.rng[stream] then self:Random(c,stream,1,1) end
    return c.rng[stream]:Float(lo,hi)
end
function B:Center(c) return N:CellCenter(c.arena.center)+Vector(0,0,2) end
function B:Point(c,index) return copy(c.points[(math.floor(index or 1)-1)%#c.points+1]) end
function B:Floor(c,pos)
    local cell=self:ExactCell(c,pos)
    if not cell or not c.arena.court[key(cell)] then return end
    return Vector(pos.x,pos.y,N:CellCenter(cell).z+2)
end
function B:SafePoint(c,pos)
    local floor=self:Floor(c,pos);if not floor then return end
    local tr=util.TraceHull({start=floor,endpos=floor,mins=Vector(-16,-16,0),maxs=Vector(16,16,72),mask=MASK_NPCSOLID,
        filter=function(e) return not e.LODHostile and not e:IsPlayer() end})
    if not tr.StartSolid and not tr.AllSolid and not tr.Hit then return floor end
end
function B:ValidateRoutes(c,positions,radius)
    -- A bounded baseline-Hero clearance graph, not a center-cell approximation.
    -- Nine samples per authored court cell retain alternate aisle routes; every
    -- edge is checked against expanded solid footprints, including offset props.
    local obstacles={};radius=math.max(8,radius or 32)
    for _,o in ipairs(c.objects or {}) do if not o.retired and o.spec.solid then
        obstacles[#obstacles+1]={pos=o.pos,r=(o.spec.radius or 24)+18}
    end end
    for _,pos in ipairs(positions or {}) do
        local cell=self:ExactCell(c,pos);if not cell or not c.arena.court[key(cell)] then return false end
        obstacles[#obstacles+1]={pos=pos,r=radius+18}
        for _,o in ipairs(c.objects or {}) do if not o.retired and o.spec.use
            and math.abs(o.pos.z-pos.z)<100 and o.pos:DistToSqr(pos)<(radius+40)^2 then return false end end
    end
    local function blocked(a,b)
        for _,o in ipairs(obstacles) do if math.abs(a.z-o.pos.z)<100 and math.abs(b.z-o.pos.z)<100 then
            local d=b-a;local n=d:LengthSqr();local t=n>0 and math.Clamp((o.pos-a):Dot(d)/n,0,1) or 0
            local nearest=a+d*t;local delta=nearest-o.pos;delta.z=0
            if delta:LengthSqr()<o.r*o.r then return true end
        end end
        return false
    end
    local cells={};for k in pairs(c.arena.court) do cells[k]=c.graph.Cells[k] end
    cells[key(c.arena.entry)]=c.graph.Cells[key(c.arena.entry)]
    local nodes,byCell={},{};local offsets={-96,0,96}
    local keys={};for k in pairs(cells) do keys[#keys+1]=k end;table.sort(keys)
    for _,k in ipairs(keys) do local center=N:CellCenter(cells[k])+Vector(0,0,2);local list={};byCell[k]=list
        for ix,dx in ipairs(offsets) do for iy,dy in ipairs(offsets) do
            local pos=center+Vector(dx,dy,0)
            if not blocked(pos,pos) then local node={pos=pos,k=k,x=ix,y=iy};nodes[#nodes+1]=node;list[ix..':'..iy]=#nodes end
        end end
    end
    local start=byCell[key(c.arena.entry)] and byCell[key(c.arena.entry)]['2:2'];if not start then return false end
    local seen={[start]=true};local queue={start};local at=1
    local function visit(a,index)
        if index and not seen[index] and not blocked(a.pos,nodes[index].pos) then seen[index]=true;queue[#queue+1]=index end
    end
    while queue[at] do local node=nodes[queue[at]];at=at+1;local list=byCell[node.k]
        for _,d in ipairs({{-1,0},{1,0},{0,-1},{0,1}}) do visit(node,list[(node.x+d[1])..':'..(node.y+d[2])]) end
        local cell=cells[node.k]
        for nk in pairs(cell.neighbors) do local other=cells[nk];local target=byCell[nk]
            if other and target then
                if other.z~=cell.z then
                    if node.x==2 and node.y==2 then visit(node,target['2:2']) end
                elseif other.x>cell.x and node.x==3 then visit(node,target['1:'..node.y])
                elseif other.x<cell.x and node.x==1 then visit(node,target['3:'..node.y])
                elseif other.y>cell.y and node.y==3 then visit(node,target[node.x..':1'])
                elseif other.y<cell.y and node.y==1 then visit(node,target[node.x..':3']) end
            end
        end
    end
    -- Every authored anchor and every optional/mandatory use point needs an
    -- approachable reachable node, not merely an unrelated path to the jail.
    local required={}
    local anchors=c.requiredPoints or (c.id=='button' and (c.data.pedestals or c.points)) or {}
    for _,v in ipairs(anchors) do required[#required+1]={pos=v,range=105} end
    if c.data.safe then required[#required+1]={pos=c.data.safe,range=105} end
    for _,p in ipairs(self:Targets(c)) do required[#required+1]={pos=p:GetPos(),range=150} end
    required[#required+1]={pos=N:CellCenter(c.progression.JailEdge.beforeCell),range=150}
    for _,o in ipairs(c.objects or {}) do if not o.retired and o.spec.use then required[#required+1]={pos=o.pos,range=105} end end
    for _,q in ipairs(required) do
        local reachable=false;local cell=self:ExactCell(c,q.pos);local list=cell and byCell[key(cell)]
        for _,index in pairs(list or {}) do local delta=nodes[index].pos-q.pos;delta.z=0
            if seen[index] and delta:LengthSqr()<=q.range*q.range and not blocked(nodes[index].pos,q.pos) then reachable=true;break end
        end
        -- A solid decorative center may itself be occupied, but its cell still
        -- needs an approach. Interactable anchors do not receive this exception.
        if not reachable and q.range==150 then for _,index in pairs(list or {}) do if seen[index] then reachable=true;break end end end
        if not reachable then return false end
    end
    return true
end
function B:Cue(c,id,pos)
    local names={honk=true,boing=true,clang=true,rumble=true}
    if self:Current(c) and names[id] and sound and sound.Play then sound.Play('legend_of_deborah/boss/'..id..'.wav',pos or self:Center(c),75,100,.7) end
end
if resource and resource.AddFile then for _,id in ipairs({'honk','boing','clang','rumble'}) do resource.AddFile('sound/legend_of_deborah/boss/'..id..'.wav') end end
function B:Announce(c,text) if self:Current(c) then c.action=tostring(text):sub(1,160);P:Announce(c.action);self:Log(c,'CUE',{caption=c.action}) end end
function B:Log(c,event,data)
    if LOD.RPGTestLog then data=data or {};data.boss=c.id;data.serial=c.serial;data.phase=c.phase;LOD.RPGTestLog:Write('BOSS_'..event,data) end
end
function B:Later(c,delay,id,fn)
    if not self:Current(c) or type(fn)~='function' or c.cancelling then return false end
    local cosmetic=tostring(id):sub(1,9)=='cosmetic:'
    if c.dead and not cosmetic then return false end
    if not c.pending[id] and table.Count(c.pending)>=64 then return false end
    c.pending[id]={at=CurTime()+math.Clamp(delay or 0,0,60),fn=fn,cosmetic=cosmetic,bindings=c.activeBindings or self:BindTargets(c),sourceBinding=c.activeSourceBinding or self:BindSource(c,c.actor)};return true
end
function B:Cancel(c,id) c.pending[id]=nil end
function B:SetPhase(c,n)
    n=math.Clamp(math.floor(n),1,3);if c.phase==n then return end
    local old=c.phase;c.phase=n
    for id,v in pairs(c.pending) do if not v.cosmetic then c.pending[id]=nil end end
    for e in pairs(c.moves) do self:Stop(c,e) end
    if c.def.Phase then c.def:Phase(c,n,old) end
    self:Announce(c,(c.def.phaseNames or {})[n] or ('PHASE '..n));self:Log(c,'PHASE',{old=old})
end
function B:CanInitiate(c,source,spec)
    source=source or c.actor;spec=spec or {}
    if not self:Live(c) or c.cancelling or not IsValid(source) then return false end
    if c.activeSourceBinding and not self:SourceLive(c,c.activeSourceBinding) then return false end
    if source:IsPlayer() then if not self:Hero(c,source) then return false end
    elseif not self:Owned(c,source) or not alive(source) then return false end
    local status=LOD.RPGStatusElements
    if not status:CanInitiateAttack(source) or CurTime()<math.max(source.LODBossStaggerUntil or 0,source.LODHitStunUntil or 0) then return false end
    if (spec.content or spec.kind=='arc' or spec.magic==true) and not status:CanInitiateMagic(source) then return false end
    return true
end
function B:Stagger(c,seconds,source)
    source=source or c.actor;if c.cancelling or not self:Live(c) or not alive(source) or c.activeSourceBinding and not self:SourceLive(c,c.activeSourceBinding) then return false end
    local now=CurTime();if now<(source.LODBossStaggerGuard or 0) then return false end
    seconds=math.Clamp(seconds or 1,0.2,6);source.LODBossStaggerUntil=now+seconds;source.LODBossStaggerGuard=now+seconds+2
    source.LODHitStunUntil=math.max(source.LODHitStunUntil or 0,now+seconds);self:Stop(c,source)
    self:Warn(c,'VULNERABLE',source:GetPos(),seconds,70);return true
end
function B:Heal(c,amount,actor)
    actor=actor or c.actor;if c.cancelling or not self:Live(c) or not alive(actor) or c.activeSourceBinding and not self:SourceLive(c,c.activeSourceBinding) then return 0 end
    local hp=actor:Health();actor:SetHealth(math.min(actor:GetMaxHealth(),hp+math.max(0,amount or 0)));return actor:Health()-hp
end
function B:SelfDamage(c,amount,reason,actor)
    actor=actor or c.actor;if c.cancelling or not self:Live(c) or not alive(actor) or c.activeSourceBinding and not self:SourceLive(c,c.activeSourceBinding) then return 0 end
    c.selfDamage=c.selfDamage or {};local used=c.selfDamage[actor] or 0
    local cap=actor:GetMaxHealth()*.18;local applied=math.min(math.max(0,amount or 0),cap-used,math.max(0,actor:Health()-1))
    if applied>0 then c.selfDamage[actor]=used+applied;actor:SetHealth(actor:Health()-applied);self:Log(c,'SELF_DAMAGE',{amount=applied,reason=reason}) end
    return applied
end
function B:CountActors(c,role)
    local n=0;for e,r in pairs(c.owned) do if alive(e) and (not role or r==role) then n=n+1 end end;return n
end
function B:SpawnActor(c,id,role,pos,options)
    options=options or {};if not self:Live(c) or c.cancelling then return end
    if role~='primary' and self:CountActors(c)-1>=(c.def.maxAdds or 8) then return end
    if LOD.EncounterDirector:GetActiveCount()+1>LOD.Config.Encounter.ActiveHostileCeiling then return end
    pos=self:SafePoint(c,pos or self:Center(c));if not pos then return end
    local e=ents.Create('lod_hostile');if not IsValid(e) then return end
    local ordinal=c.ordinal+1;e.LODBossEncounter=c;e.LODBossRole=role;e.LODBossManual=options.manual~=false
    e.LODBossParty=c.party;e.LODBossDefinition=self.Support[id] or self.Modules[id]
    e.LODBossAirborne=e.LODBossDefinition and e.LODBossDefinition.arena and e.LODBossDefinition.airborne==true
    if e.LODBossAirborne then
        pos=pos+Vector(0,0,c.arena.flightHeight or 420)
        local lo,hi=B:Hull(e);local tr=util.TraceHull({start=pos,endpos=pos,mins=lo,maxs=hi,mask=MASK_NPCSOLID,filter=e})
        if tr.Hit or tr.StartSolid or tr.AllSolid then e:Remove();return end
    end
    e.LODArchetypeId=id;e.LODEncounterId='boss:'..c.id;e.LODEncounterOrdinal=930000+ordinal
    e.LODHomeCellKey=key(self:ExactCell(c,pos));e.LODActivated=true;e.LODMajorThreat=role=='primary';e.majorThreat=e.LODMajorThreat
    e.LODPushImmune=(e.LODBossDefinition and e.LODBossDefinition.pushScale==0) or false
    c.owned[e]=role;c.actors[#c.actors+1]=e
    local ok,err=pcall(function()
        e:SetPos(pos);e:Spawn();if not IsValid(e) then error('actor spawn invalid') end
        if options.model then e:SetModel(options.model) end
        LOD.EnemyVariance:Apply(e);LOD.HostileMotionV2:SnapSpawn(e)
        if e.LODBossDefinition and not e.LODBossDefinition.hull and util.GetModelBounds then
            local mn,mx=util.GetModelBounds(e:GetModel());local scale=options.scale or e.LODBossDefinition.size or 1
            if mn and mx then e.LODBossHull={mins=Vector(mn.x*scale,mn.y*scale,0),maxs=Vector(mx.x*scale,mx.y*scale,math.max(12,(mx.z-mn.z)*scale))} end
        end
        local lo,hi=B:Hull(e);e:SetCollisionBounds(lo,hi)
        if options.hpFraction then local hp=math.max(1,math.floor(e:GetMaxHealth()*math.Clamp(options.hpFraction,.05,5)));e:SetMaxHealth(hp);e:SetHealth(hp);if e.LODProgressionState then e.LODProgressionState.derivedStats.maxHP=hp end end
        e:SetNW2String('LOD_BossId',c.id);e:SetNW2String('LOD_BossSupportId',role~='primary' and (B.Support[role] and role or id) or '')
        e:SetNW2Int('LOD_BossSerial',c.serial);e:SetNW2String('LOD_MonsterName',options.name or LOD.BossRegistry.Names[id] or (e.LODConfig and e.LODConfig.name) or id)
        e:SetNW2Float('LOD_SizeScale',options.scale or (e.LODBossDefinition and e.LODBossDefinition.size) or 1)
        e:SetNW2Bool('LOD_PushImmune',e.LODPushImmune)
    end)
    if not ok then c.owned[e]=nil;if IsValid(e) then e:Remove() end;self:Log(c,'SPAWN_REJECT',{error=tostring(err)});return end
    c.ordinal=ordinal;LOD.EncounterDirector.Entities[#LOD.EncounterDirector.Entities+1]=e;return e
end
function B:QueueAdd(c,id,role,pos,opts)
    if c.cancelling or not self:Live(c) or #c.addQueue>=16 then return false end
    c.addQueue[#c.addQueue+1]={id=id,role=role,pos=copy(pos),options=opts or {manual=false},expires=CurTime()+30};return true
end
function B:RetireActor(c,e)
    if IsValid(e) and e.LODBossEncounter==c and c.owned[e] then self:Stop(c,e);e.LODBossRetired=true;e:Remove() end
end
function B:ReplacePrimary(c,e)
    if not self:Live(c) or not self:Owned(c,e) or not alive(e) then return false end
    if IsValid(c.actor) then c.owned[c.actor]='retired_primary';c.actor.LODBossRole='retired_primary' end
    c.actor=e;c.primary=e;c.owned[e]='primary';e.LODBossRole='primary';c.savedHP=e:Health();c.savedMax=e:GetMaxHealth();c.savedPos=copy(e:GetPos());return true
end
function B:Prepare()
    local s=R.State;local id=LOD.BossRegistry:Modular(s.Level)
    if not id or not s.Graph or not s.BuildReady or s.Failed or s.LevelCleared or not s.GatesOpen[4] then return false end
    if s.Boss then return self:Current(s.Boss) end
    local d=self.Modules[id];if not d then return false end
    self.Serial=self.Serial+1
    local c={id=id,def=d,serial=self.Serial,run=s,graph=s.Graph,progression=s.Graph.Progression,arena=s.Graph.Progression.Warden,
        epoch=s.CampaignEpoch,campaignSeed=s.CampaignSeed,runId=s.RunId,seed=s.LevelSeed,level=s.Level,
        phase=1,data={},owned={},actors={},objects={},hazards={},pending={},moves={},points={},heroes={},addQueue={},resupply={},ordinal=0}
    c.lock=c.arena.lock.entity;c.jail=c.progression.JailEdge.entity;c.rescue=s.RescueEntity
    s.Boss=c;local keys={};for k in pairs(c.arena.court) do keys[#keys+1]=k end;table.sort(keys)
    -- First eight anchors span the ground court instead of clustering in a
    -- lexicographic column; the rest remain deterministic and include galleries.
    local ground={};for _,k in ipairs(keys) do local cell=c.graph.Cells[k];if cell.z==c.arena.center.z then ground[#ground+1]=cell end end
    local used={};local center=N:CellCenter(c.arena.center)
    for sector=0,7 do
        local dir=Vector(math.cos(sector*math.pi/4),math.sin(sector*math.pi/4),0);local best,score
        for _,cell in ipairs(ground) do local delta=N:CellCenter(cell)-center;local value=delta:Dot(dir)-math.abs(delta.x*dir.y-delta.y*dir.x)*.6
            if not used[key(cell)] and (not score or value>score) then best,score=cell,value end
        end
        if best then used[key(best)]=true;c.points[#c.points+1]=N:CellCenter(best)+Vector(0,0,2) end
    end
    for _,k in ipairs(keys) do if not used[k] then c.points[#c.points+1]=N:CellCenter(c.graph.Cells[k])+Vector(0,0,2) end end
    return true
end
function B:Resupply(c,p)
    local ps=R:GetPlayerState(p);if not ps or c.resupply[ps.identity] then return end
    c.resupply[ps.identity]=true;p:SetHealth(math.min(p:GetMaxHealth(),p:Health()+25));LOD.DiceAmmo:GrantWardenResupply(p)
    LOD.Equipment:Grant(p,'healing_potion',1,'boss_resupply')
end
function B:Commit(c)
    if not self:Live(c) or c.started then return false end
    local party={};for _,p in ipairs(player.GetAll()) do if R:IsActivePlayer(p) and not R:IsSoldierControl(p) then party[#party+1]=p end end
    table.sort(party,function(a,b) return tostring(R:GetPlayerState(a).identity)<tostring(R:GetPlayerState(b).identity) end)
    c.party=math.Clamp(#party,1,4);c.heroes={};c.startedAt=CurTime();c.now=c.startedAt
    for _,p in ipairs(party) do local binding=self:BindTarget(c,p);if binding then
        local weapon=p:GetActiveWeapon();binding.weaponClass=IsValid(weapon) and weapon:GetClass() or nil
        binding.model=p:GetModel();binding.progressionState=table.Copy(binding.profile or {});binding.color=p:GetColor();c.heroes[#c.heroes+1]=binding
    end end
    local e=self:SpawnActor(c,c.id,'primary',self:Center(c),{manual=true})
    if not e then return false end
    local previous={started=c.run.WardenStarted,stage=c.run.ObjectiveStage,checkpoint=c.run.CheckpointPos}
    c.actor=e;c.primary=e;c.started=true;c.run.WardenStarted=true;c.run.ObjectiveStage=P.Stages.DEFEAT_WARDEN
    c.run.CheckpointPos=N:CellCenter(c.arena.entry)+Vector(0,0,12)
    local gate=c.arena.lock.entity;if IsValid(gate) then gate:SetOpened(false);gate:SetNotSolid(false);gate:SetSolid(SOLID_BBOX) end
    local ok,err=pcall(function() if c.def.Start then c.def:Start(c) end end)
    if not ok then
        self:Log(c,'MODULE_ERROR',{error=tostring(err)});self:Cleanup(c,'start_error')
        c.run.WardenStarted=previous.started;c.run.ObjectiveStage=previous.stage;c.run.CheckpointPos=previous.checkpoint
        if IsValid(gate) then gate:OpenGate() end;P:SyncAll();return false
    end
    self:Announce(c,string.upper(c.def.name));P:SyncAll()
    self:Log(c,'COMMIT',{party=c.party,maxHP=e:GetMaxHealth()});return true
end
function B:Join(p,gate)
    local c=R.State.Boss;if not self:Current(c) or gate~=c.arena.lock.entity or not IsValid(p) or not p:Alive() or not R:IsActivePlayer(p) then return false end
    if p:GetPos():DistToSqr(gate:GetPos())>(LOD.Config.Maze.CellSize*.7)^2 then return false end
    if c.dead then gate:OpenGate();return true end
    p:SetPos(N:CellCenter(c.arena.entry)+Vector(0,0,12));self:Resupply(c,p);return true
end
function B:AcceptDeath(e)
    local c=e.LODBossEncounter
    if not self:Owned(c,e) or c.dead or c.run.SimulationFrozen or e.LODDead or e:Health()>0 then return false end
    c.deaths=c.deaths or {};if c.deaths[e] then return false end
    c.deaths[e]={actor=e,encounter=c,role=c.owned[e],serial=c.serial};return true
end
function B:RewardOwned(e)
    local c=e.LODBossEncounter;local q=c and c.deaths and c.deaths[e]
    return self:Current(c) and not e.LODBossRetired and q and q.actor==e and q.encounter==c and e.LODDead and e:Health()<=0
end
function B:Killed(e)
    local c=e and e.LODBossEncounter;if not c or not self:RewardOwned(e) then return end
    local q=c.deaths[e];if q.handled then return end;q.handled=true
    local handled=c.def.ActorKilled and c.def:ActorKilled(c,e,q.role)
    if e~=c.actor or q.role~='primary' or handled then return end
    self:Complete(c,e,'native_death')
end
function B:Complete(c,e,reason)
    if not self:Current(c) or c.dead or e~=c.actor or not self:RewardOwned(e) then return false end
    c.receipt=c.deaths[e];c.dead=true;c.deathAt=CurTime();c.keyAt=c.deathAt+(c.def.deathDuration or 0);c.keyReady=not c.def.deferKey
    c.pending={};c.addQueue={};self:Log(c,'DEFEATED',{reason=reason})
    -- Native collision/entity mutation must wait until the lethal callback returns.
    timer.Simple(0,function()
        if not B:Current(c) or c.receipt~=c.deaths[e] then return end
        B:Clear(c)
        for owned in pairs(c.owned) do if owned~=e and alive(owned) then B:RetireActor(c,owned) end end
        for moving in pairs(c.moves) do B:Stop(c,moving) end
        if c.def.Defeat then c.def:Defeat(c) end
        if not c.keyPosition and c.def.KeyPosition then c.keyPosition=c.def:KeyPosition(c) end
        if IsValid(c.arena.lock.entity) then c.arena.lock.entity:OpenGate() end
        c.run.ObjectiveStage=P.Stages.TAKE_JAIL_KEY
        B:EnsureKey(c)
        local caption=c.def.deathCaption or (string.upper(c.def.name)..' DEFEATED')
        if c.def.deathCaptionDelay then B:Later(c,c.def.deathCaptionDelay,'cosmetic:defeat_caption',function(owner) B:Announce(owner,caption) end)
        else B:Announce(c,caption) end;P:SyncAll()
    end)
    return true
end
function B:EnsureKey(c)
    c=c or R.State.Boss
    if not self:Current(c) or not c.dead or not c.receipt or not c.keyReady or CurTime()<(c.keyAt or 0) or c.run.JailKey then return end
    if IsValid(c.run.JailKeyEntity) then return c.run.JailKeyEntity end
    local pos=c.keyPosition or (c.def.KeyPosition and c.def:KeyPosition(c)) or self:Center(c)
    pos=self:SafePoint(c,pos) or self:Center(c);c.keyPosition=copy(pos)
    local e=P:SpawnJailKey(pos+Vector(0,0,LOD.Config.Progression.KeycardHeight),'boss:'..c.id)
    if IsValid(e) then e.LODBossKeyReceipt=c.receipt;e.LODBossEncounter=c end;return e
end
function B:Cleanup(c,why)
    if not c or c.retired then return end;c.retired=true;c.pending={};c.addQueue={}
    if c.def.Retire then c.def:Retire(c,why) end
    self:Clear(c)
    for _,e in ipairs(c.geometry or {}) do if IsValid(e) and e.LODBossGeometry==c then e:Remove() end end;c.geometry={}
    for e in pairs(c.owned) do if IsValid(e) and e.LODBossEncounter==c then e.LODBossRetired=true;e:Remove() end end
    if R.State.Boss==c then R.State.Boss=nil end;self:Sync()
end
function B:UseDamage(c,amount,p,token)
    if not c.def.useOnly or not self:Live(c) or not self:Hero(c,p) or not alive(c.actor) then return false end
    c.useReceipts=c.useReceipts or {};if c.useReceipts[token] then return false end;c.useReceipts[token]=true
    local info=LOD.NewDamageInfo();info:SetAttacker(p);info:SetInflictor(p);info:SetDamage(math.max(0,amount));info:SetDamageType(DMG_GENERIC)
    -- A successful authored button press is the interaction, not a dodgeable
    -- combat strike. Store progress on canonical entity HP and use native death.
    if LOD.CombatAttributionSystem then LOD.CombatAttributionSystem:Record(c.actor,info) end
    c.actor:SetHealth(math.max(0,c.actor:Health()-math.max(0,amount)))
    if c.actor:Health()<=0 then c.actor:OnKilled(info) end
    return true
end
function B:TickActor(e)
    local c=e.LODBossEncounter;if not c then return false end
    if not self:Owned(c,e) or c.dead or c.run.SimulationFrozen then LOD.HostileMotionV2:Stop(e);return true end
    if e.LODBossManual then LOD.HostileMotionV2:Stop(e);return true end
    return false
end
hook.Add('OnNPCKilled','LOD_ModularBossDeath',function(e) B:Killed(e) end)
hook.Add('KeyPress','LOD_BossPrimaryInput',function(p,k)
    local c=R.State.Boss;if not B:Current(c) or not B:Hero(c,p) then return end
    if k==IN_USE then
        -- Nonblocking mandatory items still need a real native input path.
        -- The nearest visible, front-facing owned object is the sole candidate.
        local chosen,best
        for _,o in ipairs(B:Objects(c)) do if o.spec.use then
            local delta=o.pos-p:EyePos();local distance=p:GetPos():DistToSqr(o.pos)
            local forward=p:GetAimVector()
            if distance<=110^2 and delta:GetNormalized():Dot(forward)>.35 then
                local tr=util.TraceLine({start=p:EyePos(),endpos=o.pos,mask=MASK_SHOT,filter=p})
                if not tr.StartSolid and (not tr.Hit or tr.Entity==o.ent) and (not best or distance<best) then chosen,best=o,distance end
            end
        end end
        if chosen then B:ObjectUse(c,chosen,p) end
    end
    if B:Live(c) and c.def.PrimaryInput then c.def:PrimaryInput(c,p,k) end
end)
function B:DamageGate(target,info)
    local source=info:GetAttacker();local c=target.LODBossEncounter
    if target.LODBossObject then return false end
    if c then
        if not self:Live(c) or not self:Owned(c,target) or not alive(target) then info:SetDamage(0);return true end
        local credit=target.LODPendingDamageAttribution
        local attacker=credit and credit.attacker or source
        if IsValid(attacker) and IsValid(attacker.LODOwner) then attacker=attacker.LODOwner end
        if not self:Hero(c,attacker) then info:SetDamage(0);return true end
        if c.def.useOnly and c.useDamage~=info then info:SetDamage(0);return true end
        if c.def.BeforeDamage and c.def:BeforeDamage(c,target,info)==false then info:SetDamage(0);return true end
    end
    local sc=IsValid(source) and source.LODBossEncounter
    if sc and (not self:Live(sc) or not self:Owned(sc,source) or not alive(source)
        or target:IsPlayer() and not self:Hero(sc,target)) then info:SetDamage(0);return true end
    return false
end
hook.Add('PostEntityTakeDamage','LOD_BossEffectiveDamage',function(e,info,taken)
    local c=IsValid(e) and e.LODBossEncounter
    if not c or not B:Current(c) or not taken or info:GetDamage()<=0 or not c.def.AfterDamage then return end
    c.def:AfterDamage(c,e,info:GetDamage(),info:GetAttacker(),copy(info:GetDamagePosition()))
end)
function B:Quiesce(c,reason)
    if c.paused then return end;c.paused=true;c.constraints={};c.traction={};c.sliding={}
    for id,q in pairs(c.pending) do if not q.cosmetic then c.pending[id]=nil end end
    for _,o in ipairs(c.objects) do if o.projectile then self:RemoveObject(c,o,'pause') end end
    for _,z in ipairs(c.hazards) do z.retired=true end
    for e in pairs(c.moves) do self:Stop(c,e) end
    if c.def.Pause then c.def:Pause(c,reason) end
    self:Log(c,'PAUSED',{reason=reason})
end
function B:Service(now)
    local s=R.State;local c=s and s.Boss
    if c and not self:Current(c) then self:Cleanup(c,'scope');return end
    if not c then self:Prepare();c=s and s.Boss end
    if not c then return end
    c.now=now
    local actors={};for _,e in ipairs(c.actors) do
        if IsValid(e) then actors[#actors+1]=e
        elseif e~=c.actor then c.owned[e]=nil;if c.deaths then c.deaths[e]=nil end end
    end;c.actors=actors
    local dt=math.Clamp(now-(c.lastTick or now),0,.1);c.lastTick=now
    if not c.started then
        for _,p in ipairs(player.GetAll()) do if IsValid(p) and p:Alive() and R:IsActivePlayer(p) then
            local cell=self:ExactCell(c,p:GetPos())
            if cell and key(cell)==key(c.arena.entry) then self:Resupply(c,p)
            elseif self:Hero(c,p) then self:Commit(c);break end
        end end
        return
    end
    local targets=self:Targets(c)
    if c.dead then
        self:ServiceObjects(c,now,dt)
        if c.def.PostDefeat then c.def:PostDefeat(c,now,targets) end
        self:EnsureKey(c)
    elseif s.SimulationFrozen or #targets==0 then self:Quiesce(c,s.SimulationFrozen and 'frozen' or 'no_heroes')
    else
        if c.paused then c.paused=false;c.resumeAt=now+1;self:Log(c,'RESUMED',{}) end
        if now<(c.resumeAt or 0) then return end
        if not IsValid(c.actor) and not (c.deaths and c.deaths[c.actor]) then
            -- A lost native body is not a defeat. Restore exact encounter state
            -- and health rather than roll another boss/reward opportunity.
            if now>=(c.recoverAt or 0) then
                c.recoverAt=now+1;local e=self:SpawnActor(c,c.id,'primary',c.savedPos or self:Center(c),{manual=true})
                if e then c.actor=e;c.primary=e;e:SetMaxHealth(c.savedMax or e:GetMaxHealth());e:SetHealth(c.savedHP or e:GetMaxHealth())
                    if c.def.ActorReplaced then c.def:ActorReplaced(c,e) end;self:Log(c,'BODY_RECOVERED',{}) end
            end
            return
        end
        if alive(c.actor) then
            c.savedHP=c.actor:Health();c.savedMax=c.actor:GetMaxHealth();c.savedPos=copy(c.actor:GetPos())
            c.model=c.actor:GetModel();c.angles=c.actor:GetAngles()
            if not c.def.manualPhase then local f=c.savedHP/math.max(1,c.savedMax)
                local n=f<=.25 and 3 or f<=.6 and 2 or 1;if n>c.phase then self:SetPhase(c,n) end end
        end
        if #c.addQueue>0 then local q=c.addQueue[1]
            if now>=q.expires or self:SpawnActor(c,q.id,q.role,q.pos,q.options) then table.remove(c.addQueue,1) end
        end
        -- Hand-serviced fuse/folder modules must never see stale physical sources.
        for _,o in ipairs(c.objects) do if o.sourceBinding and not o.spec.cosmetic and (o.projectile or not o.spec.permanent and not o.spec.use)
            and not self:SourceLive(c,o.sourceBinding) then self:RemoveObject(c,o,'source_life') end end
        if c.def.Think then c.def:Think(c,now,dt,targets) end
        self:ServiceMoves(c,now,dt);self:ServiceObjects(c,now,dt);self:ServiceZones(c,now)
    end
    local due={};for id,q in pairs(c.pending) do if now>=q.at and (q.cosmetic or not c.paused and not c.dead) then due[#due+1]=id end end
    table.sort(due)
    for _,id in ipairs(due) do local q=c.pending[id];c.pending[id]=nil
        if q and self:Current(c) and (q.cosmetic or self:Live(c) and #targets>0) then local previous,source=c.activeBindings,c.activeSourceBinding;c.activeBindings=q.bindings;c.activeSourceBinding=q.sourceBinding;q.fn(c);c.activeBindings=previous;c.activeSourceBinding=source end
    end
end
util.AddNetworkString('LOD_BossState')
function B:Snapshot(c)
    local e=c.actor
    local visual=c.visual or {bools={},strings={},numbers={}}
    if IsValid(e) then
        visual.color=e:GetColor();visual.size=e:GetNW2Float('LOD_SizeScale',c.def.size or 1)
        for _,k in ipairs({'LOD_Beaver','LOD_MelfGiant','LOD_BDDActive','LOD_BossEngineDamaged','LOD_BossCracked','LOD_BossInverted','LOD_BossVertical','LOD_BossTorn','LOD_BossSectionDetached','LOD_RankAllDrawers','LOD_BossDoorOpen','LOD_CornetteMissingLeft','LOD_CornetteMissingRight','LOD_CornetteCrying','LOD_MookyDamaged','LOD_BossScorched'}) do visual.bools[k]=e:GetNW2Bool(k,false) end
        for _,k in ipairs({'LOD_MelfIdentity','LOD_MelfClass','LOD_MelfWeapon','LOD_BossAction','LOD_BossCycle','LOD_MookyProtectedKnee'}) do visual.strings[k]=e:GetNW2String(k,'') end
        for _,k in ipairs({'LOD_BossHeat','LOD_RankDrawer','LOD_CornetteStrain','LOD_BDDHits'}) do visual.numbers[k]=e:GetNW2Int(k,0) end
        c.visual=visual
    end
    local out={id=c.id,serial=c.serial,name=c.def.name,phase=c.phase,phaseName=(c.def.phaseNames or {})[c.phase],
        health=IsValid(e) and e:Health() or c.savedHP or 0,maximum=IsValid(e) and e:GetMaxHealth() or c.savedMax or 1,
        actor=IsValid(e) and e:EntIndex() or 0,dead=c.dead==true,deathAt=c.deathAt,deathDuration=c.def.deathDuration or 4,
        action=c.data.action or c.action,deathStage=c.data.deathStage or c.deathStage,
        deathTarget=c.data.deathTarget,deathDestination=c.data.deathDestination,
        model=c.model or (IsValid(e) and e:GetModel()) or c.def.model,position=c.savedPos or self:Center(c),angles=c.angles,
        size=visual.size or c.def.size or 1,visual=visual,detail=c.def.Snapshot and c.def:Snapshot(c) or '',received=CurTime(),warnings={},zones={},beacons={}}
    if c.id=='button' then for _,o in ipairs(self:Objects(c,'gauntlet_button')) do if #out.beacons<2 then out.beacons[#out.beacons+1]={pos=o.pos,label=o.spec.useLabel or 'E: PRESS BUTTON'} end end end
    for _,q in ipairs(c.warnings or {}) do if q.expires>CurTime() then out.warnings[#out.warnings+1]={label=q.label,pos=q.pos,start=q.start,expires=q.expires,radius=q.radius,shape=q.shape,finish=q.finish,width=q.width,color=q.color} end end
    for _,z in ipairs(c.hazards) do if not z.retired then out.zones[#out.zones+1]={kind=z.kind,label=z.label,pos=z.pos,ready=z.ready,expires=z.expires,radius=z.radius,shape=z.shape,finish=z.finish,width=z.width,color=z.color} end end
    return out
end
function B:Sync(recipient)
    local c=R.State and R.State.Boss;local active=self:Current(c) and c.started
    local data=active and util.Compress(util.TableToJSON(self:Snapshot(c))) or nil
    if data and #data>32768 then self:Log(c,'SNAPSHOT_REJECT',{bytes=#data});data=nil end
    net.Start('LOD_BossState');net.WriteBool(data~=nil)
    if data then net.WriteUInt(#data,16);net.WriteData(data,#data) end
    if IsValid(recipient) then net.Send(recipient) else net.Broadcast() end
end
local nextStep,nextSync=0,0
hook.Add('Think','LOD_BossEncounterService',function()
    local now=CurTime();if now<nextStep then return end;nextStep=now+.05
    B:Service(now)
    if now>=nextSync then nextSync=now+.2;B:Sync() end
end)
hook.Add('PlayerInitialSpawn','LOD_BossLateJoin',function(p) B:Sync(p) end)
local cleanup=LOD.MazeBuilder.Cleanup
function LOD.MazeBuilder:Cleanup(...) B:Cleanup(R.State and R.State.Boss,'maze_cleanup');return cleanup(self,...) end
local reset=P.ResetLevelState
function P:ResetLevelState(...) B:Cleanup(R.State and R.State.Boss,'reset');return reset(self,...) end
local fail=R.FailCampaign
function R:FailCampaign(...) B:Cleanup(self.State and self.State.Boss,'failure');return fail(self,...) end
-- Preserve structural Warden compatibility without running Gordon choreography
-- in the eighteen authored replacement dungeons.
local W=LOD.Warden
local prepare,commit,join,ensure,state=W.Prepare,W.Commit,W.Join,W.EnsureKey,W.State
function W:Prepare(...) if LOD.BossRegistry:Modular(R.State.Level) then return B:Prepare() end;return prepare(self,...) end
function W:State(...) if LOD.BossRegistry:Modular(R.State.Level) then return end;return state(self,...) end
function W:Commit(...) if LOD.BossRegistry:Modular(R.State.Level) then return B:Commit(R.State.Boss) end;return commit(self,...) end
function W:Join(p,g,...) if LOD.BossRegistry:Modular(R.State.Level) then B:Prepare();return B:Join(p,g) end;return join(self,p,g,...) end
function W:EnsureKey(...) if LOD.BossRegistry:Modular(R.State.Level) then return B:EnsureKey() end;return ensure(self,...) end
function W:CloneCount(level) return LOD.BossRegistry:GordonClones(level) end
function LOD.WardenTurrets:Count(level) return LOD.BossRegistry:GordonTurrets(level) end
concommand.Add('lod_boss_status',function(p)
    if IsValid(p) and not p:IsAdmin() then return end
    local c=R.State.Boss
    print('[LOD BOSS] '..(c and ('id='..c.id..' phase='..c.phase..' serial='..c.serial..' started='..tostring(c.started)..' dead='..tostring(c.dead)..' receipt='..tostring(c.receipt~=nil)..' actors='..B:CountActors(c)..' objects='..#B:Objects(c)..' hazards='..#c.hazards) or ('legacy='..LOD.BossRegistry:Name(R.State.Level))))
end)
concommand.Add('lod_boss_testkit',function(p)
    local cv=GetConVar('lod_developer_mode');local s=R.State
    if not cv or not cv:GetBool() or not IsValid(p) or not p:IsAdmin() or not p:Alive() or not R:IsActivePlayer(p)
        or not LOD.Equipment:CanAct(p) or not s.BuildReady or s.Failed or s.LevelCleared or s.SimulationFrozen then return end
    if not LOD.BossRegistry:Modular(s.Level) then return p:ConCommand('lod_warden_testkit') end
    if s.Boss and s.Boss.started then p:ChatPrint('This boss already exists; no duplicate or reset.');return end
    R:MarkUnranked('boss_testkit')
    for i=1,4 do s.Cards[i]=true;s.GatesOpen[i]=true;local e=s.Graph.Progression.Gates[i].entity;if IsValid(e) then e:OpenGate() end end
    s.ObjectiveStage=P.Stages.ENTER_WARDEN;B:Prepare();p:SetPos(N:CellCenter(s.Boss.arena.entry)+Vector(0,0,12));B:Resupply(s.Boss,p);P:SyncAll()
end)
local reserve=LOD.WanderingDirector.GetDeficitReservation
function LOD.WanderingDirector:GetDeficitReservation(...)
    local n=reserve(self,...);local s=R.State;local id=s and LOD.BossRegistry:Modular(s.Level)
    if not id then return n end
    local c=s.Boss;local d=B.Modules[id]
    local desired=(c and c.dead) and 0 or (1+(d and d.maxAdds or 8))
    -- The retained legacy wrapper reserves one absent Gordon; replace exactly
    -- that reservation with this authored encounter's frozen actor budget.
    return math.max(0,n-1)+math.max(0,desired-(c and B:CountActors(c) or 0))
end
concommand.Add('lod_boss_test_level',function(p,_,args)
    local cv=GetConVar('lod_developer_mode');local s=R.State;local level=tonumber(args and args[1])
    if not cv or not cv:GetBool() or not IsValid(p) or not p:IsAdmin() or not p:Alive() or not R:IsActivePlayer(p)
        or not level or level~=math.floor(level) or level<1 or level>20 or s.Failed or not s.BuildReady then return end
    -- Explicit unranked developer action, never an automatic retention reset.
    R:MarkUnranked('boss_test_level');B:Cleanup(s.Boss,'developer_level')
    s.Level=level
    local ok,err=R:BuildCurrentLevel()
    if not ok then p:ChatPrint('Boss test level build failed: '..tostring(err));return end
    p:ChatPrint('Authored dungeon '..level..' built unranked. Deploy normally, then use lod_boss_testkit to reach the court. Completion mechanics are not bypassed.')
end)
