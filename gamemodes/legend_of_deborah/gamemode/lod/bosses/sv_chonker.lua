-- Dungeon 2. Tiny stock pigeon, real skate/bomb/defuse encounter.
local B = LOD.BossEncounter
local D = {
    name = 'Chonker the Honker', model = 'models/pigeon.mdl', baseHP = 680,
    speed = 160, size = 1, maxObjects = 9, maxAdds = 0,
    phaseNames = {'The Honkening', 'Mine! Mine! Mine!', 'Chonker'},
    arena = {theme = 'industrial', width = 5, depth = 5},
    deathCaption = 'HONK', deathDuration = 2.6, keyLocation = 'center',
    presentation = {body = 'pigeon', motion = 'roller-skate', ordinarySize = true},
    deathSequence = {'failed skate-away', 'feet keep moving', 'tip over', 'final HONK'}
}
local bombTypes = {
    black = {hp = 24, fuse = 4, radius = 140, damage = 17, scale = .55, color = Color(24,24,24)},
    red = {hp = 30, fuse = 12, radius = 155, damage = 19, scale = .6, color = Color(215,35,30)},
    gold = {hp = 72, fuse = 6, radius = 215, damage = 24, scale = .85, color = Color(245,195,30)},
    big = {hp = 130, fuse = 8, radius = 290, damage = 29, scale = 1.3, color = Color(255,215,35)}
}
local function state(c, text)
    c.data.action = text
    if IsValid(c.actor) then c.actor:SetNW2String('LOD_BossAction', text) end
end
local function bombCount(c)
    return #B:Objects(c, 'chonker_bomb')
end
local function safePlacement(c, pos, radius)
    pos = B:Floor(c, pos)
    if not pos then return nil end
    -- One advertised escape anchor plus a connected route must survive every admission.
    if pos:DistToSqr(c.data.safe) < (radius + 90)^2 then return nil end
    local occupied = {}
    for _, o in ipairs(B:Objects(c, 'chonker_bomb')) do occupied[#occupied+1] = o.pos end
    occupied[#occupied+1] = pos
    if not B:ValidateRoutes(c, occupied, radius + 35) then return nil end
    return pos
end
function D:Start(c)
    c.data.nextAttack, c.data.nextWing, c.data.lap, c.data.cycle = c.now + 1.5, 0, 1, 0
    c.data.safe = B:Point(c, #c.points)
    state(c, 'CHASE / REPOSITION')
    B:Announce(c, 'CHONKER THE HONKER')
end
function D:PlaceBomb(c, kind, pos)
    local cfg = bombTypes[kind]
    if not cfg or bombCount(c) >= 8 then return nil end
    if (kind == 'gold' or kind == 'big') and c.data.gold and not c.data.gold.retired then return nil end
    pos = safePlacement(c, pos, cfg.radius)
    if not pos then return nil end
    local o = B:Object(c, {kind = 'chonker_bomb', role = kind, model = 'models/Combine_Helicopter/helicopter_bomb01.mdl',
        pos = pos + Vector(0,0,12), hp = cfg.hp, radius = 14, mass = 12, scale = cfg.scale,
        life = cfg.fuse + 2, color = cfg.color, label = kind == 'big' and 'THE BIG ONE: SHOOT TO BACKFIRE' or string.upper(kind)..' BOMB: SHOOT TO DEFUSE',
        solid = false, pushable = true})
    if not o then return nil end
    o.bombType, o.state, o.armAt, o.blastAt = kind, 'PLACED', c.now + .8, c.now + cfg.fuse
    if kind == 'gold' or kind == 'big' then c.data.gold = o end
    if kind == 'big' then
        o.backfirePoint = B:Point(c, c.data.lap + 1)
        state(c, 'THE BIG ONE')
        B:Announce(c, 'THE BIG ONE! ESCAPE OR FOCUS FIRE')
    end
    B:Warn(c, o.spec.label, pos, cfg.fuse, cfg.radius)
    B:Log(c, 'chonker_bomb_placed', {kind = kind, object = o.id, fuse = cfg.fuse})
    return o
end
function D:Defuse(c, o)
    if o.kind ~= 'chonker_bomb' and (not o.spec or o.spec.kind ~= 'chonker_bomb') then return end
    if o.done then return end
    o.done, o.state = true, 'DEFUSED'
    if c.data.gold == o then c.data.gold = nil end
    B:Log(c, 'chonker_bomb_defused', {kind = o.bombType, object = o.id})
    if o.bombType == 'big' and B:Live(c) then
        B:Warn(c, 'BACKFIRE INTO CHONKER\'S ROUTE', o.backfirePoint or c.actor:GetPos(), .35, 75)
        B:Later(c, .35, 'chonker_backfire', function(owner)
            B:Stop(owner, owner.actor)
            B:Stagger(owner, 4.5, owner.actor)
            owner.data.recoverUntil = owner.now + 4.5
            state(owner, 'BIG ONE BACKFIRE: PUNISH')
        end)
    end
end
function D:ObjectEvent(c, o, event)
    if event == 'destroy' then self:Defuse(c, o) end
end
function D:Detonate(c,o)
    if B.SourceLive and o.sourceBinding and not B:SourceLive(c,o.sourceBinding) then return end
    if B.Callback then return B:Callback(c,o,self.DetonateBound,self,c,o) end
    return self:DetonateBound(c,o)
end
function D:DetonateBound(c, o)
    if o.done or o.retired then return end
    o.done, o.state = true, 'DETONATED'
    local cfg = bombTypes[o.bombType]
    B:Area(c, o.pos, cfg.radius, {kind = 'blast', damage = cfg.damage, reference = 17, push = 210, origin = o.pos})
    if c.data.gold == o then c.data.gold = nil end
    B:RemoveObject(c, o, 'detonated')
end
function D:ServiceBombs(c, now, targets)
    for _, o in ipairs(B:Objects(c, 'chonker_bomb')) do
        if not o.done then
            if now >= o.armAt and o.state == 'PLACED' then o.state = o.bombType == 'red' and 'PROXIMITY ARMED' or 'FUSE LIT' end
            if o.bombType == 'red' and o.state == 'PROXIMITY ARMED' then
                for _, p in ipairs(targets) do
                    if B:Hero(c,p) and p:GetPos():DistToSqr(o.pos) <= 115^2 then
                        o.state, o.blastAt = 'TRIGGERED: EVADE', now + .85
                        B:Warn(c, 'RED MINE TRIGGERED', o.pos, .85, bombTypes.red.radius)
                        break
                    end
                end
            end
            if o.bombType == 'red' and o.state ~= 'TRIGGERED: EVADE' and now >= o.blastAt then
                o.done, o.state = true, 'EXPIRED SAFELY'
                B:RemoveObject(c, o, 'expired')
            elseif now >= o.blastAt then self:Detonate(c, o) end
        end
    end
end
function D:WingFlap(c)
    c.data.nextWing = c.now + 4
    state(c, 'WING-FLAP PUSH')
    local pos = c.actor:GetPos()
    B:Warn(c, 'WING-FLAP PUSH', pos, .45, 105)
    B:Later(c, .45, 'chonker_wings', function(owner)
        B:Area(owner, pos, 105, {kind = 'melee', damage = 5, reference = 17, push = 260, origin = pos})
    end)
end
function D:Think(c, now, dt, targets)
    self:ServiceBombs(c, now, targets)
    if (c.data.recoverUntil or 0) > now then return end
    local p = targets[1]
    if not p then return end
    if now >= c.data.nextWing and p:GetPos():DistToSqr(c.actor:GetPos()) < 95^2 then self:WingFlap(c) end
    local point = B:Point(c, c.data.lap)
    local reached, blocked = B:Move(c, c.actor, point, c.phase == 1 and 160 or (c.phase == 2 and 235 or 275), {mode = 'skate', turnRate = 1.8, stopDistance = 50})
    if reached or blocked then c.data.lap = c.data.lap % #c.points + 1 end
    if now < c.data.nextAttack then return end
    c.data.cycle = c.data.cycle + 1
    local cycle = c.data.cycle
    c.data.nextAttack = now + (c.phase == 1 and 3.5 or 2.5)
    if c.phase == 3 and cycle % 4 == 0 then
        self:PlaceBomb(c, cycle % 8 == 0 and 'big' or 'gold', B:Point(c, c.data.lap + 1))
    elseif c.phase >= 2 and cycle % 3 == 0 then
        state(c, 'FAST BOMB-DROPPING LAP')
        for n = 1, 3 do
            B:Later(c, (n-1)*.65, 'chonker_lap_'..n, function(owner)
                self:PlaceBomb(owner, n == 2 and 'red' or 'black', B:Point(owner, owner.data.lap + n))
            end)
        end
    else
        local kind = c.phase >= 2 and cycle % 2 == 0 and 'red' or 'black'
        local placement = kind == 'red' and B:Point(c, c.data.lap + 1) or c.actor:GetPos()
        self:PlaceBomb(c, kind, placement)
        if c.phase == 1 then
            B:Stop(c, c.actor); c.data.recoverUntil = now + .85
            state(c, 'PIGEON TAUNT: PUNISH'); B:Announce(c, 'honk')
        end
    end
end
function D:Phase(c, phase)
    c.data.nextAttack = c.now + 1.2
    state(c, self.phaseNames[phase])
end
function D:Pause(c)
    B:Clear(c, 'chonker_bomb')
    c.data.gold, c.data.recoverUntil = nil, nil
    c.data.nextAttack, c.data.nextWing = c.now + 1.5, c.now + 1
end
function D:Defeat(c)
    c.data.deathStage='failed_skate';state(c, 'FAILED SKATE-AWAY')
    B:Later(c,.8,'cosmetic:chonker_feet',function(owner)
        owner.data.deathStage='feet_running';state(owner,'FEET STILL MOVING / GOING NOWHERE')
    end)
    B:Later(c,1.5,'cosmetic:chonker_tip',function(owner)
        owner.data.deathStage='tipped';state(owner,'TIPPED OVER')
    end)
    B:Later(c,1.9,'cosmetic:chonker_honk',function(owner)
        owner.data.deathStage='final_honk';state(owner,'FINAL HONK');B:Announce(owner,'HONK');if B.Cue then B:Cue(owner,'honk') end
    end)
end
function D:Snapshot(c)
    return (c.data.action or '')..' | Bombs '..bombCount(c)..'/8 | SHOOT BOMBS TO DEFUSE'
end
B:Register('chonker', D)
