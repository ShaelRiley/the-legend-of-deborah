local env=dofile('tools/test_enemy_update.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
ACT_IDLE,ACT_MELEE_ATTACK1,ACT_MELEE_ATTACK2,ACT_RANGE_ATTACK1,ACT_RANGE_ATTACK2=10,11,12,13,14
ACT_RUN_AIM_RIFLE,ACT_IDLE_ANGRY_SMG1,ACT_FLY=15,16,17
dofile(root..'sv_hostile_animation.lua')
local A=LOD.HostileAnimation
local function model(name,attackName)
    local e={model=name,seq=0,rate=1,queries=0,names={[0]='reference',[1]='idle',[2]=attackName,[3]='walk'}}
    function e:GetModel() return self.model end
    function e:GetSequenceName(seq) return self.names[seq] or '' end
    function e:GetSequence() return self.seq end
    function e:GetPlaybackRate() return self.rate end
    function e:SetPlaybackRate(rate) self.rate=rate end
    function e:ResetSequence(seq) assert(A:Valid(self,seq));self.seq=seq end
    function e:LookupSequence(name)
        self.queries=self.queries+1
        for i,n in pairs(self.names) do if name==n then return i end end
        return -1
    end
    function e:SelectWeightedSequence(act)
        self.queries=self.queries+1
        -- Unsupported attack enums can resolve to a valid idle sequence.
        return act==ACT_WALK and 3 or 1
    end
    function e:GetSequenceList() return {'reference','idle',self.names[2],'walk'} end
    return e
end
for _,name in ipairs({'melee_gunhit','swing','attack1','bite','jumpattack','melee_attack01'}) do
    local e=model('stock '..name,name)
    assert(A:Apply(e,ACT_MELEE_ATTACK1,true) and e.seq==2,'melee silently selected idle: '..name)
    local q=e.queries;A:Apply(e,ACT_MELEE_ATTACK1,true)
    assert(e.queries==q,'attack resolution repeated model scan')
end
for _,name in ipairs({'fire','shoot','zapattack','laserfire'}) do
    local e=model('stock '..name,name)
    assert(A:Apply(e,ACT_RANGE_ATTACK1,true) and e.seq==2,'ranged silently selected idle: '..name)
end
local e=model('no skeletal strike','ragdoll')
assert(A:Apply(e,ACT_MELEE_ATTACK1,true) and e.seq==1,'device selected invalid body sequence')
e.model='changed';e.names[2]='swing'
assert(A:Apply(e,ACT_MELEE_ATTACK1,true) and e.seq==2,'model swap retained idle attack cache')

-- The actual base melee method must request an attack, rather than just apply
-- HP damage while the most recent walk animation loops indefinitely.
local path='gamemodes/legend_of_deborah/entities/entities/lod_hostile/init.lua'
local f=assert(io.open(path));local src=f:read('*a');f:close()
local cls={};assert(load('local ENT=...\n'..assert(src:match('(function ENT:_MeleeAttack%(target%)%s.-\nend)'))))(cls)
local h=env.actor(1);h.LODArchetypeId='runner';h.LODConfig={meleeDamage=5,meleeRange=90,meleeCooldown=1}
local p=env.actor(1);p.LODHostile=false;p.player=true;p.TakeDamage=function(self,n) self.damage=(self.damage or 0)+n end
h._HasLineOfSight=function() return true end
h._SetActivity=function(self,activity,force) self.activity=activity;self.forced=force end
assert(cls._MeleeAttack(h,p) and h.activity==ACT_MELEE_ATTACK1 and h.forced and p.damage==5,'native melee had no attack animation')
assert(not cls._MeleeAttack(h,p) and p.damage==5,'animation repair bypassed cooldown')
print('ENEMY_ATTACK_ANIMATION_PASS named stock melee/ranged, activity-idle rejection, bounded caches/model swaps, safe device pose, actual native melee request')

-- Native NextBots expose their owned Lua table separately from entity indexing.
-- Keep value/invalidation coverage after rejecting the native-table fast path.
local originalType,originalFindMetaTable=type,FindMetaTable
local nativeTables=setmetatable({},{__mode="k"})
local signatureReads=0
local signatureKeys={LODAnimationModel=true,LODAnimationRazor=true,LODAnimationHold=true,LODAnimationCache=true}
local native=model('native animation cache','swing')
local proxy=setmetatable({}, {
    __index=function(_,key) if signatureKeys[key] then signatureReads=signatureReads+1 end;return native[key] end,
    __newindex=function(_,key,value)native[key]=value end
})
nativeTables[proxy]=native
_G.type=function(value) if value==proxy then return 'NextBot' end;return originalType(value) end
FindMetaTable=function(name) if name=='Entity' then return {GetTable=function(actor)return nativeTables[actor]end} end end
dofile(root..'sv_hostile_animation.lua')
assert(A:Resolve(proxy,ACT_WALK)==3,'native cache did not populate')
signatureReads=0
assert(A:Resolve(proxy,ACT_WALK)==3,'owned animation cache changed its sequence')
native.LODAnimationCache[ACT_WALK]=false
assert(A:Resolve(proxy,ACT_WALK)==nil,'cached unsupported animation was retried')
native.LODAnimationCache={[ACT_WALK]=2}
assert(A:Resolve(proxy,ACT_WALK)==2,'live cache replacement was ignored')
native.model='native replacement';native.names[2]='bite'
assert(A:Resolve(proxy,ACT_WALK)==3,'model replacement retained stale cache')
native.LODArchetypeId='razor';native.model='models/manhack.mdl'
A:Resolve(proxy,ACT_IDLE)
assert(native.LODAnimationRazor==true,'razor signature did not invalidate')
native.LODArchetypeId='runner';native.model='models/player/skeleton.mdl';native.LODSkeletonHero=true
native.LODProgressionState={classId='wizard'}
A:Resolve(proxy,ACT_IDLE)
assert(native.LODAnimationRazor==false and native.LODAnimationHold=='_MAGIC','live skeleton hold change was missed')
native.LODFallenHero={weaponClass='weapon_pistol'};A:Resolve(proxy,ACT_IDLE)
assert(native.LODAnimationHold=='_PISTOL','live copied weapon hold was missed')
native.LODSkeletonHero=nil;native.model='native inherited fallback';A:Resolve(proxy,ACT_WALK)
native.LODAnimationCache[ACT_WALK]=2;nativeTables[proxy]={};signatureReads=0
assert(A:Resolve(proxy,ACT_WALK)==2 ,'inherited cache did not retain original entity lookup')
nativeTables[proxy]=nil
assert(A:Resolve(proxy,ACT_WALK)==2,'missing native table did not retain original resolver')
_G.type,FindMetaTable=originalType,originalFindMetaTable
print('ANIMATION_CACHE_INVALIDATION_PASS owned hit, false/replaced cache, model/razor/skeleton/copied hold, inherited/missing fallback')
