-- Character Sheet Snapshot & Client Renderer Contract Validator for Human Soldiers (AG-008R1)
print("=== SOLDIER CHARACTER SHEET SNAPSHOT & RENDERER CONTRACT TEST ===")

local root = "."

SERVER = true
CLIENT = false
unpack = unpack or table.unpack
DeriveGamemode = function() end
GM = {}
Vector = function(x, y, z) return {x = x or 0, y = y or 0, z = z or 0} end
Angle = function(p, y, r) return {p = p or 0, y = y or 0, r = r or 0} end
Color = function(r, g, b, a) return {r = r or 255, g = g or 255, b = b or 255, a = a or 255} end
CurTime = function() return 1000 end
RealTime = function() return 1000 end
util = {AddNetworkString = function() end, CRC = function(v) return tostring(v) end}
net = {Receive = function() end, Send = function() end, Start = function() end, WriteTable = function() end, WriteString = function() end, WriteUInt = function() end}
hook = {Add = function() end, GetTable = function() return {} end, Run = function() end}
concommand = {Add = function() end}
CreateConVar = function(name, default) return {GetBool = function() return true end, GetInt = function() return 1 end, GetFloat = function() return 1.0 end, GetString = function() return tostring(default or "") end} end
GetConVar = function() return {GetBool = function() return true end} end
IsValid = function(v) return v ~= nil and type(v) == "table" and v._isValid == true end
isentity = function(v) return type(v) == "table" and v._isEntity == true end
isfunction = function(v) return type(v) == "function" end
istable = function(v) return type(v) == "table" end
isstring = function(v) return type(v) == "string" end
isnumber = function(v) return type(v) == "number" end
math.Clamp = function(v, min, max) return math.max(min, math.min(max, v)) end
string.Trim = function(v) return string.match(v, "^%s*(.-)%s*$") end
table.Count = function(t)
    local count = 0
    for _ in pairs(t or {}) do count = count + 1 end
    return count
end
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
AddCSLuaFile = AddCSLuaFile or function() end
include = include or function() end

dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sh_config.lua")
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

dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sv_snapshot_delivery.lua")
dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sv_character_progression.lua")
dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sv_hero_ability_rolls.lua")
dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_gate_d.lua")
dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_wizard_rules.lua")
dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sv_human_soldier_progression.lua")
dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sv_run_manager.lua")

local RunManager = LOD.RunManager
local SoldierProgression = LOD.SoldierProgression
local CPS = LOD.CharacterProgressionSystem

-- Setup mock RunManager state
RunManager.State = {
    CampaignSeed = 99123,
    RosterSeed = 12345,
    LevelSeed = 99123,
    Level = 1,
    BuildReady = true,
    Failed = false,
    CharacterOrder = LOD.Config.Models.Characters,
    CharacterByIdentity = {},
    PlayedIdentities = {},
    PlayerState = {},
    ActiveIdentity = {},
    WaitingSince = {}
}

local mockPlayer = {
    _isValid = true,
    _isEntity = true,
    IsPlayer = function() return true end,
    SteamID64 = function() return "76561198000000001" end,
    Nick = function() return "TestPlayer" end,
    Health = function() return 35 end,
    UnSpectate = function() end,
    Spawn = function() end,
    SetModel = function() end,
    SetNW2Bool = function() end,
    SetNW2Int = function() end,
    SetNW2String = function() end
}

local psMock = RunManager:_AdmitIdentity(mockPlayer)
RunManager.State.ActiveIdentity[mockPlayer:SteamID64()] = true
psMock.lives = 0
psMock.eliminated = true
psMock.eliminatedSince = 1000

-- Initialize Soldier state
local okJoin, errJoin = RunManager:JoinSoldierRole(mockPlayer)
assert(okJoin == true, "JoinSoldierRole must succeed: " .. tostring(errJoin or "none"))
local soldierState = SoldierProgression:StateFor(mockPlayer)
assert(soldierState, "Soldier state must exist for mockPlayer")

local errors = {}
local function check(cond, msg)
    if cond then
        print("  [PASS] " .. msg)
    else
        print("  [FAIL] " .. msg)
        errors[#errors + 1] = msg
    end
end

-- Test 1: Snapshot contract at Level 1
local snap1 = CPS:BuildClientSnapshot(mockPlayer)
check(snap1 ~= nil, "Level 1 Soldier snapshot built successfully")
check(snap1.isSoldier == true, "snap1.isSoldier is true")
check(snap1.readOnly == true, "snap1.readOnly is true")
check(type(snap1.fullDisplayName) == "string" and #snap1.fullDisplayName > 0, "snap1.fullDisplayName is valid non-empty string")
check(type(snap1.className) == "string" and #snap1.className > 0, "snap1.className is valid non-empty string")
check(type(snap1.identityTraits) == "table" and #snap1.identityTraits == 0, "snap1.identityTraits is empty table for Soldiers")

-- Test 2: Ability row schema contract
check(type(snap1.abilities) == "table" and #snap1.abilities == 6, "snap1.abilities contains 6 ability rows")
for _, ab in ipairs(snap1.abilities or {}) do
    local validRow = type(ab.label) == "string"
        and type(ab.score) == "number"
        and type(ab.modifier) == "number"
        and (ab.role == "Primary Growth" or ab.role == "Secondary Growth" or ab.role == "Ordinary Growth")
        and type(ab.base) == "number"
        and type(ab.growth) == "number"
        and type(ab.fighterTraining) == "number"
        and type(ab.identity) == "number"
        and type(ab.feat) == "number"
    check(validRow, string.format("Ability row %s satisfies exact addAbilityRow renderer contract", tostring(ab.label)))
end

-- Test 3: Hit die ledger enrichment contract at Level 5
soldierState.level = 5
for lvl = 2, 5 do
    soldierState.hitDieRollsByLevel[lvl] = {formula = "d8", values = {6}, total = 6}
end

local snap5 = CPS:BuildClientSnapshot(mockPlayer)
check(#snap5.hitDieRolls == 4, "snap5.hitDieRolls contains 4 rolls for levels 2-5")
for _, roll in ipairs(snap5.hitDieRolls) do
    local validRoll = type(roll.level) == "number"
        and type(roll.formula) == "string"
        and type(roll.values) == "table"
        and type(roll.total) == "number"
        and type(roll.conBonus) == "number"
        and type(roll.hpGain) == "number"
        and type(roll.capped) == "boolean"
    check(validRoll, string.format("Hit die roll Level %d satisfies addHitDieLedger renderer contract", roll.level))
end
check(type(snap5.rolledHitPointSubtotal) == "number", "snap5.rolledHitPointSubtotal is present")
check(type(snap5.hpConBonusPerLevel) == "number", "snap5.hpConBonusPerLevel is present")

-- Test 4: Owned feats & stack count contract
soldierState.featIds = {"DEX_FAST_RELOAD", "DEX_FAST_RELOAD"}
soldierState.featStackCounts = {DEX_FAST_RELOAD = 2}
soldierState.featSlotsGranted = 2

local snapFeat = CPS:BuildClientSnapshot(mockPlayer)
check(#snapFeat.ownedFeats >= 1, "snapFeat.ownedFeats contains owned feats")
local reloadFeat = snapFeat.ownedFeats[1]
check(reloadFeat and reloadFeat.stackCount == 2, "Feat stackCount is 2 (from soldierState.featStackCounts)")
check(snapFeat.featSlotsGranted == 2, "snapFeat.featSlotsGranted matches soldierState.featSlotsGranted (2)")
check(snapFeat.ordinaryFeatsCommitted == 2, "snapFeat.ordinaryFeatsCommitted matches soldierState.featSlotsGranted (2)")

-- Test 5: Level-20 Capstone read-only contract
soldierState.level = 20
soldierState.classId = "fighter"
soldierState.classCapstoneFeatId = "FTR_CAP_ONE_PERSON_ARMY"

local snap20 = CPS:BuildClientSnapshot(mockPlayer)
check(snap20.capstoneDraft ~= nil, "snap20.capstoneDraft is present for Level 20 Soldier")
check(snap20.capstoneDraft.resolved == true, "snap20.capstoneDraft.resolved is true (read-only)")
check(#snap20.capstoneDraft.offers == 1, "snap20.capstoneDraft.offers contains 1 capstone")
check(snap20.capstoneDraft.offers[1].selected == true, "snap20 capstone offer is selected")
check(snap20.selectedCapstone ~= nil and snap20.selectedCapstone.featId == "FTR_CAP_ONE_PERSON_ARMY", "snap20.selectedCapstone exposes enriched capstone definition")

-- Test 6: Emulate client renderer traversal (no nil errors, no string format crashes)
local function emulateClientRender(snap)
    local identitySectionTitle = snap.isSoldier and "Soldier Incarnation" or "Identity Traits"
    assert(identitySectionTitle, "identitySectionTitle non-nil")
    for _, trait in ipairs(snap.identityTraits or {}) do
        local cat = string.upper(trait.tableType) .. " / " .. trait.categoryName
        local perk = trait.perkDisplayName
        local me = trait.mechanicalEffect
        local fl = trait.flavorText
    end

    local xpLine = snap.isSoldier
        and (snap.nextThreshold and string.format("SoldierXP: %d / %d", snap.soldierXP or 0, snap.nextThreshold) or "SoldierXP: MAX")
        or (snap.xpForNextLevel and string.format("XP: %d / %d", snap.xp or 0, snap.xpForNextLevel) or "XP: MAX")

    for _, ab in ipairs(snap.abilities or {}) do
        local mod = ab.modifier >= 0 and ("+" .. ab.modifier) or tostring(ab.modifier)
        local scoreText = tostring(ab.score) .. "  (" .. mod .. ")"
        local roleText = ab.role
        local tipText = string.format("Base %d + growth %d + Fighter Training %d + identity %d + feat %d",
            ab.base, ab.growth, ab.fighterTraining, ab.identity, ab.feat)
    end

    for _, roll in ipairs(snap.hitDieRolls or {}) do
        local values = {}
        for index, value in ipairs(roll.values or {}) do values[index] = tostring(value) end
        local text = string.format("L%d  %s [%s]  %+d CON  =  +%d HP%s",
            roll.level, roll.formula, table.concat(values, "+"), roll.conBonus or 0,
            roll.hpGain or 1, roll.capped and " (CHAIN CAPPED)" or "")
    end

    local progLabel = snap.isSoldier and "Soldier progression d%d" or "Hero progression d%d"
    local classLineText = string.format("%s  /  favored %s  /  " .. progLabel,
        snap.className, "STR", snap.classHitDie or 0)

    for _, feat in ipairs(snap.ownedFeats or {}) do
        local stacks = (feat.stackCount or 1) > 1 and ("  x" .. feat.stackCount) or ""
        local title = feat.displayName .. stacks
        local effect = feat.effect or ""
    end

    if snap.capstoneDraft then
        for _, feat in ipairs(snap.capstoneDraft.offers or {}) do
            local title = feat.displayName
            local effect = feat.effect or ""
            local status = feat.selected and "SELECTED" or "NOT SELECTED"
        end
    end
end

local okRender, errRender = pcall(function()
    emulateClientRender(snap1)
    emulateClientRender(snap5)
    emulateClientRender(snap20)
end)
check(okRender == true, "Emulated client character sheet render completed cleanly with 0 errors: " .. tostring(errRender or "clean"))

if #errors == 0 then
    print("\nSOLDIER_CHARACTER_SHEET_TEST_PASS — All snapshot & renderer contract tests passed with 0 discrepancies.")
else
    print(string.format("\nSOLDIER_CHARACTER_SHEET_TEST_FAIL — %d failures detected.", #errors))
    os.exit(1)
end
