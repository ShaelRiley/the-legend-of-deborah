LOD = LOD or {}
LOD.DiceAmmo = LOD.DiceAmmo or {}

local Ammo = LOD.DiceAmmo
local TICK_SECONDS = 0.25
local NO_FIRE_DELAY = 3.0
local SHARED_TIMER = "LOD_DiceAmmoSharedTick"

-- Keep the base/shared profile table aligned with the final production capacities
-- so early scaffolding and lod_dice_ammo_status cannot report retired values even
-- though later weapon-specific modules still reinforce these same balances.
local PROFILES = {
    weapon_pistol = {
        label = "Pistol", ammo = "Pistol", load = 18, cap = 54,
        floor = 18, recovery = 60, pickup = 6
    },
    weapon_shotgun = {
        label = "Shotgun", ammo = "Buckshot", load = 7, cap = 21,
        floor = 7, recovery = 90, pickup = 3
    },
    weapon_smg1 = {
        label = "SMG", ammo = "SMG1", load = 34, cap = 102,
        floor = 34, recovery = 120, pickup = 15
    },
    weapon_ar2 = {
        label = "AR2", ammo = "AR2", load = 20, cap = 60,
        floor = 20, recovery = 150, pickup = 10
    },
    weapon_357 = {
        label = ".357 Magnum", ammo = "357", load = 6, cap = 18,
        floor = 6, recovery = 180, pickup = 2
    }
}

Ammo.PlayerState = Ammo.PlayerState or setmetatable({}, {__mode = "k"})
Ammo.Stats = Ammo.Stats or {roundsRegenerated = 0, capClamps = 0}

local function developerAllowed(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return false end
    return IsValid(ply) and ply:IsAdmin()
end

local function familyWeapon(ply, weaponClass)
    if not IsValid(ply) then return nil end
    local weapon = ply:GetWeapon(weaponClass)
    return IsValid(weapon) and weapon or nil
end

local function familyTotal(ply, weaponClass, profile)
    local weapon = familyWeapon(ply, weaponClass)
    local clip = weapon and math.max(0, weapon:Clip1()) or 0
    return clip + math.max(0, ply:GetAmmoCount(profile.ammo)), clip, weapon
end

local function testkitBypass(ply, weaponClass)
    return weaponClass == "weapon_pistol" and ply.LODM3InfiniteTestPistol == true
end

function Ammo:_FamilyState(ply, weaponClass)
    local state = self.PlayerState[ply]
    if not state then
        state = {}
        self.PlayerState[ply] = state
    end
    if not state[weaponClass] then state[weaponClass] = {} end
    return state[weaponClass]
end

function Ammo:ClampFamily(ply, weaponClass, profile)
    if not IsValid(ply) or testkitBypass(ply, weaponClass) then return false end
    local total, clip, weapon = familyTotal(ply, weaponClass, profile)
    if total <= profile.cap then return false end

    if weapon and clip > profile.cap then
        weapon:SetClip1(profile.cap)
        clip = profile.cap
    end
    ply:SetAmmo(math.max(0, profile.cap - clip), profile.ammo)
    self.Stats.capClamps = (self.Stats.capClamps or 0) + 1
    return true
end

-- Temporary Gate-C test support. The final LootDirector will own individualized,
-- seeded weighted drops. Until then, death pickups grant a small amount of ammo
-- for the collector's most depleted firearm family. This deliberately reuses the
-- production caps so the scaffold cannot create ammunition above normal limits.
function Ammo:GrantTemporaryDrop(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return false end

    local chosenClass
    local chosenProfile
    local chosenTotal
    local chosenRatio

    for weaponClass, profile in pairs(PROFILES) do
        if not testkitBypass(ply, weaponClass) then
            local total, _, weapon = familyTotal(ply, weaponClass, profile)
            if weapon and total < profile.cap then
                local ratio = total / math.max(1, profile.cap)
                if chosenRatio == nil or ratio < chosenRatio
                    or (ratio == chosenRatio and weaponClass < chosenClass)
                then
                    chosenClass = weaponClass
                    chosenProfile = profile
                    chosenTotal = total
                    chosenRatio = ratio
                end
            end
        end
    end

    if not chosenProfile then return false end

    local headroom = math.max(0, chosenProfile.cap - chosenTotal)
    local amount = math.min(headroom, math.max(1, chosenProfile.pickup or 1))
    if amount <= 0 then return false end

    ply:SetAmmo(ply:GetAmmoCount(chosenProfile.ammo) + amount, chosenProfile.ammo)
    self:ClampFamily(ply, chosenClass, chosenProfile)
    self.Stats.pickupsCollected = (self.Stats.pickupsCollected or 0) + 1
    self.Stats.pickupRounds = (self.Stats.pickupRounds or 0) + amount

    return true, chosenProfile.label, amount
end

function Ammo:Interrupt(ply, weaponClass, now)
    local profile = PROFILES[weaponClass]
    if not profile or not IsValid(ply) or testkitBypass(ply, weaponClass) then return end
    local state = self:_FamilyState(ply, weaponClass)
    state.nextRoundAt = (now or CurTime()) + NO_FIRE_DELAY
        + profile.recovery / profile.floor
end

function Ammo:TickPlayer(ply, now)
    if not IsValid(ply) or not ply:Alive() then return end
    now = now or CurTime()

    for weaponClass, profile in pairs(PROFILES) do
        if not testkitBypass(ply, weaponClass) then
            self:ClampFamily(ply, weaponClass, profile)
            local total, _, weapon = familyTotal(ply, weaponClass, profile)
            local state = self:_FamilyState(ply, weaponClass)

            if not weapon or total >= profile.floor then
                state.nextRoundAt = nil
            else
                local interval = profile.recovery / profile.floor
                state.nextRoundAt = state.nextRoundAt or (now + NO_FIRE_DELAY + interval)
                while total < profile.floor and now >= state.nextRoundAt do
                    ply:SetAmmo(ply:GetAmmoCount(profile.ammo) + 1, profile.ammo)
                    total = total + 1
                    state.nextRoundAt = state.nextRoundAt + interval
                    self.Stats.roundsRegenerated = (self.Stats.roundsRegenerated or 0) + 1
                end
            end
        end
    end
end

hook.Add("EntityFireBullets", "LOD_DiceAmmoInterrupt", function(shooter)
    if not IsValid(shooter) or not shooter:IsPlayer() then return end
    local weapon = shooter:GetActiveWeapon()
    if not IsValid(weapon) then return end
    Ammo:Interrupt(shooter, weapon:GetClass(), CurTime())
end)

hook.Add("PlayerSpawn", "LOD_DiceAmmoResetEligibility", function(ply)
    Ammo.PlayerState[ply] = nil
end)

timer.Create(SHARED_TIMER, TICK_SECONDS, 0, function()
    local run = LOD.RunManager
    local state = run and run.State
    if not state or not state.BuildReady or state.Failed or state.LevelCleared then return end
    local now = CurTime()
    for _, ply in ipairs(player.GetAll()) do
        if run:IsActivePlayer(ply) then Ammo:TickPlayer(ply, now) end
    end
end)

local function printLine(ply, line)
    print("[LOD:DICE-AMMO] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end

concommand.Add("lod_dice_ammo_status", function(ply)
    if not developerAllowed(ply) then return end
    local owned = 0
    local overflow = 0
    local details = {}
    for weaponClass, profile in pairs(PROFILES) do
        local total, _, weapon = familyTotal(ply, weaponClass, profile)
        if weapon then owned = owned + 1 end
        if not testkitBypass(ply, weaponClass) and total > profile.cap then overflow = overflow + 1 end
        if weapon then
            details[#details + 1] = string.format("%s=%d/%d floor=%d",
                profile.label, total, profile.cap, profile.floor)
        end
    end
    table.sort(details)
    printLine(ply, string.format(
        "owned=%d overflow=%d regenerated=%d clamps=%d pickups=%d pickupRounds=%d %s result=%s",
        owned, overflow, Ammo.Stats.roundsRegenerated or 0, Ammo.Stats.capClamps or 0,
        Ammo.Stats.pickupsCollected or 0, Ammo.Stats.pickupRounds or 0,
        table.concat(details, " "), overflow == 0 and "PASS" or "FAIL"))
end)

concommand.Add("lod_dice_ammo_probe", function(ply)
    if not developerAllowed(ply) or not ply:Alive() then return end
    local profile = PROFILES.weapon_pistol
    ply.LODM3InfiniteTestPistol = false
    local weapon = familyWeapon(ply, "weapon_pistol")
    if not weapon then weapon = ply:Give("weapon_pistol", true) end
    if not IsValid(weapon) then
        printLine(ply, "probe could not grant pistol result=FAIL")
        return
    end

    weapon:SetClip1(profile.load)
    ply:SetAmmo(999, profile.ammo)
    Ammo:ClampFamily(ply, "weapon_pistol", profile)
    local cappedTotal = familyTotal(ply, "weapon_pistol", profile)
    local capPass = cappedTotal == profile.cap

    weapon:SetClip1(0)
    ply:SetAmmo(0, profile.ammo)
    Ammo:Interrupt(ply, "weapon_pistol", CurTime())
    local probeName = "LOD_DiceAmmoProbe_" .. ply:EntIndex()
    timer.Remove(probeName)
    timer.Create(probeName, NO_FIRE_DELAY + profile.recovery / profile.floor + 0.75, 1, function()
        if not IsValid(ply) then return end
        local total = familyTotal(ply, "weapon_pistol", profile)
        local regenPass = total == 1
        printLine(ply, string.format(
            "capTotal=%d capExpected=%d cap=%s regenTotal=%d regenExpected=1 regen=%s result=%s",
            cappedTotal, profile.cap, capPass and "PASS" or "FAIL", total,
            regenPass and "PASS" or "FAIL", capPass and regenPass and "PASS" or "FAIL"))
    end)
end)
