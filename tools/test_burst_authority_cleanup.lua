-- Execute canonical weapon bursts, including injected engine/hook failures.
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local function noop() end
local clock=100
CurTime=function() return clock end
IsValid=function(v) return type(v)=='table' and v.valid==true end
isfunction=function(v) return type(v)=='function' end
isstring=function(v) return type(v)=='string' end
math.Clamp=function(v,a,b) return math.max(a,math.min(b,v)) end
math.Rand=function() return 0 end
local vector={GetNormalized=function(self) return self end}
vector_origin={}; Angle=function() return {} end
local hooks={}
hook={Add=function(e,n,f) hooks[e]=hooks[e] or {}; hooks[e][n]=f end}
timer={Create=noop}; concommand={Add=noop}
local errors=0
ErrorNoHalt=function() errors=errors+1 end
local bonus,aimCalls=0,0
LOD={CombatRolls={Stats={},_RNG=function() return {Int=function() return 1 end} end},
    RPGAbilityRules={BurstBonusRounds=function() return bonus end},
    UniversalAim={CommitPrimaryAttack=function() aimCalls=aimCalls+1; return 2 end}}
dofile(root..'sv_magnum_super_explosive.lua')
dofile(root..'sv_player_weapon_specials.lua')
local mag=LOD.MagnumSuperExplosive
local weapon={valid=true,clip=1,class='weapon_357',GetMaxClip1=function() return 6 end,
    Clip1=function(self) return self.clip end,SetClip1=function(self,n) self.clip=n end,
    GetClass=function(self) return self.class end,SendWeaponAnim=noop,EmitSound=noop,GetPrimaryAmmoType=function() return 1 end}
local ply={valid=true,hp=100,alive=true,IsPlayer=function() return true end,Alive=function(self) return self.alive end,
    Health=function(self) return self.hp end,GetMaxHealth=function() return 100 end,
    GetActiveWeapon=function() return weapon end,GetAimVector=function() return vector end,
    GetShootPos=function() return vector end,SetAnimation=noop,MuzzleFlash=noop,ViewPunch=noop,
    LagCompensation=function(self,on) self.lag=on end}
local fired=0
function ply:FireBullets(b)
    fired=fired+1
    hooks.EntityFireBullets.LOD_MagnumCylinderBurst(self,b)
end
local function trigger(clip,rank)
    weapon.clip=clip; bonus=rank; mag.Bursts[ply]=nil; fired=0
    hooks.EntityFireBullets.LOD_MagnumCylinderBurst(ply,{Dir=vector})
    return mag.Bursts[ply]
end
local function drain()
    for i=1,8 do clock=clock+.1; hooks.Think.LOD_MagnumCylinderBurstThink() end
end
for rank=0,3 do
    for clip=0,1 do
        local burst=assert(trigger(clip,rank))
        local authored=clip==1 and 2 or 3
        assert(burst.remaining==authored-1+rank and burst.aimMultiplier==2)
        assert(burst.finalBurstCount==authored+rank)
        drain()
        assert(fired==authored-1+rank and weapon.clip==clip and not mag.Bursts[ply],
            'authored follow-ups plus one Burster contribution, without more ammo consumption')
        assert(not weapon.LODMagnumInjectedBurst and ply.lag==false)
    end
end
assert(not trigger(3,3),'ordinary healthy chamber is not promoted to a Burster event')
ply.hp=30
local burst=assert(trigger(3,3))
assert(burst.remaining==1 and burst.burstBonusRounds==0,'low-health bonus alone does not qualify for Burster')
-- The real firing seam throws; no injected flag/lag state or free preserved ammo survives.
ply.FireBullets=function() error('injected bullet hook failure') end
burst=assert(trigger(0,1)); assert(burst.preserveFinal)
drain()
assert(errors==1 and not weapon.LODMagnumInjectedBurst and ply.lag==false and weapon.clip==0)
assert(not mag.Bursts[ply],'failed burst cancels rather than retrying possibly applied damage')
weapon.class='weapon_ar2'
local oldEvent={}; ply.LODCommittedAttackEvent=oldEvent
assert(not LOD.PlayerWeaponSpecials:FireAR2Round(ply,{weapon=weapon,ammoCommitted=1,direction=vector,attackEvent={}}))
assert(errors==2 and ply.lag==false and ply.LODCommittedAttackEvent==oldEvent,
    'AR2 restores its previous attack context and lag compensation after a thrown hook')
print('BURST_AUTHORITY_CLEANUP_PASS: all ranks/chambers, Aim, low-health exclusion and failure cleanup')
