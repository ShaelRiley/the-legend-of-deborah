LOD = LOD or {}
LOD.RuntimeAudit = LOD.RuntimeAudit or {}
local Audit = LOD.RuntimeAudit
Audit.Build = "stability-20260915-02"
LOD.RuntimeReceipts = LOD.RuntimeReceipts or {}

local expected = SERVER and {"hostile", "pickup", "loot", "staging", "equipment", "crowbar", "statue"}
    or {"meshes", "mirror"}

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
        lua_kb = math.floor(collectgarbage("count")),
        entities = ents.GetCount and ents.GetCount() or #ents.GetAll(),
        meshes = LOD.TexturedBox and LOD.TexturedBox.MeshCacheCount and LOD.TexturedBox:MeshCacheCount() or 0
    }
end

function Audit:Report()
    local data = self:Snapshot()
    local parts = {}
    for _, key in ipairs({"build", "realm", "install", "missing", "architecture", "branch", "engine", "lua_kb", "entities", "meshes"}) do
        parts[#parts + 1] = key .. "=" .. tostring(data[key])
    end
    print("[LOD BUILD_IDENTITY] " .. table.concat(parts, " "))
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
