-- Dungeon 8. Heavy main body retains all boss HP; furniture and chaise are hazards.
local B = LOD.BossEncounter
local D = {
    name = 'Sofa King Dangerous', model = 'models/props_c17/FurnitureCouch002a.mdl',
    baseHP = 1360, speed = 85, size = 2.8, maxObjects = 20, maxAdds = 0,
    phaseNames = {'Please Sit Down', 'Sectional Violence', 'SOFA KING DANGEROUS'},
    arena = {theme = 'living_room', width = 6, depth = 5, clearLanes = true},
    deathCaption = 'SOFA KING DEFEATED', deathDuration = 4, keyLocation = 'between_cushions',
    presentation = {body = 'couch', tornPhase = 3, brokenLegPhase = 3},
    deathSequence = {'short final charge', 'broken leg snaps', 'roll onto back', 'cushion drops', 'spring boing', 'key between cushions'}
}
local furniture = {
    chair = {model='models/props_c17/FurnitureChair001a.mdl',speed=360,lift=20,mass=18,radius=24,life=4,damage=14,push=130},
    lamp = {model='models/props_c17/FurnitureLamp001a.mdl',speed=0,lift=-45,mass=14,radius=22,life=3,damage=20,push=100},
    table = {model='models/props_c17/FurnitureTable001a.mdl',speed=300,lift=10,mass=48,radius=46,life=4.5,damage=22,push=230},
    ottoman = {model='models/props_c17/FurnitureCouch001a.mdl',speed=260,lift=30,mass=28,radius=35,life=4.2,damage=17,push=170},
    cushion = {model='models/props_c17/FurnitureCouch001a.mdl',speed=330,lift=210,mass=5,radius=17,life=3.5,damage=10,push=95,scale=.34}
}
local function action(c, text)
    c.data.action=text
    if IsValid(c.actor) then c.actor:SetNW2String('LOD_BossAction',text) end
end
local function direction(from,to)
    local v=to-from;v.z=0
    return v:LengthSqr()>1 and v:GetNormalized() or Vector(1,0,0)
end
local function safeHazard(c,pos,radius)
    pos=B:Floor(c,pos)
    if not pos or pos:DistToSqr(c.data.safe)<(radius+100)^2 then return nil end
    return B:ValidateRoutes(c,{pos},radius+30) and pos or nil
end
function D:Start(c)
    c.data.safe=B:Point(c,#c.points)
    c.data.cycle,c.data.nextAttack,c.data.nextSwipe=0,c.now+1.5,0
    c.data.islands={}
    -- Finite, explicitly designated charge-smash furniture. No generic scenery exploit.
    for n=1,3 do
        local pos=safeHazard(c,B:Point(c,n*3),65)
        if pos then
            local all={pos};for _,o in ipairs(c.data.islands) do all[#all+1]=o.pos end
            if B:ValidateRoutes(c,all,65) then
                local o=B:Object(c,{kind='sofa_island',role='designated_smash',model='models/props_c17/FurnitureTable001a.mdl',
                    pos=pos,hp=75,radius=42,mass=80,solid=true,permanent=true,label='FRAGILE FURNITURE: BAIT A MISSED CHARGE'})
                if o then c.data.islands[#c.data.islands+1]=o end
            end
        end
    end
    action(c,'PLEASE SIT DOWN')
end
function D:SmashIsland(c,pos,trace,hitHero)
    if hitHero then return false end
    for _,o in ipairs(c.data.islands) do
        if not o.retired and (pos:DistToSqr(o.pos)<145^2 or (trace and trace.Entity==o.ent)) then
            B:RemoveObject(c,o,'charge_smash')
            B:Stagger(c,2.7,c.actor);c.data.recoverUntil=c.now+2.7
            B:Log(c,'sofa_designated_smash',{object=o.id})
            action(c,'FURNITURE SMASH: PUNISH')
            return true
        end
    end
    return false
end
function D:FinishCharge(c,hit,pos,trace)
    c.data.charging=nil
    if self:SmashIsland(c,pos,trace,hit) then return end
    c.data.recoverUntil=c.now+(hit and 1.25 or 2)
    B:Stagger(c,hit and 1.25 or 2,c.actor)
    action(c,'SKID RECOVERY')
end
function D:SofaCharge(c,destination)
    destination=B:Floor(c,destination)
    if not destination then return end
    c.data.charging=true;c.data.chargeDeadline=c.now+8
    local origin=c.actor:GetPos()
    local drift=c.phase==3
    local v=direction(origin,destination)
    local side=Vector(-v.y,v.x,0)
    local middle=drift and B:Floor(c,origin+(destination-origin)*.58+side*75) or nil
    action(c,drift and 'BROKEN-LEG DRIFT' or 'SOFA CHARGE')
    B:Warn(c,'CREAK / COMPRESSION',origin,1.1,95,{shape='lane',finish=middle or destination,width=190})
    if middle then B:Warn(c,'BROKEN-LEG DRIFT: FIXED SECOND SEGMENT',middle,1.1,95,{shape='lane',finish=destination,width=190}) end
    B:Charge(c,c.actor,middle or destination,{label='SOFA CHARGE',warning=1.1,speed=drift and 525 or 440,width=95,
        recovery=middle and .2 or 2,damage={kind='melee',damage=26,reference=25,push=280},
        onFinish=function(owner,hit,pos,trace)
            if self:SmashIsland(owner,pos,trace,hit) then owner.data.charging=nil;return end
            if middle and not (trace and trace.Hit) then
                B:Charge(owner,owner.actor,destination,{label='BROKEN-LEG DRIFT',warning=.35,speed=470,width=95,recovery=2,
                    damage={kind='melee',damage=22,reference=25,push=235},
                    onFinish=function(final,lastHit,lastPos,lastTrace) self:FinishCharge(final,hit or lastHit,lastPos,lastTrace) end})
            else self:FinishCharge(owner,hit,pos,trace) end
        end})
end
function D:Furniture(c,kind,destination,origin)
    local cfg=furniture[kind]
    if not cfg or #B:Objects(c,'sofa_furniture')>=10 then return nil end
    destination=safeHazard(c,destination,kind=='table' and 100 or 65)
    if not destination then return nil end
    origin=kind=='lamp' and destination+Vector(0,0,310) or origin or c.actor:GetPos()+Vector(0,0,60)
    local velocity=direction(origin,destination)*cfg.speed+Vector(0,0,cfg.lift)
    local o=B:Projectile(c,{kind='sofa_furniture',role=kind,model=cfg.model,pos=origin,velocity=velocity,
        gravity=(kind=='chair' or kind=='table' or kind=='ottoman') and 70 or 440,
        radius=cfg.radius,mass=cfg.mass,scale=cfg.scale or 1,hp=kind=='table' and 45 or 20,life=cfg.life,
        bounces=kind=='cushion' and 1 or 0,breakOnImpact=true,pushable=true,
        label=string.upper(kind)..(kind=='lamp' and ' FALL' or ' SLIDE'),
        damage={kind='melee',damage=cfg.damage,reference=25,push=cfg.push}})
    if o then o.state=kind=='lamp' and 'FALLING' or 'SKIDDING' end
    return o
end
function D:ThrowFurniture(c,kind,destination)
    action(c,string.upper(kind)..(kind=='lamp' and ' FALL' or ' TOSS'))
    local origin=c.actor:GetPos()+Vector(0,0,65)
    B:Warn(c,string.upper(kind)..': VISIBLE SOURCE',kind=='lamp' and destination or origin,1,70,
        {shape=kind=='lamp' and 'circle' or 'lane',finish=destination,width=110})
    B:Later(c,1,'sofa_throw',function(owner) self:Furniture(owner,kind,destination,origin) end)
end
function D:SectionalSplit(c,destination)
    if c.data.section and not c.data.section.retired then return end
    destination=safeHazard(c,destination,110)
    if not destination then return end
    local origin=c.actor:GetPos()+Vector(0,0,25)
    action(c,'SECTIONAL SPLIT')
    B:Warn(c,'DETACHED CHAISE LANE',origin,1.1,65,{shape='lane',finish=destination,width=130})
    B:Later(c,1.1,'sofa_split',function(owner)
        local o=B:Projectile(owner,{kind='sofa_section',role='detached_chaise',model='models/props_c17/FurnitureCouch001a.mdl',
            pos=origin,velocity=direction(origin,destination)*240,gravity=0,radius=52,mass=65,scale=1.8,
            hp=60,life=5.5,bounces=0,breakOnImpact=false,pushable=false,label='DETACHED CHAISE: HAZARD, NOT BOSS',
            damage={kind='melee',damage=20,reference=25,push=230},
            onImpact=function(owner,object,tr) object.velocity=Vector(0,0,0);object.state='WAITING TO RECONNECT';return not B:Hero(owner,tr.Entity) end,
            onExpire=function(current,object) self:Reconnect(current,object) end})
        if o then
            owner.data.section=o;o.state='DETACHED'
            owner.actor:SetNW2Bool('LOD_BossSectionDetached',true)
            B:Later(owner,5.2,'sofa_reconnect',function(current) self:Reconnect(current,o) end)
        end
    end)
end
function D:Reconnect(c,o)
    if o.rejoined then return end
    o.rejoined=true
    B:RemoveObject(c,o,'reconnected')
    if c.data.section==o then c.data.section=nil end
    if IsValid(c.actor) then c.actor:SetNW2Bool('LOD_BossSectionDetached',false) end
    B:Log(c,'sofa_section_reconnected',{object=o.id})
end
function D:ObjectEvent(c,o,event)
    if o.spec and o.spec.kind=='sofa_section' and event=='destroy' then self:Reconnect(c,o) end
end
function D:Swipe(c)
    c.data.nextSwipe=c.now+4
    local origin=c.actor:GetPos()
    B:Warn(c,'ARMREST SWIPE',origin,.6,150)
    B:Later(c,.6,'sofa_swipe',function(owner)
        B:Area(owner,origin,150,{kind='melee',damage=12,reference=25,push=230,origin=origin})
    end)
end
function D:Recline(c,destination,full)
    destination=B:Floor(c,destination)
    if not destination then return end
    local origin=c.actor:GetPos()
    local length=full and 320 or 220
    local finish=B:Floor(c,origin+direction(origin,destination)*length)
    if not finish then return end
    local width=full and 210 or 155
    -- Only admit a slam rectangle when at least one connected baseline route survives.
    if not B:ValidateRoutes(c,{origin,finish},width*.55) then return end
    action(c,full and 'FULL RECLINE: VERTICAL' or 'RECLINER SLAM')
    c.data.reclining=true
    B:Stop(c,c.actor)
    c.actor:SetNW2Bool('LOD_BossVertical',true)
    B:Warn(c,full and 'FULL RECLINE' or 'RECLINER SLAM',origin,full and 1.6 or 1.05,width,
        {shape='rect',finish=finish,width=width})
    B:Later(c,full and 1.6 or 1.05,'sofa_recline',function(owner)
        local hit=false
        local zone=B:Zone(owner,{kind='sofa_slam',label=full and 'FULL RECLINE' or 'RECLINER SLAM',pos=origin,finish=finish,
            shape='rect',width=width,radius=width*.5,life=.18,interval=.2,
            damage={kind='melee',damage=full and 33 or 24,reference=25,push=275},
            onTick=function(_,_,targets) if #targets>0 then hit=true end end,
            onExpire=function(current)
                current.data.reclining=nil
                current.actor:SetNW2Bool('LOD_BossVertical',false)
                local inverted=full and not hit
                local duration=inverted and 4.1 or 1.7
                current.data.invertedUntil=inverted and current.now+duration or nil
                current.data.recoverUntil=current.now+duration
                current.actor:SetNW2Bool('LOD_BossInverted',inverted)
                B:Stagger(current,duration,current.actor)
                action(current,inverted and 'INVERTED: EXPOSED UNDERSIDE' or 'SLAM RECOVERY')
                if inverted then
                    B:Later(current,duration-.65,'sofa_recovery_warning',function(final)
                        B:Warn(final,'VIOLENT RECOVERY SHOVE',final.actor:GetPos(),.65,180)
                    end)
                    B:Later(current,duration,'sofa_recovery_shove',function(final)
                        final.data.invertedUntil=nil;final.actor:SetNW2Bool('LOD_BossInverted',false)
                        local at=final.actor:GetPos()
                        B:Area(final,at,180,{kind='melee',damage=8,reference=25,push=300,origin=at})
                        action(final,'VIOLENT RECOVERY SHOVE')
                    end)
                end
            end})
        if not zone then
            owner.data.reclining=nil;owner.data.recoverUntil=owner.now+1.2
            owner.actor:SetNW2Bool('LOD_BossVertical',false)
            action(owner,'SAFE SLAM RECOVERY')
        end
    end)
end
function D:BeforeDamage(c,actor,info)
    if actor==c.actor and (c.data.invertedUntil or 0)>c.now then
        if info:IsDamageType(DMG_CLUB) or info:IsDamageType(DMG_SLASH) then info:ScaleDamage(1.4) end
    end
end
function D:CushionMine(c,pos)
    pos=safeHazard(c,pos,105)
    if not pos or #B:Objects(c,'sofa_cushion_mine')>=4 then return end
    local o=B:Object(c,{kind='sofa_cushion_mine',model=furniture.cushion.model,pos=pos+Vector(0,0,12),
        scale=.4,radius=18,hp=15,life=4.5,solid=false,label='CUSHION MINE: SOFT BURST'})
    if not o then return end
    o.state='SOFT BURST IN 2 SECONDS'
    B:Warn(c,'CUSHION MINE',pos,2,100)
    B:Later(c,2,'sofa_mine_'..o.id,function(owner)
        if o.retired then return end
        B:Area(owner,o.pos,100,{kind='melee',damage=9,reference=25,push=250,origin=o.pos})
        B:RemoveObject(owner,o,'soft_burst')
    end)
end
function D:Storm(c,destination)
    action(c,'FURNITURE STORM')
    B:Announce(c,'FURNITURE STORM! KEEP A CLEAR ROUTE')
    local kinds={'chair','lamp','table','ottoman'}
    for n,kind in ipairs(kinds) do
        local pos=B:Point(c,c.data.cycle+n)
        B:Warn(c,'FURNITURE STORM: '..string.upper(kind),pos,1+n*.55,85)
        B:Later(c,1+n*.55,'sofa_storm_'..n,function(owner) self:Furniture(owner,kind,pos) end)
    end
    B:Later(c,3.5,'sofa_storm_recline',function(owner) self:Recline(owner,destination,true) end)
    c.data.nextAttack=c.now+9
end
function D:Think(c,now,dt,targets)
    if c.data.charging and (c.data.chargeDeadline or now+1)<now then
        B:Stop(c,c.actor);c.data.charging=nil;c.data.recoverUntil=now+1.2
        action(c,'SAFE CHARGE RECOVERY')
    end
    if not targets[1] or c.data.charging or c.data.reclining or (c.data.recoverUntil or 0)>now then return end
    local p=targets[1]
    if now>=c.data.nextSwipe and p:GetPos():DistToSqr(c.actor:GetPos())<135^2 then self:Swipe(c) end
    if now<c.data.nextAttack then
        B:Move(c,c.actor,p:GetPos(),85,{mode='ground',turnRate=55,stopDistance=175})
        return
    end
    c.data.cycle=c.data.cycle+1;local n=c.data.cycle
    c.data.nextAttack=now+3.9
    local target=targets[((n-1)%#targets)+1]:GetPos()
    local grammar=c.phase==1 and {'charge','slam','cushion','charge','slam'}
        or c.phase==2 and {'charge','chair','split','barrage','lamp','slam','table','charge','ottoman'}
        or {'charge','mine','full','chair','split','barrage','storm','lamp','table','ottoman'}
    local move=grammar[(n-1)%#grammar+1]
    if move=='storm' then self:Storm(c,target)
    elseif move=='full' then self:Recline(c,target,true)
    elseif move=='mine' then self:CushionMine(c,target)
    elseif move=='split' then self:SectionalSplit(c,target)
    elseif move=='charge' then self:SofaCharge(c,target)
    elseif move=='slam' then self:Recline(c,target,false)
    elseif move=='barrage' then
        self:ThrowFurniture(c,'cushion',target)
        for k=1,2 do
            local point=target+Vector(0,(k==1 and -1 or 1)*110,0)
            B:Warn(c,'CUSHION BARRAGE',point,1+k*.25,65)
            B:Later(c,1+k*.25,'sofa_cushion_'..k,function(owner) self:Furniture(owner,'cushion',point) end)
        end
    else self:ThrowFurniture(c,move,target) end
end
function D:Phase(c,phase)
    c.data.charging,c.data.reclining,c.data.invertedUntil,c.data.recoverUntil=nil,nil,nil,nil
    c.data.nextAttack=c.now+1.4
    if c.data.section then self:Reconnect(c,c.data.section) end
    c.actor:SetNW2Bool('LOD_BossInverted',false);c.actor:SetNW2Bool('LOD_BossVertical',false)
    c.actor:SetNW2Bool('LOD_BossTorn',phase==3)
    action(c,self.phaseNames[phase])
end
function D:Pause(c)
    c.data.charging,c.data.reclining,c.data.invertedUntil,c.data.recoverUntil=nil,nil,nil,nil
    if c.data.section then self:Reconnect(c,c.data.section) end
    B:Clear(c,'sofa_furniture');B:Clear(c,'sofa_cushion_mine');B:Clear(c,'sofa_slam')
    c.actor:SetNW2Bool('LOD_BossInverted',false);c.actor:SetNW2Bool('LOD_BossVertical',false)
    c.data.nextAttack=c.now+1.5
end
function D:Retire(c)
    if IsValid(c.actor) then
        c.actor:SetNW2Bool('LOD_BossInverted',false);c.actor:SetNW2Bool('LOD_BossVertical',false)
        c.actor:SetNW2Bool('LOD_BossSectionDetached',false)
    end
end
function D:Defeat(c)
    c.data.keyDrop=B:SafePoint(c,IsValid(c.actor) and c.actor:GetPos() or c.deathPosition or B:Center(c)) or B:Center(c)
    c.data.deathStage='final_charge';action(c,'ONE LAST SHORT CHARGE')
    B:Later(c,.65,'cosmetic:sofa_leg',function(owner)
        owner.data.deathStage='leg_snaps';action(owner,'BROKEN LEG SNAPS')
    end)
    B:Later(c,1.2,'cosmetic:sofa_back',function(owner)
        owner.data.deathStage='on_back';action(owner,'ROLLED ONTO BACK')
    end)
    B:Later(c,1.6,'cosmetic:sofa_cushion',function(owner)
        owner.data.deathStage='cushion_drop'
        local pos=owner.deathPosition or B:Center(owner)
        B:Object(owner,{kind='sofa_death_cushion',cosmetic=true,model=furniture.cushion.model,pos=pos+Vector(0,0,80),
            velocity=Vector(35,25,-30),gravity=250,radius=10,mass=1,hp=0,scale=.4,life=2,solid=false,label='LAST CUSHION'})
    end)
    B:Later(c,2.5,'cosmetic:sofa_boing',function(owner)
        owner.data.deathStage='boing';action(owner,'BOING');B:Announce(owner,'SOFA KING DEFEATED');if B.Cue then B:Cue(owner,'boing') end
    end)
end
function D:KeyPosition(c)
    -- Explicit authored exception: key falls between cushions; clamp to a reachable floor point.
    return B:SafePoint(c,c.data.keyDrop or (IsValid(c.actor) and c.actor:GetPos()) or c.deathPosition or B:Center(c)) or B:Center(c)
end
function D:Snapshot(c)
    return (c.data.action or '')..(c.data.section and ' | DETACHED SECTION: NO BOSS HP' or '')
end
B:Register('sofa',D)
