LOD = LOD or {}
LOD.InstructionManualTransport = LOD.InstructionManualTransport or {}
local Transport = LOD.InstructionManualTransport

local REQUEST_NET = "LOD_RequestInstructionManual"
local PAYLOAD_NET = "LOD_InstructionManualPayload"
local CHUNK_BYTES = 60000
local MAX_CHUNKS = 64

local manifest = include("lod/manual/manifest.lua")
local source = {}
for index = 1, manifest.chunks do
    source[index] = include(string.format("lod/manual/html_%02d.lua", index))
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
Transport.Active = Transport.Active or setmetatable({}, {__mode = "k"})
Transport.LastRequest = Transport.LastRequest or setmetatable({}, {__mode = "k"})

util.AddNetworkString(REQUEST_NET)
util.AddNetworkString(PAYLOAD_NET)

local function nextTransferId()
    Transport.NextTransfer = (Transport.NextTransfer % 65535) + 1
    return Transport.NextTransfer
end

local function sendChunk(ply, transferId, index)
    if not IsValid(ply) or Transport.Active[ply] ~= transferId then return end
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
    if index == chunkCount and Transport.Active[ply] == transferId then
        Transport.Active[ply] = nil
    end
end

net.Receive(REQUEST_NET, function(_, ply)
    if not IsValid(ply) or Transport.Active[ply] then return end
    local now = CurTime()
    if Transport.LastRequest[ply] and now - Transport.LastRequest[ply] < 5 then return end
    Transport.LastRequest[ply] = now
    local transferId = nextTransferId()
    Transport.Active[ply] = transferId
    for index = 1, chunkCount do
        timer.Simple((index - 1) * 0.03, function()
            sendChunk(ply, transferId, index)
        end)
    end
end)

LOD.RuntimeReceipts = LOD.RuntimeReceipts or {}
LOD.RuntimeReceipts["manual"] = "stability-20260915-04"
