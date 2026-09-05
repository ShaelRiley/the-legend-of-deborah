if CLIENT then return end

LOD = LOD or {}
LOD.RPGTestObservability = LOD.RPGTestObservability or {}
local Obs = LOD.RPGTestObservability

local function safe(value)
    if value == nil then return "" end
    local text = tostring(value)
    text = string.gsub(text, "[\r\n\t]", " ")
    return text
end

local function install()
    local Summary = LOD.RPGTestSessionSummary
    if not Summary or not isfunction(Summary.Render) then return false end
    if Obs.RateOfFireSummaryWrapped then return true end

    Obs.RateOfFireSummaryWrapped = true
    local baseRender = Summary.Render
    function Summary:Render()
        local text = baseRender(self)
        local Effects = LOD.RPG and LOD.RPG.FeatEffectSystem
        local stats = Effects and Effects.AttackRateStats or {}
        local last = stats.lastScale or Obs.LastRateOfFireScale or {}
        local miss = stats.lastDeadlineMiss or Obs.LastRateOfFireDeadlineMiss or {}
        local scaleCount = math.max(tonumber(stats.attackIntervalsScaled) or 0,
            tonumber(Obs.RateOfFireScaleEvents) or 0)
        local missCount = math.max(tonumber(stats.deadlineConfirmationTimeouts) or 0,
            tonumber(Obs.RateOfFireDeadlineMisses) or 0)

        Obs.RateOfFireScaleEvents = scaleCount
        Obs.RateOfFireDeadlineMisses = missCount
        if next(last) ~= nil then Obs.LastRateOfFireScale = last end
        if next(miss) ~= nil then Obs.LastRateOfFireDeadlineMiss = miss end

        local extra = table.concat({
            "[RATE_OF_FIRE_OBSERVABILITY]",
            "rate_of_fire_scale_events=" .. safe(scaleCount),
            "rate_of_fire_confirmed_attacks=" .. safe(stats.confirmedAttacks or 0),
            "rate_of_fire_deadline_misses=" .. safe(missCount),
            "last_rate_of_fire_weapon=" .. safe(last.weaponClass),
            "last_rate_of_fire_channel=" .. safe(last.channel),
            "last_rate_of_fire_multiplier=" .. safe(last.multiplier),
            "last_rate_of_fire_authored_seconds=" .. safe(last.authoredSeconds),
            "last_rate_of_fire_scaled_seconds=" .. safe(last.scaledSeconds),
            "last_rate_of_fire_saved_seconds=" .. safe(last.savedSeconds),
            "last_rate_of_fire_confirmation=" .. safe(last.confirmation),
            "last_rate_of_fire_miss_weapon=" .. safe(miss.weaponClass),
            "last_rate_of_fire_miss_confirmation=" .. safe(miss.confirmation),
            ""
        }, "\n")
        return text .. "\n" .. extra
    end
    return true
end

local function tryInstall()
    if install() then
        timer.Remove("LOD_RPGTestRateOfFireObservabilityInstall")
    end
end

timer.Create("LOD_RPGTestRateOfFireObservabilityInstall", 0.10, 0, tryInstall)
timer.Simple(0, tryInstall)
hook.Add("InitPostEntity", "LOD_RPGTestRateOfFireObservabilityInstall", function()
    timer.Simple(0, tryInstall)
end)
