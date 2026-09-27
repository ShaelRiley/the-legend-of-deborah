LOD = LOD or {}
LOD.SnapshotDelivery = LOD.SnapshotDelivery or {}
local Delivery = LOD.SnapshotDelivery

-- State snapshots are replaceable observations, unlike ordered DIE-LOGGER events.
-- Multi-kill XP settlement used to write the entire sheet/book forty times in one
-- tick. Resolve only the latest state after that transaction and deduplicate it.
-- Fixed channels keep each player's pending/cache storage bounded.
local CHANNELS = {"LOD_RPG_Snapshot", "LOD_MagicSpellbookSnapshot", "LOD_EquipmentSnapshot", "LOD_WalletSnapshot"}
local allowed = {}; for _, name in ipairs(CHANNELS) do allowed[name] = true end
local INTERVAL = 0.1 -- presentation delivery only; gameplay never waits for this
local function weakKeys() return setmetatable({}, {__mode = "k"}) end
Delivery.Players = weakKeys()
-- Presentation leases survive cache invalidation/map cleanup. A full resync is
-- not a new life and must not silently mark unread content as read.
Delivery.PageScopes = Delivery.PageScopes or weakKeys()
Delivery.PageEpoch = Delivery.PageEpoch or 0
Delivery.Stats = {requested=0, coalesced=0, unchanged=0, sent=0, bytes=0, maxFlushBytes=0}

local function equal(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then return a == b end
    for k, v in pairs(a) do if not equal(v, b[k]) then return false end end
    for k in pairs(b) do if a[k] == nil then return false end end
    return true
end

local PAGE_CHANNEL = {LOD_RPG_Snapshot=true, LOD_MagicSpellbookSnapshot=true,
    LOD_EquipmentSnapshot=true}
local SCOPE_KEYS = {"run", "playerState", "hero", "identity", "soldier", "alive"}
function Delivery:PageScope(ply, delivery)
    local run = LOD.RunManager
    local ps = run and run.GetPlayerState and run:GetPlayerState(ply)
    local soldier = LOD.SoldierProgression
    local scope = {run=run and run.State, playerState=ps,
        hero=ps and ps.progressionState, identity=ps and ps.identity,
        soldier=soldier and soldier:StateFor(ply), alive=ply.Alive and ply:Alive()}
    local old = self.PageScopes[ply]
    local same = old ~= nil
    for _, key in ipairs(SCOPE_KEYS) do
        if not old or old[key] ~= scope[key] then same=false; break end
    end
    if not same then
        self.PageEpoch = self.PageEpoch + 1
        scope.epoch, scope.revisions = self.PageEpoch, {}
        self.PageScopes[ply] = scope
    else scope = old end
    if delivery.scope ~= scope then
        delivery.scope = scope
        for channel in pairs(PAGE_CHANNEL) do delivery.last[channel] = nil end
        delivery.pageMeta = {}
    end
    return scope
end

local function envelope(snapshot, meta)
    local wire = {}
    for key, value in pairs(snapshot) do wire[key] = value end
    wire._pageUpdate = meta
    return wire
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
                    local scope = PAGE_CHANNEL[channel] and self:PageScope(ply, state)
                    local snapshot = queued.build(ply)
                    -- A producer may synchronously finish a role/profile transition.
                    if scope and self:PageScope(ply, state) ~= scope then
                        self:Queue(ply, channel, queued.build, queued.write)
                        return
                    end
                    if not snapshot then state.last[channel] = nil; return end
                    if equal(snapshot, state.last[channel]) then
                        self.Stats.unchanged = self.Stats.unchanged + 1
                        return
                    end
                    local wire, previous, meta = snapshot, state.last[channel]
                    if scope then
                        meta = {epoch=scope.epoch, revision=(scope.revisions[channel] or 0)+1}
                        local previousMeta = state.pageMeta[channel]
                        if previous and previousMeta then
                            meta.base = previousMeta.revision
                            previous = envelope(previous, previousMeta)
                        else previous = nil end
                        wire = envelope(snapshot, meta)
                    end
                    net.Start(channel)
                    if queued.write then queued.write(wire, previous, equal)
                    else net.WriteTable(wire) end
                    local bytes = net.BytesWritten and net.BytesWritten() or 0
                    net.Send(ply)
                    -- Some Soldier fields alias mutable server tables.
                    state.last[channel] = table.Copy(snapshot)
                    if scope then
                        scope.revisions[channel] = meta.revision
                        state.pageMeta[channel] = meta
                    end
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
    Delivery.Players[ply], Delivery.PageScopes[ply] = nil, nil
end)
-- Do not use the deployment/spawn serial: ordinary dungeon transitions also
-- spawn the same Hero. Death explicitly retires even a same-tick respawn.
hook.Add("PlayerDeath", "LOD_SnapshotDeliveryLife", function(ply)
    Delivery.PageScopes[ply] = nil
end)
hook.Add("PreCleanupMap", "LOD_SnapshotDeliveryCleanup", function()
    Delivery.Players = weakKeys()
end)
