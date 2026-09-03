if CLIENT then return end

LOD = LOD or {}
LOD.RPGTestObservability = LOD.RPGTestObservability or {}

local Obs = LOD.RPGTestObservability
local DATA_DIR = "legend_of_deborah"
local ARCHIVE_PATH = DATA_DIR .. "/rpg_test_log.txt"
local SESSION_PATH = DATA_DIR .. "/rpg_test_session.txt"
local SUMMARY_PATH = DATA_DIR .. "/rpg_test_summary.txt"

local ARCHIVE_MAX = 4 * 1024 * 1024
local ARCHIVE_KEEP = 2 * 1024 * 1024
local SESSION_MAX = 8 * 1024 * 1024
local SESSION_KEEP = 4 * 1024 * 1024
local SIZE_CHECK_INTERVAL = 256
local SUMMARY_INTERVAL = 10

Obs.Paths = {
    archive = ARCHIVE_PATH,
    session = SESSION_PATH,
    summary = SUMMARY_PATH
}
Obs.Retention = {
    archiveMaxBytes = ARCHIVE_MAX,
    archiveKeepBytes = ARCHIVE_KEEP,
    sessionMaxBytes = SESSION_MAX,
    sessionKeepBytes = SESSION_KEEP,
    summaryIntervalSeconds = SUMMARY_INTERVAL
}

local function safe(value)
    if value == nil then return "" end
    local text = tostring(value)
    text = string.gsub(text, "[\r\n\t]", " ")
    return text
end

local function sizeOf(path)
    local size = file.Size(path, "DATA")
    return math.max(0, tonumber(size) or 0)
end

local function trimTail(path, maxBytes, keepBytes, label)
    local size = sizeOf(path)
    if size <= maxBytes then return false, size end

    local body = file.Read(path, "DATA") or ""
    if #body <= maxBytes then return false, #body end

    local tail = string.sub(body, -keepBytes)
    local newline = string.find(tail, "\n", 1, true)
    if newline then tail = string.sub(tail, newline + 1) end
    local header = table.concat({
        "# The Legend of Deborah rolling log was compacted automatically.",
        "# log=" .. safe(label),
        "# compacted_utc=" .. os.date("!%Y-%m-%dT%H:%M:%SZ"),
        "# policy=max:" .. safe(maxBytes) .. " keep_recent:" .. safe(keepBytes),
        "# older records were discarded; current summary aggregates remain authoritative for the active session.",
        "# --- RECENT TAIL FOLLOWS ---",
        ""
    }, "\n")
    file.Write(path, header .. tail)
    return true, sizeOf(path)
end

function Obs:Compact(force)
    local archiveTrimmed, archiveSize = trimTail(ARCHIVE_PATH, ARCHIVE_MAX, ARCHIVE_KEEP, "rpg_test_log.txt")
    local sessionTrimmed, sessionSize = trimTail(SESSION_PATH, SESSION_MAX, SESSION_KEEP, "rpg_test_session.txt")
    if force or archiveTrimmed or sessionTrimmed then
        print(string.format(
            "[LOD:RPG-LOG] retention archive=%dB%s session=%dB%s summary=%dB",
            archiveSize, archiveTrimmed and " compacted" or "",
            sessionSize, sessionTrimmed and " compacted" or "",
            sizeOf(SUMMARY_PATH)))
    end
end

local function actorLabel(ply)
    if not IsValid(ply) then return "server" end
    if ply:IsPlayer() then return string.format("player:%s#%d", safe(ply:Nick()), ply:EntIndex()) end
    return safe(ply:GetClass())
end

local function commandAllowed(ply)
    return not IsValid(ply) or ply:IsAdmin()
end

local function syncReloadStats()
    local Effects = LOD.RPG and LOD.RPG.FeatEffectSystem
    local stats = Effects and Effects.ReloadStats
    if not stats then return end
    local count = tonumber(stats.reloadExtensionsScaled) or 0
    if count <= (Obs.LastReloadScaleCount or 0) then return end
    Obs.LastReloadScaleCount = count
    Obs.ReloadScaleEvents = math.max(tonumber(Obs.ReloadScaleEvents) or 0, count)
    local last = stats.lastScale or {}
    Obs.LastReloadScale = {
        count = count,
        weaponClass = last.weaponClass,
        channel = last.channel,
        multiplier = last.multiplier,
        authoredSeconds = last.authoredSeconds,
        scaledSeconds = last.scaledSeconds,
        savedSeconds = math.max(0, (tonumber(last.authoredSeconds) or 0) - (tonumber(last.scaledSeconds) or 0))
    }
end

local function wrapLogger()
    local Log = LOD.RPGTestLog
    local Summary = LOD.RPGTestSessionSummary
    if not Log or not Summary then return false end
    if not isfunction(Log.Write) or not isfunction(Log.BeginSession) then return false end

    if not Obs.LoggerWrapped then
        Obs.LoggerWrapped = true
        local baseWrite = Log.Write
        local baseBegin = Log.BeginSession

        function Log:BeginSession(reason)
            Obs:Compact(false)
            local ok = baseBegin(self, reason)
            if ok then Obs:Compact(false) end
            return ok
        end

        function Log:Write(eventName, fields)
            local before = tonumber(self.Sequence) or 0
            baseWrite(self, eventName, fields)
            local after = tonumber(self.Sequence) or before
            if after > before and after % SIZE_CHECK_INTERVAL == 0 then
                Obs:Compact(false)
            end
        end
    end

    if isfunction(Summary.Record) and not Obs.SummaryRecordWrapped then
        Obs.SummaryRecordWrapped = true
        local baseRecord = Summary.Record
        function Summary:Record(sequence, eventTime, eventName, fields)
            fields = fields or {}
            if eventName == "MARK" and (fields.text == nil or tostring(fields.text) == "") and fields.label ~= nil then
                fields.text = fields.label
            end
            if eventName == "RPG_VALIDATE" then
                Obs.LastValidation = {
                    sequence = sequence,
                    time = eventTime,
                    result = fields.result,
                    errors = fields.errors
                }
            elseif eventName == "RELOAD_SCALE" then
                local count = tonumber(fields.count) or 0
                Obs.ReloadScaleEvents = math.max(tonumber(Obs.ReloadScaleEvents) or 0, count)
                Obs.LastReloadScaleCount = math.max(tonumber(Obs.LastReloadScaleCount) or 0, count)
                Obs.LastReloadScale = fields
            elseif eventName == "MARK" then
                Obs.LastMark = fields.text or fields.label
            end
            return baseRecord(self, sequence, eventTime, eventName, fields)
        end
    end

    if isfunction(Summary.Render) and not Obs.SummaryRenderWrapped then
        Obs.SummaryRenderWrapped = true
        local baseRender = Summary.Render
        function Summary:Render()
            syncReloadStats()
            local text = baseRender(self)
            local lastValidation = Obs.LastValidation or {}
            local lastReload = Obs.LastReloadScale or {}
            local extra = table.concat({
                "[OBSERVABILITY]",
                "retention=console:per-GMod-launch;session:current-server-session;summary:overwrite-every-10s;archive:rolling-4MiB",
                "physical_upload_dir=garrysmod/data/legend_of_deborah/",
                "recommended_upload=console_latest.txt + rpg_summary_latest.txt",
                "detailed_upload_when_needed=rpg_session_latest.txt",
                "archive_upload_only_on_request=rpg_archive_latest.txt",
                "last_mark=" .. safe(Obs.LastMark),
                "last_rpg_validate=" .. safe(lastValidation.result),
                "last_rpg_validate_errors=" .. safe(lastValidation.errors),
                "reload_scale_events=" .. safe(Obs.ReloadScaleEvents or 0),
                "last_reload_weapon=" .. safe(lastReload.weaponClass),
                "last_reload_channel=" .. safe(lastReload.channel),
                "last_reload_multiplier=" .. safe(lastReload.multiplier),
                "last_reload_authored_seconds=" .. safe(lastReload.authoredSeconds),
                "last_reload_scaled_seconds=" .. safe(lastReload.scaledSeconds),
                "last_reload_saved_seconds=" .. safe(lastReload.savedSeconds),
                "",
            }, "\n")
            return text .. "\n" .. extra
        end
    end

    Obs:Compact(false)
    return true
end

local function writeProfiles(Log, reason)
    if not Log or not isfunction(Log.WriteProfile) then return end
    for _, ply in ipairs(player.GetHumans()) do
        if IsValid(ply) then Log:WriteProfile(ply, reason) end
    end
end

local function runValidation(Log)
    local Validation = LOD.RPGValidation
    if not Validation or not isfunction(Validation.Run) then return nil end
    local ok, errors = Validation:Run(false)
    local errorText = ""
    if errors and #errors > 0 then errorText = table.concat(errors, " | ") end
    Log:Write("RPG_VALIDATE", {result = ok and "PASS" or "FAIL", errors = errorText})
    return ok
end

local function finishTest(ply, label)
    if not wrapLogger() then
        print("[LOD:RPG-TEST] observability unavailable: RPG logger/summary not ready")
        return
    end

    local Log = LOD.RPGTestLog
    local Summary = LOD.RPGTestSessionSummary
    label = safe(label)
    if label == "" then label = "unnamed-test" end

    syncReloadStats()
    Log:Write("MARK", {
        player = actorLabel(ply),
        text = "TEST_END " .. label,
        label = label
    })
    writeProfiles(Log, "test finish " .. label)
    local validationOK = runValidation(Log)
    Obs.LastMark = "TEST_END " .. label
    if Summary and isfunction(Summary.WriteSummary) then Summary:WriteSummary() end
    Obs:Compact(true)

    local Export = LOD.RPGTestUploadExport
    if Export and isfunction(Export.Publish) then
        timer.Simple(0.05, function()
            Export:Publish("test finish " .. label, false)
        end)
    end

    local result = validationOK == nil and "not-run" or (validationOK and "PASS" or "FAIL")
    print(string.format("[LOD:RPG-TEST] finished %s; core validation=%s", label, result))
    print("[LOD:RPG-TEST] upload from garrysmod/data/legend_of_deborah/: console_latest.txt + rpg_summary_latest.txt")
    print("[LOD:RPG-TEST] add rpg_session_latest.txt for timing/event-order bugs; archive only when requested")
end

local function installCommands()
    if Obs.CommandsInstalled then return end
    Obs.CommandsInstalled = true

    concommand.Add("lod_rpg_test_mark", function(ply, _, _, argStr)
        if not commandAllowed(ply) or not wrapLogger() then return end
        local text = safe(argStr)
        if text == "" then text = "manual mark" end
        LOD.RPGTestLog:Write("MARK", {player = actorLabel(ply), text = text, label = text})
        print("[LOD:RPG-TEST] mark: " .. text)
    end)

    concommand.Add("lod_rpg_test_finish", function(ply, _, _, argStr)
        if not commandAllowed(ply) then return end
        finishTest(ply, argStr)
    end)

    concommand.Add("lod_rpg_test_logs_status", function(ply)
        if not commandAllowed(ply) then return end
        wrapLogger()
        syncReloadStats()
        Obs:Compact(true)
        local lines = {
            string.format("archive data/%s %dB (rolling max 4MiB, keeps recent 2MiB)", ARCHIVE_PATH, sizeOf(ARCHIVE_PATH)),
            string.format("session data/%s %dB (current session; max 8MiB, keeps recent 4MiB)", SESSION_PATH, sizeOf(SESSION_PATH)),
            string.format("summary data/%s %dB (overwritten every %ds and at test finish)", SUMMARY_PATH, sizeOf(SUMMARY_PATH), SUMMARY_INTERVAL),
            "physical upload directory: garrysmod/data/legend_of_deborah/",
            "console_latest.txt is externally mirrored from engine console.log; -condebug -conclearlog resets source each GMod launch",
            "default upload: console_latest.txt + rpg_summary_latest.txt"
        }
        for _, line in ipairs(lines) do
            print("[LOD:RPG-LOG] " .. line)
            if IsValid(ply) then ply:ChatPrint(line) end
        end
    end)
end

local function bootstrap()
    wrapLogger()
    installCommands()
    timer.Create("LOD_RPGTestObservability_AutoSummary", SUMMARY_INTERVAL, 0, function()
        if not wrapLogger() then return end
        syncReloadStats()
        local Summary = LOD.RPGTestSessionSummary
        if Summary and isfunction(Summary.WriteSummary) and (tonumber(Summary.EventCount) or 0) > 0 then
            Summary:WriteSummary()
        end
    end)
    timer.Create("LOD_RPGTestObservability_ReloadWatch", 0.25, 0, syncReloadStats)
end

timer.Simple(0, bootstrap)
hook.Add("InitPostEntity", "LOD_RPGTestObservability_Bootstrap", function()
    timer.Simple(0, bootstrap)
end)
hook.Add("ShutDown", "LOD_RPGTestObservability_Finalize", function()
    syncReloadStats()
    local Summary = LOD.RPGTestSessionSummary
    if Summary and isfunction(Summary.WriteSummary) then Summary:WriteSummary() end
    Obs:Compact(false)
end)
