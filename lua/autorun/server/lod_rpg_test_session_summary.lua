if CLIENT then return end

LOD = LOD or {}
LOD.RPGTestSessionSummary = LOD.RPGTestSessionSummary or {}

local Summary = LOD.RPGTestSessionSummary
local DATA_DIR = "legend_of_deborah"
local SESSION_PATH = DATA_DIR .. "/rpg_test_session.txt"
local SUMMARY_PATH = DATA_DIR .. "/rpg_test_summary.txt"
local SUMMARY_SCHEMA = "rpg-test-summary-v1"

Summary.SessionPath = SESSION_PATH
Summary.SummaryPath = SUMMARY_PATH

local function safe(value)
    if value == nil then return "" end
    if isbool(value) then return value and "true" or "false" end
    local text = tostring(value)
    text = string.gsub(text, "[\r\n\t]", " ")
    return text
end

local function copyFields(fields)
    local out = {}
    for key, value in pairs(fields or {}) do
        out[tostring(key)] = value
    end
    return out
end

local function encodedFields(fields)
    local keys = {}
    for key in pairs(fields or {}) do keys[#keys + 1] = tostring(key) end
    table.sort(keys)
    local out = {}
    for _, key in ipairs(keys) do
        out[#out + 1] = key .. "=" .. safe(fields[key])
    end
    return table.concat(out, "\t")
end

local function csvCount(value)
    if value == nil then return 0 end
    if type(value) == "table" then return #value end
    local text = tostring(value)
    if text == "" then return 0 end
    local _, commas = string.gsub(text, ",", "")
    return commas + 1
end

local function parseDiceFormula(formula)
    local count, sides = string.match(tostring(formula or ""), "(%d+)d(%d+)")
    return tonumber(count), tonumber(sides)
end

local function sessionHeader(reason)
    return table.concat({
        "# The Legend of Deborah RPG current-session runtime log",
        "# schema=rpg-test-session-v1",
        "# generated_utc=" .. os.date("!%Y-%m-%dT%H:%M:%SZ"),
        "# map=" .. safe(game.GetMap()),
        "# gamemode=" .. safe(engine.ActiveGamemode()),
        "# reason=" .. safe(reason or "manual"),
        "# this file contains only the current server session",
        "# fields are tab-separated key=value pairs; one event per line",
        ""
    }, "\n")
end

function Summary:BeginSession(reason)
    file.CreateDir(DATA_DIR)
    self.SessionReason = reason or "manual"
    self.EventCount = 0
    self.LastSequence = 0
    self.EventCounts = {}
    self.Marks = {}
    self.Profiles = {}
    self.Dice = {}
    self.LastValidation = nil
    file.Write(SESSION_PATH, sessionHeader(self.SessionReason))
end

function Summary:Record(sequence, eventTime, eventName, fields)
    if not self.EventCounts then
        self:BeginSession("summary attached to active logger session")
    end

    eventName = safe(eventName)
    fields = fields or {}
    self.EventCount = (self.EventCount or 0) + 1
    self.LastSequence = tonumber(sequence) or self.LastSequence or 0
    self.EventCounts[eventName] = (self.EventCounts[eventName] or 0) + 1

    local line = string.format("%06d\t%.3f\t%s", tonumber(sequence) or 0, tonumber(eventTime) or CurTime(), eventName)
    local encoded = encodedFields(fields)
    if encoded ~= "" then line = line .. "\t" .. encoded end
    file.Append(SESSION_PATH, line .. "\n")

    if eventName == "MARK" then
        self.Marks[#self.Marks + 1] = {
            sequence = tonumber(sequence) or 0,
            time = tonumber(eventTime) or 0,
            player = safe(fields.player),
            text = safe(fields.text)
        }
    elseif eventName == "PROFILE" then
        local playerKey = safe(fields.player)
        if playerKey == "" then playerKey = "unknown" end
        self.Profiles[playerKey] = copyFields(fields)
    elseif eventName == "GATE_D_VALIDATE" then
        self.LastValidation = copyFields(fields)
    elseif eventName == "PLAYER_ROLL" then
        local formulaCount, sides = parseDiceFormula(fields.formula)
        if sides then
            local dieKey = tostring(sides)
            local stats = self.Dice[dieKey]
            if not stats then
                stats = {
                    sides = sides,
                    roll_events = 0,
                    base_dice = 0,
                    exploding_rolls = 0,
                    continuation_dice = 0,
                    max_continuations = 0,
                    thresholds = {}
                }
                self.Dice[dieKey] = stats
            end

            local baseDice = tonumber(fields.base_dice) or formulaCount or 1
            local values = csvCount(fields.values)
            local continuations = math.max(0, values - baseDice)
            stats.roll_events = stats.roll_events + 1
            stats.base_dice = stats.base_dice + baseDice
            stats.continuation_dice = stats.continuation_dice + continuations
            if continuations > 0 then stats.exploding_rolls = stats.exploding_rolls + 1 end
            stats.max_continuations = math.max(stats.max_continuations, continuations)

            local thresholdText = safe(fields.thresholds)
            if thresholdText ~= "" then stats.thresholds[thresholdText] = true end
        end
    end
end

local PROFILE_KEYS = {
    "class", "level", "hp", "max_hp", "magic",
    "strx", "aimx", "movex", "dr_per_die", "regenx", "magicx", "mapx",
    "crumbs", "stun_inflict_x", "stun_resist_x", "diversion",
    "rogue_explodes", "boom_shift", "rogue_boom_shift", "rogue_capstone_shift",
    "ace_prime_seconds", "fighter_capstone_x", "wizard_capstone_magic_x"
}

local function profileLine(playerKey, fields)
    local out = {"player=" .. safe(playerKey)}
    for _, key in ipairs(PROFILE_KEYS) do
        if fields[key] ~= nil then out[#out + 1] = key .. "=" .. safe(fields[key]) end
    end
    return table.concat(out, "\t")
end

local function thresholdList(stats)
    local values = {}
    for threshold in pairs(stats.thresholds or {}) do values[#values + 1] = threshold end
    table.sort(values)
    return table.concat(values, " | ")
end

function Summary:Render()
    local lines = {
        "# The Legend of Deborah RPG current-session summary",
        "# schema=" .. SUMMARY_SCHEMA,
        "# generated_utc=" .. os.date("!%Y-%m-%dT%H:%M:%SZ"),
        "# map=" .. safe(game.GetMap()),
        "# gamemode=" .. safe(engine.ActiveGamemode()),
        "# session_reason=" .. safe(self.SessionReason or "unknown"),
        "# event_count=" .. safe(self.EventCount or 0),
        "# last_sequence=" .. safe(self.LastSequence or 0),
        "",
        "[MARKS]"
    }

    if #(self.Marks or {}) == 0 then
        lines[#lines + 1] = "none"
    else
        for _, mark in ipairs(self.Marks) do
            lines[#lines + 1] = string.format("sequence=%06d\ttime=%.3f\tplayer=%s\ttext=%s", mark.sequence, mark.time, mark.player, mark.text)
        end
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = "[EVENT_COUNTS]"
    local eventNames = {}
    for eventName in pairs(self.EventCounts or {}) do eventNames[#eventNames + 1] = eventName end
    table.sort(eventNames)
    if #eventNames == 0 then
        lines[#lines + 1] = "none"
    else
        for _, eventName in ipairs(eventNames) do
            lines[#lines + 1] = eventName .. "=" .. safe(self.EventCounts[eventName])
        end
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = "[LATEST_PROFILES]"
    local players = {}
    for playerKey in pairs(self.Profiles or {}) do players[#players + 1] = playerKey end
    table.sort(players)
    if #players == 0 then
        lines[#lines + 1] = "none"
    else
        for _, playerKey in ipairs(players) do
            lines[#lines + 1] = profileLine(playerKey, self.Profiles[playerKey])
        end
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = "[PLAYER_DICE]"
    local diceSides = {}
    for dieKey, stats in pairs(self.Dice or {}) do diceSides[#diceSides + 1] = tonumber(stats.sides) or tonumber(dieKey) or 0 end
    table.sort(diceSides)
    if #diceSides == 0 then
        lines[#lines + 1] = "none"
    else
        for _, sides in ipairs(diceSides) do
            local stats = self.Dice[tostring(sides)]
            lines[#lines + 1] = table.concat({
                "d" .. safe(sides),
                "roll_events=" .. safe(stats.roll_events),
                "base_dice=" .. safe(stats.base_dice),
                "exploding_rolls=" .. safe(stats.exploding_rolls),
                "continuation_dice=" .. safe(stats.continuation_dice),
                "max_continuations=" .. safe(stats.max_continuations),
                "thresholds=" .. safe(thresholdList(stats))
            }, "\t")
        end
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = "[LATEST_GATE_D_VALIDATE]"
    if self.LastValidation then
        lines[#lines + 1] = encodedFields(self.LastValidation)
    else
        lines[#lines + 1] = "none"
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = "# current-session event stream: garrysmod/data/" .. SESSION_PATH
    lines[#lines + 1] = "# cumulative archive: garrysmod/data/legend_of_deborah/rpg_test_log.txt"
    lines[#lines + 1] = ""
    return table.concat(lines, "\n")
end

function Summary:WriteSummary()
    file.CreateDir(DATA_DIR)
    file.Write(SUMMARY_PATH, self:Render())
    return SUMMARY_PATH
end

local function attach()
    local Log = LOD and LOD.RPGTestLog
    if not Log or Summary.Attached then return false end
    if not isfunction(Log.BeginSession) or not isfunction(Log.Write) then return false end

    Summary.Attached = true
    Summary.OriginalBeginSession = Log.BeginSession
    Summary.OriginalWrite = Log.Write

    function Log:BeginSession(reason)
        local ok = Summary.OriginalBeginSession(self, reason)
        if ok then Summary:BeginSession(reason) end
        return ok
    end

    function Log:Write(eventName, fields)
        local before = tonumber(self.Sequence) or 0
        Summary.OriginalWrite(self, eventName, fields)
        local after = tonumber(self.Sequence) or before
        if after > before then
            Summary:Record(after, CurTime(), eventName, fields)
        end
    end

    if Log.Started then
        Summary:BeginSession("summary attached to active logger session")
    end

    return true
end

concommand.Add("lod_rpg_test_summary", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    if not attach() then
        print("[LOD:RPG-TEST] summary unavailable: runtime logger is not ready")
        return
    end

    local Log = LOD and LOD.RPGTestLog
    if Log and isfunction(Log.WriteProfile) then
        for _, playerObject in ipairs(player.GetAll()) do
            if IsValid(playerObject) then Log:WriteProfile(playerObject, "summary requested") end
        end
    end

    local path = Summary:WriteSummary()
    print("[LOD:RPG-TEST] current-session summary written to garrysmod/data/" .. path)
    print("[LOD:RPG-TEST] current-session event stream: garrysmod/data/" .. SESSION_PATH)
end)

attach()
hook.Add("Initialize", "LOD.RPGTestSessionSummary.Attach", attach)
hook.Add("InitPostEntity", "LOD.RPGTestSessionSummary.AttachPost", function()
    timer.Simple(0, attach)
end)
timer.Simple(0, attach)
