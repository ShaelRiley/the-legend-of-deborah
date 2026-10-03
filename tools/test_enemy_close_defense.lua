-- Real EnemyRoster service, actor dice/defenses and native coroutine dispatch;
-- only Source entity, trace, animation and HP-write boundaries are doubled.
local H=dofile('tools/test_bestiary_b7.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local E,Status,Rolls=LOD.EnemyRoster,LOD.RPGStatusElements,LOD.CombatRolls
local noop=function() end
ACT_IDLE=ACT_IDLE or 4;ACT_MELEE_ATTACK1=21
dofile(root..'sv_watcher.lua');dofile(root..'sv_seeker.lua');dofile(root..'sv_deadcrab.lua')
dofile(root..'sv_enemy_crossfire.lua')
local function read(path) local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local cls={}
local source=read('gamemodes/legend_of_deborah/entities/entities/lod_hostile/init.lua')
assert(load('local ENT=...\n'..assert(source:match('(function ENT:RunBehaviour%(%)%s.-\nend)')),'@native-hostile-loop'))(cls)
local now=1000
local function at(t) now=t;H.at(t) end
local function setup(id)
    H.reset();at(now+10)
    local e=H.actor(id);e:SetPos(H.center()+Vector(0,0,2));e.LODTarget=H.hero
    e.LODNextAttack=0;e.LODNextHitStun=0;e.LODHitStunUntil=nil
    e.SetVelocity=noop;e.SetAngles=noop
    e._BehaviourTick=function(self) self.ordinaryTicks=(self.ordinaryTicks or 0)+1 end
    e._SetActivity=function(self,act) self.animation=act end
    H.hero:SetPos(e:GetPos()+Vector(72,0,0));H.hero.hits=0
    H.hero.LODProgressionState.classId='fighter';H.hero.LODProgressionState.derivedStats={}
    H.hero.LODProgressionState.featIds={};H.hero.LODProgressionState.equipmentBlockChanceContribution=0
    local co=coroutine.create(function() cls.RunBehaviour(e) end)
    return e,co
end
local function tick(co)
    local ok,err=coroutine.resume(co);assert(ok,err)
end
local function release(e)
    local a=assert(e.LODRosterAttack,'close enemy never committed a counterattack')
    H.service(a.ready+.025);now=a.ready+.025
    assert(not e.LODRosterAttack,'counterattack did not finish')
    return a
end
-- The native dispatcher must reach ranged/support/rare variants before a
-- specialized behavior wrapper consumes the frame, even during primary reload.
local count=0
for id in pairs(LOD.Config.Encounter.Archetypes) do
    if id~='shambler' and id~='runner' then
        local e,co=setup(id);e.LODNextAttack=now+99
        tick(co)
        assert(e.LODRosterAttack and e.LODRosterAttack.closeDefense,id..' walked into Hero without attacking')
        assert(e.animation==ACT_MELEE_ATTACK1 and e.nw.LOD_MeleeMode==5,id..' missing attack tell')
        local before=H.hero:Health();release(e)
        assert(H.hero.hits==1 and H.hero:Health()<before,id..' failed real physical damage settlement')
        H.service(now+.025);assert(H.hero.hits==1,'duplicate release '..id)
        tick(co);assert(not e.LODRosterAttack,'recovery skipped '..id)
        count=count+1
    end
end
assert(count==61,'all 63 normal identities (including the two ordinary melee types) must be represented')

-- Continuous crowbar pressure: native HP damage is independent of whether its
-- late melee-flinch request is admitted. Use the actual shared flinch authority.
for _,id in ipairs({'arccaster','repriser','shy','sentry','bioblaster','sniper'}) do
    local e,co=setup(id);local start=now;local flinches=0;local hp=e:Health()
    for i=0,120 do
        at(start+i*.025)
        if i%10==0 then
            local event={}
            e:SetHealth(e:Health()-.1)
            LOD.EnemyReactions:ObserveHit(e,H.hero,{attackEvent=event,physical=true,melee=true},.1,now)
            if LOD.M3HitFeedback:ApplyHitStun(e,1,H.hero,nil,'melee',event) then flinches=flinches+1 end
        end
        tick(co);H.service(now)
    end
    assert(H.hero.hits>=1,id..' can be crowbar stun-locked without retaliation')
    assert(flinches==2 and e:Health()<hp,id..' changed HP damage or melee-stagger boundary')
end

for _,status in ipairs({'held','muted','intimidated','morale_flee'}) do
    local e,co=setup('gaoler')
    if status=='morale_flee' then
        assert(Status:AttemptMorale(H.hero,e,{forceMorale=true,rng={Int=function(_,lo) return lo end}}))
    else assert(Status:Apply(e,status,H.hero,{direct=true,duration=5}),status) end
    tick(co)
    if status=='held' or status=='muted' then
        assert(e.LODRosterAttack,status..' incorrectly forbids stationary physical defense')
        local seen
        local original=H.hero.TakeDamageInfo
        H.hero.TakeDamageInfo=function(self,info) seen=Status:DamageContext(info,self);return original(self,info) end
        release(e);H.hero.TakeDamageInfo=original
        assert(H.hero.hits==1 and seen.physical and seen.melee and not seen.magic and not seen.riderStatusId,'fallback inherited Magic/status content')
    else assert(not e.LODRosterAttack,status..' bypassed attack prohibition') end
end

for _,case in ipairs({'cover','startsolid','range','sidestep','source drift','target life','source life',
    'target profile','source profile','new graph','new run','freeze','death','late tick','invisible','faction','stun'}) do
    local e,co=setup('arccaster');tick(co);local a=assert(e.LODRosterAttack)
    local factions=LOD.FactionManager;local savedDamage=factions.CanDamage
    if case=='cover' then util.TraceLine=function(t) return {Hit=true,Entity=NULL,HitPos=t.endpos} end
    elseif case=='startsolid' then util.TraceLine=function(t) return {Hit=false,StartSolid=true,HitPos=t.endpos} end
    elseif case=='range' then H.hero:SetPos(e:GetPos()+Vector(160,0,0))
    elseif case=='sidestep' then H.hero:SetPos(e:GetPos()+Vector(0,72,0))
    elseif case=='source drift' then e:SetPos(e:GetPos()+Vector(5,0,0))
    elseif case=='target life' then Status:ResetActorLife(H.hero)
    elseif case=='source life' then Status:ResetActorLife(e)
    elseif case=='target profile' then H.hero.LODProgressionState=table.Copy(H.hero.LODProgressionState)
    elseif case=='source profile' then e.LODProgressionState=table.Copy(e.LODProgressionState)
    elseif case=='new graph' then H.state.Graph=table.Copy(H.state.Graph)
    elseif case=='new run' then LOD.RunManager.State=table.Copy(H.state)
    elseif case=='freeze' then H.state.SimulationFrozen=true
    elseif case=='death' then e.LODDead=true
    elseif case=='invisible' then H.hero.LODRPGInvisibleUntil=now+5;LOD.RPGPerceptionState={IsInvisible=function(_,p) return p==H.hero end}
    elseif case=='faction' then factions.CanDamage=function()return false end
    elseif case=='stun' then e.LODHitStunUntil=a.ready+2 end
    H.service(case=='late tick' and a.expires+.01 or a.ready+.025)
    assert(H.hero.hits==0 and not e.LODRosterAttack,'unsafe release: '..case)
    factions.CanDamage=savedDamage;LOD.RPGPerceptionState=nil;H.hero.LODRPGInvisibleUntil=nil
end

-- A short legal strike does not require both feet to occupy the same grid cell.
do
    local e,co=setup('fencer');local cell=H.state.Graph.Cells['3:3:0']
    local edge=LOD.MazeNavigator:CellCenter(cell)+Vector(LOD.Config.Maze.CellSize*.5-24,0,2)
    e:SetPos(edge);H.hero:SetPos(edge+Vector(72,0,0))
    assert(LOD.MazeNavigator:WorldToCell(H.state.Graph,e:GetPos())~=LOD.MazeNavigator:WorldToCell(H.state.Graph,H.hero:GetPos()))
    tick(co);release(e);assert(H.hero.hits==1,'open grid seam silently disarmed melee')
end

-- One callback cannot replay the hit; a replacement life during dice/defense
-- callbacks cannot receive it. Exercise both pre-packet and native admission.
do
    local e,co=setup('stitcher');tick(co);local a=e.LODRosterAttack
    local old=H.hero.TakeDamageInfo
    H.hero.TakeDamageInfo=function(self,info) E:StepCloseDefense(e,a,CurTime());return old(self,info) end
    release(e);H.hero.TakeDamageInfo=old;assert(H.hero.hits==1,'reentrant impact')
    e,co=setup('silencer');tick(co)
    local resolve=Rolls.ResolveActorDamage
    Rolls.ResolveActorDamage=function(self,...)
        local result=resolve(self,...);Status:ResetActorLife(H.hero);return result
    end
    release(e);Rolls.ResolveActorDamage=resolve;assert(H.hero.hits==0,'dice callback replaced target life')
end
-- Arrival and special ownership gates remain authoritative before the fallback.
do
    local e,co=setup('sentry')
    LOD.EntrySafety={BeforeAI=function()return true end}
    tick(co);assert(not e.LODRosterAttack and not e.ordinaryTicks,'arrival sanctuary bypassed')
    LOD.EntrySafety=nil
    e.LODSkeletonHero=true;LOD.SkeletonHero={Live=function() return false end}
    tick(co);assert(not e.LODRosterAttack,'stale/rising skeleton attacked')
    LOD.SkeletonHero=nil;e.LODSkeletonHero=nil
    e.LODWardenTurret={};LOD.WardenTurrets={Ready=function()return nil end}
    tick(co);assert(not e.LODRosterAttack,'retired turret attacked')
    LOD.WardenTurrets=nil
end
-- Already warned primary attacks and attached bites retain their controller.
for _,field in ipairs({'LODRosterAttack','LODSoldierBurst','LODSniperShot','LODBioBlast','LODBruteCharge','LODBruteAttack','LODClimberVictim','LODWatcherScan','LODSeekerState'}) do
    local e,co=setup('sniper');local pending={};e[field]=pending
    tick(co);assert(e[field]==pending and e.ordinaryTicks==1,'preempted active primary '..field)
end
-- Named actors use their existing ownership/reveal boundaries. The retained
-- boss suites separately exercise those full encounter controllers.
for _,id in ipairs({'warden','hector','neil','brute'}) do
    local e,co=setup(id)
    tick(co);assert(not e.LODRosterAttack,'unowned named actor attacked: '..id)
    if id=='warden' then
        e.LODWardenOwner={actor=e,phase=1,phaseOne={stage='hidden'}}
        LOD.Warden={ActorOwner=function(_,w,actor) return w.actor==actor end,Protected=function() return false end}
        tick(co);assert(not e.LODRosterAttack,'cloaked Gordon attacked without showing warning')
        e.LODWardenOwner.phaseOne.stage='arrive';tick(co)
        assert(not e.LODRosterAttack,'Gordon attacked during arrival tell')
        e.LODWardenOwner.phaseOne.stage='attack'
    elseif id=='hector' then
        e.LODHectorEncounter={actor=e}
        LOD.Hector={Live=function(_,actor) return actor.LODHectorEncounter.actor==actor end,Hero=function()return true end}
    else H.state.NeilHunt={seed=H.state.LevelSeed};H.state.NeilHunt[id]=e end
    tick(co);release(e);assert(H.hero.hits==1,'owned named actor lacked close defense: '..id)
    LOD.Warden=nil;LOD.Hector=nil;H.state.NeilHunt=nil
end
print('ENEMY_CLOSE_DEFENSE_PASS '..count..' registered types; actual native dispatch/service/combat; repeated melee flinches; Held/Muted; fixed arc/cover/life/scope; reentrancy; no primary preemption')

-- The real Watcher instance router replaces ENT:RunBehaviour in production.
-- Exercise it with the actual close-defense commitment/damage service, rather
-- than assuming the generic coroutine above is the installed controller.
do
    local watcherTicks=0
    LOD.WatcherUnified={Stats={},BehaviourTick=function() watcherTicks=watcherTicks+1 end}
    LOD.WatcherScanEscapeHandoff=nil;LOD.WatcherUnifiedDispatch=nil
    local stored=scripted_ents.GetStored
    local find=ents.FindByClass;ents.FindByClass=function()return {} end
    scripted_ents.GetStored=function()return nil end
    dofile(root..'sv_watcher_instance_dispatch.lua')
    local e=setup('watcher');e.GetClass=function()return 'lod_hostile'end
    local co=coroutine.create(function()LOD.WatcherUnifiedDispatch.Router(e)end)
    tick(co);assert(e.LODRosterAttack and e.LODRosterAttack.closeDefense and watcherTicks==0,
        'actual Watcher router bypassed close defense')
    local before=e:GetPos();e.LODMotionLastUpdate=now-.05
    assert(not LOD.HostileMotionV2:MoveToward(e,{pos=before+Vector(100,0,0)}) and e:GetPos()==before,
        'independent retreat moved Watcher during its close warning')
    release(e);assert(H.hero.hits==1,'actual Watcher route failed shared physical impact')
    tick(co);assert(watcherTicks==1,'Watcher controller did not resume during recovery')
    at(now+3);e.LODWatcherScan={target=H.hero}
    tick(co);assert(not e.LODRosterAttack and watcherTicks==2,'close defense stole committed Watcher scan')
    e.LODWatcherScan=nil
    LOD.EntrySafety={BeforeAI=function()return true end}
    tick(co);assert(not e.LODRosterAttack and watcherTicks==2,'Watcher router bypassed sanctuary')
    LOD.EntrySafety=nil;scripted_ents.GetStored=stored;ents.FindByClass=find
end
print('WATCHER_CLOSE_DISPATCH_PASS: actual instance router, native damage, stationary warning, recovery, retained scan, sanctuary')
