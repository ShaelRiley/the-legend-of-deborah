local now=10
function CurTime() return now end
function IsValid(a) return type(a)=='table' and a.valid~=false end
function math.Clamp(v,a,b) return math.max(a,math.min(b,v)) end
vector_origin={}
DMG_BULLET,DMG_BUCKSHOT,DMG_CLUB,DMG_SLASH,DMG_FALL,DMG_CRUSH=1,2,3,4,5,6
local world={};game={GetWorld=function() return world end}
util={AddNetworkString=function() end};net={Start=function() end,Send=function() end}
hook={Add=function() end}
local draws,reports=0,{}
local rngValue=0.1
LOD={Equipment={BlockCap=.33},RunManager={State={Graph={},LevelSeed=1}},
    RPGAbilityRules={Stats={},ProgressionState=function(_,p) return p.state end,
        Derived=function(_,p) return p.state.derivedStats end},
    RPGStatusElements={DamageContext=function(_,info) return info.context end,
        AttachDamageContext=function(_,info,c) info.context=c end},
    CombatRolls={_RNG=function() return {Float=function() draws=draws+1;return rngValue end} end,
        _Send=function(_,_,_,text) reports[#reports+1]=text end,EntityDisplayName=function() return 'Hero' end}}
local function actor(id)
    return {id=id,state={equipmentBlockChanceContribution=.8,derivedStats={dodgeChanceContribution=.33}},
        IsPlayer=function() return true end,Alive=function() return true end,
        EmitSound=function() end,EntIndex=function(p) return p.id end}
end
local target,source=actor(1),actor(2)
local function hit(event,kind,context)
    local info={damage=10,context=context or {},kind=kind or DMG_BULLET}
    info.context.attackEvent=event
    function info:GetDamage() return self.damage end
    function info:SetDamage(d) self.damage=d end
    function info:SetDamageForce(f) self.force=f end
    function info:GetAttacker() return source end
    function info:IsDamageType(t) return t==self.kind end
    return info
end
local root='gamemodes/legend_of_deborah/gamemode/lod/'
dofile(root..'sv_rpg_dodge.lua');dofile(root..'sv_rpg_block.lua')
local R=LOD.RPGAbilityRules
R.DodgeMovement=function() return 0,100,200 end
assert(R:BlockChance(target)==.33,'33% hard cap')
local event={};local a=hit(event)
assert(not R:ApplyDodge(target,a));assert(R:ApplyBlock(target,a))
assert(a.damage==0 and a.force==vector_origin and a.context.blocked)
local initial=draws
for i=1,8 do assert(R:ApplyBlock(target,hit(event))) end
assert(draws==initial and #reports==2,'One event/pellet group, one report per participant')
rngValue=.8;event={};assert(not R:ApplyBlock(target,hit(event)))
initial=draws;rngValue=0
assert(not R:ApplyBlock(target,hit(event)) and draws==initial,'Failed result also cached')
for _,context in ipairs({{magic=true},{statusDamage=true},{environmental=true},{unavoidable=true},{wallCrush=true},{passiveDamage=true}}) do
    assert(not R:ApplyBlock(target,hit({},DMG_CLUB,context)))
end
assert(not R:ApplyBlock(target,hit({},DMG_FALL)))
assert(not R:ApplyBlock(target,hit({},999)))
assert(draws==initial,'Ineligible damage must not roll')
R.DodgeMovement=function() return 60,100,200 end
local dodged=hit({})
assert(R:ApplyDodge(target,dodged));initial=draws
assert(not R:ApplyBlock(target,dodged) and draws==initial,'Successful Dodge suppresses Block')
R.DodgeMovement=function() return 0,100,200 end
LOD.RunManager.State.LevelSeed=2
assert(R:ApplyBlock(target,hit(event)) and draws==initial+1,'New level invalidates cached outcome')
local old=target.state;target.state={equipmentBlockChanceContribution=0,derivedStats={}}
assert(not R:ApplyBlock(target,hit(event)),'New character must not inherit block')
print('EQUIPMENT_BLOCK_PASS: cap, Dodge order, per-event success/failure cache, exclusions, lifecycle, Die Log reports')
