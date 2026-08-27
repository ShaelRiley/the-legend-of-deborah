LOD = LOD or {}
LOD.TopologySyncSafety = LOD.TopologySyncSafety or {}

local Sync = LOD.TopologySyncSafety
local RunManager = LOD.RunManager
local ProgressionDirector = LOD.ProgressionDirector
local WallVisuals = LOD.WallVisuals

if not RunManager or not ProgressionDirector then return end

Sync.BuildSerial = Sync.BuildSerial or 0

util.AddNetworkString("LOD_TopologyIdentity")
util.AddNetworkString("LOD_WallVisualsRequest")

-- Every build transaction gets a monotonically increasing identity, even if the
-- caller deliberately regenerates the exact same seed. This matters during live
-- development because presentation code can change while topology coordinates do
-- not; a same-seed rebuild must still retire all client caches from the prior build.
if not RunManager.LODTopologyBuildSerialWrapped then
    RunManager.LODTopologyBuildSerialWrapped = true
    local baseBuildCurrentLevel = RunManager.BuildCurrentLevel

    function RunManager:BuildCurrentLevel(...)
        Sync.BuildSerial = (Sync.BuildSerial or 0) + 1
        return baseBuildCurrentLevel(self, ...)
    end
end

local function topologyIdentity()
    local state = RunManager.State
    local graph = state and state.Graph
    if not state or not graph or not state.BuildReady then return nil end

    return {
        buildSerial = math.max(0, tonumber(Sync.BuildSerial) or 0),
        epoch = math.max(0, tonumber(state.CampaignEpoch) or 0),
        level = math.max(1, tonumber(state.Level) or 1),
        seed = math.max(0, tonumber(graph.LevelSeed or state.LevelSeed) or 0),
        layoutAttempt = math.max(0, tonumber(graph.ProgressionLayoutAttempt) or 0),
        mazeAttempt = math.max(0, tonumber(graph.Attempt) or 0)
    }
end

function Sync:SendIdentity(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    local identity = topologyIdentity()
    if not identity then return false end

    net.Start("LOD_TopologyIdentity")
    net.WriteUInt(identity.buildSerial, 32)
    net.WriteUInt(identity.epoch, 32)
    net.WriteUInt(identity.level, 20)
    net.WriteUInt(identity.seed, 32)
    net.WriteUInt(math.min(identity.layoutAttempt, 255), 8)
    net.WriteUInt(math.min(identity.mazeAttempt, 255), 8)
    net.Send(ply)
    return true
end

-- Progression state is already the canonical moment at which each client learns
-- that a built level is live. Attach an immutable topology identity to that same
-- synchronization point. This closes the same-level restart/regeneration hole in
-- which a client could retain a perfectly valid map or wall manifest from an old
-- Level 1 merely because the displayed level number had not changed.
if not ProgressionDirector.LODTopologyIdentityWrapped then
    ProgressionDirector.LODTopologyIdentityWrapped = true
    local baseSyncPlayer = ProgressionDirector.SyncPlayer

    function ProgressionDirector:SyncPlayer(ply)
        local result = baseSyncPlayer(self, ply)
        if RunManager.State and RunManager.State.BuildReady and RunManager.State.Graph then
            Sync:SendIdentity(ply)
        end
        return result
    end
end

-- Wall visuals are clientside presentation, while wall collision is server-side.
-- Give a client that detects a stale manifest one cheap event-driven recovery path
-- instead of allowing a phantom wall to persist for the rest of the dungeon.
net.Receive("LOD_WallVisualsRequest", function(_, ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    local now = CurTime()
    if now < (ply.LODNextWallVisualResync or 0) then return end
    ply.LODNextWallVisualResync = now + 0.35
    if WallVisuals and WallVisuals.Send then WallVisuals:Send(ply) end
end)

hook.Add("PlayerInitialSpawn", "LOD_TopologyIdentityInitialSync", function(ply)
    timer.Simple(1.0, function()
        if IsValid(ply) then Sync:SendIdentity(ply) end
    end)
end)

concommand.Add("lod_topology_server_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local identity = topologyIdentity()
    if not identity then
        print("[LOD:TOPOLOGY] no built topology")
        return
    end

    local wallSeed = WallVisuals and WallVisuals.Payload and identity.seed or 0
    local line = string.format(
        "build=%d epoch=%d level=%d topologySeed=%d layoutAttempt=%d mazeAttempt=%d wallManifest=%s wallSegments=%d",
        identity.buildSerial, identity.epoch, identity.level, identity.seed,
        identity.layoutAttempt, identity.mazeAttempt,
        wallSeed == identity.seed and "READY" or "MISSING",
        WallVisuals and WallVisuals.LogicalCount or 0)
    print("[LOD:TOPOLOGY] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
