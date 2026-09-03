if CLIENT then return end

LOD = LOD or {}
LOD.RPGTestUploadExport = LOD.RPGTestUploadExport or {}

local Export = LOD.RPGTestUploadExport
local DATA_DIR = "legend_of_deborah"

local SOURCE_ARCHIVE = DATA_DIR .. "/rpg_test_log.txt"
local SOURCE_SESSION = DATA_DIR .. "/rpg_test_session.txt"
local SOURCE_SUMMARY = DATA_DIR .. "/rpg_test_summary.txt"

local DEST_CONSOLE = DATA_DIR .. "/console_latest.txt"
local DEST_ARCHIVE = DATA_DIR .. "/rpg_archive_latest.txt"
local DEST_SESSION = DATA_DIR .. "/rpg_session_latest.txt"
local DEST_SUMMARY = DATA_DIR .. "/rpg_summary_latest.txt"

local CONSOLE_MAX = 8 * 1024 * 1024
local CONSOLE_HEAD = 256 * 1024
local CONSOLE_TAIL = 6 * 1024 * 1024

Export.Paths = {
    console = DEST_CONSOLE,
    archive = DEST_ARCHIVE,
    session = DEST_SESSION,
    summary = DEST_SUMMARY
}

local function safe(value)
    if value == nil then return "" end
    local text = tostring(value)
    text = string.gsub(text, "[\r\n\t]", " ")
    return text
end

local function commandAllowed(ply)
    return not IsValid(ply) or ply:IsAdmin()
end

local function sizeOf(path)
    local size = file.Size(path, "DATA")
    return math.max(0, tonumber(size) or 0)
end

local function copyData(sourcePath, destinationPath)
    local body = file.Read(sourcePath, "DATA")
    if body == nil then return false, 0 end
    file.Write(destinationPath, body)
    return true, #body
end

local function readEngineConsole()
    local candidates = {"console.log", "console.txt"}
    for _, candidate in ipairs(candidates) do
        local body = file.Read(candidate, "MOD")
        if body ~= nil and body ~= "" then
            return body, candidate
        end
    end
    return nil, nil
end

local function boundedConsole(body)
    if #body <= CONSOLE_MAX then return body, false end

    local head = string.sub(body, 1, CONSOLE_HEAD)
    local tail = string.sub(body, -CONSOLE_TAIL)
    local separator = table.concat({
        "",
        "# --- THE LEGEND OF DEBORAH CONSOLE EXPORT COMPACTED ---",
        "# Original engine console exceeded 8 MiB.",
        "# Preserved: first 256 KiB (startup/load evidence) + newest 6 MiB (recent runtime evidence).",
        "# Middle console output was discarded from this upload copy only.",
        "# The engine's original console file remains untouched.",
        "",
    }, "\n")
    return head .. separator .. tail, true
end

local function writeConsoleExport(reason)
    local body, sourceName = readEngineConsole()
    if not body then
        local placeholder = table.concat({
            "# The Legend of Deborah console upload export",
            "# generated_utc=" .. os.date("!%Y-%m-%dT%H:%M:%SZ"),
            "# reason=" .. safe(reason),
            "# status=ENGINE_CONSOLE_NOT_READABLE",
            "# expected Source launch options: -condebug -conclearlog",
            "# tried MOD/console.log and MOD/console.txt",
            "",
        }, "\n")
        file.Write(DEST_CONSOLE, placeholder)
        return false, #placeholder, "unavailable", false
    end

    local bounded, compacted = boundedConsole(body)
    local header = table.concat({
        "# The Legend of Deborah console upload export",
        "# generated_utc=" .. os.date("!%Y-%m-%dT%H:%M:%SZ"),
        "# reason=" .. safe(reason),
        "# engine_source=garrysmod/" .. safe(sourceName),
        "# source_bytes=" .. safe(#body),
        "# compacted=" .. (compacted and "true" or "false"),
        "# --- ENGINE CONSOLE FOLLOWS ---",
        "",
    }, "\n")
    local output = header .. bounded
    file.Write(DEST_CONSOLE, output)
    return true, #output, sourceName, compacted
end

function Export:Publish(reason, quiet)
    file.CreateDir(DATA_DIR)
    reason = safe(reason)
    if reason == "" then reason = "automatic export" end

    local consoleOK, consoleBytes, consoleSource, consoleCompacted = writeConsoleExport(reason)
    local summaryOK, summaryBytes = copyData(SOURCE_SUMMARY, DEST_SUMMARY)
    local sessionOK, sessionBytes = copyData(SOURCE_SESSION, DEST_SESSION)
    local archiveOK, archiveBytes = copyData(SOURCE_ARCHIVE, DEST_ARCHIVE)

    self.LastPublish = {
        reason = reason,
        utc = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        consoleOK = consoleOK,
        consoleBytes = consoleBytes,
        consoleSource = consoleSource,
        consoleCompacted = consoleCompacted,
        summaryOK = summaryOK,
        summaryBytes = summaryBytes,
        sessionOK = sessionOK,
        sessionBytes = sessionBytes,
        archiveOK = archiveOK,
        archiveBytes = archiveBytes
    }

    if not quiet then
        print(string.format(
            "[LOD:RPG-UPLOAD] exported data/%s (%dB), %s (%dB), %s (%dB), %s (%dB)",
            DEST_CONSOLE, consoleBytes,
            DEST_SUMMARY, summaryBytes,
            DEST_SESSION, sessionBytes,
            DEST_ARCHIVE, archiveBytes))
        if not consoleOK then
            print("[LOD:RPG-UPLOAD] WARNING: engine console was unavailable; verify -condebug -conclearlog and upload the placeholder for diagnosis")
        end
        if not summaryOK then print("[LOD:RPG-UPLOAD] WARNING: current RPG summary source was unavailable") end
        if not sessionOK then print("[LOD:RPG-UPLOAD] WARNING: current RPG session source was unavailable") end
        if not archiveOK then print("[LOD:RPG-UPLOAD] WARNING: rolling RPG archive source was unavailable") end
    end

    return consoleOK and summaryOK
end

local function installSummaryBridge()
    if Export.SummaryBridgeInstalled then return true end

    local Summary = LOD.RPGTestSessionSummary
    if not Summary or not isfunction(Summary.WriteSummary) then return false end

    Export.SummaryBridgeInstalled = true
    local baseWriteSummary = Summary.WriteSummary

    function Summary:WriteSummary(...)
        local path = baseWriteSummary(self, ...)
        timer.Simple(0, function()
            if LOD and LOD.RPGTestUploadExport then
                LOD.RPGTestUploadExport:Publish("summary refresh", true)
            end
        end)
        return path
    end

    return true
end

local function installCommands()
    if Export.CommandsInstalled then return end
    Export.CommandsInstalled = true

    concommand.Add("lod_rpg_test_export_now", function(ply, _, _, argStr)
        if not commandAllowed(ply) then return end
        installSummaryBridge()

        local Summary = LOD.RPGTestSessionSummary
        if Summary and isfunction(Summary.WriteSummary) then
            Summary:WriteSummary()
        end

        local label = safe(argStr)
        if label == "" then label = "manual export" end
        timer.Simple(0.05, function()
            Export:Publish(label, false)
        end)
    end)

    concommand.Add("lod_rpg_test_upload_status", function(ply)
        if not commandAllowed(ply) then return end

        local last = Export.LastPublish or {}
        local lines = {
            "physical upload directory: garrysmod/data/" .. DATA_DIR .. "/",
            string.format("%s %dB", DEST_CONSOLE, sizeOf(DEST_CONSOLE)),
            string.format("%s %dB", DEST_SUMMARY, sizeOf(DEST_SUMMARY)),
            string.format("%s %dB", DEST_SESSION, sizeOf(DEST_SESSION)),
            string.format("%s %dB", DEST_ARCHIVE, sizeOf(DEST_ARCHIVE)),
            "default upload: console_latest.txt + rpg_summary_latest.txt",
            "add rpg_session_latest.txt for timing/event-order bugs; archive only when requested",
            "last_publish_utc=" .. safe(last.utc) .. " reason=" .. safe(last.reason)
        }

        for _, line in ipairs(lines) do
            print("[LOD:RPG-UPLOAD] " .. line)
            if IsValid(ply) then ply:ChatPrint(line) end
        end
    end)
end

local function bootstrap()
    file.CreateDir(DATA_DIR)
    installSummaryBridge()
    installCommands()

    timer.Create("LOD_RPGTestUploadExport_BridgeRetry", 0.5, 0, function()
        if installSummaryBridge() then
            timer.Remove("LOD_RPGTestUploadExport_BridgeRetry")
        end
    end)

    timer.Simple(2, function()
        Export:Publish("startup snapshot", true)
    end)
end

timer.Simple(0, bootstrap)

hook.Add("InitPostEntity", "LOD_RPGTestUploadExport_Bootstrap", function()
    timer.Simple(0, bootstrap)
end)

hook.Add("ShutDown", "LOD_RPGTestUploadExport_Finalize", function()
    local Summary = LOD.RPGTestSessionSummary
    if Summary and isfunction(Summary.WriteSummary) then
        Summary:WriteSummary()
    end
    Export:Publish("shutdown snapshot", true)
end)
