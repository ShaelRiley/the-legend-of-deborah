-- Optional prison incidents use the event director's placement, tick and body
-- ownership; rewards use the shared transactional event authority. There is no
-- second movement, status, timer, inventory or navigation system here.
LOD.EventIncidents = LOD.EventIncidents or {}
local I, Run, Registry = LOD.EventIncidents, LOD.RunManager, LOD.EventRegistry
I.TickSeconds = .25
local function key(c) return LOD.MazeGenerator.CellKey(c.x,c.y,c.z) end
local function clockLive()
    local s=Run.State
    local clock=s.CampaignClock
    return not s.SimulationFrozen and not (clock and (clock.expired or clock.scene
        or clock.deadline and SysTime()>=clock.deadline))
end
local function owned(director,instance)
    if not director:IsCurrent(instance) or instance.state~='active' or not clockLive() then return false end
    if not instance.parts or #instance.parts~=#instance.entities then return false end
    for index,ent in ipairs(instance.parts) do
        if not IsValid(ent) or ent.LODEventInstance~=instance or instance.entities[index]~=ent
            or ent.LODIncidentPart~=index-1 then return false end
    end
    return #instance.parts>0
end
local function body(b)
    local p,ps=b.ply,b.ps
    return IsValid(p) and p:IsPlayer() and p:Alive() and p:SteamID64()==b.identity
        and Run.State==b.run and Run.State.Graph==b.graph and Run:GetPlayerState(p)==ps
        and ps.identity==b.psIdentity and ps.progressionState==b.progression and ps.equipmentLifeSerial==b.life
        and p.LODRunSpawnSerial==b.spawn and Run:IsActivePlayer(p) and not Run:IsSoldierControl(p)
        and ps.deploymentComplete and not ps.inStaging and not ps.eliminated and (ps.lives or 0)>0
        and p:GetMoveType()==MOVETYPE_WALK and not p:InVehicle()
end
function I:Bind(director,instance,ply,identity)
    if not IsValid(ply) then return nil end
    local ps=Run:GetPlayerState(ply)
    if not ps then return nil end
    local b={director=director,instance=instance,ply=ply,identity=identity or ply:SteamID64(),
        ps=ps,life=ps.equipmentLifeSerial,spawn=ply.LODRunSpawnSerial,progression=ps.progressionState,
        psIdentity=ps.identity,run=Run.State,graph=Run.State.Graph,parts=instance.parts,owners={},cell=instance.cell}
    for index,ent in ipairs(instance.parts or {}) do b.owners[index]=ent end
    if not self:Current(b) then return nil end
    return b
end
local function inCell(b)
    local p,center=b.ply,LOD.MazeBuilder:CellCenter(b.instance.cell)
    local pos=p:GetPos()
    -- Every incident footprint is wholly inside its reserved ordinary cell.
    -- A neighbouring floor, wall, safe cell or stair cannot activate it.
    local mins,maxs=p:GetHull()
    local half=LOD.Config.Maze.CellSize*.5-12
    if math.abs(pos.z-center.z)>24 or pos.x+mins.x<center.x-half or pos.x+maxs.x>center.x+half
        or pos.y+mins.y<center.y-half or pos.y+maxs.y>center.y+half then return false end
    return true
end
local function exactParts(b)
    if b.parts~=b.instance.parts or b.cell~=b.instance.cell or b.graph.Cells[key(b.cell)]~=b.cell then return false end
    for index,ent in ipairs(b.owners) do if b.parts[index]~=ent then return false end end
    return true
end
function I:Current(b,entity)
    if not b or not exactParts(b) or not owned(b.director,b.instance) or not body(b) or not inCell(b) then return false end
    entity=entity or b.parts[1]
    if not b.director:InteractionCurrent(b.instance,b.ply,b.identity,b.ps,entity) then return false end
    -- The trace above can run native callbacks. Recheck the exact owners after it.
    return exactParts(b) and owned(b.director,b.instance) and body(b) and inCell(b)
        and b.ply:GetPos():DistToSqr(entity:GetPos())<=160*160
end
function I:Seed(instance,identity,label)
    return LOD.Seeds.Derive(LOD.Seeds.DeriveLevel(Run.State.CampaignSeed,instance.level),
        'dungeon-events:incident:'..instance.archetype..':'..identity..':'..label)
end
local function feedback(ply,text)
    pcall(function() ply:ChatPrint(text) end)
    if LOD.CombatRolls then pcall(LOD.CombatRolls._Send,LOD.CombatRolls,ply,3,text,'event',
        {event='dungeon_incident'}) end
end
local function sync(director,ply)
    if ply then pcall(director.SyncPlayer,director,ply) else pcall(director.SyncAll,director) end
end
local function claim(instance,identity)
    return LOD.EventTransactions.Claim(instance,identity)
end
local function settled(instance,identity)
    local receipt,reason=claim(instance,identity)
    return receipt~=nil or reason~=nil,receipt,reason
end
local function reward(b,credit,result,extra)
    local called,ok,receipt=pcall(function()
        if not I:Current(b) then return false,'Hero or event changed; no reward spent.' end
        local binding,reason=LOD.EventTransactions.Begin(b.director,b.instance,b.ply,b.identity)
        if not binding then return false,reason end
        local options={credit=credit,result=result,validate=function() return I:Current(b) end}
        for k,v in pairs(extra or {}) do options[k]=v end
        return LOD.EventTransactions.Commit(binding,options)
    end)
    if not called then
        -- A native presentation error after COMMIT is not permission to replay.
        receipt=claim(b.instance,b.identity)
        ok=receipt~=nil
        if not ok then receipt='Reward unavailable. Nothing newly spent; retry shortly.' end
    end
    if ok then
        sync(b.director,b.ply)
        feedback(b.ply,Registry.Definitions[b.instance.archetype].name..' — '..
            (result.message or (credit>0 and (credit..' $DEB collected.') or 'Attempt recorded.')))
    end
    return ok,receipt
end
local function endpointSnapshot(instance)
    local out={}
    for index,ent in ipairs(instance.parts or {}) do
        out[index]={entityIndex=IsValid(ent) and ent:EntIndex() or 0,part=index-1,
            name=index==1 and Registry.Definitions[instance.archetype].name or
                (instance.archetype=='memory_terminal' and 'BUTTON ' or
                    instance.archetype=='relay_race' and 'MARKER ' or 'PLATE ')..(index-1),
            action=index>1 and (instance.archetype=='memory_terminal' and ('press button '..(index-1))
                or instance.archetype=='relay_race' and ('RUN HERE — marker '..(index-1))
                or 'STAND HERE — partner on the opposite plate.') or nil}
    end
    return out
end
local function snapshot(instance,ply,identity)
    local def=Registry.Definitions[instance.archetype]
    local result={kind='incident',name=def.name,offer=def.offer,action=def.action,
        status=instance.disabled and 'DISABLED — safe for everyone.' or nil,
        endpoints=endpointSnapshot(instance),phase=instance.phase,phaseAt=instance.phaseAt}
    if def.rewarded then
        local receipt,err=claim(instance,identity)
        if err then result.status='Reward storage unavailable. Retry shortly.'
        elseif receipt then result.status=receipt.message or 'RESOLVED — your attempt is recorded for this dungeon.' end
        result.spent=receipt~=nil
    end
    local session=instance.sessions and instance.sessions[ply]
    if session and session.binding.identity==identity then result.endsAt=session.endsAt end
    return result,session
end
local function flat(_,g,placement)
    local cell=g.Cells[placement.cellKey]
    return LOD.SafeTeleport and LOD.SafeTeleport:FlatCell(g,cell) or false
end
local function create(director,instance)
    local def=Registry.Definitions[instance.archetype]
    instance.parts,instance.sessions={},{ }
    instance.contacts,instance.effects=setmetatable({},{__mode='k'}),setmetatable({},{__mode='k'})
    instance.startedAt,instance.disabled=CurTime(),false
    local positions=def.points or {Vector(0,0,8)}
    for index,offset in ipairs(positions) do
        local ent=ents.Create('lod_dungeon_event')
        if not IsValid(ent) then return nil,'incident entity creation failed' end
        if not director:Track(instance,ent) then ent:Remove();return nil,'stale incident creation' end
        instance.parts[index]=ent
        ent.LODIncidentPart=index-1
        ent:SetNW2String('LOD_EventArchetype',instance.archetype)
        ent:SetNW2Int('LOD_IncidentPart',index-1)
        ent:SetEventID(instance.id)
        ent:SetPos(LOD.MazeBuilder:CellCenter(instance.cell)+offset)
        ent:Spawn();ent:Activate()
        if index>1 then
            ent:SetModel(instance.archetype=='memory_terminal' and 'models/props_lab/reciever01a.mdl'
                or 'models/props_combine/combine_mine01.mdl')
            ent:SetColor(Color(95,185,230))
        end
        if not IsValid(ent) or not director:Track(instance,ent) then return nil,'incident lost during creation' end
    end
    return instance.parts[1]
end
local function clearEffects(instance)
    local status=LOD.RPGStatusElements
    if not status then return end
    for actor,effect in pairs(instance.effects or {}) do
        -- Do not erase a combat refresh that subsequently extended this entry.
        if IsValid(actor) and effect.entry.source==effect.source
            and effect.entry.expiresAt==effect.expiresAt then
            pcall(status.ClearExpected,status,actor,effect.id,effect.entry,'event ended')
        end
    end
    instance.effects=setmetatable({},{__mode='k'})
end
local function cleanup(_,instance)
    clearEffects(instance)
    instance.parts,instance.sessions,instance.contacts,instance.effects=nil,nil,nil,nil
    instance.pair,instance.interactions=nil,nil
end
local function register(def)
    def.production,def.repeatable,def.nonblocking=true,true,true
    def.contract=def.contract or 'UTILITY'
    def.reversible=def.contract=='HAZARD' or nil
    def.Create,def.Validate,def.Cleanup=create,flat,cleanup
    def.Snapshot=def.Snapshot or snapshot
    def.scope=def.scope or 'personal';def.persistence=def.persistence or (def.rewarded and 'account_dungeon' or 'dungeon')
    def.topology=def.contract=='REWARD' and 'dead_end' or def.contract=='HAZARD' and 'optional' or 'respite'
    def.weight=def.weight or 1
    def.previewNotice=def.name..' preview is unranked. '..def.offer
    if def.rewarded then def.Claim=claim end
    Registry:Register(def)
end
local function tickReady(director,instance)
    if not owned(director,instance) or CurTime()<(instance.nextIncidentTick or 0) then return false end
    instance.nextIncidentTick=CurTime()+I.TickSeconds
    return true
end
local function stationary(b,origin)
    local p=b.ply
    return p:OnGround() and p:GetPos():DistToSqr(origin)<=12*12
        and not p:KeyDown(IN_ATTACK) and not p:KeyDown(IN_ATTACK2) and not p:KeyDown(IN_JUMP)
end
local function onPoint(b,part,radius)
    return I:Current(b,b.parts[part+1]) and b.ply:OnGround()
        and b.ply:GetPos():DistToSqr(b.parts[part+1]:GetPos())<=radius*radius
end
local function phase(director,instance,name,color)
    if instance.phase==name then return end
    instance.phase,instance.phaseAt=name,CurTime()
    local ent=instance.parts[1]
    ent:SetNW2String('LOD_IncidentPhase',name)
    if color then ent:SetColor(Color(color[1],color[2],color[3])) end
    sync(director)
end
function I:ApplyHazard(b,id,duration,cooldown)
    if not self:Current(b) or b.instance.disabled then return false end
    local instance,ps,status=b.instance,b.ps,LOD.RPGStatusElements
    if not status or CurTime()<(instance.contacts[ps] and instance.contacts[ps].untilAt or 0) then return false end
    local previous=instance.contacts[ps]
    local serial=(previous and previous.serial or 0)+1
    local present=status:Has(b.ply,id)
    if not self:Current(b) then return false end
    -- Reserve before callbacks and never prolong an existing condition.
    instance.contacts[ps]={untilAt=CurTime()+cooldown,serial=serial}
    if present then return false end
    local source=b.parts[1]
    local ok,reason,entry=status:Apply(b.ply,id,source,{duration=duration,dc=12,
        rng=LOD.RNG.New(self:Seed(instance,b.identity,'hazard:'..serial))})
    if ok and reason=='applied' and entry then
        if not self:Current(b) then
            if entry.source==source then status:ClearExpected(b.ply,id,entry,'stale incident') end
            return false
        end
        instance.effects[b.ply]={id=id,entry=entry,source=source,expiresAt=entry.expiresAt}
    end
    return ok
end
local function disable(director,instance,ply,identity)
    local b=I:Bind(director,instance,ply,identity)
    if not b then return false,'Incident changed.' end
    if instance.disabled then return false,'Already disabled for this dungeon.' end
    instance.disabled=true
    clearEffects(instance)
    if not owned(director,instance) then return false,'Incident ended.' end
    phase(director,instance,'disabled',{85,125,95})
    feedback(ply,Registry.Definitions[instance.archetype].name..' disabled for everyone.')
    return true,{disabled=true}
end
local function nearby(director,instance,fn)
    local center=LOD.MazeBuilder:CellCenter(instance.cell)
    for _,ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:GetPos():DistToSqr(center)<=150*150 then
            local b=I:Bind(director,instance,ply)
            if b then fn(b) end
            if not owned(director,instance) then return end
        end
    end
end

register({id='steam_vent',name='STEAM VENT',contract='HAZARD',family='traps',scope='party',
    interactionMode='automatic',risk='moderate',role='risk',themeAffinities={occupation=2,quarantine=1.5},
    presentation={model='models/props_c17/TrapPropeller_Lever.mdl',color={135,185,195}},
    offer='4s safe / 1s warning / 1s steam. Within 64 units: WIS save DC12 or Muted for 2s.',
    action='USE — seal the valve permanently for this dungeon.',Interact=disable,
    Tick=function(director,instance)
        if not tickReady(director,instance) or instance.disabled then return end
        local elapsed=(CurTime()-instance.startedAt)%6
        phase(director,instance,elapsed<4 and 'safe' or elapsed<5 and 'warning' or 'steam',
            elapsed<4 and {95,190,150} or elapsed<5 and {235,185,55} or {240,105,70})
        if not owned(director,instance) or elapsed<5 then return end
        nearby(director,instance,function(b)
            if b.ply:GetPos():DistToSqr(instance.parts[1]:GetPos())<=64*64 then I:ApplyHazard(b,'muted',2,6) end
        end)
    end,
    Snapshot=function(instance,ply,identity)
        local s=snapshot(instance,ply,identity)
        if not instance.disabled then s.status=string.upper(instance.phase or 'safe')..' — walk around or wait for green.' end
        return s
    end})

register({id='stasis_beacon',name='STASIS BEACON',contract='HAZARD',family='anomalies',scope='party',
    interactionMode='automatic',risk='moderate',role='risk',themeAffinities={corruption=2,hunting=2},
    presentation={model='models/props_combine/combine_mine01.mdl',color={115,115,230}},
    offer='Standing within 64 units: DEX save DC12 or Clumsy for 2s. Crouching avoids the field.',
    action='USE — switch off the field for everyone.',Interact=disable,
    Tick=function(director,instance)
        if not tickReady(director,instance) or instance.disabled then return end
        nearby(director,instance,function(b)
            if not b.ply:Crouching() and b.ply:GetPos():DistToSqr(instance.parts[1]:GetPos())<=64*64 then
                I:ApplyHazard(b,'clumsy',2,3)
            end
        end)
    end})

local function behind(b)
    local ent=b.parts[1]
    return (b.ply:GetPos()-ent:GetPos()):Dot(ent:GetForward()) < -8
end
register({id='watchful_eye',name='WATCHFUL EYE',contract='HAZARD',family='traps',scope='party',
    interactionMode='automatic',risk='moderate',role='risk',themeAffinities={crossfire=2,corruption=1.5},
    presentation={model='models/props_lab/monitor01b.mdl',color={215,110,100}},
    offer='Meet its gaze within 64 units: WIS save DC12 or Reckless for 3s. Avert your eyes.',
    action='Approach behind the screen, then USE to unplug it.',
    Interact=function(director,instance,ply,identity)
        local b=I:Bind(director,instance,ply,identity)
        if not b then return false,'Eye unavailable.' end
        if not behind(b) then return false,'The plug is behind the screen. Circle around without meeting its gaze.' end
        return disable(director,instance,ply,identity)
    end,
    Tick=function(director,instance)
        if not tickReady(director,instance) or instance.disabled then return end
        nearby(director,instance,function(b)
            local ent=b.parts[1]
            if not behind(b) and b.ply:GetPos():DistToSqr(ent:GetPos())<=64*64
                and b.ply:GetAimVector():Dot((ent:WorldSpaceCenter()-b.ply:EyePos()):GetNormalized())>.8 then
                I:ApplyHazard(b,'reckless',3,6)
            end
        end)
    end})

register({id='prison_surveyor',name='PRISON SURVEYOR',family='inhabitants',scope='personal',
    interactionMode='interacted',risk='low',role='information',themeAffinities={retinue=2,crossfire=1.5},
    presentation={model='models/Humans/Group03/male_07.mdl',color={185,180,160}},
    offer='A prisoner charts your current objective through passages that are open now.',
    action='USE — ask for current route and physical floor.',
    Interact=function(director,instance,ply,identity)
        local b=I:Bind(director,instance,ply,identity)
        if not b then return false,'Surveyor unavailable.' end
        local P,N=LOD.ProgressionDirector,LOD.MazeNavigator
        local target=P:GetObjectiveGraphTarget()
        local cell=target and target.a and b.graph.Cells[key(target.a)]
        if not cell then return false,'No current objective can be charted.' end
        local path=N:FindPath(b.graph,instance.cell,cell)
        local directions={}
        for index=2,math.min(4,#(path or {})) do
            local a,c=path[index-1],path[index]
            directions[#directions+1]=c.z>a.z and 'upstairs' or c.z<a.z and 'downstairs'
                or c.x>a.x and 'east' or c.x<a.x and 'west' or c.y>a.y and 'north' or 'south'
        end
        local report=P:GetObjectiveText()..' — physical floor '..(cell.z+1)..'. '..
            (path and (#path==1 and 'You are in the objective room.' or
                (#path-1)..' passages away. First steps: '..table.concat(directions,', ')..'.')
                or 'A closed gate or event blocks the route from here. Resolve it before following this lead.')
        if not I:Current(b) then return false,'Route changed; ask again.' end
        instance.sessions[ply]={binding=b,report=report}
        feedback(ply,report);sync(director,ply)
        return true,{message=report}
    end,
    Snapshot=function(instance,ply,identity)
        local s,session=snapshot(instance,ply,identity)
        if session then s.status=session.report end
        return s
    end})

local function openCounterweight(director,instance)
    if not owned(director,instance) or instance.opened then return false end
    instance.opened=true;instance.sessions={};instance.pair=nil
    phase(director,instance,'open',{100,210,145})
    return true
end
register({id='counterweight_cache',name='COUNTERWEIGHT CACHE',contract='REWARD',family='mechanisms',
    scope='party_unlock_personal_reward',rewarded=true,interactionMode='mixed',risk='low',role='challenge',
    themeAffinities={occupation=2,retinue=1.5},synergies={'cooperation'},
    presentation={model='models/Items/item_item_crate.mdl',color={195,145,65}},
    points={Vector(0,0,8),Vector(-80,0,2),Vector(80,0,2)},
    offer='Two Heroes stand on opposite plates for 3s; alone, USE then stay still for 10s. Each account earns 15 $DEB.',
    action='USE — operate the solo lever, or collect once the cache opens.',
    Interact=function(director,instance,ply,identity,entity)
        local b=I:Bind(director,instance,ply,identity)
        if not b then return false,'Cache unavailable.' end
        if entity~=instance.parts[1] then return false,'Stand on this plate with a partner on the other; the central lever also works alone.' end
        if settled(instance,identity) then return false,'Your reward was already collected or storage is unavailable.' end
        if instance.opened then return reward(b,15,{payout=15,message='15 $DEB collected.'}) end
        if instance.sessions[ply] then instance.sessions[ply]=nil;sync(director,ply);return true,{message='Lever released.'} end
        instance.sessions[ply]={binding=b,origin=ply:GetPos(),endsAt=CurTime()+10}
        sync(director,ply)
        return true,{message='Hold still for 10 seconds to open the counterweight alone.'}
    end,
    Tick=function(director,instance)
        if not tickReady(director,instance) or instance.opened then return end
        for ply,session in pairs(instance.sessions) do
            if not I:Current(session.binding) or not stationary(session.binding,session.origin) then
                instance.sessions[ply]=nil;sync(director,ply)
            elseif CurTime()>=session.endsAt and instance.sessions[ply]==session then
                if openCounterweight(director,instance) then return end
            end
            if not owned(director,instance) then return end
        end
        local left,right
        nearby(director,instance,function(b)
            if not left and onPoint(b,1,30) then left=b
            elseif not right and onPoint(b,2,30) then right=b end
        end)
        if not owned(director,instance) then return end
        if not left or not right or left.identity==right.identity then instance.pair=nil;return end
        local pair=instance.pair
        if not pair or pair.a.ply~=left.ply or pair.b.ply~=right.ply
            or not I:Current(pair.a) or not I:Current(pair.b) then
            instance.pair={a=left,b=right,since=CurTime()};return
        end
        if CurTime()>=pair.since+3 and instance.pair==pair and onPoint(pair.a,1,30) and onPoint(pair.b,2,30) then
            openCounterweight(director,instance)
        end
    end,
    Snapshot=function(instance,ply,identity)
        local s,session=snapshot(instance,ply,identity)
        if not s.spent then s.status=instance.opened and 'OPEN — USE the cache for your 15 $DEB.'
            or session and 'HOLD STILL — operating the solo lever.' or 'LOCKED — use two plates or the solo lever.' end
        return s
    end})

register({id='relay_race',name='PRISON RELAY',contract='REWARD',family='trials',rewarded=true,
    interactionMode='automatic',risk='low',role='challenge',themeAffinities={crossfire=1.5,occupation=1.5},
    presentation={model='models/props_lab/reciever01a.mdl',color={80,200,195}},
    points={Vector(0,0,8),Vector(-90,-70,2),Vector(90,-70,2),Vector(0,90,2)},
    offer='Run over markers 1 → 2 → 3 within 12s. 15 $DEB once per account. Moving is entirely normal.',
    action='Step onto marker 1 to begin. USE the console to collect a completed run.',
    Interact=function(director,instance,ply,identity)
        local session=instance.sessions[ply]
        if not session or not session.complete then return false,'Step on markers 1, 2, then 3 within 12 seconds.' end
        if session.busy then return false,'Reward is settling.' end
        session.busy=true
        local ok,result=reward(session.binding,15,{payout=15,message='Relay completed: 15 $DEB.'})
        session.busy=nil
        if ok and instance.sessions then instance.sessions[ply]=nil end
        return ok,result
    end,
    Tick=function(director,instance)
        if not tickReady(director,instance) then return end
        nearby(director,instance,function(b)
            local ply=b.ply
            local session=instance.sessions[ply]
            if session and not I:Current(session.binding) then instance.sessions[ply]=nil;session=nil end
            if session and not session.complete and CurTime()>session.endsAt then instance.sessions[ply]=nil;session=nil;sync(director,ply) end
            if session and not session.busy and not session.complete and onPoint(b,session.nextPart,30) then
                session.nextPart=session.nextPart+1
                if session.nextPart==4 then session.complete=true;session.endsAt=nil end
                sync(director,ply)
            elseif not session and onPoint(b,1,30) and not settled(instance,b.identity) then
                instance.sessions[ply]={binding=b,nextPart=2,endsAt=CurTime()+12};sync(director,ply)
            end
        end)
        if not owned(director,instance) then return end
        for ply,session in pairs(instance.sessions) do
            if not I:Current(session.binding) then instance.sessions[ply]=nil;sync(director,ply) end
        end
    end,
    Snapshot=function(instance,ply,identity)
        local s,session=snapshot(instance,ply,identity)
        if not s.spent and session then s.status=session.complete and 'COMPLETE — USE console to collect 15 $DEB.'
            or 'RUNNING — next marker '..session.nextPart..'; finish before the timer.' end
        return s
    end})

register({id='memory_terminal',name='MEMORY TERMINAL',contract='REWARD',family='games',rewarded=true,
    interactionMode='interacted',risk='low',role='challenge',themeAffinities={crossfire=2,corruption=1.5},
    presentation={model='models/props_lab/monitor02.mdl',color={175,135,205}},
    points={Vector(0,-55,8),Vector(-65,40,8),Vector(0,55,8),Vector(65,40,8)},
    offer='Watch three numbered lights, then USE the matching buttons in order. 15 $DEB once per account.',
    action='USE the main screen to replay; mistakes reset the sequence without cost.',
    Interact=function(director,instance,ply,identity,entity)
        local b=I:Bind(director,instance,ply,identity)
        if not b or not I:Current(b,entity) then return false,'Terminal unavailable.' end
        if settled(instance,identity) then return false,'Your reward was already collected or storage is unavailable.' end
        local part=entity.LODIncidentPart
        local session=instance.sessions[ply]
        if session and session.busy then return false,'Reward is settling.' end
        if part==0 then
            local rng=LOD.RNG.New(I:Seed(instance,identity,'sequence'))
            instance.sessions[ply]={binding=b,sequence={rng:Int(1,3),rng:Int(1,3),rng:Int(1,3)},
                startedAt=CurTime(),endsAt=CurTime()+30,nextPart=1}
            sync(director,ply);return true,{message='Watch the three lights.'}
        end
        if not session or not I:Current(session.binding) or CurTime()>session.endsAt then
            instance.sessions[ply]=nil;return false,'USE the main screen to see the sequence first.'
        end
        if session.complete then
            session.busy=true
            local ok,result=reward(session.binding,15,{payout=15,message='Sequence remembered: 15 $DEB.'})
            session.busy=nil;if ok and instance.sessions then instance.sessions[ply]=nil end
            return ok,result
        end
        if CurTime()<session.startedAt+3 then return false,'Watch all three lights before answering.' end
        if part~=session.sequence[session.nextPart] then
            instance.sessions[ply]=nil;sync(director,ply)
            return false,'Sequence incorrect. USE the screen to watch and try again.'
        end
        session.nextPart=session.nextPart+1
        if session.nextPart==4 then
            session.complete=true;session.busy=true
            local ok,result=reward(session.binding,15,{payout=15,message='Sequence remembered: 15 $DEB.'})
            session.busy=nil;if ok and instance.sessions then instance.sessions[ply]=nil end
            return ok,result
        end
        sync(director,ply);return true,{message='Correct button; continue.'}
    end,
    Tick=function(director,instance)
        if not tickReady(director,instance) then return end
        for ply,session in pairs(instance.sessions) do
            if not session.busy then
                local step=math.min(4,math.floor(CurTime()-session.startedAt)+1)
                if not I:Current(session.binding) or CurTime()>session.endsAt then
                    instance.sessions[ply]=nil;sync(director,ply)
                elseif session.visibleStep~=step then
                    session.visibleStep=step;sync(director,ply)
                end
            end
            if not owned(director,instance) then return end
        end
    end,
    Snapshot=function(instance,ply,identity)
        local s,session=snapshot(instance,ply,identity)
        if session and not s.spent then
            local step=math.floor(CurTime()-session.startedAt)+1
            s.phase=step<=3 and 'watch' or 'answer'
            if step>=1 and step<=3 then s.visibleLight=session.sequence[step] end
            s.status=session.complete and 'CORRECT — USE any button to retry unconfirmed payment.'
                or step<=3 and ('WATCH — light '..session.sequence[math.max(1,step)]..' ('..step..'/3)')
                or 'REPEAT — enter remembered light '..session.nextPart..' of 3 using the numbered buttons.'
        end
        return s -- never send the stored sequence or upcoming/correct choices
    end})

register({id='nerve_clock',name='NERVE CLOCK',contract='REWARD',family='games',rewarded=true,
    interactionMode='interacted',risk='moderate',role='challenge',themeAffinities={crossfire=2,hunting=1.5},
    presentation={model='models/props_lab/reciever01b.mdl',color={205,90,70}},
    offer='USE to start. USE again on GREEN: 20 $DEB. RED: attempt spent; WIS DC12 or Reckless 3s.',
    action='3 seconds red, then 1 second green. One result per account; 12 seconds to act.',
    Interact=function(director,instance,ply,identity)
        local b=I:Bind(director,instance,ply,identity)
        if not b then return false,'Clock unavailable.' end
        if settled(instance,identity) then return false,'Your attempt was already spent or storage is unavailable.' end
        local session=instance.sessions[ply]
        if session and session.busy then return false,'Attempt settling.' end
        if not session or not I:Current(session.binding) or (session.won==nil and CurTime()>session.endsAt) then
            instance.sessions[ply]={binding=b,startedAt=CurTime(),endsAt=CurTime()+12}
            sync(director,ply);return true,{message='Clock started; stop on green.'}
        end
        session.busy=true
        if session.won==nil then session.won=(CurTime()-session.startedAt)%4>=3 end
        local won=session.won
        local result={success=won,payout=won and 20 or 0,message=won and 'GREEN — 20 $DEB collected.'
            or 'RED — attempt spent. No reward.'}
        local ok,receipt=reward(session.binding,result.payout,result)
        session.busy=nil
        if ok then
            if instance.sessions then instance.sessions[ply]=nil end
            if not won and I:Current(b) then I:ApplyHazard(b,'reckless',3,6) end
        end
        return ok,receipt
    end,
    Tick=function(director,instance)
        if not tickReady(director,instance) then return end
        for ply,session in pairs(instance.sessions) do
            if not session.busy then
                local visible=(CurTime()-session.startedAt)%4>=3
                if not I:Current(session.binding) or (session.won==nil and CurTime()>session.endsAt) then
                    instance.sessions[ply]=nil;sync(director,ply)
                elseif session.visibleGreen~=visible then
                    session.visibleGreen=visible;sync(director,ply)
                end
            end
            if not owned(director,instance) then return end
        end
    end,
    Snapshot=function(instance,ply,identity)
        local s,session=snapshot(instance,ply,identity)
        if session and not s.spent then
            local green=(CurTime()-session.startedAt)%4>=3
            s.phase=session.won~=nil and 'pending' or green and 'green' or 'red'
            s.status=session.won~=nil and 'Payment unconfirmed — USE to retry the frozen result.'
                or green and 'GREEN — USE NOW for 20 $DEB.' or 'RED — wait for green; USE now spends your attempt.'
        end
        return s
    end})

register({id='strength_press',name='STRENGTH PRESS',contract='REWARD',family='trials',rewarded=true,
    interactionMode='interacted',risk='low',role='challenge',themeAffinities={occupation=2,retinue=1.5},
    presentation={model='models/props_c17/TrapPropeller_Engine.mdl',color={180,155,110}},
    offer='One lift: non-exploding 1d20 + your STR modifier against 12. Success: 20 $DEB. Failure: no cost or reward.',
    action='USE — make your one Strength attempt this dungeon.',
    Interact=function(director,instance,ply,identity)
        local b=I:Bind(director,instance,ply,identity)
        if not b then return false,'Press unavailable.' end
        if settled(instance,identity) then return false,'Your attempt was already spent or storage is unavailable.' end
        local session=instance.sessions[ply]
        if session and session.busy then return false,'Attempt settling.' end
        if not session or not I:Current(session.binding) then
            local derived=LOD.RPGAbilityRules:Derived(ply)
            if not derived or not I:Current(b) then return false,'Strength unavailable.' end
            local natural=LOD.RNG.New(I:Seed(instance,identity,'strength')):Int(1,20)
            local modifier=derived.strMod or 0
            local total=natural+modifier
            local result={face=natural,modifier=modifier,total=total,dc=12,success=total>=12,payout=total>=12 and 20 or 0}
            result.message=string.format('1d20 [%d] %+g STR = %g vs 12 — %s',natural,modifier,total,
                result.success and '20 $DEB collected.' or 'failed; attempt spent.')
            session={binding=b,result=result};instance.sessions[ply]=session
        end
        session.busy=true
        local result=session.result
        local ok,receipt=reward(session.binding,result.payout,result)
        session.busy=nil
        if ok and instance.sessions then instance.sessions[ply]=nil end
        if ok and LOD.RPGStatusElements then pcall(LOD.RPGStatusElements.ReportDice,LOD.RPGStatusElements,ply,b.parts[1],
            'STRENGTH PRESS','1d20',{result.face},result.total,result.message,'event_strength') end
        return ok,receipt
    end,
    Snapshot=function(instance,ply,identity)
        local s,session=snapshot(instance,ply,identity)
        if not s.spent then
            local derived=LOD.RPGAbilityRules:Derived(ply)
            local mod=derived and derived.strMod or 0
            local chance=math.Clamp(math.floor(9+mod),0,20)*5
            s.status=session and 'Payment unconfirmed — USE to retry the frozen roll and STR modifier.'
                or string.format('Your STR modifier: %+g. Success chance: %g%%.',mod,chance)
        end
        return s
    end})

register({id='silent_archive',name='SILENT ARCHIVE',family='anomalies',rewarded=true,
    interactionMode='mixed',risk='low',role='recovery',themeAffinities={corruption=2,quarantine=1.5},
    presentation={model='models/props_lab/binderredlabel.mdl',color={115,165,210}},
    offer='USE, then remain grounded and still without attacking for 4s. Restore up to 25 Magic once per account.',
    action='Movement cancels freely. USE again to cancel the reading.',
    Interact=function(director,instance,ply,identity)
        local b=I:Bind(director,instance,ply,identity)
        if not b then return false,'Archive unavailable.' end
        if settled(instance,identity) then return false,'Your reading was already claimed or storage is unavailable.' end
        if instance.sessions[ply] then instance.sessions[ply]=nil;sync(director,ply);return true,{message='Reading cancelled.'} end
        if (b.ps.magic or 100)>=math.max(1,ply:GetNW2Int('LOD_MagicMax',100)) then return false,'Magic is full; your reading remains available.' end
        instance.sessions[ply]={binding=b,origin=ply:GetPos(),endsAt=CurTime()+4}
        sync(director,ply);return true,{message='Remain still and quiet for four seconds.'}
    end,
    Tick=function(director,instance)
        if not tickReady(director,instance) then return end
        for ply,session in pairs(instance.sessions) do
            if not session.busy then
                local b=session.binding
                if not I:Current(b) or not stationary(b,session.origin) then
                    instance.sessions[ply]=nil;sync(director,ply)
                elseif CurTime()>=session.endsAt then
                    local before=tonumber(b.ps.magic) or 100
                    local after=math.min(math.max(1,ply:GetNW2Int('LOD_MagicMax',100)),before+25)
                    if after<=before then instance.sessions[ply]=nil;sync(director,ply)
                    else
                        session.busy=true
                        local ok=reward(b,0,{magic=after-before,message=(after-before)..' Magic restored.'},{
                            psFields={magic=after},validate=function()
                                return I:Current(b) and stationary(b,session.origin) and b.ps.magic==before
                                    and instance.sessions[ply]==session
                            end})
                        session.busy=nil
                        if ok then
                            if instance.sessions then instance.sessions[ply]=nil end
                            if I:Current(b) and LOD.Magic then pcall(LOD.Magic._Sync,LOD.Magic,ply,b.ps) end
                        end
                    end
                end
            end
            if not owned(director,instance) then return end
        end
    end,
    Snapshot=function(instance,ply,identity)
        local s,session=snapshot(instance,ply,identity)
        if session and not s.spent then s.status='READING — stay grounded, still and quiet until the timer ends.' end
        return s
    end})
