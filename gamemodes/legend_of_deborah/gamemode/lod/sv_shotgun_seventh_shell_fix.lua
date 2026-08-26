LOD = LOD or {}
LOD.ShotgunSeventhShellFix = LOD.ShotgunSeventhShellFix or {}

local Fix = LOD.ShotgunSeventhShellFix
local SHOTGUN_CLASS = "weapon_shotgun"
local SHOTGUN_AMMO = "Buckshot"
local EFFECTIVE_MAGAZINE = 7
local TOTAL_CAP = 21
local STOCK_ENGINE_MAX = 6
local RELOAD_POLL_INTERVAL = 0.10
local RELOAD_POLL_COUNT = 70

Fix.Stats = Fix.Stats or {
    acquisitionTopoffs = 0,
    reloadTopoffs = 0,
    failedSetClip = 0
}

local function activeShotgun(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return nil end
    local weapon = ply:GetActiveWeapon()
    return IsValid(weapon) and weapon:GetClass() == SHOTGUN_CLASS and weapon or nil
end

local function clampFamily(ply, weapon)
    if not IsValid(ply) or not IsValid(weapon) then return end
    local clip = math.max(0, weapon:Clip1())
    local reserve = math.max(0, ply:GetAmmoCount(SHOTGUN_AMMO))
    local allowedReserve = math.max(0, TOTAL_CAP - clip)
    if reserve > allowedReserve then
        ply:SetAmmo(allowedReserve, SHOTGUN_AMMO)
    end
end

local function forceSeventhShell(ply, weapon, consumeReserve, reason)
    if not IsValid(ply) or not IsValid(weapon) or weapon:GetClass() ~= SHOTGUN_CLASS then return false end
    if weapon:Clip1() >= EFFECTIVE_MAGAZINE then return true end
    if weapon:Clip1() ~= STOCK_ENGINE_MAX then return false end

    local reserve = math.max(0, ply:GetAmmoCount(SHOTGUN_AMMO))
    if consumeReserve and reserve <= 0 then return false end

    if consumeReserve then
        ply:SetAmmo(reserve - 1, SHOTGUN_AMMO)
    end
    weapon:SetClip1(EFFECTIVE_MAGAZINE)

    if weapon:Clip1() ~= EFFECTIVE_MAGAZINE then
        if consumeReserve then
            ply:SetAmmo(ply:GetAmmoCount(SHOTGUN_AMMO) + 1, SHOTGUN_AMMO)
        end
        Fix.Stats.failedSetClip = (Fix.Stats.failedSetClip or 0) + 1
        return false
    end

    clampFamily(ply, weapon)
    if reason == "acquisition" then
        Fix.Stats.acquisitionTopoffs = (Fix.Stats.acquisitionTopoffs or 0) + 1
    else
        Fix.Stats.reloadTopoffs = (Fix.Stats.reloadTopoffs or 0) + 1
    end
    return true
end

-- weapon_shotgun is a stock engine weapon whose GetMaxClip1() remains hard-coded
-- at 6 even when Lua Primary.ClipSize is changed. SetClip1(7) itself is legal, so
-- give-time topoff establishes the authored seven-shell tube without replacing the
-- stock weapon implementation.
hook.Add("WeaponEquip", "LOD_ShotgunSeventhShellEquip", function(weapon, ply)
    if not IsValid(weapon) or weapon:GetClass() ~= SHOTGUN_CLASS then return end
    timer.Simple(0, function()
        if not IsValid(ply) or not IsValid(weapon) then return end
        forceSeventhShell(ply, weapon, false, "acquisition")
    end)
end)

local function reloadTimerName(ply)
    return "LOD_ShotgunSeventhShellReload_" .. tostring(IsValid(ply) and ply:EntIndex() or 0)
end

-- The stock shell-by-shell reload stops when the engine thinks the six-shell tube
-- is full. A finite reload watcher waits for that exact state, then transfers one
-- real reserve shell into Clip1. It exists only after an explicit reload press and
-- self-terminates after at most seven seconds; there is no permanent polling loop.
hook.Add("KeyPress", "LOD_ShotgunSeventhShellReload", function(ply, key)
    if key ~= IN_RELOAD then return end
    local weapon = activeShotgun(ply)
    if not IsValid(weapon) or weapon:Clip1() >= EFFECTIVE_MAGAZINE then return end
    if ply:GetAmmoCount(SHOTGUN_AMMO) <= 0 then return end

    local timerName = reloadTimerName(ply)
    timer.Remove(timerName)

    -- If the stock tube is already at its hard-coded six-shell ceiling, this is
    -- specifically the request to insert shell seven. Give it a short authored
    -- reload presentation because the C++ weapon otherwise rejects the reload.
    if weapon:Clip1() == STOCK_ENGINE_MAX then
        timer.Simple(0.12, function()
            if not IsValid(ply) or not IsValid(weapon) or activeShotgun(ply) ~= weapon then return end
            if forceSeventhShell(ply, weapon, true, "reload") then
                weapon:SendWeaponAnim(ACT_VM_RELOAD)
                weapon:EmitSound("Weapon_Shotgun.Reload", 60, 100, 0.75, CHAN_WEAPON)
                weapon:SetNextPrimaryFire(math.max(weapon:GetNextPrimaryFire(), CurTime() + 0.45))
            end
        end)
        return
    end

    timer.Create(timerName, RELOAD_POLL_INTERVAL, RELOAD_POLL_COUNT, function()
        if not IsValid(ply) or not ply:Alive() then timer.Remove(timerName) return end
        if not IsValid(weapon) or activeShotgun(ply) ~= weapon then timer.Remove(timerName) return end
        if weapon:Clip1() >= EFFECTIVE_MAGAZINE or ply:GetAmmoCount(SHOTGUN_AMMO) <= 0 then
            timer.Remove(timerName)
            return
        end
        if weapon:Clip1() == STOCK_ENGINE_MAX then
            forceSeventhShell(ply, weapon, true, "reload")
            timer.Remove(timerName)
        end
    end)
end)

hook.Add("PlayerDeath", "LOD_ShotgunSeventhShellClear", function(ply)
    timer.Remove(reloadTimerName(ply))
end)

-- Replace the earlier diagnostic with one that distinguishes the immutable stock
-- C++ max-clip report from the effective seven-shell gameplay capacity.
concommand.Remove("lod_shotgun_ammo_status")
concommand.Add("lod_shotgun_ammo_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local clip, reserve, total, engineMax = -1, -1, -1, -1
    if IsValid(ply) then
        local weapon = ply:GetWeapon(SHOTGUN_CLASS)
        if IsValid(weapon) then
            clip = weapon:Clip1()
            reserve = ply:GetAmmoCount(SHOTGUN_AMMO)
            total = clip + reserve
            engineMax = weapon:GetMaxClip1()
        end
    end

    local result = clip < 0 or clip <= EFFECTIVE_MAGAZINE and total <= TOTAL_CAP
    local line = string.format(
        "Shotgun clip=%d engineMax=%d effectiveMag=%d reserve=%d total=%d cap=%d drops=3/5/7 acquire7=%d reload7=%d failed=%d result=%s",
        clip, engineMax, EFFECTIVE_MAGAZINE, reserve, total, TOTAL_CAP,
        Fix.Stats.acquisitionTopoffs or 0, Fix.Stats.reloadTopoffs or 0,
        Fix.Stats.failedSetClip or 0, result and "PASS" or "FAIL")
    print("[LOD:SHOTGUN-AMMO] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
