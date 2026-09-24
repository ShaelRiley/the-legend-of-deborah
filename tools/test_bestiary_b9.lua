-- B9 exercises tether/screen commitments through the real roster service, combat and status pipeline.
-- Native entities, collision traces, motion transport and networking are doubles.
local env=dofile('tools/test_enemy_update.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local noop=function() end
local v=getmetatable(Vector())
v.__div=function(a,b) return a*(1/b) end
v.__unm=function(a) return a*-1 end
function v:Dot(b) return self.x*b.x+self.y*b.y+self.z*b.z end
function v:Length2D() return math.sqrt(self.x*self.x+self.y*self.y) end
function v:Normalize() local n=self:GetNormalized();self.x,self.y,self.z=n.x,n.y,n.z end
local am={};am.__index=am
function Angle(p,y,r) return setmetatable({p=p or 0,y=y or 0,r=r or 0},am) end
function am:Forward() local y=math.rad(self.y);return Vector(math.cos(y),math.sin(y),0) end
function am:Right() local y=math.rad(self.y);return Vector(-math.sin(y),math.cos(y),0) end
function v:Angle() return Angle(0,math.deg(math.atan(self.y,self.x)),0) end
function math.AngleDifference(a,b) return (a-b+180)%360-180 end
function istable(x) return type(x)=='table' end
function isfunction(x) return type(x)=='function' end
function string.Trim(x) return x:match('^%s*(.-)%s*$') end
ACT_IDLE,ACT_RUN_AIM_RIFLE,ACT_IDLE_ANGRY_SMG1,ACT_RANGE_ATTACK1,ACT_FLY=4,5,6,7,8
MASK_SOLID=3;NULL={valid=false};DMG_ENERGYBEAM,DMG_BURN,DMG_POISON,DMG_SLASH=4,5,6,7
DMG_FALL,DMG_CRUSH,DMG_BUCKSHOT,DMG_CLUB=8,9,10,11
net.WriteUInt=noop;net.WriteVector=noop;net.WriteBool=noop;net.Broadcast=noop;net.Receive=noop
hook.Run=noop;timer.Create=noop;timer.Remove=noop
game={GetWorld=function() return NULL end}
function ErrorNoHalt(message) error(message) end
GM={};dofile(root..'sv_damage_info.lua')
dofile(root..'sh_rng.lua');dofile(root..'sh_rpg_schema.lua')
dofile(root..'sv_rpg_gate_b_catalog.lua');dofile(root..'sv_rpg_gate_c_catalog.lua')
dofile(root..'sh_die_logger.lua');dofile(root..'sv_combat_rolls.lua');dofile(root..'sv_combat_feed_semantics.lua');dofile(root..'sv_character_progression.lua')
dofile(root..'sv_rpg_gate_d.lua');dofile(root..'sv_rpg_status_elements.lua')
dofile(root..'sv_rpg_gate_e_feats.lua');dofile(root..'sv_rpg_gate_e_rate_of_fire.lua');dofile(root..'sv_rpg_dodge.lua')
dofile(root..'sh_equipment.lua');dofile(root..'sh_equipment_catalog.lua')
dofile(root..'sv_rpg_block.lua');dofile(root..'sv_loot_director.lua')
dofile(root..'sv_enemy_roster.lua');dofile(root..'sv_enemy_melee.lua');dofile(root..'sv_hostile_motion_v2.lua')
local E,D,C,Status,Rules=LOD.EnemyRoster,LOD.EncounterDirector,LOD.CharacterProgressionSystem,LOD.RPGStatusElements,LOD.RPGAbilityRules
local time,serial=200,100
local function at(n) time=n;env.setTime(n) end
at(time)
local s=LOD.RunManager.State
s.BuildReady=true;s.Failed=false;s.LevelCleared=false;s.SimulationFrozen=false;s.Level=8
s.CampaignEpoch=1;s.RunId='b7';s.CampaignSeed=77;s.LevelSeed=123
local clearTrace=function(t) return {Hit=false,HitPos=t.endpos} end
util.TraceLine=clearTrace;util.TraceHull=clearTrace
LOD.CombatRolls._Send=noop;LOD.CombatRolls.ReportEnemyHealth=noop
LOD.CombatRolls.EntityDisplayName=function(_,e) return e.LODArchetypeId end
local function actor(id,pos)
    local e=env.actor(1);serial=serial+1;e.index=serial;e.LODArchetypeId=id
    e:SetPos(LOD.MazeNavigator:CellCenter(s.Graph.Cells['3:1:0'])+(pos or Vector()))
    e.LODConfig=table.Copy(LOD.Config.Encounter.Archetypes[id] or LOD.Config.Encounter.Archetypes.runner)
    e.health=e.LODConfig.baseHP;e.maximum=e.health
    e.SetNW2Int=e.SetNW2Bool;e.SetNW2Float=e.SetNW2Bool;e.SetNW2String=e.SetNW2Bool
    e.SetNW2Entity=e.SetNW2Bool
    e.SetColor=noop;e.SetModelScale=noop;e.GetAngles=function() return Angle() end
    e.GetNW2Float=function(self,k,default) return self.nw[k] or default end
    e.GetNW2Int=e.GetNW2Float;e.GetNW2Vector=e.GetNW2Float
    e.Health=function(self) return self.health end;e.GetMaxHealth=function(self) return self.maximum end
    e.SetHealth=function(self,n) self.health=n end;e.SetMaxHealth=function(self,n) self.maximum=n end
    e.EntIndex=function(self) return self.index end
    -- Every actor uses the real archetype template, class, feat, growth and HP path.
    if LOD.RPG.ArchetypeProgressionTemplates[id] then
        assert(C:AttachMonsterProgression(e,72000+serial,8),'real progression attachment')
    end
    return e
end
local hero=actor('runner',Vector(160,0,0));hero.player=true;hero.LODHostile=false
LOD.RunManager.GetPlayerState=function(_,e) return type(e)=='table' and {progressionState=e.LODProgressionState} or nil end
player.GetAll=function() return {hero} end
local function reset()
    if LOD.EnemyReactions then LOD.EnemyReactions.Active={};LOD.EnemyReactions.NextService=0 end
    E.Projectiles={};E.NextService=0;E.LastService=time
    E.Active=setmetatable({}, {__mode='k'});D.Entities={};Status.Active=setmetatable({}, {__mode='k'})
    s.Graph=table.Copy(s.Graph);s.Graph.Progression={Gates={}};s.SimulationFrozen=false;s.Failed=false;s.LevelCleared=false
    util.TraceLine=clearTrace;util.TraceHull=clearTrace;hero.valid=true;hero.alive=true;hero.health=hero.maximum
    if LOD.EnemySupport then LOD.EnemySupport.Pending={};LOD.EnemySupport.Recipients={};LOD.EnemySupport.NextService=0 end
end

dofile(root..'sv_enemy_reactions.lua')
local R=LOD.EnemyReactions
local function pair(id)
    reset();s.BuildReady=true;s.GatesOpen={};LOD.RunManager.State=s
    hero.LODHitStunUntil=nil;hero:SetPos(LOD.MazeNavigator:CellCenter(s.Graph.Cells['3:1:0'])+Vector(160,0,0))
    local source=actor(id);source.LODTarget=hero;E:Prepare(source);D.Entities={source}
    source.LODProgressionState.equipmentBlockChanceContribution=0
    source.LODProgressionState.derivedStats.blockChanceContribution=0
    return source
end
local function service(n)
    at(n);E.NextService=0;env.hooks.LOD_EnemyRosterAttacks()
end
-- Native damage-object and health mutation are the Source boundary. The actual
-- GM mitigation, firearm hit-stun, post-damage reaction observer and cleanup run.
local weapon={valid=true,GetClass=function() return 'weapon_pistol' end}
hero.GetActiveWeapon=function() return weapon end
hero.GetClass=function() return 'player' end
hero.SteamID64=function() return 'b7-tester' end
hero.Nick=function() return 'B7 tester' end
hero.GetNW2Bool=hero.GetNW2Float
LOD.RunManager.IdentityOf=function(_,p) return p==hero and 'b7-tester' or nil end
local priorGetState=LOD.RunManager.GetPlayerState
LOD.RunManager.GetPlayerState=function(self,p)
    if p=='b7-tester' then return {progressionState=hero.LODProgressionState} end
    return priorGetState(self,p)
end
function DamageInfo()
    local d={damage=0,kind=DMG_BULLET}
    function d:GetDamage() return self.damage end
    function d:SetDamage(n) self.damage=n end
    function d:ScaleDamage(n) self.damage=self.damage*n end
    function d:GetAttacker() return self.attacker end
    function d:SetAttacker(e) self.attacker=e end
    function d:GetInflictor() return self.inflictor end
    function d:SetInflictor(e) self.inflictor=e end
    function d:GetDamageType() return self.kind end
    function d:SetDamageType(n) self.kind=n end
    function d:IsDamageType(n) return self.kind==n end
    function d:GetDamagePosition() return self.pos or Vector() end
    function d:SetDamagePosition(p) self.pos=p end
    function d:GetDamageForce() return self.force or Vector() end
    function d:SetDamageForce(p) self.force=p end
    return d
end
local received,receivedContext=0,nil
function hero:TakeDamageInfo(d)
    received=received+1;receivedContext=Status:DamageContext(d,self)
    GM:EntityTakeDamage(self,d);self.health=math.max(0,self.health-d:GetDamage())
    GM:PostEntityTakeDamage(self,d,true)
end
function EffectData() return {SetOrigin=noop} end
util.Effect=noop
unpack=table.unpack
LOD.WanderingDirector={Config={ArchetypeWeights={}}}
dofile(root..'sv_enemy_roster_placement.lua')
dofile(root..'sv_magic_progression.lua');dofile(root..'sv_magic_forms.lua')
local N,key=LOD.MazeNavigator,LOD.MazeGenerator.CellKey
local function grid()
    local g={Cells={},CellTags={},VerticalEdges={},Progression={Gates={}},Width=7,Height=5,Layers=1}
    for x=1,7 do for y=1,5 do g.Cells[key(x,y,0)]={x=x,y=y,z=0,neighbors={}} end end
    for _,c in pairs(g.Cells) do
        for _,d in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do
            local k=key(c.x+d[1],c.y+d[2],0);if g.Cells[k] then c.neighbors[k]=true end
        end
    end
    return g
end
local party={hero};local scans=0
player.GetAll=function() scans=scans+1;return party end
local function center() return N:CellCenter(s.Graph.Cells[key(3,3,0)]) end
clearTrace=function(t)
    if t.start.x==t.endpos.x and t.start.y==t.endpos.y and t.start.z>center().z and t.endpos.z<center().z then
        return {Hit=true,HitPos=Vector(t.start.x,t.start.y,center().z),HitNormal=Vector(0,0,1)}
    end
    return {Hit=false,HitPos=t.endpos}
end
local function coverTrace(t)
    local floor=clearTrace(t)
    if floor.Hit then return floor end
    return {Hit=true,HitPos=t.endpos,Entity=NULL}
end
local baseReset=reset
reset=function()
    baseReset();util.TraceHull=function(t) return {Hit=false,HitPos=t.endpos} end;s.Graph=grid();s.BuildReady=true;LOD.RunManager.State=s
    s.GatesOpen={};party={hero};received=0;hero.hits=0;hero.negate=false
    hero.LODStatusImmunities=nil;hero.LODHitStunUntil=nil;hero.health=10000
    Status:ResetActorLife(hero)
    hero.LODProgressionState.classId='fighter';hero.LODProgressionState.featIds={}
    hero.LODProgressionState.derivedStats={};hero.LODProgressionState.equipmentBlockChanceContribution=0
    hero:SetPos(center()+Vector(90,0,0))
end
pair=function(id)
    reset();local e=actor(id);e:SetPos(center()+Vector(0,0,2));e.LODTarget=hero
    E:Prepare(e);D.Entities={e};return e
end
local function begin(id,setup)
    local e=pair(id);if setup then setup(e) end
    E:Tick(e);return e,assert(e.LODRosterAttack,'production AI commits '..id)
end
local originalDamage=hero.TakeDamageInfo
function hero:TakeDamageInfo(info)
    if self.negate then info:SetDamage(0) end
    self.hits=self.hits+1;originalDamage(self,info)
end
-- Native health/application and traces remain doubles; real rolls, mitigation,
-- damage context, rider save and final status application execute unchanged.
local saveRoll=1
LOD.CombatRolls._RNG=function() return {Int=function(_,lo,hi) return hi==20 and saveRoll or lo end} end
local function strike(e,a,second)
    service((second and a.second or a.ready)-.01)
    local hits=hero.hits;service((second and a.second or a.ready)+.01)
    return hero.hits-hits
end

-- Real canonical Pushback; native transport, traces and entities stay doubled.
concommand={Add=noop};net.WriteEntity=noop;net.WriteFloat=noop;net.WriteString=noop;net.WriteAngle=noop
LOD.RunManager.IsActivePlayer=function(_,p) return p==hero end
hero.GetCollisionBounds=function() return Vector(-16,-16,0),Vector(16,16,72) end
hero.SetAngles=noop;hero.GetModel=function() return "models/police.mdl" end
hero.GetColor=function() return Color(255,255,255) end
LOD.CombatRolls._RNG=function() return {Int=function(_,lo,hi) return hi==20 and saveRoll or lo end,Float=function() return 1 end} end
dofile(root..'sv_rpg_gate_e_pusher.lua')
dofile(root..'sv_pushback.lua')
dofile(root..'sv_enemy_support.lua')
dofile(root..'sv_enemy_tactical.lua')
table.Count=function(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
local Push=LOD.Pushback
Push._PushSaveNatural=function() return saveRoll end
local oldPair=pair
pair=function(id)
    local e=oldPair(id);E.Screens={};hero:SetPos(center()+Vector(180,0,2));hero.GetAngles=function() return Angle() end
    e.LODProgressionState.derivedStats={};hero.LODProgressionState.derivedStats={}
    Status:ResetActorLife(hero);saveRoll=1
    return e
end
local function tow(setup)
    local e=pair('towline');if setup then setup(e) end
    E:Tick(e);return e,assert(e.LODRosterAttack,'Towline AI commitment')
end
local function resolve(e,a) service(a.ready+.01) end
local e,a=tow();local before=copy and copy(hero:GetPos()) or hero:GetPos()
assert(e.nw.LOD_TacticalMode==1 and a.direction.x==1)
resolve(e,a)
assert(hero.hits==1 and hero.health<10000 and hero:GetPos().x<before.x,'real damage and Pushback displacement')
assert(hero:GetPos().x==before.x-48 and not e.LODRosterAttack,'one inward 48-unit contest')
local recovery=e.LODMeleeRecovery.expires
E:Interrupt(e);E:Tick(e);assert(e.LODMeleeRecovery.expires==recovery,'fixed recovery')
local pushCount=Push.Stats.pushes;service(time+.03);assert(Push.Stats.pushes==pushCount,'no repeated pull')
for _,case in ipairs({'side','near','far','jump','cover','floor','cell'}) do
    e,a=tow();local pos=hero:GetPos()
    if case=='side' then hero:SetPos(pos+Vector(0,32,0))
    elseif case=='near' then hero:SetPos(center()+Vector(80,0,2))
    elseif case=='far' then hero:SetPos(center()+Vector(220,0,2))
    elseif case=='jump' then hero:SetPos(pos+Vector(0,0,24))
    elseif case=='cover' then util.TraceLine=coverTrace
    elseif case=='floor' then util.TraceLine=function(t) return {Hit=false,HitPos=t.endpos} end
    elseif case=='cell' then hero:SetPos(pos+Vector(500,0,0)) end
    pos=hero:GetPos();resolve(e,a)
    assert(hero.hits==0 and hero:GetPos():DistToSqr(pos)==0,'escaped tether '..case)
end
-- A hit can hurt but cannot move through native geometry or an unsupported span.
for _,case in ipairs({'hull','startsolid','interior_floor','save','blocked_damage','death','replacement','boost'}) do
    e,a=tow();before=hero:GetPos()
    if case=='hull' then util.TraceHull=function(t) return {Hit=true,Fraction=.5,HitPos=t.endpos} end
    elseif case=='startsolid' then util.TraceHull=function(t) return {Hit=false,StartSolid=true,HitPos=t.endpos} end
    elseif case=='interior_floor' then
        util.TraceLine=function(t)
            if math.abs(t.start.x-(before.x-16))<1 then return {Hit=false,HitPos=t.endpos} end
            return clearTrace(t)
        end
    elseif case=='save' then saveRoll=20
    elseif case=='blocked_damage' then hero.negate=true
    elseif case=='boost' then e.LODProgressionState.derivedStats.fighterCapstoneOutgoingPushMultiplier=20 end
    local old=hero.TakeDamageInfo
    if case=='death' then hero.TakeDamageInfo=function(self,d) old(self,d);self.health=0;self.alive=false end
    elseif case=='replacement' then hero.TakeDamageInfo=function(self,d) old(self,d);Status:ResetActorLife(self) end end
    resolve(e,a);hero.TakeDamageInfo=old
    local moved=math.sqrt(before:DistToSqr(hero:GetPos()))
    if case=='boost' then assert(moved==64,'post-modifier hard spatial cap')
    else assert(moved==0,'pull forfeited '..case) end
end
-- Block/Dodge remain canonical: a successful Block makes damage and pull zero.
e,a=tow();hero.LODProgressionState.equipmentBlockChanceContribution=.33
local rng=LOD.CombatRolls._RNG
LOD.CombatRolls._RNG=function(_,channel)
    if channel:find('block:') then return {Float=function() return 0 end} end
    return rng()
end
before=hero:GetPos();resolve(e,a)
assert(hero.health==10000 and hero:GetPos():DistToSqr(before)==0,'canonical Block denies pull')
LOD.CombatRolls._RNG=rng
local mutations={
 death=function(e) e.LODDead=true end,removal=function(e) e.valid=false end,
 source_life=function(e) Status:ResetActorLife(e) end,
 source_state=function(e) e.LODProgressionState=table.Copy(e.LODProgressionState) end,
 hero_life=function() Status:ResetActorLife(hero) end,
 hero_state=function() hero.LODProgressionState=table.Copy(hero.LODProgressionState) end,
 disconnect=function() hero.valid=false end,
 graph=function() s.Graph=table.Copy(s.Graph) end,
 progression=function() s.Graph.Progression={} end,
 epoch=function() s.CampaignEpoch=s.CampaignEpoch+1 end,
 runid=function() s.RunId=s.RunId..'x' end,
 campaign=function() s.CampaignSeed=s.CampaignSeed+1 end,
 seed=function() s.LevelSeed=s.LevelSeed+1 end,
 run=function() LOD.RunManager.State=table.Copy(s) end,
 freeze=function() s.SimulationFrozen=true end,failed=function() s.Failed=true end,
 cleared=function() s.LevelCleared=true end,build=function() s.BuildReady=false end,
 drift=function(e) e:SetPos(e:GetPos()+Vector(8,0,0)) end,
 stun=function(e) e.LODHitStunUntil=time+10 end,
 morale=function(e) Status.Active[e]={morale_flee={expires=time+10}} end,
 interrupt=function(e) E:Interrupt(e) end,
}
for name,mutate in pairs(mutations) do
    e,a=tow();mutate(e);resolve(e,a);assert(hero.hits==0,'tether retires '..name)
end
e,a=tow();service(a.ready+.3);assert(hero.hits==0,'missed beat does not catch up')
for _,id in ipairs({'held','muted'}) do
    e,a=tow();Status.Active[e]={[id]={expires=time+10}};resolve(e,a);assert(hero.hits==1,'stationary physical tether permits '..id)
end
local function screen(setup)
    e=pair('screenwright')
    local allies={}
    for i=1,4 do local ally=actor('soldier');ally:SetPos(center()+Vector(-40,i*20,2));allies[i]=ally end
    local entries={e,table.unpack(allies)};local scans=0
    LOD.HostileRegistry={List=function() scans=scans+1;return entries end}
    if setup then setup(e,allies,entries) end
    E:Tick(e);a=assert(e.LODRosterAttack,'screen AI commitment')
    return e,a,allies,function() return scans end
end
local function shot(target,origin)
    local info=DamageInfo();info:SetAttacker(hero);info:SetInflictor(hero);info:SetDamage(20)
    Status:AttachDamageContext(info,{physical=true,attackEvent={},attackOrigin=origin or hero:WorldSpaceCenter()})
    return info
end
local function contribution(e,a,target,origin) return E:ScreenContribution(target,hero,shot(target,origin)) end
local allies,scan
e,a,allies,scan=screen()
assert(a.tactical=='screen' and table.Count(a.recipients)==3 and not a.recipients[e],'bounded captured group excludes source')
assert(contribution(e,a,allies[1])==0,'warning grants no protection')
resolve(e,a);assert(e.nw.LOD_RosterAttack==2 and contribution(e,a,allies[1])==.25,'crossing shot receives cover')
assert(contribution(e,a,allies[4])==0,'uncaptured fourth ally receives no guard')
local oldPosition=allies[1]:GetPos();allies[1]:SetPos(center()+Vector(100,20,2))
assert(contribution(e,a,allies[1])==0,'walking through screen forfeits protection');allies[1]:SetPos(oldPosition)
assert(contribution(e,a,allies[1],center()+Vector(-100,0,48))==0,'rear attack bypasses screen')
assert(contribution(e,a,allies[1],center()+Vector(180,500,48))==0,'finite width permits flank')
assert(contribution(e,a,allies[1],center()+Vector(180,0,300))==0,'finite height')
assert(contribution(e,a,e)==0,'engineer remains exposed')
local ally=allies[1];ally.LODProgressionState.equipmentBlockChanceContribution=.2
assert(Rules:BlockChance(ally,hero,shot(ally))==.33,'shared aggregate cap')
local rolls=0;LOD.CombatRolls._RNG=function() return {Float=function() rolls=rolls+1;return 0 end} end
local info=shot(ally);assert(Rules:ApplyBlock(ally,info) and info:GetDamage()==0,'canonical Block settlement')
info:SetDamage(20);assert(Rules:ApplyBlock(ally,info) and rolls==1,'one roll per attack')
info=shot(ally);Status:AttachDamageContext(info,{magic=true,attackEvent={}})
assert(not Rules:ApplyBlock(ally,info) and rolls==1,'Magic bypasses guard without rolling')
LOD.CombatRolls._RNG=rng
assert(scan()==1,'no recurring candidate discovery')
service(a.expires);assert(not E.Screens[e] and not e.LODRosterAttack,'fixed expiry retires screen')
for name,mutate in pairs(mutations) do
    e,a,allies=screen();resolve(e,a);mutate(e)
    assert(contribution(e,a,allies[1])==0,'screen use rejects stale '..name)
    service(time+.03);assert(not E.Screens[e],'screen service releases '..name)
end
for _,case in ipairs({'recipient_life','recipient_state','recipient_dead','cover','range','cell'}) do
    e,a,allies=screen();resolve(e,a);ally=allies[1]
    if case=='recipient_life' then Status:ResetActorLife(ally)
    elseif case=='recipient_state' then ally.LODProgressionState=table.Copy(ally.LODProgressionState)
    elseif case=='recipient_dead' then ally.LODDead=true
    elseif case=='cover' then util.TraceLine=coverTrace
    elseif case=='range' then ally:SetPos(center()+Vector(-250,0,2))
    else ally:SetPos(center()+Vector(-500,0,2)) end
    assert(contribution(e,a,ally)==0,'recipient invalidation '..case)
end
for _,id in ipairs({'held','muted'}) do
    e,a,allies=screen();Status.Active[e]={[id]={expires=time+10}};resolve(e,a)
    assert(contribution(e,a,allies[1])==.25,'stationary physical screen permits '..id)
end
e,a,allies=screen();service(a.ready+.3);assert(not E.Screens[e],'missed screen warning forfeits')
e,a=screen(function(_,_,entries) for i=#entries,2,-1 do table.remove(entries,i) end end)
assert(a.fallbackLife and not a.tactical,'no allies uses finite ordinary fallback')
resolve(e,a);assert(#E.Projectiles==1 and E.Projectiles[1].fallbackLife==a.fallbackLife,'fallback projectile retains life')
Status:ResetActorLife(hero);service(time+.03);assert(#E.Projectiles==0,'fallback retires replacement')

-- Caps are admissions, not truncated active work. The seventeenth screen fires
-- the ordinary fallback; new allies beyond the one-time scan never inherit it.
e,a,allies=screen();resolve(e,a)
for index=2,16 do
    local source=actor('screenwright');source:SetPos(e:GetPos());source.LODTarget=hero;E:Prepare(source)
    assert(E:BeginTactical(source,hero,time) and source.LODRosterAttack.tactical=='screen','screen admission '..index)
end
local excess=actor('screenwright');excess:SetPos(e:GetPos());excess.LODTarget=hero;E:Prepare(excess)
assert(E:BeginTactical(excess,hero,time) and excess.LODRosterAttack.fallbackLife,'global cap falls back')
assert(table.Count(E.Screens)==16,'global active and warning cap')
local target=allies[1];assert(contribution(e,a,target)==.25,'screens do not stack their contribution')
e,a=screen(function(source,_,entries)
    for i=#entries,1,-1 do entries[i]=nil end
    for i=1,128 do entries[i]=source end
    local hidden=actor('soldier');hidden:SetPos(center()+Vector(-40,0,2));entries[129]=hidden
end)
assert(a.fallbackLife,'candidate beyond bound is never captured')
-- Attack prohibition cancels without inventing a private Held/Muted rule.
e,a=tow();local canAttack=Status.CanInitiateAttack
Status.CanInitiateAttack=function(_,who) return who~=e end
resolve(e,a);assert(hero.hits==0,'shared attack prohibition');Status.CanInitiateAttack=canAttack
-- Preserve exact scope even in a reentrant damage callback.
e,a=tow();local take=hero.TakeDamageInfo;before=hero:GetPos()
hero.TakeDamageInfo=function(self,info) take(self,info);E:StepTactical(e,a,time);s.Graph=table.Copy(s.Graph) end
resolve(e,a);hero.TakeDamageInfo=take
assert(hero.hits==1 and hero:GetPos():DistToSqr(before)==0,'one hit and no stale reentrant pull')

-- Runtime orientation/support must agree with the deployed screen, even after
-- production admission at a different facing.
e,a,allies=screen();util.TraceHull=function(t)
    if math.abs(t.endpos.y-t.start.y)>90 then return {Hit=true,HitPos=t.endpos} end
    return {Hit=false,HitPos=t.endpos}
end
resolve(e,a);assert(not e.LODRosterAttack and not E.Screens[e],'changed lateral clearance denies deployment')
e,a,allies=screen();resolve(e,a)
local ground=util.TraceLine
util.TraceLine=function(t)
    if math.abs(t.start.x-a.plane.x)<1 and t.start.x==t.endpos.x then return {Hit=false,HitPos=t.endpos} end
    return ground(t)
end
assert(contribution(e,a,allies[1])==0,'removed screen anchor forfeits cover immediately')
service(time+.03);assert(not E.Screens[e],'support loss retires display and commitment')
print('BESTIARY_B9_PASS: real roster/combat/Block/Pushback; constrained pull, escapable lane, finite captured screen, caps, source/recipient/run lifetimes and fallback')
