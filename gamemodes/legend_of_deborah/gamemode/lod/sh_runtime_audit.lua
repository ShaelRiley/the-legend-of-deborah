LOD = LOD or {}
LOD.RuntimeAudit = LOD.RuntimeAudit or {}
local Audit = LOD.RuntimeAudit
Audit.Build = "stability-20260916-07"
LOD.RuntimeReceipts = LOD.RuntimeReceipts or {}

local expected = SERVER and {"hostile", "pickup", "loot", "staging", "equipment", "crowbar", "statue", "manual"}
    or {"meshes", "mirror", "manual_reader"}

local function validCount(objects)
    local count = 0
    for _, object in pairs(objects or {}) do if IsValid(object) then count = count + 1 end end
    return count
end

function Audit:Snapshot()
    local missing = {}
    for _, name in ipairs(expected) do
        if LOD.RuntimeReceipts[name] ~= self.Build then missing[#missing + 1] = name end
    end
    local installation = file.Read("legend_of_deborah/dev_build.txt", "DATA") or "unrecorded"
    installation = string.sub(string.gsub(installation, "[\r\n]", " "), 1, 160)
    return {
        build = self.Build, realm = SERVER and "server" or "client",
        install = installation, missing = #missing > 0 and table.concat(missing, ",") or "none",
        architecture = jit and jit.arch or "unknown", branch = tostring(BRANCH or "unknown"),
        engine = tostring(VERSIONSTR or VERSION or "unknown"),
        lua_errors = self.ErrorCount or 0,
        wall_models = validCount(LOD.WallVisualsClient and LOD.WallVisualsClient.models),
        loot_entities = validCount(LOD.LootDirector and LOD.LootDirector.Entities),
        jit_version = jit and jit.version or "unknown",
        lua_kb = math.floor(collectgarbage("count")),
        entities = ents.GetCount and ents.GetCount() or #ents.GetAll(),
        meshes = LOD.TexturedBox and LOD.TexturedBox.MeshCacheCount and LOD.TexturedBox:MeshCacheCount() or 0
    }
end

function Audit:Report()
    local data = self:Snapshot()
    local parts = {}
    for _, key in ipairs({"build", "realm", "install", "missing", "architecture", "branch", "engine", "lua_errors", "lua_kb", "entities", "meshes", "wall_models", "loot_entities", "jit_version"}) do
        parts[#parts + 1] = key .. "=" .. tostring(data[key])
    end
    print("[LOD BUILD_IDENTITY] " .. table.concat(parts, " "))
    self:Record("BUILD_IDENTITY", table.concat(parts, " "))
    if SERVER and LOD.RPGTestLog and LOD.RPGTestLog.Write then
        LOD.RPGTestLog:Write("BUILD_IDENTITY", data)
    end
end

hook.Add("InitPostEntity", "LOD_RuntimeBuildIdentity", function()
    timer.Simple(1, function() Audit:Report() end)
end)
concommand.Add(SERVER and "lod_stability_status" or "lod_stability_client_status", function(ply)
    if SERVER and IsValid(ply) and not ply:IsAdmin() then return end
    Audit:Report()
end)
-- Developer-only resource trend, bounded to one record per 30 seconds. Lua KB
-- is not process/native memory; record the engine architecture separately.
timer.Create("LOD_RuntimeStabilityHeartbeat", 30, 0, function()
    local cv = GetConVar("lod_developer_mode")
    if cv and cv:GetBool() then Audit:Report() end
end)

-- Keep the first errors and the last native boundary across a force-close.
-- A fixed ring bounds disk/memory, even if a broken Think hook repeats forever.
Audit.Journal = Audit.Journal or {}
Audit.ErrorCount = Audit.ErrorCount or 0
Audit.NextErrorRecord = Audit.NextErrorRecord or 0
function Audit:Record(kind, detail)
    if self.WritingJournal then return end
    self.WritingJournal = true
    local ok, err = pcall(function()
        local line = string.format("%.3f %s %s %s", RealTime(), self.Build,
            tostring(kind), string.sub(tostring(detail or ""), 1, 3000))
        local entries = self.Journal
        entries[#entries + 1] = line
        if #entries > 64 then table.remove(entries, 1) end
        file.CreateDir("legend_of_deborah")
        file.Write("legend_of_deborah/stability_" .. (SERVER and "server" or "client") .. "_latest.txt",
            table.concat(entries, "\n") .. "\n")
    end)
    self.WritingJournal = nil
    if not ok then print("[LOD STABILITY JOURNAL] " .. tostring(err)) end
end
hook.Add("OnLuaError", "LOD_RuntimeLuaErrors", function(message, realm, stack)
    Audit.ErrorCount = Audit.ErrorCount + 1
    if RealTime() < Audit.NextErrorRecord then return end
    Audit.NextErrorRecord = RealTime() + 1
    local lines = {"count=" .. Audit.ErrorCount .. " realm=" .. tostring(realm), tostring(message)}
    for i = 1, math.min(12, #(stack or {})) do
        local frame = stack[i]
        lines[#lines + 1] = tostring(frame.File or frame.short_src or frame.source)
            .. ":" .. tostring(frame.Line or frame.currentline) .. " " .. tostring(frame.Function or frame.name)
    end
    Audit:Record("LUA_ERROR", table.concat(lines, "\n"))
end)
