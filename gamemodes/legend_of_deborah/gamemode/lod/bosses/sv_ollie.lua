-- Dungeon 5: a finite basket, interruptible purchases and authored shopping routes.
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
    hull = {mins=Vector(-32,-24,0),maxs=Vector(32,24,78)},
    name = 'Ollie the Trolly', model = 'models/props_junk/ShoppingCart01a.mdl',
    baseHP = 920, speed = 150, size = 1.45, maxObjects = 20, maxAdds = 3,
    phaseNames = {'Cleanup on Aisle Six', 'Everything Must Go', 'NO RECEIPT'},
    arena = {theme = 'checkout', width = 6, depth = 5}, deathCaption = 'THANK YOU FOR SHOPPING',
    presentation = {body = 'shopping-cart', motion = 'rolling-drifting', basket = true},
    deathSequence = {'broken wheel', 'veers into corral', 'basket tips', 'Jail Key drops'}
}
local catalog = {
    can = {name = 'SOUP CAN BARRAGE', model = 'models/props_junk/garbage_metalcan001a.mdl', speed = 520, mass = 3, damage = 9, gravity = 220, life = 3, count = 3},
    ball = {name = 'BOWLING BALL', model = 'models/props_phx/misc/soccerball.mdl', speed = 420, mass = 42, damage = 22, gravity = 100, life = 5, push = 210, expose = true},
    melon = {name = 'ANGRY MELON', model = 'models/props_junk/watermelon01.mdl', speed = 380, mass = 12, damage = 15, gravity = 390, life = 4, blast = 105},
    explosive = {name = 'EXPLOSIVE PURCHASE', model = 'models/props_junk/propane_tank001a.mdl', speed = 320, mass = 18, damage = 20, gravity = 450, life = 5, blast = 135, fuse = 2.1, expose = true},
    groceries = {name = 'BAD GROCERIES', model = 'models/props_junk/garbage_bag001a.mdl'},
    crabs = {name = 'CART FULL OF CRABS', model = 'models/headcrabclassic.mdl'},
    spring = {name = 'SPRING-LOADED PROP', model = 'models/props_junk/wood_crate001a.mdl', speed = 720, mass = 16, damage = 16, gravity = 100, life = 2.5, push = 165},
    mystery = {name = 'MYSTERY BAG', model = 'models/props_junk/garbage_bag001a.mdl'}
}
local first = {'can', 'ball', 'spring', 'explosive'}
local full = {'can', 'ball', 'melon', 'explosive', 'groceries', 'crabs', 'spring'}
local function action(c, text)
    c.data.action = text
    if IsValid(c.actor) then c.actor:SetNW2String('LOD_BossAction', text) end
end
local function targetPoint(c, p) return B:Floor(c, p:GetPos()) or B:Center(c) end
local function packet(n, push) return {kind = 'melee', damage = n, dice = {2, 6, n - 7}, reference = n, push = push or 0} end
function D:Start(c)
    local d = c.data
    d.nextAttack, d.attackIndex, d.nextSpree, d.nextPrice = c.now + 2, 0, c.now + 22, c.now + 12
    d.highUntil, d.recovery, d.safe = 0, 0, point(c, 8)
    d.route = {point(c, 2), point(c, 4), point(c, 6)}
    d.corrals = {point(c, 1), point(c, 5)}
    local aisles = {point(c,3),point(c,7)}
    if B:ValidateRoutes(c,aisles,30) then
        for _,pos in ipairs(aisles) do
            B:Object(c,{kind='ollie_aisle',model='models/props_c17/FurnitureShelf001a.mdl',pos=pos,
                permanent=true,solid=true,radius=28,hp=0,label='CHECKOUT AISLE: CROSS ROUTES OPEN'})
        end
    end
    for i, pos in ipairs(d.corrals) do
        B:Object(c, {kind = 'ollie_corral', role = tostring(i), model = 'models/props_c17/Handrail04_Short.mdl',
            pos = pos, permanent = true, solid = false, hp = 0, label = 'CART RETURN: BAIT CART CRASH HERE'})
    end
    for i = 1, 6 do
        local item = full[(i - 1) % #full + 1]
        local o = B:Object(c, {kind = 'ollie_loose', model = catalog[item].model, pos = d.route[(i - 1) % 3 + 1] + Vector((i % 2) * 42, 0, 14),
            hp = 12, radius = 12, mass = 8, permanent = true, solid = false, pushable = true, label = 'SHOPPING SPREE STOCK: SHOOT TO REMOVE'})
        if o then o.purchase = item end
    end
    action(c, 'BASKET LOADED')
end
function D:Launch(c, item, pos)
    local cfg = catalog[item]
    if not cfg then return end
    B:Log(c, 'ollie_purchase', {item = item})
    if item == 'groceries' then
        if pos:DistToSqr(c.data.safe) < 240^2 then return end
        B:Zone(c, {kind = 'ollie_groceries', label = cfg.name, pos = pos, radius = 120, delay = .7, life = 5, interval = 1,
            damage = {kind = 'venom', damage = 7, dice = {1, 6, 3.5}, reference = 7}, color = Color(105,145,55)})
    elseif item == 'crabs' then
        for i = 1, math.min(2, 3 - B:CountActors(c, 'cart_crab')) do
            B:QueueAdd(c, 'bigcrab', 'cart_crab', point(c, i + 2), {scale = .65, name = 'Cart Crab', manual = false})
        end
    else
        local origin = c.actor:GetPos() + Vector(0,0,72)
        for i = 1, cfg.count or 1 do
            local offset = (i - ((cfg.count or 1) + 1) / 2) * 32
            local direction = (pos + Vector(offset, -offset, 20) - origin):GetNormalized()
            B:Projectile(c, {kind = 'ollie_purchase', model = cfg.model, pos = origin, velocity = direction * cfg.speed + Vector(0,0,cfg.gravity * .35),
                mass = cfg.mass, gravity = cfg.gravity, life = cfg.life, hp = 10, radius = item == 'ball' and 15 or 11,
                bounces = item == 'ball' and 1 or 0, breakOnImpact = item ~= 'ball' and item ~= 'explosive',
                fuse = cfg.fuse, explodeRadius = cfg.blast or 0, damage = packet(cfg.damage, cfg.push), label = cfg.name,
                color = item == 'ball' and Color(40,30,65) or Color(220,210,175)})
        end
    end
end
function D:Pull(c, item, pos, sequence)
    if not B:Live(c) or not catalog[item] then return false end
    local d, cfg = c.data, catalog[item]
    if item == 'mystery' then
        if c.now < d.highUntil and not sequence then return false end
        d.highUntil = c.now + 6
        action(c, 'MYSTERY BAG: KNOWN DANGER, NO REFUNDS')
        local remix = {'explosive', 'melon', 'ball'}
        local chosen = B:Random(c, 'mystery_remix', 1, #remix)
        for i = 1, 2 do
            local purchase = remix[(chosen + i - 2) % #remix + 1]
            B:Later(c, .5 + i * 1.3, 'ollie_mystery_' .. i, function(owner) D:Pull(owner, purchase, pos, true) end)
        end
        return true
    end
    d.recovery = math.max(d.recovery, c.now + 2.55)
    action(c, 'RUMMAGE: ' .. cfg.name)
    c.actor:EmitSound('physics/metal/metal_box_strain1.wav', 70, 110)
    B:Warn(c, cfg.name, pos, 1.15, cfg.blast or 65)
    d.pullSerial = (d.pullSerial or 0) + 1
    local serial = d.pullSerial
    local exposed
    if cfg.expose then
        exposed = B:Object(c, {kind = 'ollie_exposed', model = cfg.model, pos = c.actor:GetPos() + Vector(0,0,88),
            hp = 16, mass = 1, life = 1.5, solid = false, label = 'EXPOSED ' .. cfg.name .. ': SHOOT TO INTERRUPT'})
        if exposed then exposed.purchase, exposed.pullSerial = item, serial end
    end
    B:Later(c, 1.15, 'ollie_pull_' .. serial, function(owner)
        if exposed and exposed.interrupted then return end
        if exposed then B:RemoveObject(owner, exposed, 'thrown') end
        D:Launch(owner, item, pos)
        owner.data.recovery = math.max(owner.data.recovery, owner.now + 1.4)
        action(owner, 'RELOADING BASKET: PUNISH')
    end)
    return true
end
function D:ObjectEvent(c, o, event)
    if o.spec.kind == 'ollie_exposed' and event == 'destroy' and not o.interrupted then
        o.interrupted = true
        B:Cancel(c, 'ollie_pull_' .. o.pullSerial)
        B:Stagger(c, 2, c.actor)
        c.data.recovery = c.now + 2
        if o.purchase == 'explosive' then B:SelfDamage(c, 16, 'explosive_purchase_backfire', c.actor) end
        action(c, 'PURCHASE REJECTED: BASKET STUN')
    end
end
function D:ShoppingSpree(c)
    local d = c.data
    if c.now < d.highUntil then return false end
    d.spree = {step = 1, collected = {}, deadline = c.now + 10}
    d.highUntil, d.nextSpree = c.now + 20, c.now + 34
    action(c, 'SHOPPING SPREE: DESTROY LOOSE STOCK')
    B:Announce(c, 'SHOPPING SPREE')
    return true
end
function D:FinishSpree(c, target)
    local d, spree = c.data, c.data.spree
    if not spree then return end
    d.spree = nil
    -- Immutable catalog snapshot: late damage/movement cannot change a committed sequence.
    local frozen = {}
    for i, item in ipairs(spree.collected) do frozen[i] = item end
    local pos = targetPoint(c, target)
    d.highUntil = c.now + #frozen * 1.8 + 2
    d.disgorge = {remaining = frozen, count = #frozen}
    local inventory = d.disgorge
    B:Log(c, 'ollie_spree_frozen', {count = #frozen})
    for i, item in ipairs(frozen) do
        local purchase = item
        B:Later(c, (i - 1) * 1.8, 'ollie_spree_' .. i, function(owner)
            inventory.remaining[i] = nil
            D:Pull(owner, purchase, pos, true)
        end)
    end
    if #frozen == 0 then B:Stagger(c, 3, c.actor); action(c, 'EMPTY BASKET: FREE WINDOW') end
end
function D:Crash(c, destination)
    action(c, c.phase == 3 and 'CART CRASH: DAMAGED WHEEL' or 'EXPRESS CHECKOUT')
    local admitted = B:Charge(c, c.actor, destination, {label = c.data.action, warning = 1.2, speed = c.phase == 3 and 650 or 440,
        width = 70, damage = packet(c.phase == 3 and 24 or 16, 260), recovery = 2,
        onFinish = function(owner, hit, pos)
            owner.data.motionUntil = 0
            owner.data.recovery = owner.now + 2
            for _, corral in ipairs(owner.data.corrals) do
                if pos and pos:DistToSqr(corral) < 145^2 then
                    owner.data.recovery = owner.now + 4
                    B:Stagger(owner, 4, owner.actor); action(owner, 'CART CORRAL: STUCK')
                    break
                end
            end
        end})
    if admitted then c.data.motionUntil = c.now + 1.2 + (destination - c.actor:GetPos()):Length() / (c.phase == 3 and 650 or 440) + 1 end
end
function D:Think(c, now, dt, targets)
    local d, target = c.data, targets[1]
    if not target then return end
    if d.spree then
        if d.spree.step > #d.route then self:FinishSpree(c, target); return end
        local pos = d.route[d.spree.step]
        local reached = B:Move(c, c.actor, pos, 220, {mode = 'skate', turnRate = 3.5})
        if reached or c.actor:GetPos():DistToSqr(pos) < 100^2 then
            for _, o in ipairs(B:Objects(c, 'ollie_loose')) do
                if o.pos:DistToSqr(pos) < 170^2 then
                    d.spree.collected[#d.spree.collected + 1] = o.purchase
                    B:RemoveObject(c, o, 'collected')
                end
            end
            d.spree.step = d.spree.step + 1
            if d.spree.step > #d.route then self:FinishSpree(c, target) end
        elseif now >= d.spree.deadline then self:FinishSpree(c, target) end
        return
    end
    if now < (d.motionUntil or 0) then return end
    if now < d.recovery or now < d.highUntil then B:Stop(c, c.actor); return end
    if c.phase >= 2 and now >= d.nextSpree and #B:Objects(c, 'ollie_loose') > 0 then self:ShoppingSpree(c); return end
    if d.priceTarget then
        if now < d.priceUntil and B:TargetLive(c, d.priceTarget) then
            B:Move(c, c.actor, d.priceTarget.player:GetPos(), 260, {mode = 'skate', turnRate = c.phase == 3 and 1.8 or 4})
            return
        end
        local binding = d.priceTarget
        d.priceTarget = nil
        if B:TargetLive(c, binding) then self:Crash(c, targetPoint(c, binding.player)) end
        return
    end
    if c.phase >= 2 and now >= d.nextPrice then
        d.priceTarget, d.priceUntil, d.nextPrice = B:BindTarget(c, target), now + 3.5, now + 18
        action(c, 'PRICE CHECK: SCANNER LOCK')
        c.actor:EmitSound('buttons/blip1.wav', 75, 120)
        return
    end
    if now < d.nextAttack then
        B:Move(c, c.actor, target:GetPos(), c.phase == 3 and 205 or 150, {mode = 'skate', turnRate = c.phase == 3 and 1.5 or 4})
        return
    end
    d.attackIndex, d.nextAttack = d.attackIndex + 1, now + (c.phase == 3 and 3.8 or 4.5)
    if c.phase == 3 and d.attackIndex % 3 == 0 then self:Crash(c, targetPoint(c, target)); return end
    if B:Random(c, 'harmless_dud', 1, 16) == 1 then
        action(c, 'ONE EXPIRED COUPON. NOTHING HAPPENS.'); d.recovery = now + 2.5; B:Stagger(c, 2.5, c.actor); return
    end
    local list = c.phase == 1 and first or full
    local item = c.phase == 3 and d.attackIndex % 4 == 0 and 'mystery' or list[(d.attackIndex - 1) % #list + 1]
    self:Pull(c, item, targetPoint(c, target))
end
function D:Pause(c)
    c.data.priceTarget = nil
    c.data.motionUntil = 0
    if c.data.disgorge then
        local remaining = {}
        for i=1,c.data.disgorge.count do
            local item=c.data.disgorge.remaining[i]
            if item then remaining[#remaining+1]=item end
        end
        if #remaining > 0 then c.data.spree={step=#c.data.route+1,collected=remaining,deadline=c.now} end
        c.data.disgorge=nil
    end
    if c.data.spree then c.data.spree.deadline = c.now + 10 end
    c.data.highUntil, c.data.recovery, c.data.nextAttack = c.now + 1.5, c.now + 1.5, c.now + 2
    B:Clear(c, 'ollie_exposed')
end
function D:Phase(c)
    self:Pause(c)
    action(c, self.phaseNames[c.phase])
end
function D:Snapshot(c)
    return (c.data.action or '') .. ' | Loose stock ' .. #B:Objects(c, 'ollie_loose') .. ' | Cart crabs ' .. B:CountActors(c, 'cart_crab') .. '/3'
end
function D:KeyPosition(c)
    local pos=c.data.deathDestination or c.data.corrals[1]
    return B:SafePoint(c,pos+Vector(75,0,0)) or B:Center(c)
end
function D:Defeat(c)
    local origin=c.actor:GetPos()
    local nearest=c.data.corrals[1]
    for _,pos in ipairs(c.data.corrals) do if pos:DistToSqr(origin)<nearest:DistToSqr(origin) then nearest=pos end end
    c.data.deathDestination=nearest
    action(c, 'BROKEN WHEEL: RETURNING CART')
    c.actor:SetNW2Int('LOD_BossDeathStage', 1)
    B:Later(c, 1, 'cosmetic:ollie_tip', function(owner)
        if IsValid(owner.actor) then
            owner.actor:SetNW2Int('LOD_BossDeathStage', 2)
            owner.actor:EmitSound('physics/metal/metal_box_break1.wav', 80, 95)
        end
        action(owner, 'THANK YOU FOR SHOPPING')
    end)
end
function D:ActorReplaced(c, actor)
    actor:SetNW2String('LOD_BossAction',c.data.action or '')
end
B:Register('ollie', D)
