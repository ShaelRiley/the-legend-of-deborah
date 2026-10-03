-- Dungeon 13: a legible laundry cycle, optional local drains and finite debris.
local B = LOD.BossEncounter
-- Spatially distributed ground anchors; raw legal-point order interleaves floors.
local function point(c, index)
    if not c.data.sectors then
        local center = B:Center(c)
        local minx, maxx, miny, maxy = center.x, center.x, center.y, center.y
        for _, p in ipairs(c.points) do
            if math.abs(p.z - center.z) < 32 then
                minx, maxx = math.min(minx,p.x), math.max(maxx,p.x)
                miny, maxy = math.min(miny,p.y), math.max(maxy,p.y)
            end
        end
        c.data.sectors = {}
        for i=1,8 do
            local theta=(i-1)*math.pi/4
            local wanted=Vector((minx+maxx)/2+math.cos(theta)*(maxx-minx)*.35,
                (miny+maxy)/2+math.sin(theta)*(maxy-miny)*.35,center.z)
            c.data.sectors[i]=B:Floor(c,wanted) or B:Point(c,i)
        end
    end
    local p=c.data.sectors[(math.floor(index or 1)-1)%8+1]
    return Vector(p.x,p.y,p.z)
end
local D = {
    hull = {mins=Vector(-45,-45,0),maxs=Vector(45,45,95)},
    name = 'Moshi the Washy', model = 'models/props_c17/FurnitureWashingmachine001a.mdl',
    baseHP = 1400, speed = 105, size = 1.7, maxObjects = 22, maxAdds = 0,
    phaseNames = {'Normal Cycle', 'Heavy Load', 'UNBALANCED LOAD'},
    arena = {theme = 'laundromat', width = 6, depth = 6, upper = true}, deathCaption = 'CYCLE COMPLETE',
    presentation = {body = 'washing-machine', drum = true, cycle = true},
    deathSequence = {'violent spin', 'DING', 'door opens', 'harmless laundry', 'one more sock', 'Jail Key', 'tips over'}
}
local debris = {
    light = {model = 'models/props_junk/garbage_bag001a.mdl', mass = 3, speed = 540, gravity = 260, damage = 9, push = 35, radius = 9, tell = .8, life = 3, color = Color(150,195,235)},
    medium = {model = 'models/props_junk/garbage_metalcan002a.mdl', mass = 15, speed = 410, gravity = 390, damage = 15, push = 90, radius = 13, tell = 1.1, life = 4, color = Color(225,185,85)},
    heavy = {model = 'models/props_c17/oildrum001.mdl', mass = 42, speed = 300, gravity = 470, damage = 23, push = 160, radius = 19, tell = 1.6, life = 4.5, color = Color(235,95,75)}
}
local function action(c, text)
    c.data.action = text
    if IsValid(c.actor) then c.actor:SetNW2String('LOD_BossAction', text) end
end
local function physical(n, push) return {kind = 'melee', damage = n, dice = {2,6,n-7}, reference = n, push = push or 0} end
local function safe(c, pos, radius)
    pos = B:Floor(c, pos)
    if not pos or pos:DistToSqr(c.data.dry) < (radius + 110)^2 then return nil end
    for _, platform in ipairs(c.data.dryPlatforms or {}) do
        if math.abs(pos.x-platform.pos.x)<platform.length*.5+radius+32
            and math.abs(pos.y-platform.pos.y)<platform.width*.5+radius+32 then return nil end
    end
    return pos
end
function D:Start(c)
    local d = c.data
    d.cycle, d.cycleEnd, d.round, d.shot, d.nextShot = 'Fill', c.now + 4, 1, 0, 0
    d.dry, d.wet, d.drains, d.reinforced, d.orbits = point(c, 8), {}, {}, {}, {}
    d.openUntil, d.nextWalk, d.walkIndex = 0, c.now + 2, 0
    self:DrainageFloor(c)
    for i = 1, 3 do
        local pos = point(c, i * 2)
        local o = B:Object(c, {kind = 'moshi_drain', model = 'models/hunter/plates/plate1x1.mdl', pos = pos+Vector(0,0,3),
            color=Color(95,110,125), scale=1.1, radius=22,
            hp = 24, solid = false, use = true, hold = .8, permanent = true, label = 'JAMMED DRAIN: SHOOT OR HOLD E', useLabel = 'HOLD E: CLEAR DRAIN'})
        if o then o.drainPos = pos; d.drains[#d.drains+1] = o end
        local center=B:Center(c)+Vector(0,0,2)
        local channel=B:Object(c,{kind='moshi_channel',model='models/hunter/plates/plate1x1.mdl',
            pos=(center+pos)*.5,scale=.08,hp=0,solid=false,permanent=true,color=Color(35,65,80),label='DRAINAGE CHANNEL'})
        if channel then
            channel.ent:SetNW2Vector('LOD_MoshiChannelFrom',center)
            channel.ent:SetNW2Vector('LOD_MoshiChannelTo',pos+Vector(0,0,2))
            channel.channelFrom,channel.channelTo=center,pos+Vector(0,0,2)
        end
    end
    for i = 1, 2 do
        local pos = point(c, i == 1 and 1 or 5)
        local positions = {}; for _, p in ipairs(d.reinforced) do positions[#positions+1] = p end; positions[#positions+1] = pos
        if B:ValidateRoutes(c, positions, 50) then
            local o = B:Object(c, {kind = 'moshi_reinforced', model = 'models/props_c17/concrete_barrier001a.mdl',
                pos = pos, hp = 0, radius = 45, permanent = true, solid = true, label = 'REINFORCED STOP: BAIT UNSTABLE CHARGE'})
            if o then d.reinforced[#d.reinforced+1] = pos end
        end
    end
    self:Fill(c)
end
-- Four shallow stair approaches create two real dry islands without sealing lanes.
function D:DrainageFloor(c)
    local d, center=c.data,B:Center(c)
    d.dryPlatforms={}
    B:Object(c,{kind='moshi_central_grate',model='models/hunter/plates/plate1x1.mdl',
        pos=center+Vector(0,0,2),scale=2.4,hp=0,solid=false,permanent=true,
        color=Color(55,75,90),label='CENTRAL DRAINAGE FLOOR'})
    for i,sector in ipairs({8,3}) do
        local pos=B:Floor(c,center+(point(c,sector)-center)*.8)
        local room=pos~=nil
        if room then
            for _,dx in ipairs({-128,128}) do for _,dy in ipairs({-100,100}) do
                if not B:Floor(c,pos+Vector(dx,dy,0)) then room=false end
            end end
        end
        -- Conservative bypass proof in addition to the six-unit walk-up step rise.
        if room and #(c.geometry or {})+8<=24 and B:ValidateRoutes(c,{pos},165) then
            local west=B:StaticRamp(c,{pos=pos+Vector(-64,0,0),yaw=0,width=200,length=128,height=24,steps=4,label='DRY PLATFORM WEST APPROACH'})
            local east=B:StaticRamp(c,{pos=pos+Vector(64,0,0),yaw=180,width=200,length=128,height=24,steps=4,label='DRY PLATFORM EAST APPROACH'})
            if west or east then
                local platform={pos=pos,width=200,length=256,height=24,west=west,east=east}
                d.dryPlatforms[#d.dryPlatforms+1]=platform
                if i==1 then d.dry=pos end
                local marker=B:Object(c,{kind='moshi_dry_platform',model='models/hunter/plates/plate1x1.mdl',
                    pos=pos+Vector(0,0,25),hp=0,solid=false,permanent=true,scale=.25,
                    color=Color(220,210,145),label='RAISED DRY PLATFORM: WALK UP EITHER END'})
                if marker then marker.platform=platform end
            end
        end
    end
    B:Log(c,'moshi_drainage_floor',{platforms=#d.dryPlatforms,steps=#(c.geometry or {})})
end
function D:WetZone(c, pos, suds)
    pos = safe(c, pos, suds and 110 or 125)
    if not pos then return end
    -- Already-cleared drains remain helpful for the encounter, not mandatory switches.
    for _, drain in ipairs(c.data.drains) do
        if drain.cleared and pos:DistToSqr(drain.drainPos) < 250^2 then return end
    end
    local z = B:Zone(c, {kind = 'moshi_wet', label = suds and 'SUDS: VERY SLIPPERY' or 'WET FLOOR', pos = pos,
        radius = suds and 110 or 125, delay = .8, life = 11, interval = 1,
        traction = suds and .48 or .72, color = suds and Color(195,225,240) or Color(75,140,205)})
    if z then
        local kept = {}; for _, old in ipairs(c.data.wet) do if not old.retired then kept[#kept+1] = old end end
        kept[#kept+1] = z; c.data.wet = kept
    end
end
function D:Fill(c)
    action(c, c.phase >= 2 and 'FILL: HEAVY SUDS' or 'FILL')
    c.actor:SetNW2String('LOD_BossCycle', 'Fill')
    c.actor:EmitSound('ambient/water/water_spray1.wav', 70, 95)
    for i = 1, 3 do self:WetZone(c, point(c, i * 2 + c.data.round % 2), c.phase >= 2 and i % 2 == 0) end
    B:Warn(c, 'GUARANTEED DRY SPACE', c.data.dry, 4, 100, {color = Color(220,220,140)})
end
function D:ClearDrain(c, o)
    if o.cleared then return end
    o.cleared, o.state = true, 'DRAIN CLEAR'
    for _, z in ipairs(c.data.wet) do
        local pos = z.pos or (z.spec and z.spec.pos)
        if pos and not z.retired and pos:DistToSqr(o.drainPos) < 250^2 then B:Clear(c, z) end
    end
    B:Log(c, 'moshi_drain_clear', {object = o.id})
    B:Announce(c, 'DRAIN CLEARED: NEARBY FLOOR DRYING')
end
function D:ObjectEvent(c, o, event, payload)
    if o.spec.kind == 'moshi_drain' and (event == 'destroy' or (event == 'use' and B:Hero(c, payload))) then self:ClearDrain(c, o) end
end
function D:Eject(c, pos, class)
    local cfg = debris[class]
    c.data.shot = c.data.shot + 1
    local serial = c.data.shot
    c.data.openUntil = math.max(c.data.openUntil, c.now + cfg.tell + .8)
    action(c, 'OPEN DRUM: ' .. string.upper(class) .. ' LOAD')
    B:Warn(c, string.upper(class) .. ' LAUNDRY', pos, cfg.tell, cfg.radius * 4)
    B:Later(c, cfg.tell, 'moshi_eject_' .. serial, function(owner)
        local origin = owner.actor:GetPos() + Vector(0,0,70)
        B:Projectile(owner, {kind = 'moshi_debris', role = class, model = cfg.model, pos = origin,
            velocity = (pos - origin):GetNormalized() * cfg.speed + Vector(0,0,170), gravity = cfg.gravity,
            mass = cfg.mass, radius = cfg.radius, life = cfg.life, hp = class == 'heavy' and 24 or 10,
            bounces = class == 'heavy' and 1 or 0, breakOnImpact = class ~= 'heavy', color = cfg.color,
            damage = physical(cfg.damage, cfg.push), label = string.upper(class) .. ' LOAD'})
    end)
end
function D:SpinCharge(c, pos, lostSock)
    local d = c.data
    local unstable = c.phase >= 2
    action(c, lostSock and 'THE LOST SOCK: OFF-ANGLE SPIN CHARGE' or (unstable and 'OFF-BALANCE SPIN' or 'SPIN CHARGE'))
    c.actor:EmitSound('physics/metal/metal_box_strain2.wav', 80, unstable and 125 or 95)
    -- The curved path is fixed at launch. It never follows the Hero after final lock.
    B:Charge(c, c.actor, pos, {label = d.action, warning = lostSock and .85 or (unstable and 1.5 or 1.2),
        speed = lostSock and 680 or (c.phase == 3 and 570 or 440), width = lostSock and 105 or 75,
        lateralArc = unstable and (d.round % 2 == 0 and 55 or -55) or 0,
        damage = physical(lostSock and 28 or 20, 230), recovery = 2.4,
        onFinish = function(owner, hit, finish, trace)
            local recovery = hit and 1.3 or 2.8
            if owner.phase >= 2 and trace and trace.Hit and finish then
                for _, wall in ipairs(owner.data.reinforced) do
                    if finish:DistToSqr(wall) < 150^2 then recovery = 4.5; action(owner, 'SPIN-OUT: SUSPENSION FAILED'); break end
                end
            end
            owner.data.recoverUntil, owner.data.openUntil = owner.now + recovery, owner.now + recovery
            B:Stagger(owner, recovery, owner.actor)
            if not hit then action(owner, 'SKID / WOBBLE: OPEN DRUM') end
        end})
end
function D:LostSock(c, target)
    action(c, 'THE LOST SOCK')
    B:Announce(c, 'THE LOST SOCK')
    local origin = c.actor:GetPos() + Vector(0,0,75)
    -- Harmless clue: no Damage spec, no hidden hit, finite lifetime and budget.
    B:Projectile(c, {kind = 'moshi_sock', model = 'models/props_junk/garbage_bag001a.mdl', pos = origin,
        velocity = Vector(110,0,130), gravity = 280, mass = .1, radius = 3, life = 2,
        scale = .15, color = Color(235,220,180), label = 'ONE HARMLESS SOCK', breakOnImpact = true})
    local pos = B:Floor(c, target:GetPos()) or B:Center(c)
    local delta = pos - origin
    local direction = Vector(delta.x, delta.y, 0):GetNormalized()
    local side = Vector(-direction.y, direction.x, 0)
    local offAngle = B:Floor(c, pos + side * (c.data.round % 2 == 0 and 100 or -100)) or pos
    B:Later(c, 1.15, 'moshi_lost_sock_charge', function(owner) D:SpinCharge(owner, offAngle, true) end)
end
function D:ViolentSpin(c)
    local d = c.data
    action(c, 'VIOLENT SPIN: LOOSE SUSPENSION')
    B:Warn(c, 'ORBITING LAUNDRY: KEEP CLEAR', c.actor:GetPos(), .8, 150)
    B:Later(c, .8, 'moshi_orbit', function(owner)
        for i = 1, 3 do
            local theta = i * math.pi * 2 / 3
            local origin = owner.actor:GetPos() + Vector(math.cos(theta)*110, math.sin(theta)*110, 65)
            local o = B:Projectile(owner, {kind = 'moshi_debris', role = 'orbit', model = debris.light.model,
                pos = origin, velocity = Vector(-math.sin(theta)*230,math.cos(theta)*230,0), gravity = 0,
                mass = 3, radius = 10, life = 3.5, hp = 12, damage = physical(10,45), breakOnImpact = true, label = 'VIOLENT SPIN DEBRIS'})
            if o then o.orbitStart, o.orbitUntil, o.orbitAngle = owner.now, owner.now + 1.8, theta; owner.data.orbits[#owner.data.orbits+1] = o end
        end
    end)
end
function D:Rinse(c)
    action(c, 'RINSE CYCLE: DIRECTIONAL WATER BANDS')
    local center = B:Center(c)
    for i = 1, 3 do
        local start, finish = point(c, i * 2), point(c, i * 2 + 1)
        local delta, rel = finish - start, c.data.dry - start
        local length = delta:Dot(delta)
        local t = length > 0 and math.max(0,math.min(1,rel:Dot(delta)/length)) or 0
        local clear=(start+delta*t):DistToSqr(c.data.dry)>175^2
        for _,platform in ipairs(c.data.dryPlatforms or {}) do
            local rel=platform.pos-start
            local closest=length>0 and math.max(0,math.min(1,rel:Dot(delta)/length)) or 0
            if (start+delta*closest):DistToSqr(platform.pos)<245^2 then clear=false end
        end
        if clear then
            B:Zone(c, {kind = 'moshi_rinse', label = 'RINSE BAND ' .. i, pos = start, finish = finish, shape = 'lane', width = 65,
                delay = .9 + (i - 1) * .8, life = .6, interval = .7, traction = .8,
                color = Color(120,190,230), onTick = function(owner, zone, heroes)
                    -- Push has no damage and follows the visible band direction.
                    for _, hero in ipairs(heroes) do B:Push(owner, hero, delta:GetNormalized(), 105, owner.actor) end
                end})
        end
    end
end
function D:NextCycle(c, target)
    local d = c.data
    if d.cycle == 'Fill' then
        d.cycle, d.cycleEnd, d.nextShot, d.openUntil = 'Wash', c.now + 4.5, c.now, c.now + 1.4
        action(c, 'WASH: DRUM OPEN')
    elseif d.cycle == 'Wash' then
        d.cycle, d.cycleEnd = 'Spin', c.now + 5
        if c.phase == 3 then
            self:ViolentSpin(c)
            if d.round % 2 == 0 then self:LostSock(c, target)
            else
                local pos = B:Floor(c, target:GetPos()) or B:Center(c)
                B:Later(c, 1.4, 'moshi_violent_charge', function(owner) D:SpinCharge(owner, pos) end)
            end
        else self:SpinCharge(c, B:Floor(c, target:GetPos()) or B:Center(c)) end
    elseif d.cycle == 'Spin' then
        d.cycle, d.cycleEnd, d.openUntil = 'Drain', c.now + 3.5, c.now + 2
        B:Clear(c, 'moshi_wet'); d.wet = {}
        action(c, 'DRAIN: DOOR OPEN')
        if c.phase >= 2 then self:Rinse(c) end
    else
        d.cycle, d.cycleEnd, d.round = 'Fill', c.now + 4, d.round + 1
        self:Fill(c)
    end
    c.actor:SetNW2String('LOD_BossCycle', d.cycle)
end
function D:BeforeDamage(c, actor, info)
    if actor ~= c.actor or c.now >= c.data.openUntil then return end
    local pos = info:GetDamagePosition()
    local front = c.actor:GetPos() + c.actor:GetForward() * 34 + Vector(0,0,48)
    if pos and pos:DistToSqr(front) <= 58^2 then info:ScaleDamage(1.2) end
end
function D:Think(c, now, dt, targets)
    local d, target = c.data, targets[1]
    if not target then return end
    local keep = {}
    for _, o in ipairs(d.orbits) do
        if not o.retired and now < o.orbitUntil then
            local theta = o.orbitAngle + (now - o.orbitStart) * 2.2
            local destination = c.actor:GetPos() + Vector(math.cos(theta)*110, math.sin(theta)*110,65)
            local delta = destination - o.pos
            o.velocity = delta:GetNormalized() * math.min(360,delta:Length()*6)
            keep[#keep+1] = o
        end
    end
    d.orbits = keep
    local open = now < d.openUntil
    if d.doorOpen ~= open then d.doorOpen = open; c.actor:SetNW2Bool('LOD_BossDoorOpen',open) end
    if now < (d.recoverUntil or 0) then return end
    if now >= d.cycleEnd then self:NextCycle(c, target); return end
    if d.cycle == 'Wash' and now >= d.nextShot then
        local classes = c.phase == 1 and {'light','medium'} or {'light','medium','heavy'}
        self:Eject(c, B:Floor(c,target:GetPos()) or B:Center(c), classes[d.shot % #classes + 1])
        d.nextShot = now + 1.8
    elseif c.phase == 3 and d.cycle == 'Fill' then
        if now >= d.nextWalk then d.walkIndex = d.walkIndex + 1; d.walkPos = point(c,d.walkIndex+2); d.nextWalk = now + 1.2; action(c,'WALKING WASHER') end
        if d.walkPos then B:Move(c,c.actor,d.walkPos,180,{mode='bounce',height=45,turnRate=2.5}) end
    end
end
function D:Pause(c)
    c.data.orbits = {}
    B:Clear(c,'moshi_debris'); B:Clear(c,'moshi_rinse'); B:Clear(c,'moshi_wet'); c.data.wet = {}
    -- Restart only the readable action cycle; cleared drains and battle phase persist.
    c.data.cycle, c.data.cycleEnd, c.data.openUntil = 'Drain', c.now + 2, 0
end
function D:Phase(c) self:Pause(c); action(c,self.phaseNames[c.phase]) end
function D:Snapshot(c)
    local cleared = 0; for _, o in ipairs(c.data.drains) do if o.cleared then cleared = cleared + 1 end end
    return (c.data.action or '') .. ' | ' .. c.data.cycle .. ' | Drains ' .. cleared .. '/' .. #c.data.drains
end
function D:Defeat(c)
    local deathPosition=c.actor:GetPos()
    c.actor:SetNW2Int('LOD_BossDeathStage',1)
    action(c,'FINAL VIOLENT SPIN')
    B:Later(c,.8,'cosmetic:moshi_ding',function(owner)
        if IsValid(owner.actor) then
            owner.actor:EmitSound('buttons/bell1.wav',80,110)
            owner.actor:SetNW2Bool('LOD_BossDoorOpen',true); owner.actor:SetNW2Int('LOD_BossDeathStage',2)
        end
        action(owner,'DING! CYCLE COMPLETE')
        for i=1,3 do B:Object(owner,{kind='moshi_clean_laundry',model=debris.light.model,pos=deathPosition+Vector(0,0,65),
            velocity=Vector(i*35-70,70,70),gravity=300,mass=.1,life=3,scale=.3,cosmetic=true,label='CLEAN LAUNDRY'}) end
    end)
    B:Later(c,1.6,'cosmetic:moshi_last_sock',function(owner)
        B:Object(owner,{kind='moshi_final_sock',model=debris.light.model,pos=deathPosition+Vector(0,0,60),velocity=Vector(40,30,80),
            gravity=250,mass=.1,life=3,scale=.15,cosmetic=true,label='ONE LAST SOCK'})
        if IsValid(owner.actor) then owner.actor:SetNW2Int('LOD_BossDeathStage',3) end
    end)
end
function D:ActorReplaced(c, actor)
    actor:SetNW2String('LOD_BossAction',c.data.action or '')
    actor:SetNW2String('LOD_BossCycle',c.data.cycle)
    actor:SetNW2Bool('LOD_BossDoorOpen',c.now<c.data.openUntil)
end
B:Register('moshi',D)
