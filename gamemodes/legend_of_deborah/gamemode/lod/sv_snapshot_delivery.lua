LOD = LOD or {}
LOD.SnapshotDelivery = LOD.SnapshotDelivery or {}
local Delivery = LOD.SnapshotDelivery

-- State snapshots are replaceable observations, unlike ordered DIE-LOGGER events.
-- Multi-kill XP settlement used to write the entire sheet/book forty times in one
-- tick. Resolve only the latest state after that transaction and deduplicate it.
-- Fixed channels keep each player's pending/cache storage bounded.
local CHANNELS = {"LOD_RPG_Snapshot", "LOD_MagicSpellbookSnapshot", "LOD_EquipmentSnapshot"}
local allowed = {}; for _, name in ipairs(CHANNELS) do allowed[name] = true end
local INTERVAL = 0.1 -- presentation delivery only; gameplay never waits for this
local function weakKeys() return setmetatable({}, {__mode = "k"}) end
Delivery.Players = weakKeys()
Delivery.Stats = {requested=0, coalesced=0, unchanged=0, sent=0, bytes=0, maxFlushBytes=0}

local function equal(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then return a == b end
    for k, v in pairs(a) do if not equal(v, b[k]) then return false end end
    for k in pairs(b) do if a[k] == nil then return false end end
    return true
end

function Delivery:Queue(ply, name, build, write)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    assert(allowed[name], "unregistered snapshot channel")
    local state = self.Players[ply]
    if not state then
        state = {pending={}, last={}}
        self.Players[ply] = state
    end
    self.Stats.requested = self.Stats.requested + 1
    if state.pending[name] then self.Stats.coalesced = self.Stats.coalesced + 1 end
    state.pending[name] = {build=build, write=write}
    if state.scheduled then return end
    state.scheduled = true
    timer.Simple(INTERVAL, function()
        -- Disconnect/cleanup invalidates captured work even if an entity index is reused.
        if self.Players[ply] ~= state or not IsValid(ply) then return end
        state.scheduled = false
        local pending = state.pending
        state.pending = {}
        local flushBytes = 0
        for _, channel in ipairs(CHANNELS) do
            local queued = pending[channel]
            if queued then
                local ok, err = pcall(function()
                    -- Read at dispatch: never send a captured, retired incarnation.
                    local snapshot = queued.build(ply)
                    if not snapshot then state.last[channel] = nil; return end
                    if equal(snapshot, state.last[channel]) then
                        self.Stats.unchanged = self.Stats.unchanged + 1
                        return
                    end
                    net.Start(channel)
                    if queued.write then queued.write(snapshot, state.last[channel], equal)
                    else net.WriteTable(snapshot) end
                    local bytes = net.BytesWritten and net.BytesWritten() or 0
                    net.Send(ply)
                    -- Some Soldier fields alias mutable server tables.
                    state.last[channel] = table.Copy(snapshot)
                    self.Stats.sent = self.Stats.sent + 1
                    self.Stats.bytes = self.Stats.bytes + bytes
                    flushBytes = flushBytes + bytes
                    local log = LOD.RPGTestLog
                    if log and log.Write then
                        log:Write("SNAPSHOT_SEND", {channel=channel, bytes=bytes,
                            player=ply:EntIndex(), coalesced=self.Stats.coalesced})
                    end
                end)
                if not ok then ErrorNoHalt("[LOD:SNAPSHOT] " .. tostring(err) .. "\n") end
            end
        end
        self.Stats.maxFlushBytes = math.max(self.Stats.maxFlushBytes, flushBytes)
    end)
end

-- Explicit client requests recover a snapshot sent before InitPostEntity, or a
-- discarded local UI cache. They still share the same bounded delivery window.
function Delivery:Invalidate(ply, channel)
    local state = self.Players[ply]
    if not state then return end
    if channel then state.last[channel] = nil else state.last = {} end
end

hook.Add("PlayerDisconnected", "LOD_SnapshotDeliveryDisconnect", function(ply)
    Delivery.Players[ply] = nil
end)
hook.Add("PreCleanupMap", "LOD_SnapshotDeliveryCleanup", function()
    Delivery.Players = weakKeys()
end)
