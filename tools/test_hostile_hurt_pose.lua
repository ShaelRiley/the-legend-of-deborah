-- Finite production-code regression for hit-stun floor-sinking presentation.
-- Synthetic Source sequence metadata, not native model/visual acceptance.
-- Run from the repository: python3 tools/run_lua54.py tools/test_hostile_hurt_pose.lua
-- Optional first argument points to another source root for before/after proof.
local root=(arg[1] or '.')..'/gamemodes/legend_of_deborah/gamemode/lod/'
local now,actors,deferred=10,{},{}
local noop=function() end
function IsValid(e) return type(e)=='table' and e.valid~=false end
function isnumber(v) return type(v)=='number' end
function CurTime() return now end
function math.Clamp(v,a,b) return math.max(a,math.min(b,v)) end
bit={band=function(a,b) return a & b end}
vector_origin={x=0,y=0,z=0}
ACT_IDLE,ACT_WALK,ACT_RUN=1,2,3
ACT_BIG_FLINCH,ACT_FLINCH_CHEST,ACT_SMALL_FLINCH,ACT_FLINCH_HEAD=10,11,12,13
ACT_MELEE_ATTACK1,ACT_RANGE_ATTACK1,ACT_RANGE_ATTACK_SMG1=20,21,22
ACT_DIESIMPLE,ACT_DIEBACKWARD,ACT_GMOD_DEATH=30,31,32
ACT_HL2MP_IDLE,ACT_HL2MP_IDLE_FIST,ACT_HL2MP_GESTURE_RANGE_ATTACK_FIST=40,41,42
util={AddNetworkString=noop};net={Start=noop,Send=noop}
concommand={Add=noop};ents={FindByClass=function() return actors end}
local hooks={}
hook={Add=function(event,id,fn) hooks[event]=hooks[event] or {};hooks[event][id]=fn end,
    Remove=function(event,id) if hooks[event] then hooks[event][id]=nil end end}
local function fire(event,...)
    for _,fn in pairs(hooks[event] or {}) do fn(...) end
end
timer={Simple=function(_,fn) deferred[#deferred+1]=fn end}
local function flush()
    local queue=deferred;deferred={}
    for _,fn in ipairs(queue) do fn() end
end
local class={}
function class:_BehaviourTick() self.behaviour=(self.behaviour or 0)+1 end
function class:BodyUpdate() self.body=(self.body or 0)+1 end
scripted_ents={GetStored=function() return {t=class} end}
LOD={HostileRegistry={List=function() return actors end}}
dofile(root..'sv_hostile_animation.lua')
dofile(root..'sv_m3_hit_feedback.lua')
dofile(root..'sv_hostile_death_pose.lua')
dofile(root..'sv_hostile_hurt_pose.lua')
local A,H,F=LOD.HostileAnimation,LOD.HostileHurtPose,LOD.M3HitFeedback
local function actor()
    local e=setmetatable({LODHostile=true,LODArchetypeId='soldier',LODConfig={speed=90},
        model='fixture_npc.mdl',sequence=1,cycle=.97,rate=1,writes={},queries=0,
        metadata={
            [0]={label='reference',flags=0},[1]={label='walk_all',flags=1},
            [2]={label='idle',flags=1},[3]={label='flinch_phys_01',flags=0x3004},
            [4]={label='small_recoil',flags=0},[5]={label='pain',flags=0},
            [6]={label='gesture_flinch',flags=0},[7]={label='flinch_chest',flags=0,activityname='ACT_GESTURE_FLINCH_CHEST'},
            [8]={label='flinch_head',flags=0x3020},[9]={label='death_01',flags=0}},
        named={flinch_phys_01=3,idle=2},
        weighted={[ACT_BIG_FLINCH]=3,[ACT_IDLE]=2,[ACT_HL2MP_IDLE]=2,
            [ACT_HL2MP_IDLE_FIST]=2,[ACT_HL2MP_GESTURE_RANGE_ATTACK_FIST]=3}}, {__index=class})
    function e:GetModel() return self.model end
    function e:GetSequenceName(seq) return self.metadata[seq] and self.metadata[seq].label or '' end
    function e:GetSequenceInfo(seq) self.queries=self.queries+1;return self.metadata[seq] end
    function e:LookupSequence(name) return self.named[name] or -1 end
    function e:SelectWeightedSequence(act) return self.weighted[act] or -1 end
    function e:GetSequenceList() return {'idle'} end
    function e:GetSequence() return self.sequence end
    function e:SetSequence(seq) self.writes[#self.writes+1]=seq;self.sequence=seq end
    e.ResetSequence=e.SetSequence
    function e:GetCycle() return self.cycle end
    function e:SetCycle(cycle) self.cycle=cycle end
    function e:GetPlaybackRate() return self.rate end
    function e:SetPlaybackRate(rate) self.rate=rate end
    function e:SetVelocity(v) self.velocity=v end
    function e:SetNW2Bool(k,v) self[k]=v end
    function e:FrameAdvance() self.frames=(self.frames or 0)+1 end
    function e:AddGestureSequence(seq,autokill) self.gesture={seq,autokill} end
    local function forbidden() error('pose repair changed position/hull/bone offsets') end
    e.SetPos,e.SetRenderOrigin,e.SetCollisionBounds,e.SetModelScale,e.ManipulateBonePosition=forbidden,forbidden,forbidden,forbidden,forbidden
    e.loco={SetDesiredSpeed=function(_,v) e.speed=v end,SetVelocity=function(_,v) e.locoVelocity=v end}
    return e
end
local function safeWrites(e)
    for _,seq in ipairs(e.writes) do
        local info=e.metadata[seq]
        assert(info and (info.flags & 0x24)==0,'unsafe delta/empty sequence installed as a body: '..tostring(seq))
        assert(not info.label:lower():find('gesture',1,true),'gesture replaced the base')
    end
end
local function near(a,b) assert(math.abs(a-b)<1e-8,tostring(a)..' ~= '..tostring(b)) end
local passed,failed=0,0
local function check(name,fn)
    now=10;actors={};deferred={};LOD.Warden=nil;LOD.RPGAbilityRules=nil;LOD.EnemyRoster=nil
    local ok,err=pcall(fn)
    if ok then passed=passed+1;print('PASS '..name)
    else failed=failed+1;print('FAIL '..name..': '..tostring(err)) end
end
check('real stun never temporarily installs an additive NPC flinch',function()
    local e=actor();assert(F:ApplyHitStun(e));safeWrites(e)
    assert(e.sequence==1 and e.rate==0);near(e.cycle,.97)
    near(e.LODHitStunUntil,10.30);near(e.LODNextHitStun,10.36)
end)
check('named full-body flinch survives while earlier delta is skipped',function()
    local e=actor();e.named.pain=5
    assert(F:ApplyHitStun(e));safeWrites(e);assert(e.sequence==5);near(e.cycle,.44)
end)
check('weighted full-body recoil survives with unrelated name',function()
    local e=actor();e.weighted[ACT_FLINCH_CHEST]=4
    assert(F:ApplyHitStun(e));safeWrites(e);assert(e.sequence==4);near(e.cycle,.44)
end)
check('empty animation data is rejected',function()
    local e=actor();e.named={flinch_head=8,idle=2};e.weighted[ACT_BIG_FLINCH]=8
    assert(F:ApplyHitStun(e));safeWrites(e);assert(e.sequence==1)
end)
check('named gesture and gesture activity are not base poses',function()
    local e=actor();e.named={flinch_chest=7,idle=2};e.weighted[ACT_BIG_FLINCH]=6
    assert(F:ApplyHitStun(e));assert(e.sequence==1 and #e.writes==0)
end)
check('missing flags and nonexistent sequence fail closed',function()
    local e=actor();e.metadata[3].flags=nil;e.weighted[ACT_FLINCH_CHEST]=999
    assert(F:ApplyHitStun(e));assert(e.sequence==1 and #e.writes==0)
end)
check('fallback preserves entire cycle interval including endpoints',function()
    for _,cycle in ipairs({0,.03,.97,1}) do
        local e=actor();e.cycle=cycle;e.named={idle=2};e.weighted[ACT_BIG_FLINCH]=2
        assert(H:Freeze(e,.44,'stun'));near(e.cycle,cycle);assert(e.sequence==1)
    end
end)
check('invalid or delta current base recovers to safe idle',function()
    for _,seq in ipairs({0,3,999}) do
        local e=actor();e.sequence=seq
        assert(H:Freeze(e,.44,'stun'));safeWrites(e);assert(e.sequence==2);near(e.cycle,0)
    end
end)
check('no safe pose never chooses a reference or delta by fiat',function()
    local e=actor();e.sequence=0;e.metadata[2].flags=4
    assert(not H:Freeze(e,.44,'stun'));assert(#e.writes==0)
end)
check('missing optional adapter metadata never introduces a flinch',function()
    local e=actor();e.GetSequenceInfo=false;e.GetCycle=false
    assert(H:Freeze(e,.44,'stun'));assert(e.sequence==1 and #e.writes==0);near(e.cycle,0)
end)
check('player skeleton retains current base and repairs missing base',function()
    local e=actor();e.LODSkeletonHero=true;e.model='models/player/skeleton.mdl'
    e.LODProgressionState={classId='fighter'}
    assert(F:ApplyHitStun(e));assert(e.sequence==1);near(e.cycle,.97)
    e.sequence=0;assert(H:Freeze(e,.44,'stun'));assert(e.sequence==2)
    safeWrites(e)
end)
check('normal player attack overlays are unchanged',function()
    local e=actor();e.LODSkeletonHero=true;e.model='models/player/skeleton.mdl'
    e.LODProgressionState={classId='fighter'}
    assert(A:PlayerAttack(e));assert(e.sequence==1 and e.gesture[1]==3 and e.gesture[2])
end)
check('hold defeats body overwrite without repeated metadata work',function()
    local e=actor();actors={e};assert(F:ApplyHitStun(e));local queries=e.queries
    for _=1,60 do e.sequence=2;e.cycle=.2;e.rate=1;fire('Think') end
    assert(e.sequence==1 and e.rate==0);near(e.cycle,.97)
    assert(e.queries==queries,'metadata queried every frame')
    e:_BehaviourTick();e:BodyUpdate();assert(not e.behaviour and e.frames==1)
    assert(e.speed==0 and e.velocity==vector_origin);safeWrites(e)
end)
check('expiry clears pose and restores ordinary AI and playback',function()
    local e=actor();actors={e};assert(F:ApplyHitStun(e));now=10.31;fire('Think');e:_BehaviourTick()
    assert(not e.LODFrozenHurtSequence and not e.LODFrozenHurtModel and e.rate==1)
    assert(e.speed==90 and e.behaviour==1 and e.LODNextRouteRefresh==0)
end)
check('duplicate and crowbar anti-stunlock windows remain intact',function()
    local e=actor();assert(F:ApplyHitStun(e,1,nil,nil,'melee'))
    local cycle,writes=e.cycle,#e.writes
    assert(not F:ApplyHitStun(e));now=10.5;assert(not F:ApplyHitStun(e,1,nil,nil,'melee'))
    near(e.LODMeleeStaggerReady,13);near(e.cycle,cycle);assert(#e.writes==writes)
    now=13.01;assert(F:ApplyHitStun(e,1,nil,nil,'melee'));safeWrites(e)
end)
check('shotgun double stun and ability/form multipliers unchanged',function()
    local e=actor();assert(F:ApplyShotgunShellStun(e));near(e.LODHitStunUntil,10.60);near(e.LODNextHitStun,10.66)
    assert(not F:ApplyShotgunShellStun(e))
    e=actor();LOD.RPGAbilityRules={HitStunMultiplier=function() return 1.5 end}
    assert(F:ApplyHitStun(e,1,nil,2));near(e.LODHitStunUntil,10.90);near(e.LODNextHitStun,10.96)
end)
check('Gordon deadline and callback order retained',function()
    local e=actor();e.LODArchetypeId='warden'
    LOD.Warden={HitStunDeadline=function() return 10.12 end,Interrupt=noop,
        OnTellHitStun=function(_,v) v.sequence=2;v.cycle=.03 end}
    assert(F:ApplyHitStun(e));near(e.LODHitStunUntil,10.12)
    assert(e.sequence==2);near(e.cycle,.03);safeWrites(e)
    now=10.2;assert(not F:ApplyHitStun(e))
end)
check('interrupt identity and attack recovery still reach canonical owners',function()
    local e=actor();local token,attacker={},{};e.LODSoldierBurst={};e.LODBioBlast={}
    LOD.EnemyRoster={Definitions={soldier=true},Interrupt=function(_,v,event,source)
        assert(v==e and event==token and source==attacker);v.interrupted=true end}
    assert(F:ApplyHitStun(e,1,attacker,nil,nil,token));assert(e.interrupted)
    assert(not e.LODSoldierBurst and not e.LODBioBlast and e.LOD_SoldierTelegraph==false)
    near(e.LODNextAttack,10.40);near(e.LODNextBioCharge,10.65)
end)
check('dead and latched enemies still reject living stun',function()
    local e=actor();e.LODDead=true;assert(not F:ApplyHitStun(e))
    e.LODDead=false;e.LODDeadcrabState='latched';assert(not F:ApplyHitStun(e));assert(#e.writes==0)
end)
check('lethal transition is safe immediately and on deferred death hook',function()
    local e=actor();actors={e};assert(F:ApplyHitStun(e));e.LODDead=true
    fire('LOD_HostileDeathApplyPose',e);safeWrites(e);assert(e.sequence==1);near(e.cycle,.97)
    fire('OnNPCKilled',e);flush();now=11;fire('Think');safeWrites(e)
    assert(e.LODFrozenHurtMode=='death' and e.rate==0);near(e.cycle,.97)
end)
check('full-body death pose keeps original sampled cycles',function()
    local e=actor();e.named.pain=5;e.LODDead=true
    fire('LOD_HostileDeathApplyPose',e);assert(e.sequence==5);near(e.cycle,.48)
    fire('OnNPCKilled',e);flush();near(e.cycle,.50);safeWrites(e)
end)
check('removed or not-dead bodies ignore deferred death callbacks',function()
    local e=actor();fire('OnNPCKilled',e);flush();assert(#e.writes==0)
    e.LODDead=true;fire('OnNPCKilled',e);e.valid=false;flush();assert(#e.writes==0)
end)
check('model replacement cannot replay an old model-local hurt ID',function()
    local e=actor();e.named.pain=5;actors={e};assert(F:ApplyHitStun(e));assert(e.sequence==5)
    e.writes={};e.model='replacement.mdl';e.metadata[5].flags=4;e.named.pain=nil
    fire('Think');safeWrites(e);assert(e.sequence==2 and e.LODFrozenHurtModel==e.model)
end)
print(string.format('HOSTILE_HURT_POSE %d passed; %d failed',passed,failed))
assert(failed==0,'hurt-pose regression failure')
