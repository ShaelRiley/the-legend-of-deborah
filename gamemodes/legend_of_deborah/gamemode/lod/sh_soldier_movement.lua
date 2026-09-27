-- SPOT-17 projection inside the existing input/movement authorities. No timer,
-- player-speed mutation, retained actor state, teleport or parallel locomotion.
LOD.SoldierMovement = LOD.SoldierMovement or {}
local Movement = LOD.SoldierMovement

function Movement:Active(ply)
    -- Read-only progression/snapshot actors are not native controllable bodies.
    if not IsValid(ply) or not ply.IsPlayer or not ply:IsPlayer()
        or not ply.Alive or not ply:Alive() then return false end
    if SERVER then
        local run = LOD.RunManager
        if not run or not run.IsSoldierControl or not run:IsSoldierControl(ply) then return false end
    elseif not ply:GetNW2Bool("LOD_IsSoldier", false) then return false end
    if not ply.GetNW2Bool or ply:GetNW2Bool("LOD_Staged", false)
        or not ply:GetNW2Bool("LOD_Deployed", false)
        or ply:GetNW2Bool("LOD_SoldierWaiting", false) then return false end
    if ply.GetObserverMode and ply:GetObserverMode() ~= OBS_MODE_NONE then return false end
    return true
end

function Movement:BaseSpeed()
    local config = LOD.Config.Encounter.Archetypes.soldier
    return math.max(0, tonumber(config.speed) or 0)
end

function Movement:Locked(ply)
    if not self:Active(ply) then
        if SERVER then
            local specials = LOD.PlayerWeaponSpecials
            local state = specials and specials.PlayerState[ply]
            if state and state.ar2 and state.ar2.soldierBinding then specials:CancelSoldierAR2(ply, state) end
        end
        return false, 0
    end
    if SERVER then
        local specials = LOD.PlayerWeaponSpecials
        if specials and specials.SoldierMovementLock then return specials:SoldierMovementLock(ply) end
        return false, 0
    end
    local deadline = ply:GetNW2Float("LOD_SoldierRootUntil", 0)
    local context = ply:GetNW2String("LOD_TeamMenuContext", "")
    local weapon = ply:GetActiveWeapon()
    local valid = deadline > CurTime() and context ~= ""
        and ply:GetNW2String("LOD_SoldierRootContext", "") == context
        and IsValid(weapon) and weapon:GetClass() == "weapon_ar2"
        and ply:GetNW2Entity("LOD_SoldierRootWeapon") == weapon
    return valid, valid and deadline or 0
end

function Movement:ClearProjection(ply)
    if not SERVER or not IsValid(ply) then return end
    ply:SetNW2Float("LOD_SoldierRootUntil", 0)
    ply:SetNW2String("LOD_SoldierRootContext", "")
    ply:SetNW2Entity("LOD_SoldierRootWeapon", NULL)
    ply:SetNW2Float("LOD_SoldierForcedUntil", 0)
end

function Movement:Publish(ply)
    if not SERVER or not IsValid(ply) then return end
    local locked, deadline = self:Locked(ply)
    if not locked then self:ClearProjection(ply); return end
    ply:SetNW2Float("LOD_SoldierRootUntil", deadline)
    ply:SetNW2String("LOD_SoldierRootContext", LOD.RunManager:TeamMenuContext(ply))
    ply:SetNW2Entity("LOD_SoldierRootWeapon", ply:GetActiveWeapon())
    ply:SetNW2Float("LOD_SoldierForcedUntil", tonumber(ply.LODForcedMovementUntil) or 0)
end

function Movement:FilterInput(ply, input, locked)
    if not self:Active(ply) then return end
    if locked == nil then locked = self:Locked(ply) end
    local function remove(key)
        if input.RemoveKey then input:RemoveKey(key)
        else input:SetButtons(bit.band(input:GetButtons(), bit.bnot(key))) end
    end
    remove(IN_SPEED)
    if locked or ply:OnGround() then remove(IN_JUMP) end
    if locked then
        remove(IN_FORWARD); remove(IN_BACK); remove(IN_MOVELEFT); remove(IN_MOVERIGHT)
        if input.ClearMovement then input:ClearMovement() end
    end
end

-- Apply BEFORE existing DEX/status/Haste and directional modifiers, so they
-- compose once instead of being neutralized by a late absolute Soldier cap.
function Movement:PrepareMove(ply, move)
    if not self:Active(ply) then return false end
    local locked = self:Locked(ply)
    self:FilterInput(ply, move, locked)
    local base = self:BaseSpeed()
    move:SetMaxClientSpeed(math.min(move:GetMaxClientSpeed(), base))
    move:SetMaxSpeed(math.min(move:GetMaxSpeed(), base))
    return locked
end

function Movement:ApplyRoot(ply, move)
    move:SetForwardSpeed(0); move:SetSideSpeed(0); move:SetUpSpeed(0)
    move:SetMaxClientSpeed(0); move:SetMaxSpeed(0)
    local forcedUntil = SERVER and (tonumber(ply.LODForcedMovementUntil) or 0)
        or ply:GetNW2Float("LOD_SoldierForcedUntil", 0)
    if CurTime() >= forcedUntil then
        local velocity = move:GetVelocity()
        -- Source still owns gravity, vertical fall, collision and base velocity.
        -- Never use Freeze, SetPos or SetMoveType to implement an attack root.
        move:SetVelocity(Vector(0, 0, velocity.z))
    end
end

function Movement:DodgeTarget(ply, rules)
    return math.min(520, self:BaseSpeed() * rules:MovementMultiplier(ply))
end
