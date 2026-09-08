-- Production map authorization, net close/drain lifecycle, progression and movement.
local function noop() end
local hooks, receivers, timers = {}, {}, {}
local now, permitted, mapless = 10, true, false
local magicState = {magic = 100}
local actor = {alive = true}
function actor:IsPlayer() return true end
function actor:Alive() return self.alive end
function actor:SetNW2Bool() end
function IsValid(v) return v == actor end
function CurTime() return now end
function GetConVar(name) if name == 'lod_mapless' then return {GetBool = function() return mapless end} end end
function math.Clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end
function table.Copy(t) local r = {} for k,v in pairs(t) do r[k] = type(v)=='table' and table.Copy(v) or v end return r end
function ErrorNoHalt(s) error(s) end
util = {AddNetworkString = noop}
local requestedOpen = true
net = {Receive = function(n,f) receivers[n]=f end, ReadBool = function() return requestedOpen end,
    Start = noop, WriteString = noop, Send = noop}
concommand = {Add = noop}
hook = {Add = function(n,id,f) hooks[id]=f end}
timer = {Create = function(n,_,__,f) timers[n]=f end, Simple = noop}
GM = {}
LOD = {RunManager = {State = {Failed=false}},
    MinimapServer = {CanUse = function() return permitted end},
    Magic = {_EnsureState = function() return magicState end, _Sync = noop},
    RPGValidation = {Run = function() return true, {} end},
    RPGAbilityRules = {}}
local root = 'gamemodes/legend_of_deborah/gamemode/lod/'
for _, name in ipairs({'sh_rpg_schema','sv_rpg_gate_b_catalog','sv_rpg_gate_c_catalog',
    'sv_rpg_gate_e_feats','sv_character_progression','sv_rpg_gate_d',
    'sv_rpg_gate_e_map_movement','sv_rpg_gate_e_quantum','sv_minimap_magic'}) do assert(loadfile(root..name..'.lua'))() end
local cps, effects, rules = LOD.CharacterProgressionSystem, LOD.RPG.FeatEffectSystem, LOD.RPGAbilityRules
local state = cps:NewProgressionState('test','hero')
state.baseAbilities = {str=10,dex=14,con=10,int=17,wis=10,cha=10}
state.classId = 'fighter'
state.primaryAbility = 'str'
state.secondaryAbilities = {'con','int'}
LOD.RunManager.GetPlayerState = function() return {progressionState=state} end
local ps={progressionState=state,magic=100,characterId='male'}
LOD.RunManager.GetPlayerState=function() return ps end
local vec=setmetatable({}, {__add=function(a) return a end,__mul=function(a) return a end})
function vec:GetNormalized() return self end
vector_origin={}
function actor:GetAimVector() return vec end
function actor:GetShootPos() return vec end
function actor:EmitSound() end
function actor:SetNW2Float() end
function actor:SetNW2Int() end
function actor:EntIndex() return 1 end
file={Exists=function() return false end}
net.WriteEntity=noop; net.WriteVector=noop; net.Broadcast=noop
hook.Run=noop
assert(loadfile(root..'sv_magic.lua'))()
local magic=LOD.Magic
local ids={'INT_QUANTUM_MATHEMATICS_1','INT_QUANTUM_MECHANICS_2','INT_QUANTUM_MASTERY_3'}
local costs={30,27,24,21}
for rank=0,3 do
    state.featIds={}
    for i=1,rank do state.featIds[i]=ids[i] end
    cps:_RecomputeProgressionState(state)
    local before=state.derivedStats.magicRegenMultiplier
    local cost=costs[rank+1]
    assert(rules:OffensiveMagicCost(actor,30)==cost)
    now=now+2; ps.magic=cost-0.01
    local casts=magic.Stats.casts
    assert(not magic:CastForceShout(actor))
    assert(ps.magic==cost-0.01 and magic.Stats.casts==casts)
    ps.magic=cost
    effects.QuantumStats[actor]={casts=0,base=0,cost=0,spent=0}
    assert(magic:CastForceShout(actor))
    assert(ps.magic==0)
    assert(effects.QuantumStats[actor].cost==cost and effects.QuantumStats[actor].casts==1)
    ps.magic=100
    assert(not magic:CastForceShout(actor)) -- rejected cooldown does not charge
    assert(ps.magic==100 and effects.QuantumStats[actor].casts==1)
    assert(state.derivedStats.magicRegenMultiplier==before)
end
-- Utility construction and unrelated player defense remain untouched.
assert(rules:UtilityMagicCostMultiplier(actor)==state.derivedStats.utilityMagicCostMultiplier)
local old=LOD.Magic; LOD.Magic=nil
state.featIds={}; state.featQualificationAbilities.int=17
assert(not cps:_FeatEligible({},state,LOD.RPG.IdentityCatalog.OrdinaryFeats[ids[1]]))
LOD.Magic=old
state.featQualificationAbilities.int=12
assert(not cps:_FeatEligible({},state,LOD.RPG.IdentityCatalog.OrdinaryFeats[ids[1]]))
state.featQualificationAbilities.int=17
assert(not cps:_FeatEligible({},state,LOD.RPG.IdentityCatalog.OrdinaryFeats[ids[3]]))
state.featIds={ids[1],ids[2]}
assert(cps:_FeatEligible({},state,LOD.RPG.IdentityCatalog.OrdinaryFeats[ids[3]]))
assert(effects:QuantumCost(1,.67)==1 and effects:QuantumCost(31,.67)==21)
local ok,errors=effects:ValidateQuantum(); assert(ok,table.concat(errors,'; '))
print('quantum PASS: live cast affordability/deduction, all ranks, replacement, rounding/minimum, no rejected-cast spend, unchanged cooldown/utility/regen, eligibility')
