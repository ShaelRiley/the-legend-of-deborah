LOD = LOD or {}
LOD.InstructionManualTransport = LOD.InstructionManualTransport or {}
local Transport = LOD.InstructionManualTransport

local REQUEST_NET = "LOD_RequestInstructionManual"
local PAYLOAD_NET = "LOD_InstructionManualPayload"
local ACK_NET = "LOD_InstructionManualAck"
local CHUNK_BYTES = 16384
local MAX_CHUNKS = 255

local manifest = include("legend_of_deborah/gamemode/lod/manual/manifest.lua")
local source = {}
for index = 1, manifest.chunks do
    source[index] = include(string.format("legend_of_deborah/gamemode/lod/manual/html_%02d.lua", index))
end

local html = table.concat(source)
local packed = util.Compress(html)
assert(isstring(packed) and #packed > 0, "instruction manual compression failed")

local chunkCount = math.ceil(#packed / CHUNK_BYTES)
assert(chunkCount <= MAX_CHUNKS, "instruction manual exceeds bounded transport")

Transport.Version = manifest.version
Transport.Chapters = manifest.chapters
Transport.PackedBytes = #packed
Transport.ChunkCount = chunkCount
Transport.NextTransfer = Transport.NextTransfer or 0
Transport.Active = setmetatable({}, {__mode = "k"})
Transport.LastRequest = Transport.LastRequest or setmetatable({}, {__mode = "k"})

util.AddNetworkString(REQUEST_NET)
util.AddNetworkString(PAYLOAD_NET)
util.AddNetworkString(ACK_NET)

local function nextTransferId()
    Transport.NextTransfer = (Transport.NextTransfer % 65535) + 1
    return Transport.NextTransfer
end

local function sendChunk(ply, transferId, index)
    local transfer = Transport.Active[ply]
    if not IsValid(ply) or not transfer or transfer.id ~= transferId then return end
    transfer.index, transfer.expires = index, RealTime() + 10
    local first = (index - 1) * CHUNK_BYTES + 1
    local data = string.sub(packed, first, math.min(first + CHUNK_BYTES - 1, #packed))
    net.Start(PAYLOAD_NET)
    net.WriteString(manifest.version)
    net.WriteUInt(manifest.chapters, 8)
    net.WriteUInt(transferId, 16)
    net.WriteUInt(index, 8)
    net.WriteUInt(chunkCount, 8)
    net.WriteUInt(#packed, 24)
    net.WriteUInt(#data, 16)
    net.WriteData(data, #data)
    net.Send(ply)
end

net.Receive(REQUEST_NET, function(length, ply)
    if length ~= 0 then return end
    if not IsValid(ply) or Transport.Active[ply] then return end
    local now = RealTime()
    if Transport.LastRequest[ply] and now - Transport.LastRequest[ply] < 5 then return end
    Transport.LastRequest[ply] = now
    local transferId = nextTransferId()
    Transport.Active[ply] = {id = transferId}
    sendChunk(ply, transferId, 1)
end)

LOD.RuntimeReceipts = LOD.RuntimeReceipts or {}
LOD.RuntimeReceipts["manual"] = "stability-20260916-07"

-- One chunk in flight per client: never fill the reliable channel with the
-- illustrated book. Receipt of a matching ACK is the only way to advance.
net.Receive(ACK_NET, function(length, ply)
    if length ~= 24 then return end
    local id, index = net.ReadUInt(16), net.ReadUInt(8)
    local transfer = Transport.Active[ply]
    if not transfer or transfer.id ~= id or transfer.index ~= index or transfer.waiting then return end
    if index == chunkCount then Transport.Active[ply] = nil; return end
    transfer.waiting = true
    timer.Simple(0.05, function()
        if Transport.Active[ply] ~= transfer then return end
        transfer.waiting = nil
        sendChunk(ply, id, index + 1)
    end)
end)
hook.Add("PlayerDisconnected", "LOD_ManualTransferCleanup", function(ply)
    Transport.Active[ply], Transport.LastRequest[ply] = nil, nil
end)
timer.Create("LOD_ManualTransferExpiry", 1, 0, function()
    for ply, transfer in pairs(Transport.Active) do
        if not IsValid(ply) or RealTime() > transfer.expires then Transport.Active[ply] = nil end
    end
end)
