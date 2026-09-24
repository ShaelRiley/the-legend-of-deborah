-- Complete ordinary roster. Native models only; attacks share RPG authorities.
LOD.EnemyRoster = LOD.EnemyRoster or {}
local E=LOD.EnemyRoster
local EC=LOD.Config.Encounter
E.Definitions={
    fusilier={name="Fusilier",model="models/combine_soldier.mdl",baseHP=45,speed=125,damage=5.5,range=360,warning=1.25,recovery=3,threat=3.5,activity=ACT_RUN_AIM_RIFLE or ACT_RUN,kind="bullet",crossfire=1,color=Color(225,135,75),dice={1,6,2}},
    bombardier={name="Bombardier",model="models/combine_super_soldier.mdl",baseHP=55,speed=100,damage=5.5,range=360,warning=1.6,recovery=3.5,threat=4,activity=ACT_RUN_AIM_RIFLE or ACT_RUN,kind="bullet",crossfire=2,color=Color(210,175,80),dice={1,6,2}},
    siphoner={name="Siphoner",model="models/stalker.mdl",baseHP=35,speed=125,damage=5.5,range=360,warning=1.25,recovery=3.5,threat=3.5,activity=ACT_WALK,kind="arc",contentId="raw",resource="drain",color=Color(185,115,235),dice={1,6,2}},
    accumulator={name="Accumulator",model="models/vortigaunt_slave.mdl",baseHP=50,speed=100,damage=5.5,range=360,warning=1.25,recovery=2.5,threat=4,activity=ACT_WALK,kind="arc",contentId="raw",resource="recharge",color=Color(235,205,95),dice={1,6,2}},
    outrider={name="Outrider",model="models/antlion.mdl",baseHP=45,speed=170,damage=5.5,range=144,warning=1.1,recovery=2.4,threat=3.5,activity=ACT_RUN,kind="melee",melee="single",spacing="isolation",color=Color(225,170,80),dice={1,6,2}},
    conductor={name="Conductor",model="models/vortigaunt.mdl",baseHP=40,speed=110,damage=5.5,range=360,warning=1.4,recovery=3.5,threat=4,activity=ACT_WALK,kind="bolt",contentId="raw",spacing="link",color=Color(150,190,250),dice={1,6,2}},
    absolver={name="Absolver",model="models/vortigaunt_slave.mdl",baseHP=40,speed=105,damage=3.5,range=600,warning=.7,recovery=2.2,threat=3.5,activity=ACT_WALK,kind="bullet",support="cleanse",color=Color(170,240,225),dice={1,4,1}},
    exactor={name="Exactor",model="models/combine_super_soldier.mdl",baseHP=50,speed=130,damage=5.5,range=360,warning=1.25,recovery=3,threat=4,activity=ACT_RUN_AIM_RIFLE or ACT_RUN,kind="bullet",condition=true,color=Color(230,95,115),dice={1,6,2}},
    listener={name="Listener",model="models/police.mdl",baseHP=40,speed=165,damage=5.5,range=112,warning=.9,recovery=1.8,threat=3.5,activity=ACT_RUN,kind="melee",melee="single",perception="sound",color=Color(235,195,100),dice={1,6,2}},
    shy={name="Shy",model="models/zombie/fast.mdl",baseHP=50,speed=180,damage=5.5,range=112,warning=.9,recovery=1.8,threat=3.5,activity=ACT_RUN,kind="melee",melee="single",perception="sight",color=Color(175,150,230),dice={1,6,2}},
    censer={name="Censer",model="models/combine_soldier.mdl",baseHP=45,speed=120,damage=5.5,range=320,warning=1.2,recovery=3.5,threat=3.5,activity=ACT_RUN,kind="bullet",mobile="carrier",color=Color(220,150,60),dice={1,6,2}},
    trailmaker={name="Trailmaker",model="models/police.mdl",baseHP=35,speed=150,damage=5.5,range=320,warning=1.2,recovery=3.5,threat=3.5,activity=ACT_RUN,kind="bullet",mobile="trail",color=Color(130,195,85),dice={1,6,2}},
    towline={name="Towline",model="models/police.mdl",baseHP=40,speed=135,damage=5.5,range=320,warning=1.2,recovery=3,threat=3.5,activity=ACT_RUN,kind="bullet",tactical="tow",color=Color(70,200,185),dice={1,6,2}},
    screenwright={name="Screenwright",model="models/combine_soldier.mdl",baseHP=50,speed=110,damage=3.5,range=600,warning=1,recovery=4,threat=4,activity=ACT_RUN_AIM_RIFLE or ACT_RUN,kind="bullet",tactical="screen",color=Color(100,155,230),dice={1,4,1}},
    afterburst={name="Afterburst",model="models/zombie/classic.mdl",baseHP=50,speed=105,damage=5.5,range=112,warning=.9,recovery=2.5,threat=3.5,activity=ACT_RUN,kind="melee",melee="single",color=Color(215,115,65),dice={1,6,2}},
    carrion={name="Carrion",model="models/zombie/fast.mdl",baseHP=45,speed=155,damage=5.5,range=112,warning=.8,recovery=2.2,threat=4,activity=ACT_RUN,kind="melee",melee="single",color=Color(160,190,85),dice={1,6,2}},
    reaper={name="Reaper",model="models/zombie/classic.mdl",baseHP=55,speed=140,damage=5.5,range=144,warning=1.1,recovery=2.5,threat=3.5,activity=ACT_RUN,kind="melee",melee="sweep",color=Color(135,190,125),dice={1,6,2}},
    drubber={name="Drubber",model="models/zombie/fast.mdl",baseHP=60,speed=125,damage=5.5,range=112,warning=1,recovery=2.8,threat=4,activity=ACT_RUN,kind="melee",melee="double",color=Color(220,160,70),dice={1,6,2}},
    fencer={name="Fencer",model="models/police.mdl",baseHP=35,speed=180,damage=5.5,range=144,warning=.9,recovery=2.5,threat=3.5,activity=ACT_RUN,kind="melee",melee="feint",color=Color(195,155,235),dice={1,6,2}},
    nodule={name="Nodule",model="models/barnacle.mdl",baseHP=30,speed=0,damage=3.5,range=384,warning=0,recovery=1,threat=2.5,activity=ACT_IDLE,kind="gas",stationary=true,dice={1,4,1}},
    climber={name="Climber",model="models/zombie/fast.mdl",baseHP=14,speed=205,damage=3.5,range=225,warning=.4,recovery=.75,threat=1.8,activity=ACT_RUN,kind="climber",color=Color(255,35,180),dice={1,4,1}},
    flamer={name="Flamer",model="models/combine_soldier.mdl",baseHP=40,speed=140,damage=13.5,range=280,warning=1,recovery=2.5,threat=3,activity=ACT_RUN_AIM_RIFLE or ACT_RUN,kind="flame",color=Color(240,65,55),dice={3,6,3}},
    bigcrab={name="Big Crab",model="models/headcrabclassic.mdl",baseHP=75,speed=105,damage=13.5,range=280,warning=1,recovery=2.5,threat=4,activity=ACT_RUN,kind="flame",dice={3,6,3}},
    sentry={name="Sentry",model="models/combine_turrets/floor_turret.mdl",baseHP=55,speed=0,damage=9,range=1050,warning=.75,recovery=.7,threat=3.5,activity=ACT_IDLE,kind="bullet",stationary=true,dice={2,6,2}},
    razor={name="Razor",model="models/manhack.mdl",baseHP=22,speed=185,damage=11,range=560,warning=.65,recovery=1.8,threat=2.8,activity=ACT_FLY or ACT_RUN,kind="dive",dice={2,6,4}},
    arccaster={name="Arc Caster",model="models/vortigaunt.mdl",baseHP=40,speed=100,damage=13.5,range=1000,warning=1.25,recovery=2.8,threat=3.5,activity=ACT_WALK,kind="arc",dice={3,6,3}},
    lurker={name="Lurker",model="models/barnacle.mdl",baseHP=24,speed=0,damage=5.5,range=1000,warning=1,recovery=3,threat=2.5,activity=ACT_IDLE,kind="venom",stationary=true,dice={1,4,3}},
    beamsweeper={name="Beam Sweeper",model="models/stalker.mdl",baseHP=50,speed=0,damage=10,range=640,warning=1.4,recovery=3,threat=3.8,activity=ACT_IDLE,kind="beam",stationary=true,dice={2,6,3}},
    -- B1 custodians: Content is attack identity, independent of rolled affinity/class.
    gaoler={name="Gaoler",model="models/vortigaunt.mdl",baseHP=40,speed=100,damage=5.5,range=720,warning=1.25,recovery=3.2,threat=3.5,activity=ACT_WALK,kind="arc",contentId="ice",color=Color(90,180,255),dice={1,6,2}},
    silencer={name="Silencer",model="models/combine_super_soldier.mdl",baseHP=30,speed=150,damage=5.5,range=800,warning=.9,recovery=2.8,threat=3,activity=ACT_RUN_AIM_RIFLE or ACT_RUN,kind="bolt",contentId="light",color=Color(235,225,175),dice={1,6,2}},
    repulsor={name="Repulsor",model="models/vortigaunt.mdl",baseHP=55,speed=125,damage=5.5,range=220,warning=1.1,recovery=3,threat=3.5,activity=ACT_WALK,kind="pulse",contentId="earth",color=Color(190,135,55),dice={1,6,2}},
    stitcher={name="Stitcher",model="models/vortigaunt_slave.mdl",baseHP=35,speed=100,damage=3.5,range=600,warning=.7,recovery=2.2,threat=3.5,activity=ACT_WALK,kind="bullet",support="recovery",color=Color(90,230,150),dice={1,4,1}},
    bulwark={name="Bulwark",model="models/combine_super_soldier.mdl",baseHP=65,speed=90,damage=3.5,range=600,warning=.7,recovery=2.2,threat=4,activity=ACT_RUN_AIM_RIFLE or ACT_RUN,kind="bullet",support="protection",color=Color(100,150,240),dice={1,4,1}},
    cantor={name="Cantor",model="models/police.mdl",baseHP=40,speed=140,damage=3.5,range=600,warning=.7,recovery=2.2,threat=3.5,activity=ACT_RUN_AIM_RIFLE or ACT_RUN,kind="bullet",support="rally",color=Color(235,180,70),dice={1,4,1}},
    pincer={name="Pincer",model="models/combine_soldier.mdl",baseHP=40,speed=180,damage=5.5,range=520,warning=.65,recovery=2.5,threat=3.5,activity=ACT_RUN_AIM_RIFLE or ACT_RUN,kind="bullet",pursuit=true,color=Color(210,100,235),dice={1,6,2}},
    harrier={name="Harrier",model="models/police.mdl",baseHP=30,speed=190,damage=5.5,range=720,warning=.85,recovery=3,threat=3.5,activity=ACT_RUN_AIM_RIFLE or ACT_RUN,kind="bullet",pursuit=true,color=Color(65,215,215),dice={1,6,2}},
    pavise={name="Pavise",model="models/combine_super_soldier.mdl",baseHP=65,speed=110,damage=5.5,range=600,warning=.7,recovery=2.4,threat=4,activity=ACT_RUN_AIM_RIFLE or ACT_RUN,kind="bullet",reaction=true,color=Color(165,190,215),dice={1,6,2}},
    repriser={name="Repriser",model="models/police.mdl",baseHP=40,speed=145,damage=5.5,range=600,warning=.7,recovery=2.4,threat=3.5,activity=ACT_RUN_AIM_RIFLE or ACT_RUN,kind="bullet",reaction=true,color=Color(230,100,180),dice={1,6,2}},
    redliner={name="Redliner",model="models/combine_soldier.mdl",baseHP=50,speed=170,damage=5.5,range=600,warning=.7,recovery=2.4,threat=3.5,activity=ACT_RUN_AIM_RIFLE or ACT_RUN,kind="bullet",reaction=true,color=Color(215,65,45),dice={1,6,2}},
    wirewright={name="Wirewright",model="models/combine_soldier.mdl",baseHP=40,speed=125,damage=5.5,range=600,warning=1.25,recovery=3,threat=3.5,activity=ACT_RUN_AIM_RIFLE or ACT_RUN,kind="bullet",trap="wire",color=Color(240,175,70),dice={1,6,2}},
    snarer={name="Snarer",model="models/vortigaunt.mdl",baseHP=35,speed=110,damage=5.5,range=600,warning=1,recovery=3.5,threat=3.5,activity=ACT_WALK,kind="arc",trap="snare",contentId="ice",color=Color(95,190,250),dice={1,6,2}},
    cordon={name="Cordon",model="models/combine_turrets/floor_turret.mdl",baseHP=55,speed=0,damage=5.5,range=600,warning=1.5,recovery=4,threat=4,activity=ACT_IDLE,kind="bullet",trap="ring",stationary=true,color=Color(235,110,60),dice={1,6,2}},
    caromer={name="Caromer",model="models/combine_soldier.mdl",baseHP=40,speed=125,damage=5.5,range=720,warning=1.1,recovery=3,threat=3.5,activity=ACT_RUN_AIM_RIFLE or ACT_RUN,kind="bullet",pattern="bank",color=Color(90,210,240),dice={1,6,2}},
    reeler={name="Reeler",model="models/police.mdl",baseHP=40,speed=145,damage=5.5,range=600,warning=1.1,recovery=3.5,threat=3.5,activity=ACT_RUN_AIM_RIFLE or ACT_RUN,kind="bullet",pattern="return",color=Color(235,180,95),dice={1,6,2}},
    forker={name="Forker",model="models/combine_super_soldier.mdl",baseHP=55,speed=110,damage=5.5,range=600,warning=1.2,recovery=3.2,threat=4,activity=ACT_RUN_AIM_RIFLE or ACT_RUN,kind="bullet",pattern="split",color=Color(150,240,180),dice={1,6,2}},
    waylayer={name="Waylayer",model="models/combine_super_soldier.mdl",baseHP=55,speed=145,damage=5.5,range=520,warning=.8,recovery=2.8,threat=4,activity=ACT_RUN_AIM_RIFLE or ACT_RUN,kind="bullet",pursuit=true,color=Color(245,145,65),dice={1,6,2}}
}
for id,d in pairs(E.Definitions) do
    EC.Archetypes[id]={class="lod_hostile",name=d.name,model=d.model,baseHP=d.baseHP,speed=d.speed,
        meleeDamage=0,meleeRange=0,meleeCooldown=99,burstDamage=d.damage,fireRange=d.range,
        burstTelegraph=d.warning,burstCooldown=d.recovery,activity=d.activity,threat=d.threat}
    LOD.CombatRolls.HostileDamageProfiles[id]={label=string.upper(d.name),source=d.kind,
        count=d.dice[1],sides=d.dice[2],bonus=d.dice[3],reference=d.damage,magicDamage=d.contentId~=nil}
end
E.Active=E.Active or setmetatable({}, {__mode="k"})
E.Projectiles=E.Projectiles or {}
local N=LOD.MazeNavigator
local function key(c) return c and LOD.MazeGenerator.CellKey(c.x,c.y,c.z) end
E.Key=key
local function state() return LOD.RunManager and LOD.RunManager.State end
-- Seeds repeat deliberately; object identity and campaign scope distinguish rebuilds.
function E:Bind(record,s)
    record.run=s;record.seed=s.LevelSeed;record.graph=s.Graph
    record.progression=s.Graph and s.Graph.Progression
    record.epoch=s.CampaignEpoch;record.campaignSeed=s.CampaignSeed;record.runId=s.RunId
    return record
end
function E:Live(record,s)
    return record and s and record.run==s and record.seed==s.LevelSeed and record.graph==s.Graph
        and record.progression==(s.Graph and s.Graph.Progression) and record.epoch==s.CampaignEpoch
        and record.campaignSeed==s.CampaignSeed and record.runId==s.RunId
end
-- Shared incarnation binding for finite roster commitments; no new life owner.
function E:CaptureLife(e,hero)
    local status,rules=LOD.RPGStatusElements,LOD.RPGAbilityRules
    status:BindActorLife(e);status:BindActorLife(hero)
    return self:Bind({source=e,hero=hero,sourceState=rules:ProgressionState(e),heroState=rules:ProgressionState(hero),
        sourceLife=status.ActorLives[e],heroLife=status.ActorLives[hero]},state())
end
function E:ValidSourceLife(r)
    local s=state();local status,rules=LOD.RPGStatusElements,LOD.RPGAbilityRules
    return r and s and s.BuildReady and not s.Failed and not s.LevelCleared and not s.SimulationFrozen
        and self:Live(r,s) and IsValid(r.source) and not r.source.LODDead
        and r.source:Health()>0 and r.source.LODActivated
        and (not r.source.LODRosterContext or self:Live(r.source.LODRosterContext,s))
        and rules:ProgressionState(r.source)==r.sourceState and status.ActorLives[r.source]==r.sourceLife
end
function E:ValidLife(r)
    return self:ValidSourceLife(r) and self:Target(r.hero)
        and LOD.RPGAbilityRules:ProgressionState(r.hero)==r.heroState
        and LOD.RPGStatusElements.ActorLives[r.hero]==r.heroLife
end
function E:CanCast(e)
    local statuses=LOD.RPGStatusElements
    local d=self.Definitions[e.LODArchetypeId]
    return statuses:CanInitiateAttack(e) and (not (d and (d.pattern or d.trap or d.melee or d.tactical or d.mobile or d.condition or d.spacing or d.resource or d.crossfire)) or not statuses:Has(e,"morale_flee"))
        and (not (d and d.contentId) or statuses:CanInitiateMagic(e))
end
function E:Target(p) return LOD.FactionManager:IsValidPlayerTarget(p) end
function E:AcquireTarget(p) return LOD.FactionManager:CanAcquirePlayerTarget(p) end
function E:Safe(graph,c)
    local tag=graph and c and (graph.CellTags or {})[key(c)]
    return not c or (tag and (tag.safe or tag.role=="boss" or tag.role=="resupply"))
end
function E:Visible(e,p,origin)
    local tr=util.TraceLine({start=origin or e:WorldSpaceCenter(),endpos=p:WorldSpaceCenter(),mask=MASK_SOLID,
        filter=function(v) return v~=e and not v.LODHostile end})
    return not tr.Hit or tr.Entity==p
end
function E:Origin(e)
    if e.LODArchetypeId=="lurker" then return e:GetPos()+Vector(0,0,-22) end
    return e:GetPos()+Vector(0,0,e.LODArchetypeId=="bigcrab" and 32 or 48)
end
function E:Prepare(e)
    if e.LODArchetypeId=="nodule" and LOD.HostileShapes then
        local size=e:GetNW2Float('LOD_SizeScale',1)
        if e.LODNoduleHullScale~=size then
            local lo,hi=LOD.HostileShapes:NoduleBounds(e)
            e:SetSolid(SOLID_BBOX);e:SetCollisionBounds(lo,hi)
            e.LODNoduleHullScale=size
        end
    end
    if e.LODRosterReady then return end
    if self.Definitions[e.LODArchetypeId].perception then e.LODPerceptionBorn=CurTime() end
    e.LODRosterReady=true;self.Active[e]=true;e:SetNW2Bool("LOD_RosterAlive",true)
    e.LODRosterContext=self:Bind({},state())
    local d=self.Definitions[e.LODArchetypeId]
    if d.color then e:SetColor(d.color) end
    if d.stationary then e.LODRosterAnchor=e:GetPos();e.LODRosterYaw=e:GetAngles().y end
end
function E:Cancel(e)
    local d=self.Definitions[e.LODArchetypeId]
    if d and d.perception then e.LODPerceptionMemory=nil;e.LODPerceptionDiscardBefore=CurTime() end
    if e.LODRosterAttack and e.LODRosterAttack.tactical then self:RetireTactical(e) end
    if e.LODRosterAttack and (e.LODRosterAttack.mobile or e.LODRosterAttack.perception) then LOD.HostileMotionV2:Stop(e) end
    e.LODRosterAttack=nil;e:SetNW2Int("LOD_RosterAttack",0)
    if d and d.condition then e:SetNW2Bool("LOD_ConditionMark",false) end
    if d and d.spacing then e:SetNW2Int("LOD_SpacingMode",0) end
    if d and d.resource then e:SetNW2Int("LOD_ResourceMode",0) end
    if d and d.crossfire then e:SetNW2Int("LOD_CrossfireMode",0);e:SetNW2Float("LOD_CrossfireUntil",0) end
end
function E:Interrupt(e,attackEvent,attacker)
    if self.Definitions[e.LODArchetypeId] and self.Definitions[e.LODArchetypeId].perception then
        e.LODPerceptionMemory=nil;e.LODPerceptionDiscardBefore=CurTime()
    end
    if LOD.EnemyRemains then LOD.EnemyRemains:Interrupt(e) end
    if LOD.EnemyReactions then LOD.EnemyReactions:Interrupt(e,attackEvent,attacker) end
    if LOD.EnemySupport then LOD.EnemySupport:Interrupt(e) end
    if LOD.EnemyPursuit then LOD.EnemyPursuit:Cancel(e) end
    local a=e.LODRosterAttack
    -- A released beam is solved by movement/cover; gunfire only cancels charge.
    if a and (a.melee or a.tactical or a.mobile or a.perception or a.condition or a.spacing or a.spacingFallback or a.resource or a.crossfire) then self:Finish(e,CurTime())
    elseif a and not (a.released and a.kind=="beam") then self:Cancel(e) end
    if LOD.Climber then LOD.Climber:Interrupt(e) end
end
function E:Damage(e,p,event,kind)
    if e.LODSkeletonHero and not LOD.SkeletonHero:Live(e) then return end
    if not IsValid(e) or e.LODDead or not self:Target(p) then return end
    return self:_DamagePacket(e,p,event,kind)
end
-- Shared packet construction; ordinary callers enter through Damage's living
-- gate. Post-defeat callers enter only through EnemyRemains' sealed receipt.
function E:_DamagePacket(e,p,event,kind)
    local gate=event.crossfireGate
    if gate and not gate() then return end
    local rolls=LOD.CombatRolls
    local profile=rolls.HostileDamageProfiles[e.LODArchetypeId]
    if e.LODSkeletonHero and kind=="arc" then profile=table.Copy(profile);profile.magicDamage=true end
    event.roll=event.roll or rolls:RollHostileAttack(e,profile,e.LODConfig.burstDamage)
    if gate and not gate() then return end
    local c={};for k,v in pairs(event.roll) do c[k]=v end
    if e.LODSkeletonHero and event.skeletonFullMagicBonus~=nil then c.wizardFullMagicIntBonus=event.skeletonFullMagicBonus end
    if event.resourceFullMagicBonus~=nil then c.wizardFullMagicIntBonus=event.resourceFullMagicBonus end
    if event.impactOrigin then c.sourcePosition=event.impactOrigin end
    local d=self.Definitions[e.LODArchetypeId]
    local magic=kind=="arc" or kind=="beam" or (d and d.contentId~=nil)
    local rider=(kind=="flame" and "immolated") or (kind=="venom" and "poisoned") or nil
    event.riders=event.riders or setmetatable({}, {__mode="k"})
    local tags={physical=not magic,magic=magic,melee=kind=="dive" or kind=="climber" or kind=="melee",
        element=kind=="flame" and "fire" or (magic and "raw" or nil),
        attackEvent=c.attackEvent,damageContract=c,authoredScale=c.scale,
        riderStatusId=rider,riderConsumedTargets=event.riders}
    local content=event.skeletonContent or (d and d.contentId and LOD.RPG.MagicContents[d.contentId])
    if magic and content then
        for k,v in pairs(LOD.MagicForms:_DamageContext(content)) do tags[k]=v end
        local definition=tags.riderStatusId and LOD.RPGStatusElements.Registry[tags.riderStatusId]
        if definition and definition.ability then tags.riderDC=LOD.RPGStatusElements:ConditionDC(e,definition.ability) end
    elseif rider then tags.riderDC=LOD.RPGStatusElements:ConditionDC(e,rider=="immolated" and "dex" or "con") end
    local amount=rolls:ResolveActorDamage(c,e,p,tags)
    if gate and not gate() then return end
    local info=LOD.NewDamageInfo();info:SetAttacker(e);info:SetInflictor(e);info:SetDamage(amount)
    info:SetDamageType(magic and DMG_ENERGYBEAM or (kind=="flame" and DMG_BURN or ((kind=="venom" or kind=="gas") and DMG_POISON or DMG_SLASH)))
    info:SetDamagePosition(p:WorldSpaceCenter());tags.actorDamageResolved=true
    LOD.RPGStatusElements:AttachDamageContext(info,tags)
    rolls:QueueDamageReport(info,function(final)
        c.final=final
        local observer=event.crossfireAttack and event.crossfireAttack.target or p
        if IsValid(observer) and observer:IsPlayer() then rolls:_Send(observer,1,rolls:_HostileRollText(c,e,p)) end
    end)
    if gate and not gate() then return end
    local before=p:Health()
    if event.crossfireAttack then self:AuthorizeCrossfire(info,e,p,event.crossfireAttack) end
    p:TakeDamageInfo(info)
    if event.crossfireAttack then self:RevokeCrossfire(info) end
    if IsValid(e) and not e.LODDead and IsValid(p) and content
        and (not e.LODSkeletonHero or LOD.SkeletonHero:Live(e)) then
        local after=p:Health()
        LOD.MagicForms:ApplyContentPush(e,e,p,content,(p:GetPos()-(event.pushOrigin or e:GetPos())):GetNormalized(),
            math.max(0,math.min(before,before-after)))
    end
    return IsValid(p) and math.max(0,math.min(before,before-p:Health())) or 0
end
local sounds={flame="ambient/fire/ignite.wav",arc="npc/vort/attack_charge.wav",bolt="npc/vort/attack_charge.wav",pulse="npc/vort/attack_charge.wav",venom="npc/barnacle/barnacle_tongue_pull1.wav",
    beam="npc/stalker/laser_burn.wav",bullet="npc/turret_floor/active.wav",dive="npc/manhack/mh_engine_start1.wav"}
function E:Begin(e,p,now,override)
    override=override or {}
    if e.LODSkeletonHero and not LOD.SkeletonHero:CanBeginArc(e,now) then return false end
    local d=self.Definitions[e.LODArchetypeId];local cfg=e.LODConfig
    if d.resource then return self:BeginResource(e,p,now) end
    if d.crossfire then return self:BeginCrossfire(e,p,now) end
    if d.spacing and not override.spacingFallback then return self:BeginSpacing(e,p,now) end
    if d.condition and not override.conditionFallback then return self:BeginCondition(e,p,now) end
    if d.tactical and not override.tacticalFallback then return self:BeginTactical(e,p,now) end
    if d.mobile then return self:BeginMobile(e,p,now) end
    if d.trap then return self:BeginTrap(e,p,now) end
    if d.melee then return self:BeginMelee(e,p,now) end
    local origin=self:Origin(e);local aim=p:WorldSpaceCenter()
    local a={kind=override.kind or d.kind,target=p,origin=origin,aim=aim,ready=now+(override.warning or cfg.burstTelegraph),
        range=override.range or cfg.fireRange,
        seed=state().LevelSeed,run=state(),hit={},event={},started=now,direction=(aim-origin):GetNormalized()}
    self:Bind(a,state())
    if override.spacingFallback then
        a.spacingFallback=true;a.last=now;a.life=self:CaptureLife(e,p)
        a.sourceGround=Vector(e:GetPos().x,e:GetPos().y,e:GetPos().z);a.cell=N:WorldToCell(state().Graph,a.sourceGround)
    end
    if override.tacticalFallback or override.conditionFallback or override.spacingFallback then a.fallbackLife=self:CaptureLife(e,p);a.deadline=a.ready+.2 end
    if d.pattern then
        if not self:PlanPattern(e,a,d.pattern) then e.LODNextAttack=now+.5;return false end
        a.patternLife=self:CaptureLife(e,p);a.deadline=a.ready+.2
    end
    if d.reaction and LOD.EnemyReactions then a.reactionRecord=override.reactionRecord or LOD.EnemyReactions:Capture(e,p) end
    if d.pursuit and LOD.EnemyPursuit then
        a.pursuitRecord=LOD.EnemyPursuit:Capture(e,p)
        a.pursuitRecord.snapshot=Vector(p:GetPos().x,p:GetPos().y,p:GetPos().z)
    end
    if d.kind=="arc" then a.aim=Vector(p:GetPos().x,p:GetPos().y,p:GetPos().z+3) end
    if d.kind=="pulse" then a.aim=Vector(origin.x,origin.y,e:GetPos().z+3);a.event.pushOrigin=origin end
    if d.kind=="beam" then
        a.origin=e:GetPos()+Vector(0,0,56);a.yaw=e.LODRosterYaw or e:GetAngles().y;a.previous=-45
        a.aim=a.origin+Angle(0,a.yaw,0):Forward()*cfg.fireRange
    end
    if e.LODSkeletonHero then a.skeletonContent=e.LODSkeletonPendingContent end
    e.LODRosterAttack=a
    if a.spacingFallback then
        e:SetNW2Int("LOD_SpacingMode",0);e:SetNW2Float("LOD_SpacingReady",a.ready);e:SetNW2Float("LOD_SpacingUntil",a.deadline)
    end
    e:SetNW2Int("LOD_RosterAttack",1);e:SetNW2Vector("LOD_RosterOrigin",a.origin)
    e:SetNW2Vector("LOD_RosterAim",a.aim);e:SetNW2Float("LOD_RosterReady",a.ready)
    e:SetNW2Float("LOD_RosterRange",a.range)
    if a.spacingFallback and (e.LODRosterAttack~=a or not self:ValidLife(a.life)) then return end
    e:EmitSound(sounds[a.kind] or "npc/fast_zombie/leap1.wav",72,100,.75)
    if not a.spacingFallback or (e.LODRosterAttack==a and self:ValidLife(a.life)) then e:_SetActivity(ACT_RANGE_ATTACK1 or ACT_IDLE,true) end
end
function E:Finish(e,now)
    local attack=e.LODRosterAttack
    self:Cancel(e)
    if attack and (attack.melee or attack.tactical or attack.mobile or attack.perception or attack.condition or attack.spacing or attack.spacingFallback or attack.resource or attack.crossfire) then
        e.LODMeleeRecovery={life=attack.life,expires=attack.recoveryUntil or now+self.Definitions[e.LODArchetypeId].recovery}
        e.LODNextAttack=e.LODMeleeRecovery.expires
        LOD.HostileMotionV2:Stop(e);e:_SetActivity(ACT_IDLE)
        return
    end
    local rate=LOD.RPGAbilityRules and LOD.RPGAbilityRules:RateOfFireMultiplier(e) or 1
    e.LODNextAttack=now+e.LODConfig.burstCooldown/math.max(.1,rate)
    e:_SetActivity(ACT_IDLE)
    if attack and LOD.EnemyReactions then LOD.EnemyReactions:AfterAttack(e,attack,now) end
    if attack and LOD.EnemyPursuit then LOD.EnemyPursuit:AfterAttack(e,attack,now) end
end
function E:Release(e,a,now)
    if a.fallbackLife and (not self:ValidLife(a.fallbackLife) or now>a.deadline) then return false end
    if a.patternLife and (not self:ValidLife(a.patternLife) or now>a.deadline) then return false end
    if a.reactionRecord and not LOD.EnemyReactions:ValidAttack(a.reactionRecord) then return false end
    if a.pursuitRecord and not LOD.EnemyPursuit:ValidCharge(a.pursuitRecord) then return false end
    if a.released or (e.LODSkeletonHero and a.skeletonCommitting) then return false end
    if e.LODSkeletonHero and not LOD.SkeletonHero:CommitArc(e,a) then
        if IsValid(e) and e.LODRosterAttack==a then self:Finish(e,now) end
        return false
    end
    a.released=true;a.finish=now+(a.kind=="beam" and 1.2 or (a.kind=="flame" and .8 or (a.kind=="dive" and .65 or .15)))
    a.last=now;e:SetNW2Int("LOD_RosterAttack",2);e:SetNW2Float("LOD_RosterRelease",now)
    e:SetNW2Float("LOD_RosterFinish",a.finish)
    -- Release is finite: an emitted looping flame asset outlives this attack.
    e:EmitSound(a.kind=="flame" and "ambient/fire/ignite.wav" or (a.kind=="venom" and "npc/barnacle/barnacle_digesting1.wav" or "ambient/energy/weld2.wav"),74,100,.7)
    if a.spacingFallback and (e.LODRosterAttack~=a or not self:ValidLife(a.life)) then return false end
    if a.pattern then
        self:ReleasePattern(e,a,now)
    elseif a.kind=="bullet" or a.kind=="venom" or a.kind=="bolt" then
        if #self.Projectiles<64 then
            local speed=a.kind=="bullet" and 950 or (a.kind=="bolt" and 540 or 380)
            local q={owner=e,pos=a.origin,velocity=a.direction*speed,
                expires=now+(a.range or e.LODConfig.fireRange)/speed,kind=a.kind,event=a.event}
            -- Preserve the commitment's scope, never bind a stale release to a new run.
            for _,k in ipairs({"seed","run","graph","progression","epoch","campaignSeed","runId"}) do q[k]=a[k] end
            q.reactionRecord=a.reactionRecord
            q.pursuitRecord=a.pursuitRecord
            q.fallbackLife=a.fallbackLife
            q.spacingFallback=a.spacingFallback
            self.Projectiles[#self.Projectiles+1]=q
            a.shotEmitted=true
        end
    end
end
function E:Attack(e,a,now)
    if a.resource then return self:StepResource(e,a,now) end
    if a.fallbackLife and (not self:ValidLife(a.fallbackLife) or not a.released and now>a.deadline) then self:Finish(e,now);return end
    if a.crossfire then return self:StepCrossfire(e,a,now) end
    if a.spacing then return self:StepSpacing(e,a,now) end
    if a.spacingFallback and not a.released and not self:SpacingFallbackValid(e,a,now) then self:Finish(e,now);return end
    if a.condition then return self:StepCondition(e,a,now) end
    if a.perception then return self:StepPerception(e,a,now) end
    if a.mobile then return self:StepMobile(e,a,now) end
    if a.tactical then return self:StepTactical(e,a,now) end
    if a.melee then return self:StepMelee(e,a,now) end
    if a.trap then return self:StepTrap(e,a,now) end
    if a.patternLife and (not self:ValidLife(a.patternLife) or not a.released and now>a.deadline) then self:Finish(e,now);return end
    if a.reactionRecord and not LOD.EnemyReactions:ValidAttack(a.reactionRecord) then self:Finish(e,now);return end
    if a.pursuitRecord and not (a.released and LOD.EnemyPursuit:ValidLife(a.pursuitRecord)
        or not a.released and LOD.EnemyPursuit:ValidCharge(a.pursuitRecord)) then self:Finish(e,now);return end
    if not a.released then
        if not self:AcquireTarget(a.target) or not self:Visible(e,a.target,a.origin)
            or not self:CanCast(e) then self:Finish(e,now);return end
        if now<a.ready then return end
        self:Release(e,a,now)
        if a.spacingFallback and (e.LODRosterAttack~=a or not self:ValidSourceLife(a.life)) then return end
        if not a.released then return end
    end
    local kind=a.kind;local range=a.range or e.LODConfig.fireRange
    if kind=="dive" then
        local dt=math.Clamp(now-a.last,0,.05);a.last=now
        local origin=e:GetPos();local dir=Vector(a.direction.x,a.direction.y,0):GetNormalized()
        local goal=origin+dir*780*dt
        if not self:LegalStep(e,origin,goal) then self:Finish(e,now);return end
        local tr=util.TraceHull({start=origin,endpos=goal,mins=Vector(-16,-16,2),maxs=Vector(16,16,64),mask=MASK_NPCSOLID,
            filter=function(v) return v~=e and not v.LODHostile and not v:IsPlayer() end})
        if tr.Hit or tr.StartSolid then self:Finish(e,now);return end
        e:SetPos(goal);e.LODMotionVelocity=dir*780;e.LODMotionSpeed=780
        for _,p in ipairs(player.GetAll()) do
            if self:Target(p) and not a.hit[p] and util.DistanceToLine(origin,goal,p:GetPos())<=48 and self:Visible(e,p) then
                a.hit[p]=true;self:Damage(e,p,a.event,kind)
            end
        end
    elseif kind=="flame" or kind=="arc" or kind=="beam" or kind=="pulse" then
        local current=kind=="beam" and math.Clamp((now-(a.finish-1.2))/1.2,0,1)*90-45 or 0
        for _,p in ipairs(player.GetAll()) do
            if self:Target(p) and not a.hit[p] then
                local pos=p:WorldSpaceCenter();local delta=pos-a.origin;local inside=false
                if kind=="flame" then inside=delta:Length()<=range and delta:GetNormalized():Dot(a.direction)>=math.cos(math.rad(28))
                elseif kind=="arc" then inside=(pos-a.aim):Length2D()<=112 and pos.z>=a.aim.z-3 and pos.z<=a.aim.z+192
                elseif kind=="pulse" then inside=delta:Length()<=range
                else
                    local yaw=math.AngleDifference(delta:Angle().y,a.yaw)
                    local lo,hi=p:WorldSpaceAABB()
                    inside=delta:Length2D()<=range and lo.z<=a.origin.z+3 and hi.z>=a.origin.z-3
                        and yaw>=a.previous-1 and yaw<=current+1
                end
                local source=kind=="arc" and a.aim+Vector(0,0,24) or a.origin
                if inside and self:Visible(e,p,source) then a.hit[p]=true;self:Damage(e,p,a.event,kind) end
            end
        end
        if kind=="beam" then a.previous=current end
    end
    if now>=a.finish then self:Finish(e,now) end
end
function E:LegalStep(e,from,to)
    local s=state();local graph=s and s.Graph
    local a=graph and N:WorldToCell(graph,from);local b=graph and N:WorldToCell(graph,to)
    if self:Safe(graph,a) or self:Safe(graph,b) or a.z~=b.z then return false end
    return key(a)==key(b) or (a.neighbors[key(b)] and N:CanTraverse(graph,key(a),key(b)))
end
function E:Tick(e)
    -- This shared dispatch also sees non-roster Fighter/Rogue skeletons before
    -- ordinary melee/Soldier execution. Late native method binding cannot erase
    -- the exact-event guard by replacing an instance method.
    if e.LODSkeletonHero and not LOD.SkeletonHero:Live(e) then
        e.LODSoldierBurst=nil;self:Cancel(e);LOD.HostileMotionV2:Stop(e);return true
    end
    local d=self.Definitions[e.LODArchetypeId];if not d then return false end
    local s=state();local motion=LOD.HostileMotionV2;local now=CurTime()
    if e.LODDead or not e.LODActivated or not s or not s.BuildReady or s.Failed or s.LevelCleared or s.SimulationFrozen then
        self:Cancel(e);if LOD.EnemyReactions then LOD.EnemyReactions:Cancel(e,true) end;if LOD.EnemySupport then LOD.EnemySupport:Cancel(e) end;if LOD.EnemyPursuit then LOD.EnemyPursuit:Cancel(e) end;if e.LODClimberVictim and LOD.Climber then LOD.Climber:Detach(e) end;motion:Stop(e);return true
    end
    self:Prepare(e)
    if not self:Live(e.LODRosterContext,s) then self:Cancel(e);if LOD.EnemyReactions then LOD.EnemyReactions:Cancel(e,true) end;if LOD.EnemySupport then LOD.EnemySupport:Cancel(e) end;if LOD.EnemyPursuit then LOD.EnemyPursuit:Cancel(e) end;motion:Stop(e);return true end
    if LOD.EnemyRemains and LOD.EnemyRemains.Pending[e] then motion:Stop(e);return true end
    if e.LODMeleeRecovery then
        local recovery=e.LODMeleeRecovery
        if self:ValidSourceLife(recovery.life) and now<recovery.expires then
            motion:Stop(e);e:_SetActivity(ACT_IDLE);return true
        end
        e.LODMeleeRecovery=nil
    end
    if d.reaction and LOD.EnemyReactions and LOD.EnemyReactions:Tick(e,now) then return true end
    if d.support and LOD.EnemySupport and LOD.EnemySupport:Tick(e,now) then motion:Stop(e);return true end
    if d.kind=="climber" then return LOD.Climber:Tick(e,s,now) end
    if d.kind=="gas" then
        motion:Stop(e);e:_SetActivity(ACT_IDLE)
        if now>=(e.LODNextGas or 0) then
            e.LODNextGas=now+1
            local cell=N:WorldToCell(s.Graph,e:GetPos());local event={}
            for _,p in ipairs(player.GetAll()) do
                if self:Target(p) and key(N:WorldToCell(s.Graph,p:GetPos()))==key(cell) then self:Damage(e,p,event,"gas") end
            end
        end
        return true
    end
    local a=e.LODRosterAttack
    if a then motion:Stop(e);return true end -- shared service owns attacks, even committed sweeps during stun
    if d.perception and (now<(e.LODHitStunUntil or 0) or not self:CanCast(e) or not LOD.RPGStatusElements:CanMoveVoluntarily(e)) then
        self:Cancel(e)
        -- Perception retirement must not consume canonical morale locomotion.
        if not LOD.RPGStatusElements:Has(e,"morale_flee") then motion:Stop(e);return true end
    end
    if motion:HoldHitStun(e,now) then return true end
    local statuses=LOD.RPGStatusElements
    if d.stationary then
        motion:Stop(e)
        if not statuses:CanInitiateAttack(e) or statuses:Has(e,"morale_flee") then return true end
    elseif statuses:HandleAIFlee(e,s.Graph,motion) then return true end
    if d.perception then return self:TickPerception(e,now) end
    if not e.LODPursuit then e:_RefreshTarget(s.Graph) end
    local p=e.LODTarget
    if d.pursuit and LOD.EnemyPursuit and LOD.EnemyPursuit:Tick(e,p,now) then return true end
    if d.pursuit and (not self:AcquireTarget(p) or not self:Visible(e,p)) then
        e.LODTarget=nil;motion:Stop(e);e:_SetActivity(ACT_IDLE);return true
    end
    local can=self:AcquireTarget(p) and self:CanCast(e)
        and self:Origin(e):DistToSqr(p:WorldSpaceCenter())<=(d.kind=="beam" and EC.Archetypes.beamsweeper.fireRange or e.LODConfig.fireRange)^2 and self:Visible(e,p,self:Origin(e))
    if can and d.kind=="beam" and now>=(e.LODNextAttack or 0) then
        local direction=p:GetPos()-e:GetPos();direction.z=0
        local yaw=direction:Angle().y
        local origin=e:GetPos()+Vector(0,0,56)
        local range=EC.Archetypes.beamsweeper.fireRange
        for offset=-45,45,15 do
            local tr=util.TraceLine({start=origin,endpos=origin+Angle(0,yaw+offset,0):Forward()*range,mask=MASK_SOLID,
                filter=function(v) return v~=e and not v.LODHostile and not v:IsPlayer() end})
            if tr.Hit then range=math.min(range,origin:Distance(tr.HitPos)-8) end
        end
        if range>=120 then e.LODRosterYaw=yaw;e.LODConfig.fireRange=range;motion:FaceToward(e,p:GetPos()) end
    end
    if can and (d.kind=="bullet" or d.kind=="beam") and not d.support and not d.pursuit and not d.reaction and not d.pattern and not d.trap and not d.tactical and not d.mobile and not d.condition and not d.crossfire then
        local direction=(p:GetPos()-e:GetPos()):GetNormalized()
        can=direction:Dot(Angle(0,e.LODRosterYaw or 0,0):Forward())>=math.cos(math.rad(d.kind=="beam" and 45 or 55))
    end
    -- Arc Casters advance between commitments. Previously merely seeing a target
    -- inside the very long cast range held them still for the entire cooldown.
    local reposition=(d.crossfire and now<(e.LODCrossfireAdvanceUntil or 0)) or (d.resource and now<(e.LODResourceAdvanceUntil or 0)) or (d.spacing and now<(e.LODSpacingAdvanceUntil or 0)) or (d.condition and now<(e.LODConditionAdvanceUntil or 0)) or (d.mobile and now<(e.LODMobileAdvanceUntil or 0)) or (d.tactical and now<(e.LODTacticalAdvanceUntil or 0)) or (d.melee and now<(e.LODMeleeAdvanceUntil or 0)) or (d.trap and now<(e.LODTrapAdvanceUntil or 0)) or (d.kind=="arc" and not d.trap and now<(e.LODNextAttack or 0)
        and self:Target(p) and e:GetPos():DistToSqr(p:GetPos())>240^2)
    if can and not reposition then
        motion:Stop(e)
        if not d.stationary then motion:FaceToward(e,p:GetPos()) end
        if now>=(e.LODNextAttack or 0) then self:Begin(e,p,now) end
    elseif not d.stationary then
        e:_RefreshRoute(s.Graph);local wp=e:_AdvanceWaypoint()
        if wp then motion:MoveToward(e,wp) else motion:Stop(e);e:_SetActivity(ACT_IDLE) end
    end
    return true
end
-- One bounded projectile/attack service, independent of outer AI stun wrappers.
hook.Add("Think","LOD_EnemyRosterAttacks",function()
    local s=state();local now=CurTime()
    if now<(E.NextService or 0) then return end
    local dt=math.Clamp(now-(E.LastService or now),0,.05);E.LastService=now;E.NextService=now+.025
    local active=s and s.BuildReady and not s.Failed and not s.LevelCleared and not s.SimulationFrozen
    if E.ServiceTactical then E:ServiceTactical() end
    if LOD.EnemyRemains then LOD.EnemyRemains:Service(now,active) end
    if LOD.EnemyReactions then LOD.EnemyReactions:Service(now,active) end
    if LOD.EnemySupport then LOD.EnemySupport:Service(now,active) end
    if LOD.EnemyPursuit then LOD.EnemyPursuit:Service(now,active) end
    for e in pairs(E.Active) do
        if not IsValid(e) then E.Active[e]=nil
        elseif e.LODDead then E:Cancel(e);E.Active[e]=nil
        elseif not active then E:Cancel(e)
        elseif e.LODRosterAttack then
            local a=e.LODRosterAttack
            if not E:Live(a,s) or (a.pursuitRecord and not LOD.EnemyPursuit:ValidLife(a.pursuitRecord)) then E:Cancel(e)
            elseif not (a.released and a.kind=="beam") and (now<(e.LODHitStunUntil or 0) or not E:CanCast(e)) then E:Finish(e,now)
            else E:Attack(e,a,now) end
        end
    end
    local kept={}
    for _,q in ipairs(E.Projectiles) do
        if active and E:Live(q,s) and IsValid(q.owner) and not q.owner.LODDead and now<q.expires
            and (not q.reactionRecord or LOD.EnemyReactions:ValidLife(q.reactionRecord))
            and (not q.pursuitRecord or LOD.EnemyPursuit:ValidLife(q.pursuitRecord))
            and (not q.fallbackLife or E:ValidLife(q.fallbackLife)) then
            if q.pattern then
                if E:ValidLife(q.patternLife) and E:StepPattern(q,now,dt) then kept[#kept+1]=q end
            else
            local finish=q.pos+q.velocity*dt
            local radius=(q.kind=="venom" or q.kind=="bolt") and 7 or 2
            local tr=util.TraceHull({start=q.pos,endpos=finish,mins=Vector(-radius,-radius,-radius),maxs=Vector(radius,radius,radius),mask=MASK_SOLID,
                filter=function(v) return v~=q.owner and not v.LODHostile end})
            if tr.Hit then
                if E:Target(tr.Entity) and (not q.spacingFallback or tr.Entity==q.fallbackLife.hero) then E:Damage(q.owner,tr.Entity,q.event,q.kind) end
                local fx=EffectData();fx:SetOrigin(tr.HitPos);util.Effect(q.kind=="venom" and "cball_explode" or "Sparks",fx,true,true)
            else q.pos=finish;kept[#kept+1]=q end
            end
        end
    end
    E.Projectiles=kept
    if active and (#kept>0 or E.HadProjectiles) and now>=(E.NextSync or 0) then
        E.HadProjectiles=#kept>0
        E.NextSync=now+.1;net.Start("LOD_RosterProjectiles");net.WriteUInt(#kept,7)
        for _,q in ipairs(kept) do net.WriteVector(q.pos);net.WriteVector(q.velocity);net.WriteUInt(q.pattern and 3 or (q.kind=="venom" and 1 or (q.kind=="bolt" and 2 or 0)),2) end
        net.Broadcast()
    end
end)
util.AddNetworkString("LOD_RosterProjectiles")

-- Register spatial pain/death/step cues in the existing audio authority.
if LOD.CombatAudio and LOD.CombatAudio.RegisterHostileProfile then
    local banks={
        outrider={"npc/antlion/pain1.wav","npc/antlion/die1.wav","npc/antlion/foot1.wav"},
        siphoner={"npc/stalker/stalker_pain1.wav","npc/stalker/stalker_die1.wav","npc/stalker/stalker_footstep_left.wav"},
        accumulator={"npc/vort/vort_pain1.wav","npc/vort/vort_die1.wav","npc/vort/vort_foot1.wav"},
        conductor={"npc/vort/vort_pain1.wav","npc/vort/vort_die1.wav","npc/vort/vort_foot1.wav"},
        absolver={"npc/vort/vort_pain1.wav","npc/vort/vort_die1.wav","npc/vort/vort_foot1.wav"},
        exactor={"npc/combine_soldier/pain1.wav","npc/combine_soldier/die1.wav","npc/combine_soldier/gear1.wav"},
        listener={"npc/metropolice/pain1.wav","npc/metropolice/die1.wav","npc/metropolice/gear1.wav"},
        shy={"npc/fast_zombie/leap1.wav","npc/fast_zombie/fz_scream1.wav","npc/fast_zombie/foot1.wav"},
        censer={"npc/combine_soldier/pain1.wav","npc/combine_soldier/die1.wav","npc/combine_soldier/gear1.wav"},
        trailmaker={"npc/metropolice/pain1.wav","npc/metropolice/die1.wav","npc/metropolice/gear1.wav"},
        towline={"npc/metropolice/pain1.wav","npc/metropolice/die1.wav","npc/metropolice/gear1.wav"},
        screenwright={"npc/combine_soldier/pain1.wav","npc/combine_soldier/die1.wav","npc/combine_soldier/gear1.wav"},
        afterburst={"npc/zombie/zombie_pain1.wav","npc/zombie/zombie_die2.wav","npc/zombie/foot1.wav"},
        carrion={"npc/fast_zombie/wake1.wav","npc/fast_zombie/fz_scream1.wav","npc/fast_zombie/foot1.wav"},
        reaper={"npc/zombie/zombie_pain1.wav","npc/zombie/zombie_die1.wav","npc/zombie/foot1.wav"},
        drubber={"npc/fast_zombie/fz_pain1.wav","npc/fast_zombie/fz_die1.wav","npc/fast_zombie/foot1.wav"},
        fencer={"npc/metropolice/pain1.wav","npc/metropolice/die1.wav","npc/metropolice/gear1.wav"},
        climber={"npc/fast_zombie/fz_pain1.wav","npc/fast_zombie/fz_die1.wav","npc/fast_zombie/foot1.wav"},
        flamer={"npc/combine_soldier/pain2.wav","npc/combine_soldier/die2.wav","npc/combine_soldier/gear2.wav"},
        bigcrab={"npc/headcrab/pain1.wav","npc/headcrab/die1.wav","npc/headcrab/alert1.wav"},
        sentry={"npc/turret_floor/ping.wav","npc/turret_floor/die.wav"},
        razor={"npc/manhack/grind1.wav","npc/manhack/gib.wav","npc/manhack/mh_engine_start1.wav"},
        arccaster={"npc/vort/vort_pain1.wav","npc/vort/vort_die1.wav","npc/vort/vort_foot1.wav"},
        nodule={"npc/barnacle/barnacle_tongue_pull1.wav","npc/barnacle/barnacle_die1.wav"},
        lurker={"npc/barnacle/barnacle_tongue_pull1.wav","npc/barnacle/barnacle_die1.wav"},
        beamsweeper={"npc/stalker/stalker_pain1.wav","npc/stalker/stalker_die1.wav"},
        gaoler={"npc/vort/vort_pain1.wav","npc/vort/vort_die1.wav","npc/vort/vort_foot1.wav"},
        silencer={"npc/combine_soldier/pain2.wav","npc/combine_soldier/die2.wav","npc/combine_soldier/gear2.wav"},
        repulsor={"npc/vort/vort_pain1.wav","npc/vort/vort_die1.wav","npc/vort/vort_foot1.wav"},
        stitcher={"npc/vort/vort_pain1.wav","npc/vort/vort_die1.wav","npc/vort/vort_foot1.wav"},
        bulwark={"npc/combine_soldier/pain2.wav","npc/combine_soldier/die2.wav","npc/combine_soldier/gear2.wav"},
        cantor={"npc/metropolice/pain1.wav","npc/metropolice/die1.wav","npc/metropolice/gear1.wav"},
        pincer={"npc/combine_soldier/pain2.wav","npc/combine_soldier/die2.wav","npc/combine_soldier/gear2.wav"},
        harrier={"npc/metropolice/pain1.wav","npc/metropolice/die1.wav","npc/metropolice/gear1.wav"},
        pavise={"npc/combine_soldier/pain2.wav","npc/combine_soldier/die2.wav","npc/combine_soldier/gear2.wav"},
        repriser={"npc/metropolice/pain1.wav","npc/metropolice/die1.wav","npc/metropolice/gear1.wav"},
        redliner={"npc/combine_soldier/pain2.wav","npc/combine_soldier/die2.wav","npc/combine_soldier/gear2.wav"},
        wirewright={"npc/combine_soldier/pain2.wav","npc/combine_soldier/die2.wav","npc/combine_soldier/gear2.wav"},
        snarer={"npc/vort/vort_pain1.wav","npc/vort/vort_die1.wav","npc/vort/vort_foot1.wav"},
        cordon={"npc/turret_floor/ping.wav","npc/turret_floor/die.wav"},
        caromer={"npc/combine_soldier/pain2.wav","npc/combine_soldier/die2.wav","npc/combine_soldier/gear2.wav"},
        reeler={"npc/metropolice/pain1.wav","npc/metropolice/die1.wav","npc/metropolice/gear1.wav"},
        forker={"npc/combine_soldier/pain2.wav","npc/combine_soldier/die2.wav","npc/combine_soldier/gear2.wav"},
        waylayer={"npc/combine_soldier/pain2.wav","npc/combine_soldier/die2.wav","npc/combine_soldier/gear2.wav"}
    }
    for id,b in pairs(banks) do LOD.CombatAudio:RegisterHostileProfile(id,{pain={b[1]},death={b[2]},
        footsteps=b[3] and {b[3]} or {},footDistance=60,footInterval=.5,footVolume=.5,footPitch=100,activation={b[1]}}) end
end
function E:CombatBounds(e)
    local pos=e:GetPos();local size=math.Clamp(e:GetNW2Float("LOD_SizeScale",1),.33,1.33)
    local id=e.LODArchetypeId
    if id=="nodule" and LOD.HostileShapes then
        local lo,hi=LOD.HostileShapes:NoduleBounds(e)
        return pos+lo,pos+hi
    end
    if id=="climber" then return pos+Vector(-14,-14,-8),pos+Vector(14,14,38*size) end
    if id=="lurker" then return pos+Vector(-18,-18,-64*size),pos+Vector(18,18,0) end
    if id=="bigcrab" then local scale=2.4+size-.33;return pos+Vector(-18*scale,-18*scale,0),pos+Vector(18*scale,18*scale,24*scale) end
    if id=="razor" then return pos+Vector(-14,-14,42),pos+Vector(14,14,68) end
end
hook.Add("ShouldCollide","LOD_ClimberLatchNoPush",function(a,b)
    if IsValid(a) and IsValid(b) and (a.LODClimberVictim==b or b.LODClimberVictim==a
        or (a.LODArchetypeId=="lurker" and b:IsPlayer()) or (b.LODArchetypeId=="lurker" and a:IsPlayer())) then return false end
end)

hook.Add("OnNPCKilled","LOD_RosterDeath",function(e)
    if IsValid(e) and E.Definitions[e.LODArchetypeId] then
        E:Cancel(e);e:SetNW2Bool("LOD_RosterAlive",false)
        if e.LODClimberVictim then LOD.Climber:Detach(e) end
    end
end)
