-- The canonical manual is server-streamed because clientside AddCSLuaFile
-- delivery of its generated payload failed in the native Steam Deck runtime.
local registered, receivers, messages = {}, {}, {}
local first = '<!doctype html><html><body>' .. string.rep('A', 59990)
local second = string.rep('B', 10020) .. '</body></html>'

LOD = {}
isstring = function(value) return type(value) == 'string' end
IsValid = function(value) return type(value) == 'table' and value.valid ~= false end
CurTime = function() return 10 end
include = function(path)
    if path == 'lod/manual/manifest.lua' then
        return {version = 'transport-test', chapters = 124, chunks = 2}
    end
    if path == 'lod/manual/html_01.lua' then return first end
    if path == 'lod/manual/html_02.lua' then return second end
    error('unexpected include ' .. tostring(path))
end
util = {
    Compress = function(value) return value end,
    AddNetworkString = function(name) registered[name] = true end
}
timer = {Simple = function(_, callback) callback() end}

local writing
net = {
    Receive = function(name, callback) receivers[name] = callback end,
    Start = function(name) writing = {name = name, fields = {}} end,
    WriteString = function(value) writing.fields[#writing.fields + 1] = value end,
    WriteUInt = function(value) writing.fields[#writing.fields + 1] = value end,
    WriteData = function(value) writing.fields[#writing.fields + 1] = value end,
    Send = function(player)
        writing.player = player
        messages[#messages + 1] = writing
        writing = nil
    end
}

dofile('gamemodes/legend_of_deborah/gamemode/lod/sv_instruction_manual.lua')
assert(registered.LOD_RequestInstructionManual and registered.LOD_InstructionManualPayload)
assert(receivers.LOD_RequestInstructionManual)
local player = {valid = true}
receivers.LOD_RequestInstructionManual(0, player)
assert(#messages == 2, '70KB compressed fixture must be split into two bounded messages')

local pieces = {}
for index, message in ipairs(messages) do
    local fields = message.fields
    assert(message.name == 'LOD_InstructionManualPayload' and message.player == player)
    assert(fields[1] == 'transport-test' and fields[2] == 124)
    assert(fields[3] == 1 and fields[4] == index and fields[5] == 2)
    assert(fields[6] == #(first .. second) and fields[7] == #fields[8])
    assert(fields[7] <= 60000, 'transport chunk exceeds safe net-message payload')
    pieces[index] = fields[8]
end
assert(table.concat(pieces) == first .. second, 'transport did not preserve exact manual bytes')

messages = {}
receivers.LOD_RequestInstructionManual(0, {valid = false})
assert(#messages == 0, 'invalid requesters must not start a transfer')
print('MANUAL_TRANSPORT_PASS: canonical bytes stream in bounded ordered chunks without client payload files')
