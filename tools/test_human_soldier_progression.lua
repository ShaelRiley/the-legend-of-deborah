-- Human Soldier Progression Authority Deterministic Validator (AG-006)
local root = "."

local function mockGMod()
    SERVER = true
    CLIENT = false
    unpack = unpack or table.unpack
    DeriveGamemode = function() end
    GM = {}
    Vector = function(x,y,z) return {x=x or 0, y=y or 0, z=z or 0} end
    Color = function(r,g,b,a) return {r=r, g=g, b=b, a=a} end
    util = {AddNetworkString = function() end, CRC = function(v) return tostring(v) end}
    net = {Receive = function() end}
    hook = {Add = function() end, GetTable = function() return {} end}
    concommand = {Add = function() end}
    GetConVar = function() return {GetBool = function() return true end} end
    IsValid = function(v) return v ~= nil and type(v) == "table" and v._isValid == true end
    isentity = function(v) return type(v) == "table" and v._isEntity == true end
    isfunction = function(v) return type(v) == "function" end
    istable = function(v) return type(v) == "table" end
    isstring = function(v) return type(v) == "string" end
    isnumber = function(v) return type(v) == "number" end
    math.Clamp = function(v, min, max) return math.max(min, math.min(max, v)) end
    string.Trim = function(v) return string.match(v, "^%s*(.-)%s*$") end
    table.Copy = function(v)
        if type(v) ~= "table" then return v end
        local copy = {}
        for k, item in pairs(v) do copy[k] = table.Copy(item) end
        return copy
    end
    team = {SetUp = function() end}
    timer = {Simple = function() end, Create = function() end, Remove = function() end, Exists = function() return false end}
    player = {GetAll = function() return {} end}
    resource = {AddFile = function() end, AddWorkshop = function() end}
    include = function(path)
        local f = io.open("gamemodes/legend_of_deborah/gamemode/" .. path, "rb")
        if not f then error("Cannot open " .. path) end
        local code = f:read("*a")
        f:close()
        local fn, err = load(code, path)
        if not fn then error("Load error in " .. path .. ": " .. tostring(err)) end
        fn()
    end
end

mockGMod()

dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sh_rng.lua")
dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sh_rpg_schema.lua")
dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_gate_b_catalog.lua")
dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_gate_c_catalog.lua")

LOD = LOD or {}
LOD.RPG = LOD.RPG or {}
LOD.CombatRolls = LOD.CombatRolls or {}
function LOD.CombatRolls:RollProgressionHitDie(seed, sides)
    seed = tonumber(seed) or 12345
    sides = tonumber(sides) or 8
    local value = (LOD.RNG and LOD.RNG.New) and LOD.RNG.New(seed):Int(1, sides) or math.random(1, sides)
    return {seed = seed, sides = sides, formula = "d" .. tostring(sides), values = {value}, total = value}
end

dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sv_character_progression.lua")
dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sv_hero_ability_rolls.lua")
dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_gate_d.lua")
dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_wizard_rules.lua")
dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sv_human_soldier_progression.lua")

local System = assert(LOD.SoldierProgression, "SoldierProgression system required")
local CPS = assert(LOD.CharacterProgressionSystem, "CharacterProgressionSystem required")
local Rules = assert(LOD.RPGAbilityRules, "RPGAbilityRules required")
local RPG = assert(LOD.RPG, "LOD.RPG required")

local errors = {}
local function check(ok, message)
    if not ok then
        table.insert(errors, message)
    end
end

-- 1. Canonical threshold table exactness
local th = System.THRESHOLDS
check(type(th) == "table" and #th == 3, "Threshold table has 3 elements")
check(th[1] == 100, "Threshold 1 is 100")
check(th[2] == 250, "Threshold 2 is 250")
check(th[3] == 450, "Threshold 3 is 450")

-- 2-7. Deterministic boundary check for EarnedLevelsForXP
check(System:EarnedLevelsForXP(99) == 0, "99 XP does not advance")
check(System:EarnedLevelsForXP(100) == 1, "100 XP advances to earned level 1")
check(System:EarnedLevelsForXP(249) == 1, "249 XP remains at earned level 1")
check(System:EarnedLevelsForXP(250) == 2, "250 XP reaches earned level 2")
check(System:EarnedLevelsForXP(449) == 2, "449 XP remains at earned level 2")
check(System:EarnedLevelsForXP(450) == 3, "450 XP reaches earned level 3")
check(System:EarnedLevelsForXP(1000) == 3, "1000 XP remains capped at 3 earned levels")

-- 8. Single XP award crossing multiple thresholds
LOD.RunManager = { State = { Level = 20, CampaignSeed = 77123 } }
local lumpSoldier = System:CreateIncarnation(77123, 40, 1)
check(lumpSoldier ~= nil, "Incarnation creation succeeded")
check(lumpSoldier.level == 1, "Initial level is 1")
local okLump, errLump = System:Award(lumpSoldier, 450, false)
check(okLump == true, "Lump 450 XP award succeeded: " .. tostring(errLump))
check(lumpSoldier.soldierXP == 450, "soldierXP recorded as 450")
check(lumpSoldier.soldierEarnedLevels == 3, "soldierEarnedLevels recorded as 3")
check(lumpSoldier.level == 4, "Incarnation level advanced from 1 to 4")

-- 9. Automatic advancement does not enter Hero feat/class choice flow
local unresolvedChoice = false
for _, draft in ipairs(lumpSoldier.pendingFeatSlots or {}) do
    if draft.resolved == false then unresolvedChoice = true break end
end
check(unresolvedChoice == false, "No unresolved Hero feat choice UI slots generated")
check(lumpSoldier.archetypeId == "soldier" and lumpSoldier.actorType == "human_soldier", "Archetype is soldier and actorType is human_soldier")

-- 10. Hero progression fields/state remain untouched by Soldier advancement
local heroState = CPS:NewProgressionState("hero_test_id", "hero", "hero")
heroState.level = 5
heroState.xp = 1200
heroState.classId = "wizard"
heroState.baseAbilities = RPG.NewAbilityBlock(14)
heroState.featIds = {"INT_MANA_BARRIER_1"}
local originalHeroCopy = table.Copy(heroState)

local mockPlayer = {
    _isValid = true,
    _isEntity = true,
    IsPlayer = function() return true end,
    Alive = function() return true end,
    identity = "hero_test_id"
}

LOD.RunManager.GetPlayerState = function(_, ply)
    return { progressionState = heroState }
end

local soldierAttached, attachErr = System:Attach(mockPlayer, 88219, 40, 1)
check(soldierAttached ~= nil, "Attached soldier incarnation to player: " .. tostring(attachErr))
check(mockPlayer.LODHumanSoldierProgressionState == soldierAttached, "Player owns attached soldier state")

-- Combat rules active state check
local activeState = Rules:ProgressionState(mockPlayer)
check(activeState == soldierAttached, "Rules:ProgressionState returns active soldier incarnation state")
check(activeState.actorType == "human_soldier", "Active actorType is human_soldier")

-- Advance soldier state
local okAdv = System:Award(mockPlayer, 250, false)
check(okAdv == true, "Award on player attached soldier succeeded")
check(soldierAttached.soldierXP == 250, "Attached soldier XP updated to 250")
check(soldierAttached.soldierEarnedLevels == 2, "Attached soldier earned levels updated to 2")

-- Verify stored Hero state was NOT mutated
check(heroState.level == originalHeroCopy.level, "Hero level unmutated (5)")
check(heroState.xp == originalHeroCopy.xp, "Hero XP unmutated (1200)")
check(heroState.classId == originalHeroCopy.classId, "Hero classId unmutated (wizard)")
check(#heroState.featIds == #originalHeroCopy.featIds and heroState.featIds[1] == originalHeroCopy.featIds[1], "Hero feat inventory unmutated")

-- 11. Soldier reset/retirement clears incarnation-local Soldier progression
local okRetire = System:Retire(mockPlayer)
check(okRetire == true, "Retire on player returned true")
check(mockPlayer.LODHumanSoldierProgressionState == nil, "Player LODHumanSoldierProgressionState cleared to nil")
local revertedState = Rules:ProgressionState(mockPlayer)
check(revertedState == heroState, "Rules:ProgressionState reverted back to Hero state")
check(revertedState.level == 5 and revertedState.classId == "wizard", "Reverted state is original Hero state")

-- 12. Fresh Soldier incarnation begins from canonical fresh state
local freshSoldier, freshErr = System:Attach(mockPlayer, 99401, 40, 1)
check(freshSoldier ~= nil, "Fresh attach succeeded")
check(freshSoldier.soldierXP == 0, "Fresh soldierXP is 0")
check(freshSoldier.soldierEarnedLevels == 0, "Fresh soldierEarnedLevels is 0")
check(freshSoldier.level == 1, "Fresh soldier level starts at spawn level 1")

-- 13. Repeated reset calls do not create duplicate state or corrupt Hero state
local repeatRetire1 = System:Retire(mockPlayer)
check(repeatRetire1 == true, "First retirement returned true")
local repeatRetire2 = System:Retire(mockPlayer)
check(repeatRetire2 == false, "Second retirement returned false idempotently")
local repeatRetire3 = System:Reset(mockPlayer)
check(repeatRetire3 == false, "Reset call on already-retired player returned false idempotently")
check(mockPlayer.LODHumanSoldierProgressionState == nil, "Player state remains nil")
check(heroState.level == 5 and heroState.xp == 1200, "Hero state preserved without corruption")

-- Direct state reset check
local directState = System:CreateIncarnation(55123, 40, 1)
System:Award(directState, 100, false)
check(directState.soldierXP == 100, "Direct state XP is 100")
local resetDirect = System:Reset(directState)
check(resetDirect == true, "Reset on direct state returned true")
check(directState.soldierXP == 0 and directState.soldierIncarnation == false, "Direct state reset to 0 XP and unattached")
local resetDirect2 = System:Reset(directState)
check(resetDirect2 == false, "Repeated Reset on direct state returned false idempotently")

-- 14. Effective Soldier advancement obeys existing dungeon/world progression constraint
LOD.RunManager.State.Level = 1 -- EffectiveLevelCap for human_soldier at dungeon 1 is 1+3 = 4
local constrainedSoldier = System:CreateIncarnation(12345, 40, 1) -- dungeon level 1
local initialSpawnLevel = constrainedSoldier.soldierSpawnLevel
check(initialSpawnLevel <= 4, "Initial spawn level within dungeon 1 cap")
System:Award(constrainedSoldier, 1000, false) -- 1000 XP (3 earned levels)
check(constrainedSoldier.soldierXP == 1000, "soldierXP is 1000")
check(constrainedSoldier.level == 4, "Soldier level clamped to D+3 ceiling (4)")

-- 15. Soldier XP award integration seams routing
local attackerPlayer = {
    _isValid = true,
    _isEntity = true,
    IsPlayer = function() return true end,
    Alive = function() return true end,
    identity = "attacker_soldier"
}
local defenderHeroPlayer = {
    _isValid = true,
    _isEntity = true,
    IsPlayer = function() return true end,
    Alive = function() return true end,
    identity = "defender_hero"
}

LOD.RunManager.GetPlayerState = function(_, ply)
    if ply == defenderHeroPlayer then
        return { progressionState = { actorType = "hero", level = 2, classId = "fighter" } }
    end
    return nil
end

local seamSoldier = System:Attach(attackerPlayer, 66100, 40, 1)
local okSeam, errSeam = System:ObserveEffectiveHeroDamage(attackerPlayer, defenderHeroPlayer, 100)
check(okSeam == true, "ObserveEffectiveHeroDamage awarded damage XP: " .. tostring(errSeam))
check(seamSoldier.soldierXP == 100, "Attacker soldierXP increased to 100 via damage seam")

-- Non-Hero target exclusion check
local defenderNonHero = {
    _isValid = true,
    _isEntity = true,
    IsPlayer = function() return false end,
    Alive = function() return true end
}
local okNonHero, errNonHero = System:ObserveEffectiveHeroDamage(attackerPlayer, defenderNonHero, 100)
check(okNonHero == false, "ObserveEffectiveHeroDamage rejected non-Hero target")

-- Personal life consumed credit (+50 XP) check
local okLife, errLife = System:Award(attackerPlayer, 0, true)
check(okLife == true, "Award with lifeConsumed=true succeeded: " .. tostring(errLife))
check(seamSoldier.soldierXP == 150, "soldierXP increased by 50 to 150 for life consumed")

if #errors == 0 then
    print("HUMAN_SOLDIER_PROGRESSION_HARNESS_PASS — All 15 requirements verified with 0 discrepancies.")
else
    print("HUMAN_SOLDIER_PROGRESSION_HARNESS_FAIL — Discrepancies found:")
    for _, err in ipairs(errors) do
        print("  - " .. err)
    end
    error("Human Soldier progression validation failed")
end
