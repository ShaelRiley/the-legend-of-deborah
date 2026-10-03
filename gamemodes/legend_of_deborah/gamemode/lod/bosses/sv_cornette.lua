-- Dungeon 12. Skating android, physically launched drill hands and flank drones.
local B = LOD.BossEncounter
local D = {
    name = "Cornette, Who's Drills Hurt",model = 'models/Humans/Group03/female_07.mdl',
    baseHP = 1350,speed = 205,size = 1.15,maxObjects = 14,maxAdds = 3,
    phaseNames = {'Why Do They Hurt?','Drizel Ore','THE DRILLS HURT'},
    arena = {theme = 'drilling_floor',width = 6,depth = 6,upper = true},
    deathCaption = 'Oh.',deathDuration = 2.8,keyLocation = 'center',
    presentation = {body = 'female_android',hands = 'helical_drills',feet = 'roller_skates',crying = true}
}
local function action(c,text)
    c.data.action = text
    c.actor:SetNW2String('LOD_BossAction',text)
end
local function unit(v)
    if v:LengthSqr() < .01 then return Vector(1,0,0) end
    return v:GetNormalized()
end
local function handState(c,hand,missing)
    c.data.hands[hand] = missing
    c.actor:SetNW2Bool('LOD_CornetteMissing' .. hand,missing)
end
local function actualDrones(c)
    local out = {}
    for _, actor in ipairs(c.actors) do
        if IsValid(actor) and actor:Health() > 0 and c.owned[actor] == 'drizel_drone' then out[#out + 1] = actor end
    end
    return out
end
function D:Start(c)
    c.data.nextAttack,c.data.nextDrone,c.data.nextCry = c.now + 1.5,c.now + 2,c.now + 4
    c.data.cycle,c.data.route,c.data.strain,c.data.lastStrain = 0,1,0,c.now
    c.data.hands,c.data.handSerial,c.data.nextHand = {Left = false,Right = false},{Left = 0,Right = 0},'Left'
    c.data.droneState,c.data.columns,c.data.drillSerial = {},{},0
    c.data.droneCap = c.party > 1 and 3 or 2
    c.data.droneOrdinal = 0
    c.actor:SetColor(Color(170,192,200))
    c.actor:SetNW2Bool('LOD_CornetteAndroid',true)
    c.actor:SetNW2Int('LOD_CornetteStrain',0)
    for i = 1,3 do
        local p = B:Point(c,i * 3)
        if B:ValidateRoutes(c,{p},55) then
            local o = B:Object(c,{kind = 'cornette_column',model = 'models/props_c17/concrete_barrier001a.mdl',
                pos = p,permanent = true,hp = 0,solid = true,radius = 40,scale = 1.5,
                label = 'HEAVY DRILL COLUMN: BAIT THE RUSH'})
            if o then c.data.columns[#c.data.columns + 1] = o end
        end
    end
    action(c,'WHY DO THEY HURT?')
end
function D:AddStrain(c, amount)
    if c.phase ~= 3 then return end
    c.data.strain = math.min(100,c.data.strain + amount)
    c.data.lastStrain = c.now
    c.actor:SetNW2Int('LOD_CornetteStrain',math.floor(c.data.strain))
    if c.data.strain >= 100 and c.now >= (c.data.overstrainUntil or 0) then
        c.data.overstrainUntil = c.now + 4.8
        c.data.recoverUntil = math.max(c.data.recoverUntil or 0,c.now + 4.8)
        c.data.nextAttack = math.max(c.data.nextAttack,c.now + 5)
        B:Clear(c,'cornette_contact'); B:Stop(c,c.actor); B:Stagger(c,4.8,c.actor)
        action(c,'OW OW OW OW OW: OVERSTRAIN')
        B:Announce(c,'OW OW OW OW OW')
        c.actor:SetNW2Bool('LOD_CornetteOverheated',true)
        B:Log(c,'cornette_overstrain',{strain = c.data.strain,recovery = 4.8})
    end
end
function D:ReturnHand(c, hand, serial)
    if c.data.handSerial[hand] ~= serial then return end
    handState(c,hand,false)
    B:Log(c,'cornette_drill_return',{hand = hand,serial = serial})
end
function D:DrillShot(c, target, runaway)
    if not B:Hero(c,target) then return false end
    if runaway and c.data.runaway and not c.data.runaway.retired then return false end
    local hand = c.data.nextHand
    if c.data.hands[hand] then hand = hand == 'Left' and 'Right' or 'Left' end
    if c.data.hands[hand] then return false end
    c.data.nextHand = hand == 'Left' and 'Right' or 'Left'
    local serial = c.data.handSerial[hand] + 1
    c.data.handSerial[hand] = serial
    local binding,aim = B:BindTarget(c,target),target:GetPos() + Vector(0,0,36)
    local tell = runaway and 1.5 or 1.05
    action(c,(runaway and 'RUNAWAY ' or '') .. string.upper(hand) .. ' DRILL: SPINNING UP')
    c.actor:SetNW2String('LOD_CornetteSpinHand',hand)
    B:Warn(c,'DRILL SHOT: ' .. string.upper(hand),c.actor:GetPos(),tell,20,{shape = 'lane',finish = aim,width = 40})
    B:Later(c,tell,'cornette_drill_launch',function(owner)
        if not B:TargetLive(owner,binding) then return end
        handState(owner,hand,true)
        local actor = owner.actor
        local pos = actor:GetPos() + actor:GetRight() * (hand == 'Left' and -18 or 18) + Vector(0,0,49)
        local drill = B:Projectile(owner,{kind = 'cornette_drill',model = 'models/props_junk/garbage_metalcan001a.mdl',
            pos = pos,velocity = unit(aim - pos) * (runaway and 590 or 760),gravity = 0,mass = 12,radius = 12,
            life = runaway and 5.5 or 3.4,hp = 22,bounces = runaway and 3 or 1,breakOnImpact = false,
            label = runaway and 'RUNAWAY DRILL' or string.upper(hand) .. ' DRILL',scale = .6,
            damage = {kind = 'melee',damage = owner.phase == 3 and 22 or 16,reference = 13.5,push = 110},
            onHit = function(enc,o)
                if not runaway then
                    o.state,o.velocity,o.gravity,o.spec.gravity = 'RETURNING',Vector(0,0,0),0,0
                    o.expires = math.min(o.expires,enc.now + .6)
                end
            end,
            onImpact = function(enc,o,tr)
                if B:Hero(enc,tr.Entity) then return end
                o.wallImpacts = (o.wallImpacts or 0) + 1
                if o.wallImpacts <= (runaway and 3 or 1) then
                    if tr.HitNormal and IsValid(o.ent) then
                        local reflected = o.velocity - tr.HitNormal * (2 * o.velocity:Dot(tr.HitNormal))
                        o.ent:SetAngles(reflected:Angle())
                    end
                    return
                end
                o.state,o.velocity,o.gravity,o.spec.gravity = 'EMBEDDED',Vector(0,0,0),0,0
                o.expires = math.min(o.expires,enc.now + .95)
                o.spec.damage = nil
                B:Warn(enc,'DRILL EMBEDDED: RETURNING SOON',tr.HitPos or o.pos,.95,20)
                return true
            end,
            onExpire = function(enc) D:ReturnHand(enc,hand,serial) end,
            onDestroy = function(enc) D:ReturnHand(enc,hand,serial) end})
        if not drill then D:ReturnHand(owner,hand,serial); return end
        drill.hand,drill.handSerial = hand,serial
        drill.ent:SetAngles(drill.velocity:Angle())
        if runaway then owner.data.runaway = drill end
        -- Hard, exact-owner fallback also restores hands after a normal impact retirement.
        B:Later(owner,(runaway and 5.5 or 3.4) + .15,'cornette_return_' .. hand,
            function(enc) D:ReturnHand(enc,hand,serial) end)
        D:AddStrain(owner,runaway and 34 or 23)
        B:Log(owner,'cornette_drill_launch',{hand = hand,runaway = runaway or false,serial = serial})
    end)
    return true
end
function D:PainfulDrilling(c, target, cross)
    local start = c.actor:GetPos()
    local finish = B:Floor(c,start + unit(target:GetPos() - start) * 180)
    if not finish then return end
    action(c,cross and 'CROSS DRILL: FRONT / REAR' or 'PAINFUL DRILLING')
    B:Stop(c,c.actor)
    c.data.recoverUntil = c.now + 2.5
    B:Zone(c,{kind = 'cornette_contact',label = cross and 'CROSS DRILL: FRONT' or 'PAINFUL DRILLING',
        pos = start,finish = finish,shape = 'lane',width = 105,delay = .95,life = 1.5,interval = .65,
        damage = {kind = 'melee',damage = c.phase == 3 and 11 or 8,reference = 13.5,push = 45},
        color = Color(200,225,235)})
    B:Later(c,2.45,'cornette_contact_strain',function(owner) D:AddStrain(owner,30) end)
    if cross then
        for _, drone in ipairs(actualDrones(c)) do self:AcquireDrone(c,drone,target,false) end
    end
end
function D:TearfulRetreat(c, target)
    local best,bestDistance = B:Point(c,c.data.route + 2),-1
    for _, p in ipairs(c.points) do
        local dist = p:DistToSqr(target:GetPos())
        if dist > bestDistance then best,bestDistance = p,dist end
    end
    action(c,'TEARFUL RETREAT: BREATHER')
    c.data.retreatPoint,c.data.retreatUntil = best,c.now + 3
    c.data.nextAttack,c.data.recoverUntil = c.now + 3.6,c.now + 3
    c.actor:SetNW2Bool('LOD_CornetteCrying',true)
    B:Warn(c,'BACKWARD SKATE / RECOVERY',best,.65,45)
end
function D:DronePoint(c, target, index)
    local best,bestScore = nil,-math.huge
    local origin,facing = target:GetPos(),target:GetForward()
    for i,p in ipairs(c.points) do
        local displacement = p - origin
        local distance = displacement:Length()
        if distance >= 150 and distance <= 720 then
            local behind = -unit(displacement):Dot(facing)
            local elevation = math.abs(p.z - origin.z) >= 45 and 1.2 or 0
            local oppositeSide = ((i + index) % 2 == 0) and .2 or 0
            local score = behind * 2 + elevation + oppositeSide - math.abs(distance - 330) / 600
            if score > bestScore then best,bestScore = p,score end
        end
    end
    return best or B:Point(c,index * 3)
end
function D:ServiceDrones(c, now, targets)
    if c.phase < 2 then return end
    local drones = actualDrones(c)
    if now >= c.data.nextDrone and #drones < c.data.droneCap then
        c.data.nextDrone = now + 12
        local drone = B:SpawnActor(c,'razor','drizel_drone',B:Point(c,#drones * 3 + 2),
            {manual = true,primary = false,model = 'models/manhack.mdl',hpFraction = 1.3,scale = 1.2,name = 'Drizel Ore Drone'})
        if IsValid(drone) then
            drone:SetNW2String('LOD_BossSupportId','drizel_drone')
            c.data.droneOrdinal = c.data.droneOrdinal + 1
            c.data.droneState[drone] = {next = now + 2,index = c.data.droneOrdinal}
            drones[#drones + 1] = drone
        end
    end
    local target = targets[1]
    if not target then return end
    for i,drone in ipairs(drones) do
        local state = c.data.droneState[drone]
        if not state then
            c.data.droneOrdinal = c.data.droneOrdinal + 1
            state = {next = now + 1.8,index = c.data.droneOrdinal}; c.data.droneState[drone] = state
        end
        if now >= state.next then
            self:AcquireDrone(c,drone,target,c.data.pullDronesUntil and now < c.data.pullDronesUntil)
        elseif not state.chargingUntil or now >= state.chargingUntil then
            B:Move(c,drone,self:DronePoint(c,target,state.index),145,{mode = 'air',height = 70,turnRate = 1.8})
        end
    end
end
function D:AcquireDrone(c, drone, target, pull)
    if not IsValid(drone) or not B:Hero(c,target) then return end
    local state = c.data.droneState[drone]
    if not state or state.chargingUntil and c.now < state.chargingUntil then return end
    state.next,state.chargingUntil = c.now + 4.5,c.now + 1.15
    local binding,aim = B:BindTarget(c,target),target:GetPos() + Vector(0,0,28)
    local start = drone:GetPos()
    B:Stop(c,drone)
    drone:SetNW2String('LOD_BossAction',pull and 'DRILL THEM TOWARD ME: CHARGING' or 'DRIZEL ORE: CHARGING')
    B:Warn(c,pull and 'DRONE PUSH TOWARD CORNETTE' or 'DRIZEL ORE BLAST',start,1.15,18,
        {shape = 'lane',finish = aim,width = 36,color = Color(170,135,255)})
    local index = state.index
    B:Later(c,1.15,'cornette_drone_' .. index,function(owner)
        if not IsValid(drone) or c.owned[drone] ~= 'drizel_drone' or drone:Health() <= 0 or not B:TargetLive(owner,binding) then return end
        B:Projectile(owner,{kind = 'cornette_drone_blast',model = 'models/props_junk/garbage_metalcan001a.mdl',
            pos = start,velocity = unit(aim - start) * 490,gravity = 0,mass = 1,radius = 9,
            life = 1.7,hp = 0,bounces = 0,breakOnImpact = true,source = drone,label = 'DRIZEL ORE BLAST',scale = .35,
            damage = {kind = 'blast',damage = 8,reference = 17,push = pull and 100 or 35,
                direction = pull and unit(owner.actor:GetPos() - aim) or unit(aim - start)}})
        drone:SetNW2String('LOD_BossAction','DRIZEL ORE: REPOSITION')
    end)
end
function D:DrillSkateCharge(c, target)
    action(c,'DRILL-SKATE CHARGE: BOTH DRILLS FORWARD')
    -- Missing-arm attacks cannot falsely produce the two-drill column punish.
    local bothHands = not c.data.hands.Left and not c.data.hands.Right
    B:Charge(c,c.actor,target:GetPos(),{label = 'DRILL-SKATE CHARGE',warning = 1.75,speed = 650,width = 55,
        damage = {kind = 'melee',damage = 26,reference = 13.5,push = 245},recovery = 1.8,
        onFinish = function(owner,hit,position,tr)
            local stuck = false
            for _, column in ipairs(owner.data.columns) do
                if not column.retired and tr and tr.Entity == column.ent then stuck = bothHands; break end
            end
            if stuck then
                owner.data.recoverUntil,owner.data.nextAttack = owner.now + 5.5,owner.now + 5.8
                B:Stagger(owner,5.5,owner.actor)
                owner.actor:SetNW2Bool('LOD_CornetteColumnStuck',true)
                action(owner,'BOTH DRILLS STUCK: MAJOR PUNISH WINDOW')
                B:Log(owner,'cornette_column_stuck',{bothHands = true,recovery = 5.5})
            else owner.data.recoverUntil = owner.now + 1.8; action(owner,'SKATE WOBBLE: RECOVER') end
            D:AddStrain(owner,35)
        end})
end
function D:Think(c, now, dt, targets)
    self:ServiceDrones(c,now,targets) -- Drones suppress while the android is overstrained.
    if c.data.overstrainUntil and now >= c.data.overstrainUntil then
        c.data.overstrainUntil,c.data.strain = nil,20
        c.actor:SetNW2Bool('LOD_CornetteOverheated',false)
        c.actor:SetNW2Int('LOD_CornetteStrain',20)
    elseif c.phase == 3 and now > c.data.lastStrain + 4 and not c.data.overstrainUntil then
        local old = math.floor(c.data.strain)
        c.data.strain = math.max(0,c.data.strain - dt * 3)
        if math.floor(c.data.strain) ~= old then c.actor:SetNW2Int('LOD_CornetteStrain',math.floor(c.data.strain)) end
    end
    if now >= c.data.nextCry then
        c.data.nextCry = now + 12
        c.actor:EmitSound('vo/npc/female01/pain07.wav',67,105,.35)
        c.actor:SetNW2Bool('LOD_CornetteCrying',true)
    end
    local target = targets[1]
    if not target then return end
    if c.data.retreatUntil and now < c.data.retreatUntil then
        B:Move(c,c.actor,c.data.retreatPoint,190,{mode = 'skate',turnRate = 1.1}); return
    end
    if now < (c.data.recoverUntil or 0) then B:Stop(c,c.actor); return end
    c.actor:SetNW2Bool('LOD_CornetteColumnStuck',false)
    if now < c.data.nextAttack then
        local reached,blocked = B:Move(c,c.actor,B:Point(c,c.data.route),c.phase == 3 and 235 or 205,{mode = 'skate',turnRate = .95})
        if reached or blocked then c.data.route = c.data.route + 1 end
        return
    end
    c.data.cycle,c.data.nextAttack = c.data.cycle + 1,now + 3.4
    local n = ((c.data.cycle - 1) % (c.phase == 1 and 4 or c.phase == 2 and 6 or 9)) + 1
    if n == 1 or n == 3 then self:DrillShot(c,target,false)
    elseif n == 2 then self:PainfulDrilling(c,target,false)
    elseif n == 4 then self:TearfulRetreat(c,target)
    elseif n == 5 then self:PainfulDrilling(c,target,true)
    elseif n == 6 then
        action(c,'DRILL THEM TOWARD ME')
        c.data.pullDronesUntil = now + 5
        for _, drone in ipairs(actualDrones(c)) do self:AcquireDrone(c,drone,target,true) end
        if B:Random(c,'cornette_rare_bark',1,5) == 1 then B:Announce(c,"SHE'S BEHIND YOU!") end
    elseif n == 7 then self:DrillShot(c,target,true)
    elseif n == 8 then self:DrillSkateCharge(c,target)
    else self:PainfulDrilling(c,target,true) end
end
function D:ActorReplaced(c, actor)
    actor:SetColor(Color(170,192,200))
    actor:SetNW2Bool('LOD_CornetteAndroid',true)
    actor:SetNW2Int('LOD_CornetteStrain',math.floor(c.data.strain))
    actor:SetNW2Int('LOD_CornetteDamageStage',c.phase)
    for _, hand in ipairs({'Left','Right'}) do
        c.data.handSerial[hand] = c.data.handSerial[hand] + 1
        handState(c,hand,false)
    end
end
function D:Phase(c, phase)
    c.data.cycle = phase == 2 and 4 or phase == 3 and 6 or 0
    c.data.nextAttack,c.data.nextDrone = c.now + 1.4,c.now + .5
    c.actor:SetNW2Int('LOD_CornetteDamageStage',phase)
    action(c,D.phaseNames[phase]); B:Announce(c,D.phaseNames[phase])
end
function D:BeforeDamage(c, actor, info)
    if actor == c.actor and c.now < (c.data.recoverUntil or 0) and info.ScaleDamage then info:ScaleDamage(1.25) end
end
function D:ActorKilled(c, actor, role)
    if role ~= 'drizel_drone' then return false end
    c.data.droneState[actor] = nil
    c.data.nextDrone = math.max(c.data.nextDrone,c.now + 12)
    return true
end
function D:Pause(c)
    for _, kind in ipairs({'cornette_drill','cornette_contact','cornette_drone_blast'}) do B:Clear(c,kind) end
    for _, hand in ipairs({'Left','Right'}) do
        c.data.handSerial[hand] = c.data.handSerial[hand] + 1
        handState(c,hand,false)
    end
    for _, state in pairs(c.data.droneState) do state.chargingUntil = nil; state.next = c.now + 1.5 end
    c.data.retreatUntil = nil
end
function D:Retire(c)
    c.data.droneState = {}
end
function D:Defeat(c)
    if IsValid(c.actor) then
        c.actor:SetNW2Bool('LOD_CornetteCrying',false)
        c.actor:SetNW2Bool('LOD_CornetteDeathSpin',true)
        action(c,'Oh.')
    else c.data.action = 'Oh.' end
    B:Announce(c,'Oh.')
    if B.Cue then B:Later(c,1.6,'cosmetic:cornette_drill_clang',function(owner) B:Cue(owner,'clang') end) end
end
function D:Snapshot(c)
    return (c.data.action or 'SKATING') .. ' | OVERSTRAIN ' .. math.floor(c.data.strain) .. '/100 | DRONES ' .. #actualDrones(c)
end
B:Register('cornette',D)
