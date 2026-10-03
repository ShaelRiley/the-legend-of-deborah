-- Dungeon 14. Chuck owns the sole boss receipt; Jane is a subordinate actor.
-- All damage, physics, admissions, scheduling and progression stay in BossEncounter.
local B = LOD.BossEncounter
local D = {
    name = 'Chuck Chuck Bo Buck', model = 'models/Humans/Group01/male_07.mdl',
    baseHP = 1500, speed = 145, size = 1.15, maxObjects = 24, maxAdds = 1,
    phaseNames = {'Fresh Cut', 'Heavy Timber', 'LUMBER LIQUIDATION'},
    arena = {theme = 'filling_station', width = 6, depth = 6, upper = true},
    deathCaption = 'CHUCK CHUCK BO BUCK DEFEATED', keyLocation = 'center',
    presentation = {body = 'citizen_beaver', face = 'beaver_muzzle_incisors', tail = 'crosshatched_paddle',
        companion = 'jane_propane', wood = {'plank', 'timber', 'panel'}}
}
local J = {name = 'Jane the Propane', model = 'models/props_junk/propane_tank001a.mdl',
    baseHP = 650, speed = 140, size = 2.1, phaseNames = {'Pilot Light', 'Highly Flammable', 'PRESSURE VESSEL'}, subordinate = true}
B:RegisterSupport('jane_propane', J)
local citizens = {'male_01', 'male_02', 'male_03', 'male_04', 'male_05', 'male_06', 'male_07', 'male_08', 'male_09',
    'female_01', 'female_02', 'female_03', 'female_04', 'female_06'}
local woods = {
    plank = {model = 'models/props_debris/wood_board04a.mdl', mass = 9, speed = 720, lift = 35, gravity = 120,
        radius = 13, hp = 14, life = 3, bounces = 1, damage = 12, push = 105, tell = .85, recovery = 1.1},
    timber = {model = 'models/props_debris/wood_board07a.mdl', mass = 65, speed = 385, lift = 220, gravity = 380,
        radius = 26, hp = 35, life = 5, bounces = 1, damage = 23, push = 240, tell = 1.55, recovery = 1.8},
    panel = {model = 'models/props_debris/wood_board06a.mdl', mass = 22, speed = 285, lift = 95, gravity = 110,
        radius = 42, hp = 24, life = 4, bounces = 0, damage = 9, push = 80, tell = 1.4, recovery = 1.65}
}
local cylinderColors = {Stable = Color(140,165,170), Leaking = Color(210,220,90),
    Ignited = Color(255,130,35), Critical = Color(255,35,25)}
local function aliveJane(c)
    return not c.data.janeDisabled and IsValid(c.data.jane) and c.owned[c.data.jane] == 'jane_propane'
end
local function action(c, text, actor)
    if actor == c.data.jane then c.data.janeAction = text else c.data.action = text end
    if IsValid(actor or c.actor) then (actor or c.actor):SetNW2String('LOD_BossAction', text) end
end
local function unit(v)
    if v:LengthSqr() < .01 then return Vector(1,0,0) end
    return v:GetNormalized()
end
local function sourceOK(c, actor)
    return B:Live(c) and IsValid(actor) and (actor == c.actor or (actor == c.data.jane and aliveJane(c)))
end
local function safeHazard(c, position, radius)
    local p = B:Floor(c, position)
    if not p or p:DistToSqr(c.data.safe) < (radius + 110)^2 then return nil end
    local occupied,maxRadius = {p},radius
    for _, o in ipairs(B:Objects(c, 'chuck_panel')) do occupied[#occupied + 1] = o.pos; maxRadius = math.max(maxRadius,65) end
    for _, g in ipairs(c.data.gas or {}) do
        if not g.done and c.now < g.expires then occupied[#occupied + 1] = g.pos; maxRadius = math.max(maxRadius,g.radius) end
    end
    for _, o in ipairs(B:Objects(c,'jane_cylinder')) do
        if not o.done and o.state ~= 'Stable' then occupied[#occupied + 1] = o.pos; maxRadius = math.max(maxRadius,135) end
    end
    return B:ValidateRoutes(c, occupied, maxRadius + 28) and p or nil
end
function D:Start(c)
    local citizen = citizens[B:Random(c, 'chuck_citizen', 1, #citizens)]
    c.data.citizenModel = 'models/Humans/Group01/' .. citizen .. '.mdl'
    c.actor:SetModel(c.data.citizenModel)
    c.actor:SetNW2Bool('LOD_Beaver', true)
    c.data.safe = B:Point(c, #c.points)
    c.data.nextWood, c.data.woodCycle, c.data.movePoint = c.now + 1.2, 0, 1
    c.data.janeNext, c.data.janeCycle, c.data.janeRoute = c.now + 2.5, 0, 2
    c.data.gas, c.data.gasSerial, c.data.cylinderSerial = {}, 0, 0
    c.data.janeBlastDamage, c.data.janeBlastCount, c.data.janeBlastImmune = 0, 0, 0
    c.data.janeSpawnAt = 0
    self:EnsureJane(c)
    c.data.racks = {}
    for i = 1,2 do
        local rack = B:Object(c,{kind = 'jane_rack',model = 'models/props_c17/FurnitureShelf001a.mdl',
            pos = B:Point(c,4 + i * 3),permanent = true,hp = 0,solid = false,radius = 30,
            label = i == 1 and 'CYLINDER RACK / NO SMOKING' or 'FILLING STATION: VALVES / PIPEWORK'})
        if rack then c.data.racks[#c.data.racks + 1] = rack end
    end
    for i = 1,2 do
        B:Object(c,{kind = 'jane_blast_wall',model = 'models/props_c17/concrete_barrier001a.mdl',
            pos = B:Point(c,3 + i * 4),permanent = true,hp = 0,solid = true,radius = 35,label = 'BLAST WALL'})
    end
    action(c, 'FRESH CUT: WATCH THE WOOD')
    B:Announce(c, 'CHUCK CHUCK BO BUCK / WITH JANE THE PROPANE')
end
function D:EnsureJane(c)
    if c.data.janeDisabled then return end
    if c.data.janeAdmitted then
        -- Native removal is neutralization, not a new support roll or free replacement.
        if not aliveJane(c) or c.data.jane:Health() <= 0 then self:DisableJane(c) end
        return
    end
    if c.now < (c.data.janeSpawnAt or 0) then return end
    c.data.janeSpawnAt = c.now + 1
    local actor = B:SpawnActor(c,'jane_propane','jane_propane',B:Point(c,2),
        {manual = true,primary = false,model = J.model,scale = 2.1,name = J.name})
    if not IsValid(actor) then return end
    c.data.jane,c.data.janeAdmitted = actor,true
    c.data.janeMaxHP = actor:GetMaxHealth()
    actor:SetNW2String('LOD_BossSupportId','jane_propane')
    actor:SetNW2String('LOD_BossAction',J.phaseNames[c.phase])
    actor:SetNW2Int('LOD_JaneLeaks',c.phase - 1)
end
function D:ActorReplaced(c, actor)
    actor:SetModel(c.data.citizenModel)
    actor:SetNW2Bool('LOD_Beaver',true)
    actor:SetNW2String('LOD_BossAction',c.data.action or D.phaseNames[c.phase])
end
function D:SettlePanel(c, o, point)
    if o.settled then return end
    o.settled = true
    local pos = safeHazard(c, point, 65)
    if pos and #B:Objects(c, 'chuck_panel') < 3 then
        B:Object(c, {kind = 'chuck_panel', model = woods.panel.model, pos = pos + Vector(0,0,18),
            label = 'BROAD PANEL: BREAKABLE / 5s', hp = 24, mass = 22, radius = 46,
            life = 5, solid = true, pushable = true, scale = 1.8})
    end
    B:RemoveObject(c, o, 'panel_settled')
end
function D:ThrowWood(c, kind, target)
    local cfg = woods[kind]
    if not cfg or #B:Objects(c, 'chuck_wood') >= 7 or not B:Hero(c,target) then return false end
    local binding, point = B:BindTarget(c,target), target:GetPos() + Vector(0,0,28)
    action(c, string.upper(kind) .. ': WIND-UP')
    B:Stop(c,c.actor)
    c.data.woodTellUntil = c.now + cfg.tell
    c.actor:SetNW2String('LOD_ChuckWood', kind)
    B:Warn(c, string.upper(kind) .. ' THROW', c.actor:GetPos(), cfg.tell, cfg.radius,
        {shape = 'lane', finish = point, width = cfg.radius * 2 + 12})
    B:Later(c, cfg.tell, 'chuck_wood_throw', function(owner)
        if not B:TargetLive(owner,binding) then return end
        local start = owner.actor:GetPos() + Vector(0,0,52)
        local direction = unit(point - start)
        local o = B:Projectile(owner, {kind = 'chuck_wood', role = kind, model = cfg.model,
            pos = start, velocity = direction * cfg.speed + Vector(0,0,cfg.lift), gravity = cfg.gravity,
            radius = cfg.radius, mass = cfg.mass, life = cfg.life, hp = cfg.hp, bounces = cfg.bounces,
            label = string.upper(kind), scale = kind == 'panel' and 1.8 or 1.3, spin = kind == 'panel' and 65 or 0, breakOnImpact = kind == 'plank',
            damage = {kind = 'melee', damage = cfg.damage, reference = 13.5, push = cfg.push},
            onHit = function(enc, object)
                if kind == 'plank' then B:RemoveObject(enc,object,'plank_shattered')
                elseif kind == 'panel' then D:SettlePanel(enc,object,object.pos) end
            end,
            onImpact = function(enc, object, tr)
                if kind == 'panel' and not B:Hero(enc,tr.Entity) then D:SettlePanel(enc,object,tr.HitPos or object.pos); return true end
                if kind == 'timber' and not object.rolling and tr.HitNormal and tr.HitNormal.z > .5 then
                    object.rolling, object.state = true, 'SHORT ROLL'
                    object.velocity = unit(Vector(object.velocity.x,object.velocity.y,0)) * 190
                    object.gravity, object.spec.gravity, object.spec.breakOnImpact = 0, 0, false
                    object.expires = math.min(object.expires, enc.now + 1.5)
                    return true
                end
            end})
        if o then o.woodType = kind end
        action(owner, string.upper(kind) .. ': RECOVER')
        B:Log(owner,'chuck_wood',{kind = kind, speed = cfg.speed, mass = cfg.mass})
    end)
    c.data.nextWood = c.now + cfg.tell + cfg.recovery
    return true
end
function D:CylinderState(c, o, state)
    o.state = state
    o.spec.pushable = state == 'Stable' or state == 'Leaking'
    o.spec.color = cylinderColors[state]
    o.spec.label = 'CYLINDER: ' .. string.upper(state) .. ' / VALVE AT TOP'
    if IsValid(o.ent) then
        o.ent:SetColor(cylinderColors[state])
        o.ent:SetNW2String('LOD_BossObjectState', state)
        o.ent:SetNW2String('LOD_BossObjectLabel', o.spec.label)
    end
    B:Log(c,'jane_cylinder_state',{id = o.id, state = state})
end
function D:LooseCylinder(c, pos, velocity, mode)
    if not aliveJane(c) or #B:Objects(c,'jane_cylinder') >= 6 then return nil end
    pos = safeHazard(c,pos,120)
    if not pos then return nil end
    c.data.cylinderSerial = c.data.cylinderSerial + 1
    local o = B:Projectile(c, {kind = 'jane_cylinder', model = J.model, pos = pos + Vector(0,0,18),
        velocity = velocity or Vector(0,0,0), gravity = 0, hp = 28, mass = 24, radius = 15,
        life = 10, bounces = 1, source = c.data.jane, pushable = true, breakOnImpact = false,
        label = 'CYLINDER: STABLE / VALVE AT TOP', damage = mode == 'bowling' and
            {kind = 'melee', damage = 10, reference = 13.5, push = 140} or nil,
        onImpact = function(enc, object, tr)
            if B:Hero(enc,tr.Entity) then return end
            object.velocity = Vector(0,0,0)
            return true
        end})
    if not o then return nil end
    o.cylinder, o.cylinderMode, o.serial = true, mode, c.data.cylinderSerial
    o.leakAt, o.igniteAt, o.criticalAt, o.blastAt = c.now + 1.4, c.now + 4.1, c.now + 5.1, c.now + 6.4
    o.leakedAt, o.warned = nil, false
    self:CylinderState(c,o,'Stable')
    return o
end
function D:JaneBlast(c, point)
    if not aliveJane(c) or c.data.jane:GetPos():DistToSqr(point) > 175^2 then return end
    local maximum = math.max(1,c.data.janeMaxHP or 1)
    local remaining = maximum * .16 - c.data.janeBlastDamage
    if remaining <= 0 or c.now < c.data.janeBlastImmune then return end
    local amount = math.min(remaining, maximum * .035 / (1 + c.data.janeBlastCount * .5))
    c.data.janeBlastDamage = c.data.janeBlastDamage + amount
    c.data.janeBlastCount, c.data.janeBlastImmune = c.data.janeBlastCount + 1, c.now + 4
    B:SelfDamage(c,amount,'jane_cylinder_backfire',c.data.jane)
    B:Stagger(c,math.max(.35,1.6 / c.data.janeBlastCount),c.data.jane)
    c.data.janeRecover = math.max(c.data.janeRecover or 0,c.now + 1.6)
end
function D:DetonateCylinder(c,o)
    if B.SourceLive and o.sourceBinding and not B:SourceLive(c,o.sourceBinding) then return end
    if B.Callback then return B:Callback(c,o,self.DetonateCylinderBound,self,c,o) end
    return self:DetonateCylinderBound(c,o)
end
function D:DetonateCylinderBound(c, o)
    if o.done or o.retired then return end
    o.done = true
    if sourceOK(c,o.source) then
        B:Area(c,o.pos,135,{kind = 'blast',damage = 17,reference = 17,push = 210},o.source)
        self:JaneBlast(c,o.pos)
    end
    B:RemoveObject(c,o,'cylinder_detonated')
end
function D:ServiceCylinders(c, now)
    for _, o in ipairs(B:Objects(c,'jane_cylinder')) do
        if not o.done then
            if not aliveJane(c) then B:RemoveObject(c,o,'jane_disabled')
            elseif o.state == 'Stable' and now >= o.leakAt then
                self:CylinderState(c,o,'Leaking'); o.leakedAt = now
                B:Warn(c,'LEAKING CYLINDER: IGNITION NEXT',o.pos,math.max(1,o.igniteAt - now),135)
            elseif o.state == 'Leaking' and now >= o.igniteAt and now >= (o.leakedAt or now) + 1 then
                self:CylinderState(c,o,'Ignited')
                if o.cylinderMode == 'rocket' then o.velocity = o.rocketDirection * 380; o.expires = math.min(o.expires,now + 2.5) end
            elseif o.state == 'Ignited' and now >= o.criticalAt then
                self:CylinderState(c,o,'Critical')
                B:Warn(c,'CRITICAL CYLINDER: BLAST',o.pos,math.max(.8,o.blastAt - now),135)
                o.blastAt = math.max(o.blastAt,now + .8)
            elseif o.state == 'Critical' and now >= o.blastAt then self:DetonateCylinder(c,o) end
        end
    end
end
function D:ValveHit(c, o, info)
    if o.done or not aliveJane(c) then return end
    local position = info.GetDamagePosition and info:GetDamagePosition()
    local valve = o.pos + Vector(0,0,25)
    local precise = position and position:DistToSqr(valve) <= 15^2
    local fire = info.IsDamageType and (info:IsDamageType(DMG_BURN or 8) or info:IsDamageType(DMG_SLOWBURN or 2097152))
    if precise then
        if o.state == 'Stable' then
            self:CylinderState(c,o,'Leaking'); o.leakedAt = c.now
            o.igniteAt = math.max(c.now + 1.4,o.igniteAt)
            B:Warn(c,'VALVE VENT: IGNITION NEXT',o.pos,1.4,135)
        elseif o.state == 'Leaking' then
            local attacker = info.GetAttacker and info:GetAttacker()
            if IsValid(attacker) then o.velocity = unit(o.pos - attacker:GetPos()) * 220 end
            o.igniteAt = math.max(c.now + 1,o.leakedAt + 1)
            B:Warn(c,'REDIRECTED CYLINDER: IGNITION',o.pos,1,135)
        elseif o.state == 'Ignited' then
            self:CylinderState(c,o,'Critical'); o.blastAt = c.now + 1
            B:Warn(c,'VALVE SHOT: CRITICAL',o.pos,1,135)
        end
    elseif fire and o.state == 'Leaking' then
        -- Fire can ignite explicitly leaking fuel only. No Ice exception or ambient propagation.
        o.igniteAt = math.max(c.now + .85,(o.leakedAt or c.now) + 1)
        B:Warn(c,'FIRE IGNITES LEAKING CYLINDER',o.pos,.85,135)
    end
end
function D:GasPocket(c, pos, radius, ignitionDelay, label, lane)
    if not aliveJane(c) then return nil end
    local live = 0
    for _, g in ipairs(c.data.gas) do if not g.done and c.now < g.expires then live = live + 1 end end
    if live >= 5 then return nil end
    pos = safeHazard(c,pos,radius)
    if not pos then return nil end
    if lane then
        lane.finish = B:Floor(c,lane.finish)
        if not lane.finish then return nil end
        local delta = lane.finish - pos
        local t = math.max(0,math.min(1,(c.data.safe - pos):Dot(delta) / math.max(1,delta:LengthSqr())))
        if (pos + delta * t):DistToSqr(c.data.safe) < ((lane.width or radius) + 110)^2 then return nil end
        if not B:ValidateRoutes(c,{pos,pos + delta * .5,lane.finish},(lane.width or radius) + 28) then return nil end
    end
    c.data.gasSerial = c.data.gasSerial + 1
    local g = {pos = pos, radius = radius, igniteAt = c.now + math.max(2,ignitionDelay or 3),
        expires = c.now + math.max(2,ignitionDelay or 3) + 2.4, serial = c.data.gasSerial, source = c.data.jane}
    local z = B:Zone(c,{kind = 'jane_gas',label = label or 'UNIGNITED GAS',pos = pos,radius = radius,
        shape = lane and 'lane' or 'circle',finish = lane and lane.finish,width = lane and lane.width,
        delay = 0,life = g.expires - c.now,interval = .8,color = Color(170,200,75,75),source = c.data.jane,
        onTick = function(owner,zone,targets)
            if g.done or not sourceOK(owner,g.source) then return end
            if g.ignited and owner.now >= g.igniteAt then
                for _, target in ipairs(targets or {}) do
                    B:Damage(owner,target,{kind = 'flame',damage = 8,reference = 13.5,content = 'fire',origin = g.pos},g.source)
                end
            end
        end,
        onExpire = function() g.done = true end})
    if not z then return nil end
    g.zone = z
    c.data.gas[#c.data.gas + 1] = g
    B:Warn(c,label or 'GAS POCKET: NO FIRE YET',pos,math.max(1,g.igniteAt - c.now - 1),radius)
    return g
end
function D:ServiceGas(c, now)
    local retained = {}
    for _, g in ipairs(c.data.gas) do
        if not g.done and now < g.expires and aliveJane(c) then
            retained[#retained + 1] = g
            if not g.warned and now >= g.igniteAt - 1.1 then
                g.warned = true
                B:Warn(c,'IGNITION: LEAVE MARKED GAS',g.pos,1.1,g.radius,{color = Color(255,105,20),
                    shape = g.zone.shape,finish = g.zone.finish,width = g.zone.width})
            end
            if g.warned and now >= g.igniteAt then
                g.ignited = true
                g.zone.label,g.zone.color = 'IGNITED GAS',Color(255,85,20,130)
            end
        else g.done = true end
    end
    c.data.gas = retained
end
function D:PressureJet(c, target)
    if not aliveJane(c) or not B:Hero(c,target) then return end
    local jane, finish = c.data.jane, target:GetPos()
    local start = jane:GetPos()
    action(c,'PRESSURE JET',jane)
    B:Zone(c,{kind = 'jane_pressure',label = 'PRESSURE JET',pos = start,finish = finish,shape = 'lane',width = 65,
        delay = 1,life = .4,interval = .5,damage = {kind = 'melee',damage = 7,reference = 13.5,push = 245},
        source = jane,color = Color(180,220,235)})
end
function D:FlameBurst(c, target, sweep)
    if not aliveJane(c) or not B:Hero(c,target) then return end
    local jane, start = c.data.jane, c.data.jane:GetPos()
    local direction = unit(target:GetPos() - start)
    local count = sweep and 5 or 1
    action(c,sweep and 'BLOWTORCH SWEEP' or 'FLAME BURST',jane)
    -- All sweep lanes are announced before the first one lights; no tracking after commitment.
    for i = 1,count do
        local theta = sweep and (i - 3) * .16 or 0
        local d = Vector(direction.x * math.cos(theta) - direction.y * math.sin(theta),
            direction.x * math.sin(theta) + direction.y * math.cos(theta),0)
        local endpoint = B:Floor(c,start + d * 380)
        if endpoint then
            B:Zone(c,{kind = 'jane_flame',label = sweep and 'BLOWTORCH ' .. i or 'FLAME BURST',pos = start,
                finish = endpoint,shape = 'lane',width = sweep and 42 or 80,delay = 1.25 + (i - 1) * .32,
                life = .35,interval = .4,damage = {kind = 'flame',damage = sweep and 9 or 12,reference = 13.5,content = 'fire'},
                source = jane,color = Color(255,130,25)})
        end
    end
end
function D:JaneDash(c, target, multi)
    if not aliveJane(c) or not B:Hero(c,target) then return end
    local jane, finish = c.data.jane, target:GetPos()
    action(c,multi and 'MULTI-JET MOVEMENT' or 'PROPANE DASH',jane)
    B:Charge(c,jane,finish,{label = 'PROPANE DASH: JET LINE',warning = 1.15,speed = 430,width = 52,
        damage = {kind = 'melee',damage = 10,reference = 13.5,push = 160},recovery = 1.3,
        onFinish = function(owner)
            if not aliveJane(owner) then return end
            if multi then
                owner.data.janeRoute = owner.data.janeRoute + 2
                local p = B:Point(owner,owner.data.janeRoute)
                B:Warn(owner,'LATERAL GAS-JET HOP',p,.75,55)
                B:Later(owner,.75,'jane_multijet',function(enc)
                    if aliveJane(enc) then B:Move(enc,enc.data.jane,p,235,{mode = 'bounce',height = 65,turnRate = 1.4}) end
                end)
            end
        end})
end
function D:VentAndIgnite(c)
    action(c,'VENT-AND-IGNITE LANES',c.data.jane)
    for i = 1,3 do
        local p = B:Point(c,c.data.janeRoute + i * 2)
        self:GasPocket(c,p,65,2.3 + i * .65,'VENT LANE ' .. i .. ': GAS BEFORE FIRE',
            {finish = B:Point(c,c.data.janeRoute + i * 2 + 1),width = 48})
    end
end
function D:EmergencyRelief(c)
    if not aliveJane(c) then return end
    local jane, pos = c.data.jane,c.data.jane:GetPos()
    action(c,'EMERGENCY RELIEF: SAFE / VULNERABLE',jane)
    B:Clear(c,'jane_gas'); B:Clear(c,'jane_flame')
    for _, g in ipairs(c.data.gas) do g.done = true end
    c.data.gas = {}
    for _, o in ipairs(B:Objects(c,'jane_cylinder')) do
        if o.state == 'Stable' or o.state == 'Leaking' then
            o.velocity = unit(o.pos - pos) * 180
            o.igniteAt,o.criticalAt,o.blastAt = c.now + 4,c.now + 5,c.now + 6.3
        end
    end
    B:Warn(c,'RELIEF VENT: CYLINDERS PUSH OUTWARD',pos,.65,170)
    B:Stagger(c,4,jane)
    c.data.janeRecover,c.data.janeNext = c.now + 4,c.now + 4.6
end
function D:PropaneNightmare(c)
    if not aliveJane(c) or c.data.nightmareUntil and c.now < c.data.nightmareUntil then return end
    c.data.nightmareUntil,c.data.janeNext = c.now + 10,c.now + 12
    action(c,'PROPANE NIGHTMARE: CLICK... CLICK...',c.data.jane)
    B:Stop(c,c.data.jane)
    -- Three sections illuminate in order. Each old section goes safe before the next ignites;
    -- the permanent safe anchor plus route validation survives the complete sequence.
    for i = 1,3 do
        local g = self:GasPocket(c,B:Point(c,c.data.janeRoute + i * 2),110,3.6 + (i - 1) * 2.7,
            'PROPANE NIGHTMARE: SECTION ' .. i)
        if g then g.expires = g.igniteAt + 1.8; g.zone.expires = g.expires end
    end
    for i = 1,3 do
        B:Later(c,i * .8,'jane_failed_click_' .. i,function(owner)
            if aliveJane(owner) then
                action(owner,'IGNITION FAILED: CLICK',owner.data.jane)
                owner.data.jane:EmitSound('buttons/button10.wav',70,95,.6)
            end
        end)
    end
    B:Later(c,10,'jane_nightmare_relief',function(owner) if aliveJane(owner) then D:EmergencyRelief(owner) end end)
end
function D:JaneAttack(c, target)
    if not aliveJane(c) then return end
    local n = c.data.janeCycle + 1
    c.data.janeCycle = n
    c.data.janeNext = c.now + (c.phase == 3 and 4.5 or 5)
    local mode = ((n - 1) % (c.phase == 1 and 4 or c.phase == 2 and 8 or 12)) + 1
    if mode == 1 then self:PressureJet(c,target)
    elseif mode == 2 then self:FlameBurst(c,target,false)
    elseif mode == 3 then self:JaneDash(c,target,c.phase == 3)
    elseif mode == 4 then self:LooseCylinder(c,B:Point(c,c.data.janeRoute + 1))
    elseif mode == 5 then
        action(c,'CYLINDER BOWLING',c.data.jane)
        local pos = c.data.jane:GetPos()
        B:Warn(c,'CYLINDER BOWLING',pos,1.2,25,{shape = 'lane',finish = target:GetPos(),width = 50})
        local dir = unit(target:GetPos() - pos)
        B:Later(c,1.2,'jane_bowling',function(owner) D:LooseCylinder(owner,pos,dir * 250,'bowling') end)
    elseif mode == 6 then self:GasPocket(c,target:GetPos(),105,3.2)
    elseif mode == 7 then
        local o = self:LooseCylinder(c,B:Point(c,c.data.janeRoute + 2),nil,'rocket')
        if o then o.rocketDirection = unit(target:GetPos() - o.pos); action(c,'ROCKET CYLINDER: LEAK / LIGHT / LAUNCH',c.data.jane) end
    elseif mode == 8 then self:VentAndIgnite(c)
    elseif mode == 9 then self:FlameBurst(c,target,true)
    elseif mode == 10 then
        action(c,'CYLINDER STORM',c.data.jane)
        for i = 1,3 do
            local pos = B:Point(c,c.data.janeRoute + i * 2)
            B:Warn(c,'CYLINDER STORM: DROP ' .. i,pos,1.3 + i * .3,40)
            B:Later(c,1.3 + i * .3,'jane_storm_' .. i,function(owner) D:LooseCylinder(owner,pos) end)
        end
    elseif mode == 11 then self:EmergencyRelief(c)
    else self:PropaneNightmare(c) end
end
function D:Think(c, now, dt, targets)
    self:EnsureJane(c)
    self:ServiceCylinders(c,now); self:ServiceGas(c,now)
    local target = targets[1]
    if not target then return end
    if now >= c.data.nextWood then
        c.data.woodCycle = c.data.woodCycle + 1
        local catalog = c.phase == 1 and {'plank','timber'} or {'plank','timber','panel'}
        local kind = catalog[B:Random(c,'chuck_wood_catalog',1,#catalog)]
        if not self:ThrowWood(c,kind,target) then c.data.nextWood = now + .6 end
    elseif now >= (c.data.woodTellUntil or 0) and now < c.data.nextWood - .3 then
        local reached = B:Move(c,c.actor,B:Point(c,c.data.movePoint),145,{mode = 'ground',turnRate = 2.2})
        if reached then c.data.movePoint = c.data.movePoint + 1 end
    end
    if aliveJane(c) and now >= (c.data.janeRecover or 0) then
        if now >= c.data.janeNext then self:JaneAttack(c,target)
        elseif not c.data.nightmareUntil or now >= c.data.nightmareUntil then
            local p = B:Point(c,c.data.janeRoute)
            local reached = B:Move(c,c.data.jane,p,c.phase == 3 and 155 or 120,{mode = 'skate',turnRate = 1.1})
            if reached then c.data.janeRoute = c.data.janeRoute + 1 end
        end
    end
end
function D:Phase(c, phase)
    c.data.nextWood,c.data.janeNext = c.now + 1.3,c.now + 2
    c.data.janeCycle,c.data.nightmareUntil = phase == 2 and 4 or phase == 3 and 8 or 0,nil
    if aliveJane(c) then
        c.data.jane:SetNW2Int('LOD_JaneLeaks',phase - 1)
        action(c,J.phaseNames[phase],c.data.jane)
    end
    action(c,D.phaseNames[phase]); B:Announce(c,D.phaseNames[phase])
end
function D:BeforeDamage(c, actor, info)
    if actor == c.data.jane and c.now < (c.data.janeRecover or 0) and info.ScaleDamage then info:ScaleDamage(1.2) end
end
function D:ObjectEvent(c, o, event, payload)
    if o.cylinder then
        if event == 'hit' then self:ValveHit(c,o,payload)
        elseif event == 'destroy' then
            o.done = true -- Shooting is always a safe cancellation, never an untelegraphed blast.
            B:Log(c,'jane_cylinder_vented',{id = o.id,state = o.state})
        end
    end
end
function D:ClearJane(c)
    for _, kind in ipairs({'jane_cylinder','jane_gas','jane_flame','jane_pressure'}) do B:Clear(c,kind) end
end
function D:DisableJane(c, deferred)
    if c.data.janeDisabled then return end
    c.data.janeDisabled = true
    if deferred then
        B:Later(c,0,'jane_retire_hazards',function(owner) D:ClearJane(owner) end)
    else self:ClearJane(c) end
    for _, g in ipairs(c.data.gas) do g.done = true end
    c.data.gas = {}
    -- No Complete/ReplacePrimary/UseDamage, Jail Key, boss HP, or receipt path exists here.
    B:Announce(c,'JANE NEUTRALIZED: CHUCK IS STILL THE BOSS')
    B:Log(c,'jane_disabled',{primary = 'chuck',receipt = false,key = false})
end
function D:ActorKilled(c, actor, role)
    if role ~= 'jane_propane' then return false end
    local pos = actor:GetPos()
    actor:SetNW2Bool('LOD_JaneDead',true)
    self:DisableJane(c,true)
    -- Deferred cosmetic death only; no native mutation or damage in lethal callback.
    B:Later(c,.1,'jane_death_cosmetic',function(owner)
        local rack = owner.data.racks and owner.data.racks[1]
        local direction = rack and unit(rack.pos - pos) or Vector(-1,0,0)
        B:Object(owner,{kind = 'jane_death',model = J.model,pos = pos,velocity = direction * 30,
            scale = 2.1,cosmetic = true,hp = 0,life = 3.2,solid = false,label = 'VALVES SHUT / TINY LEAK'})
        B:Later(owner,1.25,'jane_fallen_cylinder',function(enc)
            B:Object(enc,{kind = 'jane_dead_cylinder',model = J.model,pos = pos + direction * 40 + Vector(0,0,100),
                velocity = Vector(0,0,-120),cosmetic = true,hp = 0,life = .7,solid = false,label = 'LOOSE CYLINDER FALLS'})
        end)
        B:Warn(owner,'CONTROLLED PROPANE DISPLAY / NO SMOKING',pos,1.6,70,{color = Color(255,155,75)})
    end)
    return true
end
function D:Pause(c)
    for _, kind in ipairs({'jane_gas','jane_flame','jane_pressure','jane_cylinder','chuck_wood'}) do B:Clear(c,kind) end
    for _, g in ipairs(c.data.gas or {}) do g.done = true end
    c.data.gas = {}
    c.data.nightmareUntil = nil
end
function D:Retire(c)
    c.data.janeDisabled = true
    for _, g in ipairs(c.data.gas or {}) do g.done = true end
end
function D:Snapshot(c)
    return (c.data.action or 'LUMBER') .. ' | JANE: ' .. (c.data.janeDisabled and 'NEUTRALIZED' or c.data.janeAction or 'PILOT LIGHT')
end
B:Register('chuck',D)
