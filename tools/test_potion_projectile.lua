-- Production swept-projectile impact/lifecycle semantics, independently of rendering.
local now=0
function CurTime() return now end
function IsValid(e) return type(e)=="table" and e.valid~=false end
function math.Clamp(v,a,b) return math.max(a,math.min(b,v)) end
function Color(...) return {...} end
local vmt={}
function Vector(x,y,z) return setmetatable({x=x,y=y,z=z},vmt) end
vmt.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
vmt.__mul=function(a,b) return Vector(a.x*b,a.y*b,a.z*b) end
MASK_SHOT,MOVETYPE_NONE,SOLID_NONE=1,0,0
function GetConVar() return {GetFloat=function() return 600 end} end
function AddCSLuaFile() end
function include() end
local effects, heals, traceResult=0,0,nil
util={SpriteTrail=function() end,Effect=function() effects=effects+1 end,
    TraceHull=function(options)
        assert(options.mask==MASK_SHOT and #options.filter==2)
        return traceResult or {Hit=false,HitPos=options.endpos}
    end}
function EffectData() return {SetOrigin=function() end,SetScale=function() end} end
local itemState={}
local ps={equipment=itemState}
local caster={alive=true,GetAimVector=function() return Vector(1,0,0) end}
local ally={IsPlayer=function() return true end,hero=true}
LOD={Equipment={Definitions={healing_potion={model="bottle",effect="heal",amount=25}},
    ThrowSpeed=700,ThrowLift=120,ProjectileLifetime=5,
    CanAct=function(_,p) return IsValid(p) and p.alive end,
    Heal=function(_,source,target,amount)
        assert(source==caster and amount==25)
        if target.hero then heals=heals+1 end
    end},RunManager={State={LevelSeed=1},GetPlayerState=function() return ps end}}
ENT={}
dofile("gamemodes/legend_of_deborah/entities/entities/lod_potion_projectile/init.lua")
local function projectile()
    local e=setmetatable({pos=Vector(0,0,0),LODPotionDefinition="healing_potion",LODPotionCaster=caster,
        LODPotionState=itemState,LODPotionRun=LOD.RunManager.State,LODPotionLevelSeed=LOD.RunManager.State.LevelSeed}, {__index=ENT})
    function e:SetModel() end
    function e:SetModelScale() end
    function e:SetColor() end
    function e:SetMoveType() end
    function e:SetSolid() end
    function e:GetPos() return self.pos end
    function e:SetPos(p) self.pos=p end
    function e:NextThink() end
    function e:EmitSound() end
    function e:Remove() self.valid=false end
    e:Initialize()
    return e
end
local p=projectile()
now=.05;p:Think()
assert(p.pos.x==35 and p.pos.z==6 and p.LODVelocity.z==90,"Ballistic sweep advances and applies gravity")
traceResult={Hit=true,HitPos=Vector(40,0,0),Entity=ally}
now=.1;p:Think();p:Think()
assert(heals==1 and effects==1 and p.valid==false,"One direct ally impact, no repeated healing")
traceResult={Hit=true,HitPos=Vector(30,0,0),Entity={IsPlayer=function() return false end}}
p=projectile();now=.15;p:Think()
assert(heals==1 and p.valid==false,"Wall collision destroys bottle without healing through cover")
traceResult={Hit=true,HitPos=Vector(30,0,0),Entity={IsPlayer=function() return true end,hero=false}}
p=projectile();now=.2;p:Think()
assert(heals==1,"An enemy player is not an eligible ally")
traceResult=nil
p=projectile();LOD.RunManager.State.LevelSeed=2;now=.3;p:Think()
assert(p.valid==false and heals==1,"No effects across dungeon transition")
p=projectile();caster.alive=false;p:Think();assert(p.valid==false)
caster.alive=true
p=projectile();ps.equipment={};p:Think();assert(p.valid==false,"No effects for replacement character state")
ps.equipment=itemState
p=projectile();now=10;p:Think();assert(p.valid==false,"Bounded lifetime")
print("POTION_PROJECTILE_PASS: swept arc, direct ally impact, one-shot resolution, cover and lifecycle expiry")
