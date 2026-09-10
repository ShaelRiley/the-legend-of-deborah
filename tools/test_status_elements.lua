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

hook = {Add = function() end, Run = function() end}
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

print("status/element headless matrix PASS")
