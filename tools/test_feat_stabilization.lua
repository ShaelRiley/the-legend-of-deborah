-- Load the shipped include graph, so late overrides participate in these checks.
dofile('tools/test_checkpoint_d_closure.lua')
local Catalog = LOD.RPG.IdentityCatalog
local count, capstones, fallbacks = 0, 0, 0
local function description(def)
    assert(type(def.displayName) == 'string' and def.displayName:match('%S'), def.featId .. ': missing name')
    local text = def.effectParams and def.effectParams.description
    assert(type(text) == 'string' and text:match('%S'), def.featId .. ': blank description')
    assert(not text:lower():find('todo', 1, true), def.featId .. ': placeholder description')
end
for id, def in pairs(Catalog.OrdinaryFeats) do
    assert(id == def.featId, 'registry/feat ID disagreement')
    description(def); count = count + 1
    for _, prerequisite in ipairs(def.prerequisiteFeatIds or {}) do
        assert(Catalog.OrdinaryFeats[prerequisite], id .. ': orphan prerequisite ' .. prerequisite)
    end
    for _, excluded in ipairs(def.incompatibleFeatIds or {}) do
        assert(Catalog.OrdinaryFeats[excluded], id .. ': orphan mutual exclusion ' .. excluded)
    end
end
for _, def in pairs(Catalog.FallbackFeats) do description(def); fallbacks = fallbacks + 1 end
for _, class in pairs(Catalog.ClassCapstones) do
    for _, def in pairs(class) do description(def); capstones = capstones + 1 end
end
local Effects = LOD.RPG.FeatEffectSystem
local function near(actual, expected, label)
    assert(math.abs(actual - expected) < 1e-8, label .. ': ' .. tostring(actual) .. ' ~= ' .. expected)
end
-- Highest family rank replaces earlier ranks; the independent Fighter source adds.
near(Effects:HealthRegenProfile({classId='fighter',featIds={}}).ceilingFraction,.33,'innate Fighter')
near(Effects:HealthRegenProfile({classId='rogue',featIds={}}).ceilingFraction,0,'no innate Rogue regen')
for rank, id in ipairs({'CON_REGEN_11','CON_REGEN_22','CON_REGEN_33'}) do
    for _, class in ipairs({'fighter','rogue','wizard'}) do
        local profile = Effects:HealthRegenProfile({classId=class,featIds={id}})
        near(profile.ceilingFraction,rank*.11+(class=='fighter' and .33 or 0),'combined ceiling')
        assert(profile.damageFreeDelaySeconds==5 and profile.baseMaxHPPerSecond==.01)
    end
end
near(Effects:HealthRegenProfile({classId='fighter',featIds={'CON_REGEN_11','CON_REGEN_22','CON_REGEN_33'}}).ceilingFraction,.66,'no family double count')
local Rules = LOD.RPGAbilityRules
local diverted, spent, remaining = Rules:ComputeMagicDiversion(3,.1,100,1,true)
near(diverted,1,'Wizard upward rounding');near(spent,1,'Wizard funding');near(remaining,2,'Wizard HP')
diverted,spent,remaining = Rules:ComputeMagicDiversion(.2,.1,100,1,true)
near(diverted,.2,'never prevent more than incoming damage');near(remaining,0,'fractional damage clamp')
diverted,spent,remaining = Rules:ComputeMagicDiversion(3,.15,100,1,false)
near(diverted,.45,'non-Wizard Mana Barrier continuous rule');near(remaining,2.55,'Mana Barrier HP')
diverted,spent,remaining = Rules:ComputeMagicDiversion(10,.5,.35,1,true)
near(diverted,.35,'fractional Magic funding');near(spent,.35,'no negative Magic');near(remaining,9.65,'unfunded HP')
diverted,spent,remaining = Rules:ComputeMagicDiversion(10,.5,2,1.5,true)
near(diverted,3,'Living Aegis efficiency');near(spent,2,'Living Aegis funding');near(remaining,7,'Living Aegis HP')
assert(Catalog.ClassCapstones.wizard.WIZ_CAP_LIVING_AEGIS.effectParams.diversionBonus == nil,'no invented diversion bonus')
for i, req in ipairs({13,15,17}) do
    assert(Catalog.OrdinaryFeats['INT_MANA_BARRIER_'..i].abilityRequirements.int==req,'canonical Mana Barrier requirement')
end
-- Exercise the production wrapper with an upstream cancellation. No defense,
-- resource spending, attribution, or observers may run after a cancelled hit.
local baseResult = true
GM.EntityTakeDamage = function() return baseResult end
dofile('gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_gate_d.lua')
local oldValid, oldState, oldWis = IsValid, Rules.ProgressionState, Rules.ApplyWisDefense
local wisCalls = 0
IsValid = function(value) return type(value)=='table' and value.valid==true end
Rules.ProgressionState = function(_,actor) return actor.state end
Rules.ApplyWisDefense = function() wisCalls=wisCalls+1 end
CurTime = function() return 10 end
LOD.RunManager = {State={Level=3}}
local actor = {valid=true, state={notYetConsumedDungeonLevel=3}, LODRPGNotYetImmuneUntil=10.5}
local damage = {amount=20,SetDamage=function(self,n) self.amount=n end}
assert(GM:EntityTakeDamage(actor,damage)==true,'upstream cancellation must survive wrapper')
assert(wisCalls==0 and damage.amount==20,'cancelled hit must not run downstream defenses')
baseResult=nil
assert(GM:EntityTakeDamage(actor,damage)==true and damage.amount==0,'Not Yet immunity cancels whole hit')
assert(wisCalls==0,'immune hit must not consume Wisdom cooldown or reach shield spending')
LOD.RunManager.State.Level=4
assert(not Rules:NotYetImmunityActive(actor),'immunity cannot cross dungeon boundary')
actor.state={}
LOD.RunManager.State.Level=3
assert(not Rules:NotYetImmunityActive(actor),'reused player entity cannot lend immunity to a fresh identity')
baseResult=false
assert(GM:EntityTakeDamage(nil,nil)==false,'false return must remain false')
baseResult=nil
assert(GM:EntityTakeDamage(nil,nil)==nil,'nil return must remain nil')
IsValid, Rules.ProgressionState, Rules.ApplyWisDefense = oldValid, oldState, oldWis

print(string.format('[FEAT_STABILIZATION] PASS: %d ordinary + %d fallback + %d capstones, zero blank descriptions; shared regression checks passed. This does not certify feat completeness.', count,fallbacks,capstones))
