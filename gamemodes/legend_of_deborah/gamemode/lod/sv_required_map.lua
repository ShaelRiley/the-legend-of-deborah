LOD = LOD or {}
LOD.RequiredMap = LOD.RequiredMap or {}

local Required = LOD.RequiredMap
local REQUIRED_MAP = "gm_flatgrass"

Required.Name = REQUIRED_MAP
Required.Redirects = Required.Redirects or 0

local function onRequiredMap()
    return string.lower(game.GetMap() or "") == REQUIRED_MAP
end

function Required:IsCorrect()
    return onRequiredMap()
end

-- The stock GMod menu treats a gamemode's `maps` field as categorisation metadata,
-- not as a hard launch whitelist. Preserve the exact menu metadata, but also make
-- the runtime contract authoritative: LOD only runs on gm_flatgrass. If somebody
-- launches the gamemode from another visible map category, immediately redirect
-- before normal play can begin instead of building the procedural dungeon there.
if not onRequiredMap() then
    timer.Simple(0, function()
        if onRequiredMap() then return end
        Required.Redirects = (Required.Redirects or 0) + 1
        print(string.format(
            "[LOD:MAP] unsupported base map '%s'; redirecting to %s",
            tostring(game.GetMap()), REQUIRED_MAP))
        RunConsoleCommand("changelevel", REQUIRED_MAP)
    end)
end

concommand.Add("lod_required_map_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local line = string.format(
        "map=%s required=%s correct=%s redirects=%d",
        tostring(game.GetMap()), REQUIRED_MAP, tostring(onRequiredMap()),
        Required.Redirects or 0)
    print("[LOD:MAP] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
