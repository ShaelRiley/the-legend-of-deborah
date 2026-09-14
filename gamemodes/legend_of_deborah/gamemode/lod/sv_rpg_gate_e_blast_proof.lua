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
        description = "Once every 2.0 seconds per defender, suppresses the first qualifying continuation created by an incoming actor-owned exploding damage die. The triggering die and all already-resolved damage remain; that continuation is omitted and its chain ends. Independent damage-die chains are unaffected."
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
    if attacker:IsPlayer() and attacker ~= defender and rolls and rolls._Send then
        rolls:_Send(attacker, 3, "BLAST-PROOF — target prevented an explosion continuation", "resist", {event = "blast_proof"})
    end
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

-- Shared attacks keep one immutable sampled roll. Each defender resolves a
-- view of that roll: suppression ends only that defender's first eligible chain,
-- never the attack's other independent chains or another victim's damage.
function Effects:BlastProofTargetContract(contract, attacker, defender)
    if not contract or not contract.values or not IsValid(defender) then return contract end
    if LOD.RPGStatusElements and LOD.RPGStatusElements.BindActorLife then LOD.RPGStatusElements:BindActorLife(defender) end
    contract.blastProofTargets = contract.blastProofTargets or setmetatable({}, {__mode = "k"})
    local state = Rules:ProgressionState(defender)
    local epoch = LOD.RunManager and LOD.RunManager.State and LOD.RunManager.State.LevelSeed
    local cached = contract.blastProofTargets[defender]
    if cached and cached.identity == state and cached.epoch == epoch then return cached.contract end
    local view = contract
    local starts = {}
    for _, index in ipairs(contract.chainStarts or {1}) do starts[index] = true end
    for index = 2, #contract.values do
        if not starts[index] and self:TryBlastProofContinuation(defender, attacker,
            {incoming = true, damageDie = true, continuation = true,
                sides = contract.profile and contract.profile.sides, chainDepth = index - 1}) then
            view = {}
            for key, value in pairs(contract) do view[key] = value end
            view.originContract = contract.originContract or contract
            view.values, view.contributions, view.thresholds, view.chainStarts = {}, {}, {}, {}
            view.total = tonumber(contract.bonus) or 0
            local finish = index
            while finish <= #contract.values and not starts[finish] do finish = finish + 1 end
            for i, value in ipairs(contract.values) do
                if i < index or i >= finish then
                    local nextIndex = #view.values + 1
                    view.values[nextIndex] = value
                    view.contributions[nextIndex] = (contract.contributions or {})[i] or value
                    view.thresholds[nextIndex] = (contract.thresholds or {})[i]
                    if starts[i] then view.chainStarts[#view.chainStarts + 1] = nextIndex end
                    view.total = view.total + view.contributions[nextIndex]
                end
            end
            view.blastProofSuppressed = finish - index
            break
        end
    end
    contract.blastProofTargets[defender] = {identity = state, epoch = epoch, contract = view}
    return view
end

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
    if not Rolls or not Rolls.ResolveActorDamage or not Effects.BlastProofTargetContract then
        ok = false
        errors[#errors + 1] = "runtime target contract resolver unavailable"
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

-- Finite synchronous probe: no delayed callbacks can retain temporary ownership
-- across death, disconnect, or a level transition.
concommand.Add("lod_rpg_test_blast_proof", function(ply)
    if not developerAllowed(ply) or not IsValid(ply) or not ply:IsPlayer() then return end
    local state = Rules:ProgressionState(ply)
    if not state then return end
    local attacker = ents.Create("base_anim")
    if not IsValid(attacker) then return end
    attacker:SetNoDraw(true)
    attacker:Spawn()
    if LOD.RPGStatusElements then LOD.RPGStatusElements:BindActorLife(ply) end
    local originalFeats, originalReady = state.featIds, ply.LODRPGBlastProofReadyAt
    state.featIds = table.Copy(originalFeats or {})
    if not owns(state, FEAT_ID) then state.featIds[#state.featIds + 1] = FEAT_ID end
    local ok, failure = pcall(function()
        local function sample()
            return {values = {6, 6, 2, 3}, contributions = {6, 6, 2, 3},
                chainStarts = {1, 4}, total = 17, bonus = 0, profile = {sides = 6}}
        end
        ply.LODRPGBlastProofReadyAt = nil
        local original = sample()
        local view = Effects:BlastProofTargetContract(original, attacker, ply)
        assert(view.total == 9 and #view.values == 2, "first chain ends; independent die survives")
        assert(original.total == 17 and #original.values == 4, "shared source remains immutable")
        assert(Effects:BlastProofTargetContract(original, attacker, ply) == view, "target view reused")
        local spent = sample()
        assert(Effects:BlastProofTargetContract(spent, attacker, ply) == spent, "cooldown respected")
        ply.LODRPGBlastProofReadyAt = CurTime() - 0.01
        assert(Effects:BlastProofTargetContract(sample(), attacker, ply).total == 9, "recharged defense")
        ply.LODRPGBlastProofReadyAt = nil
        local selfRoll = sample()
        assert(Effects:BlastProofTargetContract(selfRoll, ply, ply) == selfRoll, "self damage excluded")
        local passed, errors = Effects:ValidateBlastProof()
        assert(passed, table.concat(errors, "; "))
    end)
    state.featIds, ply.LODRPGBlastProofReadyAt = originalFeats, originalReady
    if IsValid(attacker) then attacker:Remove() end
    print("[LOD:BLAST-PROOF] " .. (ok and "PASS" or ("FAIL: " .. tostring(failure))))
    ply:ChatPrint("Blast-Proof test " .. (ok and "PASS." or "FAILED; return logs."))
end)

return Effects
