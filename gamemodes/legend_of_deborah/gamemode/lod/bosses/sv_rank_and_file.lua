-- Dungeon 15. Existing zombie families, bounded queue, destructible PENDING work.
local B = LOD.BossEncounter
local D = {
    name = 'Rank and File', model = 'models/props_wasteland/controlroom_filecabinet002a.mdl',
    baseHP = 1700, speed = 95, size = 3.2, maxObjects = 28, maxAdds = 12,
    phaseNames = {'Filing Error', 'Personnel Department', 'BACKLOG'},
    arena = {theme = 'records_department',width = 7,depth = 6,upper = true},
    deathCaption = 'CASE CLOSED', deathDuration = 3.4, keyLocation = 'MISC drawer',
    presentation = {body = 'filing_cabinet',drawers = {'PERSONNEL','COMPLAINTS','DECEASED','PENDING','DENIED'}}
}
local zombies = {'afterburst','carrion','reaper','drubber','shy'}
local allowed = {}
for _, name in ipairs(zombies) do allowed[name] = true end
local drawerIndex = {PERSONNEL = 1,COMPLAINTS = 2,DECEASED = 3,PENDING = 4,DENIED = 5}
local function action(c,text,drawer)
    c.data.action = text
    c.actor:SetNW2String('LOD_BossAction',text)
    if drawer then c.actor:SetNW2Int('LOD_RankDrawer',drawerIndex[drawer] or 0) end
end
local function direction(v)
    if v:LengthSqr() < .01 then return Vector(1,0,0) end
    return v:GetNormalized()
end
local function liveZombies(c)
    local found = {}
    -- Encounter actor order is stable; never search the world or borrow unrelated enemies.
    for _, actor in ipairs(c.actors) do
        if IsValid(actor) and actor:Health() > 0 and c.owned[actor] == 'rank_zombie' then found[#found + 1] = actor end
    end
    return found
end
function D:Start(c)
    c.data.action,c.data.cycle,c.data.route = 'FILING ERROR',0,1
    c.data.nextAttack,c.data.nextSpawn = c.now + 1.4,c.now
    c.data.spawnQueue,c.data.folderSerial,c.data.spawnSerial = {},0,0
    c.data.addCap,c.data.queueCap = math.min(12,6 + c.party),14
    c.data.doors,c.data.shredders = {},{}
    c.data.safe = B:Point(c,#c.points)
    for i = 1,3 do
        local pos = B:Point(c,i * 3)
        local door = B:Object(c,{kind = 'rank_archive_door',model = 'models/props_c17/door01_left.mdl',
            pos = pos,scale = 1.2,permanent = true,solid = false,hp = 0,label = 'ARCHIVE DOOR ' .. i,radius = 22})
        if door then c.data.doors[#c.data.doors + 1] = door end
    end
    for i = 1,2 do
        local pos = B:Point(c,i * 4 + 1)
        local o = B:Object(c,{kind = 'rank_shredder',model = 'models/props_lab/reciever01b.mdl',
            pos = pos + Vector(0,0,20),hp = 0,permanent = true,solid = false,radius = 24,
            use = true,hold = .6,useLabel = 'SHRED NEARBY PENDING FOLDERS',label = 'SHREDDER: OPTIONAL E'})
        if o then o.shredReady = 0; c.data.shredders[#c.data.shredders + 1] = o end
    end
    for _, offset in ipairs({Vector(-170,-240,0),Vector(170,-240,0),Vector(-170,240,0),Vector(170,240,0)}) do
        local pos = B:Floor(c,B:Center(c) + offset)
        if pos then B:Object(c,{kind = 'rank_archive_row',model = D.model,pos = pos,permanent = true,
            hp = 0,solid = true,radius = 28,scale = 1.1,label = 'ARCHIVE ROW: CROSS-AISLE OPEN'}) end
    end
    B:Announce(c,'RANK AND FILE / PERSONNEL • COMPLAINTS • DECEASED • PENDING • DENIED')
end
function D:QueueBatch(c, count, reason, archetype, pos)
    local queued = 0
    for i = 1,count do
        if #c.data.spawnQueue >= c.data.queueCap then break end
        local family = archetype or zombies[B:Random(c,'rank_zombie_family',1,#zombies)]
        if allowed[family] then
            c.data.spawnSerial = c.data.spawnSerial + 1
            c.data.spawnQueue[#c.data.spawnQueue + 1] = {family = family,reason = reason,
                pos = pos or B:Point(c,c.data.spawnSerial * 2 + 1),serial = c.data.spawnSerial}
            queued = queued + 1
        end
    end
    B:Log(c,'rank_queue',{reason = reason,added = queued,queued = #c.data.spawnQueue,cap = c.data.queueCap})
    return queued
end
function D:ServiceQueue(c, now)
    if now < c.data.nextSpawn or #c.data.spawnQueue == 0 then return end
    c.data.nextSpawn = now + .65
    if B:CountActors(c,'rank_zombie') >= c.data.addCap then return end
    local item = c.data.spawnQueue[1]
    if item.folder and (item.folder.done or item.folder.retired) then
        table.remove(c.data.spawnQueue,1)
        B:Log(c,'rank_pending_queue_cancelled',{serial = item.folder.serial})
        return
    end
    local pos = B:SafePoint(c,item.pos)
    if not pos then item.pos = B:Point(c,item.serial + 1); return end
    if not item.warnedAt then
        item.warnedAt = now
        B:Warn(c,'PERSONNEL ARRIVING: ' .. string.upper(item.family),pos,1.15,40)
        return
    end
    if now < item.warnedAt + 1.15 then return end
    local actor = B:SpawnActor(c,item.family,'rank_zombie',pos,{manual = false,primary = false})
    -- A failed shared/global admission leaves the exact bounded queue intact for retry.
    if not IsValid(actor) then return end
    actor.LODRankOrdinaryFamily = item.family
    actor:SetNW2String('LOD_RankFileReason',item.reason)
    table.remove(c.data.spawnQueue,1)
    if item.folder then
        item.folder.done = true
        B:RemoveObject(c,item.folder,'pending_emerged')
    end
    B:Log(c,'rank_personnel_spawn',{family = item.family,serial = item.serial,remaining = #c.data.spawnQueue})
end
function D:Personnel(c, surge)
    action(c,surge and 'ALL HANDS ON DECK' or 'PERSONNEL: NEW HIRES','PERSONNEL')
    B:Stop(c,c.actor)
    local count = surge and math.min(8,4 + c.party) or math.min(3,1 + c.party)
    self:QueueBatch(c,count,surge and 'ALL HANDS ON DECK' or 'PERSONNEL')
    if surge then
        c.data.exposedUntil,c.data.stationaryUntil = c.now + 6,c.now + 6
        c.actor:SetNW2Bool('LOD_RankAllDrawers',true)
        c.actor:SetNW2Bool('LOD_RankExposed',true)
        B:Announce(c,'ALL HANDS ON DECK: DRAWERS OPEN / CABINET EXPOSED')
        B:Stagger(c,5,c.actor)
    end
end
function D:Pending(c, pos)
    if #B:Objects(c,'rank_pending') >= 4 then return nil end
    pos = B:SafePoint(c,pos)
    if not pos or pos:DistToSqr(c.data.safe) < 100^2 then return nil end
    c.data.folderSerial = c.data.folderSerial + 1
    local o = B:Object(c,{kind = 'rank_pending',model = 'models/props_lab/clipboard.mdl',pos = pos + Vector(0,0,9),
        hp = 18,life = 16,radius = 25,solid = false,scale = 1.5,
        label = 'PENDING: SHOOT FOLDER TO CANCEL / 4s',color = Color(240,180,65)})
    if not o then return nil end
    o.pending,o.emergeAt,o.serial = true,c.now + 4,c.data.folderSerial
    o.family = zombies[B:Random(c,'rank_pending_family',1,#zombies)]
    B:Warn(c,'PENDING ZOMBIE: DESTROY FOLDER',pos,4,45)
    action(c,'PENDING: CANCEL THE FOLDERS','PENDING')
    return o
end
function D:ServicePending(c, now)
    for _, o in ipairs(B:Objects(c,'rank_pending')) do
        if not o.done and not o.queued and now >= o.emergeAt then
            -- The same attackable marker remains until actual native admission, even at the ceiling.
            if self:QueueBatch(c,1,'PENDING',o.family,o.pos) == 1 then
                o.queued = true
                c.data.spawnQueue[#c.data.spawnQueue].folder = o
                o.spec.label = 'PENDING: WAITING / SHOOT TO CANCEL'
                if IsValid(o.ent) then o.ent:SetNW2String('LOD_BossObjectLabel',o.spec.label) end
            end
        end
    end
end
function D:Shred(c, o, player)
    if c.now < (o.shredReady or 0) or not B:Hero(c,player) then return end
    o.shredReady = c.now + 4
    local removed = 0
    for _, folder in ipairs(B:Objects(c,'rank_pending')) do
        if not folder.done and folder.pos:DistToSqr(o.pos) <= 300^2 then
            folder.done = true; removed = removed + 1
            B:RemoveObject(c,folder,'pending_shredded')
        end
    end
    B:Log(c,'rank_shred',{cancelled = removed})
end
function D:Misfiled(c)
    action(c,'MISFILED: WATCH THE ARCHIVE DOORS','DECEASED')
    local actors = liveZombies(c)
    for i = 1,math.min(3,#actors) do
        local door = c.data.doors[((i + c.data.cycle - 1) % math.max(1,#c.data.doors)) + 1]
        if door and not door.retired then
            B:Relocate(c,actors[i],door.pos,'MISFILED: SAME ZOMBIE / NEW ARCHIVE DOOR')
        end
    end
end
function D:DuplicateCopy(c)
    local actors = liveZombies(c)
    if #actors == 0 then self:Personnel(c,false); return end
    local source = actors[B:Random(c,'rank_duplicate_source',1,#actors)]
    local family = source.LODRankOrdinaryFamily
    if not allowed[family] then return end
    action(c,'DUPLICATE COPY: ' .. string.upper(family),'PERSONNEL')
    self:QueueBatch(c,math.min(3,1 + c.party),'DUPLICATE COPY',family)
end
function D:Denied(c, target)
    action(c,'DENIED: FRONTAL PUSH','DENIED')
    local start = c.actor:GetPos()
    local finish = B:Floor(c,start + direction(target:GetPos() - start) * 310)
    if not finish then return end
    B:Zone(c,{kind = 'rank_denied',label = 'DENIED',pos = start,finish = finish,width = 130,shape = 'lane',
        delay = 1.15,life = .35,interval = .4,damage = {kind = 'melee',damage = 5,reference = 13.5,push = 235},
        color = Color(245,65,65)})
end
function D:DrawerPunch(c, target)
    action(c,'COMPLAINTS: DRAWER PUNCH','COMPLAINTS')
    local start = c.actor:GetPos()
    local finish = B:Floor(c,start + direction(target:GetPos() - start) * 195)
    if not finish then return end
    B:Zone(c,{kind = 'rank_drawer',label = 'DRAWER PUNCH',pos = start,finish = finish,width = 95,shape = 'lane',
        delay = .95,life = .25,interval = .3,damage = {kind = 'melee',damage = 19,reference = 13.5,push = 185}})
    c.data.stationaryUntil = c.now + 1.65
end
function D:FileFan(c, target, paperCut)
    action(c,paperCut and 'PAPER CUT' or 'FILE FAN','COMPLAINTS')
    local start = c.actor:GetPos() + Vector(0,0,75)
    local aim = target:GetPos() + Vector(0,0,25)
    local dir = direction(aim - start)
    local count,tell = paperCut and 1 or 5,paperCut and .75 or 1.2
    B:Warn(c,paperCut and 'PAPER CUT' or 'FILE FAN',start,tell,35,{shape = 'lane',finish = aim,width = paperCut and 30 or 150})
    local binding = B:BindTarget(c,target)
    B:Later(c,tell,'rank_file_fan',function(owner)
        if not B:TargetLive(owner,binding) then return end
        for i = 1,count do
            local theta = (i - (count + 1) / 2) * .13
            local velocity = Vector(dir.x * math.cos(theta) - dir.y * math.sin(theta),
                dir.x * math.sin(theta) + dir.y * math.cos(theta),dir.z) * (paperCut and 510 or 430)
            B:Projectile(owner,{kind = 'rank_file',model = 'models/props_lab/clipboard.mdl',pos = start,
                velocity = velocity,gravity = 45,mass = 1,radius = 10,life = 2.4,hp = 3,bounces = 0,
                breakOnImpact = true,label = paperCut and 'PAPER CUT' or 'FILE FAN',
                damage = {kind = 'melee',damage = paperCut and 4 or 7,reference = 13.5,push = 35}})
        end
    end)
end
function D:CabinetCharge(c, target)
    action(c,'CABINET CHARGE: CLEAR THE AISLE','DENIED')
    B:Charge(c,c.actor,target:GetPos(),{label = 'CABINET CHARGE',warning = 1.4,speed = 385,width = 88,
        damage = {kind = 'melee',damage = 21,reference = 13.5,push = 215},recovery = 2,
        onFinish = function(owner,hit)
            owner.data.stationaryUntil = owner.now + 2
            action(owner,hit and 'DRAWER RECOIL' or 'MISFILED THE CHARGE: RECOVER','COMPLAINTS')
        end})
end
function D:RecordsAvalanche(c)
    action(c,'RECORDS AVALANCHE','DECEASED')
    for i = 1,4 do
        local pos = B:Point(c,c.data.route + i * 2)
        if pos:DistToSqr(c.data.safe) > 190^2 then
            B:Zone(c,{kind = 'rank_avalanche',label = 'FALLING RECORDS ' .. i,pos = pos,radius = 80,
                delay = 1.6 + i * .35,life = .3,interval = .4,
                damage = {kind = 'melee',damage = 14,reference = 13.5,push = 90},color = Color(240,215,155)})
            B:Later(c,1.25 + i * .35,'rank_avalanche_prop_' .. i,function(owner)
                B:Projectile(owner,{kind = 'rank_falling_file',model = 'models/props_lab/binderblue.mdl',
                    pos = pos + Vector(0,0,210),velocity = Vector(0,0,-210),gravity = 160,
                    life = 1.2,hp = 0,mass = 2,radius = 8,bounces = 0,breakOnImpact = true,label = 'FALLING FILES'})
            end)
        end
    end
end
function D:MassFiling(c, target)
    action(c,'MASS FILING: PERSONNEL → PENDING → DENIED','PERSONNEL')
    self:Personnel(c,false)
    local binding = B:BindTarget(c,target)
    B:Later(c,1.5,'rank_mass_pending',function(owner)
        D:Pending(owner,B:Point(owner,owner.data.route + 2))
        D:Pending(owner,B:Point(owner,owner.data.route + 5))
    end)
    B:Later(c,3.1,'rank_mass_denied',function(owner)
        if B:TargetLive(owner,binding) then D:Denied(owner,target) end
    end)
    c.data.nextAttack,c.data.stationaryUntil = c.now + 5.5,c.now + 3.6
end
function D:Think(c, now, dt, targets)
    self:ServicePending(c,now); self:ServiceQueue(c,now)
    if c.data.exposedUntil and now >= c.data.exposedUntil then
        c.data.exposedUntil = nil
        c.actor:SetNW2Bool('LOD_RankAllDrawers',c.phase == 3)
        c.actor:SetNW2Bool('LOD_RankExposed',false)
    end
    local target = targets[1]
    if not target then return end
    if now < (c.data.stationaryUntil or 0) then B:Stop(c,c.actor) end
    if now < c.data.nextAttack then
        if now >= (c.data.stationaryUntil or 0) then
            local reached = B:Move(c,c.actor,B:Point(c,c.data.route),95,{mode = 'skate',turnRate = .9})
            if reached then c.data.route = c.data.route + 1 end
        end
        return
    end
    c.data.cycle = c.data.cycle + 1
    c.data.nextAttack = now + 3.7
    local count = c.phase == 1 and 4 or c.phase == 2 and 9 or 12
    local n = ((c.data.cycle - 1) % count) + 1
    if n == 1 then self:DrawerPunch(c,target)
    elseif n == 2 then self:FileFan(c,target,false)
    elseif n == 3 then self:CabinetCharge(c,target)
    elseif n == 4 then self:FileFan(c,target,true)
    elseif n == 5 then self:Personnel(c,false)
    elseif n == 6 then self:Pending(c,B:Point(c,c.data.route + 2)); self:Pending(c,B:Point(c,c.data.route + 5))
    elseif n == 7 then self:Denied(c,target)
    elseif n == 8 then self:Misfiled(c)
    elseif n == 9 then self:DuplicateCopy(c)
    elseif n == 10 then self:RecordsAvalanche(c)
    elseif n == 11 then self:MassFiling(c,target)
    else self:Personnel(c,true); c.data.nextAttack = now + 7 end
end
function D:BeforeDamage(c, actor, info)
    if actor ~= c.actor or not info.ScaleDamage then return end
    if c.data.exposedUntil and c.now < c.data.exposedUntil then info:ScaleDamage(1.3); return end
    if c.phase ~= 3 or not info.GetDamagePosition then return end
    local hit = actor:WorldToLocal(info:GetDamagePosition())
    -- Extended drawer faces, not a parallel HP pool. Body damage remains ordinary.
    if hit.x >= 18 * D.size and math.abs(hit.y) <= 22 * D.size and hit.z >= 12 * D.size and hit.z <= 68 * D.size then
        info:ScaleDamage(1.25)
    end
end
function D:ObjectEvent(c, o, event, payload)
    if o.pending and (event == 'destroy' or event == 'expiry') then
        o.done = true; B:Log(c,'rank_pending_cancelled',{serial = o.serial,reason = event})
    elseif o.spec.kind == 'rank_shredder' and event == 'use' then self:Shred(c,o,payload) end
end
function D:ActorReplaced(c, actor)
    actor:SetNW2Bool('LOD_RankAllDrawers',c.phase == 3)
    actor:SetNW2String('LOD_BossAction',c.data.action or D.phaseNames[c.phase])
end
function D:Phase(c, phase)
    c.data.nextAttack = c.now + 1.4
    c.data.cycle = phase == 2 and 4 or phase == 3 and 9 or 0
    c.actor:SetNW2Bool('LOD_RankAllDrawers',phase == 3)
    action(c,D.phaseNames[phase]); B:Announce(c,D.phaseNames[phase])
end
function D:Pause(c)
    B:Clear(c,'rank_file'); B:Clear(c,'rank_falling_file')
    B:Clear(c,'rank_denied'); B:Clear(c,'rank_drawer'); B:Clear(c,'rank_avalanche')
    for _, item in ipairs(c.data.spawnQueue) do item.warnedAt = nil end
    -- Pending work and queue count persist; the shared pause stops service and damage.
end
function D:Retire(c)
    c.data.spawnQueue = {}
end
function D:KeyPosition(c)
    -- The authored MISC drawer drop gets a safe floor fallback, never an unreachable cabinet top.
    if c.data.miscDrop then return c.data.miscDrop end
    local pos = IsValid(c.actor) and c.actor:GetPos() or c.savedPos or B:Center(c)
    local forward = IsValid(c.actor) and c.actor:GetForward() or Vector(1,0,0)
    return B:SafePoint(c,pos + forward * 105) or B:Center(c)
end
function D:Defeat(c)
    c.data.miscDrop = self:KeyPosition(c)
    c.data.action = 'CASE CLOSED / MISC'
    if IsValid(c.actor) then
        c.actor:SetNW2Bool('LOD_RankAllDrawers',true)
        c.actor:SetNW2String('LOD_BossAction','CASE CLOSED / MISC')
    end
    B:Announce(c,'CASE CLOSED')
end
function D:Snapshot(c)
    return (c.data.action or 'FILING') .. ' | QUEUED ' .. #c.data.spawnQueue ..
        ' | PERSONNEL ' .. B:CountActors(c,'rank_zombie') .. '/' .. c.data.addCap
end
B:Register('rank_and_file',D)
