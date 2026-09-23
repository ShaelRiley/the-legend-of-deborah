LOD = LOD or {}

-- DamageInfo() is a shared engine object, not a fresh allocation. Weak-key maps
-- do not expire its old semantic tags merely because a damage call returned.
function LOD.ReleaseDamageInfo(info)
    local status, rolls, piercing = LOD.RPGStatusElements, LOD.CombatRolls, LOD.MagnumPiercing
    if status and status.DamageContexts then status.DamageContexts[info] = nil end
    if rolls and rolls.PendingDamageReports then rolls.PendingDamageReports[info] = nil end
    if piercing and piercing.DamageSegments then piercing.DamageSegments[info] = nil end
    if LOD.EnemyReactions and LOD.EnemyReactions.Damage then LOD.EnemyReactions.Damage[info] = nil end
    if LOD.CryptoDirector and LOD.CryptoDirector.Damage then LOD.CryptoDirector.Damage[info] = nil end
    if LOD.GeneratedGeometryBallistics and LOD.GeneratedGeometryBallistics.ForgetDamageInfo then
        LOD.GeneratedGeometryBallistics:ForgetDamageInfo(info)
    end
end
function LOD.NewDamageInfo()
    local info = DamageInfo()
    LOD.ReleaseDamageInfo(info)
    return info
end

-- Post-damage observers may request wall-crush damage. Finish the current
-- native damage/death stack before creating another shared DamageInfo object.
-- Callers capture plain values, never the borrowed damage userdata.
function LOD.DeferDamageReaction(attacker, target, callback)
    local run = LOD.RunManager and LOD.RunManager.State
    local seed = run and run.LevelSeed
    local rules = LOD.RPGAbilityRules
    local sourceState = rules and rules:ProgressionState(attacker)
    local targetState = rules and rules:ProgressionState(target)
    local sourceLife = IsValid(attacker) and attacker.LODCombatLifeSerial
    local targetLife = IsValid(target) and target.LODCombatLifeSerial
    timer.Simple(0, function()
        if not IsValid(attacker) or not IsValid(target) or target.LODDead or target:Health() <= 0
            or attacker.LODDead or attacker:Health() <= 0 then return end
        local current = LOD.RunManager and LOD.RunManager.State
        if current ~= run or current and (current.LevelSeed ~= seed or current.Failed or current.LevelCleared) then return end
        if attacker.LODCombatLifeSerial ~= sourceLife or target.LODCombatLifeSerial ~= targetLife then return end
        if rules and (rules:ProgressionState(attacker) ~= sourceState or rules:ProgressionState(target) ~= targetState) then return end
        callback()
    end)
end

local previous = GM.PostEntityTakeDamage
function GM:PostEntityTakeDamage(target, info, taken)
    local result = previous and previous(self, target, info, taken)
    -- hook.Call runs this seam after every ordinary post-damage observer.
    LOD.ReleaseDamageInfo(info)
    return result
end
