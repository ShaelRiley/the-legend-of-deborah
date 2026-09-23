-- B1 production attacks, Content riders, lifecycle and encounter entry points.
-- Source traces/damage dispatch and dice are controlled boundaries; status
-- saves/application, Content translation/push policy and AI movement are real.
local env=dofile('tools/test_enemy_update.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local noop=function() end
local v=getmetatable(Vector())
v.__div=function(a,b) return a*(1/b) end
function v:Dot(b) return self.x*b.x+self.y*b.y+self.z*b.z end
function v:Length2D() return math.sqrt(self.x*self.x+self.y*self.y) end
function v:Normalize() local n=self:GetNormalized();self.x,self.y,self.z=n.x,n.y,n.z end
local am={};am.__index=am
function Angle(p,y,r) return setmetatable({p=p or 0,y=y or 0,r=r or 0},am) end
function am:Forward() local y=math.rad(self.y);return Vector(math.cos(y),math.sin(y),0) end
function v:Angle() return Angle(0,math.deg(math.atan(self.y,self.x)),0) end
function math.AngleDifference(a,b) return (a-b+180)%360-180 end
ACT_IDLE,ACT_RUN_AIM_RIFLE,ACT_IDLE_ANGRY_SMG1,ACT_RANGE_ATTACK1,ACT_FLY=4,5,6,7,8
MASK_SOLID=3;NULL={valid=false};DMG_ENERGYBEAM,DMG_BURN,DMG_POISON,DMG_SLASH=4,5,6,7
net.WriteUInt=noop;net.WriteVector=noop;net.WriteBool=noop;net.Broadcast=noop;net.Receive=noop
hook.Run=noop;timer.Create=noop;timer.Remove=noop
game={GetWorld=function() return NULL end}
function ErrorNoHalt(message) error(message) end
GM={};dofile(root..'sv_damage_info.lua')
dofile(root..'sh_rng.lua');dofile(root..'sh_rpg_schema.lua')
LOD.CharacterProgressionSystem={}
LOD.RPGAbilityRules={ProgressionState=function(_,a) return a.LODProgressionState end,
    Derived=function(_,a) return a.LODProgressionState.derivedStats end,
    RateOfFireMultiplier=function() return 1 end,MovementMultiplier=function() return 1 end}
local pushed={}
LOD.Pushback={Apply=function(_,target,context) pushed[#pushed+1]={target=target,context=context};return true end}
dofile(root..'sv_rpg_status_elements.lua');dofile(root..'sv_magic_progression.lua');dofile(root..'sv_magic_forms.lua')
local Status=LOD.RPGStatusElements
local saveRoll=1
LOD.CombatRolls._RNG=function() return {Int=function(_,lo,hi) return hi==20 and saveRoll or lo end} end
local rolls,contexts=0,{}
LOD.CombatRolls.RollHostileAttack=function(_,e,profile,amount)
    assert(profile.magicDamage and profile.count==1 and profile.sides==6 and profile.bonus==2,'B1 canonical magical profile')
    rolls=rolls+1;return {total=amount,scale=1,attackEvent={}}
end
LOD.CombatRolls.ResolveActorDamage=function(_,c,e,p,tags)
    assert(tags.magic and not tags.physical,'Content attacks must enter magical defense')
    contexts[#contexts+1]=tags;return c.total
end
LOD.CombatRolls.QueueDamageReport=noop
function DamageInfo()
    return {SetAttacker=function(self,a) self.attacker=a end,GetAttacker=function(self) return self.attacker end,
        SetDamage=function(self,n) self.amount=n end,GetDamage=function(self) return self.amount end,
        SetInflictor=noop,SetDamageType=noop,SetDamagePosition=noop}
end
local time=200
local function at(n) time=n;env.setTime(n) end
at(time)
local function actor(id,pos)
    local e=env.actor(1);e.LODArchetypeId=id;e:SetPos(pos or Vector());e.health=1000
    e.LODConfig=table.Copy(LOD.Config.Encounter.Archetypes[id] or {})
    e.SetNW2Int=e.SetNW2Bool;e.SetNW2Float=e.SetNW2Bool;e.SetNW2String=e.SetNW2Bool
    e.SetColor=noop;e.GetAngles=function() return Angle() end
    e.GetNW2Float=function(_,_,default) return default end
    e.Health=function(self) return self.health end;e.GetMaxHealth=function() return 1000 end
    e.LODProgressionState={level=1,abilities={str=10,dex=10,con=10,int=10,wis=10,cha=10},derivedStats={}}
    e.TakeDamageInfo=function(self,info)
        if self.negate then info:SetDamage(0) end
        self.hits=(self.hits or 0)+1;Status:ObserveDamage(self,info)
        self.health=math.max(0,self.health-info:GetDamage())
    end
    return e
end
local p=actor('hero',Vector(120,0,0));p.player=true;p.LODHostile=false
local party={p};player.GetAll=function() return party end
util.TraceLine=function(t) return {Hit=false,HitPos=t.endpos} end
util.TraceHull=function(t) return {Hit=false,HitPos=t.endpos} end
util.Effect=noop;function EffectData() return {SetOrigin=noop} end
dofile(root..'sv_enemy_roster.lua')
local E=LOD.EnemyRoster
local s=LOD.RunManager.State;s.BuildReady=true;s.Failed=false;s.LevelCleared=false;s.SimulationFrozen=false
s.CampaignEpoch=1;s.RunId='b1';s.CampaignSeed=77;s.LevelSeed=123
local function clean()
    E.Active=setmetatable({}, {__mode='k'});E.Projectiles={};E.NextService=0;E.LastService=time
    Status:ResetActorLife(p);p.health=1000;p.alive=true;p.valid=true;p.negate=false;p.hits=0
    p:SetPos(Vector(120,0,0));party={p};pushed={};saveRoll=1
    util.TraceLine=function(t) return {Hit=false,HitPos=t.endpos} end
    util.TraceHull=function(t) return {Hit=false,HitPos=t.endpos} end
end
local function begin(id)
    local e=actor(id);e.LODTarget=p;E:Prepare(e);E:Begin(e,p,time)
    assert(e.LODRosterAttack,id..' creates a playable commitment');return e,e.LODRosterAttack
end
local function release(e,a) at(a.ready);E:Attack(e,a,time);assert(a.released,'warning must release') end
local function service() at(time+.05);env.hooks.LOD_EnemyRosterAttacks() end

-- Frozen Gaoler mark permits escape; repeated ticks cannot repeat damage/save.
clean();local gaoler,a=begin('gaoler');local mark=a.aim
at(a.ready-.001);E:Attack(gaoler,a,time);assert(p.hits==0,'no early eruption')
p:SetPos(Vector(500,0,0));release(gaoler,a);assert(p.hits==0 and a.aim==mark,'mark cannot track fleeing target')
clean();gaoler,a=begin('gaoler');local before=rolls;release(gaoler,a)
assert(p.hits==1 and Status:Has(p,'held') and not Status:CanMoveVoluntarily(p),'Ice enters canonical Held')
local saves=Status.Stats.saves;E:Attack(gaoler,a,time+.01)
assert(p.hits==1 and rolls==before+1 and Status.Stats.saves==saves,'one roll/hit/save per target per commitment')
assert(contexts[#contexts].element=='ice' and contexts[#contexts].riderStatusId=='held')
clean();saveRoll=20;gaoler,a=begin('gaoler');release(gaoler,a)
assert(p.hits==1 and not Status:Has(p,'held'),'successful WIS save prevents Held without canceling damage')
clean();p.LODStatusImmunities={'held'};gaoler,a=begin('gaoler');release(gaoler,a)
assert(p.hits==1 and not Status:Has(p,'held'),'canonical immunity prevents the rider');p.LODStatusImmunities=nil
clean();p.negate=true;gaoler,a=begin('gaoler');release(gaoler,a)
assert(not Status:Has(p,'held'),'zero actual damage cannot apply rider')
clean();p.health=1;gaoler,a=begin('gaoler');release(gaoler,a)
assert(p.health==0 and not Status:Has(p,'held'),'lethal damage cannot install lasting rider')

-- Repulsor pulse is a committed location/radius, with normal cover and targets.
clean();local repulsor;repulsor,a=begin('repulsor');local origin=a.origin
repulsor:SetPos(Vector(800,0,0));release(repulsor,a)
assert(a.origin==origin and p.hits==1 and #pushed==1,'pulse remains at telegraphed origin')
assert(pushed[1].context.source=='earth content' and pushed[1].context.magicPush and pushed[1].context.distance==336)
assert(pushed[1].context.direction.x>0,'push must point out from the frozen pulse origin after caster displacement')
E:Attack(repulsor,a,time+.01);assert(p.hits==1 and #pushed==1,'pulse dedup includes Earth push')
clean();repulsor,a=begin('repulsor');p:SetPos(Vector(repulsor.LODConfig.fireRange+10,0,0));release(repulsor,a)
assert(p.hits==0 and #pushed==0,'escaping pulse range wins')
clean();p.negate=true;repulsor,a=begin('repulsor');release(repulsor,a);assert(#pushed==0,'zero damage cannot push')
clean();p.health=1;repulsor,a=begin('repulsor');release(repulsor,a);assert(#pushed==0,'lethal damage cannot push')
clean();repulsor,a=begin('repulsor');util.TraceLine=function(t) return {Hit=true,HitPos=t.start} end
at(a.ready);E:Attack(repulsor,a,time);assert(p.hits==0 and #pushed==0,'cover stops pulse')
clean();local ally=actor('runner',Vector(80,0,0));local corpse=actor('hero',Vector(90,0,0));corpse.player=true;corpse.alive=false
party={p,ally,corpse};repulsor,a=begin('repulsor');release(repulsor,a)
assert(p.hits==1 and not ally.hits and not corpse.hits,'faction and living-player target membership')

-- Silencer fires one finite non-homing bolt; a released bolt survives Mute.
clean();local silencer;silencer,a=begin('silencer');local aim=a.direction;release(silencer,a)
assert(#E.Projectiles==1);local q=E.Projectiles[1];local start=q.pos
E:Release(silencer,a,time);assert(#E.Projectiles==1,'duplicate release cannot duplicate projectile')
p:SetPos(Vector(100,300,0));Status:Apply(silencer,'muted',p,{direct=true,duration=20});service()
assert(#E.Projectiles==1 and q.velocity:GetNormalized():DistToSqr(aim)<1e-12,'released bolt direction cannot home and owner Mute cannot recall it')
assert(math.abs(q.pos:Distance(start)-27)<.001,'540 units/sec finite travel')
util.TraceHull=function(t) assert(t.maxs.x==7,'Content bolt hull radius');return {Hit=true,HitPos=t.endpos,Entity=p} end
service();assert(#E.Projectiles==0 and p.hits==1 and Status:Has(p,'muted'),'Light projectile impact enters canonical Mute')
service();assert(p.hits==1,'consumed bolt cannot hit twice')
clean();silencer,a=begin('silencer');release(silencer,a);local blocker={valid=true}
util.TraceHull=function(t) return {Hit=true,HitPos=t.endpos,Entity=blocker} end
service();assert(#E.Projectiles==0 and p.hits==0,'physical cover consumes bolt without damage')
clean();silencer,a=begin('silencer');release(silencer,a);at(E.Projectiles[1].expires);service()
assert(#E.Projectiles==0,'projectile TTL bound')

-- New casts/charging share status and hit-stun locks; Held stops movement only.
for _,id in ipairs({'gaoler','silencer','repulsor'}) do
    clean();local e=actor(id);e.LODTarget=p;Status:Apply(e,'muted',p,{direct=true,duration=20})
    E:Tick(e);assert(not e.LODRosterAttack,id..' cannot initiate while muted')
    Status:Clear(e,'muted');E:Tick(e);assert(e.LODRosterAttack,id..' resumes after Mute')
    Status:Apply(e,'muted',p,{direct=true,duration=20});service()
    assert(not e.LODRosterAttack,id..' Mute cancels charge')
    Status:Clear(e,'muted');e.LODNextAttack=0;E:Tick(e);assert(e.LODRosterAttack)
    e.LODHitStunUntil=time+2;service();assert(not e.LODRosterAttack,id..' stun cancels charge')
end
dofile(root..'sv_hostile_motion_v2.lua')
clean();local held=actor('repulsor');Status:Apply(held,'held',p,{direct=true,duration=20})
local heldPos=held:GetPos();assert(not LOD.HostileMotionV2:MoveToward(held,{pos=heldPos+Vector(20,0,0)}))
assert(held:GetPos()==heldPos and held.LODMotionSpeed==0 and Status:CanInitiateMagic(held),'Held uses movement authority and does not become Mute')

-- Hard bounded pool and exact-dungeon identity reject every stale attack/bolt.
clean();for i=1,65 do local e,attack=begin('silencer');E:Release(e,attack,time) end
assert(#E.Projectiles==64,'shared global projectile ceiling')
local changes={
    {'death',function(e) e.LODDead=true end},
    {'owner removal',function(e) e.valid=false end},
    {'freeze',function() s.SimulationFrozen=true end},
    {'same-seed graph replacement',function() s.Graph=table.Copy(s.Graph) end},
    {'same-seed progression replacement',function() s.Graph.Progression=table.Copy(s.Graph.Progression) end},
    {'epoch',function() s.CampaignEpoch=s.CampaignEpoch+1 end},
    {'run ID',function() s.RunId=s.RunId..'x' end},
    {'campaign seed',function() s.CampaignSeed=s.CampaignSeed+1 end},
    {'level seed',function() s.LevelSeed=s.LevelSeed+1 end},
    {'state replacement',function() s=table.Copy(s);LOD.RunManager.State=s end}
}
for _,row in ipairs(changes) do
    clean();s.SimulationFrozen=false;local e,attack=begin('silencer');E:Release(e,attack,time)
    local charging=begin('gaoler');row[2](e);if row[1]=='death' then charging.LODDead=true elseif row[1]=='owner removal' then charging.valid=false end
    service();assert(#E.Projectiles==0,row[1]..' must discard released projectile')
    assert(not charging.valid or charging.LODDead or not charging.LODRosterAttack,row[1]..' must discard charge')
end
s.SimulationFrozen=false
for _,invalid in ipairs({'death','disconnect'}) do
    clean();local e=begin('gaoler');if invalid=='death' then p.alive=false else p.valid=false end
    service();assert(not e.LODRosterAttack,invalid..' target cancels charge')
end

-- Canonical authored spawner keeps valid survivors on a failed native creation,
-- consumes stable ordinals, never retries/duplicates, and reserves before spawn.
clean();s.Graph={Cells={},CellTags={},VerticalEdges={},Progression={Gates={}}}
local cell={x=1,y=1,z=0,neighbors={}};local key=LOD.MazeGenerator.CellKey(1,1,0)
s.Graph.Cells[key]=cell
LOD.WanderingDirector={Config={ArchetypeWeights={}}}
dofile(root..'sv_enemy_roster_placement.lua')
local D=LOD.EncounterDirector;D.Entities={}
D.GetActiveCount=function(self) return self.activeCount or #self.Entities end
D._SpawnOffsets=function(_,count) local offsets={} for i=1,count do offsets[i]=Vector() end return offsets end
LOD.HostileMotionV2.SnapSpawn=noop
local creates=0
ents.Create=function()
    creates=creates+1;if creates==2 then return NULL end
    local e=actor('gaoler');e.Spawn=function(self) self.LODConfig=table.Copy(LOD.Config.Encounter.Archetypes[self.LODArchetypeId]) end
    return e
end
local encounter={id=901,cell=cell,cellKey=key,role='arena',sector=2,composition={gaoler=1,silencer=1,repulsor=1},entities={}}
D.activeCount=LOD.Config.Encounter.ActiveHostileCeiling-2
assert(not D:_SpawnEncounter(encounter) and creates==0 and not encounter.spawned,'reserve ceiling before any native creation')
D.activeCount=0;assert(D:_SpawnEncounter(encounter) and encounter.spawned and #encounter.entities==2)
assert(encounter.entities[1].LODArchetypeId=='gaoler' and encounter.entities[1].LODEncounterOrdinal==1)
assert(encounter.entities[2].LODArchetypeId=='repulsor' and encounter.entities[2].LODEncounterOrdinal==3,'failed slot must not shift deterministic identity')
assert(D:_SpawnEncounter(encounter) and creates==3 and #encounter.entities==2,'partial native creation must not duplicate on retry')
for _,template in ipairs({'gaoler_hold','silencer_screen','repulsor_screen'}) do
    assert(table.HasValue(D:_EligibleTemplates(2,'arena'),template) and table.HasValue(D:_EligibleTemplates(2,'ambush'),template))
    assert(not table.HasValue(D:_EligibleTemplates(1,'arena'),template))
end
print('BESTIARY_B1_PASS: frozen Ice mark; finite Light bolt; committed Earth pulse; canonical saves/riders/push; cover/faction/dedup; Mute/Held/stun; bounded pool; exact-run lifecycle; cap/partial-spawn ordinals')

-- Exercise actual client decoding/drawing: low effects retain warning geometry
-- and the two-bit Light projectile type is visibly distinct from Venom/bullets.
function Color(r,g,b,a) return {r=r,g=g,b=b,a=a or 255} end
function Material(path) return path end
function EyePos() return Vector() end
local low=false;GetConVar=function() return {GetBool=function() return low end} end
local receivers,discs,beams,sprites={},{},{},{}
net.Receive=function(name,callback) receivers[name]=callback end
render={SetMaterial=noop,SetColorMaterial=noop,
    DrawBeam=function(from,to,width,_,_,color) beams[#beams+1]={from=from,to=to,width=width,color=color} end,
    DrawSprite=function(pos,w,h,color) sprites[#sprites+1]={pos=pos,w=w,h=h,color=color} end}
LOD.MagicArea={Disc=function(_,pos,radius) discs[#discs+1]={pos=pos,radius=radius} end}
dofile(root..'cl_enemy_roster.lua')
for _,id in ipairs({'gaoler','repulsor'}) do
    local e=actor(id);local aim=Vector(70,80,3)
    e.GetNW2String=function() return id end;e.GetNW2Vector=function(_,name) return name=='LOD_RosterAim' and aim or Vector(0,0,48) end
    e.GetNW2Float=function() return 220 end
    for _,reduced in ipairs({false,true}) do for stage=1,2 do
        low=reduced;e.GetNW2Int=function() return stage end;discs={};beams={}
        LOD.EnemyRosterVisual:Draw(e,1)
        local radius=id=='repulsor' and 220 or 112
        assert(#discs==1 and discs[1].pos==aim and discs[1].radius==radius,'warning geometry must match actual attack bounds')
        local rings=0;for _,line in ipairs(beams) do
            if line.from.z==line.to.z then
                rings=rings+1;assert(math.abs(line.from:Distance(aim)-radius)<.001)
            end
        end
        assert(rings==24,'low effects cannot drop warning boundary segments')
    end end
end
local reads=0
net.ReadUInt=function(bits) reads=reads+1;assert(bits==(reads==1 and 7 or 2));return reads==1 and 1 or 2 end
local vectors=0;net.ReadVector=function() vectors=vectors+1;return vectors==1 and Vector() or Vector(540,0,0) end
receivers.LOD_RosterProjectiles();sprites={};beams={};env.hooks.LOD_RosterProjectiles(false,false)
assert(#sprites==1 and sprites[1].w==24 and sprites[1].color.r==255 and sprites[1].color.g==245 and sprites[1].color.b==170,'two-bit Light bolt decoding/color')
assert(#beams==1 and beams[1].width==5,'Light bolt trail width')
at(time+.31);sprites={};env.hooks.LOD_RosterProjectiles(false,false);assert(#sprites==0,'stale projectile packets expire visually')
print('BESTIARY_B1_VISUAL_PASS: exact warning discs/rings at full and reduced effects; two-bit Light decode; finite visual timeout')

-- Use the accepted actor fixture to exercise real generation (including feat
-- drafts, class/growth and HP), then the production attribution settlement.
dofile('tools/test_actor_progression.lua')
dofile(root..'sv_rpg_gate_d.lua')
local Progression,Attribution=LOD.CharacterProgressionSystem,LOD.CombatAttributionSystem
local awards=0
Progression.AwardHeroXP=function(_,identity,amount) assert(identity=='tester');awards=awards+amount;return true end
for id,baseXP in pairs({gaoler=50,silencer=45,repulsor=50}) do
    local generated=assert(Progression:GenerateMonsterProgression(id,72001,8,45,'ai'))
    local replay=assert(Progression:GenerateMonsterProgression(id,72001,8,45,'ai'))
    assert(generated.archetypeId==id and generated.usesMagic and generated.level>=9,'B1 must retain own progression identity and Magic capability')
    assert(generated.classId==replay.classId and generated.level==replay.level and generated.derivedStats.maxHP==replay.derivedStats.maxHP,'B1 actor generation must be deterministic')
    assert(generated.progressionHitDieSides==LOD.RPG.ArchetypeProgressionTemplates[id].progressionHitDieSides)
    local hostile={LODArchetypeId=id,LODProgressionState=generated}
    Attribution.Ledgers[hostile]={effectiveDamageByHeroId={tester=100},killingBlowHeroId='tester'}
    local beforeAward=awards;assert(Attribution:Settle(hostile))
    local expected=math.max(5,5*math.floor((baseXP*(1+.05*(generated.level-1)))/5+.5))
    assert(hostile.LODRPGXPSettlement.value==expected and awards-beforeAward==expected,'own archetype XP reaches shared kill/contribution award')
    assert(not Attribution:Settle(hostile) and awards-beforeAward==expected,'B1 reward cannot settle twice')
end
print('BESTIARY_B1_PROGRESSION_PASS: own actor identity; seeded class/Level/HP; Magic capability; level-scaled XP; one settlement')
