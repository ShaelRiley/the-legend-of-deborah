-- Human Soldier RPG & Return-to-Hero Lifecycle Deterministic Validator (AG-007)
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

dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sv_character_progression.lua")
dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sv_hero_ability_rolls.lua")
dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_gate_d.lua")
dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_wizard_rules.lua")
dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sv_human_soldier_progression.lua")
dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sv_run_manager.lua")
dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sv_loot_director.lua")

local RunManager = LOD.RunManager
local Loot = LOD.LootDirector
local SoldierProgression = LOD.SoldierProgression
local CPS = LOD.CharacterProgressionSystem
local Rules = LOD.RPGAbilityRules

local errors = {}
local function check(ok, message)
    if not ok then
        table.insert(errors, message)
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
        SetNW2Bool = function() end,
        SetNW2Int = function() end,
        SetNW2String = function() end,
        SetPos = function() end,
        SetEyeAngles = function() end,
        ChatPrint = function() end
    }
    return p
end

local allPlayers = {}
player.GetAll = function() return allPlayers end

-- Setup initial RunManager state
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

local p1 = createMockPlayer("steam_1001", "Player 1", 1)
local p2 = createMockPlayer("steam_1002", "Player 2", 2)
allPlayers = {p1, p2}

local ps1 = RunManager:_AdmitIdentity(p1)
local ps2 = RunManager:_AdmitIdentity(p2)

check(ps1 ~= nil and ps2 ~= nil, "Admitted player 1 and player 2 identities")
RunManager.State.ActiveIdentity["steam_1001"] = true
RunManager.State.ActiveIdentity["steam_1002"] = true

local hero1State = CPS:NewProgressionState("steam_1001", "hero", "hero")
hero1State.level = 5
hero1State.xp = 1250
hero1State.classId = "wizard"
hero1State.featIds = {"INT_MANA_BARRIER_1"}
ps1.progressionState = hero1State
ps1.lives = 1

local hero2State = CPS:NewProgressionState("steam_1002", "hero", "hero")
hero2State.level = 3
hero2State.xp = 600
hero2State.classId = "fighter"
ps2.progressionState = hero2State
ps2.lives = 3

-- 1. Hero State Preservation during Soldier Control
check(RunManager:IsSoldierControl(p1) == false, "P1 starts out not in Soldier control")
local soldier1 = RunManager:AttachSoldier(p1, 7701, 40, 1)
check(soldier1 ~= nil, "Attached Soldier to P1")
check(RunManager:IsSoldierControl(p1) == true, "P1 is now under Soldier control")
check(ps1.progressionState.level == 5 and ps1.progressionState.xp == 1250, "Hero 1 level and XP preserved untouched")

-- 2. Fresh Soldier Incarnation Properties
check(soldier1.soldierXP == 0, "Fresh Soldier incarnation has 0 SoldierXP")
check(soldier1.soldierIncarnation == true, "soldierIncarnation flag is true")
check(Rules:ProgressionState(p1) == soldier1, "Rules:ProgressionState returns active Soldier state")

-- 3. Soldier Leveling Isolation
SoldierProgression:Award(p1, 450, false)
check(soldier1.soldierXP == 450 and soldier1.level == 4, "Soldier 1 gained 450 XP and reached level 4")
check(ps1.progressionState.level == 5 and ps1.progressionState.xp == 1250, "Underlying Hero 1 state strictly unmutated")

-- 4. Soldier Retirement & Hero Restoration
RunManager:RetireSoldier(p1)
check(RunManager:IsSoldierControl(p1) == false, "P1 Soldier retired")
check(Rules:ProgressionState(p1) == hero1State, "Rules:ProgressionState reverted back to Hero 1 state")
check(p1.LODHumanSoldierProgressionState == nil, "LODHumanSoldierProgressionState is nil")

-- 5. Hero Elimination & Soldier Transition on Hero Death
ps1.lives = 1
p1:SetAlive(false)
RunManager:HandleDeath(p1)
check(ps1.lives == 0, "P1 lives decremented to 0")
check(ps1.eliminated == true, "P1 marked eliminated")
check(ps1.eliminatedSince ~= nil, "P1 eliminatedSince timestamp set")
check(RunManager:IsActivePlayer(p1) == false, "P1 removed from ActiveIdentity")

-- Simulate spawn as Soldier after respawn delay
RunManager:ApplyPlayerState(p1)
check(RunManager:IsSoldierControl(p1) == true, "P1 automatically attached as Soldier on spawn")
check(Rules:ProgressionState(p1).soldierXP == 0, "New Soldier incarnation starts with 0 SoldierXP")

-- 6. Soldier Death & Reincarnation Reset
SoldierProgression:Award(p1, 250, false)
check(Rules:ProgressionState(p1).soldierXP == 250, "Soldier 1 accumulated 250 XP")
p1:SetAlive(false)
RunManager:HandleDeath(p1)
check(RunManager:IsSoldierControl(p1) == false, "Soldier state retired immediately on Soldier death")

RunManager:ApplyPlayerState(p1)
check(RunManager:IsSoldierControl(p1) == true, "Fresh Soldier state attached on respawn")
check(Rules:ProgressionState(p1).soldierXP == 0, "Fresh Soldier incarnation resets to 0 SoldierXP")

-- 7. Return-to-Hero Queue Ordering (Priority 1: Oldest Eliminated Hero)
mockTime = 1100
ps1.eliminatedSince = 1000

-- Eliminate P2 Hero as well
RunManager:RetireSoldier(p1)
ps2.lives = 1
p2:SetAlive(false)
RunManager:HandleDeath(p2)
ps2.eliminatedSince = 1050

local queue = RunManager:_SortedHeroQueueCandidates()
check(#queue >= 2, "Hero queue candidates found")
check(queue[1].id == "steam_1001", "Queue priority 1 is P1 (eliminatedSince 1000 < 1050)")
check(queue[2].id == "steam_1002", "Queue priority 2 is P2 (eliminatedSince 1050)")

-- 8. Return-to-Hero Queue Ordering (Priority 2: Non-Hero Spectator)
local p3 = createMockPlayer("steam_1003", "Player 3", 3)
table.insert(allPlayers, p3)
RunManager.State.WaitingSince["steam_1003"] = 900 -- Spectator waiting since 900
queue = RunManager:_SortedHeroQueueCandidates()
check(queue[1].id == "steam_1001" and queue[2].id == "steam_1002", "Eliminated Heroes take priority over non-Hero spectator")
check(queue[3].id == "steam_1003", "Non-Hero spectator is 3rd in queue")

-- 9. Revival Ineligibility during Active Soldier Control
RunManager:ApplyPlayerState(p1) -- P1 active as Soldier
p2:SetAlive(false) -- P2 dead spectating
RunManager:RetireSoldier(p2)

local revId, revState = Loot:_OldestEliminatedTeammate("steam_1002")
check(revId == nil or revId ~= "steam_1001", "P1 skipped for Extra Life revival while active as Soldier")

-- 10. Revival Eligibility when Spectating (Dead Soldier)
p1:SetAlive(false)
RunManager:RetireSoldier(p1) -- P1 Soldier died, spectating
revId, revState = Loot:_OldestEliminatedTeammate("steam_1002")
check(revId == "steam_1001", "P1 selected for Extra Life revival while dead/spectating")

-- 11. Hero Restoration on Extra Life Revival
ps2.lives = 4 -- P2 has max lives, forcing Extra Life to revive eliminated teammate P1
local okLife, msgLife = Loot:_GrantExtraLife(p2)
check(okLife == true, "Extra Life granted to revive P1: " .. tostring(msgLife))
check(ps1.eliminated == false and ps1.lives == 1, "P1 revived with 1 life and eliminated=false")
check(RunManager:IsActivePlayer(p1) == true, "P1 restored to ActiveIdentity")
RunManager:ApplyPlayerState(p1)
check(RunManager:IsSoldierControl(p1) == false, "P1 spawned as Hero, not Soldier")
check(Rules:ProgressionState(p1) == hero1State, "P1 active state is Hero 1 state")

-- 12. Cooperative Party Wipe with Active Soldiers
RunManager.State.Failed = false
ps1.lives = 0; ps1.eliminated = true; RunManager.State.ActiveIdentity["steam_1001"] = nil
ps2.lives = 0; ps2.eliminated = true; RunManager.State.ActiveIdentity["steam_1002"] = nil
RunManager:ApplyPlayerState(p1) -- P1 alive as Soldier
p1:SetAlive(true)

local wipe = RunManager:EvaluateWipe()
check(wipe == true, "EvaluateWipe did not trigger party wipe when all Heroes eliminated")
RunManager.State.Failed = false -- Reset failure state for next tests

-- 13. Level Clear Reset & Advancement
RunManager.State.LevelCleared = true
RunManager.State.Failed = false
RunManager:AdvanceLevel()
check(RunManager.State.Level == 2, "Level advanced to 2")
check(ps1.lives == 1 and ps1.eliminated == false, "P1 lives reset to 1 on next level")
check(ps2.lives == 1 and ps2.eliminated == false, "P2 lives reset to 1 on next level")
check(RunManager:IsSoldierControl(p1) == false and RunManager:IsSoldierControl(p2) == false, "All Soldiers retired on next level advance")

-- 14. Multi-Cycle Safety & Idempotence
for cycle = 1, 3 do
    ps1.lives = 0
    ps1.eliminated = true
    RunManager.State.ActiveIdentity["steam_1001"] = nil
    local st, err = RunManager:AttachSoldier(p1)
    if not st then print("ATTACH ERROR:", err) end
    RunManager:ApplyPlayerState(p1)
    local isSol = RunManager:IsSoldierControl(p1)
    check(isSol == true, "Cycle " .. cycle .. ": Attached Soldier (got " .. tostring(isSol) .. ")")
    SoldierProgression:Award(p1, 100, false)
    RunManager:HandleDeath(p1)
    check(RunManager:IsSoldierControl(p1) == false, "Cycle " .. cycle .. ": Retired Soldier")
    RunManager:RetireSoldier(p1) -- Duplicate retire call
    check(RunManager:IsSoldierControl(p1) == false, "Cycle " .. cycle .. ": Idempotent duplicate retire")
end
check(hero1State.level == 5 and hero1State.xp == 1250, "Hero 1 state remained completely uncorrupted after 3 cycles")

-- Print results
if #errors == 0 then
    print("HUMAN_SOLDIER_LIFECYCLE_HARNESS_PASS — All 15 requirements verified with 0 discrepancies.")
else
    print("HUMAN_SOLDIER_LIFECYCLE_HARNESS_FAIL — Discrepancies found:")
    for _, err in ipairs(errors) do
        print("  - " .. err)
    end
end
