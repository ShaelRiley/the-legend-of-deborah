-- Production backpedal/SetupMove regression, including map and analog composition.
local function noop() end
local hooks, receivers, timers = {}, {}, {}
local now, permitted, mapless = 10, true, false
local magicState = {magic = 100}
MOVETYPE_WALK = 2
IN_JUMP = 2
local actor = {alive = true, grounded = true, mode = MOVETYPE_WALK, water = 0}
function actor:GetMoveType() return self.mode end
function actor:OnGround() return self.grounded end
function actor:WaterLevel() return self.water end
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
    'sv_rpg_gate_e_map_movement','sv_rpg_gate_e_backpedal','sv_minimap_magic'}) do assert(loadfile(root..name..'.lua'))() end
local cps, effects, rules = LOD.CharacterProgressionSystem, LOD.RPG.FeatEffectSystem, LOD.RPGAbilityRules
local state = cps:NewProgressionState('test','hero')
state.baseAbilities = {str=10,dex=14,con=10,int=17,wis=10,cha=10}
state.classId = 'fighter'
state.primaryAbility = 'str'
state.secondaryAbilities = {'con','int'}
LOD.RunManager.GetPlayerState = function() return {progressionState=state} end
local function near(a,b) assert(math.abs(a-b)<0.000001,tostring(a)..' != '..tostring(b)) end
local function move(forward,side,cap,jump)
    local m={forward=forward,side=side,speed=cap or 200,client=cap or 200,vertical=320}
    function m:GetForwardSpeed() return self.forward end
    function m:GetSideSpeed() return self.side end
    function m:SetForwardSpeed(v) self.forward=v end
    function m:SetSideSpeed(v) self.side=v end
    function m:GetMaxSpeed() return self.speed end
    function m:GetMaxClientSpeed() return self.client end
    function m:SetMaxSpeed(v) self.speed=v end
    function m:SetMaxClientSpeed(v) self.client=v end
    function m:KeyDown() return jump == true end
    hooks.LOD_RPG_GateD_Movement(actor,m)
    return m
end
cps:_RecomputeProgressionState(state)
near(move(-100,0).speed,208)
state.featIds={'INT_WAS_DEBORAH'}
cps:_RecomputeProgressionState(state)
for _,cap in ipairs({100,200,400}) do
    local m=move(-100,50,cap)
    near(m.speed,cap*1.04*1.25); near(m.client,m.speed)
    near(m.forward,-125); near(m.side,62.5); assert(m.vertical==320)
end
near(move(100,0).speed,208); near(move(0,100).speed,208)
near(move(0,0).speed,208)
-- Low analog input scales along with cap, maintaining desired-vector fraction.
local analog=move(-10,5)
near(analog.forward,-12.5); near(analog.side,6.25)
actor.grounded=false; near(move(-100,50).speed,208); actor.grounded=true
actor.mode=9; near(move(-100,50).speed,208); actor.mode=MOVETYPE_WALK
actor.water=2; near(move(-100,50).speed,208); actor.water=0
near(move(-100,50,200,true).speed,208)
actor.alive=false; near(move(-100,50).speed,200); actor.alive=true
state.featIds={'INT_WAS_DEBORAH','INT_WORLD_WALKER_1','INT_GLOBETROTTER_2','INT_MIND_STRIDER_3'}
cps:_RecomputeProgressionState(state)
receivers.LOD_MapMagicState(0,actor)
near(move(-100,50).speed,200*1.04*1.75*1.25)
near(move(100,50).speed,200*1.04*1.75)
requestedOpen=false; receivers.LOD_MapMagicState(0,actor)
near(move(-100,50).speed,200*1.04*1.25)
state.featIds={}; cps:_RecomputeProgressionState(state)
near(move(-100,50).speed,208)
local def=LOD.RPG.IdentityCatalog.OrdinaryFeats.INT_WAS_DEBORAH
state.featQualificationAbilities.int=12; assert(not cps:_FeatEligible({},state,def))
state.featQualificationAbilities.int=13; assert(cps:_FeatEligible({},state,def))
local ok,errors=effects:ValidateBackpedal(); assert(ok,table.concat(errors,'; '))
print('backpedal PASS: acquisition/removal, INT gate, backward/diagonal, analog, walk/run caps, DEX/map composition, forward/strafe/idle/air/jump/ladder/swim/death exclusions')
