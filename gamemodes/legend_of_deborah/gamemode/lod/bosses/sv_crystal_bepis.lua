-- Dungeon 6: all soda packets enter shared Poisoned; vending stock is encounter-owned.
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
    name = 'Crystal Bepis', model = 'models/Humans/Group01/female_02.mdl', baseHP = 1000, speed = 145,
    size = 1.1, maxObjects = 18, maxAdds = 0, phaseNames = {'Refreshingly Toxic', 'Six-Pack Problem', 'DIET CRYSTAL'},
    arena = {theme = 'break_room', width = 6, depth = 5}, deathCaption = 'THANK YOU',
    presentation = {body = 'woman', weapon = 'poisonous-soda', finiteVendingStock = 4},
    deathSequence = {'last can rolls', 'SOLD OUT', 'slump against machine', 'last can drops', 'Jail Key in return'}
}
local canModel = 'models/props_junk/PopCan01a.mdl'
local function action(c, text)
    c.data.action = text
    if IsValid(c.actor) then c.actor:SetNW2String('LOD_BossAction', text) end
end
local function poison(damage, push)
    return {kind = 'venom', damage = damage, reference = damage, dice = {2, 6, damage - 7}, push = push or 0}
end
local function safeSoda(c, pos, radius)
    local p = B:Floor(c, pos)
    if not p or p:DistToSqr(c.data.safe) < (radius + 90)^2 then return nil end
    return p
end
function D:Start(c)
    local d = c.data
    d.stock, d.jammed, d.runs, d.attackIndex = 4, false, 0, 0
    d.nextThirst, d.nextAttack, d.furiousUntil, d.buffUntil = c.now + 18, c.now + 2, 0, 0
    d.safe, d.machinePos = point(c, 8), point(c, 2)
    d.machine = B:Object(c, {kind = 'bepis_machine', model = 'models/props_interiors/VendingMachineSoda01a.mdl',
        pos = d.machinePos, hp = 0, permanent = true, solid = false, use = true, hold = 1.5,
        label = 'SODA STOCK 4/4', useLabel = 'HOLD E: JAM NEXT VENDING ATTEMPT'})
    action(c, 'SODA STOCK 4/4')
end
function D:ObjectEvent(c, o, event, payload)
    if o ~= c.data.machine or event ~= 'use' or not B:Hero(c, payload) then return end
    local d = c.data
    if d.stock <= 0 or d.jammed then return end
    d.jammed = true
    o.state = 'JAMMED: ONE ATTEMPT'
    B:Announce(c, 'VENDING MACHINE JAMMED: ONE ATTEMPT')
    B:Log(c, 'bepis_jam', {remaining = d.stock})
end
function D:Spray(c, pos, label, life, radius)
    pos = safeSoda(c, pos, radius or 110)
    if not pos then return end
    B:Zone(c, {kind = 'bepis_spray', label = label, pos = pos, radius = radius or 110, delay = .75,
        life = life or 4, interval = 1, damage = poison(7), color = Color(65,155,95)})
end
function D:Toss(c, pos, mode)
    local origin = c.actor:GetPos() + Vector(0,0,60)
    local fast = mode == 'FASTBALL'
    local skip = mode == 'CAN SKIP'
    local velocity = (pos + Vector(0,0,24) - origin):GetNormalized() * (fast and 720 or (skip and 560 or 390))
    if not fast and not skip then velocity = velocity + Vector(0,0,210) end
    B:Projectile(c, {kind = 'bepis_can', model = canModel, pos = origin, velocity = velocity,
        gravity = fast and 60 or (skip and 170 or 420), mass = 2, hp = 7, radius = 8, life = 4,
        bounces = skip and 2 or 0, breakOnImpact = not skip, label = mode,
        damage = poison(fast and 15 or 11, skip and 30 or 0), explodeRadius = not fast and not skip and 95 or 0})
end
function D:Attack(c, pos, name)
    action(c, name)
    if name == 'SODA POP' then
        B:Warn(c, name, c.actor:GetPos(), .8, 145)
        local origin = c.actor:GetPos()
        B:Later(c, .8, 'bepis_pop', function(owner) B:Area(owner, origin, 145, poison(12, 180)) end)
    elseif name == 'SHAKEN CAN' then self:Spray(c, pos, name, 4)
    elseif name == 'SODA FOUNTAIN' then
        local origin = c.actor:GetPos()
        local direction = (pos - origin):GetNormalized()
        local side = Vector(-direction.y, direction.x, 0)
        for i = -1, 1 do
            local endpoint = B:Floor(c, origin + direction * 380 + side * (i * 110))
            local safeLane = false
            if endpoint then
                local lane,rel=endpoint-origin,c.data.safe-origin
                local length=lane:Dot(lane)
                local t=length>0 and math.max(0,math.min(1,rel:Dot(lane)/length)) or 0
                safeLane=(origin+lane*t):DistToSqr(c.data.safe)>190^2
            end
            if endpoint and safeLane then
                B:Zone(c, {kind = 'bepis_spray', label = name .. ': SWEEP ' .. (i + 2), pos = origin, finish = endpoint,
                    shape = 'lane', width = 60, delay = .9 + (i + 1) * .65, life = .6, interval = .65,
                    damage = poison(10), color = Color(70,165,90)})
            end
        end
    else
        local count = name == 'SIX-PACK' and 6 or 1
        for i = 1, count do
            local slot = i
            local aim = pos + Vector(((i - 1) % 3 - 1) * (count > 1 and 65 or 0), math.floor((i - 1) / 3) * 65, 0)
            B:Warn(c, name, aim, .9 + (i - 1) * .16, 65)
            B:Later(c, .9 + (i - 1) * .16, 'bepis_toss_' .. slot, function(owner) D:Toss(owner, aim, name) end)
        end
    end
end
function D:StartRun(c, signature)
    local d = c.data
    if d.stock <= 0 or d.run then return false end
    B:Cancel(c, 'bepis_pop')
    for i=1,6 do B:Cancel(c, 'bepis_toss_' .. i) end
    d.runs = d.runs + 1
    d.run = {started = c.now, deadline = c.now + 8, focused = 0, focusUntil = 0, lastPos = c.actor:GetPos(), lost = 0}
    d.nextThirst = c.now + (c.phase == 3 and 16 or 22)
    -- The signature commits marked positions before the sprint; it never retargets replacements.
    if signature then
        action(c, 'CRYSTAL CLEAR')
        for i = 1, 4 do
            local pos = point(c, i + 2)
            self:Spray(c, pos, 'CRYSTAL CLEAR ' .. i, 4.5, 95)
        end
    else action(c, 'CRYSTAL IS THIRSTY') end
    B:Announce(c, 'CRYSTAL IS THIRSTY | STOCK ' .. d.stock .. '/4')
    B:Log(c, 'bepis_vending_run', {stock = d.stock, signature = signature == true})
    return true
end
function D:EndRun(c, reached, reason)
    local d = c.data
    if not d.run then return end
    d.run = nil
    B:Stop(c, c.actor)
    if reached and d.jammed then
        d.jammed = false
        d.furiousUntil, d.recoverUntil = c.now + 4, c.now + 3
        B:Stagger(c, 3, c.actor)
        action(c, 'JAMMED! FURIOUS AND EXPOSED')
    elseif reached and d.stock > 0 then
        d.stock = d.stock - 1
        local heal = c.actor:GetMaxHealth() * (c.phase == 3 and .05 or .09)
        B:Heal(c, heal, c.actor)
        d.recoverUntil = c.now + 2.5
        if c.phase == 3 then d.buffUntil = c.now + 7 end
        action(c, d.stock == 0 and 'SOLD OUT' or 'DRINKING: STOCK ' .. d.stock .. '/4')
        B:Log(c, 'bepis_drink', {stock = d.stock, heal = heal, diet = c.phase == 3})
    else
        d.recoverUntil = c.now + 2
        B:Stagger(c, 2, c.actor)
        action(c, 'VENDING RUN STOPPED: ' .. (reason or 'INTERRUPTED'))
    end
    d.nextAttack = math.max(d.nextAttack, d.recoverUntil or c.now)
    if d.machine and not d.machine.retired then d.machine.state = d.stock == 0 and 'SOLD OUT' or (d.jammed and 'JAMMED: ONE ATTEMPT' or 'STOCK ' .. d.stock .. '/4') end
end
function D:AfterDamage(c, actor, amount)
    local run = c.data.run
    if actor ~= c.actor or not run then return end
    if c.now > run.focusUntil then run.focused = 0 end
    run.focusUntil, run.focused = c.now + 1.4, run.focused + amount
    if run.focused >= c.actor:GetMaxHealth() * .065 then self:EndRun(c, false, 'FOCUSED STAGGER') end
end
function D:BeforeDamage(c, actor, info)
    if actor == c.actor and c.now < c.data.furiousUntil then info:ScaleDamage(1.2) end
end
function D:Think(c, now, dt, targets)
    local d, target = c.data, targets[1]
    if not target then return end
    if d.run then
        local run = d.run
        local reached, blocked = B:Move(c, c.actor, d.machinePos, 300, {turnRate = 5, stopDistance = 62})
        if reached or c.actor:GetPos():DistToSqr(d.machinePos) < 70^2 then self:EndRun(c, true); return end
        if blocked then run.lost = run.lost + dt else run.lost = math.max(0, run.lost - dt) end
        if now >= run.deadline or run.lost >= 2 then self:EndRun(c, false, 'ROUTE DENIED') end
        return
    end
    if now < (d.recoverUntil or 0) then B:Stop(c, c.actor); return end
    if d.stock > 0 and now >= d.nextThirst then self:StartRun(c, c.phase >= 2 and (d.runs + 1) % 2 == 0); return end
    local buff = now < d.buffUntil
    if now < d.nextAttack then
        B:Move(c, c.actor, point(c, d.attackIndex + 3), buff and 185 or 145, {turnRate = 4})
        return
    end
    local pos = B:Floor(c, target:GetPos()) or B:Center(c)
    d.attackIndex = d.attackIndex + 1
    d.nextAttack = now + (buff and 2.1 or 2.9)
    local first = {'BEPIS TOSS', 'SHAKEN CAN', 'FASTBALL', 'SODA POP'}
    local later = {'SIX-PACK', 'SODA FOUNTAIN', 'CAN SKIP', 'BEPIS TOSS', 'SHAKEN CAN', 'FASTBALL'}
    local list = c.phase == 1 and first or later
    self:Attack(c, pos, c.actor:GetPos():DistToSqr(pos) < 125^2 and 'SODA POP' or list[(d.attackIndex - 1) % #list + 1])
end
function D:Pause(c)
    -- Stock and the one-shot jam are retained; stale attack/run commitments are not.
    c.data.run = nil
    c.data.nextThirst = math.max(c.data.nextThirst, c.now + 3)
    c.data.nextAttack = c.now + 2
end
function D:Phase(c)
    self:Pause(c)
    action(c, self.phaseNames[c.phase])
end
function D:Snapshot(c)
    return (c.data.action or '') .. ' | ' .. (c.data.stock == 0 and 'SOLD OUT' or 'SODA ' .. c.data.stock .. '/4') .. (c.data.jammed and ' | JAM READY' or '')
end
function D:KeyPosition(c)
    -- Explicit authored vending-return drop, still validated by the common key service.
    return B:SafePoint(c, c.data.machinePos + Vector(80,0,0)) or B:Center(c)
end
function D:Defeat(c)
    c.data.deathDestination=c.data.machinePos+Vector(80,0,0)
    action(c, 'SOLD OUT')
    c.actor:SetNW2Int('LOD_BossDeathStage', 1)
    B:Object(c, {kind = 'bepis_final_can', model = canModel, pos = c.data.machinePos + Vector(0,0,65),
        cosmetic = true, life = 4, velocity = Vector(35,0,0), gravity = 350, mass = 1, label = 'ONE LAST CAN'})
    B:Later(c, 1.5, 'cosmetic:bepis_thank_you', function(owner)
        if IsValid(owner.actor) then owner.actor:SetNW2Int('LOD_BossDeathStage', 2); owner.actor:EmitSound('buttons/button14.wav', 70, 95) end
        action(owner, 'THANK YOU')
    end)
end
function D:ActorReplaced(c, actor)
    actor:SetNW2String('LOD_BossAction',c.data.action or '')
end
B:Register('crystal_bepis', D)
