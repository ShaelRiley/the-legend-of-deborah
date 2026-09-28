-- Production animation resolver, Motion V2 BodyUpdate, hurt and death hooks.
-- Native model APIs expose only player activities; NPC requests return the
-- reference pose. This is a headless contract test, not Source visual proof.
local env=dofile('tools/test_enemy_update.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local noop=function() end
AddCSLuaFile,include=noop,noop
timer.Create,timer.Remove=noop,noop
ACT_IDLE,ACT_RUN_AIM_RIFLE,ACT_RANGE_ATTACK1,ACT_RANGE_ATTACK_SMG1=20,21,22,23
ACT_MELEE_ATTACK1,ACT_DIESIMPLE,ACT_DIEBACKWARD,ACT_GMOD_DEATH=24,25,26,27
ACT_IDLE_ANGRY_SMG1=28
local names={[0]='reference',[90]='idle_smg1'} -- tempting additive idle fallback
names[ACT_GMOD_DEATH]='death_01'
local serial=100
for _,suffix in ipairs({'','_FIST','_MAGIC','_SMG1','_PISTOL','_REVOLVER','_AR2','_SHOTGUN','_CROSSBOW','_MELEE'}) do
    for _,role in ipairs({'IDLE','WALK','RUN','GESTURE_RANGE_ATTACK'}) do
        serial=serial+1
        _G['ACT_HL2MP_'..role..suffix]=serial
        names[serial]=string.lower(role..suffix)
    end
end
dofile(root..'sv_hostile_animation.lua')
local A=LOD.HostileAnimation
ENT={};dofile('gamemodes/legend_of_deborah/entities/entities/lod_hostile/init.lua')
local class=ENT
scripted_ents.GetStored=function() return {t=class} end
dofile(root..'sv_hostile_motion_v2.lua')
assert(class.LODMotionV2Patched)

local function actor(kind,weapon)
    local archetype=kind=='rogue' and 'soldier' or kind=='wizard' and 'arccaster' or 'runner'
    local e=setmetatable({LODHostile=true,LODSkeletonHero=true,LODArchetypeId=archetype,
        LODProgressionState={classId=kind},LODConfig={activity=ACT_RUN},
        model='models/player/skeleton.mdl',sequence=0,rate=1,pose={},frames=0,
        resets=0,queries=0,gestures=0,LODAnimationCache={}}, {__index=class})
    if weapon then e.LODFallenHero={weaponClass=weapon} end
    function e:GetModel() return self.model end
    function e:GetSequenceName(seq) return names[seq] or '' end
    function e:SelectWeightedSequence(act)
        self.queries=self.queries+1
        if self.missing and self.missing[act] then return -1 end
        return names[act] and act or 0
    end
    function e:LookupSequence(name) return name=='idle_smg1' and 90 or -1 end
    function e:GetSequenceList() return {'reference','idle_smg1'} end
    function e:GetSequence() return self.sequence end
    function e:ResetSequence(seq)
        assert(A:Valid(self,seq) and seq~=90,'invalid or additive idle used as body')
        assert(not names[seq]:find('gesture',1,true),'attack gesture replaced the body')
        self.sequence=seq;self.resets=self.resets+1
    end
    e.SetSequence=e.ResetSequence
    function e:GetPlaybackRate() return self.rate end
    function e:SetPlaybackRate(rate) self.rate=rate end
    e.SetVelocity=noop
    function e:SetPoseParameter(name,value) self.pose[name]=value end
    function e:SetCycle(cycle) self.cycle=cycle end
    function e:FrameAdvance() self.frames=self.frames+1 end
    function e:GetVelocity() return vector_origin end
    function e:BodyMoveXY() error('native velocity must not drive kinematic player animations') end
    function e:AddGestureSequence(seq,autokill)
        assert(names[seq]:find('gesture',1,true) and autokill)
        self.gestures=self.gestures+1;self.lastGesture=seq
    end
    return e
end

for kind,suffix in pairs({fighter='_FIST',rogue='_SMG1',wizard='_MAGIC'}) do
    local e=actor(kind)
    e:_SetActivity(ACT_IDLE,true)
    assert(e.sequence==_G['ACT_HL2MP_IDLE'..suffix],kind..' spawned in an NPC pose')
    e.LODMotionSpeed=190
    e:BodyUpdate()
    assert(e.sequence==_G['ACT_HL2MP_RUN'..suffix] and e.pose.move_x==1 and e.pose.move_y==0)
    assert(e.frames==1 and e:GetVelocity():LengthSqr()==0,'movement depended on native velocity')
    local queries,resets=e.queries,e.resets
    for _=1,60 do A:Move(e);e:BodyUpdate() end
    assert(e.queries==queries and e.resets==resets,'steady motion re-resolved/restarted animation')
    e:_SetActivity(ACT_WALK)
    assert(e.sequence==_G['ACT_HL2MP_WALK'..suffix])
    LOD.HostileMotionV2:Stop(e);e:BodyUpdate()
    assert(e.sequence==_G['ACT_HL2MP_IDLE'..suffix] and e.pose.move_x==0,'stopped skeleton kept walking')
    e:_SetActivity(ACT_IDLE_ANGRY_SMG1);e:BodyUpdate()
    local idleResets=e.resets
    for _=1,60 do e:_SetActivity(ACT_IDLE_ANGRY_SMG1);e:BodyUpdate() end
    assert(e.resets==idleResets,'equivalent NPC idle requests restarted the same player cycle')
    e:_SetActivity(ACT_RANGE_ATTACK1,true)
    assert(e.gestures==1 and e.lastGesture==_G['ACT_HL2MP_GESTURE_RANGE_ATTACK'..suffix])
    e:BodyUpdate();e:BodyUpdate()
    assert(e.gestures==1,'BodyUpdate replayed the attack gesture')
    e:_SetActivity(ACT_MELEE_ATTACK1,true)
    assert(e.gestures==2)
    e.rate=0;e.LODHitStunUntil=11;e.LODMotionSpeed=190
    env.setTime(10);e:BodyUpdate()
    assert(e.rate==0 and e.pose.move_x==0,'hit-stun restarted player animation')
    env.setTime(12);e:BodyUpdate()
    assert(e.rate==1 and e.pose.move_x==1,'recovery left skeleton frozen')
    LOD.RunManager.State.SimulationFrozen=true;e:BodyUpdate()
    assert(e.pose.move_x==0,'frozen world retained travel blend')
    LOD.RunManager.State.SimulationFrozen=false
    e.LODDead=true;e:_SetActivity(ACT_DIESIMPLE,true)
    local corpse=e.sequence;e:BodyUpdate()
    assert(corpse==ACT_GMOD_DEATH and e.sequence==corpse,'body update overwrote the corpse')
    assert(not A:PlayerAttack(e),'dead skeleton added attack gesture')
end

local fallen=actor('fighter','weapon_pistol')
fallen:BodyUpdate();assert(fallen.sequence==ACT_HL2MP_IDLE_PISTOL)
fallen.LODFallenHero.weaponClass='weapon_ar2';fallen:BodyUpdate()
assert(fallen.sequence==ACT_HL2MP_IDLE_AR2,'copied weapon switch retained stale hold cache')
A:PlayerAttack(fallen);assert(fallen.lastGesture==ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2)
fallen.LODFallenHero.weaponClass='weapon_lod_crowbar';fallen:BodyUpdate()
assert(fallen.sequence==ACT_HL2MP_IDLE_MELEE)
fallen.LODFallenHero.weaponClass='unsupported';fallen:BodyUpdate()
assert(fallen.sequence==ACT_HL2MP_IDLE,'unknown copied weapon must use safe player base')

local fallback=actor('fighter')
fallback.missing={[ACT_HL2MP_IDLE_FIST]=true}
fallback:BodyUpdate();assert(fallback.sequence==ACT_HL2MP_IDLE)
fallback.model='models/zombie/fast.mdl'
A:Resolve(fallback,ACT_RUN) -- old native model cache must not survive the swap
fallback.model='models/player/skeleton.mdl';fallback.LODMotionSpeed=180;fallback:BodyUpdate()
assert(fallback.sequence==ACT_HL2MP_RUN_FIST)

-- Freeze existing valid player bases, never an additive NPC flinch. A missing
-- current sequence is repaired through the same safe player idle resolver.
hook.Remove=noop
dofile(root..'sv_hostile_hurt_pose.lua')
fallback.LODMotionSpeed=0;fallback:BodyUpdate()
local idle=fallback.sequence
ACT_BIG_FLINCH,ACT_FLINCH_CHEST,ACT_SMALL_FLINCH,ACT_FLINCH_HEAD=40,41,42,43
assert(LOD.M3HitFeedback:ApplyHitStun(fallback),'real hit-stun path rejected skeleton')
assert(fallback.sequence==idle and fallback.rate==0)
fallback.sequence=0
assert(LOD.HostileHurtPose:Freeze(fallback,.44,'stun') and fallback.sequence==idle)
dofile(root..'sv_hostile_death_pose.lua')
fallback.LODDead=true;fallback:_SetActivity(ACT_DIESIMPLE,true)
env.hooks.LOD_HostileDeathPainPose(fallback)
assert(fallback.sequence==ACT_GMOD_DEATH and fallback.rate==0)

local npc=actor('fighter');npc.LODSkeletonHero=nil
local npcQueries=npc.queries
npc:BodyUpdate()
assert(npc.pose.move_yaw==0 and npc.pose.move_x==nil and npc.frames==1)
assert(npc.queries==npcQueries,'ordinary NPC animation path changed')
print('SKELETON_ANIMATION_PASS stock player activities; all classes/copy holds; kinematic 9-way poses; cache/model swaps; overlay attacks; stun/recovery/death; NPC body unchanged')
