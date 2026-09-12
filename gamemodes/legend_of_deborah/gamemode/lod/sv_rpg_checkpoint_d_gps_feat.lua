LOD = LOD or {}; LOD.RPG = LOD.RPG or {}
local RPG = LOD.RPG
local Catalog = assert(RPG.IdentityCatalog, "GPS requires RPG catalog")
local Feats = assert(Catalog.OrdinaryFeats or Catalog.LevelOneOrdinaryFeats, "GPS requires ordinary feats")
local Rules = assert(LOD.RPGAbilityRules, "GPS requires ability rules")
local GPS_ID = "WIS_GPS"

assert(Feats[GPS_ID] == nil, "duplicate canonical feat " .. GPS_ID)
Feats[GPS_ID] = {
    featId = GPS_ID, displayName = "GPS", featFamilyId = "wis_gps", rankIndex = 1,
    replacesLowerRank = false, repeatableFallback = false,
    governingAbilities = {"wis"}, abilityRequirements = {wis = 17},
    prerequisiteFeatIds = {}, requiredCapabilityTags = {}, incompatibleFeatIds = {},
    allowedActorTypes = {"hero"}, requiredSubsystemTags = {"navigation", "information"},
    synergyTags = {"wisdom", "navigation", "information"}, oneRank = true,
    effectHandlerId = "canonical_gps_navigation",
    effectParams = {
        idleBaseSeconds = 3, idleDieSides = 6, defaultKey = "G",
        magicCost = 0, maxBarksPerStationaryEpisode = 1
    },
    directorBaseWeight = 1.0, eligibilityText = "WIS 17",
    actorText = "Player-controlled Heroes only"
}
Catalog.OrdinaryFeats = Feats

local NET_STATE = "LOD_RPGWisGPSState"
local NET_TOGGLE = "LOD_RPGWisGPSToggle"
local NET_BARK = "LOD_RPGWisGPSBark"
util.AddNetworkString(NET_STATE)
util.AddNetworkString(NET_TOGGLE)
util.AddNetworkString(NET_BARK)
resource.AddFile("sound/lod/gps_voice_bank.mp3")

local runtime = setmetatable({}, {__mode = "k"})
local MOVE_SPEED_SQR = 32 * 32
local COMBAT_QUIET_SECONDS = 3.0

local function owns(state)
    for _, id in ipairs(state and state.featIds or {}) do
        if id == GPS_ID then return true end
    end
    return false
end

local function heroOwnsGPS(ply)
    local state = Rules:ProgressionState(ply)
    return IsValid(ply) and ply:IsPlayer() and state ~= nil and owns(state)
end

local function sendState(ply, enabled, acquired)
    net.Start(NET_STATE)
    net.WriteBool(enabled == true)
    net.WriteBool(acquired == true)
    net.Send(ply)
end

local function resetEpisode(r)
    r.cellKey = nil
    r.idleStarted = nil
    r.delay = nil
    r.barked = false
end

local function cellKey(cell)
    return cell and string.format("%d:%d:%d", cell.x or 0, cell.y or 0, cell.z or 0) or nil
end

local function sealedIdleDelay(ply, r)
    r.episode = (r.episode or 0) + 1
    local identity = ply:SteamID64() or tostring(ply:UserID())
    local roll = math.floor(util.SharedRandom("LOD_WIS_GPS:" .. identity, 1, 7, r.episode))
    return 3 + math.Clamp(roll, 1, 6)
end

local function activeCombat(ply)
    if ply:KeyDown(IN_ATTACK) or ply:KeyDown(IN_ATTACK2) then return true end
    local audit = LOD.HostileDamageAudit
    local record = audit and audit.LastByPlayer and audit.LastByPlayer[ply]
    return record and (CurTime() - (record.at or 0)) < COMBAT_QUIET_SECONDS or false
end

local function intrusiveState(ply)
    if not IsValid(ply) or not ply:Alive() then return true end
    local rm = LOD.RunManager
    local rs = rm and rm.State
    if not rm or not rm.IsActivePlayer or not rm:IsActivePlayer(ply) then return true end
    if rs and (rs.Failed or rs.LevelCleared or rs.IntermissionEnd) then return true end
    if ply:GetObserverMode() ~= OBS_MODE_NONE then return true end
    return activeCombat(ply)
end

local function cardinalFromYaw(yaw)
    local normalized = math.NormalizeAngle(tonumber(yaw) or 0)
    local quarter = math.floor((normalized + 45) / 90)
    quarter = ((quarter % 4) + 4) % 4
    if quarter == 0 then return 1, 0 end
    if quarter == 1 then return 0, 1 end
    if quarter == 2 then return -1, 0 end
    return 0, -1
end

local function edgeDirection(a, b)
    if not a or not b then return nil end
    local dz = (b.z or 0) - (a.z or 0)
    if dz > 0 then return "UP" end
    if dz < 0 then return "DOWN" end
    local dx, dy = (b.x or 0) - (a.x or 0), (b.y or 0) - (a.y or 0)
    if math.abs(dx) + math.abs(dy) ~= 1 then return nil end
    return dx, dy
end

local function turnText(fx, fy, dx, dy)
    local dot = fx * dx + fy * dy
    if dot == 1 then return "FORWARD" end
    if dot == -1 then return "TURN AROUND" end
    return (fx * dy - fy * dx) > 0 and "TURN LEFT" or "TURN RIGHT"
end

function RPG:CheckpointDWisGPSGuidance(path, yaw)
    if not path or #path <= 1 then return "YOU HAVE ARRIVED AT YOUR DESTINATION" end
    local d1, d2 = edgeDirection(path[1], path[2])
    if d1 == "UP" then return "TAKE THE STAIRS UP" end
    if d1 == "DOWN" then return "TAKE THE STAIRS DOWN" end
    if not d1 then return nil end

    local fx, fy = cardinalFromYaw(yaw)
    local immediate = turnText(fx, fy, d1, d2)
    if immediate ~= "FORWARD" then return immediate end

    local run, pdx, pdy = 1, d1, d2
    for i = 2, #path - 1 do
        local ndx, ndy = edgeDirection(path[i], path[i + 1])
        if ndx == "UP" or ndx == "DOWN" then
            return string.format("IN %d %s TAKE THE STAIRS %s",
                run, run == 1 and "SQUARE" or "SQUARES", ndx)
        end
        if not ndx then break end
        if ndx ~= pdx or ndy ~= pdy then
            return string.format("IN %d %s %s",
                run, run == 1 and "SQUARE" or "SQUARES", turnText(pdx, pdy, ndx, ndy))
        end
        run = run + 1
    end
    return "CONTINUE FORWARD"
end

local function guidanceFor(ply, cell)
    local rm = LOD.RunManager
    local graph = rm and rm.State and rm.State.Graph
    local navigator = LOD.MazeNavigator
    local director = LOD.ProgressionDirector
    if not graph or not navigator or not director then return nil end
    local objective = director:GetObjectiveGraphTarget()
    if not objective or not objective.a then return nil end
    local path = navigator:FindPath(graph, cell, objective.a)
    if not path then return nil end
    return RPG:CheckpointDWisGPSGuidance(path, ply:EyeAngles().y)
end

local function updateGPS(ply)
    if not heroOwnsGPS(ply) then
        runtime[ply] = nil
        return
    end

    local r = runtime[ply]
    if not r then
        r = {enabled = true, episode = 0}
        runtime[ply] = r
        sendState(ply, true, true)
    end

    if not r.enabled or intrusiveState(ply) then
        resetEpisode(r)
        return
    end

    local graph = LOD.RunManager and LOD.RunManager.State and LOD.RunManager.State.Graph
    local navigator = LOD.MazeNavigator
    if not graph or not navigator then resetEpisode(r); return end
    local cell = navigator:WorldToCell(graph, ply:GetPos())
    if not cell then resetEpisode(r); return end

    local moving = ply:GetVelocity():Length2DSqr() >= MOVE_SPEED_SQR
    local key = cellKey(cell)
    if moving or (r.cellKey and r.cellKey ~= key) then
        resetEpisode(r)
        r.cellKey = key
        return
    end

    if r.cellKey ~= key or not r.idleStarted then
        r.cellKey = key
        r.idleStarted = CurTime()
        r.delay = sealedIdleDelay(ply, r)
        r.barked = false
        return
    end

    if r.barked or CurTime() < r.idleStarted + r.delay then return end
    local text = guidanceFor(ply, cell)
    if not text then return end
    r.barked = true
    net.Start(NET_BARK)
    net.WriteString(text)
    net.Send(ply)
end

net.Receive(NET_TOGGLE, function(_, ply)
    if not heroOwnsGPS(ply) then return end
    local r = runtime[ply] or {enabled = true, episode = 0}
    runtime[ply] = r
    r.enabled = not r.enabled
    resetEpisode(r)
    sendState(ply, r.enabled, false)
end)

timer.Create("LOD_CheckpointDWisGPS", 0.20, 0, function()
    for _, ply in ipairs(player.GetHumans()) do updateGPS(ply) end
end)

function RPG:ValidateCheckpointDWisGPS()
    local errors = {}
    local function expect(ok, message) if not ok then errors[#errors + 1] = message end end
    local gps = Feats[GPS_ID]
    expect(gps and gps.abilityRequirements.wis == 17, "GPS WIS 17 gate")
    expect(gps and #gps.allowedActorTypes == 1 and gps.allowedActorTypes[1] == "hero", "GPS Hero-only")
    expect(gps and gps.effectParams.idleBaseSeconds == 3 and gps.effectParams.idleDieSides == 6,
        "GPS sealed 3+1d6 delay")
    expect(gps and gps.effectParams.magicCost == 0, "GPS no Magic cost")
    expect(self:CheckpointDWisGPSGuidance({
        {x=1,y=1,z=0},{x=2,y=1,z=0},{x=3,y=1,z=0},{x=3,y=2,z=0}
    }, 0) == "IN 2 SQUARES TURN LEFT", "GPS exact route turn distance")
    expect(self:CheckpointDWisGPSGuidance({{x=1,y=1,z=0},{x=1,y=2,z=0}}, 0) == "TURN LEFT",
        "GPS immediate left")
    expect(self:CheckpointDWisGPSGuidance({{x=1,y=1,z=0},{x=0,y=1,z=0}}, 0) == "TURN AROUND",
        "GPS immediate reverse")
    expect(self:CheckpointDWisGPSGuidance({{x=1,y=1,z=0},{x=1,y=1,z=1}}, 0) == "TAKE THE STAIRS UP",
        "GPS stairs up")
    expect(self:CheckpointDWisGPSGuidance({{x=1,y=1,z=0}}, 0) == "YOU HAVE ARRIVED AT YOUR DESTINATION",
        "GPS arrival")
    return #errors == 0, errors
end

concommand.Add("lod_rpg_validate_wis_gps", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end
    local ok, errors = RPG:ValidateCheckpointDWisGPS()
    print("[LOD:WIS-GPS] " .. (ok and "PASS" or "FAIL")
        .. (#errors > 0 and (" " .. table.concat(errors, "; ")) or ""))
end)
