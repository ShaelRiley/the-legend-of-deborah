LOD = LOD or {}
LOD.RPG = LOD.RPG or {}

local RPG = LOD.RPG
local Catalog = RPG.IdentityCatalog
local Feats = Catalog and (Catalog.OrdinaryFeats or Catalog.LevelOneOrdinaryFeats)
local Effects = RPG.FeatEffectSystem
local Progression = LOD.CharacterProgressionSystem
local Rules = LOD.RPGAbilityRules
local Validation = LOD.RPGValidation
if not Feats or not Effects or not Progression or not Rules then return end

local FEAT_ID = "CON_BLAST_PROOF"
local FAMILY = "con_blast_proof"
local COOLDOWN_SECONDS = 2.0
local SOURCE_REVISION = "ANLCKQnyvpsTp5jD3d0uuW_i_5JCMIKNR3cuBLTYuaz36uztotE0HseqhKVqnGCyzEewiIyAH6EjQCzrgATFmGFx8MppAcLXQcnxwiun9w"

Feats[FEAT_ID] = {
    featId = FEAT_ID,
    displayName = "Blast-Proof",
    featFamilyId = FAMILY,
    rankIndex = 1,
    replacesLowerRank = false,
    repeatableFallback = false,
    governingAbilities = {"con"},
    abilityRequirements = {con = 15},
    prerequisiteFeatIds = {},
    requiredCapabilityTags = {},
    incompatibleFeatIds = {},
    allowedActorTypes = {"hero", "human_soldier", "ai"},
    requiredSubsystemTags = {},
    synergyTags = {"damage_dice", "exploding_dice"},
    oneRank = true,
    effectHandlerId = FAMILY,
    effectParams = {
        cooldownSeconds = COOLDOWN_SECONDS,
        description = "Once every 2.0 seconds per defender, suppresses the first qualifying continuation created by an incoming actor-owned exploding damage die. The triggering die and all already-resolved damage remain; only that continuation is omitted."
    },
    directorBaseWeight = 1.0,
    eligibilityText = "CON 15",
    actorText = "Heroes, human Soldiers, AI"
}
Catalog.OrdinaryFeats = Feats
Catalog.GateEBlastProofSourceRevisionId = SOURCE_REVISION

local function owns(state, featId)
    for _, ownedId in ipairs(state and state.featIds or {}) do
        if ownedId == featId then return true end
    end
    return false
end

local function contains(values, wanted)
    for _, value in ipairs(values or {}) do if value == wanted then return true end end
    return false
end

function Effects:BlastProofProfile(state)
    return {
        enabled = owns(state, FEAT_ID),
        cooldownSeconds = COOLDOWN_SECONDS
    }
end

-- Pure decision seam used by both runtime and finite validation.  The continuation
-- flag means explosion qualification has already succeeded and the engine is at
-- canonical combat-resolution stage 3: whether to create the next damage die.
function Effects:BlastProofDecision(state, readyAt, now, context)
    context = context or {}
    readyAt = tonumber(readyAt) or 0
    now = tonumber(now) or 0
    if not owns(state, FEAT_ID)
        or context.incoming ~= true
        or context.damageDie ~= true
        or context.continuation ~= true
    then
        return false, readyAt
    end
    if now < readyAt then return false, readyAt end
    return true, now + COOLDOWN_SECONDS
end

Effects.BlastProofStats = Effects.BlastProofStats or {
    suppressions = 0,
    lastSides = 0,
    lastChainDepth = 0,
    lastDefender = ""
}

function Effects:TryBlastProofContinuation(defender, attacker, context)
    if not IsValid(defender) or not IsValid(attacker)
        or defender == attacker or attacker == game.GetWorld()
    then
        return false
    end
    local state = Rules:ProgressionState(defender)
    local now = CurTime()
    local suppress, nextReady = self:BlastProofDecision(
        state, defender.LODRPGBlastProofReadyAt, now, context)
    if not suppress then return false end

    defender.LODRPGBlastProofReadyAt = nextReady
    defender.LODRPGLastBlastProofAt = now
    local stats = self.BlastProofStats
    stats.suppressions = (stats.suppressions or 0) + 1
    stats.lastSides = math.floor(tonumber(context and context.sides) or 0)
    stats.lastChainDepth = math.floor(tonumber(context and context.chainDepth) or 0)
    stats.lastDefender = defender:IsPlayer() and defender:Nick() or defender:GetClass()

    local rolls = LOD.CombatRolls
    if defender:IsPlayer() and rolls and rolls._Send then
        rolls:_Send(defender, 3, "BLAST-PROOF — explosion continuation suppressed")
    end
    print(string.format(
        "[LOD:RPG] BLAST-PROOF suppressed continuation defender=%s sides=d%d chainDepth=%d readyIn=%.1fs",
        tostring(stats.lastDefender), stats.lastSides, stats.lastChainDepth, COOLDOWN_SECONDS))
    return true
end

if not Effects.LODBlastProofApplyDerivedWrapped then
    Effects.LODBlastProofApplyDerivedWrapped = true
    local baseApplyDerived = Effects.ApplyDerived
    function Effects:ApplyDerived(state, derived)
        baseApplyDerived(self, state, derived)
        derived.blastProofEnabled = owns(state, FEAT_ID)
        derived.blastProofCooldownSeconds = COOLDOWN_SECONDS
    end
end

if RPG.Schema and RPG.Schema.DerivedStats then
    if not contains(RPG.Schema.DerivedStats, "blastProofEnabled") then
        RPG.Schema.DerivedStats[#RPG.Schema.DerivedStats + 1] = "blastProofEnabled"
    end
    if not contains(RPG.Schema.DerivedStats, "blastProofCooldownSeconds") then
        RPG.Schema.DerivedStats[#RPG.Schema.DerivedStats + 1] = "blastProofCooldownSeconds"
    end
end

local function installBlastProofRuntime()
    local Rolls = LOD.CombatRolls
    local damageHooks = hook.GetTable() and hook.GetTable().EntityTakeDamage
    local baseDamageAuthority = damageHooks and damageHooks.LOD_DiceDamageAuthority
    if not Rolls or not Rolls._RollExploding or not Rolls.RollActorDamage or not baseDamageAuthority then
        return false
    end
    if Rolls.LODBlastProofContinuationInstalled then return true end

    local baseActorDamage = Rolls.RollActorDamage
    local baseRollExploding = Rolls._RollExploding

    function Rolls:RollActorDamage(attacker, profile, rng, bonusDice)
        local previous = self.LODBlastProofActorDamageActive
        self.LODBlastProofActorDamageActive = true
        local result
        local ok, err = xpcall(function()
            result = baseActorDamage(self, attacker, profile, rng, bonusDice)
        end, debug.traceback)
        self.LODBlastProofActorDamageActive = previous
        if not ok then error(err, 0) end
        return result
    end

    function Rolls:_RollExploding(profile, rng)
        if self.LODBlastProofActorDamageActive ~= true
            or not IsValid(self.LODBlastProofTarget)
            or not IsValid(self.LODBlastProofAttacker)
        then
            return baseRollExploding(self, profile, rng)
        end

        local drawCount = 0
        local proxy = {}
        function proxy:Int(minimum, maximum)
            drawCount = drawCount + 1
            if drawCount > 1 and Effects:TryBlastProofContinuation(
                Rolls.LODBlastProofTarget,
                Rolls.LODBlastProofAttacker,
                {
                    incoming = true,
                    damageDie = true,
                    continuation = true,
                    sides = tonumber(profile and profile.sides) or 0,
                    chainDepth = drawCount - 1
                })
            then
                return nil
            end
            return rng:Int(minimum, maximum)
        end
        return baseRollExploding(self, profile, proxy)
    end

    hook.Remove("EntityTakeDamage", "LOD_DiceDamageAuthority")
    hook.Add("EntityTakeDamage", "LOD_DiceDamageAuthority", function(target, dmginfo)
        local previousTarget = Rolls.LODBlastProofTarget
        local previousAttacker = Rolls.LODBlastProofAttacker
        Rolls.LODBlastProofTarget = target
        Rolls.LODBlastProofAttacker = dmginfo and dmginfo:GetAttacker() or nil
        local result
        local ok, err = xpcall(function()
            result = baseDamageAuthority(target, dmginfo)
        end, debug.traceback)
        Rolls.LODBlastProofTarget = previousTarget
        Rolls.LODBlastProofAttacker = previousAttacker
        if not ok then error(err, 0) end
        return result
    end)

    Rolls.LODBlastProofContinuationInstalled = true
    print("[LOD:RPG] Gate E Batch 15 Blast-Proof runtime installed")
    return true
end

-- This module is loaded from shared.lua before init.lua installs combat rolls and
-- the d12 Boomchain wrapper.  Install on the first server tick so we wrap the final
-- canonical _RollExploding implementation, including universal SUPER-d12 behavior.
timer.Simple(0, function()
    if installBlastProofRuntime() then return end
    timer.Simple(0.25, function()
        if not installBlastProofRuntime() then
            ErrorNoHalt("[LOD:RPG] Gate E Batch 15 Blast-Proof runtime installation FAILED\n")
        end
    end)
end)

function Effects:ValidateBlastProof()
    local errors = {}
    local function expect(ok, message) if not ok then errors[#errors + 1] = message end end
    local feat = Feats[FEAT_ID]
    expect(feat ~= nil, "missing CON_BLAST_PROOF definition")
    if feat then
        expect(feat.featFamilyId == FAMILY, "feat family")
        expect((feat.governingAbilities or {})[1] == "con", "governing ability")
        expect(feat.abilityRequirements and feat.abilityRequirements.con == 15, "CON 15 prerequisite")
        expect(#(feat.prerequisiteFeatIds or {}) == 0, "no feat prerequisite")
        expect(contains(feat.allowedActorTypes, "hero"), "Hero actor scope")
        expect(contains(feat.allowedActorTypes, "human_soldier"), "human Soldier actor scope")
        expect(contains(feat.allowedActorTypes, "ai"), "AI actor scope")
        expect(feat.effectParams and feat.effectParams.cooldownSeconds == 2.0, "2.0-second cooldown")
    end

    local state = {featIds = {FEAT_ID}}
    local suppress, readyAt = self:BlastProofDecision(state, 0, 10, {
        incoming = true, damageDie = true, continuation = true, chainDepth = 1})
    expect(suppress and readyAt == 12, "ready continuation suppression")
    local again, unchanged = self:BlastProofDecision(state, readyAt, 11.999, {
        incoming = true, damageDie = true, continuation = true, chainDepth = 1})
    expect(not again and unchanged == readyAt, "cooldown blocks later explosion")
    local recharged = self:BlastProofDecision(state, readyAt, 12, {
        incoming = true, damageDie = true, continuation = true, chainDepth = 1})
    expect(recharged == true, "automatic recharge at 2.0 seconds")
    local midChain = self:BlastProofDecision(state, 0, 20, {
        incoming = true, damageDie = true, continuation = true, chainDepth = 2})
    expect(midChain == true, "later continuation may be suppressed")
    local outgoing = self:BlastProofDecision(state, 0, 20, {
        incoming = false, damageDie = true, continuation = true})
    expect(outgoing == false, "outgoing damage excluded")
    local utility = self:BlastProofDecision(state, 0, 20, {
        incoming = true, damageDie = false, continuation = true})
    expect(utility == false, "count/utility rolls excluded")
    local ordinary = self:BlastProofDecision(state, 0, 20, {
        incoming = true, damageDie = true, continuation = false})
    expect(ordinary == false, "non-exploding rolls excluded")
    local noFeat = self:BlastProofDecision({featIds = {}}, 0, 20, {
        incoming = true, damageDie = true, continuation = true})
    expect(noFeat == false, "actor without feat excluded")

    return #errors == 0, errors
end

if Validation and not Validation.LODBlastProofWrapped then
    Validation.LODBlastProofWrapped = true
    local baseValidation = Validation.Run
    function Validation:Run(printResult)
        local baseOK, errors = baseValidation(self, false)
        errors = errors or {}
        local featOK, featErrors = Effects:ValidateBlastProof()
        for _, message in ipairs(featErrors or {}) do
            errors[#errors + 1] = "Gate E Blast-Proof: " .. message
        end
        local ok = baseOK and featOK and #errors == 0
        if printResult ~= false then
            if ok then
                print("[LOD:RPG] core RPG validation PASS — gateEBlastProof=true")
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

concommand.Add("lod_rpg_gate_e_blast_proof_validate", function(ply)
    if not developerAllowed(ply) then return end
    local ok, errors = Effects:ValidateBlastProof()
    local Rolls = LOD.CombatRolls
    if not Rolls or Rolls.LODBlastProofContinuationInstalled ~= true then
        ok = false
        errors[#errors + 1] = "runtime continuation interceptor unavailable"
    end
    if ok then
        print("[LOD:RPG-E:B15] Blast-Proof validator PASS — CON15, incoming-only continuation suppression, 2.0s recharge")
    else
        ErrorNoHalt("[LOD:RPG-E:B15] Blast-Proof validator FAILED\n")
        for _, message in ipairs(errors or {}) do
            ErrorNoHalt("[LOD:RPG-E:B15]  - " .. message .. "\n")
        end
    end
end)

local function scriptedRNG(values, onDraw)
    return {
        index = 0,
        Int = function(self, minimum, maximum)
            self.index = self.index + 1
            if onDraw then onDraw(self.index) end
            local value = tonumber(values and values[self.index]) or minimum
            return math.Clamp(math.floor(value), minimum, maximum)
        end
    }
end

local function removeInjectedFeat(state)
    for index = #(state and state.featIds or {}), 1, -1 do
        if state.featIds[index] == FEAT_ID then
            table.remove(state.featIds, index)
            return
        end
    end
end

concommand.Add("lod_rpg_test_blast_proof", function(ply)
    if not developerAllowed(ply) or not IsValid(ply) or not ply:IsPlayer() then return end
    local Rolls = LOD.CombatRolls
    local run = LOD.RunManager
    local ps = run and run.GetPlayerState and run:GetPlayerState(ply) or nil
    local state = ps and ps.progressionState or nil
    if not Rolls or Rolls.LODBlastProofContinuationInstalled ~= true or not state then
        ply:ChatPrint("Blast-Proof testkit unavailable: runtime or progression state missing.")
        return
    end

    local attacker = ents.Create("base_anim")
    if not IsValid(attacker) then
        ply:ChatPrint("Blast-Proof testkit could not create a temporary actor.")
        return
    end
    attacker:SetNoDraw(true)
    attacker:Spawn()

    local alreadyOwned = owns(state, FEAT_ID)
    if not alreadyOwned then state.featIds[#state.featIds + 1] = FEAT_ID end
    local originalReadyAt = ply.LODRPGBlastProofReadyAt
    local originalTarget = Rolls.LODBlastProofTarget
    local originalAttacker = Rolls.LODBlastProofAttacker
    local failures = {}
    local initialSuppressions = Effects.BlastProofStats.suppressions or 0

    local function expect(ok, message)
        if not ok then failures[#failures + 1] = message end
    end
    local function setContext(source)
        Rolls.LODBlastProofTarget = ply
        Rolls.LODBlastProofAttacker = source
    end
    local function incoming(values, source, onDraw)
        setContext(source or attacker)
        return Rolls:RollActorDamage(source or attacker,
            {count = 1, sides = 6, exploding = 6}, scriptedRNG(values, onDraw), 0)
    end
    local function cleanup()
        Rolls.LODBlastProofTarget = originalTarget
        Rolls.LODBlastProofAttacker = originalAttacker
        ply.LODRPGBlastProofReadyAt = originalReadyAt
        if not alreadyOwned then removeInjectedFeat(state) end
        if IsValid(attacker) then attacker:Remove() end
    end

    -- Mid-chain: begin spent so the first continuation is permitted.  The test RNG
    -- re-arms the defense while returning that first continuation's exploding 6;
    -- the next continuation request must then be the one suppressed.
    ply.LODRPGBlastProofReadyAt = CurTime() + 100
    local mid = incoming({6, 6, 1}, attacker, function(drawIndex)
        if drawIndex == 2 then ply.LODRPGBlastProofReadyAt = CurTime() - 0.01 end
    end)
    expect(mid and #mid.values == 2 and mid.values[1] == 6 and mid.values[2] == 6,
        "mid-chain suppression must preserve both already-resolved dice")
    expect((Effects.BlastProofStats.lastChainDepth or 0) == 2,
        "mid-chain suppression must occur at continuation depth 2")

    -- Ready defense suppresses the initiating explosion's continuation.
    ply.LODRPGBlastProofReadyAt = nil
    local beforeReady = Effects.BlastProofStats.suppressions or 0
    local ready = incoming({6, 6, 1}, attacker)
    expect(ready and #ready.values == 1 and ready.values[1] == 6,
        "ready defense must retain the triggering die and omit its continuation")
    expect((Effects.BlastProofStats.suppressions or 0) == beforeReady + 1,
        "ready suppression telemetry")
    local rechargeAt = ply.LODRPGBlastProofReadyAt
    expect(rechargeAt and rechargeAt > CurTime(), "suppression must start cooldown")

    -- While spent, the next legitimate explosion chain resolves normally.
    local beforeSpent = Effects.BlastProofStats.suppressions or 0
    local spent = incoming({6, 1}, attacker)
    expect(spent and #spent.values == 2, "cooldown must allow later explosion continuation")
    expect((Effects.BlastProofStats.suppressions or 0) == beforeSpent,
        "cooldown must not consume another suppression")

    -- The defender's own outgoing damage is not protected by Blast-Proof.
    ply.LODRPGBlastProofReadyAt = nil
    local beforeOutgoing = Effects.BlastProofStats.suppressions or 0
    local outgoing = incoming({6, 1}, ply)
    expect(outgoing and #outgoing.values == 2, "defender outgoing damage excluded")
    expect((Effects.BlastProofStats.suppressions or 0) == beforeOutgoing,
        "outgoing damage must not log suppression")

    -- Direct exploding calls outside RollActorDamage model utility/non-damage dice;
    -- the actor-damage-active guard must prevent Blast-Proof from touching them.
    setContext(attacker)
    ply.LODRPGBlastProofReadyAt = nil
    local beforeUtility = Effects.BlastProofStats.suppressions or 0
    local _, utilityValues = Rolls:_RollExploding(
        {count = 1, sides = 6, exploding = 6}, scriptedRNG({6, 1}))
    expect(utilityValues and #utilityValues == 2, "non-damage exploding roll excluded")
    expect((Effects.BlastProofStats.suppressions or 0) == beforeUtility,
        "non-damage roll must not log suppression")

    -- Real automatic recharge check: spend it, then wait just over the exact 2.0 s.
    ply.LODRPGBlastProofReadyAt = nil
    local cooldownSeed = incoming({6, 1}, attacker)
    expect(cooldownSeed and #cooldownSeed.values == 1, "cooldown seed suppression")
    local suppressionsBeforeRecharge = Effects.BlastProofStats.suppressions or 0

    print(string.format(
        "[LOD:RPG-E:B15] Blast-Proof testkit phase 1 %s — mid-chain, ready, spent, outgoing, utility guards",
        #failures == 0 and "PASS" or "FAILED"))
    for _, message in ipairs(failures) do
        ErrorNoHalt("[LOD:RPG-E:B15]  - " .. message .. "\n")
    end

    timer.Simple(COOLDOWN_SECONDS + 0.05, function()
        if not IsValid(ply) then
            if IsValid(attacker) then attacker:Remove() end
            return
        end
        local afterRecharge = incoming({6, 1}, attacker)
        expect(afterRecharge and #afterRecharge.values == 1,
            "automatic 2.0-second recharge must suppress again")
        expect((Effects.BlastProofStats.suppressions or 0) == suppressionsBeforeRecharge + 1,
            "recharge suppression telemetry")
        expect((Effects.BlastProofStats.suppressions or 0) >= initialSuppressions + 4,
            "expected finite test suppression count")
        local passed = #failures == 0
        if passed then
            print("[LOD:RPG-E:B15] Blast-Proof TESTKIT PASS — mid-chain preservation, cooldown, 2.0s recharge, ownership/scope guards")
            ply:ChatPrint("Gate E Batch 15 Blast-Proof testkit PASS.")
        else
            ErrorNoHalt("[LOD:RPG-E:B15] Blast-Proof TESTKIT FAILED\n")
            for _, message in ipairs(failures) do
                ErrorNoHalt("[LOD:RPG-E:B15]  - " .. message .. "\n")
            end
            ply:ChatPrint("Gate E Batch 15 Blast-Proof testkit FAILED; return logs.")
        end
        cleanup()
    end)
end)

return Effects