local root = "."
local clock = 100

function math.Clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end
function CurTime() return clock end
function IsValid(value)
    return type(value) == "table" and value.removed ~= true
end
function ErrorNoHalt(message) io.stderr:write(message) end
function table.Copy(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for key, item in pairs(value) do copy[key] = table.Copy(item) end
    return copy
end

local hooks = {}
hook = {Add = function(event, name, fn)
    hooks[event] = hooks[event] or {}; hooks[event][name] = fn
end, Run = function() end}
timer = {Create = function() end, Remove = function() end}
concommand = {Add = function() end}
game = {GetWorld = function() return {} end}
vector_origin = {}
DMG_GENERIC, DMG_POISON, DMG_BURN, DMG_SLASH = 0, 1, 2, 4

dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sh_rng.lua")
dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sh_rpg_schema.lua")

LOD.RPGAbilityRules = {}
function LOD.RPGAbilityRules:ProgressionState(actor)
    return actor and actor.LODProgressionState or nil
end
function LOD.RPGAbilityRules:Derived(actor)
    local state = self:ProgressionState(actor)
    return state and state.derivedStats or nil
end
function LOD.RPGAbilityRules:ResolveDamageContract(contract)
    local total = tonumber(contract and contract.bonus) or 0
    for _, value in ipairs(contract and contract.contributions or {}) do total = total + value end
    return total, {}, 0
end
function LOD.RPGAbilityRules:MovementMultiplier() return 1 end
function LOD.RPGAbilityRules:AimSpreadMultiplier() return 1 end

dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_status_elements.lua")
local System = LOD.RPGStatusElements

local ok, errors = System:ValidateMatrix()
if not ok then
    for _, message in ipairs(errors) do io.stderr:write(message .. "\n") end
    error("status/element matrix failed")
end

local function actor(playerControlled, abilities, level, morale)
    local value = {
        health = 100,
        maxHealth = 100,
        LODProgressionState = {
            actorType = playerControlled and "hero" or "ai",
            level = level or 1,
            abilities = abilities or {str = 10, dex = 10, con = 10, int = 10, wis = 10, cha = 10},
            derivedStats = {},
            moraleBonus = morale or 0
        }
    }
    function value:IsPlayer() return playerControlled end
    function value:Alive() return self.health > 0 end
    function value:Health() return self.health end
    function value:GetMaxHealth() return self.maxHealth end
    function value:SetNW2Bool() end
    function value:SetNW2Float() end
    return value
end

local function scripted(values)
    local index = 0
    return {Int = function(_, low, high)
        index = index + 1
        return math.Clamp(values[index] or low, low, high)
    end}
end

local target = actor(false)
local source = actor(false, {str = 10, dex = 10, con = 18, int = 10, wis = 10, cha = 30}, 20)
local applied, reason, poison = System:Apply(target, "poisoned", source,
    {direct = true, dc = 18, rng = scripted({1,1,1,1,1,1,1,1,1})})
assert(applied and reason == "applied", "poison initial application")
local recovery = poison.nextRecoveryAt
local reapplied, repeatReason = System:Apply(target, "poisoned", source,
    {direct = true, dc = 22, rng = scripted({6,6,6,6,6,6,6,6,6,1})})
assert(reapplied and repeatReason == "refreshed", "poison reapplication")
assert(poison.nextRecoveryAt == recovery and poison.dc == 22,
    "poison reapplication keeps schedule and raises DC")

local amount, resolution = System:ResolveElementDamage(100, source, target, {
    element = "fire", targetElement = "fire", targetWeaknesses = {fire = true}
}, scripted({1}))
assert(math.abs(amount - 111) < 0.001 and resolution.kind == "weakness",
    "weakness wins the one-table elemental selection")
source.LODProgressionState.featIds = {"WIS_ATTUNEMENT"}
amount, resolution = System:ResolveElementDamage(100, source, target, {
    magic = true, element = "fire", targetWeaknesses = {fire = true}
}, scripted({1, 8}))
assert(math.abs(amount - 188) < 0.001 and resolution.kind == "weakness",
    "Attunement keeps the better weakness-table result")
source.LODProgressionState.featIds = nil
local invalid, invalidInfo = System:ResolveElementDamage(100, source, target,
    {element = "water"}, scripted({1}))
assert(invalid == 100 and invalidInfo.kind == "none", "invalid element cannot proc")

local moraleTarget = actor(false)
local checked, outcome, morale = System:AttemptMorale(source, moraleTarget, {
    hpBefore = 100, maxHP = 100, finalHPDamage = 40,
    rng = scripted({1, 1, 1, 1})
})
assert(checked and outcome == "flee" and morale.duration == 10,
    "AI Morale failure creates bounded flee")
assert(math.abs(moraleTarget.LODMoraleCooldownUntil - 108.25) < 0.001,
    "AI Morale cooldown uses 0.25 controller multiplier")
local blocked, blockedReason = System:AttemptMorale(source, moraleTarget, {
    hpBefore = 60, maxHP = 100, finalHPDamage = 40,
    statusDamage = true, rng = scripted({1})
})
assert(not blocked and blockedReason == "ineligible", "status damage cannot recurse into Morale")

local immuneTarget = actor(false, nil, 1, "immune")
local immune, immuneReason = System:AttemptMorale(source, immuneTarget, {
    hpBefore = 100, maxHP = 100, finalHPDamage = 90, rng = scripted({1})
})
assert(not immune and immuneReason == "ineligible", "Morale immunity blocks resolution")

clock = 1000
System:Process(clock)
assert(not System:Has(moraleTarget, "morale_flee", clock), "flee expires through shared scheduler")

-- Real scheduler, with only HP application replaced at the engine boundary.
local a, b = actor(false), actor(false)
a.LODProgressionState.actorId, b.LODProgressionState.actorId = "A", "B"
System.Active, System.ActorLives = {}, {}
local order = {}
System._RNG = function() return scripted({1,20}) end
System._ApplyStatusDamage = function(_, target)
    order[#order+1] = target.LODProgressionState.actorId
end
local function bleeding(target)
    return System:Apply(target, "bleeding", source, {direct=true, dc=10, rng=scripted({1})})
end
bleeding(b); bleeding(a)
clock = clock + 1
System:Process(clock)
assert(table.concat(order) == "AB", "Simultaneous ticks use stable actor order, not hash insertion order")
assert(System.Active[a] == nil and System.Active[b] == nil, "Last cleared status releases active table")

order = {}; bleeding(a); bleeding(b)
System._ApplyStatusDamage = function(self, target)
    order[#order+1] = target.LODProgressionState.actorId
    if target == a then self:Clear(b, "bleeding", "observer"); bleeding(b) end
end
clock = clock + 1; System:Process(clock)
assert(table.concat(order) == "A" and System:Has(b, "bleeding"),
    "A replaced status cannot execute from the old scheduler transaction")
System:ResetActorLife(a); System:ResetActorLife(b)

bleeding(a)
System:Apply(a, "immolated", source, {direct=true, dc=100, duration=10})
order = {}
System._ApplyStatusDamage = function(self, target)
    order[#order+1] = target.LODProgressionState.actorId
    target.LODProgressionState = table.Copy(target.LODProgressionState)
end
clock = clock + 1; System:Process(clock)
assert(#order == 1 and System.Active[a] == nil,
    "Incarnation replacement during damage cancels the old tick's save and remaining statuses")

LOD.RunManager = {State={CampaignEpoch=1,LevelSeed=1,Graph={}}}
bleeding(a)
LOD.RunManager.State.Graph = {} -- Same-seed rebuild is still a new world.
assert(not System:Has(a, "bleeding"), "Same-seed topology replacement clears stale statuses")
bleeding(a)
System:BindActorLife(b)
b.LODRPGNotYetImmuneUntil = clock + 10
hooks.PreCleanupMap.LOD_RPG_CombatLifeCleanup()
assert(not next(System.Active) and not next(System.ActorLives), "Cleanup clears all active status lifetimes")
assert(b.LODRPGNotYetImmuneUntil == nil, "Cleanup also clears bound actors with no active status")
print("status/element headless matrix PASS")
