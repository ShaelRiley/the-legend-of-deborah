LOD = LOD or {}
LOD.M3HitFeedback = LOD.M3HitFeedback or {}

local HitFeedback = LOD.M3HitFeedback
local STUN_SECONDS = 0.16
local STUN_RETRIGGER_SECONDS = 0.24

util.AddNetworkString("LOD_HitConfirm")

local stunned = setmetatable({}, {__mode = "k"})

local function bulletDamage(dmginfo)
    return dmginfo and dmginfo:IsDamageType(DMG_BULLET)
end

local function activeShooter(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    if LOD.RunManager and LOD.RunManager.IsActivePlayer then
        return LOD.RunManager:IsActivePlayer(ply)
    end
    return ply:Alive()
end

local function playFlinch(hostile)
    local activities = {ACT_BIG_FLINCH, ACT_FLINCH_CHEST, ACT_SMALL_FLINCH, ACT_FLINCH_HEAD}
    for _, activity in ipairs(activities) do
        if isnumber(activity) and hostile.SelectWeightedSequence then
            local sequence = hostile:SelectWeightedSequence(activity)
            if isnumber(sequence) and sequence >= 0 then
                hostile:ResetSequence(sequence)
                hostile:SetCycle(0)
                hostile:SetPlaybackRate(1)
                return
            end
        end
    end
end

local function sendHitConfirm(attacker)
    local now = CurTime()
    if now < (attacker.LODNextHitConfirm or 0) then return end
    attacker.LODNextHitConfirm = now + 0.035
    net.Start("LOD_HitConfirm")
    net.Send(attacker)
end

function HitFeedback:ApplyHitStun(hostile)
    if not IsValid(hostile) or not hostile.LODHostile or hostile.LODDead then return end
    if hostile.LODDeadcrabState == "latched" then return end

    local now = CurTime()
    if now < (hostile.LODNextHitStun or 0) then return end

    hostile.LODNextHitStun = now + STUN_RETRIGGER_SECONDS
    hostile.LODHitStunUntil = now + STUN_SECONDS
    hostile.LODHitStunWasActivated = hostile.LODActivated ~= false
    hostile.LODActivated = false
    stunned[hostile] = true

    -- Being shot is a real interruption. Cancel telegraphed ranged attacks
    -- rather than allowing them to release through the visible flinch.
    if hostile.LODSoldierBurst then
        hostile.LODSoldierBurst = nil
        hostile:SetNW2Bool("LOD_SoldierTelegraph", false)
        hostile.LODNextAttack = math.max(hostile.LODNextAttack or 0, now + 0.25)
    end

    if hostile.LODBioBlast then
        hostile.LODBioBlast = nil
        hostile.LODNextBioCharge = now + 0.55
    end

    -- A Deadcrab can be knocked out of a leap, but once it is latched the fuse
    -- is committed and does not pause from teammate fire.
    if hostile.LODArchetypeId == "deadcrab" and hostile.LODDeadcrabState == "leaping" then
        hostile.LODDeadcrabState = nil
        hostile.LODDeadcrabTarget = nil
        hostile.LODDeadcrabNextLeap = now + 0.55
    end

    if hostile.loco then
        hostile.loco:SetDesiredSpeed(0)
        if hostile.loco.SetVelocity then hostile.loco:SetVelocity(vector_origin) end
    end

    playFlinch(hostile)
end

hook.Add("EntityTakeDamage", "LOD_M3_HitConfirmAndStun", function(ent, dmginfo)
    if not IsValid(ent) or not ent.LODHostile or ent.LODDead then return end
    if not bulletDamage(dmginfo) then return end

    local attacker = dmginfo:GetAttacker()
    if not activeShooter(attacker) then return end

    local incoming = dmginfo:GetDamage() or 0
    if incoming <= 0 then return end

    sendHitConfirm(attacker)

    -- Lethal hits transition directly into the established blinking pain-pose
    -- death presentation. Nonlethal hits receive the momentary combat flinch.
    if incoming < ent:Health() then
        HitFeedback:ApplyHitStun(ent)
    end
end)

hook.Add("Think", "LOD_M3_HitStunRestore", function()
    local now = CurTime()
    for hostile in pairs(stunned) do
        if not IsValid(hostile) or hostile.LODDead then
            stunned[hostile] = nil
        elseif now >= (hostile.LODHitStunUntil or 0) then
            hostile.LODActivated = hostile.LODHitStunWasActivated ~= false
            hostile.LODHitStunWasActivated = nil
            hostile.LODHitStunUntil = nil
            hostile.LODNextRouteRefresh = 0
            hostile.LODNextTargetRefresh = 0
            if hostile.loco and hostile.LODConfig then
                hostile.loco:SetDesiredSpeed(hostile.LODConfig.speed or 90)
            end
            stunned[hostile] = nil
        end
    end
end)
