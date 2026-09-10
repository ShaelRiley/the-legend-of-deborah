LOD = LOD or {}

local Rolls = LOD.CombatRolls
local Magnum = LOD.MagnumSuperExplosive
local Rules = LOD.RPGAbilityRules
local Specials = LOD.PlayerWeaponSpecials
if not Rolls or not Magnum or not Rules then return end

local BASE_AIM_HOLD_SECONDS = 0.50
local POSITION_EPSILON_SQR = 0.01
local ANGLE_EPSILON = 0.01
local MOVE_INPUT_EPSILON = 0.5

util.AddNetworkString("LOD_MagnumAimLocked")

local AIMABLE_CLASSES = {
    weapon_lod_crowbar = true,
    weapon_pistol = true,
    weapon_357 = true,
    weapon_smg1 = true,
    weapon_shotgun = true,
    weapon_ar2 = true,
    weapon_frag = true
}

Magnum.AimStates = Magnum.AimStates or setmetatable({}, {__mode = "k"})
Magnum.Stats = Magnum.Stats or {}
Magnum.Stats.aimLocks = Magnum.Stats.aimLocks or 0
Magnum.Stats.aimShots = Magnum.Stats.aimShots or 0
Magnum.Stats.aimCancels = Magnum.Stats.aimCancels or 0
Magnum.Stats.aimAttackInterruptions = Magnum.Stats.aimAttackInterruptions or 0

LOD.UniversalAim = LOD.UniversalAim or {}
local Aim = LOD.UniversalAim
Aim.States = Magnum.AimStates
Aim.AimableClasses = AIMABLE_CLASSES
Aim.Stats = Magnum.Stats

local function ownsDeadeye(state)
    for _, id in ipairs(state and state.featIds or {}) do
        if id == "DEX_MAGNUM_DEADEYE" then return true end
    end
    return false
end

function Aim:CanAimClass(state, weaponClass)
    if weaponClass == "weapon_357" then return true end
    return AIMABLE_CLASSES[weaponClass] == true and ownsDeadeye(state)
end

function Aim:MultiplierForClass(state, weaponClass)
    if not self:CanAimClass(state, weaponClass) then return 1 end
    if weaponClass == "weapon_357" then
        return ownsDeadeye(state) and 3 or 2
    end
    return 2
end

function LOD.AimableWeaponForState(state, weapon)
    if not weapon or not weapon.GetClass then return false end
    return Aim:CanAimClass(state, weapon:GetClass())
end

local function activeAimableWeapon(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return nil end
    local weapon = ply:GetActiveWeapon()
    if not IsValid(weapon) then return nil end
    local state = Rules.ProgressionState and Rules:ProgressionState(ply) or nil
    return Aim:CanAimClass(state, weapon:GetClass()) and weapon or nil
end

local function publishAimState(ply, armed, multiplier)
    if not IsValid(ply) then return end
    ply:SetNW2Bool("LOD_UniversalAimState", armed == true)
    ply:SetNW2Float("LOD_UniversalAimMultiplier", armed and math.max(1, tonumber(multiplier) or 1) or 1)
    ply:SetNW2Bool("LOD_MagnumAimState", armed == true)
end

local function clearAimState(ply, state, countCancel)
    if not state then return end
    if state.armed and countCancel then
        Magnum.Stats.aimCancels = (Magnum.Stats.aimCancels or 0) + 1
    end
    state.armed = false
    state.multiplier = 1
    publishAimState(ply, false, 1)
end

function Aim:ResetPlayer(ply)
    local state = self.States and self.States[ply]
    if state then clearAimState(ply, state, false) end
    if self.States then self.States[ply] = nil end
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
    if Rules.AimHoldSeconds then
        return math.max(0, tonumber(Rules:AimHoldSeconds(ply)) or BASE_AIM_HOLD_SECONDS)
    end
    return BASE_AIM_HOLD_SECONDS
end

hook.Add("StartCommand", "LOD_MagnumAimState_Input", function(ply, cmd)
    if not IsValid(ply) then return end

    local weapon = activeAimableWeapon(ply)
    local state = Aim.States[ply]
    if not IsValid(weapon) then
        if state then
            clearAimState(ply, state, true)
            Aim.States[ply] = nil
        end
        return
    end

    local now = CurTime()
    local pos = ply:GetPos()
    local ang = cmd:GetViewAngles()
    local weaponClass = weapon:GetClass()

    if not state or state.weapon ~= weapon then
        if state then clearAimState(ply, state, true) end
        state = {
            weapon = weapon,
            weaponClass = weaponClass,
            lastPos = pos,
            lastAngles = Angle(ang.p, ang.y, ang.r),
            stationarySince = now,
            armed = false,
            multiplier = 1
        }
        Aim.States[ply] = state
        publishAimState(ply, false, 1)
        return
    end

    local moved = movementInput(cmd)
        or positionChanged(state.lastPos, pos)
        or angleChanged(state.lastAngles, ang)

    state.lastPos = pos
    state.lastAngles = Angle(ang.p, ang.y, ang.r)
    state.weaponClass = weaponClass

    if moved then
        clearAimState(ply, state, true)
        state.stationarySince = now
        state.attackHeld = false
        return
    end

    local attackDown = cmd:KeyDown(IN_ATTACK)
    if not state.armed and attackDown then
        if not state.attackHeld then
            Magnum.Stats.aimAttackInterruptions = (Magnum.Stats.aimAttackInterruptions or 0) + 1
        end
        state.attackHeld = true
        state.stationarySince = now
        state.multiplier = 1
        return
    end
    state.attackHeld = attackDown

    local requiredHold = aimHoldSeconds(ply)
    if not state.armed and now - (state.stationarySince or now) >= requiredHold then
        local progressionState = Rules.ProgressionState and Rules:ProgressionState(ply) or nil
        state.armed = true
        state.multiplier = Aim:MultiplierForClass(progressionState, weaponClass)
        state.lastRequiredHoldSeconds = requiredHold
        state.lastLockElapsed = now - (state.stationarySince or now)
        publishAimState(ply, true, state.multiplier)

        Magnum.Stats.aimLocks = (Magnum.Stats.aimLocks or 0) + 1
        Magnum.Stats.lastAimHoldSeconds = requiredHold
        Magnum.Stats.lastAimLockElapsed = state.lastLockElapsed
        Magnum.Stats.lastAimWeaponClass = weaponClass
        Magnum.Stats.lastAimMultiplier = state.multiplier

        net.Start("LOD_MagnumAimLocked")
        net.Send(ply)
    end
end)

function Aim:PeekMultiplier(ply, expectedWeaponClass)
    local state = self.States and self.States[ply]
    if not state or state.weaponClass ~= expectedWeaponClass or state.armed ~= true then
        return 1, false
    end
    return math.max(1, tonumber(state.multiplier) or 1), true
end

function Aim:CommitPrimaryAttack(ply, expectedWeaponClass)
    local state = self.States and self.States[ply]
    if not state or state.weaponClass ~= expectedWeaponClass then
        return 1, false
    end

    local now = CurTime()
    if state.armed ~= true then
        state.stationarySince = now
        state.multiplier = 1
        publishAimState(ply, false, 1)
        return 1, false
    end

    local multiplier = math.max(1, tonumber(state.multiplier) or 1)
    if expectedWeaponClass == "weapon_357" and IsValid(state.weapon) then
        state.weapon.LODMagnumAimConsumedMultiplier = multiplier
    end

    clearAimState(ply, state, false)
    state.stationarySince = now
    state.multiplier = 1
    state.attackHeld = false

    Magnum.Stats.aimShots = (Magnum.Stats.aimShots or 0) + 1
    Magnum.Stats.lastAimMultiplier = multiplier
    Magnum.Stats.lastAimWeaponClass = expectedWeaponClass
    return multiplier, true
end

function LOD.ConsumeAimState(ply, weapon)
    if not IsValid(weapon) then return 1 end
    local multiplier = Aim:CommitPrimaryAttack(ply, weapon:GetClass())
    return multiplier
end

if Specials and isfunction(Specials.BeginAR2Burst) and not Specials.LODUniversalAimBurstWrapped then
    Specials.LODUniversalAimBurstWrapped = true
    local baseBeginAR2Burst = Specials.BeginAR2Burst

    function Specials:BeginAR2Burst(ply, weapon, direction)
        local started = baseBeginAR2Burst(self, ply, weapon, direction)
        if not started then return false end

        local multiplier, aimed = Aim:CommitPrimaryAttack(ply, "weapon_ar2")
        local playerState = self.PlayerState and self.PlayerState[ply]
        local ar2 = playerState and playerState.ar2
        if ar2 then
            ar2.LODUniversalAimMultiplier = multiplier
            ar2.LODUniversalAimState = aimed == true
        end
        return true
    end
end

if not Rolls.LODMagnumAimDamageInstalled then
    Rolls.LODMagnumAimDamageInstalled = true
    local baseRollPlayerWeapon = Rolls.RollPlayerWeapon

    function Rolls:RollPlayerWeapon(ply, weaponClass)
        local contract = baseRollPlayerWeapon(self, ply, weaponClass)
        if not contract then return contract end

        local weapon = IsValid(ply) and ply:GetActiveWeapon() or nil
        if not IsValid(weapon) or weapon:GetClass() ~= weaponClass then return contract end

        local multiplier = 1
        if weaponClass == "weapon_357" and weapon.LODMagnumInjectedBurst == true then
            local burst = Magnum.Bursts and Magnum.Bursts[ply]
            multiplier = burst and tonumber(burst.aimMultiplier) or 1
        elseif weaponClass == "weapon_357" then
            multiplier = tonumber(weapon.LODMagnumAimConsumedMultiplier) or 1
            if multiplier <= 1 then
                multiplier = select(1, Aim:CommitPrimaryAttack(ply, weaponClass))
            end
        elseif weaponClass == "weapon_ar2" then
            local playerState = Specials and Specials.PlayerState and Specials.PlayerState[ply]
            local ar2 = playerState and playerState.ar2
            if ar2 and ar2.active then
                multiplier = math.max(1, tonumber(ar2.LODUniversalAimMultiplier) or 1)
            else
                multiplier = select(1, Aim:CommitPrimaryAttack(ply, weaponClass))
            end
        else
            multiplier = select(1, Aim:CommitPrimaryAttack(ply, weaponClass))
        end

        if multiplier > 1 then
            contract.aimState = true
            contract.aimMultiplier = multiplier
        end
        return contract
    end
end

if not Rolls.LODUniversalAimShotgunResolveInstalled then
    Rolls.LODUniversalAimShotgunResolveInstalled = true
    local baseResolveActorDamage = Rolls.ResolveActorDamage

    function Rolls:ResolveActorDamage(contract, attacker, target, tags)
        if contract and contract.weaponClass == "weapon_shotgun"
            and tonumber(contract.aimMultiplier) and tonumber(contract.aimMultiplier) > 1
            and (not tags or tags.authoredScale == nil)
        then
            local resolvedTags = table.Copy(tags or {})
            resolvedTags.authoredScale = tonumber(contract.aimMultiplier) or 1
            return baseResolveActorDamage(self, contract, attacker, target, resolvedTags)
        end
        return baseResolveActorDamage(self, contract, attacker, target, tags)
    end
end

if not Magnum.LODMagnumAimBurstWrapped then
    local fireHooks = hook.GetTable().EntityFireBullets
    local baseBurstHook = fireHooks and fireHooks["LOD_MagnumCylinderBurst"] or nil
    if baseBurstHook then
        Magnum.LODMagnumAimBurstWrapped = true
        hook.Add("EntityFireBullets", "LOD_MagnumCylinderBurst", function(shooter, bullet)
            local weapon = IsValid(shooter) and shooter:GetActiveWeapon() or nil
            if not IsValid(weapon) or weapon:GetClass() ~= "weapon_357"
                or weapon.LODMagnumInjectedBurst == true
            then
                return baseBurstHook(shooter, bullet)
            end

            local multiplier = tonumber(weapon.LODMagnumAimConsumedMultiplier) or 1
            if multiplier <= 1 then
                multiplier = select(1, Aim:CommitPrimaryAttack(shooter, "weapon_357"))
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

hook.Add("EntityFireBullets", "LOD_MagnumAimState_TriggerMarkerCleanup", function(shooter)
    local weapon = IsValid(shooter) and shooter:GetActiveWeapon() or nil
    if not IsValid(weapon) or weapon:GetClass() ~= "weapon_357"
        or not weapon.LODMagnumAimConsumedMultiplier
    then
        return
    end
    timer.Simple(0, function()
        if IsValid(weapon) then weapon.LODMagnumAimConsumedMultiplier = nil end
    end)
end)

if not Rolls.LODMagnumAimDetailInstalled then
    Rolls.LODMagnumAimDetailInstalled = true
    local basePlayerRollDetail = Rolls._PlayerRollDetail

    function Rolls:_PlayerRollDetail(contract)
        local detail = basePlayerRollDetail(self, contract)
        if contract and contract.aimState then
            local multStr = "x" .. tostring(math.max(1, math.floor(tonumber(contract.aimMultiplier) or 1)))
            if detail and detail ~= "" then
                return string.sub(detail, 1, -2) .. "; AIM " .. multStr .. "]"
            end
            return "[AIM " .. multStr .. "]"
        end
        return detail
    end
end

hook.Add("PlayerDeath", "LOD_MagnumAimState_Death", function(ply)
    Aim:ResetPlayer(ply)
end)

hook.Add("PlayerDisconnected", "LOD_MagnumAimState_Disconnect", function(ply)
    Aim:ResetPlayer(ply)
end)

concommand.Add("lod_magnum_aim_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local state = IsValid(ply) and Aim.States and Aim.States[ply] or nil
    local line = string.format(
        "hold=%.2fs multiplier=x%d armed=%s weapon=%s locks=%d aimedShots=%d cancels=%d interruptions=%d result=%s",
        aimHoldSeconds(ply),
        math.max(1, math.floor(tonumber(state and state.multiplier) or 1)),
        tostring(state and state.armed == true or false),
        tostring(state and state.weaponClass or "none"),
        Magnum.Stats.aimLocks or 0,
        Magnum.Stats.aimShots or 0,
        Magnum.Stats.aimCancels or 0,
        Magnum.Stats.aimAttackInterruptions or 0,
        (Magnum.Stats.aimLocks or 0) > 0 and "PASS" or "WAITING")
    print("[LOD:MAGNUM-AIM] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)

local function bindFragAimSnapshot(ent)
    if not IsValid(ent) or ent:GetClass() ~= "npc_grenade_frag"
        or ent.LODDeadeyeAimSnapshotBound
    then
        return false
    end
    local owner = ent:GetOwner()
    if not IsValid(owner) or not owner:IsPlayer() then return false end

    local multiplier, aimed = Aim:CommitPrimaryAttack(owner, "weapon_frag")
    ent.LODDeadeyeAimSnapshotBound = true
    if aimed and multiplier > 1 then
        ent.LODAimMultiplier = multiplier
        Magnum.Stats.lastFragAimMultiplier = multiplier
    end
    return true
end

hook.Add("OnEntityCreated", "LOD_AimState_GrenadeFrag", function(ent)
    if not IsValid(ent) or ent:GetClass() ~= "npc_grenade_frag" then return end
    if bindFragAimSnapshot(ent) then return end
    timer.Simple(0, function()
        if not IsValid(ent) then return end
        if bindFragAimSnapshot(ent) then return end
        timer.Simple(0.05, function()
            if IsValid(ent) then bindFragAimSnapshot(ent) end
        end)
    end)
end)

include("sv_deadeye_validation.lua")
