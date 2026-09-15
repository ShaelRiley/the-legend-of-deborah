-- Human Soldier RPG & Return-to-Hero Lifecycle Deterministic Validator (AG-007R)
local root = "."
local luaType = type
type = function(value)
    if luaType(value) == "table" and value._isEntity then
        return value.IsPlayer and value:IsPlayer() and "Player" or "Entity"
    end
    return luaType(value)
end

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
    local hooks = {}
    hook = {Add = function(event, name, fn)
        hooks[event] = hooks[event] or {}; hooks[event][name] = fn
    end, GetTable = function() return hooks end, Run = function(event, ...)
        for _, fn in pairs(hooks[event] or {}) do fn(...) end
    end}
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
    IsValid = function(v) return luaType(v) == "table" and v._isValid == true end
    isentity = function(v) return luaType(v) == "table" and v._isEntity == true end
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
    game = {
        GetMap = function() return "gm_flatgrass" end,
        GetAmmoName = function(id) return id == 10 and "Grenade" or "Buckshot" end
    }
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
local Rules = LOD.RPGAbilityRules

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
    local ammo = {}
    local armor = 0
    local activeClass = nil
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
        Spawn = function(self) alive = true; hook.Run("PlayerSpawn", self) end,
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
        SetArmor = function(_, value) armor = value end,
        Armor = function() return armor end,
        StripWeapons = function() weapons = {}; activeClass = nil end,
        RemoveAllAmmo = function() ammo = {} end,
        GetWeapons = function() return weapons end,
        GetAmmo = function() return ammo end,
        SetAmmo = function(_, amount, ammoID) ammo[ammoID] = amount end,
        Give = function(_, cls)
            local clip1, clip2 = 30, 0
            local w = {_isValid = true, GetClass = function() return cls end,
                Clip1 = function() return clip1 end, Clip2 = function() return clip2 end,
                SetClip1 = function(_, value) clip1 = value end,
                SetClip2 = function(_, value) clip2 = value end,
                GetPrimaryAmmoType = function() return 1 end}
            table.insert(weapons, w)
            activeClass = activeClass or cls
            return w
        end,
        GetWeapon = function(_, cls)
            for _, w in ipairs(weapons) do if w:GetClass() == cls then return w end end
            return nil
        end,
        HasWeapon = function(self, cls) return self:GetWeapon(cls) ~= nil end,
        GetActiveWeapon = function(self) return activeClass and self:GetWeapon(activeClass) or nil end,
        SelectWeapon = function(_, cls) activeClass = cls end,
        GetAmmoCount = function(_, ammoID) return ammo[ammoID] or 0 end,
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
ps1.progressionState = hero1State
ps1.lives = 1

local hero2State = CPS:NewProgressionState("steam_1002", "hero", "hero")
hero2State.level = 3
hero2State.xp = 600
hero2State.classId = "fighter"
ps2.progressionState = hero2State
ps2.lives = 3

-- A normal Hero death snapshots the still-owned native loadout even though the
-- engine already reports Alive() == false, then restores that exact run state.
local pistol = p2:Give("weapon_pistol")
local shotgun = p2:Give("weapon_shotgun")
pistol:SetClip1(7); shotgun:SetClip1(3); p2:SelectWeapon("weapon_shotgun")
p2:SetAmmo(19, 1); p2:SetAmmo(4, 10); p2:SetArmor(27)
local retainedEquipment = {items={hat={definitionId="hat",count=1},
    healing_potion={definitionId="healing_potion",count=2}},
    slots={head="hat",throwable="healing_potion"}}
ps2.equipment = retainedEquipment
p2:SetAlive(false)
hook.Run("PlayerDeath", p2, nil, p1)
check(ps2.lives == 2 and ps2.equipment == retainedEquipment,
    "Respawn retention keeps wearable and throwable equipment records")
check(#ps2.inventory.weapons == 2 and ps2.inventory.activeWeaponClass == "weapon_shotgun"
    and ps2.inventory.ammo[1] == 19 and ps2.inventory.ammo[10] == nil and ps2.armor == 27,
    "PlayerDeath captures weapons, active selection, reserve ammo and armor without stock grenades")
p2:StripWeapons(); p2:RemoveAllAmmo(); p2:SetArmor(0)
p2:Spawn()
local restoredPistol, restoredShotgun = p2:GetWeapon("weapon_pistol"), p2:GetWeapon("weapon_shotgun")
check(IsValid(restoredPistol) and restoredPistol:Clip1() == 7
    and IsValid(restoredShotgun) and restoredShotgun:Clip1() == 3
    and p2:GetAmmoCount(1) == 19 and p2:Armor() == 27,
    "Hero respawn restores native weapons, magazines, reserve ammunition and armor")
check(p2:GetActiveWeapon() == restoredShotgun and ps2.equipment == retainedEquipment,
    "Hero respawn restores the wielded weapon without replacing the equipment bag")
ps2.lives = 3
ps2.respawnAt = nil
p2.LODHandledRunDeath = nil

print("--- AG-007R ASSERTION TESTS A THRU T ---")

-- A. Final Hero death preserves Hero state and enters correct eliminated/queue lifecycle without automatically becoming Soldier
mockTime = 1000
p1:SetAlive(false)
RunManager:HandleDeath(p1)
check(ps1.lives == 0 and ps1.eliminated == true, "A. P1 final death decrements lives to 0 and marks eliminated")
check(ps1.eliminatedSince == 1000, "A. P1 eliminatedSince set to mockTime 1000")
check(RunManager:IsSoldierControl(p1) == false, "A. P1 does NOT automatically become Soldier on Hero death")

-- B. Entering Soldier control is a distinct explicit transition
local okJoin, joinErr = RunManager:JoinSoldierRole(p1)
check(okJoin == true, "B. JoinSoldierRole succeeded explicitly")
check(RunManager:IsSoldierControl(p1) == true, "B. P1 is now under active Soldier control")

-- C. Active Soldier control does not alter Hero state
check(ps1.progressionState.level == 5 and ps1.progressionState.xp == 1250, "C. Hero 1 level (5) and XP (1250) preserved untouched during Soldier play")

-- AG-007R2 Safety & Invariant Tests:

-- 1. ACTIVE_HERO calling ReturnToHeroQueue must be rejected without mutating state
ps2.lives = 3
ps2.eliminated = false
local okActiveRet, errActiveRet = RunManager:ReturnToHeroQueue(p2)
check(okActiveRet == false and errActiveRet == "active hero cannot return to hero queue", "AG-007R2: Active Hero ReturnToHeroQueue rejected")
check(ps2.lives == 3 and ps2.eliminated == false, "AG-007R2: Active Hero state (lives=3, eliminated=false) preserved untouched")

-- 2. ACTIVE_SOLDIER ineligibility & ReviveIdentity safety
check(RunManager:IsHeroRevivalQueueEligible("steam_1001") == false, "AG-007R2: Active Soldier P1 is NOT revival queue eligible")
local okSolRev, errSolRev = RunManager:ReviveIdentity("steam_1001")
check(okSolRev == false and errSolRev == "ineligible", "AG-007R2: ReviveIdentity on Active Soldier P1 rejected")
check(RunManager:IsSoldierControl(p1) == true, "AG-007R2: ReviveIdentity did NOT retire Active Soldier as a side effect")
check(ps1.lives == 0 and ps1.eliminated == true, "AG-007R2: Hero state preserved as eliminated with 0 lives")

-- 3. SOLDIER_RESPAWN_WAIT ineligibility & ReviveIdentity safety
p1:SetAlive(false)
RunManager:HandleDeath(p1) -- Soldier dies -> SOLDIER_RESPAWN_WAIT
check(ps1.soldierRespawnWait == true or (ps1.respawnAt and ps1.respawnAt > CurTime()), "AG-007R2: P1 entered SOLDIER_RESPAWN_WAIT")
check(RunManager:IsHeroRevivalQueueEligible("steam_1001") == false, "AG-007R2: P1 in SOLDIER_RESPAWN_WAIT is NOT revival queue eligible")
local okWaitRev, errWaitRev = RunManager:ReviveIdentity("steam_1001")
check(okWaitRev == false and errWaitRev == "ineligible", "AG-007R2: ReviveIdentity during SOLDIER_RESPAWN_WAIT rejected")
check(ps1.lives == 0 and ps1.eliminated == true, "AG-007R2: Hero state preserved during failed wait revival")

-- 4. ReturnToHeroQueue from SOLDIER_RESPAWN_WAIT restores queue eligibility & preserves original eliminatedSince
local okWaitRet = RunManager:ReturnToHeroQueue(p1)
check(okWaitRet == true, "AG-007R2: ReturnToHeroQueue from SOLDIER_RESPAWN_WAIT succeeded")
check(ps1.soldierRespawnWait == nil and ps1.respawnAt == nil, "AG-007R2: Soldier respawn wait state cleared")
check(ps1.eliminatedSince == 1000, "AG-007R2: Original eliminatedSince (1000) preserved after wait return")
check(RunManager:IsHeroRevivalQueueEligible("steam_1001") == true, "AG-007R2: P1 is now revival queue eligible")

-- 5. Subsequent valid queue revival succeeds
local okValidRev, msgValidRev = RunManager:ReviveIdentity("steam_1001")
check(okValidRev == true, "AG-007R2: Valid queue revival succeeded")
check(ps1.lives == 1 and ps1.eliminated == false and ps1.eliminatedSince == nil, "AG-007R2: P1 Hero state restored after valid revival")

-- 6. Canonical AI Soldier authority generation check
local archetype = LOD.Config and LOD.Config.Encounter and LOD.Config.Encounter.Archetypes and LOD.Config.Encounter.Archetypes.soldier
check(archetype ~= nil and archetype.baseHP == 35 and string.lower(archetype.model) == "models/combine_soldier.mdl", "AG-007R2: Canonical AI Soldier archetype authority verified (baseHP=35, model=models/combine_soldier.mdl)")

-- D. Active Soldier is excluded from overflow revival
local revId, revState = Loot:_OldestEliminatedTeammate("steam_1002")
check(revId == nil, "D. P1 skipped for Extra Life revival while active as Soldier")

-- E. Revival occurring while Soldier-controlled is missed, not banked
ps2.lives = 4 -- P2 has max lives
local okLife, msgLife = Loot:_GrantExtraLife(p2)
check(okLife == false, "E. Extra Life revival missed/failed when only eliminated Hero is active Soldier")

-- F. Return-to-Hero Queue retires Soldier, frees control state, preserves original Hero elimination timestamp, and restores future revival eligibility
ps1.lives = 0; ps1.eliminated = true; ps1.eliminatedSince = 1000
RunManager:JoinSoldierRole(p1)
local okRet = RunManager:ReturnToHeroQueue(p1)
check(okRet == true, "F. ReturnToHeroQueue succeeded")
check(RunManager:IsSoldierControl(p1) == false, "F. Soldier retired and control state freed")
check(ps1.eliminatedSince == 1000, "F. Original Hero elimination timestamp (1000) strictly preserved")
revId, revState = Loot:_OldestEliminatedTeammate("steam_1002")
check(revId == "steam_1001", "F. P1 restored to future Extra Life revival eligibility")

-- G & T. Overflow revival chooses oldest eligible eliminated Hero using canonical tie-break
mockTime = 1100
p2:SetAlive(false)
ps2.lives = 1
RunManager:HandleDeath(p2) -- P2 eliminated at mockTime 1100
ps2.lives = 0
ps2.eliminated = true
ps2.eliminatedSince = 1100

revId, revState = Loot:_OldestEliminatedTeammate("none")
check(revId == "steam_1001", "G/T. Oldest eliminated Hero (1000 < 1100) chosen for revival")

-- Test tie-break by ordinal when eliminatedSince is identical
ps2.eliminatedSince = 1000
ps1.ordinal = 1
ps2.ordinal = 2
revId, revState = Loot:_OldestEliminatedTeammate("none")
check(revId == "steam_1001", "G/T. Deterministic ordinal tie-break chooses P1 (ordinal 1 < 2)")

-- H. There is no stale non-Hero fallback
ps1.eliminated = false
ps2.eliminated = false
revId, revState = Loot:_OldestEliminatedTeammate("none")
check(revId == nil and revState == nil, "H. No non-Hero fallback exists when no eligible eliminated Hero exists")

-- Reset states for next tests
ps1.eliminated = true; ps1.eliminatedSince = 1000
ps2.eliminated = true; ps2.eliminatedSince = 1100

-- I. No eligible Hero produces canonical no-recipient outcome
ps1.eliminated = false; ps1.lives = 3
ps2.eliminated = false; ps2.lives = 4 -- P2 max lives
okLife, msgLife = Loot:_GrantExtraLife(p2)
check(okLife == false, "I. Extra Life at max lives with no eliminated teammate produces no-recipient outcome")

-- J & K. PromoteWaitingSpectators / revival accounting consumes slot ONLY after ACTUAL successful restoration
RunManager.State.Failed = false
ps1.lives = 0; ps1.eliminated = true; RunManager.State.ActiveIdentity["steam_1001"] = nil
ps2.lives = 0; ps2.eliminated = true; RunManager.State.ActiveIdentity["steam_1002"] = nil
local count = RunManager:PromoteWaitingSpectators()
check(count == 0, "J/K. PromoteWaitingSpectators returns 0 and consumes NO active slots when candidates are eliminated Heroes")

-- L. Soldier death consumes zero Hero lives
RunManager.State.Failed = false
local okSol, solErr = RunManager:JoinSoldierRole(p1)
check(okSol == true and RunManager:IsSoldierControl(p1) == true, "L. P1 joined Soldier role successfully")
p1:SetAlive(false)
RunManager:HandleDeath(p1)
RunManager.State.Failed = false
check(RunManager:IsSoldierControl(p1) == false, "L. Soldier retired on death")
check(ps1.lives == 0, "L. Soldier death consumed 0 Hero lives (lives remains 0)")

-- M. Soldier death uses exact 20-second replacement delay
check(ps1.respawnAt == mockTime + 20, "M. Soldier death sets exact 20-second respawn delay (mockTime+20)")
mockTime = mockTime + 10
local okEarly, earlyErr = RunManager:JoinSoldierRole(p1)
check(okEarly == false and earlyErr == "soldier respawn delay active", "M. Rejoining Soldier rejected during 20s respawn delay")

-- N & O. Post-delay Soldier incarnation is fresh and old Soldier XP/rank cannot leak
mockTime = mockTime + 15 -- Now past 20s delay
local okLate, lateErr = RunManager:JoinSoldierRole(p1)
check(okLate == true, "N/O. Fresh Soldier joined after 20s replacement delay")
local freshSoldier = SoldierProgression:StateFor(p1)
check(freshSoldier.soldierXP == 0, "N/O. Fresh Soldier incarnation starts with 0 SoldierXP")

-- P. Soldier -> Hero Queue -> Soldier and restoration cycles remain deterministic & leak-free
RunManager:ReturnToHeroQueue(p1)
check(RunManager:IsSoldierControl(p1) == false, "P. Returned to Hero Queue")
RunManager:JoinSoldierRole(p1)
check(RunManager:IsSoldierControl(p1) == true, "P. Re-joined Soldier role cleanly")
RunManager:ReturnToHeroQueue(p1)

-- Q. Active Soldiers do not prevent true cooperative party wipe
ps1.lives = 0; ps1.eliminated = true; RunManager.State.ActiveIdentity["steam_1001"] = nil
ps2.lives = 0; ps2.eliminated = true; RunManager.State.ActiveIdentity["steam_1002"] = nil
RunManager:JoinSoldierRole(p1) -- P1 active as Soldier
p1:SetAlive(true)
RunManager.State.Failed = false
local wipe = RunManager:EvaluateWipe()
check(wipe == true and RunManager.State.Failed == true, "Q. Active Soldier does NOT prevent cooperative party wipe when all Heroes are eliminated")
RunManager.State.Failed = false

-- R. Next-level transition retires Soldier state and applies canonical Hero comeback rules
RunManager.State.LevelCleared = true
RunManager:AdvanceLevel()
check(RunManager.State.Level == 2, "R. Advanced to Level 2")
check(RunManager:IsSoldierControl(p1) == false and RunManager:IsSoldierControl(p2) == false, "R. Active Soldiers retired on level advance")
check(ps1.lives == 1 and ps1.eliminated == false, "R. P1 Hero restored to 1 life on level advance")
check(ps2.lives == 1 and ps2.eliminated == false, "R. P2 Hero restored to 1 life on level advance")

-- S. Duplicate transition callbacks remain idempotent
check(RunManager:RetireSoldier(p1) == false, "S. Duplicate RetireSoldier is idempotent")
ps1.eliminated = true; ps1.lives = 0
check(RunManager:ReturnToHeroQueue(p1) == true, "S. Duplicate ReturnToHeroQueue on queued player is idempotent")

-- Credit comes from the committed life transaction, not a separate death hook.
RunManager.State.Failed = false
RunManager.State.LevelCleared = false
RunManager.State.BuildReady = true
assert(RunManager:JoinSoldierRole(p1))
local credited = SoldierProgression:StateFor(p1)
ps2.lives = 2; ps2.eliminated = false
RunManager.State.ActiveIdentity["steam_1002"] = true
p2:Spawn()
p2:SetAlive(false)
RunManager:HandleDeath(p2, p1)
check(ps2.lives == 1 and credited.soldierXP == 50,
    "Actual Hero life transaction awards exactly 50 SoldierXP")
RunManager:HandleDeath(p2, p1)
check(ps2.lives == 1 and credited.soldierXP == 50, "Duplicate death cannot consume another life or credit")

local queued = {}
timer.Simple = function(_, fn) queued[#queued+1] = fn end
local failed = 0
local originalFail = RunManager.FailCampaign
RunManager.FailCampaign = function() failed = failed + 1 end
RunManager:RequestWipeEvaluation()
RunManager:RequestWipeEvaluation()
check(#queued == 1 and failed == 0, "Wipe is coalesced until the current damage batch ends")
local originalState = RunManager.State
RunManager.State = {}
queued[1]()
check(failed == 0, "An old campaign's queued wipe cannot fail its replacement")
RunManager.State = originalState
RunManager.FailCampaign = originalFail

queued = {}
local applications = 0
local originalApply = RunManager.ApplyPlayerState
RunManager.ApplyPlayerState = function() applications = applications + 1 end
p2:SetAlive(true)
hook.GetTable().PlayerSpawn.LOD_PlayerSpawn(p2)
hook.GetTable().PlayerSpawn.LOD_PlayerSpawn(p2)
queued[1](); queued[2]()
check(applications == 1, "Only the latest spawn callback applies a player loadout")
queued = {}
hook.GetTable().PlayerSpawn.LOD_PlayerSpawn(p2)
p2:SetAlive(false); queued[1]()
check(applications == 1, "Spawn followed by immediate death cannot restore dead-player HP or inventory")
RunManager.ApplyPlayerState = originalApply

-- Individualized loot has one grant authority even if Touch/Use repeat/reenter.
p2:SetAlive(true); p2.EmitSound = function() end
local pickup = {_isValid=true, LODLootOwnerIdentity="steam_1002", LODLootKind="health",
    LODLootStaticId="audit-static", LODLootLevelSeed=RunManager.State.LevelSeed, EntIndex=function() return 300 end}
local grants = 0
local originalGrant = Loot._GrantHealth
Loot._GrantHealth = function(self, ply)
    grants = grants + 1
    check(not self:Collect(pickup, ply), "Nested loot grant is rejected at the authority")
    return true
end
check(not Loot:Collect(pickup, p1), "Wrong owner/Soldier cannot claim individualized Hero loot")
check(Loot:Collect(pickup, p2) and grants == 1, "Owner receives one grant")
check(not Loot:Collect(pickup, p2) and grants == 1, "Repeated direct collection does not duplicate resources")
local duplicatePickup = {_isValid=true, LODLootOwnerIdentity="steam_1002", LODLootKind="health",
    LODLootStaticId="audit-static", LODLootLevelSeed=RunManager.State.LevelSeed}
check(not Loot:Collect(duplicatePickup, p2), "Consumed static identity rejects a duplicate entity")
pickup.LODCollected=nil;pickup.LODLootStaticId=nil
Loot._GrantHealth = function() return false end
check(not Loot:Collect(pickup,p2) and not pickup.LODCollecting and not pickup.LODCollected,
    "A currently unusable pickup remains available for a later legitimate collection")
Loot._GrantHealth = originalGrant

-- Hero spawn consumes Tetris overfill alongside the RPG health baseline.
local appliedHP, appliedMaxHP, remainingOverfill
p2.SetHealth = function(_, hp) appliedHP = hp end
p2.SetMaxHealth = function(_, hp) appliedMaxHP = hp end
p2.SetNW2Int = function(_, key, value)
    if key == "LOD_TetrisNextLifeBonus" then remainingOverfill = value end
end
ps2.progressionState.derivedStats.maxHP = 175
ps2.nextLifeHPBonus = 30
ps2.deploymentComplete = true
RunManager.State.BuildReport = {startPos = Vector(0, 0, 0)}
RunManager:ApplyPlayerState(p2)
check(appliedMaxHP == 175 and appliedHP == 205 and ps2.nextLifeHPBonus == 0,
    "Hero respawn grants RPG MaxHP plus earned overfill in one transaction")
check(remainingOverfill == 0,
    "Consumed overfill is also cleared from the player-facing state")
local retiredProfile = SoldierProgression:StateFor(p1)
SoldierProgression:Retire(retiredProfile)
check(not RunManager:IsSoldierControl(p1), "A captured retired profile cannot keep Soldier control active")

-- Revival may commit eligibility now, but its deferred spawn cannot enter a new run.
ps1.lives=0; ps1.eliminated=true; ps1.soldierRespawnWait=nil
RunManager.State.ActiveIdentity["steam_1001"]=nil
p1:SetAlive(false); queued={}
check(RunManager:ReviveIdentity("steam_1001"), "Queued Hero revival is admitted through the slot authority")
local revivalState=RunManager.State
RunManager.State={}
for _,fn in ipairs(queued) do fn() end
check(not p1:Alive(), "Old revival callback cannot spawn into a replacement campaign")
RunManager.State=revivalState

-- Final summary
if #errors == 0 then
    print("HUMAN_SOLDIER_LIFECYCLE_HARNESS_PASS — AG-007R2 verified with 0 discrepancies.")
else
    print("HUMAN_SOLDIER_LIFECYCLE_HARNESS_FAIL — Discrepancies found:")
    for _, err in ipairs(errors) do
        print("  - " .. err)
    end
    error("Human Soldier lifecycle validation failed")
end
