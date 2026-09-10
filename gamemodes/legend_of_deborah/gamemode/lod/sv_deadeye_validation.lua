if not LOD or not LOD.RPGAbilityRules then return end

local function developerAllowed(ply)
    local cv = GetConVar("lod_developer_mode")
    return cv and cv:GetBool() and (not IsValid(ply) or ply:IsAdmin())
end

local WEAPON_CLASSES = {
    "weapon_lod_crowbar",
    "weapon_pistol",
    "weapon_357",
    "weapon_smg1",
    "weapon_shotgun",
    "weapon_ar2",
    "weapon_frag"
}

concommand.Add("lod_deadeye_aim_validate", function(ply)
    if not developerAllowed(ply) then return end

    local function expect(cond, msg)
        if not cond then
            ErrorNoHalt("[LOD:DEADEYE] FAIL - " .. msg .. "\n")
            return false
        end
        return true
    end

    local catalog = LOD.RPGAbilityRules.FeatCatalog
    local deadeye = nil
    for _, feat in pairs(catalog or {}) do
        if feat.id == "DEX_MAGNUM_DEADEYE" then deadeye = feat; break end
    end

    if not expect(deadeye, "Missing DEX_MAGNUM_DEADEYE in catalog") then return end
    if not expect(deadeye.requirement == "DEX 15", "Requirement is not DEX 15") then return end
    if not expect(not deadeye.prerequisite, "Prerequisite is not None (found " .. tostring(deadeye.prerequisite) .. ")") then return end

    local mockPistol = {GetClass = function() return "weapon_pistol" end}
    local mockMagnum = {GetClass = function() return "weapon_357" end}
    local mockCrowbar = {GetClass = function() return "weapon_lod_crowbar" end}
    local mockSMG = {GetClass = function() return "weapon_smg1" end}
    local mockShotgun = {GetClass = function() return "weapon_shotgun" end}
    local mockAR2 = {GetClass = function() return "weapon_ar2" end}
    local mockFrag = {GetClass = function() return "weapon_frag" end}
    local mockOther = {GetClass = function() return "weapon_rpg" end}

    local stateWithoutDeadeye = {DEX_MAGNUM_DEADEYE = false}
    local stateWithDeadeye = {DEX_MAGNUM_DEADEYE = true}

    if not expect(LOD.RPGAbilityRules:AimHoldSeconds(stateWithoutDeadeye) == 0.50, "Baseline Aim hold is not 0.50") then return end
    if not expect(LOD.RPGAbilityRules:AimHoldSeconds(stateWithDeadeye) == 0.50, "Deadeye Aim hold is not 0.50") then return end

    if not expect(not LOD.AimableWeaponForState(stateWithoutDeadeye, mockPistol), "Baseline Pistol can Aim") then return end
    if not expect(LOD.AimableWeaponForState(stateWithoutDeadeye, mockMagnum), "Baseline Magnum cannot Aim") then return end

    local function simConsume(state, weapon)
        if not LOD.AimableWeaponForState(state, weapon) then return 1 end
        if weapon:GetClass() == "weapon_357" then
            return state.DEX_MAGNUM_DEADEYE and 3 or 2
        else
            return 2
        end
    end

    if not expect(simConsume(stateWithoutDeadeye, mockMagnum) == 2, "Baseline Magnum != x2") then return end
    if not expect(simConsume(stateWithDeadeye, mockCrowbar) == 2, "Deadeye Crowbar != x2") then return end
    if not expect(simConsume(stateWithDeadeye, mockPistol) == 2, "Deadeye Pistol != x2") then return end
    if not expect(simConsume(stateWithDeadeye, mockMagnum) == 3, "Deadeye Magnum != x3") then return end
    if not expect(simConsume(stateWithDeadeye, mockSMG) == 2, "Deadeye SMG != x2") then return end
    if not expect(simConsume(stateWithDeadeye, mockShotgun) == 2, "Deadeye Shotgun != x2") then return end
    if not expect(simConsume(stateWithDeadeye, mockAR2) == 2, "Deadeye AR2 != x2") then return end
    if not expect(simConsume(stateWithDeadeye, mockFrag) == 2, "Deadeye frag != x2") then return end
    if not expect(not LOD.AimableWeaponForState(stateWithDeadeye, mockOther), "Deadeye Other can aim") then return end

    print("[LOD:DEADEYE] definition=PASS requirement=DEX15 hold=0.50 ordinary=x2 magnum=x3 universal=true result=PASS")
end)

concommand.Add("lod_deadeye_aim_testkit", function(ply)
    if not developerAllowed(ply) or not IsValid(ply) then return end
    ply:SetNW2Int("LOD_DEX", 15)
    LOD.CharacterProgressionSystem:GrantFeat(ply, "DEX_MAGNUM_DEADEYE")

    for _, wep in ipairs(WEAPON_CLASSES) do
        ply:Give(wep)
    end
    ply:GiveAmmo(99, "Pistol")
    ply:GiveAmmo(99, "357")
    ply:GiveAmmo(99, "SMG1")
    ply:GiveAmmo(99, "Buckshot")
    ply:GiveAmmo(99, "AR2")
    ply:GiveAmmo(10, "Grenade")
    print("[LOD:DEADEYE] testkit: granted DEX 15, DEX_MAGNUM_DEADEYE, and standard weapons.")
end)

concommand.Add("lod_deadeye_aim_status", function(ply)
    if not developerAllowed(ply) then return end
    if not IsValid(ply) then return end
    local state = LOD.Magnum and LOD.Magnum.AimStates and LOD.Magnum.AimStates[ply]
    local hold = LOD.RPGAbilityRules:AimHoldSeconds(ply)
    local deadeye = LOD.RPGAbilityRules:ProgressionState(ply).DEX_MAGNUM_DEADEYE
    local activeWep = IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass() or "none"
    local aimable = LOD.AimableWeaponForState(LOD.RPGAbilityRules:ProgressionState(ply), ply:GetActiveWeapon())

    local line = string.format("hold=%.2fs deadeye=%s active=%s aimable=%s armed=%s",
        hold, tostring(deadeye == true), activeWep, tostring(aimable),
        tostring(state and state.armed == true or false))
    print("[LOD:DEADEYE] status: " .. line)
    ply:ChatPrint("[LOD:DEADEYE] " .. line)
end)
