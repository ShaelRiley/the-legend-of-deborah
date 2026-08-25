LOD = LOD or {}

local Rolls = LOD.CombatRolls
if not Rolls or not Rolls.RollHostileAttack then return end

-- Whole-dungeon playtesting showed that the first dice conversion preserved the
-- old fixed-damage averages but introduced overly lethal melee spikes. Keep the
-- existing instance-size/stat multiplier by retaining the old reference values,
-- while narrowing and lowering the actual dice rolls themselves.
--
-- Base/unscaled bands:
--   Shambler 3d4+8 -> 11..20, mean 15.5 (formerly 3d10+3 -> 6..33, mean 19.5)
--   Runner   2d4+2 ->  4..10, mean  7.0 (formerly 2d8+1  -> 3..17, mean 10.0)
--
-- Damage remains fixed across campaign levels. Later difficulty comes from
-- encounter composition and pressure rather than hidden per-level damage growth.
local MELEE_PROFILES = {
    shambler = {
        label = "SHAMBLER",
        source = "melee",
        count = 3,
        sides = 4,
        bonus = 8,
        reference = 20
    },
    runner = {
        label = "RUNNER",
        source = "melee",
        count = 2,
        sides = 4,
        bonus = 2,
        reference = 10
    }
}

-- Restore the original method before re-wrapping if this module is manually
-- reloaded in development, avoiding a wrapper stack.
if Rolls.LODBaseRollHostileAttackBeforeMeleeBalance then
    Rolls.RollHostileAttack = Rolls.LODBaseRollHostileAttackBeforeMeleeBalance
end

local baseRollHostileAttack = Rolls.RollHostileAttack
Rolls.LODBaseRollHostileAttackBeforeMeleeBalance = baseRollHostileAttack
Rolls.MeleeBalanceProfiles = MELEE_PROFILES

function Rolls:RollHostileAttack(hostile, profile, originalDamage, cacheOwner)
    local archetype = IsValid(hostile) and hostile.LODArchetypeId or nil
    local tuned = archetype and MELEE_PROFILES[archetype] or nil
    return baseRollHostileAttack(self, hostile, tuned or profile, originalDamage, cacheOwner)
end

concommand.Add("lod_enemy_melee_dice_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local line = "Shambler=3d4+8 (11-20, mean 15.5); Runner=2d4+2 (4-10, mean 7.0); campaignDamageScaling=off"
    print("[LOD:MELEE-DICE] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
