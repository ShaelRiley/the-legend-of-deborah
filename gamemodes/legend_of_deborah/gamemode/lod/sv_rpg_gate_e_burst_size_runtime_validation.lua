LOD = LOD or {}

local RPG = LOD.RPG
local Effects = RPG and RPG.FeatEffectSystem
local Rules = LOD.RPGAbilityRules
local Specials = LOD.PlayerWeaponSpecials
if not Effects or not Rules or not Specials then return end
if Effects.LODBurstSizeRuntimeAuthorityValidationInstalled then return Effects end
Effects.LODBurstSizeRuntimeAuthorityValidationInstalled = true

local EXPECTED_AUTHORITY = "gate_e_ar2_one_ammo_per_burst_v2"

-- Extend the family validator with the final mutable runtime seam. This catches the
-- exact failure seen in the first corrected Batch-7 playtest: the data/model layer
-- could validate while an older PlayerWeaponSpecials implementation still owned the
-- live AR2 transaction.
if isfunction(Effects.ValidateBurstSizeFamily) then
    local baseValidate = Effects.ValidateBurstSizeFamily
    function Effects:ValidateBurstSizeFamily()
        if isfunction(self.InstallAR2RateOfFireAuthorityWrappers) then
            self.InstallAR2RateOfFireAuthorityWrappers()
        end

        local ok, errors = baseValidate(self)
        errors = errors or {}
        local function expect(value, message)
            if not value then errors[#errors + 1] = message end
        end

        expect(Specials.AR2GateEAuthorityRevision == EXPECTED_AUTHORITY,
            "final AR2 one-ammo authority revision")
        expect(isfunction(Specials.LODRateOfFireBeginWrapper)
            and Specials.BeginAR2Burst == Specials.LODRateOfFireBeginWrapper,
            "final BeginAR2Burst wrapper owns public authority")
        expect(isfunction(Specials.LODRateOfFireFireWrapper)
            and Specials.FireAR2Round == Specials.LODRateOfFireFireWrapper,
            "final FireAR2Round wrapper owns public authority")
        expect(isfunction(Effects.RecordBurstSizeResult),
            "runtime burst-result evidence authority available")

        return ok and #errors == 0, errors
    end
end

local function developerAllowed(ply)
    local cv = GetConVar("lod_developer_mode")
    return cv and cv:GetBool() and (not IsValid(ply) or ply:IsAdmin())
end

concommand.Add("lod_rpg_gate_e_burst_authority_status", function(ply)
    if not developerAllowed(ply) then return end
    if isfunction(Effects.InstallAR2RateOfFireAuthorityWrappers) then
        Effects.InstallAR2RateOfFireAuthorityWrappers()
    end

    local beginOK = isfunction(Specials.LODRateOfFireBeginWrapper)
        and Specials.BeginAR2Burst == Specials.LODRateOfFireBeginWrapper
    local fireOK = isfunction(Specials.LODRateOfFireFireWrapper)
        and Specials.FireAR2Round == Specials.LODRateOfFireFireWrapper
    local config = Specials.AR2Config or {}
    local line = string.format(
        "revision=%s baseMode=%s beginWrapped=%s fireWrapped=%s baseConfigOneAmmo=%s resultAdapter=%s",
        tostring(Specials.AR2GateEAuthorityRevision or "none"),
        tostring(Specials.AR2GateEBaseMode or "unproven"),
        tostring(beginOK), tostring(fireOK),
        tostring(config.ammoPerTriggerBurst == 1),
        tostring(Effects.LODAR2LegacyBurstRecordAdapter == true))
    print("[LOD:RPG-E] AR2 burst authority " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)

-- Isolated one-ammo acceptance kit. Reserve ammunition is deliberately zero so an
-- empty post-burst clip cannot auto-reload and obscure the one-ammo assertion.
-- Relevant counters are reset here so a pre-test AR2 burst cannot contaminate the
-- evidence, which happened in the first corrected Batch-7 run.
concommand.Add("lod_rpg_gate_e_burst_ammo_testkit", function(ply, _, args)
    if not developerAllowed(ply) or not IsValid(ply) or not ply:Alive() then return end

    if isfunction(Effects.InstallAR2RateOfFireAuthorityWrappers) then
        Effects.InstallAR2RateOfFireAuthorityWrappers()
    end
    if isfunction(Specials.ResetPlayer) then Specials:ResetPlayer(ply) end

    local weapon = ply:GetWeapon("weapon_ar2")
    if not IsValid(weapon) then weapon = ply:Give("weapon_ar2", true) end
    if not IsValid(weapon) then
        ply:ChatPrint("Could not grant AR2 burst-ammo test weapon.")
        return
    end

    local requestedClip = math.Clamp(math.floor(tonumber(args[1]) or 1), 0, 1)
    weapon:SetClip1(requestedClip)
    local ammoType = weapon:GetPrimaryAmmoType()
    if ammoType and ammoType >= 0 then ply:SetAmmo(0, ammoType) end
    weapon:SetNextPrimaryFire(CurTime())
    weapon:SetNextSecondaryFire(CurTime())

    Specials.Stats = Specials.Stats or {}
    Specials.Stats.ar2Bursts = 0
    Specials.Stats.ar2AmmoCommitted = 0
    Specials.Stats.ar2Rounds = 0
    Specials.Stats.lastAR2BurstRounds = 0
    Specials.Stats.lastAR2BurstTarget = 0
    Specials.Stats.lastAR2BurstDesired = 0

    Effects.BurstSizeStats = Effects.BurstSizeStats or {}
    Effects.BurstSizeStats.completedBursts = 0
    Effects.BurstSizeStats.abortedBursts = 0
    Effects.BurstSizeStats.lastResult = nil

    if Effects.AR2RateOfFirePlans then Effects.AR2RateOfFirePlans[ply] = nil end
    ply:SelectWeapon("weapon_ar2")

    local bonus = isfunction(Rules.BurstBonusRounds) and Rules:BurstBonusRounds(ply) or 0
    local final = isfunction(Rules.ResolveBurstCount)
        and Rules:ResolveBurstCount(3, bonus) or (3 + bonus)
    local line = string.format(
        "Burst-ammo acceptance kit: clip=%d reserve=0 bonus=+%d final=%d. clip=1 must fire all %d projectiles for one ammo; clip=0 must fire none.",
        requestedClip, bonus, final, final)
    print("[LOD:RPG-E] " .. line)
    ply:ChatPrint(line)
end)

return Effects
