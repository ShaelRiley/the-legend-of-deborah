LOD = LOD or {}
LOD.RPG = LOD.RPG or {}

local RPG = LOD.RPG
local Catalog = RPG.IdentityCatalog
local Feats = Catalog and (Catalog.OrdinaryFeats or Catalog.LevelOneOrdinaryFeats)
local Effects = RPG.FeatEffectSystem
local Rules = LOD.RPGAbilityRules
local Progression = LOD.CharacterProgressionSystem
local Validation = LOD.RPGValidation
if not Feats or not Effects or not Rules or not Progression then return end

local SOURCE_REVISION = "ANLCKQmcBBEnzsnYbFvdzzXmHJB2gAgkhunV5P2pczqttiFNGF1lfRGWUVzYRmO9v_2DdQF2Dpg8w6Ms2v9KI5U5b6HhpuEYa3gnaXvXDA"
local TEST_IDS = {
    CON_STEADFAST = true,
    WIS_FORCEFUL_MAGIC = true,
    INT_MANA_SPRING = true
}

local function owns(state, id)
    for _, value in ipairs(state and state.featIds or {}) do
        if value == id then return true end
    end
    return false
end

local function singleton(id, name, ability, requirement, capability, family, handler,
    actorText, description)
    return {
        featId = id,
        displayName = name,
        featFamilyId = family,
        rankIndex = 1,
        replacesLowerRank = false,
        repeatableFallback = false,
        governingAbilities = {ability},
        abilityRequirements = {[ability] = requirement},
        prerequisiteFeatIds = {},
        requiredCapabilityTags = capability and {capability} or {},
        incompatibleFeatIds = {},
        allowedActorTypes = {"hero", "human_soldier", "ai"},
        requiredSubsystemTags = {},
        synergyTags = {family},
        oneRank = true,
        effectHandlerId = handler,
        effectParams = {description = description},
        directorBaseWeight = 1.0,
        eligibilityText = string.format("%s %d%s", string.upper(ability), requirement,
            capability and (" / " .. capability) or ""),
        actorText = actorText
    }
end

Feats.CON_STEADFAST = singleton(
    "CON_STEADFAST", "Hard to Move", "con", 13, nil,
    "con_steadfast", "steadfast_control_resistance",
    "Heroes, human Soldiers, and AI",
    "Incoming ordinary hit-stun duration and non-scripted push displacement are each multiplied by 0.75. Authored boss mechanics that explicitly ignore resistance remain exceptions.")

Feats.WIS_FORCEFUL_MAGIC = singleton(
    "WIS_FORCEFUL_MAGIC", "Force Multiplier", "wis", 15, "magic_push",
    "wis_forceful_magic", "forceful_magic_push",
    "Heroes, human Soldiers, and AI with a Magic push",
    "Actor-authored magic_push displacement is multiplied by 1.25. Force Shout is the initial intended beneficiary. Physical-push feats do not automatically stack unless a cross-system bridge makes the event eligible for both families.")

Feats.INT_MANA_SPRING = singleton(
    "INT_MANA_SPRING", "Mana Spring", "int", 13, "magic_pool",
    "int_mana_spring", "mana_spring_regeneration",
    "Heroes, human Soldiers, and Magic-using AI",
    "Whenever Magic reaches 0, the next time regeneration becomes legally permitted the actor receives a 1.50 multiplier to its already INT-scaled Magic regeneration for 4.0 seconds. The timer does not run and no regeneration occurs while the minimap or another regeneration-suppressing sustained effect remains active.")

Catalog.OrdinaryFeats = Feats
Catalog.GateEControlMagicSourceRevisionId = SOURCE_REVISION

Effects.ControlMagicConfig = {
    sourceRevision = SOURCE_REVISION,
    steadfastMultiplier = 0.75,
    forcefulMagicMultiplier = 1.25,
    manaSpringMultiplier = 1.50,
    manaSpringDurationSeconds = 4.0
}
Effects.ControlMagicStats = Effects.ControlMagicStats or {
    hitStunQueries = 0,
    lastHitStunBase = 1,
    lastHitStunResistance = 1,
    lastHitStunFinal = 1,
    manaSpringStarts = 0,
    manaSpringActiveTicks = 0,
    manaSpringPausedTicks = 0,
    lastManaSpringMultiplier = 1
}

function Effects:ControlMagicProfile(state)
    local steadfast = owns(state, "CON_STEADFAST")
    local forceful = owns(state, "WIS_FORCEFUL_MAGIC")
    local spring = owns(state, "INT_MANA_SPRING")
    return {
        steadfast = steadfast,
        steadfastHitStunMultiplier = steadfast and 0.75 or 1,
        steadfastPushMultiplier = steadfast and 0.75 or 1,
        forcefulMagic = forceful,
        magicPushMultiplier = forceful and 1.25 or 1,
        manaSpring = spring,
        manaSpringRegenMultiplier = spring and 1.50 or 1,
        manaSpringDurationSeconds = spring and 4.0 or 0
    }
end

-- Pure state transition used by the authoritative Magic timer and the finite
-- validator. Remaining time advances only on legally permitted regeneration
-- ticks; reaching zero arms (or re-arms) the next four-second window.
function Effects:ResolveManaSpringTick(enabled, currentMagic, waiting, remaining,
    regenerationPermitted, elapsed)
    if enabled ~= true then return 1, false, 0, false, false end

    waiting = waiting == true
    remaining = math.max(0, tonumber(remaining) or 0)
    elapsed = math.max(0, tonumber(elapsed) or 0)
    if (tonumber(currentMagic) or 0) <= 0 then waiting = true end

    local started = false
    if regenerationPermitted == true and waiting then
        waiting = false
        remaining = 4.0
        started = true
    end

    local active = regenerationPermitted == true and remaining > 0
    local multiplier = active and 1.50 or 1
    if active then remaining = math.max(0, remaining - elapsed) end
    return multiplier, waiting, remaining, started, active
end

function Effects:ResolvePushDistance(authoredDistance, attackerDerived, defenderDerived, opts)
    opts = opts or {}
    local authored = math.max(0, tonumber(authoredDistance) or 0)
    local outgoing = math.max(0, tonumber(attackerDerived
        and attackerDerived.fighterCapstoneOutgoingPushMultiplier) or 1)
    local magic = opts.magicPush == true and math.max(0,
        tonumber(attackerDerived and attackerDerived.magicPushMultiplier) or 1) or 1
    local incoming, steadfast = 1, 1
    if opts.ignoreResistance ~= true then
        incoming = math.max(0, tonumber(defenderDerived
            and defenderDerived.fighterCapstoneIncomingPushMultiplier) or 1)
        steadfast = math.max(0, tonumber(defenderDerived
            and defenderDerived.steadfastPushMultiplier) or 1)
    end
    return authored * outgoing * magic * incoming * steadfast, {
        authored = authored,
        outgoingMultiplier = outgoing,
        magicPushMultiplier = magic,
        incomingMultiplier = incoming,
        steadfastMultiplier = steadfast
    }
end

if not Effects.LODGateEControlMagicApplyDerivedWrapped then
    Effects.LODGateEControlMagicApplyDerivedWrapped = true
    local base = Effects.ApplyDerived
    function Effects:ApplyDerived(state, derived)
        base(self, state, derived)
        local profile = self:ControlMagicProfile(state)
        derived.steadfastEnabled = profile.steadfast
        derived.steadfastHitStunMultiplier = profile.steadfastHitStunMultiplier
        derived.steadfastPushMultiplier = profile.steadfastPushMultiplier
        derived.forcefulMagicEnabled = profile.forcefulMagic
        derived.magicPushMultiplier = profile.magicPushMultiplier
        derived.manaSpringEnabled = profile.manaSpring
        derived.manaSpringRegenMultiplier = profile.manaSpringRegenMultiplier
        derived.manaSpringDurationSeconds = profile.manaSpringDurationSeconds
    end
end

if not Rules.LODGateEControlMagicHitStunWrapped then
    Rules.LODGateEControlMagicHitStunWrapped = true
    local base = Rules.HitStunMultiplier
    function Rules:HitStunMultiplier(attacker, defender, opts)
        local ordinary = base(self, attacker, defender, opts)
        local defend = self:Derived(defender)
        local resistance = opts and opts.ignoreResistance == true and 1 or math.max(0,
            tonumber(defend and defend.steadfastHitStunMultiplier) or 1)
        local final = ordinary * resistance
        local stats = Effects.ControlMagicStats
        stats.hitStunQueries = (stats.hitStunQueries or 0) + 1
        stats.lastHitStunBase = ordinary
        stats.lastHitStunResistance = resistance
        stats.lastHitStunFinal = final
        return final
    end
end

local function addSchemaField(name)
    local fields = RPG.Schema and RPG.Schema.DerivedStats
    if not fields then return end
    for _, existing in ipairs(fields) do
        if existing == name then return end
    end
    fields[#fields + 1] = name
end

for _, field in ipairs({
    "steadfastEnabled", "steadfastHitStunMultiplier", "steadfastPushMultiplier",
    "forcefulMagicEnabled", "magicPushMultiplier", "manaSpringEnabled",
    "manaSpringRegenMultiplier", "manaSpringDurationSeconds"
}) do
    addSchemaField(field)
end

if not Progression.LODGateEControlMagicSnapshotWrapped then
    Progression.LODGateEControlMagicSnapshotWrapped = true
    local base = Progression.BuildClientSnapshot
    function Progression:BuildClientSnapshot(ply)
        local snapshot = base(self, ply)
        if not snapshot then return nil end
        local state = Rules:ProgressionState(ply)
        local derived = state and state.derivedStats or {}
        snapshot.steadfastEnabled = derived.steadfastEnabled == true
        snapshot.steadfastHitStunMultiplier = derived.steadfastHitStunMultiplier or 1
        snapshot.steadfastPushMultiplier = derived.steadfastPushMultiplier or 1
        snapshot.forcefulMagicEnabled = derived.forcefulMagicEnabled == true
        snapshot.magicPushMultiplier = derived.magicPushMultiplier or 1
        snapshot.manaSpringEnabled = derived.manaSpringEnabled == true
        snapshot.manaSpringRegenMultiplier = derived.manaSpringRegenMultiplier or 1
        snapshot.manaSpringDurationSeconds = derived.manaSpringDurationSeconds or 0
        return snapshot
    end
end

function Effects:ValidateControlMagicFamilies()
    local errors = {}
    local function expect(ok, message)
        if not ok then errors[#errors + 1] = message end
    end
    local expected = {
        CON_STEADFAST = {"con", 13, nil, "steadfast_control_resistance"},
        WIS_FORCEFUL_MAGIC = {"wis", 15, "magic_push", "forceful_magic_push"},
        INT_MANA_SPRING = {"int", 13, "magic_pool", "mana_spring_regeneration"}
    }
    for id, values in pairs(expected) do
        local feat = Feats[id]
        expect(feat ~= nil, "missing " .. id)
        if feat then
            expect(feat.governingAbilities[1] == values[1], id .. " governing ability")
            expect(feat.abilityRequirements[values[1]] == values[2], id .. " requirement")
            expect((feat.requiredCapabilityTags or {})[1] == values[3], id .. " capability")
            expect(feat.effectHandlerId == values[4], id .. " handler")
        end
    end

    local baseline = self:ControlMagicProfile({featIds = {}})
    local all = self:ControlMagicProfile({featIds = {
        "CON_STEADFAST", "WIS_FORCEFUL_MAGIC", "INT_MANA_SPRING"
    }})
    expect(baseline.steadfastPushMultiplier == 1
        and all.steadfastPushMultiplier == 0.75, "Hard to Move push multiplier")
    expect(baseline.steadfastHitStunMultiplier == 1
        and all.steadfastHitStunMultiplier == 0.75, "Hard to Move hit-stun multiplier")
    expect(baseline.magicPushMultiplier == 1 and all.magicPushMultiplier == 1.25,
        "Force Multiplier magic_push multiplier")

    local baselinePush, baselineParts = self:ResolvePushDistance(336, {}, {}, {magicPush = true})
    local featPush, featParts = self:ResolvePushDistance(336,
        {magicPushMultiplier = 1.25}, {steadfastPushMultiplier = 0.75},
        {magicPush = true})
    local bypassPush = self:ResolvePushDistance(336,
        {magicPushMultiplier = 1.25}, {steadfastPushMultiplier = 0.75},
        {magicPush = true, ignoreResistance = true})
    local physicalPush = self:ResolvePushDistance(336,
        {magicPushMultiplier = 1.25}, {}, {})
    expect(baselinePush == 336 and baselineParts.magicPushMultiplier == 1,
        "baseline Force Shout displacement")
    expect(featPush == 315 and featParts.magicPushMultiplier == 1.25
        and featParts.steadfastMultiplier == 0.75,
        "Force Multiplier then Hard to Move displacement")
    expect(bypassPush == 420, "explicit resistance bypass preserves Force Multiplier")
    expect(physicalPush == 336, "physical push does not inherit Force Multiplier")

    local multiplier, waiting, remaining, started, active =
        self:ResolveManaSpringTick(true, 0, false, 0, false, 0.25)
    expect(multiplier == 1 and waiting and remaining == 0 and not started and not active,
        "Mana Spring arms and pauses while regeneration is suppressed")
    multiplier, waiting, remaining, started, active =
        self:ResolveManaSpringTick(true, 0, waiting, remaining, true, 0.25)
    expect(multiplier == 1.50 and not waiting and remaining == 3.75
        and started and active, "Mana Spring begins on first legal regeneration tick")
    multiplier, waiting, remaining, started, active =
        self:ResolveManaSpringTick(true, 1, waiting, remaining, false, 0.25)
    expect(multiplier == 1 and remaining == 3.75 and not active,
        "Mana Spring timer pauses with regeneration")

    return #errors == 0, errors
end

if Validation and not Validation.LODGateEControlMagicWrapped then
    Validation.LODGateEControlMagicWrapped = true
    local base = Validation.Run
    function Validation:Run(printResult)
        local baseOK, errors = base(self, false)
        errors = errors or {}
        local featOK, featErrors = Effects:ValidateControlMagicFamilies()
        for _, message in ipairs(featErrors or {}) do
            errors[#errors + 1] = "Gate E control/Magic: " .. message
        end
        local ok = baseOK and featOK and #errors == 0
        if printResult ~= false then
            if ok then
                print(string.format(
                    "[LOD:RPG] core RPG validation PASS — gate=%s gameplayEnabled=%s gateEControlMagic=true",
                    tostring(RPG.ImplementationGate), tostring(RPG.GameplayEnabled)))
            else
                ErrorNoHalt("[LOD:RPG] core RPG validation FAILED (" .. #errors .. " error(s))\n")
                for _, message in ipairs(errors) do
                    ErrorNoHalt("[LOD:RPG]  - " .. message .. "\n")
                end
            end
        end
        return ok, errors
    end
end

local function developerAllowed(ply)
    local cv = GetConVar("lod_developer_mode")
    return cv and cv:GetBool() and (not IsValid(ply) or ply:IsAdmin())
end

local function configurePlayer(ply, enabled)
    local run = LOD.RunManager
    local ps = run and run.GetPlayerState and run:GetPlayerState(ply) or nil
    local state = ps and ps.progressionState or nil
    if not state then return nil, "RPG progression state is unavailable." end
    local kept = {}
    for _, id in ipairs(state.featIds or {}) do
        if not TEST_IDS[id] then kept[#kept + 1] = id end
    end
    state.featIds = kept
    state.featStackCounts = state.featStackCounts or {}
    for id in pairs(TEST_IDS) do state.featStackCounts[id] = nil end
    if enabled then
        for _, id in ipairs({"CON_STEADFAST", "WIS_FORCEFUL_MAGIC", "INT_MANA_SPRING"}) do
            state.featIds[#state.featIds + 1] = id
            state.featStackCounts[id] = 1
        end
    end
    Progression:_RecomputeProgressionState(state)
    Progression:SyncPlayer(ply)
    ps.magic = 30
    ps.manaSpringWaiting = false
    ps.manaSpringRemainingSeconds = 0
    local magic = LOD.Magic
    if magic and magic._Sync then magic:_Sync(ply, ps) end
    if run.MarkUnranked then run:MarkUnranked("Gate E control/Magic feat test") end
    return ps
end

local function testTarget(ply)
    local best, bestDistance
    for _, hostile in ipairs(LOD.HostileRegistry and LOD.HostileRegistry:List() or {}) do
        if IsValid(hostile) and hostile.LODHostile and not hostile.LODDead
            and hostile:Health() > 0
        then
            local distance = ply:GetPos():DistToSqr(hostile:GetPos())
            if not bestDistance or distance < bestDistance then
                best, bestDistance = hostile, distance
            end
        end
    end
    return best
end

local function configureTarget(target, enabled)
    if not IsValid(target) then return false end
    if target.LODGateEControlMagicOriginalProgressionState == nil then
        target.LODGateEControlMagicOriginalProgressionState = target.LODProgressionState or false
    end
    local state = Progression:NewProgressionState(
        "gate-e-control-target:" .. target:EntIndex(), "hostile", "ai")
    for ability in pairs(state.baseAbilities) do state.baseAbilities[ability] = 10 end
    if enabled then
        state.featIds = {"CON_STEADFAST"}
        state.featStackCounts.CON_STEADFAST = 1
    end
    Progression:_RecomputeProgressionState(state)
    target.LODProgressionState = state
    Effects.ControlMagicTestTarget = target
    return true
end

local function restoreTestTarget()
    local target = Effects.ControlMagicTestTarget
    if IsValid(target) and target.LODGateEControlMagicOriginalProgressionState ~= nil then
        local original = target.LODGateEControlMagicOriginalProgressionState
        target.LODProgressionState = original ~= false and original or nil
        target.LODGateEControlMagicOriginalProgressionState = nil
    end
    Effects.ControlMagicTestTarget = nil
end

local function resetTelemetry(enabled)
    local stats = Effects.ControlMagicStats
    stats.hitStunQueries = 0
    stats.lastHitStunBase = 1
    stats.lastHitStunResistance = 1
    stats.lastHitStunFinal = 1
    stats.manaSpringStarts = 0
    stats.manaSpringActiveTicks = 0
    stats.manaSpringPausedTicks = 0
    stats.lastManaSpringMultiplier = 1
    stats.expectedEnabled = enabled == true
    local push = LOD.Pushback and LOD.Pushback.Stats
    if push then
        push.pushes = 0
        push.lastAuthoredDistance = nil
        push.lastRequestedDistance = nil
        push.lastMagicPushMultiplier = nil
        push.lastSteadfastMultiplier = nil
    end
end

concommand.Add("lod_rpg_gate_e_control_magic_validate", function(ply)
    if not developerAllowed(ply) then return end
    local ok, errors = Effects:ValidateControlMagicFamilies()
    if ok then
        print("[LOD:RPG-E] control/Magic families PASS — Hard to Move hit-stun/push x0.75; Force Multiplier magic_push x1.25; Mana Spring regeneration x1.50 for 4.0 legal seconds")
    else
        ErrorNoHalt("[LOD:RPG-E] control/Magic families FAILED\n")
        for _, message in ipairs(errors or {}) do
            ErrorNoHalt("[LOD:RPG-E]  - " .. message .. "\n")
        end
    end
end)

concommand.Add("lod_rpg_gate_e_control_magic_status", function(ply)
    if not developerAllowed(ply) or not IsValid(ply) then return end
    local run = LOD.RunManager
    local ps = run and run.GetPlayerState and run:GetPlayerState(ply) or nil
    local state = Rules:ProgressionState(ply)
    local profile = Effects:ControlMagicProfile(state)
    local stats = Effects.ControlMagicStats
    local target = Effects.ControlMagicTestTarget
    local targetPush = IsValid(target) and target.LODLastPushback or nil
    local pushStats = LOD.Pushback and LOD.Pushback.Stats or {}
    local push = targetPush or pushStats
    local expectedPush = Effects:ResolvePushDistance(336, Rules:Derived(ply),
        IsValid(target) and Rules:Derived(target) or nil, {magicPush = true})
    local pushOK = (pushStats.pushes or 0) >= 1
        and math.abs((push.requested or push.lastRequestedDistance or 0)
            - expectedPush) < 0.01
        and math.abs((push.magicPushMultiplier or push.lastMagicPushMultiplier or 0)
            - profile.magicPushMultiplier) < 0.001
        and math.abs((push.steadfastMultiplier or push.lastSteadfastMultiplier or 0)
            - (profile.steadfast and 0.75 or 1)) < 0.001
    local stunOK = (stats.hitStunQueries or 0) >= 1
        and math.abs((stats.lastHitStunResistance or 0)
            - (profile.steadfast and 0.75 or 1)) < 0.001
    local springOK = profile.manaSpring and (stats.manaSpringStarts or 0) >= 1
        and (stats.manaSpringActiveTicks or 0) >= 1
        or (not profile.manaSpring and (stats.manaSpringStarts or 0) == 0)
    local acceptance = pushOK and stunOK and springOK
    local line = string.format(
        "steadfast=%s stunQueries=%d stunResist=x%.2f forceful=%s pushAuthored=%.1f pushMagic=x%.2f pushSteadfast=x%.2f pushRequested=%.1f manaSpring=%s starts=%d activeTicks=%d pausedTicks=%d spring=x%.2f remaining=%.2fs magic=%.2f acceptance=%s",
        tostring(profile.steadfast), stats.hitStunQueries or 0,
        stats.lastHitStunResistance or 1, tostring(profile.forcefulMagic),
        push.authored or push.lastAuthoredDistance or 0,
        push.magicPushMultiplier or push.lastMagicPushMultiplier or 1,
        push.steadfastMultiplier or push.lastSteadfastMultiplier or 1,
        push.requested or push.lastRequestedDistance or 0,
        tostring(profile.manaSpring), stats.manaSpringStarts or 0,
        stats.manaSpringActiveTicks or 0, stats.manaSpringPausedTicks or 0,
        stats.lastManaSpringMultiplier or 1,
        tonumber(ps and ps.manaSpringRemainingSeconds) or 0,
        tonumber(ps and ps.magic) or 0, acceptance and "PASS" or "WAITING")
    print("[LOD:RPG-E] " .. line)
    ply:ChatPrint(line)
end)

concommand.Add("lod_rpg_gate_e_control_magic_testkit", function(ply, _, args)
    if not developerAllowed(ply) or not IsValid(ply) or not ply:Alive() then return end
    local enabled = tonumber(args[1]) == 1
    local ps, message = configurePlayer(ply, enabled)
    if not ps then ply:ChatPrint(message) return end
    restoreTestTarget()
    local target = testTarget(ply)
    if not configureTarget(target, enabled) then
        ply:ChatPrint("No living hostile is available. Spawn one, then rerun the testkit.")
        return
    end
    target:SetHealth(math.max(target:Health(), 200))
    resetTelemetry(enabled)
    local expectedPush = Effects:ResolvePushDistance(336, Rules:Derived(ply),
        Rules:Derived(target), {magicPush = true})
    local line = string.format(
        "Control/Magic acceptance kit %s: target is %s #%d. Magic is 30. Aim at that surviving hostile and press RMB once; wait one second, then run control_magic_status. Expected requested push %.0f and Mana Spring %s.",
        enabled and "FEATS" or "BASELINE", target:GetClass(), target:EntIndex(),
        expectedPush, enabled and "x1.50 active" or "off")
    print("[LOD:RPG-E] " .. line)
    ply:ChatPrint(line)
end)

RPG.SystemBootstrap.FeatEffectSystem = "gate_e_batch_11_control_magic"
return Effects
