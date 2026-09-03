LOD = LOD or {}
local RPG = LOD.RPG
local Effects = RPG and RPG.FeatEffectSystem
if not Effects or not isfunction(Effects.ProcessReloadObservation) then return end
if Effects.LODReloadTelemetryWrapped then return Effects end

Effects.LODReloadTelemetryWrapped = true
local baseProcessReloadObservation = Effects.ProcessReloadObservation

local function emitReloadScale(beforeCount, afterCount)
    if afterCount <= beforeCount then return end

    local stats = Effects.ReloadStats or {}
    local last = stats.lastScale or {}
    local fields = {
        count = afterCount,
        delta = afterCount - beforeCount,
        weaponClass = last.weaponClass,
        channel = last.channel,
        multiplier = last.multiplier,
        authoredSeconds = last.authoredSeconds,
        scaledSeconds = last.scaledSeconds,
        savedSeconds = math.max(0, (tonumber(last.authoredSeconds) or 0) - (tonumber(last.scaledSeconds) or 0))
    }

    local Log = LOD.RPGTestLog
    if Log and isfunction(Log.Write) then
        Log:Write("RELOAD_SCALE", fields)
    end

    -- Keep the compact summary in sync immediately and tell the older fallback
    -- observer that this count is already recorded, preventing duplicate events.
    local Obs = LOD.RPGTestObservability
    if Obs then
        Obs.ReloadScaleEvents = math.max(tonumber(Obs.ReloadScaleEvents) or 0, afterCount)
        Obs.LastReloadScale = fields
        Obs.LastReloadScaleCount = math.max(tonumber(Obs.LastReloadScaleCount) or 0, afterCount)
    end
end

function Effects:ProcessReloadObservation(ply, session, now)
    local beforeCount = tonumber(self.ReloadStats and self.ReloadStats.reloadExtensionsScaled) or 0
    local result = baseProcessReloadObservation(self, ply, session, now)
    local afterCount = tonumber(self.ReloadStats and self.ReloadStats.reloadExtensionsScaled) or 0
    emitReloadScale(beforeCount, afterCount)
    return result
end

return Effects
