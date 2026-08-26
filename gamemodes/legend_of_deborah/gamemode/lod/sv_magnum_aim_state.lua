LOD = LOD or {}

local Rolls = LOD.CombatRolls
local Magnum = LOD.MagnumSuperExplosive
if not Rolls or not Magnum then return end

local AIM_HOLD_SECONDS = 0.50
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

local function activeMagnum(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return nil end
    local weapon = ply:GetActiveWeapon()
    if not IsValid(weapon) or weapon:GetClass() ~= "weapon_357" then return nil end
    return weapon
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

-- StartCommand is already the authoritative player-input cadence. This adds only
-- O(1) work for a player who currently has the Magnum equipped: compare one
-- position, one view angle, and movement input, then arm after 0.5 s of complete
-- stillness. Movement intent cancels immediately, even before position changes.
hook.Add("StartCommand", "LOD_MagnumAimState_Input", function(ply, cmd)
    if not IsValid(ply) then return end

    local weapon = activeMagnum(ply)
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

    if not state.armed and now - (state.stationarySince or now) >= AIM_HOLD_SECONDS then
        state.armed = true
        ply:SetNW2Bool("LOD_MagnumAimState", true)
        Magnum.Stats.aimLocks = (Magnum.Stats.aimLocks or 0) + 1

        net.Start("LOD_MagnumAimLocked")
        net.Send(ply)
    end
end)

-- Install Aim State at the roll-service layer rather than relying on relative
-- EntityFireBullets hook order. Every real Magnum projectile asks this wrapper
-- for its contract. The first projectile consumes the armed state; injected
-- burst projectiles inherit the multiplier saved on their active burst.
if not Rolls.LODMagnumAimDamageInstalled then
    Rolls.LODMagnumAimDamageInstalled = true
    local baseRollPlayerWeapon = Rolls.RollPlayerWeapon

    function Rolls:RollPlayerWeapon(ply, weaponClass)
        local contract = baseRollPlayerWeapon(self, ply, weaponClass)
        if weaponClass ~= "weapon_357" or not contract then return contract end

        local weapon = activeMagnum(ply)
        if not IsValid(weapon) then return contract end

        local multiplier = 1
        local injected = weapon.LODMagnumInjectedBurst == true
        if injected then
            local burst = Magnum.Bursts and Magnum.Bursts[ply]
            multiplier = burst and tonumber(burst.aimMultiplier) or 1
        else
            local state = Magnum.AimStates and Magnum.AimStates[ply]
            if state and state.armed then
                multiplier = AIM_DAMAGE_MULTIPLIER
                -- Leave a one-trigger marker for the cylinder-burst hook. If that
                -- hook runs before this wrapper, it can still read state.armed;
                -- if it runs after, it reads this marker. No hook ordering needed.
                weapon.LODMagnumAimConsumedMultiplier = multiplier
                clearAimState(ply, state, false)
                state.stationarySince = CurTime()
                Magnum.Stats.aimShots = (Magnum.Stats.aimShots or 0) + 1
            end
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
            local weapon = activeMagnum(shooter)
            local multiplier = 1
            if IsValid(weapon) and not weapon.LODMagnumInjectedBurst then
                local state = Magnum.AimStates and Magnum.AimStates[shooter]
                multiplier = tonumber(weapon.LODMagnumAimConsumedMultiplier)
                    or (state and state.armed and AIM_DAMAGE_MULTIPLIER)
                    or 1
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
    local weapon = activeMagnum(shooter)
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
        if contract and contract.weaponClass == "weapon_357" and contract.aimState then
            if detail and detail ~= "" then
                return string.sub(detail, 1, -2) .. "; AIM x2]"
            end
            return "[AIM x2]"
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
        AIM_HOLD_SECONDS,
        AIM_DAMAGE_MULTIPLIER,
        tostring(state and state.armed == true or false),
        Magnum.Stats.aimLocks or 0,
        Magnum.Stats.aimShots or 0,
        Magnum.Stats.aimCancels or 0,
        (Magnum.Stats.aimLocks or 0) > 0 and "PASS" or "WAITING")
    print("[LOD:MAGNUM-AIM] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
