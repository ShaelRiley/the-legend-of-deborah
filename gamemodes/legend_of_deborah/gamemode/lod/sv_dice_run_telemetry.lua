LOD = LOD or {}
LOD.DiceRunTelemetry = LOD.DiceRunTelemetry or {}

local Telemetry = LOD.DiceRunTelemetry

local STAGE_LABELS = {
    "RED CARD", "RED GATE", "BLUE CARD", "BLUE GATE", "YELLOW CARD",
    "YELLOW GATE", "JAIL KEY", "JAIL DOOR", "DEBORAH"
}

local AMMO_ORDER = {
    "weapon_pistol", "weapon_shotgun", "weapon_smg1", "weapon_ar2", "weapon_357"
}

local function developerAllowed(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return false end
    return not IsValid(ply) or ply:IsAdmin()
end

local function playerKey(ply)
    if not IsValid(ply) then return "unknown" end
    local steamId = ply:SteamID64()
    if steamId and steamId ~= "0" then return steamId end
    return "ent:" .. ply:EntIndex()
end

local function playerName(ply)
    if not IsValid(ply) then return "Unknown" end
    local name = string.Trim(string.gsub(tostring(ply:Nick() or "Player"), "[%c]", ""))
    return string.sub(name ~= "" and name or "Player", 1, 32)
end

local function statSnapshot()
    local stats = LOD.CombatRolls and LOD.CombatRolls.Stats or {}
    return {
        playerAttacks = stats.playerAttacks or 0,
        hostileAttacks = stats.hostileAttacks or 0
    }
end

local function closeStage(run, now)
    if not run or not run.stage or not run.stageStartedAt then return end
    now = now or CurTime()
    run.stageSeconds[run.stage] = (run.stageSeconds[run.stage] or 0)
        + math.max(0, now - run.stageStartedAt)
    run.stageStartedAt = now
end

function Telemetry:BeginLevel(level, seed)
    local now = CurTime()
    local stage = LOD.RunManager and LOD.RunManager.State.ObjectiveStage or 1
    self.Current = {
        level = tonumber(level) or 1,
        seed = tonumber(seed) or 0,
        status = "ACTIVE",
        startedAt = now,
        stage = math.Clamp(tonumber(stage) or 1, 1, #STAGE_LABELS),
        stageStartedAt = now,
        stageSeconds = {},
        deaths = 0,
        damageDealt = 0,
        damageTaken = 0,
        playerHits = 0,
        hostileHits = 0,
        kills = 0,
        killsByArchetype = {},
        ammo = {},
        ammoByStage = {},
        combatStart = statSnapshot()
    }
end

function Telemetry:ObserveStage(now)
    local run = self.Current
    if not run or run.status ~= "ACTIVE" then return end
    local state = LOD.RunManager and LOD.RunManager.State
    local stage = math.Clamp(tonumber(state and state.ObjectiveStage) or 1, 1, #STAGE_LABELS)
    if stage == run.stage then return end
    closeStage(run, now or CurTime())
    run.stage = stage
    run.stageStartedAt = now or CurTime()
end

local function sampleBucket(bucket, ply, total, profile)
    bucket.samples = (bucket.samples or 0) + 1
    if total <= profile.floor then bucket.floorSamples = (bucket.floorSamples or 0) + 1 end
    if bucket.minimum == nil or total < bucket.minimum then
        bucket.minimum = total
        bucket.player = playerName(ply)
    end
end

function Telemetry:SampleAmmo(ply, weaponClass, total, profile, now)
    local run = self.Current
    if not run or run.status ~= "ACTIVE" or not IsValid(ply) or not profile then return end
    self:ObserveStage(now)

    local key = playerKey(ply) .. ":" .. tostring(weaponClass)
    local overall = run.ammo[key]
    if not overall then
        overall = {
            weaponClass = weaponClass,
            label = profile.label or weaponClass,
            cap = profile.cap,
            floor = profile.floor,
            player = playerName(ply)
        }
        run.ammo[key] = overall
    end
    sampleBucket(overall, ply, total, profile)

    local stage = run.stage or 1
    run.ammoByStage[stage] = run.ammoByStage[stage] or {}
    local staged = run.ammoByStage[stage][key]
    if not staged then
        staged = {
            weaponClass = weaponClass,
            label = profile.label or weaponClass,
            cap = profile.cap,
            floor = profile.floor,
            player = playerName(ply)
        }
        run.ammoByStage[stage][key] = staged
    end
    sampleBucket(staged, ply, total, profile)
end

function Telemetry:RecordDamage(target, dmginfo)
    local run = self.Current
    if not run or run.status ~= "ACTIVE" or not IsValid(target) or not dmginfo then return end
    local attacker = dmginfo:GetAttacker()
    local damage = math.max(0, tonumber(dmginfo:GetDamage()) or 0)
    if damage <= 0 then return end

    if target.LODHostile and IsValid(attacker) and attacker:IsPlayer() then
        run.damageDealt = run.damageDealt + math.min(damage, math.max(0, target:Health()))
        run.playerHits = run.playerHits + 1
    elseif target:IsPlayer() and IsValid(attacker) and attacker.LODHostile then
        run.damageTaken = run.damageTaken + math.min(damage, math.max(0, target:Health()))
        run.hostileHits = run.hostileHits + 1
    end
end

function Telemetry:RecordKill(hostile)
    local run = self.Current
    if not run or run.status ~= "ACTIVE" or not IsValid(hostile) or not hostile.LODHostile then return end
    local archetype = tostring(hostile.LODArchetypeId or "unknown")
    run.kills = run.kills + 1
    run.killsByArchetype[archetype] = (run.killsByArchetype[archetype] or 0) + 1
end

function Telemetry:RecordDeath(victim)
    local run = self.Current
    if not run or run.status ~= "ACTIVE" or not IsValid(victim) then return end
    local manager = LOD.RunManager
    -- RunManager's earlier PlayerDeath hook may already have removed a
    -- final-life player from ActiveIdentity. Persistent player state remains
    -- the reliable indication that this death belonged to the expedition.
    if manager and manager.GetPlayerState and manager:GetPlayerState(victim) then
        run.deaths = run.deaths + 1
    end
end

local function attackDelta(run, key)
    local finish = run.combatFinish or statSnapshot()
    return math.max(0, (finish[key] or 0) - ((run.combatStart and run.combatStart[key]) or 0))
end

local function elapsedSeconds(run)
    return math.max(0, (run.finishedAt or CurTime()) - (run.startedAt or CurTime()))
end

local function summaryLine(run)
    return string.format(
        "status=%s level=%d seed=%d time=%.1fs deaths=%d dealt=%.1f taken=%.1f kills=%d playerAttacks=%d hostileAttacks=%d",
        run.status or "UNKNOWN", run.level or 0, run.seed or 0, elapsedSeconds(run),
        run.deaths or 0, run.damageDealt or 0, run.damageTaken or 0, run.kills or 0,
        attackDelta(run, "playerAttacks"), attackDelta(run, "hostileAttacks"))
end

local function stageLine(run)
    local parts = {}
    for stage = 1, #STAGE_LABELS do
        local seconds = run.stageSeconds[stage] or 0
        if run.status == "ACTIVE" and stage == run.stage then
            seconds = seconds + math.max(0, CurTime() - (run.stageStartedAt or CurTime()))
        end
        if seconds > 0 then
            parts[#parts + 1] = string.format("%d:%s=%.1fs", stage, STAGE_LABELS[stage], seconds)
        end
    end
    return #parts > 0 and table.concat(parts, " | ") or "no stage timing yet"
end

local function worstAmmoByClass(run)
    local worst = {}
    for _, bucket in pairs(run.ammo or {}) do
        local current = worst[bucket.weaponClass]
        local ratio = (bucket.minimum or bucket.cap or 1) / math.max(1, bucket.cap or 1)
        local currentRatio = current
            and (current.minimum or current.cap or 1) / math.max(1, current.cap or 1)
            or math.huge
        if not current or ratio < currentRatio then worst[bucket.weaponClass] = bucket end
    end
    return worst
end

local function ammoLine(run)
    local worst = worstAmmoByClass(run)
    local parts = {}
    for _, weaponClass in ipairs(AMMO_ORDER) do
        local bucket = worst[weaponClass]
        if bucket then
            local floorPct = 100 * (bucket.floorSamples or 0) / math.max(1, bucket.samples or 0)
            parts[#parts + 1] = string.format("%s[%s] min=%d/%d floor=%.0f%%",
                bucket.label, bucket.player or "Player", bucket.minimum or 0,
                bucket.cap or 0, floorPct)
        end
    end
    return #parts > 0 and table.concat(parts, " | ") or "no finite-ammo weapon sampled"
end

function Telemetry:Print(run, ply)
    if not run then return false end
    local lines = {summaryLine(run), stageLine(run), ammoLine(run)}
    for index, line in ipairs(lines) do
        local prefix = index == 1 and "[LOD:DICE-RUN] "
            or index == 2 and "[LOD:DICE-RUN-STAGES] " or "[LOD:DICE-RUN-AMMO] "
        print(prefix .. line)
        if IsValid(ply) then ply:ChatPrint(line) end
    end
    return true
end

function Telemetry:Finish(status, actor)
    local run = self.Current
    if not run or run.status ~= "ACTIVE" then return false end
    local now = CurTime()
    self:ObserveStage(now)
    closeStage(run, now)
    run.finishedAt = now
    run.status = status or "COMPLETE"
    run.completedBy = playerName(actor)
    run.combatFinish = statSnapshot()
    self.Last = run
    self.Current = nil
    self:Print(run)
    return true
end

hook.Add("LOD_LevelReady", "LOD_DiceRunTelemetryBegin", function(level, seed)
    Telemetry:BeginLevel(level, seed)
end)

hook.Add("LOD_LevelCleared", "LOD_DiceRunTelemetryComplete", function(ply)
    Telemetry:Finish("COMPLETE", ply)
end)

hook.Add("LOD_CampaignFailed", "LOD_DiceRunTelemetryFailed", function(reason)
    Telemetry:Finish("FAILED:" .. tostring(reason or "unknown"))
end)

hook.Add("EntityTakeDamage", "LOD_DiceRunTelemetryDamage", function(target, dmginfo)
    Telemetry:RecordDamage(target, dmginfo)
end)

hook.Add("OnNPCKilled", "LOD_DiceRunTelemetryKills", function(npc)
    Telemetry:RecordKill(npc)
end)

hook.Add("PlayerDeath", "LOD_DiceRunTelemetryDeaths", function(victim)
    Telemetry:RecordDeath(victim)
end)

concommand.Add("lod_dice_run_status", function(ply)
    if not developerAllowed(ply) then return end
    if not Telemetry:Print(Telemetry.Current, ply) then
        local text = "no active dice-era level telemetry"
        print("[LOD:DICE-RUN] " .. text)
        if IsValid(ply) then ply:ChatPrint(text) end
    end
end)

concommand.Add("lod_dice_run_last", function(ply)
    if not developerAllowed(ply) then return end
    if not Telemetry:Print(Telemetry.Last, ply) then
        local text = "no completed dice-era level telemetry"
        print("[LOD:DICE-RUN] " .. text)
        if IsValid(ply) then ply:ChatPrint(text) end
    end
end)
