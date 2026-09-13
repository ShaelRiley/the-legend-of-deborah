-- Checkpoint F Static / Deterministic Closure Validator (AG-009R1)
local root = "."

local mockFS = {}

SERVER = true
CLIENT = false
unpack = unpack or table.unpack

util = util or {}
net = net or {}
hook = hook or {}
file = file or {}

util.AddNetworkString = function() end
net.Start = function() end
net.WriteTable = function() end
net.Send = function() end
net.Broadcast = function() end
hook.Add = function() end

file.Exists = function(path, pathID)
    return mockFS[path] ~= nil
end
file.Read = function(path, pathID)
    return mockFS[path]
end
file.Write = function(path, content)
    mockFS[path] = content
end
file.CreateDir = function(dir) end

-- Simple mock JSON serializer / deserializer for tests
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

-- Lightweight JSON decoder sufficient for test objects
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

-- Load gamemode modules
dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sh_heroes_of_legend.lua")
dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sv_heroes_of_legend.lua")

print("--- CHECKPOINT F CLOSURE VALIDATOR (AG-009R1) ---")

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

local Heroes = LOD.HeroesOfLegend

-- Reset state
mockFS = {}
Heroes:Initialize()

-- Test 1: Rescue count formatting
assertTest(Heroes:FormatEntry({ partyMembers = {"Arthur", "Galahad"}, rescueCount = 1 }) == "Arthur, Galahad — Rescued Deborah 1 time",
    "Single rescue formats with singular 'time'")

assertTest(Heroes:FormatEntry({ partyMembers = {"Arthur", "Galahad"}, rescueCount = 3 }) == "Arthur, Galahad — Rescued Deborah 3 times",
    "Multiple rescues format with plural 'times'")

-- Test 2: Higher rescue count outranks lower rescue count
mockFS = {}
Heroes:Initialize()
Heroes:SubmitRun({ runId = "run_low", rescueCount = 3, partyMembers = {"Low Team"} })
Heroes:SubmitRun({ runId = "run_high", rescueCount = 8, partyMembers = {"High Team"} })

assertTest(#Heroes.Entries == 2, "2 entries registered")
assertTest(Heroes.Entries[1].runId == "run_high" and Heroes.Entries[2].runId == "run_low",
    "Higher rescue count (8) outranks lower rescue count (3)")

-- Test 3: Equal rescue count -> earlier completion outranks later completion
mockFS = {}
Heroes:Initialize()
local runA = Heroes:SubmitRun({ runId = "run_A", rescueCount = 5, partyMembers = {"Team A"} })
local runB = Heroes:SubmitRun({ runId = "run_B", rescueCount = 5, partyMembers = {"Team B"} })

assertTest(runA.completionOrder < runB.completionOrder, "Monotonic completionOrder assigned (runA < runB)")
assertTest(Heroes.Entries[1].runId == "run_A" and Heroes.Entries[2].runId == "run_B",
    "Equal rescue count (5) -> earlier completion (runA) outranks later completion (runB)")

-- Test 4: Cutoff behavior at #10/#11 boundary
mockFS = {}
Heroes:Initialize()
for i = 1, 10 do
    Heroes:SubmitRun({ runId = "run_" .. i, rescueCount = 7, partyMembers = {"Party " .. i} })
end

assertTest(#Heroes.Entries == 10, "Leaderboard capped at 10 initial entries")
assertTest(Heroes.Entries[10].runId == "run_10", "10th entry is run_10")

-- Submit 11th run with equal score (7 rescues)
local run11 = Heroes:SubmitRun({ runId = "run_11", rescueCount = 7, partyMembers = {"Party 11"} })
assertTest(#Heroes.Entries == 10, "Leaderboard remains strictly capped at 10 after 11th submission")
assertTest(Heroes.Entries[10].runId == "run_10",
    "Later equal-score run_11 DOES NOT displace earlier equal-score run_10 at top-10 cutoff")

-- Test 5: Higher score CAN displace entry at top-10 cutoff
local runHigh = Heroes:SubmitRun({ runId = "run_super", rescueCount = 12, partyMembers = {"Super Party"} })
assertTest(#Heroes.Entries == 10, "Leaderboard capped at 10 after higher score submission")
assertTest(Heroes.Entries[1].runId == "run_super", "Higher score (12 rescues) takes rank 1")
assertTest(Heroes.Entries[10].runId == "run_9", "Lowest remaining top-10 run (run_9) shifted to rank 10")

-- Test 6: Sorting determinism
local prevOrder = {}
for i, e in ipairs(Heroes.Entries) do prevOrder[i] = e.runId end

for iter = 1, 10 do
    Heroes:SortEntries(Heroes.Entries)
    for i, e in ipairs(Heroes.Entries) do
        assert(e.runId == prevOrder[i], "Sorting non-determinism detected on iter " .. iter)
    end
end
assertTest(true, "Repeated sorting produces 100% identical order")

-- Test 7: Persistence save / load stability
Heroes:Save()
local savedData = mockFS[Heroes.DATA_PATH]
assertTest(savedData ~= nil and savedData ~= "", "Data successfully serialized and saved to mock filesystem")

-- Wipe memory state and reload
Heroes.Entries = {}
Heroes.NextCompletionOrder = 1
Heroes:Load()

assertTest(#Heroes.Entries == 10, "10 entries loaded after reload")
for i, e in ipairs(Heroes.Entries) do
    assert(e.runId == prevOrder[i], "Order changed after reload at index " .. i)
end
assertTest(true, "Loaded entries preserve exact pre-save canonical order and completionOrder sequence")

-- Test 8: Monotonic completion sequence progression
local nextSeq = Heroes.NextCompletionOrder
assertTest(nextSeq > 11, "NextCompletionOrder monotonically advanced beyond highest assigned index (" .. nextSeq .. " > 11)")

-- Test 9: Idempotency (duplicate processing of same runId)
local countBefore = #Heroes.Entries
local seqBefore = Heroes.NextCompletionOrder
local existingRun = Heroes.Entries[1]
local resubmit = Heroes:SubmitRun({ runId = existingRun.runId, rescueCount = existingRun.rescueCount, partyMembers = existingRun.partyMembers })

assertTest(#Heroes.Entries == countBefore, "Duplicate runId submission does not increase leaderboard entry count")
assertTest(Heroes.NextCompletionOrder == seqBefore, "Duplicate runId submission does not consume a new completionOrder")
assertTest(resubmit.completionOrder == existingRun.completionOrder, "Duplicate runId submission preserves original completionOrder")

-- Test 10: Unrelated properties do NOT affect ranking
mockFS = {}
Heroes:Initialize()
Heroes:SubmitRun({ runId = "run_alpha", rescueCount = 6, partyMembers = {"Zzz Hero"}, steamId = "STEAM_0:0:999" })
Heroes:SubmitRun({ runId = "run_beta", rescueCount = 6, partyMembers = {"Aaa Hero"}, steamId = "STEAM_0:0:000" })

assertTest(Heroes.Entries[1].runId == "run_alpha",
    "Party member name ('Zzz Hero' vs 'Aaa Hero') and SteamID do NOT alter completion-order ranking")

print(string.format("\nCHECKPOINT_F_CLOSURE_HARNESS_PASS — All %d requirements verified with 0 discrepancies.", passCount))
