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
    'sv_rpg_gate_e_map_movement','sv_rpg_gate_e_backpedal','sv_rpg_gate_e_strafe','sv_minimap_magic'}) do assert(loadfile(root..name..'.lua'))() end
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
local ids={'DEX_STRAFER_1','DEX_SIDELER_2','DEX_LATERAL_MOVER_3'}
local function realized(m)
    local n=math.sqrt(m.forward*m.forward+m.side*m.side)
    local cap=math.min(m.speed,m.client)
    local k=n>0 and math.min(1,cap/n) or 1
    return m.forward*k,m.side*k
end
for rank=0,3 do
    state.featIds={}
    for i=1,rank do state.featIds[i]=ids[i] end
    cps:_RecomputeProgressionState(state)
    local multiplier=1+rank*.11
    for _,f in ipairs({-10000,0,10000}) do
        for _,side in ipairs({-10000,10000}) do
            local m=move(f,side)
            local actualF,actualS=realized(m)
            local scale=208/math.sqrt(f*f+side*side)
            near(actualF,f*scale); near(actualS,side*scale*multiplier)
            assert(m.vertical==320)
        end
    end
    local af,as=realized(move(10,5))
    near(af,10); near(as,5*multiplier)
    near(move(10000,0).speed,208)
end
local baseline=208/math.sqrt(2)
actor.grounded=false
local f,s=realized(move(10000,10000)); near(f,baseline); near(s,baseline)
actor.grounded=true; actor.mode=9
f,s=realized(move(10000,10000)); near(f,baseline); near(s,baseline)
actor.mode=MOVETYPE_WALK; actor.water=2
f,s=realized(move(10000,10000)); near(f,baseline); near(s,baseline)
actor.water=0
f,s=realized(move(10000,10000,200,true)); near(f,baseline); near(s,baseline)
-- Map and backpedal compose before the lateral-only modifier.
state.featIds={'DEX_STRAFER_1','DEX_SIDELER_2','DEX_LATERAL_MOVER_3',
    'INT_WAS_DEBORAH','INT_WORLD_WALKER_1','INT_GLOBETROTTER_2','INT_MIND_STRIDER_3'}
cps:_RecomputeProgressionState(state)
receivers.LOD_MapMagicState(0,actor)
f,s=realized(move(-10000,10000,400))
near(f,-400*1.04*1.75*1.25/math.sqrt(2)); near(s,-f*1.33)
-- Differing client/server caps and zero client cap retain the original axis.
f,s=effects:ResolveStrafeInput(10000,10000,400,200,1.33)
near(f,200/math.sqrt(2)); near(s,f*1.33)
f,s=effects:ResolveStrafeInput(10000,10000,200,0,1.33)
near(f,200/math.sqrt(2)); near(s,f*1.33)
state.featIds={}; state.featQualificationAbilities.dex=12
local catalog=LOD.RPG.IdentityCatalog.OrdinaryFeats
assert(not cps:_FeatEligible({},state,catalog[ids[1]]))
state.featQualificationAbilities.dex=17
assert(not cps:_FeatEligible({},state,catalog[ids[3]]))
state.featIds={ids[1],ids[2]}; assert(cps:_FeatEligible({},state,catalog[ids[3]]))
local ok,errors=effects:ValidateStrafe(); assert(ok,table.concat(errors,'; '))
print('strafe PASS: all ranks, replacement, left/right/backward diagonals, forward-axis preservation after engine cap, analog, exclusions, DEX/map/backpedal/sprint composition, prerequisites')
