LOD = LOD or {}
LOD.WallVisuals = LOD.WallVisuals or {}

local WallVisuals = LOD.WallVisuals
local MESSAGE = "LOD_WallVisuals"
local PROTOCOL = 1
local MAX_PAYLOAD_BYTES = 60000

util.AddNetworkString(MESSAGE)

local function connectedPlayers()
    return player.GetAll()
end

function WallVisuals:_WritePayload(payload)
    local byteCount = payload and #payload or 0
    net.Start(MESSAGE)
    net.WriteUInt(byteCount, 16)
    if byteCount > 0 then net.WriteData(payload, byteCount) end
end

function WallVisuals:Send(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    self:_WritePayload(self.Payload)
    net.Send(ply)
    return true
end

function WallVisuals:Broadcast()
    local recipients = connectedPlayers()
    if #recipients == 0 then return end
    self:_WritePayload(self.Payload)
    net.Send(recipients)
end

function WallVisuals:Clear()
    if not self.Payload and (self.LogicalCount or 0) == 0 then return end
    self.Payload = nil
    self.LogicalCount = 0
    self:Broadcast()
end

function WallVisuals:SetSegments(graph, segments)
    local compact = {}
    for _, segment in ipairs(segments or {}) do
        compact[#compact + 1] = {
            tonumber(segment[1]) or 0,
            tonumber(segment[2]) or 0,
            tonumber(segment[3]) or 0,
            tonumber(segment[4]) or 0
        }
    end

    local json = util.TableToJSON({
        v = PROTOCOL,
        seed = graph and graph.LevelSeed or 0,
        segments = compact
    }, false)
    local payload = json and util.Compress(json) or nil
    if not payload or #payload <= 0 or #payload > MAX_PAYLOAD_BYTES then
        ErrorNoHalt(string.format(
            "[LOD] wall visual manifest failed: segments=%d compressedBytes=%s\n",
            #compact, payload and tostring(#payload) or "nil"
        ))
        return false
    end

    self.Payload = payload
    self.LogicalCount = #compact
    self.CompressedBytes = #payload
    self:Broadcast()
    print(string.format(
        "[LOD] Wall visuals published: logicalSegments=%d modelInstances=%d compressedBytes=%d",
        #compact, #compact * (LOD.Config.Geometry.WallStack or 2), #payload
    ))
    return true
end

hook.Add("PlayerInitialSpawn", "LOD_WallVisualsInitialSync", function(ply)
    timer.Simple(0.75, function()
        if IsValid(ply) then WallVisuals:Send(ply) end
    end)
end)
