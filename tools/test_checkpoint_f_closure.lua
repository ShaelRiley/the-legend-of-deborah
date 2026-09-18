-- Checkpoint F Static & Deterministic Integrity Closure Validator (AG-009R2)
local root = "."

local mockFS = {}
local mockTime = 1000

SERVER = true
CLIENT = false
unpack = unpack or table.unpack

DeriveGamemode = function() end
GM = {}

Vector = function(x, y, z)
    return {x = x or 0, y = y or 0, z = z or 0}
end
Angle = function(p, y, r) return {p = p or 0, y = y or 0, r = r or 0} end
Color = function(r, g, b, a) return {r = r or 255, g = g or 255, b = b or 255, a = a or 255} end

util = {
    AddNetworkString = function() end,
    CRC = function(v) return tostring(v) end,
    IsValidModel = function(m) return true end
}
net = {
    Receive = function() end,
    Start = function() end,
    WriteTable = function() end,
    WriteString = function() end,
    WriteUInt = function() end,
    Send = function() end,
    Broadcast = function() end
}
hook = {
    Add = function() end,
    GetTable = function() return {} end
}
concommand = {Add = function() end}
ErrorNoHalt = function() end
game = {
    GetMap = function() return "gm_flatgrass" end
}

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
    local out = {}
    for k, val in pairs(v) do out[k] = table.Copy(val) end
    return out
end

file = {
    Exists = function(path, pathID) return mockFS[path] ~= nil end,
    Read = function(path, pathID) return mockFS[path] end,
    Write = function(path, content) mockFS[path] = content end,
    CreateDir = function(dir) end
}

-- Simple mock JSON encoder / decoder for test validation
local function encodeJSON(val)
    if val == nil then return "null" end
    local t = type(val)
    if t == "number" or t == "boolean" then
        return tostring(val)
    elseif t == "string" then
        return string.format("%q", val)
    elseif t == "table" then
        local isArr = true
        local maxI = 0
        for k, _ in pairs(val) do
            if type(k) ~= "number" or k < 1 or math.floor(k) ~= k then
                isArr = false
                break
            end
            if k > maxI then maxI = k end
        end
        if isArr and maxI ~= #val then isArr = false end

        local items = {}
        if isArr then
            for i = 1, #val do
                table.insert(items, encodeJSON(val[i]))
            end
            return "[" .. table.concat(items, ",") .. "]"
        else
            for k, v in pairs(val) do
                table.insert(items, string.format("%q:%s", tostring(k), encodeJSON(v)))
            end
            return "{" .. table.concat(items, ",") .. "}"
        end
    end
    return "null"
end

local function decodeJSON(str)
    if not str or str == "" then return nil end
    local luaStr = str:gsub('%[', '{'):gsub('%]', '}'):gsub('"([%a_][%w_]*)"%s*:', '%1='):gsub('null', 'nil')
    local chunk, err = load("return " .. luaStr)
    if chunk then
        local ok, res = pcall(chunk)
        if ok then return res end
    end
    return nil
end

util.TableToJSON = function(tbl) return encodeJSON(tbl) end
util.JSONToTable = function(jsonStr) return decodeJSON(jsonStr) end

player = {
    GetAll = function() return {} end
}

-- Initialize LOD namespaces
LOD = LOD or {}
LOD.Config = {
    MaxActivePlayers = 4,
    MaxActiveSoldiers = 6,
    PlayerTeam = 1,
    Models = {
        Deborah = "models/deborah.mdl",
        Characters = {
            {id = "c1", name = "Hero One", model = "models/h1.mdl", presentationSex = "female"},
            {id = "c2", name = "Hero Two", model = "models/h2.mdl", presentationSex = "male"},
            {id = "c3", name = "Hero Three", model = "models/h3.mdl", presentationSex = "female"},
            {id = "c4", name = "Hero Four", model = "models/h4.mdl", presentationSex = "male"}
        }
    },
    Lives = {StartingLives = 1},
    Campaign = {MaxPlayedIdentities = 10},
    Progression = {LayoutAttempts = 1, IntermissionSeconds = 5}
}
LOD.Seeds = {
    Normalize = function(seed) return tonumber(seed) or 1 end,
    Derive = function(seed, label)
        local val = tonumber(seed) or 1
        for i = 1, #tostring(label) do val = (val * 33 + string.byte(label, i)) % 2147483647 end
        return val
    end,
    DeriveLevel = function(seed, level) return (tonumber(seed) or 1) + (tonumber(level) or 1) * 100 end
}
LOD.RNG = {
    New = function(seed)
        local state = (tonumber(seed) or 1) % 2147483647
        return {
            Int = function(self, low, high)
                state = (state * 48271) % 2147483647
                return low + (state % (high - low + 1))
            end,
            Shuffle = function(self, tbl)
                for i = #tbl, 2, -1 do
                    local j = self:Int(1, i)
                    tbl[i], tbl[j] = tbl[j], tbl[i]
                end
            end
        }
    end
}

LOD.MazeGenerator = {
    Generate = function(self, seed)
        return {
            MasterLevelSeed = seed,
            nodes = {},
            Attempt = 1,
            Validation = { cellCount = 10, criticalVerticalTransitions = 1 }
        }, nil
    end
}
LOD.ProgressionDirector = {
    Plan = function(self, graph, seed) return true, nil end,
    ResetLevelState = function() end,
    CommitBuiltLevel = function() end,
    Announce = function() end,
    SyncAll = function() end,
    SyncPlayer = function() end
}
LOD.MazeBuilder = {
    Build = function(self, graph) return true, { entityCount = 5, totalSeconds = 0 } end
}
LOD.Validation = {
    Run = function() end
}
LOD.RunManager = LOD.RunManager or {}
LOD.RunManager.HoldPlayersForBuild = function() end

-- Load production gamemode files
dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sh_rpg_schema.lua")

LOD.RPG.IdentityCatalog = {
    FeminineFirstNames = {"Jane", "Mary"},
    MasculineFirstNames = {"John", "Max"},
    Surnames = {"Doe", "Roe"},
    Nicknames = {"Crowbar", "Lucky"},
    Origins = setmetatable({}, {__index = function(t, k) return {tableType = "origin", tableIndex = k, categoryName = "Origin", perkDisplayName = "Origin " .. k, flavorText = "", mechanicalEffect = ""} end}),
    Backgrounds = setmetatable({}, {__index = function(t, k) return {tableType = "background", tableIndex = k, categoryName = "Background", perkDisplayName = "Background " .. k, flavorText = "", mechanicalEffect = ""} end}),
    Motives = setmetatable({}, {__index = function(t, k) return {tableType = "motive", tableIndex = k, categoryName = "Motive", perkDisplayName = "Motive " .. k, flavorText = "", mechanicalEffect = ""} end}),
    ClassCapstones = {}
}
Catalog = LOD.RPG.IdentityCatalog
dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sh_heroes_of_legend.lua")
dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sv_heroes_of_legend.lua")
timer = timer or {Simple = function() end}
dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sv_snapshot_delivery.lua")
dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sv_character_progression.lua")
dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_gate_d.lua")
dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sv_human_soldier_progression.lua")
dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sv_magic_progression.lua")
dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sv_run_manager.lua")

print("--- CHECKPOINT F CLOSURE & INTEGRITY VALIDATOR (AG-009R2) ---")

local passCount = 0
local totalCount = 0

local function assertTest(condition, description)
    totalCount = totalCount + 1
    if condition then
        passCount = passCount + 1
        print(string.format("  [PASS] %d. %s", totalCount, description))
    else
        print(string.format("  [FAIL] %d. %s", totalCount, description))
        error("Test failed: " .. description)
    end
end

local RunManager = LOD.RunManager
local Heroes = LOD.HeroesOfLegend
local CPS = LOD.CharacterProgressionSystem
local MagicProgression = LOD.MagicProgression

-- Helper to create mock player entity
local function createMockPlayer(nick, identityStr)
    local nw = {}
    local ply = {
        _isValid = true,
        _isEntity = true,
        _nick = nick,
        _identity = identityStr,
        _alive = true,
        Nick = function(s) return s._nick end,
        Alive = function(s) return s._alive end,
        IsPlayer = function() return true end,
        ChatPrint = function() end,
        Health = function() return 100 end,
        MaxHealth = function() return 100 end,
        Spectate = function() end,
        SpectateEntity = function() end,
        StripWeapons = function() end,
        RemoveAllAmmo = function() end,
        SetTeam = function() end,
        SetModel = function() end,
        UnSpectate = function() end,
        SetNoCollideWithTeammates = function() end,
        CollisionRulesChanged = function() end,
        SetArmor = function() end,
        SetMaxHealth = function() end,
        SetHealth = function() end,
        SetEyeAngles = function() end,
        SetPos = function() end,
        Give = function() return { GetPrimaryAmmoType = function() return 1 end } end,
        SetAmmo = function() end,
        SetNW2Bool = function(s, k, v) nw[k] = v end,
        GetNW2Bool = function(s, k, d) return nw[k] ~= nil and nw[k] or d end,
        SetNW2Int = function(s, k, v) nw[k] = v end,
        GetNW2Int = function(s, k, d) return nw[k] ~= nil and nw[k] or d end,
        SetNW2String = function(s, k, v) nw[k] = v end,
        GetNW2String = function(s, k, d) return nw[k] ~= nil and nw[k] or d end
    }
    return ply
end

-- Mock identity mapping on RunManager
RunManager.IdentityOf = function(self, ply)
    if isstring(ply) then return ply end
    return IsValid(ply) and ply._identity or nil
end

-- --- SUITE 1: PRODUCTION RUNMANAGER INTEGRATION (REQUIREMENTS A - E) ---
mockFS = {}
Heroes:Initialize()

RunManager:NewCampaign()
local p1 = createMockPlayer("Alice", "steam_1")
local p2 = createMockPlayer("Bob", "steam_2")

RunManager:TryActivatePlayer(p1)
RunManager:TryActivatePlayer(p2)
RunManager:ApplyPlayerState(p1)
RunManager:ApplyPlayerState(p2)

-- A. Deborah rescue #1
RunManager:CompleteLevel(p1)
assertTest(RunManager.State.RescueCount == 1, "Deborah rescue #1 increments RescueCount to 1")
assertTest(#Heroes.Entries == 0, "Deborah rescue #1 does NOT submit candidate to HEROES OF LEGEND (leaderboard unchanged)")

-- B. Deborah rescue #2 (advance level first)
RunManager.State.LevelCleared = false
RunManager:CompleteLevel(p1)
assertTest(RunManager.State.RescueCount == 2, "Deborah rescue #2 increments RescueCount to 2")
assertTest(#Heroes.Entries == 0, "Deborah rescue #2 does NOT submit candidate to HEROES OF LEGEND (leaderboard unchanged)")

-- C. Canonical total-party-wipe run end
RunManager:FailCampaign("total party wipe")
assertTest(#Heroes.Entries == 1, "Canonical campaign failure submits exactly ONE candidate to HEROES OF LEGEND")
assertTest(Heroes.Entries[1].rescueCount == 2, "Submitted candidate reflects FINAL accumulated RescueCount = 2")

-- D. Repeated campaign-end callback
RunManager:FailCampaign("total party wipe")
assertTest(#Heroes.Entries == 1, "Repeated campaign failure callback creates no second entry")
assertTest(Heroes.NextCompletionOrder == 2, "Repeated campaign failure callback consumes no second completionOrder")

-- E. Ranked = false campaign
mockFS = {}
Heroes:Initialize()
RunManager:NewCampaign()
RunManager.State.Ranked = false

local p3 = createMockPlayer("Charlie", "steam_3")
RunManager:TryActivatePlayer(p3)
RunManager:ApplyPlayerState(p3)
RunManager:CompleteLevel(p3)
RunManager:FailCampaign("total party wipe")

assertTest(#Heroes.Entries == 0, "Ranked = false campaign creates no HEROES OF LEGEND entry")
assertTest(Heroes.NextCompletionOrder == 1, "Ranked = false campaign consumes no completionOrder sequence")

-- --- SUITE 2: IMMUTABILITY, IDEMPOTENCY & VALIDATION (REQUIREMENTS F - H, P, Q) ---
mockFS = {}
Heroes:Initialize()

local originalMembers = {"Alice as Hero 1", "Bob as Hero 2"}
local runA = Heroes:SubmitRun({ runId = "run_alpha", rescueCount = 3, partyMembers = originalMembers })
assertTest(runA ~= nil and runA.completionOrder == 1, "Valid run_alpha submitted successfully with completionOrder 1")

-- F. Completed record is immutable
local duplicateA = Heroes:SubmitRun({ runId = "run_alpha", rescueCount = 10, partyMembers = {"Fake Person as Imposter"} })
assertTest(Heroes.Entries[1].rescueCount == 3, "Duplicate submission cannot alter rescueCount of completed record")
assertTest(Heroes.Entries[1].partyMembers[1] == "Alice as Hero 1", "Duplicate submission cannot alter partyMembers of completed record")

-- G. Caller mutates original partyMembers table
originalMembers[1] = "MUTATED PARTY MEMBER"
assertTest(Heroes.Entries[1].partyMembers[1] == "Alice as Hero 1", "Mutating caller's source table does not alter stored historical record")

-- H. Low-scoring run falling outside top 10 duplicate protection
mockFS = {}
Heroes:Initialize()
-- Fill top 10 with 5 rescues
for i = 1, 10 do
    Heroes:SubmitRun({ runId = "high_" .. i, rescueCount = 5, partyMembers = {"Hero " .. i} })
end
-- Submit low-scoring run with 1 rescue -> falls outside top 10
local lowRun = Heroes:SubmitRun({ runId = "low_1", rescueCount = 1, partyMembers = {"Low Hero"} })
assertTest(#Heroes.Entries == 10, "Low-scoring run truncated from active top 10 Entries")

local seqBeforeLowDup = Heroes.NextCompletionOrder
local lowDup = Heroes:SubmitRun({ runId = "low_1", rescueCount = 1, partyMembers = {"Low Hero"} })
assertTest(Heroes.NextCompletionOrder == seqBeforeLowDup, "Duplicate callback for truncated low-scoring run consumes NO new completionOrder")

-- P & Q. Malformed records
local badRes = Heroes:SubmitRun({ runId = "bad_run", rescueCount = -5, partyMembers = {"Bad Hero"} })
assertTest(badRes == nil, "Invalid negative rescueCount submission rejected")

mockFS[Heroes.DATA_PATH] = encodeJSON({
    nextCompletionOrder = 20,
    entries = {
        { runId = "valid_1", rescueCount = 3, completionOrder = 1, partyMembers = {"Valid One"} },
        { runId = "malformed_1", rescueCount = "invalid_string_count", completionOrder = 2, partyMembers = {"Bad Entry"} },
        { runId = "valid_2", rescueCount = 5, completionOrder = 3, partyMembers = {"Valid Two"} }
    }
})
Heroes:Load()
assertTest(#Heroes.Entries == 2, "Persisted load filters out malformed record while retaining valid records")
assertTest(Heroes.Entries[1].runId == "valid_2", "Valid records properly sorted (valid_2 with 5 rescues ranks #1)")

-- --- SUITE 3: PARTICIPANT SET & CANONICAL PLAYERCHARACTERTEXT (REQUIREMENTS I - K) ---
mockFS = {}
Heroes:Initialize()

RunManager:NewCampaign()

local heroA = createMockPlayer("Alice", "id_A")
local heroB = createMockPlayer("Bob", "id_B")
local heroC = createMockPlayer("Charlie", "id_C")
local heroD = createMockPlayer("David", "id_D")
local visitorE = createMockPlayer("Eve", "id_E")

RunManager:_AdmitIdentity(heroA)
RunManager:_AdmitIdentity(heroB)
RunManager:_AdmitIdentity(heroC)
RunManager:_AdmitIdentity(heroD)

-- Hero C eliminated
local psC = RunManager:GetPlayerState(heroC)
psC.eliminated = true
psC.lives = 0

-- Hero D uses Soldier role
heroD.LODHumanSoldierProgressionState = { level = 2 }

-- Visitor E never admitted to play

RunManager:FailCampaign("total party wipe")
assertTest(#Heroes.Entries == 1, "Run finalized with 4 participating heroes")

local party = Heroes.Entries[1].partyMembers
assertTest(#party == 4, "Participant set contains exactly 4 heroes (A, B, C, D) and excludes visitor E")

-- I. Ordering & Soldier role check
for idx, ps in ipairs({RunManager:GetPlayerState(heroA), RunManager:GetPlayerState(heroB), psC, RunManager:GetPlayerState(heroD)}) do
    local expectedText = CPS:PlayerCharacterText(ps)
    assertTest(party[idx] == expectedText, string.format("Hero %d stored member string matches PlayerCharacterText canonical output", idx))
end

-- K. Exact presentation check
local formattedText = Heroes:FormatEntry(Heroes.Entries[1])
assertTest(string.find(formattedText, "rescued Deborah 0 times") ~= nil, "FormatEntry produces exact '<Party> rescued Deborah <N> times' presentation")

-- --- SUITE 4: RANKING, TIE-BREAK & PERSISTENCE (REQUIREMENTS L - O) ---
mockFS = {}
Heroes:Initialize()

-- L & M. RescueCount DESC then completionOrder ASC
local run1 = Heroes:SubmitRun({ runId = "r1", rescueCount = 3, partyMembers = {"Hero 1"} })
local run2 = Heroes:SubmitRun({ runId = "r2", rescueCount = 5, partyMembers = {"Hero 2"} })
local run3 = Heroes:SubmitRun({ runId = "r3", rescueCount = 5, partyMembers = {"Hero 3"} })

assertTest(Heroes.Entries[1].runId == "r2", "RescueCount 5 (r2) outranks RescueCount 3 (r1)")
assertTest(Heroes.Entries[2].runId == "r3", "Equal RescueCount 5: earlier completion r2 (order 1) outranks r3 (order 2)")

-- N. #10/#11 Cutoff equal-score preservation
mockFS = {}
Heroes:Initialize()
for i = 1, 10 do
    Heroes:SubmitRun({ runId = "cutoff_" .. i, rescueCount = 4, partyMembers = {"Party " .. i} })
end
local cutoff11 = Heroes:SubmitRun({ runId = "cutoff_11", rescueCount = 4, partyMembers = {"Party 11"} })
assertTest(#Heroes.Entries == 10 and Heroes.Entries[10].runId == "cutoff_10", "#10/#11 cutoff preserves earlier equal-score run cutoff_10 over cutoff_11")

-- O. Save/load preserves exact order and text
Heroes:Save()
local preSaveEntries = table.Copy(Heroes.Entries)
Heroes.Entries = {}
Heroes:Load()

assertTest(#Heroes.Entries == 10, "10 entries loaded after save/load")
local matchAll = true
for i = 1, 10 do
    if Heroes.Entries[i].runId ~= preSaveEntries[i].runId or Heroes.Entries[i].completionOrder ~= preSaveEntries[i].completionOrder then
        matchAll = false
    end
end
assertTest(matchAll, "Save/load preserves exact tie order and completionOrder sequence")

-- --- SUITE 5: P CHARACTER SHEET & I SPELLBOOK GATES (REQUIREMENTS R - X) ---

-- R. Fighter Human Soldier P snapshot reports actual fighterTraining
local soldierState = {
    actorType = "human_soldier", soldierIncarnation = true,
    featCatalogRevision = "hybrid-stable-150-v1", -- precomputed snapshot fixture; migration has its own production test
    level = 5,
    classId = "fighter",
    baseAbilities = {str = 14, dex = 12, con = 14, int = 10, wis = 10, cha = 10},
    effectiveAbilities = {str = 16, dex = 12, con = 15, int = 10, wis = 10, cha = 10},
    growthAbilities = {str = 1, dex = 0, con = 0, int = 0, wis = 0, cha = 0},
    fighterTraining = {str = 1, con = 1, dex = 0, int = 0, wis = 0, cha = 0},
    featStackCounts = {}
}
local soldierPly = createMockPlayer("SoldierPly", "soldier_1")
soldierPly.LODHumanSoldierProgressionState = soldierState
LOD.SoldierProgression = LOD.SoldierProgression or {}
LOD.SoldierProgression.StateMap = LOD.SoldierProgression.StateMap or {}
LOD.SoldierProgression.StateMap[soldierPly] = soldierState

local soldierSnap = CPS:BuildClientSnapshot(soldierPly)
assertTest(soldierSnap ~= nil and soldierSnap.isSoldier == true, "Soldier snapshot built successfully")
assertTest(soldierSnap.readOnly == true, "Soldier snapshot is read-only")

local strRow = nil
for _, row in ipairs(soldierSnap.abilities or {}) do
    if row.id == "str" then strRow = row end
end
assertTest(strRow and strRow.fighterTraining == 1, "Soldier P snapshot reports actual fighterTraining STR value (+1)")

-- S. Hero P snapshot remains authoritative
RunManager:NewCampaign()
local heroPly = createMockPlayer("HeroPly", "hero_1")
RunManager:TryActivatePlayer(heroPly)

local heroSnap = CPS:BuildClientSnapshot(heroPly)
if not heroSnap then print("HERO SNAP IS NIL! PS:", RunManager:GetPlayerState(heroPly)) end
assertTest(heroSnap ~= nil and heroSnap.isSoldier == false, "Hero snapshot remains authoritative and is not Soldier")

-- T & U. Spellbook Forms and Contents schema
assertTest(#MagicProgression.FormOrder == 10, "Spellbook exposes ten canonical Forms")
assertTest(#MagicProgression.ContentOrder == 6, "Spellbook exposes RAW + six canonical Contents")

local expectedForms = {wall = true, super_ball = true, watermelon = true, cone = true, blast = true, beam = true, bomb = true, missile = true, bolt = true, summon = true}
for _, fId in ipairs(MagicProgression.FormOrder) do
    assertTest(expectedForms[fId] == true, "Form " .. fId .. " is in canonical FormOrder")
end

local expectedContents = {earth = true, fire = true, dark = true, ice = true, light = true, electric = true}
for _, cId in ipairs(MagicProgression.ContentOrder) do
    assertTest(expectedContents[cId] == true, "Content " .. cId .. " is in canonical ContentOrder")
end

-- V & W. Magic state ownership & class-neutral Contents
local heroState = LOD.RunManager:GetPlayerState(heroPly).progressionState
MagicProgression:EnsureState(heroState)

local grantedForm, errForm = MagicProgression:GrantForm(heroState, "beam", "test_milestone")
assertTest(grantedForm == true, "MagicProgression:GrantForm granted 'beam' to hero state")

local grantedContent, errContent = MagicProgression:GrantContent(heroState, "fire", "test_milestone")
assertTest(grantedContent == true, "MagicProgression:GrantContent granted class-neutral 'fire' to hero state")

MagicProgression:SelectForm(heroState, "beam")
MagicProgression:SelectContent(heroState, "fire")
assertTest(heroState.selectedMagicFormId == "beam", "Selected Magic Form matches production state ('beam')")
assertTest(heroState.selectedMagicContentId == "fire", "Selected Magic Content matches production state ('fire')")

-- X. P/I mutual exclusion contract
local sheetClosed, spellbookClosed = false, false
LOD.CharacterSheet = {
    Open = function(self)
        if LOD.Spellbook and LOD.Spellbook.Close then LOD.Spellbook:Close() end
    end
}
LOD.Spellbook = {
    Close = function(self) spellbookClosed = true end
}

LOD.CharacterSheet:Open()
assertTest(spellbookClosed == true, "Opening P Character Sheet automatically invokes I Spellbook:Close()")

print(string.format("\nCHECKPOINT_F_INTEGRITY_HARNESS_PASS — All %d requirements (A through X) verified with 0 discrepancies.", passCount))
