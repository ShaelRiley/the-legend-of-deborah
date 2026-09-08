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
    'sv_rpg_gate_e_map_movement','sv_minimap_magic'}) do assert(loadfile(root..name..'.lua'))() end
local cps, effects, rules = LOD.CharacterProgressionSystem, LOD.RPG.FeatEffectSystem, LOD.RPGAbilityRules
local state = cps:NewProgressionState('test','hero')
state.baseAbilities = {str=10,dex=14,con=10,int=17,wis=10,cha=10}
state.classId = 'fighter'
state.primaryAbility = 'str'
state.secondaryAbilities = {'con','int'}
LOD.RunManager.GetPlayerState = function() return {progressionState=state} end
local ids = {'INT_WORLD_WALKER_1','INT_GLOBETROTTER_2','INT_MIND_STRIDER_3'}
local function near(a,b) assert(math.abs(a-b)<0.000001, tostring(a)..' != '..tostring(b)) end
local function open() requestedOpen=true; receivers.LOD_MapMagicState(0,actor) end
local function close() requestedOpen=false; receivers.LOD_MapMagicState(0,actor) end
for rank=0,3 do
    state.featIds={}
    for i=1,rank do state.featIds[i]=ids[i] end
    cps:_RecomputeProgressionState(state)
    close(); near(rules:MovementMultiplier(actor),1.04)
    open(); near(rules:MovementMultiplier(actor),1.04*(1+rank*.25))
end
-- Same SetupMove hook that scales walk/run speed; vertical velocity is untouched.
local move={speed=200,client=200,vertical=300}
function move:GetMaxSpeed() return self.speed end
function move:GetMaxClientSpeed() return self.client end
function move:SetMaxSpeed(v) self.speed=v end
function move:SetMaxClientSpeed(v) self.client=v end
hooks.LOD_RPG_GateD_Movement(actor,move)
near(move.speed,200*1.04*1.75); near(move.client,move.speed); assert(move.vertical==300)
-- Other actors cannot inherit this actor's open-map bonus.
near(rules:MovementMultiplier({}),1)
permitted=false; near(rules:MovementMultiplier(actor),1.04); permitted=true
mapless=true; near(rules:MovementMultiplier(actor),1.04); mapless=false
magicState.magic=0; near(rules:MovementMultiplier(actor),1.04); magicState.magic=100
LOD.RunManager.State.Failed=true; near(rules:MovementMultiplier(actor),1.04); LOD.RunManager.State.Failed=false
LOD.RunManager.State.SimulationFrozen=true; near(rules:MovementMultiplier(actor),1.04); LOD.RunManager.State.SimulationFrozen=false
now=12; near(rules:MovementMultiplier(actor),1.04); open()
actor.alive=false; near(rules:MovementMultiplier(actor),1.04); actor.alive=true
hooks.LOD_MinimapMagicDeathStop(actor); near(rules:MovementMultiplier(actor),1.04)
open(); close(); near(rules:MovementMultiplier(actor),1.04)
-- Drain remains the existing WIS-scaled map consumer and force-closes at zero.
magicState.magic=0.01; open(); now=now+.1; timers.LOD_MinimapMagicDrain()
assert(magicState.magic==0); assert(not LOD.MinimapMagic:IsOpen(actor))
near(rules:MovementMultiplier(actor),1.04)
-- Printed gates and prerequisite chain use the existing director.
state.featIds={}; state.featQualificationAbilities.int=12
assert(not cps:_FeatEligible({},state,LOD.RPG.IdentityCatalog.OrdinaryFeats[ids[1]]))
state.featQualificationAbilities.int=17
assert(not cps:_FeatEligible({},state,LOD.RPG.IdentityCatalog.OrdinaryFeats[ids[3]]))
state.featIds={ids[1],ids[2]}
assert(cps:_FeatEligible({},state,LOD.RPG.IdentityCatalog.OrdinaryFeats[ids[3]]))
local ok,errors=effects:ValidateMapMovement(); assert(ok,table.concat(errors,'; '))
print('map_movement PASS: ranks, DEX/SetupMove composition, actor isolation, close/death/access/mapless/failure/freeze/heartbeat/exhaustion, drain, prerequisites')
