-- Dungeon 11: heat/pressure -> emergency vent -> explicitly cooled punish window.
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
    hull = {mins=Vector(-24,-45,0),maxs=Vector(24,45,90)},
    name = 'Ray D. Aitor', model = 'models/props_c17/consolebox01a.mdl', baseHP = 1250, speed = 110,
    size = 1.7, maxObjects = 18, maxAdds = 0, phaseNames = {'Central Heating', 'Pressure Rising', 'REDLINE'},
    arena = {theme = 'boiler_room', width = 6, depth = 6}, deathCaption = 'PRESSURE ZERO',
    presentation = {body = 'radiator', heat = true, valves = true},
    deathSequence = {'pressure zero', 'tiny hiss', 'pipe clangs', 'radiator tips', 'key from fins'}
}
-- Stock HL2 radiator, with no Workshop asset dependency.
D.model = 'models/props_interiors/Radiator01a.mdl'
local pipeModel = 'models/props_canal/mattpipe.mdl'
local function action(c, text)
    c.data.action = text
    if IsValid(c.actor) then c.actor:SetNW2String('LOD_BossAction', text) end
end
local function fire(n, push) return {kind = 'flame', content = 'fire', damage = n, reference = n, dice = {2,6,n-7}, push = push or 0} end
local function physical(n, push) return {kind = 'melee', damage = n, reference = n, dice = {2,8,n-9}, push = push or 0} end
local function safeZone(c, pos, radius)
    pos = B:Floor(c, pos)
    if not pos or pos:DistToSqr(c.data.safe) < (radius + 100)^2 then return nil end
    return pos
end
function D:Start(c)
    local d = c.data
    d.pressure, d.mode, d.nextAttack, d.attackIndex, d.vents = 0, 'HEATING', c.now + 2, 0, 0
    d.nextSignature, d.nextLeak, d.safe, d.hotZones = c.now + 36, c.now + 5, point(c, 8), {}
    d.valves = {}
    for i = 1, 2 do
        local o = B:Object(c, {kind = 'ray_valve', model = 'models/props_c17/TrapPropeller_Lever.mdl', pos = point(c, i * 3),
            hp = 0, permanent = true, solid = false, use = true, hold = .5, useLabel = 'E: OPEN RELIEF VALVE', label = 'RELIEF VALVE READY'})
        if o then o.readyAt = 0; d.valves[#d.valves+1] = o end
    end
    local covers={point(c,1),point(c,5)}
    if B:ValidateRoutes(c,covers,45) then
        for _,pos in ipairs(covers) do
            B:Object(c,{kind='ray_hard_cover',model='models/props_c17/concrete_barrier001a.mdl',pos=pos,
                permanent=true,solid=true,radius=42,hp=0,label='PERMANENT BOILER COVER'})
        end
    end
    for _,o in ipairs(d.valves) do
        B:Object(c,{kind='ray_manifold',model=pipeModel,pos=o.pos+Vector(0,0,45),permanent=true,solid=false,hp=0,label='RELIEF MANIFOLD'})
    end
    action(c, 'CENTRAL HEATING')
end
function D:HeatZone(c, pos, label, radius, delay, life, finish)
    pos = safeZone(c, pos, radius)
    if not pos then return nil end
    if finish then
        -- A lane cannot cross the reserved safe opening, even if both endpoints are safe.
        local delta, rel = finish - pos, c.data.safe - pos
        local dot = delta:Dot(delta)
        local t = dot > 0 and math.max(0, math.min(1, rel:Dot(delta) / dot)) or 0
        if (pos + delta * t):DistToSqr(c.data.safe) < (radius + 100)^2 then return nil end
    end
    local z = B:Zone(c, {kind = 'ray_hot', label = label, pos = pos, radius = radius, width = radius * 2,
        finish = finish, shape = finish and 'lane' or 'circle', delay = delay, life = life, interval = 1,
        damage = fire(9, 35), color = Color(230,110,55)})
    if z then
        local kept = {}
        for _, old in ipairs(c.data.hotZones) do if not old.retired then kept[#kept+1] = old end end
        kept[#kept+1] = z; c.data.hotZones = kept
    end
    return z
end
function D:ObjectEvent(c, o, event, payload)
    if o.spec.kind ~= 'ray_valve' or event ~= 'use' or not B:Hero(c, payload) or c.now < o.readyAt then return end
    local d = c.data
    o.readyAt, o.state = c.now + 18, 'RELIEF COOLDOWN'
    for _, z in ipairs(d.hotZones) do
        local pos = z.pos or (z.spec and z.spec.pos)
        if not z.retired and pos and pos:DistToSqr(o.pos) <= 280^2 then B:Clear(c, z) end
    end
    if d.mode == 'VENTING' or d.mode == 'VENT WARNING' then
        d.ventEnd = math.max(c.now + .8, d.ventEnd - 1.5)
        d.coolBonus = math.min(3, (d.coolBonus or 0) + 1.5)
    elseif d.mode == 'COOLED' then
        local bonus = math.min(1.5, 3 - (d.coolBonus or 0))
        d.coolEnd, d.coolBonus = d.coolEnd + bonus, (d.coolBonus or 0) + bonus
    else d.pressure = math.max(0, d.pressure - 12) end
    B:Announce(c, 'RELIEF VALVE OPEN: LOCAL HEAT CLEARED')
    B:Log(c, 'ray_relief', {mode = d.mode, coolBonus = d.coolBonus or 0})
end
function D:StartVent(c, major)
    local d = c.data
    if d.mode == 'VENT WARNING' or d.mode == 'VENTING' or d.mode == 'COOLED' then return false end
    d.mode, d.pressure, d.ventStart, d.ventEnd = 'VENT WARNING', 100, c.now + 3, c.now + 7
    d.coolBonus, d.majorVent, d.ventZones = 0, major == true, {}
    B:Stop(c, c.actor)
    action(c, 'OVERPRESSURE: EMERGENCY VENT')
    c.actor:EmitSound('ambient/alarms/klaxon1.wav', 80, 95)
    c.actor:SetNW2Int('LOD_BossHeat', 3)
    B:Warn(c, 'SAFE RELIEF OPENING', d.safe, 7, 90, {color = Color(80,185,220)})
    for i = 1, 4 do
        local pos = safeZone(c, point(c, i * 2), 115)
        if pos then B:Warn(c, 'EMERGENCY VENT ' .. i, pos, 3, 115) end
    end
    return true
end
function D:Cool(c)
    local d = c.data
    for _, z in ipairs(d.ventZones or {}) do B:Clear(c, z) end
    d.mode, d.pressure, d.vents = 'COOLED', 0, d.vents + 1
    d.coolEnd = c.now + (c.phase == 3 and 9 or 7) + (d.coolBonus or 0)
    B:Stagger(c, d.majorVent and 5 or 3, c.actor)
    c.actor:SetNW2Int('LOD_BossHeat', 0)
    action(c, 'COOLED: MAXIMUM VULNERABILITY')
    B:Log(c, 'ray_cooled', {untilTime = d.coolEnd, major = d.majorVent == true})
end
function D:PipeDown(c)
    local d = c.data
    if d.mode ~= 'HEATING' then return false end
    d.mode, d.signatureEnd, d.nextSignature = 'PIPE DOWN', c.now + 7, c.now + 40
    action(c, 'PIPE DOWN: PERIMETER TO INWARD')
    B:Announce(c, 'PIPE DOWN: FOLLOW THE OPENINGS')
    B:Stop(c, c.actor)
    for wave = 1, 3 do
        local ring = wave
        B:Later(c, (wave - 1) * 1.8, 'ray_pipe_down_' .. wave, function(owner)
            local center = B:Center(owner)
            for i = 1, 4 do
                local edge = point(owner, i * 2)
                local pos = center + (edge - center) * (1.15 - ring * .22)
                D:HeatZone(owner, pos, 'PIPE DOWN ' .. ring, 85, 1, 1.1)
            end
        end)
    end
    return true
end
function D:Pipe(c, pos, label)
    local origin = c.actor:GetPos() + Vector(0,0,70)
    B:Warn(c, label, pos, 1.3, 80)
    c.data.pipeSerial = (c.data.pipeSerial or 0) + 1
    B:Later(c, 1.3, 'ray_pipe_' .. c.data.pipeSerial, function(owner)
        B:Projectile(owner, {kind = 'ray_pipe', model = pipeModel, pos = origin,
            velocity = (pos - origin):GetNormalized() * 420 + Vector(0,0,180), gravity = 390, mass = 36,
            radius = 16, life = 4, hp = 20, bounces = 1, breakOnImpact = false, damage = fire(18, 115), label = label,
            color = Color(220,110,65)})
    end)
end
function D:Ram(c, pos)
    local origin = c.actor:GetPos()
    action(c, 'RADIATOR RAM')
    local admitted = B:Charge(c, c.actor, pos, {label = 'RADIATOR RAM', warning = 1.25, speed = 390, width = 80,
        damage = physical(23, 230), recovery = 2.8, onFinish = function(owner, hit)
            owner.data.chargeUntil = 0
            owner.data.recoverUntil = owner.now + (hit and 1.5 or 2.8)
            if not hit then B:Stagger(owner, 2.8, owner.actor); action(owner, 'RAM MISSED: COOLING RECOVERY') end
        end})
    if admitted then c.data.chargeUntil=c.now+1.25+(pos-origin):Length()/390+1 end
    if c.phase >= 2 then self:HeatZone(c, origin, 'THERMAL WAKE', 55, 1.6, 4, pos) end
end
function D:Attack(c, pos, name)
    action(c, name)
    if name == 'STEAM JET' then self:HeatZone(c, c.actor:GetPos(), name, 48, 1.1, 1, pos)
    elseif name == 'HOT PIPE' then
        local origin = c.actor:GetPos()
        B:Warn(c, name, origin, .95, 145)
        B:Later(c, .95, 'ray_hot_pipe', function(owner) B:Area(owner, origin, 145, fire(18, 90)) end)
    elseif name == 'RADIATOR RAM' then self:Ram(c, pos)
    elseif name == 'HEATED FLOOR' then self:HeatZone(c, pos, name, 115, 1.2, 5)
    elseif name == 'DETACHED PIPE' then self:Pipe(c, pos, name)
    elseif name == 'BURST MAIN' then
        for i = 1, 2 do self:HeatZone(c, point(c, i * 2), name .. ' ' .. i, 50, 1.2 + (i - 1) * .9, 1.2, point(c, i * 2 + 1)) end
    elseif name == 'PIPE SWEEP' then
        local dir = (pos - c.actor:GetPos()):GetNormalized()
        local side = Vector(-dir.y, dir.x, 0)
        local center = c.actor:GetPos() + dir * 140
        -- Broad lateral lane permits retreat, approach or flank; not an unavoidable full ring.
        self:HeatZone(c, center - side * 190, name, 55, 1.5, .8, center + side * 190)
    elseif name == 'PIPE BOMBARDMENT' then
        for i = 1, 3 do self:Pipe(c, point(c, i + c.data.attackIndex), name .. ' ' .. i) end
    elseif name == 'PRESSURE HOP' then
        local destination = B:Floor(c, pos)
        if destination then
            B:Warn(c, name, destination, 1.6, 115)
            c.data.hop = {pos = destination, start = c.now + 1.1, finish = c.now + 8}
            local admitted=B:Charge(c,c.actor,destination,{label='PRESSURE HOP',warning=1.1,speed=280,arc=95,width=70,minimumDuration=1.3,
                onFinish=function(owner,hit,pos,trace)
                    owner.data.hop=nil;owner.data.recoverUntil=owner.now+1.8
                    if not (trace and trace.cancelled) then B:Area(owner,pos,115,physical(18,180)) end
                end})
            if not admitted then c.data.hop=nil;c.data.recoverUntil=c.now+1 end
        end
    end
    c.data.pressure = math.min(100, c.data.pressure + (c.phase == 3 and 18 or 14))
end
function D:BeforeDamage(c, actor, info)
    if actor == c.actor and c.data.mode == 'COOLED' then info:ScaleDamage(1.3) end
end
function D:Think(c, now, dt, targets)
    local d, target = c.data, targets[1]
    if not target then return end
    for _, o in ipairs(d.valves) do if now >= o.readyAt and o.state == 'RELIEF COOLDOWN' then o.state = 'RELIEF VALVE READY' end end
    if d.mode == 'PIPE DOWN' then if now >= d.signatureEnd then d.mode = 'HEATING'; self:StartVent(c, true) end; return end
    if d.mode == 'VENT WARNING' then
        if now >= d.ventStart then
            d.mode = 'VENTING'
            for i = 1, 4 do
                local z = self:HeatZone(c, point(c, i * 2), 'EMERGENCY VENT', 115, 0, math.max(.1,d.ventEnd - now))
                if z then d.ventZones[#d.ventZones+1] = z end
            end
        end
        return
    end
    if d.mode == 'VENTING' then if now >= d.ventEnd then self:Cool(c) end; return end
    if d.mode == 'COOLED' then
        B:Move(c, c.actor, point(c, 3), 55, {turnRate = 1.5})
        if now >= d.coolEnd then d.mode, d.nextAttack = 'HEATING', now + 1.5; action(c, 'REHEATING') end
        return
    end
    if now < (d.chargeUntil or 0) then return end
    if d.hop then
        if now >= d.hop.finish then B:Stop(c,c.actor);d.hop=nil;d.recoverUntil=now+1.8 end
        return
    end
    if now < (d.recoverUntil or 0) then return end
    d.pressure = math.min(100, d.pressure + dt * (c.phase == 3 and 8 or 5))
    local heat = d.pressure >= 65 and 2 or 1
    if d.heat ~= heat then d.heat = heat; c.actor:SetNW2Int('LOD_BossHeat', heat) end
    if d.pressure >= 100 then self:StartVent(c); return end
    if c.phase >= 2 and now >= d.nextSignature then self:PipeDown(c); return end
    if c.phase == 3 and now >= d.nextLeak then self:HeatZone(c, c.actor:GetPos(), 'REDLINE LEAK: KEEP CLEAR', 85, .8, 2); d.nextLeak = now + 5 end
    if now < d.nextAttack then B:Move(c, c.actor, target:GetPos(), 110, {turnRate = 2.5}); return end
    local patterns = c.phase == 1 and {'STEAM JET','HOT PIPE','RADIATOR RAM','HEATED FLOOR'}
        or (c.phase == 2 and {'DETACHED PIPE','BURST MAIN','RADIATOR RAM','PIPE SWEEP'} or {'PIPE BOMBARDMENT','PRESSURE HOP','PIPE SWEEP','RADIATOR RAM'})
    d.attackIndex, d.nextAttack = d.attackIndex + 1, now + 3.8
    self:Attack(c, B:Floor(c, target:GetPos()) or B:Center(c), patterns[(d.attackIndex - 1) % #patterns + 1])
end
function D:Pause(c)
    c.data.hop = nil
    c.data.chargeUntil = 0
    if c.data.mode == 'PIPE DOWN' then c.data.mode = 'HEATING'; c.data.pressure = 100 end
    if c.data.mode == 'VENT WARNING' or c.data.mode == 'VENTING' then
        for _, z in ipairs(c.data.ventZones or {}) do B:Clear(c, z) end
        c.data.mode, c.data.pressure = 'HEATING', 100
    end
    c.data.nextAttack = c.now + 2
end
function D:Phase(c) self:Pause(c); action(c, self.phaseNames[c.phase]) end
function D:Snapshot(c) return (c.data.action or '') .. ' | ' .. c.data.mode .. ' | E: relief valves' end
function D:KeyPosition(c)
    return B:SafePoint(c,(c.data.deathPosition or B:Center(c))+Vector(70,0,0)) or B:Center(c)
end
function D:Defeat(c)
    c.data.deathPosition=c.actor:GetPos()
    c.data.pressure = 0
    c.actor:SetNW2Int('LOD_BossHeat', 0)
    c.actor:SetNW2Int('LOD_BossDeathStage', 1)
    c.actor:EmitSound('ambient/gas/steam2.wav', 60, 135)
    action(c, 'PRESSURE ZERO')
    B:Object(c, {kind = 'ray_last_pipe', model = pipeModel, pos = c.actor:GetPos() + Vector(0,0,80), velocity = Vector(40,0,80),
        gravity = 400, mass = 1, life = 3, cosmetic = true, label = 'CLANG'})
    B:Later(c, 1, 'cosmetic:ray_tip', function(owner)
        if IsValid(owner.actor) then owner.actor:SetNW2Int('LOD_BossDeathStage', 2); owner.actor:EmitSound('physics/metal/metal_barrel_impact_hard3.wav', 75, 85) end
    end)
end
function D:ActorReplaced(c, actor)
    actor:SetNW2String('LOD_BossAction',c.data.action or '')
    actor:SetNW2Int('LOD_BossHeat',c.data.mode=='COOLED' and 0 or (c.data.mode=='VENTING' and 3 or c.data.heat or 1))
end
B:Register('ray', D)
