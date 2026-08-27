LOD = LOD or {}
LOD.MinimapMagic = LOD.MinimapMagic or {}

local MapMagic = LOD.MinimapMagic
local Minimap = LOD.MinimapServer
local RunManager = LOD.RunManager

local MAX_MAGIC = 100
local FULL_DRAIN_SECONDS = 15
local DRAIN_RATE = MAX_MAGIC / FULL_DRAIN_SECONDS
local TICK_SECONDS = 0.10
local HEARTBEAT_TIMEOUT = 1.25
local TIMER_NAME = "LOD_MinimapMagicDrain"

util.AddNetworkString("LOD_MapMagicState")
util.AddNetworkString("LOD_MapMagicForcedClose")

MapMagic.Active = MapMagic.Active or setmetatable({}, {__mode = "k"})
MapMagic.Stats = MapMagic.Stats or {opens = 0, drained = 0, forcedCloses = 0}

local function magicAuthority()
    return LOD.Magic
end

local function stopDrain(ply, reason)
    local state = MapMagic.Active[ply]
    if not state then
        if IsValid(ply) then ply:SetNW2Bool("LOD_MapMagicActive", false) end
        return
    end

    MapMagic.Active[ply] = nil
    if IsValid(ply) then
        ply:SetNW2Bool("LOD_MapMagicActive", false)
        if reason then
            net.Start("LOD_MapMagicForcedClose")
            net.WriteString(reason)
            net.Send(ply)
            MapMagic.Stats.forcedCloses = (MapMagic.Stats.forcedCloses or 0) + 1
        end
    end
end

local function canDrain(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return false end
    if not Minimap or not Minimap.CanUse or not Minimap:CanUse(ply) then return false end
    if not RunManager or not RunManager.State or RunManager.State.Failed
        or RunManager.State.LevelCleared or RunManager.State.SimulationFrozen
    then
        return false
    end
    return true
end

local function beginOrRefresh(ply)
    if not canDrain(ply) then
        stopDrain(ply, "")
        return false
    end

    local Magic = magicAuthority()
    if not Magic or not Magic._EnsureState or not Magic._Sync then
        stopDrain(ply, "MAP MAGIC UNAVAILABLE")
        return false
    end

    local ps = Magic:_EnsureState(ply)
    if not ps or (tonumber(ps.magic) or 0) <= 0 then
        stopDrain(ply, "MAP CLOSED — NO MAGIC")
        return false
    end

    local now = CurTime()
    local state = MapMagic.Active[ply]
    if not state then
        state = {
            lastHeartbeat = now,
            lastTick = now,
            mapMagic = math.Clamp(tonumber(ps.magic) or 0, 0, MAX_MAGIC)
        }
        MapMagic.Active[ply] = state
        MapMagic.Stats.opens = (MapMagic.Stats.opens or 0) + 1
        ply:SetNW2Bool("LOD_MapMagicActive", true)
    else
        state.lastHeartbeat = now
        state.mapMagic = math.min(state.mapMagic or MAX_MAGIC,
            math.Clamp(tonumber(ps.magic) or 0, 0, MAX_MAGIC))
    end
    return true
end

net.Receive("LOD_MapMagicState", function(_, ply)
    if not IsValid(ply) then return end
    local open = net.ReadBool()
    if open then
        beginOrRefresh(ply)
    else
        stopDrain(ply)
    end
end)

timer.Create(TIMER_NAME, TICK_SECONDS, 0, function()
    local Magic = magicAuthority()
    local now = CurTime()

    for ply, state in pairs(MapMagic.Active) do
        if not IsValid(ply) then
            MapMagic.Active[ply] = nil
        elseif not canDrain(ply) then
            stopDrain(ply, "")
        elseif now - (state.lastHeartbeat or 0) > HEARTBEAT_TIMEOUT then
            -- A closed/crashed client must never leave a hidden drain running.
            stopDrain(ply)
        elseif not Magic or not Magic._EnsureState or not Magic._Sync then
            stopDrain(ply, "MAP MAGIC UNAVAILABLE")
        else
            local ps = Magic:_EnsureState(ply)
            if not ps then
                stopDrain(ply, "")
            else
                local dt = math.Clamp(now - (state.lastTick or now), 0, 0.35)
                state.lastTick = now

                -- Keep a private monotonic map budget so the ordinary Magic regen
                -- timer cannot refill underneath an open map. Any other legitimate
                -- Magic expenditure is also respected immediately.
                state.mapMagic = math.min(state.mapMagic or MAX_MAGIC,
                    math.Clamp(tonumber(ps.magic) or 0, 0, MAX_MAGIC))
                local before = state.mapMagic
                state.mapMagic = math.max(0, state.mapMagic - DRAIN_RATE * dt)
                ps.magic = state.mapMagic
                Magic:_Sync(ply, ps)

                MapMagic.Stats.drained = (MapMagic.Stats.drained or 0)
                    + math.max(0, before - state.mapMagic)

                if state.mapMagic <= 0.001 then
                    ps.magic = 0
                    Magic:_Sync(ply, ps)
                    stopDrain(ply, "MAP CLOSED — MAGIC DEPLETED")
                end
            end
        end
    end
end)

hook.Add("PlayerDeath", "LOD_MinimapMagicDeathStop", function(ply)
    stopDrain(ply)
end)

hook.Add("PlayerDisconnected", "LOD_MinimapMagicDisconnectStop", function(ply)
    MapMagic.Active[ply] = nil
end)

concommand.Add("lod_minimap_magic_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local active = 0
    for _ in pairs(MapMagic.Active) do active = active + 1 end
    local line = string.format(
        "active=%d opens=%d drained=%.1f forcedCloses=%d fullDrain=%.1fs rate=%.2f/s",
        active,
        MapMagic.Stats.opens or 0,
        MapMagic.Stats.drained or 0,
        MapMagic.Stats.forcedCloses or 0,
        FULL_DRAIN_SECONDS,
        DRAIN_RATE)
    print("[LOD:MAP-MAGIC] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
