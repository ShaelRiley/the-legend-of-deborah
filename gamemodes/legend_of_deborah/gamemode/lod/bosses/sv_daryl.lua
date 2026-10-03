-- Dungeon 7. Explicit visible fuses, bounded chain reactions and nonlethal self-damage.
local B = LOD.BossEncounter
local D = {
    name = 'Daryl the Barrel', model = 'models/props_c17/oildrum001_explosive.mdl',
    baseHP = 1160, speed = 125, size = 2.65, maxObjects = 22, maxAdds = 0,
    phaseNames = {'Roll Out', 'Chain Reaction', 'Highly Flammable'},
    arena = {theme = 'powder_yard', width = 6, depth = 5, blastCover = true, ramps = true},
    deathCaption = 'DARYL EXTINGUISHED', deathDuration = 6.8, keyLocation = 'center',
    presentation = {body = 'barrel', motion = 'roll', scorchedPhase = 3},
    deathSequence = {'melodramatic long fuse', 'huge harmless explosion', 'scorch mark', 'last barrel lights and fizzles'}
}
local function action(c, value)
    c.data.action = value
    if IsValid(c.actor) then c.actor:SetNW2String('LOD_BossAction', value) end
end
local function dir(from,to)
    local v = to-from; v.z = 0
    return v:LengthSqr() > 1 and v:GetNormalized() or Vector(1,0,0)
end
local function liveBarrels(c) return B:Objects(c, 'daryl_barrel') end
local function admit(c, pos)
    pos = B:Floor(c, pos)
    if not pos or pos:DistToSqr(c.data.safe) < 245^2 then return nil end
    local occupied = {}; for _, o in ipairs(liveBarrels(c)) do occupied[#occupied+1] = o.pos end
    occupied[#occupied+1] = pos
    return B:ValidateRoutes(c, occupied, 90) and pos or nil
end
-- Permanent Powder Yard geometry is admitted through the same route authority
-- as combat hazards. Racks are ordinary nonexplosive cover, never free bomb spawns.
function D:BuildYard(c)
    c.data.yardObjects,c.data.yardRamps={},{}
    local center=B:Center(c)
    local positions={}
    local function piece(kind,model,pos,radius,label)
        pos=B:Floor(c,pos)
        if not pos or pos:DistToSqr(c.data.safe)<180^2 then return nil end
        local proposed={};for _,p in ipairs(positions) do proposed[#proposed+1]=p end
        proposed[#proposed+1]=pos
        if not B:ValidateRoutes(c,proposed,radius+35) then return nil end
        local o=B:Object(c,{kind=kind,role='permanent_yard_cover',model=model,pos=pos+Vector(0,0,radius),
            radius=radius,hp=0,mass=120,solid=true,permanent=true,pushable=false,label=label})
        if o then positions[#positions+1]=pos;c.data.yardObjects[#c.data.yardObjects+1]=o end
        return o
    end
    -- Alternating islands leave the central long axis and both lateral bypasses open.
    for _,side in ipairs({-1,1}) do
        piece('daryl_blast_barrier','models/props_c17/concrete_barrier001a.mdl',
            center+Vector(side*230,side*180,0),65,'PERMANENT BLAST BARRIER: BREAK LINE OF SIGHT')
        local rack=piece('daryl_barrel_rack','models/props_c17/FurnitureShelf001a.mdl',
            center+Vector(side*430,-side*330,0),45,'BARREL RACK: NONEXPLOSIVE STOCK')
        if rack then
            local stock=B:Object(c,{kind='daryl_rack_stock',role='nonexplosive_rack_stock',cosmetic=true,
                model='models/props_c17/oildrum001.mdl',pos=rack.pos+Vector(0,0,32),radius=10,
                hp=0,scale=.55,solid=false,permanent=true,pushable=false,label='NONEXPLOSIVE STORED BARREL'})
            if stock then c.data.yardObjects[#c.data.yardObjects+1]=stock end
        end
    end
    local rampPositions={center+Vector(-450,-400,0),center+Vector(450,400,0)}
    for index,pos in ipairs(rampPositions) do
        local floor=B:Floor(c,pos)
        if floor and floor:DistToSqr(c.data.safe)>190^2 and B:ValidateRoutes(c,{floor},125) then
            local ramp=B:StaticRamp(c,{pos=floor,yaw=index==1 and 0 or 180,width=180,length=240,height=40,steps=4,label='POWDER YARD LOADING RAMP'})
            if ramp then c.data.yardRamps[#c.data.yardRamps+1]=ramp end
        end
    end
    B:Log(c,'daryl_yard_admitted',{objects=#c.data.yardObjects,ramps=#c.data.yardRamps})
end
function D:Start(c)
    c.data.safe = B:Point(c, #c.points)
    c.data.cycle, c.data.chainSpent, c.data.internalSpent = 0, 0, 0
    c.data.staggerCount, c.data.staggerImmuneUntil, c.data.lastBlast = 0, 0, -100
    c.data.nextAttack, c.data.nextPop, c.data.nextInternal = c.now+1.7, 0, c.now+14
    self:BuildYard(c)
    action(c, 'ROLL OUT')
end
function D:SetBarrelState(c, o, value, seconds)
    if o.done then return end
    o.state = value
    o.spec.pushable = value == 'STABLE'
    if value == 'ARMED' then
        o.criticalAt, o.explodeAt = c.now + (seconds or 1.8), c.now + (seconds or 1.8) + .8
        o.spec.label = o.blue and 'BLUE BARREL: PRESSURE FUSE' or 'ARMED BARREL: VISIBLE FUSE'
        B:Warn(c, o.spec.label, o.pos, (seconds or 1.8)+.8, o.blue and 170 or 150)
    elseif value == 'CRITICAL' then
        o.spec.label = o.blue and 'BLUE: PRESSURE BURST IMMINENT' or 'CRITICAL: EXPLOSION IMMINENT'
    else
        o.criticalAt, o.explodeAt = nil, nil
        o.spec.label = o.blue and 'BLUE BARREL: PUSH BLAST' or 'STABLE BARREL: PUSH TO REPOSITION'
    end
end
function D:Barrel(c, pos, style, forceBlue)
    if #liveBarrels(c) >= 12 then return nil end
    local landed = admit(c, pos)
    if not landed then return nil end
    local blue = forceBlue
    if blue == nil then blue = B:Random(c, 'blue_barrel', 1, 14) == 1 end
    local source = c.actor:GetPos() + Vector(0,0,70)
    local moving = style == 'toss' or style == 'rolling'
    local direction = dir(source, landed)
    local spec = {kind = 'daryl_barrel', role = 'lesser_barrel', model = 'models/props_c17/oildrum001_explosive.mdl',
        pos = moving and source or landed+Vector(0,0,24), radius = 21, hp = 36, life = 16,
        mass = 30, scale = .8, pushable = true, solid = false, bounces = style == 'toss' and 1 or 0,
        color = blue and Color(50,110,235) or Color(145,95,65), breakOnImpact = false,
        label = blue and 'BLUE BARREL: PUSH BLAST' or 'STABLE BARREL: PUSH TO REPOSITION',
        onImpact = function(owner, object, trace)
            if object.state == 'STABLE' and (not trace.HitNormal or trace.HitNormal.z > .35 or style == 'rolling') then
                object.velocity = Vector(0,0,0)
                self:SetBarrelState(owner, object, 'ARMED', 1.8)
                return not B:Hero(owner, trace.Entity)
            end
        end}
    if moving then
        spec.velocity = direction*(style == 'rolling' and 310 or math.min(360,(landed-source):Length()*.65)) + Vector(0,0,style == 'toss' and 250 or -35)
        spec.gravity = style == 'toss' and 430 or 0
        spec.damage = {kind = 'melee', damage = 7, reference = 22, push = 110}
    end
    local o = moving and B:Projectile(c, spec) or B:Object(c, spec)
    if not o then return nil end
    o.blue, o.style, o.state = blue, style or 'stationary', 'STABLE'
    o.armAt = moving and c.now+2 or nil
    B:Log(c, 'daryl_barrel_spawn', {object = o.id, style = style, blue = blue})
    return o
end
function D:BlastDaryl(c, position)
    if c.actor:GetPos():DistToSqr(position) > 185^2 then return end
    local maxHP = c.actor:GetMaxHealth()
    local damage = math.min(maxHP*.015, math.max(0, maxHP*.18-c.data.chainSpent))
    if damage > 0 then
        local applied=B:SelfDamage(c, damage, 'daryl_lesser_barrel_chain') or 0
        c.data.chainSpent = c.data.chainSpent+applied
    end
    if c.now >= c.data.staggerImmuneUntil then
        if c.now-c.data.lastBlast > 18 then c.data.staggerCount = 0 end
        c.data.staggerCount = c.data.staggerCount+1
        local window = math.max(.35, 1.6/(1+(c.data.staggerCount-1)*.65))
        B:Stagger(c, window, c.actor)
        c.data.staggerImmuneUntil = c.now+5
    end
    c.data.lastBlast = c.now
end
function D:Explode(c,o)
    if B.SourceLive and o.sourceBinding and not B:SourceLive(c,o.sourceBinding) then return end
    if B.Callback then return B:Callback(c,o,self.ExplodeBound,self,c,o) end
    return self:ExplodeBound(c,o)
end
function D:ExplodeBound(c, o)
    if o.done then return end
    o.done, o.state = true, o.blue and 'PRESSURE BURST' or 'DETONATED'
    B:Area(c, o.pos, o.blue and 190 or 155, {kind = 'blast', damage = o.blue and 2 or 23,
        reference = 22, push = o.blue and 370 or 190, origin = o.pos})
    B:Log(c, 'daryl_barrel_blast', {object = o.id, blue = o.blue})
    if o.blue then
        for _, other in ipairs(liveBarrels(c)) do
            if other ~= o and other.state == 'STABLE' and other.pos:DistToSqr(o.pos) < 240^2 then
                other.velocity = dir(o.pos, other.pos)*190 + Vector(0,0,65)
                B:Log(c, 'daryl_blue_reposition', {object = other.id})
            end
        end
    else
        self:BlastDaryl(c, o.pos)
        for _, other in ipairs(liveBarrels(c)) do
            if other ~= o and not other.done and other.state == 'STABLE' and other.pos:DistToSqr(o.pos) < 175^2 then
                self:SetBarrelState(c, other, 'ARMED', .8)
            end
        end
    end
    B:RemoveObject(c, o, 'detonated')
end
function D:ObjectEvent(c, o, event)
    if not o.spec or o.spec.kind ~= 'daryl_barrel' or o.done then return end
    if event == 'hit' and o.state == 'STABLE' then self:SetBarrelState(c, o, 'ARMED', 1.8)
    elseif event == 'destroy' and B:Live(c) then self:Explode(c, o) end
end
function D:ServiceFuses(c, now)
    for _, o in ipairs(liveBarrels(c)) do
        if not o.done then
            if o.state == 'STABLE' and o.armAt and now >= o.armAt then self:SetBarrelState(c,o,'ARMED',1.8) end
            if o.state == 'ARMED' and now >= o.criticalAt then self:SetBarrelState(c,o,'CRITICAL') end
            if o.explodeAt and now >= o.explodeAt then self:Explode(c,o) end
        end
    end
end
function D:FuseTransfer(c)
    local source, target
    for _, o in ipairs(liveBarrels(c)) do
        if not source and (o.state == 'ARMED' or o.state == 'CRITICAL') then source = o
        elseif not target and o.state == 'STABLE' then target = o end
    end
    if not source or not target then return false end
    action(c, 'FUSE TRANSFER')
    B:Warn(c, 'FUSE TRANSFER', source.pos, .8, 24, {shape = 'lane', finish = target.pos, width = 36})
    -- Source extinguishes only when the recipient is still present: no duplicated fuse.
    B:Later(c, .8, 'daryl_transfer', function(owner)
        if source.done or source.retired or target.done or target.retired or target.state ~= 'STABLE' then return end
        self:SetBarrelState(owner,source,'STABLE'); source.armAt = nil
        self:SetBarrelState(owner,target,'ARMED',1.4)
        B:Log(owner, 'daryl_fuse_transfer', {from = source.id, to = target.id})
    end)
    return true
end
function D:Pattern(c, style)
    action(c, style == 'signature' and 'BARREL OF MONKEYS, BUT EXPLOSIONS' or string.upper(style))
    local count = style == 'signature' and 7 or (style == 'cluster' and 3 or 4)
    local start, finish = B:Point(c,c.data.cycle+1), B:Point(c,c.data.cycle+5)
    local anchor = B:Point(c,c.data.cycle+2)
    for n = 1, count do
        local point = style == 'line' and start+(finish-start)*((n-1)/(count-1))
            or style == 'cluster' and anchor+Vector((n-2)*100,(n==2 and 90 or -45),0)
            or B:Point(c, c.data.cycle+n)
        local o = self:Barrel(c, point, 'stationary')
        if o then
            B:Warn(c, 'SEQUENTIAL IGNITION '..n, o.pos, 1.3+n*.6, 150)
            B:Later(c, 1.3+n*.6, 'daryl_pattern_'..n, function(owner)
                if not o.done and not o.retired and o.state == 'STABLE' then self:SetBarrelState(owner,o,'ARMED',style == 'cluster' and 1.5 or 1) end
            end)
        end
    end
    c.data.nextAttack = c.now + (style == 'signature' and 8.8 or 4.2)
    if style == 'signature' then
        B:Announce(c, 'BARREL OF MONKEYS, BUT EXPLOSIONS! FOLLOW THE SAFE GAPS')
        B:Later(c, 8.5, 'daryl_overheat', function(owner)
            action(owner, 'OVERHEATED: PUNISH'); B:Stagger(owner,3.3,owner.actor)
            owner.data.recoverUntil = owner.now+3.3
        end)
    end
end
function D:InternalFuse(c)
    local origin = c.actor:GetPos()
    c.data.internal, c.data.nextInternal, c.data.nextAttack = true, c.now+17, c.now+5.8
    B:Stop(c, c.actor)
    action(c, 'DARYL IS LIT')
    B:Announce(c, 'DARYL IS LIT! COVER OR DISTANCE')
    B:Warn(c, 'CONTROLLED DETONATION', origin, 4.5, 310)
    B:Later(c, 4.5, 'daryl_internal', function(owner)
        owner.data.internal = nil
        B:Area(owner, origin, 310, {kind = 'blast', damage = 34, reference = 22, push = 300, origin = origin})
        local hp = owner.actor:GetMaxHealth()
        local amount = math.min(hp*.02, math.max(0,hp*.10-owner.data.internalSpent))
        if amount > 0 then
            local applied=B:SelfDamage(owner,amount,'daryl_controlled_detonation') or 0
            owner.data.internalSpent = owner.data.internalSpent+applied
        end
        B:Stagger(owner,2.2,owner.actor); owner.data.recoverUntil = owner.now+2.2
        action(owner, 'VENTED: PUNISH')
    end)
end
function D:PressurePop(c)
    c.data.nextPop = c.now+4
    local pos = c.actor:GetPos()
    B:Warn(c, 'PRESSURE POP', pos, .5, 125)
    B:Later(c,.5,'daryl_pop',function(owner)
        B:Area(owner,pos,125,{kind='blast',damage=6,reference=22,push=255,origin=pos})
    end)
end
function D:Think(c, now, dt, targets)
    self:ServiceFuses(c,now)
    if not targets[1] or c.data.internal or (c.data.recoverUntil or 0)>now then return end
    if c.phase == 3 and now >= c.data.nextInternal then self:InternalFuse(c); return end
    local p = targets[1]
    if now >= c.data.nextPop and p:GetPos():DistToSqr(c.actor:GetPos())<110^2 then self:PressurePop(c) end
    if now < c.data.nextAttack then return end
    c.data.cycle = c.data.cycle+1; local n = c.data.cycle
    c.data.nextAttack = now+3.5
    local grammar = c.phase==1 and {'roll','toss','pop','toss'}
        or c.phase==2 and {'line','toss','transfer','roll','cluster','rolling'}
        or {'signature','roll','cluster','toss','transfer','rolling'}
    local move=grammar[(n-1)%#grammar+1]
    if move=='signature' or move=='line' or move=='cluster' then self:Pattern(c,move)
    elseif move=='transfer' then
        if not self:FuseTransfer(c) then self:Pattern(c,'line') end
    elseif move=='pop' then self:PressurePop(c)
    elseif move=='rolling' then
        action(c,'ROLLING BOMB')
        local point = B:Point(c,n+1)
        B:Warn(c,'ROLLING BOMB',c.actor:GetPos(),1,45,{shape='lane',finish=point,width=90})
        B:Later(c,1,'daryl_rolling',function(owner) self:Barrel(owner,point,'rolling') end)
    elseif move=='toss' then
        action(c,'BARREL TOSS')
        local point = B:Floor(c,p:GetPos()) or B:Point(c,n)
        B:Warn(c,'BARREL TOSS: WATCH THE FUSE',point,.85,100)
        B:Later(c,.85,'daryl_toss',function(owner) self:Barrel(owner,point,'toss') end)
    else
        action(c,'BARREL ROLL')
        B:Charge(c,c.actor,p:GetPos(),{label='BARREL ROLL',warning=1,speed=360,width=67,recovery=1.6,
            damage={kind='melee',damage=22,reference=22,push=220},
            onFinish=function(owner) owner.data.recoverUntil=owner.now+1.6; action(owner,'ROLL RECOVERY') end})
    end
end
function D:Phase(c,phase)
    c.data.internal, c.data.recoverUntil = nil,nil
    c.data.nextAttack, c.data.nextInternal = c.now+1.5, c.now+5
    if IsValid(c.actor) then c.actor:SetNW2Bool('LOD_BossScorched',phase==3) end
    action(c,self.phaseNames[phase])
end
function D:Pause(c)
    B:Clear(c,'daryl_barrel'); c.data.internal,c.data.recoverUntil=nil,nil
    c.data.nextAttack,c.data.nextInternal = c.now+1.5,c.now+5
end
function D:Defeat(c)
    c.data.deathStage='long_fuse';action(c,'ONE LAST MELODRAMATIC FUSE')
    B:Later(c,2.8,'cosmetic:daryl_boom',function(owner)
        owner.data.deathStage='harmless_boom';action(owner,'BOOM / SCORCH MARK');B:Announce(owner,'DARYL EXTINGUISHED');if B.Cue then B:Cue(owner,'rumble') end
    end)
    B:Later(c,4.1,'cosmetic:daryl_last_barrel',function(owner)
        owner.data.deathStage='final_barrel'
        local o=B:Object(owner,{kind='daryl_death_barrel',cosmetic=true,model='models/props_c17/oildrum001_explosive.mdl',
            pos=B:Center(owner)+Vector(-150,65,25),velocity=Vector(65,0,0),gravity=0,life=2.5,
            radius=15,mass=1,hp=0,scale=.65,solid=false,label='ONE LAST BARREL...'})
        if o then
            B:Later(owner,1,'cosmetic:daryl_last_light',function(current)
                if not o.retired then o.velocity=Vector();o.state='LIT';o.spec.label='LIT...' end
                current.data.deathStage='final_fuse'
            end)
            B:Later(owner,2,'cosmetic:daryl_fizzle',function(current)
                if not o.retired then o.state='FIZZLED';o.spec.label='...FIZZLE' end
                current.data.deathStage='fizzle';action(current,'...FIZZLE')
            end)
        end
    end)
end
function D:Snapshot(c)
    local stable,armed,critical=0,0,0
    for _,o in ipairs(liveBarrels(c)) do
        if o.state=='STABLE' then stable=stable+1 elseif o.state=='ARMED' then armed=armed+1 elseif o.state=='CRITICAL' then critical=critical+1 end
    end
    return (c.data.action or '')..' | STABLE '..stable..' / ARMED '..armed..' / CRITICAL '..critical
end
B:Register('daryl',D)
