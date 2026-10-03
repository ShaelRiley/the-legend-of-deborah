-- Dungeon 3. Committed body bounces and independently pushable produce.
local B = LOD.BossEncounter
local D = {
    name = 'Felon the Melon', model = 'models/props_junk/watermelon01.mdl',
    baseHP = 840, speed = 185, size = 3.4, maxObjects = 18, maxAdds = 0, pushScale = 0,
    phaseNames = {'Melon on the Lam', 'Repeat Offender', 'Felony Melony'},
    arena = {theme = 'concrete_bowl', width = 6, depth = 5, ricochet = true},
    deathCaption = 'FELON SPLATTED', deathDuration = 3.8, keyLocation = 'center',
    presentation = {body = 'watermelon', motion = 'bounce', crackedPhase = 3},
    deathSequence = {'huge final bounce', 'splat', 'harmless chunk rolls past key'}
}
local function action(c, name)
    c.data.action = name
    if IsValid(c.actor) then c.actor:SetNW2String('LOD_BossAction', name) end
end
local function groundDirection(from, to)
    local delta = to - from; delta.z = 0
    if delta:LengthSqr() < 1 then return Vector(1,0,0) end
    return delta:GetNormalized()
end
function D:BuildBowl(c)
    local floor=B:Center(c)
    local minx,maxx,miny,maxy=floor.x,floor.x,floor.y,floor.y
    for _,point in ipairs(c.points) do
        -- Upper gallery points must not shift ground-court geometry.
        if math.abs(point.z-floor.z)<24 then
            minx,maxx=math.min(minx,point.x),math.max(maxx,point.x)
            miny,maxy=math.min(miny,point.y),math.max(maxy,point.y)
        end
    end
    local cx,cy=(minx+maxx)*.5,(miny+maxy)*.5
    local width=math.max(180,math.min(500,maxx-minx-360))
    local sideWidth=math.max(140,math.min(320,(maxy-miny-360)*.5))
    -- Six outward-rising shallow strips leave a 360-unit entry/jail corridor.
    -- The broad center stays lower; all steps are actual canonical collision boxes.
    local ramps={
        {pos=Vector(cx,miny+90,floor.z),yaw=270,width=width},
        {pos=Vector(cx,maxy-90,floor.z),yaw=90,width=width},
        {pos=Vector(minx+90,cy-180-sideWidth*.5,floor.z),yaw=180,width=sideWidth},
        {pos=Vector(minx+90,cy+180+sideWidth*.5,floor.z),yaw=180,width=sideWidth},
        {pos=Vector(maxx-90,cy-180-sideWidth*.5,floor.z),yaw=0,width=sideWidth},
        {pos=Vector(maxx-90,cy+180+sideWidth*.5,floor.z),yaw=0,width=sideWidth}
    }
    c.data.bowlRamps={}
    for _,spec in ipairs(ramps) do
        local grounded=B:Floor(c,spec.pos)
        if grounded and B:ValidateRoutes(c,{grounded},95) then
            spec.pos,spec.length,spec.height,spec.steps=grounded,180,32,4
            spec.label='SHALLOW CONCRETE BOWL RIM'
            local ramp=B:StaticRamp(c,spec)
            if ramp then c.data.bowlRamps[#c.data.bowlRamps+1]=ramp end
        end
    end
    B:Log(c,'felon_bowl_admitted',{ramps=#c.data.bowlRamps})
end
function D:Start(c)
    c.data.nextAttack, c.data.cycle, c.data.selfSpent = c.now + 1.8, 0, 0
    c.data.safe = B:Point(c, #c.points)
    c.data.lastPos, c.data.trappedAt = c.actor:GetPos(), c.now
    self:BuildBowl(c)
    action(c, 'MELON ON THE LAM')
end
function D:Smash(c, o)
    if o.smashed then return end
    o.smashed, o.state = true, 'HARMLESS CHUNKS'
    B:Log(c, 'felon_melon_smash', {object = o.id, impacts = o.impacts or 0})
    if B:Live(c) then
        -- Cosmetic fragments have no contact packet, use or collision body.
        for i = 1, 2 do
            B:Projectile(c, {kind = 'felon_chunk', model = 'models/props_junk/watermelon01_chunk02a.mdl',
                pos = o.pos, velocity = Vector(i == 1 and 75 or -75,40,65), gravity = 450,
                radius = 3, mass = 1, hp = 0, life = 1.1, bounces = 0, breakOnImpact = true,
                label = 'HARMLESS MELON CHUNK', scale = .8})
        end
    end
end
function D:Throw(c, destination, variant, origin)
    if #B:Objects(c, 'felon_melon') >= 12 then return nil end
    origin = origin or c.actor:GetPos() + Vector(0,0,58)
    local dir = groundDirection(origin, destination)
    local distance = math.min(900, (destination-origin):Length())
    local cfg = variant == 'bank' and {speed = 450, lift = 145, bounces = 3, mass = 12}
        or variant == 'trail' and {speed = 60, lift = 120, bounces = 1, mass = 8}
        or variant == 'rain' and {speed = 0, lift = -70, bounces = 1, mass = 12}
        or {speed = math.max(190, math.min(410, distance*.6)), lift = 265, bounces = 2, mass = 10}
    local o = B:Projectile(c, {kind = 'felon_melon', model = 'models/props_junk/watermelon01.mdl',
        pos = origin, velocity = dir*cfg.speed + Vector(0,0,cfg.lift), gravity = 430, radius = 16,
        mass = cfg.mass, hp = 18, scale = 1.15, life = 6, bounces = cfg.bounces,
        breakOnImpact = false, pushable = true, damage = {kind = 'melee', damage = 13, reference = 18, push = 160},
        label = variant == 'bank' and 'BANK SHOT: WALL RICOCHET' or 'ACCESSORY TO MELONY',
        onImpact = function(owner, object)
            object.impacts = (object.impacts or 0) + 1
            if object.impacts > cfg.bounces then
                self:Smash(owner, object); B:RemoveObject(owner, object, 'smashed'); return true
            end
        end,
        onExpire = function(owner, object) self:Smash(owner, object) end,
        onDestroy = function(owner, object, reason)
            if reason == 'damage' or reason == 'destroyed' or reason == 'impact' then self:Smash(owner, object) end
        end})
    if o then o.variant, o.state = variant or 'single', 'AIRBORNE / PUSHABLE' end
    return o
end
function D:ImpactPunish(c, heavy)
    B:Stop(c, c.actor)
    local duration = heavy and 1.8 or .9
    c.data.recoverUntil = c.now + duration
    B:Stagger(c, duration, c.actor)
    if c.phase == 3 and heavy then
        local cap = c.actor:GetMaxHealth()*.14
        local amount = math.min(c.actor:GetMaxHealth()*.012, math.max(0, cap-c.data.selfSpent))
        if amount > 0 then
            local applied=B:SelfDamage(c, amount, 'felon_hard_arena_impact') or 0
            c.data.selfSpent = c.data.selfSpent + applied
        end
    end
    action(c, heavy and 'HARD LANDING: PUNISH' or 'LANDING RECOVERY')
end
function D:Bounce(c, destination, kind)
    destination = B:Floor(c, destination)
    if not destination then return false end
    local cfg = kind == 'high' and {speed = 280, arc = 240, warning = 1.05}
        or kind == 'long' and {speed = 485, arc = 100, warning = .85}
        or {speed = 330, arc = 65, warning = .65}
    action(c, string.upper(kind)..' BOUNCE')
    c.data.bouncing, c.data.trappedAt = true, c.now
    local from = c.actor:GetPos()
    if c.phase >= 2 and kind == 'long' then
        for n = 1, 3 do
            local drop = from + (destination-from)*(n/4)
            B:Warn(c, 'MELON TRAIL', drop, cfg.warning + n*.3, 55)
            B:Later(c, cfg.warning+n*.3, 'felon_trail_'..n, function(owner)
                self:Throw(owner, drop, 'trail', drop+Vector(0,0,65))
            end)
        end
    end
    B:Charge(c, c.actor, destination, {label = string.upper(kind)..' BOUNCE', warning = cfg.warning,
        speed = cfg.speed, arc = cfg.arc, width = 58, recovery = kind == 'short' and .9 or 1.8,
        damage = {kind = 'melee', damage = kind == 'high' and 24 or 18, reference = 18, push = 240},
        onFinish = function(owner, hit, pos, trace)
            owner.data.bouncing = nil
            self:ImpactPunish(owner, kind ~= 'short')
            if owner.phase >= 2 and trace and trace.HitWorld and trace.HitNormal and math.abs(trace.HitNormal.z) < .5 then
                -- A single previewed rebound, never a mid-air tracking reversal.
                local direction = groundDirection(from, destination)
                local rebound = direction - trace.HitNormal*(2*direction:Dot(trace.HitNormal))
                local landing = B:Floor(owner, pos + rebound*220)
                if landing then
                    B:Warn(owner, 'WALL REBOUND', pos, 1.8, 55, {shape = 'lane', finish = landing, width = 110})
                    owner.data.bouncing, owner.data.trappedAt = true, owner.now
                    B:Later(owner, 1.8, 'felon_wall_rebound', function(current)
                        B:Charge(current, current.actor, landing, {label = 'WALL REBOUND', warning = .25,
                            speed = 320, arc = 65, width = 55, recovery = 1.6,
                            damage = {kind = 'melee', damage = 18, reference = 18, push = 190},
                            onFinish = function(final) final.data.bouncing=nil;self:ImpactPunish(final, true) end})
                    end)
                end
            end
        end})
    return true
end
function D:Spread(c, destination)
    action(c, 'MELON SPREAD')
    B:Warn(c, 'MELON SPREAD', destination, .85, 150)
    B:Later(c, .85, 'felon_spread', function(owner)
        for n = -1, 1 do self:Throw(owner, destination+Vector(0,n*150,0), 'spread') end
    end)
end
function D:BankShot(c, destination)
    -- Arena-author supplies actual ricochet anchors; a point is only a safe fallback.
    local walls = c.arena.ricochetPoints
    local bank = walls and #walls > 0 and walls[(c.data.cycle % #walls)+1] or B:Point(c, c.data.cycle+1)
    action(c, 'BANK SHOT')
    B:Warn(c, 'BANK SHOT: WATCH THE WALL', bank, 1, 65, {shape = 'lane', finish = destination, width = 100})
    B:Later(c, 1, 'felon_bank', function(owner) self:Throw(owner, bank, 'bank') end)
end
function D:ProduceRain(c)
    action(c, 'THE WHOLE PRODUCE SECTION')
    B:Announce(c, 'THE WHOLE PRODUCE SECTION! MARKED ZONES ONLY')
    local admitted = {}
    for n = 1, math.min(6, #c.points) do
        local pos = B:Point(c, c.data.cycle+n)
        if pos:DistToSqr(c.data.safe) > 210^2 then
            local candidate = {}; for _,p in ipairs(admitted) do candidate[#candidate+1] = p end
            candidate[#candidate+1] = pos
            if B:ValidateRoutes(c, candidate, 90) then
                admitted[#admitted+1] = pos
                B:Warn(c, 'FALLING MELON: SAFE ROUTE REMAINS', pos, 1.4+n*.16, 90)
                B:Later(c, 1.4+n*.16, 'felon_rain_'..n, function(owner)
                    self:Throw(owner, pos, 'rain', pos+Vector(0,0,350))
                end)
            end
        end
    end
    c.data.nextAttack = c.now + 5
end
function D:Think(c, now, dt, targets)
    if not targets[1] then return end
    if c.data.bouncing then
        if c.actor:GetPos():DistToSqr(c.data.lastPos) > 16^2 then
            c.data.lastPos, c.data.trappedAt = c.actor:GetPos(), now
        elseif now-c.data.trappedAt > 3.5 then
            B:Stop(c, c.actor); c.data.bouncing = nil
            action(c, 'HIGH ESCAPE BOUNCE')
            self:Bounce(c, B:Point(c, c.data.cycle+2), 'high')
            c.data.nextAttack = now + 4
        end
        return
    end
    if (c.data.recoverUntil or 0) > now or now < c.data.nextAttack then return end
    c.data.cycle = c.data.cycle+1
    local n = c.data.cycle
    local destination = targets[((n-1)%#targets)+1]:GetPos()
    c.data.nextAttack = now+(c.phase == 3 and 2.4 or 3.1)
    local grammar = c.phase == 1 and {'short','single','long','single','high'}
        or c.phase == 2 and {'short','spread','long','bank','high','single'}
        or {'rain','long','bank','spread','high','short','single'}
    local move = grammar[(n-1)%#grammar+1]
    if move == 'rain' then self:ProduceRain(c)
    elseif move == 'bank' then self:BankShot(c, destination)
    elseif move == 'spread' then self:Spread(c, destination)
    elseif move == 'single' then
        action(c, 'ACCESSORY TO MELONY')
        B:Warn(c, 'ACCESSORY TO MELONY', destination, .75, 65)
        B:Later(c, .75, 'felon_single', function(owner) self:Throw(owner, destination, 'single') end)
    else self:Bounce(c, destination, move) end
end
function D:Phase(c, phase)
    c.data.bouncing, c.data.recoverUntil = nil, nil
    c.data.nextAttack = c.now + 1.3
    if IsValid(c.actor) then c.actor:SetNW2Bool('LOD_BossCracked', phase == 3) end
    action(c, self.phaseNames[phase])
end
function D:Pause(c)
    c.data.bouncing, c.data.recoverUntil = nil, nil
    c.data.nextAttack, c.data.trappedAt = c.now+1.5, c.now
    B:Clear(c, 'felon_melon'); B:Clear(c, 'felon_chunk')
end
function D:Defeat(c)
    c.data.deathStage='huge_bounce';action(c,'ONE FINAL HUGE BOUNCE')
    B:Later(c,1.3,'cosmetic:felon_splat',function(owner)
        owner.data.deathStage='splat';action(owner,'SPLAT');B:Announce(owner,'FELON SPLATTED')
    end)
    B:Later(c,1.6,'cosmetic:felon_chunk',function(owner)
        owner.data.deathStage='rolling_chunk'
        B:Object(owner,{kind='felon_death_chunk',cosmetic=true,model='models/props_junk/watermelon01_chunk02a.mdl',
            pos=B:Center(owner)+Vector(-110,35,8),velocity=Vector(90,0,0),gravity=0,life=2.1,
            radius=3,mass=1,hp=0,label='HARMLESS LAST MELON CHUNK',solid=false})
    end)
end
function D:Snapshot(c) return (c.data.action or '')..' | Melons '..#B:Objects(c,'felon_melon')..'/12 | PUSH MELONS, EVADE FELON' end
B:Register('felon', D)
