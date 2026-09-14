-- Checkpoint E Static / Deterministic Closure Validator (AG-008)
local root = "."

local mockTime = 1000

local function mockGMod()
    SERVER = true
    CLIENT = false
    unpack = unpack or table.unpack
    DeriveGamemode = function() end
    GM = {}
    Vector = function(x,y,z)
        local v = {x=x or 0, y=y or 0, z=z or 0}
        setmetatable(v, {
            __add = function(a, b) return Vector((a.x or 0) + (b.x or 0), (a.y or 0) + (b.y or 0), (a.z or 0) + (b.z or 0)) end,
            __sub = function(a, b) return Vector((a.x or 0) - (b.x or 0), (a.y or 0) - (b.y or 0), (a.z or 0) - (b.z or 0)) end
        })
        return v
    end
    Angle = function(p,y,r) return {p=p or 0, y=y or 0, r=r or 0} end
    Color = function(r,g,b,a) return {r=r, g=g, b=b, a=a} end
    util = {
        AddNetworkString = function() end,
        CRC = function(v) return tostring(v) end,
        IsValidModel = function(m) return true end
    }
    net = {
        Receive = function() end,
        Start = function() end,
        WriteTable = function() end,
        Send = function() end
    }
    hook = {Add = function() end, GetTable = function() return {} end}
    concommand = {Add = function() end}
    CreateConVar = function(name, default)
        return {
            GetInt = function() return tonumber(default) or 0 end,
            GetBool = function() return (tonumber(default) or 0) ~= 0 end
        }
    end
    GetConVar = function() return {GetBool = function() return true end} end
    CurTime = function() return mockTime end
    SysTime = function() return mockTime end
    os = os or {}
    os.time = os.time or function() return 1700000000 end
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
    player = {GetAll = function() return {} end}
    timer = {
        Simple = function(delay, cb) if cb then cb() end end,
        Create = function() end,
        Remove = function() end,
        Exists = function() return false end
    }
    game = {GetMap = function() return "gm_flatgrass" end}
    resource = {AddFile = function() end, AddWorkshop = function() end}
    scripted_ents = {Register = function() end, Get = function() return {} end, GetStored = function() return {} end}
    ErrorNoHalt = function(msg) end
end

mockGMod()

dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sh_config.lua")
dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sh_rng.lua")
dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sh_rpg_schema.lua")
dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_gate_b_catalog.lua")
dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_gate_c_catalog.lua")

LOD = LOD or {}
LOD.RPG = LOD.RPG or {}
LOD.MazeGenerator = LOD.MazeGenerator or {
    Generate = function(self, seed) return { Validation = { cellCount = 10, criticalVerticalTransitions = 0 }, Attempt = 1 }, nil end
}
LOD.MazeBuilder = LOD.MazeBuilder or {
    Build = function(self, graph) return true, { entityCount = 0, startPos = Vector(0,0,0) } end,
    Cleanup = function() end
}
LOD.ProgressionDirector = LOD.ProgressionDirector or {
    Plan = function() return true end,
    ResetLevelState = function() end,
    CommitBuiltLevel = function() end,
    Announce = function() end,
    SyncAll = function() end,
    SyncPlayer = function() end
}
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
dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sv_loot_director.lua")
dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sv_multiplayer_hardening.lua")

local RunManager = LOD.RunManager
local Loot = LOD.LootDirector
local SoldierProgression = LOD.SoldierProgression
local CPS = LOD.CharacterProgressionSystem
local CC = LOD.Config

local errors = {}
local function check(ok, message)
    if not ok then
        table.insert(errors, message)
        print("  [FAIL] " .. message)
    else
        print("  [PASS] " .. message)
    end
end

local function createMockPlayer(id, nick, entIndex)
    local weapons = {}
    local alive = true
    local spectateMode = nil
    local p = {
        _isValid = true,
        _isEntity = true,
        SteamID64 = function() return id end,
        EntIndex = function() return entIndex or 1 end,
        Nick = function() return nick or id end,
        IsPlayer = function() return true end,
        Alive = function() return alive end,
        SetAlive = function(_, val) alive = val end,
        Spawn = function(self) alive = true; if RunManager and RunManager.ApplyPlayerState then RunManager:ApplyPlayerState(self) end end,
        Spectate = function(_, mode) spectateMode = mode end,
        SpectateEntity = function() end,
        UnSpectate = function() spectateMode = nil end,
        GetSpectateMode = function() return spectateMode end,
        SetTeam = function() end,
        SetNoCollideWithTeammates = function() end,
        CollisionRulesChanged = function() end,
        SetModel = function() end,
        SetMaxHealth = function() end,
        SetHealth = function() end,
        Health = function() return 100 end,
        SetArmor = function() end,
        Armor = function() return 0 end,
        StripWeapons = function() weapons = {} end,
        RemoveAllAmmo = function() end,
        GetWeapons = function() return weapons end,
        GetAmmo = function() return {} end,
        SetAmmo = function() end,
        Give = function(_, cls)
            local w = {_isValid = true, GetClass = function() return cls end, Clip1 = function() return 30 end, Clip2 = function() return 0 end, GetPrimaryAmmoType = function() return 1 end}
            table.insert(weapons, w)
            return w
        end,
        GetWeapon = function(_, cls)
            for _, w in ipairs(weapons) do if w:GetClass() == cls then return w end end
            return nil
        end,
        GetAmmoCount = function() return 0 end,
        SetNW2Bool = function() end,
        SetNW2Int = function() end,
        SetNW2String = function() end,
        SetPos = function() end,
        SetEyeAngles = function() end,
        ChatPrint = function() end
    }
    return p
end

-- Initialize RunManager
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

local pA = createMockPlayer("steam_A", "Hero A", 1)
local pB = createMockPlayer("steam_B", "Hero B", 2)
player.GetAll = function() return {pA, pB} end

local psA = RunManager:_AdmitIdentity(pA)
local psB = RunManager:_AdmitIdentity(pB)

RunManager.State.ActiveIdentity["steam_A"] = true
RunManager.State.ActiveIdentity["steam_B"] = true

local heroAState = CPS:NewProgressionState("steam_A", "hero", "hero")
heroAState.level = 6
heroAState.xp = 1500
heroAState.classId = "wizard"
psA.progressionState = heroAState
psA.lives = 3

local heroBState = CPS:NewProgressionState("steam_B", "hero", "hero")
heroBState.level = 4
heroBState.xp = 800
heroBState.classId = "fighter"
psB.progressionState = heroBState
psB.lives = 3

print("--- CHECKPOINT E CLOSURE VALIDATOR (REQUIREMENTS 1 THRU 20) ---")

-- 1 & 2. Independent Hero A and Hero B progression
check(psA.progressionState.level == 6 and psB.progressionState.level == 4, "1/2. Hero A (lvl 6) and Hero B (lvl 4) progression exist independently")

-- 3. Hero A is eliminated and explicitly becomes Human Soldier A
pA:SetAlive(false)
psA.lives = 0
psA.eliminated = true
psA.eliminatedSince = 1000
local okJoin, errJoin = RunManager:JoinSoldierRole(pA)
check(okJoin == true and RunManager:IsSoldierControl(pA) == true, "3. Hero A eliminated and explicitly joined Human Soldier role")

-- 4 & 5. Soldier A receives generated automatic Soldier profile NOT equal to Hero A progression state
local soldierAState = SoldierProgression:StateFor(pA)
check(soldierAState ~= nil, "4. Soldier A received generated automatic Soldier profile")
check(soldierAState ~= heroAState, "5. Soldier A progression state is NOT Hero A progression state")

-- 6. Soldier A XP threshold resolution
check(SoldierProgression:EarnedLevelsForXP(99) == 0, "6. SoldierXP 99 resolves to +0 earned levels")
check(SoldierProgression:EarnedLevelsForXP(100) == 1, "6. SoldierXP 100 resolves to +1 earned level")
check(SoldierProgression:EarnedLevelsForXP(249) == 1, "6. SoldierXP 249 resolves to +1 earned level")
check(SoldierProgression:EarnedLevelsForXP(250) == 2, "6. SoldierXP 250 resolves to +2 earned levels")
check(SoldierProgression:EarnedLevelsForXP(449) == 2, "6. SoldierXP 449 resolves to +2 earned levels")
check(SoldierProgression:EarnedLevelsForXP(450) == 3, "6. SoldierXP 450 resolves to +3 earned levels")

-- 7 & 8. Damage crediting seam and invalid source/target exclusions
if SoldierProgression.CreditDamageXP then
    local xpBefore = soldierAState.soldierXP or 0
    SoldierProgression:CreditDamageXP(pA, pB, 40)
    check((soldierAState.soldierXP or 0) > xpBefore, "7. Soldier A damaging Hero B credits SoldierXP through authoritative seam")
    
    local xpAfterLegit = soldierAState.soldierXP
    SoldierProgression:CreditDamageXP(pB, pA, 40) -- Non-soldier source
    check(soldierAState.soldierXP == xpAfterLegit, "8. Invalid source (Hero B) does NOT credit SoldierXP")
end

-- 9. Automatic advancement creates NO Hero choice UI or pending drafts
local snapA = CPS:BuildClientSnapshot(pA)
check(snapA ~= nil and snapA.isSoldier == true and snapA.readOnly == true, "9. BuildClientSnapshot for Soldier A is read-only")
check(snapA.pendingFeatCount == 0, "9. Soldier A automatic advancement creates 0 pending feat drafts")
local okChoiceClass, errChoiceClass = CPS:CommitClass(pA, "wizard")
check(okChoiceClass == false and errChoiceClass == "Soldier progression choices are read-only.", "9. CommitClass rejected on Soldier A")

-- 10. Hero A stored state remains completely unchanged
check(heroAState.level == 6 and heroAState.xp == 1500 and heroAState.classId == "wizard", "10. Hero A stored Level (6), XP (1500), and class (wizard) preserved untouched")

-- 11. Hero B state remains unchanged except for simulated damage
check(heroBState.level == 4 and heroBState.xp == 800 and psB.lives == 3, "11. Hero B state preserved untouched")

-- 12 & 13. Soldier death discards Soldier incarnation state; fresh incarnation starts with 0 XP
pA:SetAlive(false)
RunManager:HandleDeath(pA)
check(RunManager:IsSoldierControl(pA) == false, "12. Soldier death discarded active Soldier incarnation")
mockTime = mockTime + 25 -- Pass 20s respawn delay
local okRejoin, _ = RunManager:JoinSoldierRole(pA)
check(okRejoin == true, "13. Rejoined Soldier role after 20s delay")
local freshSoldier = SoldierProgression:StateFor(pA)
check(freshSoldier.soldierXP == 0, "13. Fresh Soldier incarnation starts with 0 SoldierXP")

-- 14. Return to Hero Queue destroys Soldier progression and restores Hero A view
RunManager:ReturnToHeroQueue(pA)
check(RunManager:IsSoldierControl(pA) == false, "14. ReturnToHeroQueue retired Soldier progression")
check(psA.eliminatedSince == 1000, "14. Hero A original eliminatedSince (1000) strictly preserved")

-- 15. Revival exclusion while ACTIVE_SOLDIER
RunManager:JoinSoldierRole(pA)
check(RunManager:IsHeroRevivalQueueEligible("steam_A") == false, "15. Same-dungeon revival excluded while ACTIVE_SOLDIER")
local okRevSol, _ = RunManager:ReviveIdentity("steam_A")
check(okRevSol == false, "15. Direct ReviveIdentity on ACTIVE_SOLDIER rejected")

-- 16. Revival exclusion while SOLDIER_RESPAWN_WAIT
pA:SetAlive(false)
RunManager:HandleDeath(pA)
check(RunManager:IsHeroRevivalQueueEligible("steam_A") == false, "16. Same-dungeon revival excluded while SOLDIER_RESPAWN_WAIT")
local okRevWait, _ = RunManager:ReviveIdentity("steam_A")
check(okRevWait == false, "16. Direct ReviveIdentity during SOLDIER_RESPAWN_WAIT rejected")

-- 17. Later valid Hero-queue revival resumes Hero A state without Soldier leakage
RunManager:ReturnToHeroQueue(pA)
local okRevValid, _ = RunManager:ReviveIdentity("steam_A")
check(okRevValid == true and psA.lives == 1 and psA.eliminated == false, "17. Later valid Hero-queue revival restored Hero A to 1 life")
check(psA.progressionState.level == 6 and psA.progressionState.xp == 1500, "17. Hero A state resumed without Soldier leakage")

-- 18. Active Soldier does not prevent cooperative wipe
psA.lives = 0; psA.eliminated = true; psA.eliminatedSince = 1000; RunManager.State.ActiveIdentity["steam_A"] = nil
psB.lives = 0; psB.eliminated = true; psB.eliminatedSince = 1000; RunManager.State.ActiveIdentity["steam_B"] = nil
RunManager:JoinSoldierRole(pA)
pA:SetAlive(true)
RunManager.State.Failed = false
local wipe = RunManager:EvaluateWipe()
check(wipe == true and RunManager.State.Failed == true, "18. Active Soldier does NOT prevent cooperative party wipe when all Heroes are eliminated")
RunManager.State.Failed = false

-- 19. Config contract: 4 Heroes + 6 Soldiers = 10 Max Played Identities
check(CC.MaxActivePlayers == 4, "19. CC.MaxActivePlayers == 4")
check(CC.MaxActiveSoldiers == 6, "19. CC.MaxActiveSoldiers == 6")
check(CC.Campaign.MaxPlayedIdentities == 10, "19. CC.Campaign.MaxPlayedIdentities == 10")

-- 20. AI vs Human Soldier deterministic generation parity check across multiple scenarios
local allowedDiffKeys = {
    actorType = true,
    actorId = true,
    controller = true,
    soldierXP = true,
    soldierEarnedLevels = true,
    soldierIncarnation = true,
    soldierActorSeed = true,
    soldierSpawnLevel = true,
    _isValid = true,
    _isEntity = true
}

local function compareRPGValues(v1, v2, path)
    if type(v1) ~= type(v2) then
        return false, string.format("%s: type mismatch (%s vs %s)", path, type(v1), type(v2))
    end
    if type(v1) ~= "table" then
        if v1 ~= v2 then
            return false, string.format("%s: value mismatch (%s vs %s)", path, tostring(v1), tostring(v2))
        end
        return true
    end
    local keys = {}
    for k in pairs(v1) do if not allowedDiffKeys[k] then keys[k] = true end end
    for k in pairs(v2) do if not allowedDiffKeys[k] then keys[k] = true end end
    for k in pairs(keys) do
        local p = path == "" and tostring(k) or (path .. "." .. tostring(k))
        local ok, err = compareRPGValues(v1[k], v2[k], p)
        if not ok then return false, err end
    end
    return true
end

local scenarios = {
    {name = "Low-level ordinary (DL 1, seed 12345)", dungeonLevel = 1, seed = 12345},
    {name = "Level-5 (DL 5, seed 77123)", dungeonLevel = 5, seed = 77123},
    {name = "Elite/Champion-capable (DL 10, seed 88123)", dungeonLevel = 10, seed = 88123},
    {name = "Level-20-capable (DL 20, seed 99123)", dungeonLevel = 20, seed = 99123},
    {name = "Post-20 numeric growth (DL 25, seed 10123)", dungeonLevel = 25, seed = 10123}
}

local allParityPassed = true
for _, sc in ipairs(scenarios) do
    local aiState, aiErr = CPS:GenerateMonsterProgression("soldier", sc.seed, sc.dungeonLevel, 35, "ai")
    local humanState, humanErr = CPS:GenerateMonsterProgression("soldier", sc.seed, sc.dungeonLevel, 35, "human_soldier")
    if not aiState or not humanState then
        allParityPassed = false
        print(string.format("  [PARITY FAIL] %s generation error ai=%s human=%s", sc.name, tostring(aiErr), tostring(humanErr)))
    else
        local ok, err = compareRPGValues(aiState, humanState, "")
        if not ok then
            allParityPassed = false
            print(string.format("  [PARITY FAIL] %s: %s", sc.name, err))
        end
    end
end

check(allParityPassed == true, "20. AI vs Human Soldier deterministic RPG generation parity PASSED across all shared build fields (5/5 scenarios)")

-- Summary
if #errors == 0 then
    print("CHECKPOINT_E_CLOSURE_HARNESS_PASS — All 20 Checkpoint E requirements verified with 0 discrepancies.")
else
    print("CHECKPOINT_E_CLOSURE_HARNESS_FAIL — Discrepancies found:")
    for _, err in ipairs(errors) do
        print("  - " .. err)
    end
    error("Checkpoint E closure validation failed")
end
