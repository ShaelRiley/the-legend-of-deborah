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
