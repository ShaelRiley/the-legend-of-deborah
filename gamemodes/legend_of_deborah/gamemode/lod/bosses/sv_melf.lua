-- Frozen, executable Mirror Kits. No player inventories, menus or resurrection.
local B=LOD.BossEncounter
local D={name="Melf the Yourself",model="models/player/group01/male_07.mdl",
    baseHP=780,speed=170,size=1,manualPhase=true,maxObjects=24,maxAdds=4,
    phaseNames={"YOU, BUT WORSE","BARE BONES","GIANT YOURSELF"},
    arena={theme="Hall of Yourself",width=6,depth=6,upper=true},
    deathCaption="YOU DEFEATED YOURSELF",keyLocation="center"}
local supportedForms={cone=true,blast=true,beam=true,bomb=true,missile=true,bolt=true,
    super_ball=true,watermelon=true,wall=true}
-- Each allowed signature has a live shared execution/mitigation path below.
local signatures={STR_CROWBAR_D6=true,STR_CROWBAR_D12=true,
    DEX_RATE_OF_FIRE_1=true,INT_MANA_BARRIER_1=true,INT_MANA_BARRIER_2=true,INT_MANA_BARRIER_3=true,
    WIS_TRUE_FAITH=true,WIS_MIND_OVER_MATTER=true,CHA_AGGRESSIVE_PERSONALITY=true,
    CHA_SELF_ACTUALIZATION=true}
local function copy(v) return Vector(v.x,v.y,v.z) end
local function live(e) return IsValid(e) and not e.LODDead and e:Health()>0 end
local function at(c) return c.now or CurTime() end
local function contains(t,id) for _,v in ipairs(t or {}) do if v==id then return true end end;return false end
local function incarnation(c,m) return {owner=c,actor=m.actor,serial=m.incarnation} end
local function valid(c,m,life)
    return B:Live(c) and m.encounter==c and not m.dead and live(m.actor) and c.data.byActor[m.actor]==m
        and (not life or life.owner==c and life.actor==m.actor and life.serial==m.incarnation)
end
local function styleName(kit,phase) return (phase==1 and "EVIL " or phase==2 and "SKELETON OF " or "GIANT ")..kit.name end
function D:CaptureKit(c,h,index)
    local source=h.progressionState or {};local p=h.player
    local class=source.classId
    if class~="fighter" and class~="rogue" and class~="wizard" then class="fighter" end
    local identity=source.characterIdentityPackage or {}
    local kit={identity=h.identity,name=identity.fullDisplayName or h.name or (IsValid(p) and p:Nick()) or "HERO",
        model=h.model or (IsValid(p) and p:GetModel()) or self.model,
        color=table.Copy(h.color or (IsValid(p) and p:GetColor()) or Color(255,255,255)),
        class=class,forms={},contents={},signatures={},index=index}
    local ps=LOD.CharacterProgressionSystem:NewProgressionState("melf:"..tostring(c.serial)..":"..index,"soldier","ai")
    ps.classId=class;ps.level=source.level or 1
    -- Snapshot the resulting scores, then let canonical derivation rebuild only
    -- class cores and the two admitted signatures. No copied derived utility.
    ps.baseAbilities=table.Copy(source.effectiveAbilities or source.baseAbilities or {})
    for _,ability in ipairs({"str","dex","con","int","wis","cha"}) do
        ps.baseAbilities[ability]=math.Clamp(tonumber(ps.baseAbilities[ability]) or 10,3,24)
    end
    ps.primaryAbility=nil;ps.secondaryAbilities={};ps.startingHP=180;ps.hitDieRollsByLevel={}
    ps.usesMagic=class=="wizard";ps.magic=100
    ps.currentElement=source.currentElement
    ps.elementalWeaknesses=table.Copy(source.elementalWeaknesses or {})
    ps.equipmentShieldEquipped=class=="fighter" and source.equipmentShieldEquipped==true
    ps.equipmentBlockChanceContribution=math.Clamp(tonumber(source.equipmentBlockChanceContribution) or 0,0,.20)
    ps.characterIdentityPackage={fullDisplayName=kit.name}
    local catalog=LOD.RPG.IdentityCatalog and LOD.RPG.IdentityCatalog.OrdinaryFeats or {}
    for _,id in ipairs(source.featIds or {}) do
        if #kit.signatures<2 and signatures[id] and catalog[id] then kit.signatures[#kit.signatures+1]=id end
    end
    ps.featIds=table.Copy(kit.signatures)
    for _,id in ipairs(source.magicFormIds or {}) do if supportedForms[id] and LOD.RPG.MagicForms[id] then kit.forms[#kit.forms+1]=id end end
    for _,id in ipairs(source.contentIds or {}) do if LOD.RPG.MagicContents[id] then kit.contents[#kit.contents+1]=id end end
    ps.magicFormIds=table.Copy(kit.forms);ps.contentIds=table.Copy(kit.contents)
    ps.selectedMagicFormId=contains(kit.forms,source.selectedMagicFormId) and source.selectedMagicFormId or kit.forms[1]
    ps.selectedMagicContentId=contains(kit.contents,source.selectedMagicContentId) and source.selectedMagicContentId or kit.contents[1]
    LOD.CharacterProgressionSystem:_RecomputeProgressionState(ps)
    kit.profile=ps
    local weapon=h.weaponClass or source.representativeWeaponClass
    if not weapon and IsValid(p) then local w=p:GetActiveWeapon();if IsValid(w) then weapon=w:GetClass() end end
    local profiles=LOD.CombatRolls.PlayerDamageProfiles
    if weapon=="weapon_lod_crowbar" then weapon="weapon_crowbar" end
    if weapon~="weapon_crowbar" and not profiles[weapon or ""] then weapon=class=="fighter" and "weapon_crowbar" or "weapon_pistol" end
    kit.weapon=weapon
    kit.weaponProfile=table.Copy(profiles[weapon] or {count=1,sides=3,bonus=0})
    kit.weaponModel=({weapon_crowbar="models/weapons/w_crowbar.mdl",weapon_pistol="models/weapons/w_pistol.mdl",
        weapon_smg1="models/weapons/w_smg1.mdl",weapon_ar2="models/weapons/w_irifle.mdl",
        weapon_357="models/weapons/w_357.mdl",weapon_shotgun="models/weapons/w_shotgun.mdl"})[weapon]
    kit.hp=math.Clamp((source.derivedStats and source.derivedStats.maxHP or 100)*1.5,150,260)
    return kit
end
function D:ApplyKit(c,actor,kit,phase,record)
    local giant=phase==3;local hp=giant and self.baseHP*(1+(c.party-1)*.35) or kit.hp*(phase==2 and .85 or 1)
    if record then
        hp=math.max(1,record.savedHP or hp)
        c.data.byActor[record.actor]=nil
        B:Cancel(c,"melf_attack:"..kit.index)
        for _,q in ipairs(record.missiles or {}) do B:RemoveObject(c,q.object,"mirror body lost") end
    end
    local maximum=record and record.savedMax or math.ceil(hp)
    actor.LODProgressionState=table.Copy(record and record.savedProfile or kit.profile)
    actor.LODProgressionState.actorId="melf:"..tostring(c.serial)..":"..phase..":"..kit.index
    actor.LODMirrorKit=kit;actor.LODVarianceApplied=true
    actor:SetModel(phase==2 and "models/player/skeleton.mdl" or kit.model)
    actor:SetColor(kit.color)
    actor.LODBossHull={mins=Vector(giant and -42 or -16,giant and -42 or -16,0),
        maxs=Vector(giant and 42 or 16,giant and 42 or 16,giant and 210 or 72)}
    if B.SetHull then B:SetHull(c,actor,actor.LODBossHull) elseif actor.SetCollisionBounds then actor:SetCollisionBounds(actor.LODBossHull.mins,actor.LODBossHull.maxs) end
    actor.LODBossCombatBounds={mins=Vector(giant and -46 or -14,giant and -46 or -14,0),
        maxs=Vector(giant and 46 or 14,giant and 46 or 14,giant and 220 or 72)}
    actor.LODProgressionState.derivedStats.maxHP=maximum
    actor:SetMaxHealth(maximum);actor:SetHealth(math.min(maximum,math.ceil(hp)))
    actor:SetNW2String("LOD_MonsterName",styleName(kit,phase))
    actor:SetNW2String("LOD_MelfIdentity",tostring(kit.identity))
    actor:SetNW2String("LOD_MelfWeapon",kit.weapon)
    actor:SetNW2String("LOD_MelfClass",kit.class)
    actor:SetNW2Float("LOD_SizeScale",giant and 3.2 or 1)
    actor:SetNW2Bool("LOD_MelfGiant",giant)
    if IsValid(actor.LODWeaponVisual) and kit.weaponModel then actor.LODWeaponVisual:SetModel(kit.weaponModel) end
    if LOD.Magic and kit.profile.usesMagic then LOD.Magic:_Sync(actor,LOD.Magic:_EnsureState(actor)) end
    local m=record or {kit=kit,phase=phase,serial=0,boneReady=0,encounter=c}
    m.actor=actor;m.incarnation=(m.incarnation or 0)+1;m.lost=nil;m.nextRecovery=nil
    m.nextAttack=math.max(m.nextAttack or 0,at(c)+1.4);m.missiles={};m.fakeout=nil;m.fakeoutUntil=nil
    c.data.byActor[actor]=m
    if not record then c.data.bodies[#c.data.bodies+1]=m end
    if actor==c.actor then c.data.primaryBody=m end
    self:SnapshotBody(c,m)
    return m
end
function D:SnapshotBody(c,m)
    if m.encounter~=c or not live(m.actor) or m.dead then return false end
    m.savedHP=m.actor:Health();m.savedMax=m.actor:GetMaxHealth();m.savedPos=copy(m.actor:GetPos())
    m.savedProfile=table.Copy(m.actor.LODProgressionState)
    return true
end
function D:Promote(c,e)
    if not B:ReplacePrimary(c,e) then return false end
    c.data.primaryBody=c.data.byActor[e]
    return true
end
function D:ActorReplaced(c,e)
    if not B:Current(c) or c.dead or c.actor~=e or not live(e) then return false end
    local m=c.data.primaryBody
    if not m or m.encounter~=c or m.dead or m.phase~=c.data.stage then return false end
    if m.actor==e and c.data.byActor[e]==m then return true end
    -- Framework passes the last observed native primary HP/max; preserve that
    -- newer snapshot while rebuilding only the frozen kit and native binding.
    m.savedHP=e:Health();m.savedMax=e:GetMaxHealth()
    self:ApplyKit(c,e,m.kit,m.phase,m)
    B:Log(c,"mirror_primary_rebound",{identity=m.kit.identity,phase=m.phase,incarnation=m.incarnation})
    return true
end
function D:ReconcileBodies(c,t)
    if not B:Live(c) then return end
    local d=c.data
    for _,m in ipairs(d.bodies) do
        if not m.dead and m.encounter==c then
            if live(m.actor) then self:SnapshotBody(c,m)
            elseif not IsValid(m.actor) and not (c.deaths and c.deaths[m.actor]) then
                m.lost=true
                -- The common framework alone recreates the current primary.
                -- A missing support remains an outstanding living identity,
                -- never an implied kill and never a reason to advance phase.
                if m~=d.primaryBody and t>=(m.nextRecovery or 0) then
                    m.nextRecovery=t+1
                    local pos=m.savedPos or B:Point(c,m.kit.index*2)
                    if B:SafePoint(c,pos) then
                        local e=B:SpawnActor(c,"soldier","melf_body",pos,{manual=true,
                            model=m.phase==2 and "models/player/skeleton.mdl" or m.kit.model,
                            scale=m.phase==3 and 3.2 or 1,name=styleName(m.kit,m.phase)})
                        if IsValid(e) then
                            self:ApplyKit(c,e,m.kit,m.phase,m)
                            if not live(c.actor) and d.primaryBody and d.primaryBody.dead then self:Promote(c,e) end
                            B:Log(c,"mirror_support_rebound",{identity=m.kit.identity,phase=m.phase,incarnation=m.incarnation})
                        end
                    end
                end
            end
        end
    end
    -- Pause/freeze may legitimately cancel a pending succession callback. The
    -- durable accepted-death flags remain the authority when service resumes.
    local survivor;local allDead=true
    for _,m in ipairs(d.bodies) do
        if not m.dead then allDead=false;if live(m.actor) then survivor=survivor or m.actor end end
    end
    if survivor and not live(c.actor) and d.primaryBody and d.primaryBody.dead then self:Promote(c,survivor) end
    if allDead and not d.stageSpawning and d.stage<3 and not d.riseAt then d.riseAt=t+1.8 end
end
function D:AfterDamage(c,actor)
    local m=c.data.byActor[actor]
    if m then self:SnapshotBody(c,m) end
end
function D:Start(c)
    local d=c.data;d.kits={};d.bodies={};d.byActor={};d.stage=1
    for i,h in ipairs(c.heroes) do d.kits[i]=self:CaptureKit(c,h,i) end
    assert(#d.kits>0,"Melf requires the committed Hero roster")
    self:ApplyKit(c,c.actor,d.kits[1],1)
    d.nextKit=2;d.stageSpawning=true
    self:SpawnBodies(c)
    B:Announce(c,"YOU, BUT WORSE")
end
function D:SpawnBodies(c)
    local d=c.data
    if not d.stageSpawning then return end
    local limit=d.stage==3 and 1 or #d.kits
    while d.nextKit<=limit do
        local kit=d.stage==3 and d.kits[d.giantIndex] or d.kits[d.nextKit]
        local e=B:SpawnActor(c,"soldier","melf_body",B:Point(c,d.nextKit*2),
            {manual=true,model=d.stage==2 and "models/player/skeleton.mdl" or kit.model,
                scale=d.stage==3 and 3.2 or 1,name=styleName(kit,d.stage)})
        if not IsValid(e) then return end -- bounded retry through normal Think
        self:ApplyKit(c,e,kit,d.stage)
        if d.nextKit==1 or not live(c.actor) then self:Promote(c,e) end
        d.nextKit=d.nextKit+1
    end
    d.stageSpawning=nil
end
function D:BeginStage(c,phase)
    local d=c.data
    d.bodies={};d.byActor={};d.stage=phase;d.nextKit=1;d.stageSpawning=true;d.riseAt=nil
    B:SetPhase(c,phase);B:Clear(c,"mirror_spell")
    if phase==3 then
        d.giantIndex=d.giantIndex or B:Random(c,"melf_giant_identity",1,#d.kits)
        B:Announce(c,"GIANT "..d.kits[d.giantIndex].name.." — MELF THE YOURSELF")
        d.pylons={}
        for i=1,4 do
            local pos=B:SafePoint(c,B:Point(c,i*3))
            if pos then
                local o=B:Object(c,{kind="mirror_pylon",role="mirror_pylon",pos=pos,
                    model="models/props_combine/combine_light001a.mdl",hp=0,solid=false,permanent=true,
                    label="MIRROR PYLON — BAIT STOP HITTING YOURSELF",scale=.75})
                if o then d.pylons[#d.pylons+1]=o end
            end
        end
    else B:Announce(c,"BARE BONES") end
    self:SpawnBodies(c)
end
function D:ActorKilled(c,actor)
    local d=c.data;local m=d.byActor[actor]
    if not m then return false end
    if m.dead then return d.stage<3 end
    m.dead=true
    if d.stage==3 then return false end
    -- No native entity mutation in the lethal stack. Each corpse keeps its
    -- sealed receipt; neither duplicate callbacks nor support death finish Melf.
    B:Later(c,0,"melf_succession",function(owner)
        local state=owner.data;local survivor;local allDead=true
        for _,body in ipairs(state.bodies) do
            if not body.dead then allDead=false;if live(body.actor) then survivor=survivor or body.actor end end
        end
        if survivor then
            if not live(owner.actor) then D:Promote(owner,survivor) end
        elseif allDead and not state.stageSpawning then state.riseAt=at(owner)+1.8 end
    end)
    return true
end
function D:Target(c,m,targets)
    if m.phase==1 then
        for _,h in ipairs(c.heroes) do
            if h.identity==m.kit.identity and B:Hero(c,h.player) then return h.player end
        end
    end
    local best
    for _,p in ipairs(targets) do if not best or p:GetPos():DistToSqr(m.actor:GetPos())<best:GetPos():DistToSqr(m.actor:GetPos()) then best=p end end
    return best
end
function D:WeaponSpec(m,giant)
    local profile=m.kit.weaponProfile
    if m.kit.weapon=="weapon_crowbar" and LOD.RPG.FeatEffectSystem.CrowbarDamageProfile then
        profile=LOD.RPG.FeatEffectSystem:CrowbarDamageProfile(m.actor)
    end
    return {kind=m.kit.weapon=="weapon_crowbar" and "melee" or "bullet",
        dice={profile.count or 1,profile.sides or 3,profile.bonus or 0},
        reference=(profile.count or 1)*((profile.sides or 3)+1)/2+(profile.bonus or 0),
        push=(m.kit.class=="fighter" and (giant and 180 or 90) or 0)}
end
function D:Physical(c,m,p,label,range,warning)
    local origin=copy(m.actor:GetPos());local aim=copy(p:GetPos());local binding=B:BindTarget(c,p)
    local spec=self:WeaponSpec(m,m.phase==3);local life=incarnation(c,m)
    B:Warn(c,label,origin,warning,range,{shape="lane",finish=aim,width=34})
    B:Later(c,warning,"melf_attack:"..m.kit.index,function(owner)
        if not valid(owner,m,life) or not B:TargetLive(owner,binding) or m.actor:GetPos():DistToSqr(origin)>96*96 then return end
        local delta=p:GetPos()-origin;local direction=(aim-origin):GetNormalized()
        if delta:LengthSqr()>range*range or not B:Visible(owner,origin,p,m.actor) then return end
        if spec.kind=="melee" then
            if delta:GetNormalized():Dot(direction)<.65 then return end
        else
            local along=math.Clamp(delta:Dot(direction),0,range)
            if (delta-direction*along):LengthSqr()>38*38 then return end
        end
        spec.gate=function() return valid(owner,m,life) and B:TargetLive(owner,binding) end
        B:Damage(owner,p,spec,m.actor)
    end)
end
function D:Spell(c,m,p,giant)
    local kit=m.kit;local life=incarnation(c,m)
    if #kit.forms==0 then return false end
    local formId=kit.forms[(m.serial-1)%#kit.forms+1]
    local form=LOD.RPG.MagicForms[formId]
    local contentId=#kit.contents>0 and kit.contents[(m.serial-1)%#kit.contents+1] or nil
    local content=contentId and LOD.RPG.MagicContents[contentId]
    local cost=LOD.RPGAbilityRules:OffensiveMagicCost(m.actor,LOD.MagicForms:TotalBaseCost(form,content))
    local pool=LOD.Magic:_EnsureState(m.actor)
    if not pool or pool.magic<cost then return false end
    local origin=copy(m.actor:GetPos())+Vector(0,0,giant and 130 or 52)
    local aim=copy(p:GetPos())+Vector(0,0,30);local binding=B:BindTarget(c,p)
    local radius=giant and 135 or 78;local warning=giant and 1.65 or 1.1
    B:Warn(c,(giant and "GIANT " or "MIRROR ")..string.upper(formId),aim,warning,radius)
    B:Later(c,warning,"melf_attack:"..kit.index,function(owner)
        if not valid(owner,m,life) or not B:TargetLive(owner,binding) then return end
        local status=LOD.RPGStatusElements
        if status and not status:CanInitiateMagic(m.actor) then return end
        if pool.magic<cost then return end
        pool.magic=pool.magic-cost;LOD.Magic:_Sync(m.actor,pool)
        local spec={kind="arc",dice={form.damageDice,form.damageSides,0},
            reference=form.damageDice*(form.damageSides+1)/2,content=contentId,origin=origin,
            gate=function() return valid(owner,m,life) end}
        local direction=(aim-origin):GetNormalized()
        if formId=="beam" then
            B:Zone(owner,{kind="mirror_spell",label="MIRROR BEAM",pos=origin,finish=aim,
                shape="lane",width=giant and 65 or 24,delay=0,life=.15,interval=1,damage=spec,source=m.actor})
        elseif formId=="blast" then B:Area(owner,aim,radius,spec,m.actor)
        elseif formId=="cone" then
            -- Each target receives one native packet, even at overlapping cone depths.
            for _,target in ipairs(B:Targets(owner)) do
                local delta=target:WorldSpaceCenter()-origin
                if delta:LengthSqr()<=(giant and 360 or 240)^2 and delta:GetNormalized():Dot(direction)>.82
                    and B:Visible(owner,origin,target,m.actor) then B:Damage(owner,target,spec,m.actor) end
            end
        elseif formId=="wall" then
            local side=Vector(-direction.y,direction.x,0)*(giant and 130 or 75)
            B:Zone(owner,{kind="mirror_spell",label="MIRROR WALL",pos=aim-side,finish=aim+side,
                shape="lane",width=20,delay=.4,life=3,interval=1,damage=spec,source=m.actor,safeGap=160})
        else
            local bomb=formId=="bomb";local ball=formId=="super_ball";local melon=formId=="watermelon"
            local missile=formId=="missile"
            local projectile=B:Projectile(owner,{kind="mirror_spell",label="MIRROR "..string.upper(formId),
                model=melon and "models/props_junk/watermelon01.mdl" or "models/Items/combine_rifle_ammo01.mdl",
                pos=origin,velocity=direction*(bomb and 380 or missile and 450 or 720)+Vector(0,0,bomb and 180 or 0),
                gravity=(bomb or melon) and 350 or 0,radius=giant and 18 or 8,life=4,mass=8,
                bounces=ball and 3 or melon and 2 or 0,breakOnImpact=not ball and not melon,
                explodeRadius=(bomb or missile) and radius or 0,fuse=bomb and 2 or nil,
                damage=spec,source=m.actor})
            if projectile and missile then
                m.missiles=m.missiles or {}
                m.missiles[#m.missiles+1]={object=projectile,binding=binding,aim=aim}
            end
        end
    end)
    return true
end
function D:Reflect(c,m,position,origin)
    position=position or m.actor:GetPos()
    for _,o in ipairs(c.data.pylons or {}) do
        local impact=position
        if origin then
            local segment=position-origin;local denominator=segment:LengthSqr()
            local along=denominator>0 and math.Clamp((o.pos-origin):Dot(segment)/denominator,0,1) or 0
            impact=origin+segment*along
        end
        if not o.retired and impact:DistToSqr(o.pos)<115*115 then
            B:SelfDamage(c,math.min(m.actor:GetMaxHealth()*.045,45),"mirror pylon reflection",m.actor)
            B:Stagger(c,3,m.actor);B:Announce(c,"STOP HITTING YOURSELF — REFLECTED")
            return true
        end
    end
    return false
end
function D:StopHittingYourself(c,m,targets)
    local p
    for _,h in ipairs(c.heroes) do if h.identity==m.kit.identity and B:Hero(c,h.player) then p=h.player;break end end
    p=p or self:Target(c,m,targets)
    if not p then return end
    local target=copy(p:GetPos());local origin=copy(m.actor:GetPos());local life=incarnation(c,m)
    B:Announce(c,"STOP HITTING YOURSELF — "..m.kit.name)
    B:Charge(c,m.actor,target,{label="STOP HITTING YOURSELF",warning=2,speed=390,width=90,
        damage=self:WeaponSpec(m,true),recovery=2.5,onFinish=function(owner,hit,pos)
            if valid(owner,m,life) then D:Reflect(owner,m,pos or target,origin) end
        end})
end
function D:Giant(c,m,p,targets)
    local life=incarnation(c,m)
    local n=(m.serial-1)%4
    if n==3 then self:StopHittingYourself(c,m,targets);return end
    if m.kit.class=="fighter" then
        local origin=copy(m.actor:GetPos());local aim=copy(p:GetPos())
        if n==0 then B:Zone(c,{kind="giant_slam",label="HUGE WEAPON SLAM",pos=aim,radius=135,
            delay=1.6,life=.2,interval=1,damage=self:WeaponSpec(m,true),source=m.actor})
        elseif n==1 then B:Zone(c,{kind="giant_sweep",label="GIANT WEAPON SWEEP",pos=origin,
            finish=aim,shape="lane",width=135,delay=1.8,life=.2,interval=1,
            damage=self:WeaponSpec(m,true),source=m.actor,safeGap=180})
        else
            local direction=(aim-origin):GetNormalized()
            B:Warn(c,"GIANT CONE PUSH",aim,1.4,170)
            B:Later(c,1.4,"giant_cone",function(owner)
                if not valid(owner,m,life) then return end
                for _,target in ipairs(B:Targets(owner)) do
                    local delta=target:GetPos()-origin
                    if delta:LengthSqr()<=340*340 and delta:GetNormalized():Dot(direction)>.75 then B:Push(owner,target,direction,220,m.actor) end
                end
            end)
        end
    elseif m.kit.class=="rogue" then
        if n==0 then
            local behind=B:SafePoint(c,p:GetPos()-p:GetForward()*220)
            if behind then
                B:Warn(c,"BEHIND YOU — GIANT FAKEOUT",behind,1.2,120)
                B:Later(c,1.2,"giant_fakeout",function(owner)
                    if valid(owner,m,life) then m.fakeout=behind;m.fakeoutUntil=at(owner)+2.2;B:Move(owner,m.actor,behind,330,{mode="ground"}) end
                end)
            end
        elseif n==1 then
            for i=1,3 do
                local pos=B:Floor(c,p:GetPos()+Vector((i-2)*105,0,0))
                if pos then B:Zone(c,{kind="weapon_rain",label="GIANT WEAPON RAIN "..i,pos=pos,radius=65,
                    delay=1.2+i*.4,life=.2,interval=1,damage=self:WeaponSpec(m,true),source=m.actor}) end
            end
        else
            for i=1,3 do B:Zone(c,{kind="shadow_floor",label="SHADOW FLOOR "..i,pos=B:Point(c,i*3),
                radius=115,delay=1+i*.8,life=1.2,interval=1.3,damage=self:WeaponSpec(m,true),source=m.actor,safeGap=180}) end
        end
    elseif not self:Spell(c,m,p,true) then self:Physical(c,m,p,"GIANT REPRESENTATIVE WEAPON",600,1.4) end
end
function D:Think(c,t,dt,targets)
    if not B:Live(c) then return end
    local d=c.data
    self:ReconcileBodies(c,t)
    if d.riseAt and t>=d.riseAt then self:BeginStage(c,d.stage+1) end
    if d.stageSpawning then self:SpawnBodies(c) end
    for _,m in ipairs(d.bodies) do
        local pushed=IsValid(m.actor) and m.actor.LODLastPushback
        if m.phase==2 and pushed and pushed~=m.seenPush then
            m.seenPush=pushed
            if pushed.crushed or (pushed.moved or 0)>=96 then self:BoneBreak(c,m) end
        end
        local missiles={}
        for _,q in ipairs(m.missiles or {}) do
            local o=q.object
            if not o.retired and IsValid(o.ent) and valid(c,m) then
                if B:TargetLive(c,q.binding) then q.aim=copy(q.binding.player:WorldSpaceCenter()) end
                local desired=(q.aim-o.pos):GetNormalized()*450
                o.velocity=(o.velocity+(desired-o.velocity)*math.min(.18,dt*1.2)):GetNormalized()*450
                missiles[#missiles+1]=q
            end
        end
        m.missiles=missiles
        if valid(c,m) and t>=(m.brokenUntil or 0) then
        local p=self:Target(c,m,targets)
        if p then
            local distance=m.actor:GetPos():DistToSqr(p:GetPos())
            local range=m.kit.class=="fighter" and 120 or 600
            if m.fakeout and t<(m.fakeoutUntil or 0) then
                B:Move(c,m.actor,m.fakeout,330,{mode="ground",stopDistance=45})
            elseif distance>range*range or m.kit.class=="rogue" and m.phase<3 then
                local destination=p:GetPos()
                if m.kit.class=="rogue" then destination=B:SafePoint(c,p:GetPos()-p:GetForward()*95) or destination end
                B:Move(c,m.actor,destination,m.phase==2 and 230 or 175,{mode="ground",stopDistance=45})
            end
            if t>=m.nextAttack then
                m.serial=m.serial+1
                local cadence=LOD.RPGAbilityRules.RateOfFireMultiplier and LOD.RPGAbilityRules:RateOfFireMultiplier(m.actor) or 1
                m.nextAttack=t+(m.phase==3 and 4.5 or m.phase==2 and 2.1 or 3)/math.max(1,cadence)
                if m.phase==3 then self:Giant(c,m,p,targets)
                elseif m.kit.class=="wizard" and self:Spell(c,m,p,false) then
                else self:Physical(c,m,p,m.phase==2 and "SKELETON ATTACK" or "MIRROR ATTACK",range,m.phase==2 and .75 or 1.1) end
            end
        end
    end end
end
function D:BoneBreak(c,m)
    if m.phase~=2 or at(c)<(m.boneReady or 0) or not valid(c,m) then return false end
    m.boneReady=at(c)+8;m.brokenUntil=at(c)+1.8
    B:Cancel(c,"melf_attack:"..m.kit.index);B:Stop(c,m.actor);B:Stagger(c,1.8,m.actor)
    m.actor:SetNW2Float("LOD_BoneBreakUntil",m.brokenUntil);B:Announce(c,"BONE BREAK")
    return true
end
function D:BeforeDamage(c,actor,info)
    local m=c.data.byActor[actor]
    if not m or m.phase~=2 or not info or at(c)<(m.boneReady or 0) then return true end
    local context=LOD.RPGStatusElements:DamageContext(info,actor) or {}
    local force=info.GetDamageForce and info:GetDamageForce()
    if context.wallCrush or info:GetDamage()>=35 or force and force:LengthSqr()>=450*450 then
        self:BoneBreak(c,m)
    end
    return true
end
function D:Pause(c)
    for _,m in ipairs(c.data.bodies or {}) do if live(m.actor) then B:Stop(c,m.actor) end end
end
function D:Defeat(c)
    B:Announce(c,"YOU DEFEATED YOURSELF")
    B:Object(c,{kind="melf_fractured_core",role="cosmetic",pos=B:Center(c)+Vector(0,0,32),
        model="models/props_combine/breenclock.mdl",scale=.6,life=2,solid=false,hp=0,
        label="FRACTURED MIRROR CORE",cosmetic=true})
end
function D:Snapshot(c)
    local d=c.data;local living=0
    for _,m in ipairs(d.bodies or {}) do if not m.dead then living=living+1 end end
    if d.stage==3 then return "GIANT "..d.kits[d.giantIndex].name.." — BAIT MIRROR PYLONS" end
    return (d.stage==2 and "SKELETONS " or "MIRRORS ")..living.."/"..#(d.kits or {})
end
B:Register("melf",D)
