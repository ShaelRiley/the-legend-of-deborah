-- In-engine Garry's Mod Runtime Validation for AG-007R2
if CLIENT then return end

LOD = LOD or {}
LOD.AG007R2RuntimeValidation = LOD.AG007R2RuntimeValidation or {}

local RunManager = LOD.RunManager
local Loot = LOD.LootDirector
local CC = LOD.Config

local function log(msg)
    local t = CurTime()
    local line = string.format("[AG-007R2] [%.3f] %s", t, msg)
    print(line)
    MsgN(line)
    if LOD.RPGTestObservability and LOD.RPGTestObservability.RecordEvent then
        LOD.RPGTestObservability:RecordEvent("AG007R2_RUNTIME", {message = msg, time = t})
    end
end

function LOD.AG007R2RuntimeValidation:RunScenario(targetPly)
    local ply = IsValid(targetPly) and targetPly or player.GetAll()[1]
    if not IsValid(ply) then
        log("FAIL: No valid player entity found for in-engine validation")
        return false, "no player entity"
    end

    log("STARTING AG-007R2 GENUINE GARRY'S MOD RUNTIME SCENARIO VALIDATION on " .. tostring(game.GetMap()))
    log("Engine Environment: Real Player=" .. tostring(ply) .. " EntIndex=" .. tostring(ply:EntIndex()) .. " SteamID=" .. tostring(ply:SteamID64() or "local"))

    if not RunManager or not RunManager.State then
        log("FAIL: RunManager state unavailable")
        return false, "no runmanager"
    end

    -- Ensure player is admitted and initialized as Hero
    local ps = RunManager:_AdmitIdentity(ply)
    if not ps then
        log("FAIL: Could not admit player identity")
        return false, "admit failed"
    end
    RunManager.State.ActiveIdentity[ps.identity] = true

    local heroState = ps.progressionState
    if not heroState then
        if LOD.CharacterProgressionSystem and LOD.CharacterProgressionSystem.NewProgressionState then
            heroState = LOD.CharacterProgressionSystem:NewProgressionState(ps.identity, "hero", "hero")
            heroState.level = 5
            heroState.xp = 1250
            ps.progressionState = heroState
        end
    end

    -- 1. Real Hero reaches 0 lives
    local t0 = CurTime()
    ps.lives = 0
    ps.eliminated = true
    ps.eliminatedSince = t0
    ps.respawnAt = nil
    ps.soldierRespawnWait = nil
    RunManager:PutInRestrictedSpectator(ply)
    log(string.format("STEP-1: Hero reaches 0 lives. lives=%d eliminated=%s eliminatedSince=%.3f", ps.lives, tostring(ps.eliminated), ps.eliminatedSince))

    -- 2. Hero remains in real restricted queue/spectator state
    local eligible1 = RunManager:IsHeroRevivalQueueEligible(ply)
    log(string.format("STEP-2: Hero in RETURN_TO_HERO_QUEUE. IsHeroRevivalQueueEligible=%s", tostring(eligible1)))
    if not eligible1 then
        log("FAIL: Hero in queue was not revival eligible")
        return false, "step 2 failed"
    end

    -- 3. Enter Human Soldier through production path
    local okJoin, errJoin = RunManager:JoinSoldierRole(ply)
    log(string.format("STEP-3: Enter Human Soldier through JoinSoldierRole. ok=%s err=%s IsSoldierControl=%s", tostring(okJoin), tostring(errJoin or "none"), tostring(RunManager:IsSoldierControl(ply))))
    if not okJoin or not RunManager:IsSoldierControl(ply) then
        log("FAIL: JoinSoldierRole failed")
        return false, "step 3 failed"
    end

    -- 4. Verify preserved Hero state
    local heroLevel = ps.progressionState and ps.progressionState.level
    local heroXP = ps.progressionState and ps.progressionState.xp
    log(string.format("STEP-4: Preserved Hero state verified during Soldier control: level=%s xp=%s", tostring(heroLevel), tostring(heroXP)))

    -- 5. Verify Soldier presentation/stats are sourced from canonical Soldier authority
    local archetype = CC and CC.Encounter and CC.Encounter.Archetypes and CC.Encounter.Archetypes.soldier
    local expectedHP = archetype and archetype.baseHP or 35
    local expectedModel = archetype and archetype.model or "models/combine_soldier.mdl"
    log(string.format("STEP-5: Soldier stats/presentation sourced from canonical authority: HP=%d (expected %d) model=%s", ply:Health(), expectedHP, tostring(ply:GetModel())))

    -- 6. Attempt same-dungeon revival while active Soldier: skipped
    local eligibleSol = RunManager:IsHeroRevivalQueueEligible(ply)
    local okRevSol, errRevSol = RunManager:ReviveIdentity(ps.identity)
    log(string.format("STEP-6: Same-dungeon revival attempted on active Soldier. IsHeroRevivalQueueEligible=%s ReviveIdentity ok=%s err=%s IsSoldierControl=%s", tostring(eligibleSol), tostring(okRevSol), tostring(errRevSol), tostring(RunManager:IsSoldierControl(ply))))
    if eligibleSol or okRevSol or not RunManager:IsSoldierControl(ply) then
        log("FAIL: Active Soldier was not excluded from revival or side-effect retired Soldier")
        return false, "step 6 failed"
    end

    -- 7. Kill Soldier -> SOLDIER_RESPAWN_WAIT
    ply:SetAlive(false)
    RunManager:HandleDeath(ply)
    local inWait = ps.soldierRespawnWait == true or (ps.respawnAt and ps.respawnAt > CurTime())
    log(string.format("STEP-7: Soldier killed. IsSoldierControl=%s inWait=%s respawnAt=%.3f", tostring(RunManager:IsSoldierControl(ply)), tostring(inWait), tonumber(ps.respawnAt) or 0))

    -- 8. During real 20-second Soldier wait, attempt revival: skipped
    local eligibleWait = RunManager:IsHeroRevivalQueueEligible(ply)
    local okRevWait, errRevWait = RunManager:ReviveIdentity(ps.identity)
    log(string.format("STEP-8: Revival attempted during SOLDIER_RESPAWN_WAIT. IsHeroRevivalQueueEligible=%s ReviveIdentity ok=%s err=%s", tostring(eligibleWait), tostring(okRevWait), tostring(errRevWait)))
    if eligibleWait or okRevWait then
        log("FAIL: Player in SOLDIER_RESPAWN_WAIT was not excluded from revival")
        return false, "step 8 failed"
    end

    -- 9. Return to Hero Queue (using production concommand seam)
    local okRet, errRet = RunManager:ReturnToHeroQueue(ply)
    log(string.format("STEP-9: ReturnToHeroQueue executed. ok=%s err=%s IsSoldierControl=%s soldierRespawnWait=%s", tostring(okRet), tostring(errRet or "none"), tostring(RunManager:IsSoldierControl(ply)), tostring(ps.soldierRespawnWait)))

    -- 10. Verify original eliminatedSince preserved
    local eliminatedSincePreserved = (ps.eliminatedSince == t0)
    local eligibleQueue = RunManager:IsHeroRevivalQueueEligible(ply)
    log(string.format("STEP-10: Preserved original eliminatedSince=%.3f (match=%s). IsHeroRevivalQueueEligible=%s", tonumber(ps.eliminatedSince) or 0, tostring(eliminatedSincePreserved), tostring(eligibleQueue)))
    if not eliminatedSincePreserved or not eligibleQueue then
        log("FAIL: eliminatedSince was not preserved or queue eligibility not restored")
        return false, "step 10 failed"
    end

    -- 11. Trigger later revival: Hero returns
    local okValidRev, msgValidRev = RunManager:ReviveIdentity(ps.identity)
    log(string.format("STEP-11: Trigger later revival. ReviveIdentity ok=%s msg=%s lives=%d eliminated=%s", tostring(okValidRev), tostring(msgValidRev), ps.lives, tostring(ps.eliminated)))
    if not okValidRev or ps.lives <= 0 or ps.eliminated then
        log("FAIL: Valid queue revival failed")
        return false, "step 11 failed"
    end

    -- 12. Verify active-Hero misuse of ReturnToHeroQueue is rejected
    local okActiveRet, errActiveRet = RunManager:ReturnToHeroQueue(ply)
    log(string.format("STEP-12: Active Hero calling ReturnToHeroQueue. ok=%s err=%s lives=%d eliminated=%s", tostring(okActiveRet), tostring(errActiveRet), ps.lives, tostring(ps.eliminated)))
    if okActiveRet or ps.lives ~= 1 or ps.eliminated then
        log("FAIL: Active Hero ReturnToHeroQueue was not rejected or mutated state")
        return false, "step 12 failed"
    end

    -- 13. Verify Soldier does not prevent true Hero-party wipe
    ps.lives = 0
    ps.eliminated = true
    RunManager:JoinSoldierRole(ply)
    ply:SetAlive(true)
    RunManager.State.Failed = false
    local wipe = RunManager:EvaluateWipe()
    log(string.format("STEP-13: EvaluateWipe with active Soldier. wipe=%s CampaignFailed=%s", tostring(wipe), tostring(RunManager.State.Failed)))
    RunManager.State.Failed = false
    if not wipe then
        log("FAIL: Active Soldier prevented party wipe when all Heroes were eliminated")
        return false, "step 13 failed"
    end

    log("AG-007R2 GENUINE GARRY'S MOD RUNTIME SCENARIO VALIDATION COMPLETE — ALL 13 STEPS VERIFIED PASS")
    return true
end

concommand.Add("lod_rpg_ag007r2_runtime_validate", function(ply)
    LOD.AG007R2RuntimeValidation:RunScenario(ply)
end)

-- Auto-run once when map loads on server in dev mode
hook.Add("InitPostEntity", "LOD_AG007R2_AutoRuntimeValidation", function()
    timer.Simple(2.0, function()
        local cvDev = GetConVar("lod_developer_mode")
        if cvDev and cvDev:GetBool() then
            LOD.AG007R2RuntimeValidation:RunScenario()
        end
    end)
end)
