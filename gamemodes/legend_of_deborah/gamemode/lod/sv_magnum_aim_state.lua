LOD = LOD or {}

local Rolls = LOD.CombatRolls
local Magnum = LOD.MagnumSuperExplosive
if not Rolls or not Magnum then return end

local BASE_AIM_HOLD_SECONDS = 0.50
local AIM_DAMAGE_MULTIPLIER = 2
local POSITION_EPSILON_SQR = 0.01
local ANGLE_EPSILON = 0.01
local MOVE_INPUT_EPSILON = 0.5

util.AddNetworkString("LOD_MagnumAimLocked")

Magnum.AimStates = Magnum.AimStates or setmetatable({}, {__mode = "k"})
Magnum.Stats = Magnum.Stats or {}
Magnum.Stats.aimLocks = Magnum.Stats.aimLocks or 0
Magnum.Stats.aimShots = Magnum.Stats.aimShots or 0
Magnum.Stats.aimCancels = Magnum.Stats.aimCancels or 0

local AIMABLE_CLASSES = {
    weapon_lod_crowbar = true,
    weapon_pistol = true,
    weapon_357 = true,
    weapon_smg1 = true,
    weapon_shotgun = true,
    weapon_ar2 = true,
    weapon_frag = true
}

local function activeAimableWeapon(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return nil end
    local weapon = ply:GetActiveWeapon()
    if not IsValid(weapon) then return nil end
    local class = weapon:GetClass()
    if not AIMABLE_CLASSES[class] then return nil end
    if class == "weapon_357" then return weapon end

    local rules = LOD.RPGAbilityRules
    local state = rules and rules.ProgressionState and rules:ProgressionState(ply)
    if state and state.featIds then
        for _, id in ipairs(state.featIds) do
            if id == "DEX_MAGNUM_DEADEYE" then return weapon end
        end
    end
    return nil
end

local function clearAimState(ply, state, countCancel)
    if not state then return end
    if state.armed and countCancel then
        Magnum.Stats.aimCancels = (Magnum.Stats.aimCancels or 0) + 1
    end
    state.armed = false
    if IsValid(ply) then ply:SetNW2Bool("LOD_MagnumAimState", false) end
end

local function angleChanged(previous, current)
    if not previous or not current then return false end
    return math.abs(math.AngleDifference(current.p, previous.p)) > ANGLE_EPSILON
        or math.abs(math.AngleDifference(current.y, previous.y)) > ANGLE_EPSILON
end

local function positionChanged(previous, current)
    return previous and current and previous:DistToSqr(current) > POSITION_EPSILON_SQR
end

local function movementInput(cmd)
    if math.abs(cmd:GetForwardMove()) > MOVE_INPUT_EPSILON then return true end
    if math.abs(cmd:GetSideMove()) > MOVE_INPUT_EPSILON then return true end
    if math.abs(cmd:GetUpMove()) > MOVE_INPUT_EPSILON then return true end
    return cmd:KeyDown(IN_JUMP)
end

local function aimHoldSeconds(ply)
    return BASE_AIM_HOLD_SECONDS
end

-- StartCommand is already the authoritative player-input cadence. This adds only
-- O(1) work for a player who currently has the Magnum equipped: compare one
-- position, one view angle, and movement input, then arm after 0.5 s of complete
-- stillness. Deadeye changes only that required duration. Movement intent
-- cancels immediately, even before position changes.
hook.Add("StartCommand", "LOD_MagnumAimState_Input", function(ply, cmd)
    if not IsValid(ply) then return end

    local weapon = activeAimableWeapon(ply)
    local state = Magnum.AimStates[ply]
    if not IsValid(weapon) then
        if state then
            clearAimState(ply, state, true)
            Magnum.AimStates[ply] = nil
        end
        return
    end

    local now = CurTime()
    local pos = ply:GetPos()
    local ang = cmd:GetViewAngles()

    if not state or state.weapon ~= weapon then
        if state then clearAimState(ply, state, true) end
        state = {
            weapon = weapon,
            lastPos = pos,
            lastAngles = Angle(ang.p, ang.y, ang.r),
            stationarySince = now,
            armed = false
        }
        Magnum.AimStates[ply] = state
        ply:SetNW2Bool("LOD_MagnumAimState", false)
        return
    end

    local moved = movementInput(cmd)
        or positionChanged(state.lastPos, pos)
        or angleChanged(state.lastAngles, ang)

    state.lastPos = pos
    state.lastAngles = Angle(ang.p, ang.y, ang.r)

    if moved then
        clearAimState(ply, state, true)
        state.stationarySince = now
        return
    end

    local requiredHold = aimHoldSeconds(ply)
    if not state.armed and now - (state.stationarySince or now) >= requiredHold then
        state.armed = true
        state.lastRequiredHoldSeconds = requiredHold
        state.lastLockElapsed = now - (state.stationarySince or now)
        ply:SetNW2Bool("LOD_MagnumAimState", true)
        Magnum.Stats.aimLocks = (Magnum.Stats.aimLocks or 0) + 1
        Magnum.Stats.lastAimHoldSeconds = requiredHold
        Magnum.Stats.lastAimLockElapsed = state.lastLockElapsed

        net.Start("LOD_MagnumAimLocked")
        net.Send(ply)
    end
end)

-- Install Aim State at the roll-service layer rather than relying on relative
-- EntityFireBullets hook order. Every real Magnum projectile asks this wrapper
-- for its contract. The first projectile consumes the armed state; injected
-- burst projectiles inherit the multiplier saved on their active burst.
function LOD.ConsumeAimState(ply, weapon)
    local state = Magnum.AimStates and Magnum.AimStates[ply]
    if not state or not state.armed or state.weapon ~= weapon then return 1 end

    local multiplier = AIM_DAMAGE_MULTIPLIER
    local class = weapon:GetClass()
    if class == "weapon_357" then
        local rules = LOD.RPGAbilityRules
        local prog = rules and rules.ProgressionState and rules:ProgressionState(ply)
        if prog and prog.featIds then
            for _, id in ipairs(prog.featIds) do
                if id == "DEX_MAGNUM_DEADEYE" then
                    multiplier = 3
                    break
                end
            end
        end
    end

    weapon.LODMagnumAimConsumedMultiplier = multiplier
    clearAimState(ply, state, false)
    state.stationarySince = CurTime()
    Magnum.Stats.aimShots = (Magnum.Stats.aimShots or 0) + 1
    return multiplier
end

if not Rolls.LODMagnumAimDamageInstalled then
    Rolls.LODMagnumAimDamageInstalled = true
    local baseRollPlayerWeapon = Rolls.RollPlayerWeapon

    function Rolls:RollPlayerWeapon(ply, weaponClass)
        local contract = baseRollPlayerWeapon(self, ply, weaponClass)
        if not contract then return contract end

        local weapon = activeAimableWeapon(ply)
        if not IsValid(weapon) or weapon:GetClass() ~= weaponClass then return contract end

        local multiplier = 1
        local injected = weapon.LODMagnumInjectedBurst == true
        if injected then
            local burst = Magnum.Bursts and Magnum.Bursts[ply]
            multiplier = burst and tonumber(burst.aimMultiplier) or 1
        else
            multiplier = LOD.ConsumeAimState(ply, weapon)
        end

        if multiplier > 1 then
            contract.aimState = true
            contract.aimMultiplier = multiplier
            contract.total = math.max(1, (tonumber(contract.total) or 1) * multiplier)
        end

        return contract
    end
end

-- Wrap the already-authored burst hook rather than adding a second burst
-- authority. Snapshot Aim State before the base hook executes. If the roll layer
-- has already consumed Aim State, the temporary marker carries the same value;
-- if the burst hook happens first, state.armed still carries it. This is robust
-- to GMod's unspecified relative hook iteration order.
if not Magnum.LODMagnumAimBurstWrapped then
    local fireHooks = hook.GetTable().EntityFireBullets
    local baseBurstHook = fireHooks and fireHooks["LOD_MagnumCylinderBurst"] or nil
    if baseBurstHook then
        Magnum.LODMagnumAimBurstWrapped = true
        hook.Add("EntityFireBullets", "LOD_MagnumCylinderBurst", function(shooter, bullet)
            local weapon = activeAimableWeapon(shooter)
            local multiplier = 1
            if IsValid(weapon) and not weapon.LODMagnumInjectedBurst then
                multiplier = tonumber(weapon.LODMagnumAimConsumedMultiplier)
                    or LOD.ConsumeAimState(shooter, weapon)
            end

            local result = baseBurstHook(shooter, bullet)
            if multiplier > 1 then
                local burst = Magnum.Bursts and Magnum.Bursts[shooter]
                if burst then burst.aimMultiplier = multiplier end
            end
            return result
        end)
    end
end

-- The trigger marker only has to survive the EntityFireBullets dispatch that
-- caused it. Clear it on the next tick so it cannot leak into a later shot.
hook.Add("EntityFireBullets", "LOD_MagnumAimState_TriggerMarkerCleanup", function(shooter)
    local weapon = activeAimableWeapon(shooter)
    if not IsValid(weapon) or not weapon.LODMagnumAimConsumedMultiplier then return end
    timer.Simple(0, function()
        if IsValid(weapon) then weapon.LODMagnumAimConsumedMultiplier = nil end
    end)
end)

-- Append Aim State to the existing Magnum roll detail so combat-feed evidence
-- distinguishes an ordinary hit from a deliberate x2 focused shot.
if not Rolls.LODMagnumAimDetailInstalled then
    Rolls.LODMagnumAimDetailInstalled = true
    local basePlayerRollDetail = Rolls._PlayerRollDetail

    function Rolls:_PlayerRollDetail(contract)
        local detail = basePlayerRollDetail(self, contract)
        if contract and contract.aimState then
            local multStr = contract.aimMultiplier == 3 and "x3" or "x2"
            if detail and detail ~= "" then
                return string.sub(detail, 1, -2) .. "; AIM " .. multStr .. "]"
            end
            return "[AIM " .. multStr .. "]"
        end
        return detail
    end
end

hook.Add("PlayerDeath", "LOD_MagnumAimState_Death", function(ply)
    local state = Magnum.AimStates and Magnum.AimStates[ply]
    if state then clearAimState(ply, state, false) end
    if Magnum.AimStates then Magnum.AimStates[ply] = nil end
end)

hook.Add("PlayerDisconnected", "LOD_MagnumAimState_Disconnect", function(ply)
    if Magnum.AimStates then Magnum.AimStates[ply] = nil end
end)

concommand.Add("lod_magnum_aim_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local state = IsValid(ply) and Magnum.AimStates and Magnum.AimStates[ply] or nil
    local line = string.format(
        "hold=%.2fs multiplier=x%d armed=%s locks=%d aimedShots=%d cancels=%d result=%s",
        aimHoldSeconds(ply),
        AIM_DAMAGE_MULTIPLIER,
        tostring(state and state.armed == true or false),
        Magnum.Stats.aimLocks or 0,
        Magnum.Stats.aimShots or 0,
        Magnum.Stats.aimCancels or 0,
        (Magnum.Stats.aimLocks or 0) > 0 and "PASS" or "WAITING")
    print("[LOD:MAGNUM-AIM] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)

hook.Add("OnEntityCreated", "LOD_AimState_GrenadeFrag", function(ent)
    if not IsValid(ent) or ent:GetClass() ~= "npc_grenade_frag" then return end
    timer.Simple(0, function()
        if not IsValid(ent) then return end
        local owner = ent:GetOwner()
        if not IsValid(owner) or not owner:IsPlayer() then return end
        local weapon = owner:GetWeapon("weapon_frag")
        if IsValid(weapon) then
            local multiplier = LOD.ConsumeAimState(owner, weapon)
            if multiplier > 1 then
                ent.LODAimMultiplier = multiplier
            end
        end
    end)
end)

if SERVER then
    include("sv_deadeye_validation.lua")
end
