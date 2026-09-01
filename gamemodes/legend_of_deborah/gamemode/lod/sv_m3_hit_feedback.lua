LOD = LOD or {}
LOD.M3HitFeedback = LOD.M3HitFeedback or {}

local HitFeedback = LOD.M3HitFeedback
local STUN_SECONDS = 0.30
local STUN_RETRIGGER_SECONDS = 0.36

local FIREARM_CLASSES = {
    weapon_pistol = true,
    weapon_357 = true,
    weapon_smg1 = true,
    weapon_shotgun = true,
    weapon_ar2 = true
}

util.AddNetworkString("LOD_HitConfirm")

local function playerShooter(ply)
    return IsValid(ply) and ply:IsPlayer() and ply:Alive()
end

local function activeWeaponClass(ply)
    if not IsValid(ply) then return "unknown" end
    local weapon = ply:GetActiveWeapon()
    return IsValid(weapon) and weapon:GetClass() or "unknown"
end

local function firearmDamage(attacker, dmginfo)
    if not playerShooter(attacker) then return false end
    local weaponClass = activeWeaponClass(attacker)
    if FIREARM_CLASSES[weaponClass] then return true end
    return dmginfo and dmginfo:IsDamageType(DMG_BULLET)
end

local function playFlinch(hostile)
    if not IsValid(hostile) then return false end

    local activities = {ACT_BIG_FLINCH, ACT_FLINCH_CHEST, ACT_SMALL_FLINCH, ACT_FLINCH_HEAD}
    for _, activity in ipairs(activities) do
        if isnumber(activity) and hostile.SelectWeightedSequence then
            local sequence = hostile:SelectWeightedSequence(activity)
            if isnumber(sequence) and sequence >= 0 then
                hostile.LODCurrentActivity = nil
                hostile:ResetSequence(sequence)
                hostile:SetCycle(0)
                hostile:SetPlaybackRate(1)
                return true
            end
        end
    end

    for _, name in ipairs({
        "flinch", "flinch1", "flinch2", "pain",
        "flinch_phys_01", "flinch_phys_02", "flinch_phys_03", "flinch_phys_04"
    }) do
        local sequence = hostile.LookupSequence and hostile:LookupSequence(name) or -1
        if isnumber(sequence) and sequence >= 0 then
            hostile.LODCurrentActivity = nil
            hostile:ResetSequence(sequence)
            hostile:SetCycle(0)
            hostile:SetPlaybackRate(1)
            return true
        end
    end

    return false
end

local function sendHitConfirm(attacker)
    local now = CurTime()
    if now < (attacker.LODNextHitConfirm or 0) then return end
    attacker.LODNextHitConfirm = now + 0.04
    net.Start("LOD_HitConfirm")
    net.Send(attacker)
end

function HitFeedback:ApplyHitStun(hostile, durationMultiplier, attacker)
    if not IsValid(hostile) or not hostile.LODHostile or hostile.LODDead then return false end
    if hostile.LODDeadcrabState == "latched" then return false end

    local now = CurTime()
    if now < (hostile.LODNextHitStun or 0) then return false end

    local stamp = hostile.LODLastHitFeedbackEvent
    attacker = IsValid(attacker) and attacker or (stamp and stamp.attacker or nil)
    local rules = LOD.RPGAbilityRules
    local abilityMultiplier = rules and rules.HitStunMultiplier
        and rules:HitStunMultiplier(attacker, hostile) or 1
    durationMultiplier = math.Clamp((tonumber(durationMultiplier) or 1) * abilityMultiplier, 0.50, 2)
    local stunSeconds = STUN_SECONDS * durationMultiplier
    local retriggerSeconds = STUN_RETRIGGER_SECONDS + STUN_SECONDS * (durationMultiplier - 1)
    hostile.LODNextHitStun = now + retriggerSeconds
    hostile.LODHitStunUntil = now + stunSeconds

    if hostile.LODSoldierBurst then
        hostile.LODSoldierBurst = nil
        hostile:SetNW2Bool("LOD_SoldierTelegraph", false)
        hostile.LODNextAttack = math.max(hostile.LODNextAttack or 0, now + stunSeconds + 0.10)
    end

    if hostile.LODBioBlast then
        hostile.LODBioBlast = nil
        hostile.LODNextBioCharge = now + stunSeconds + 0.35
    end

    if hostile.LODArchetypeId == "deadcrab" and hostile.LODDeadcrabState == "leaping" then
        hostile.LODDeadcrabState = nil
        hostile.LODDeadcrabTarget = nil
        hostile.LODDeadcrabNextLeap = now + stunSeconds + 0.35
    end

    if hostile.loco then
        hostile.loco:SetDesiredSpeed(0)
        if hostile.loco.SetVelocity then hostile.loco:SetVelocity(vector_origin) end
    end
    hostile:SetVelocity(vector_origin)

    hostile.LODHitStunHasFlinch = playFlinch(hostile)
    return true
end

function HitFeedback:ApplyShotgunShellStun(hostile)
    -- One shared Shotgun roll may deliver up to nine pellet damage events.
    -- The roll authority aggregates those events, then calls this once per
    -- damaged target so stun can never scale with pellet count.
    return self:ApplyHitStun(hostile, 2)
end

local function activeShotgunContract(attacker)
    if not IsValid(attacker) or not attacker:IsPlayer() then return nil end
    local contract = attacker.LODActiveShotgunRoll
    if not contract or CurTime() - (contract.created or 0) >= 0.20 then return nil end
    return contract
end

function HitFeedback:HandleDamageEvent(hostile, dmginfo, source)
    if not IsValid(hostile) or not hostile.LODHostile or hostile.LODDead or not dmginfo then return false end

    local attacker = dmginfo:GetAttacker()
    if not firearmDamage(attacker, dmginfo) then return false end

    local incoming = dmginfo:GetDamage() or 0
    if incoming <= 0 then return false end

    -- EntityTakeDamage and NextBot OnInjured may both observe one impact.
    -- Collapse those observations to one gameplay response.
    local now = CurTime()
    local stamp = hostile.LODLastHitFeedbackEvent
    if stamp and stamp.attacker == attacker and now - stamp.time < 0.025 then return false end
    hostile.LODLastHitFeedbackEvent = {attacker = attacker, time = now, source = source or "unknown"}

    sendHitConfirm(attacker)

    -- EntityTakeDamage is pre-damage, so health here is the pre-impact value.
    -- Do not apply ordinary hit stun to a shot that is already lethal.
    -- Shotgun pellet damage is aggregated by the combat-roll authority. It
    -- applies one doubled stun after the shell has resolved; applying the
    -- ordinary response here would make stun depend on pellet hook timing.
    if incoming < hostile:Health() and not activeShotgunContract(attacker) then
        self:ApplyHitStun(hostile, 1, attacker)
    end
    return true
end

-- This is the primary authoritative route. It is also the exact hook used by
-- the damage audit, so combat feedback and diagnostics see the same event.
hook.Add("EntityTakeDamage", "LOD_M3_HitConfirmAndStun", function(ent, dmginfo)
    if not IsValid(ent) or not ent.LODHostile then return end
    HitFeedback:HandleDamageEvent(ent, dmginfo, "EntityTakeDamage")
end)

local function installHostilePatch()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class or class.LODHitFeedbackPatched then return false end
    class.LODHitFeedbackPatched = true

    -- Keep OnInjured as a defensive fallback for unusual addon/runtime damage
    -- paths. The dedupe above prevents a normal shot from producing two cues.
    local baseOnInjured = class.OnInjured
    function class:OnInjured(dmginfo)
        if baseOnInjured then baseOnInjured(self, dmginfo) end
        HitFeedback:HandleDamageEvent(self, dmginfo, "OnInjured")
    end

    local baseBehaviourTick = class._BehaviourTick
    function class:_BehaviourTick()
        if self.LODDead then return baseBehaviourTick(self) end

        local stunUntil = self.LODHitStunUntil or 0
        if CurTime() < stunUntil then
            if self.loco then
                self.loco:SetDesiredSpeed(0)
                if self.loco.SetVelocity then self.loco:SetVelocity(vector_origin) end
            end
            return
        end

        if self.LODHitStunUntil then
            self.LODHitStunUntil = nil
            self.LODHitStunHasFlinch = nil
            self.LODNextRouteRefresh = 0
            self.LODNextTargetRefresh = 0
            if self.loco and self.LODConfig then
                self.loco:SetDesiredSpeed(self.LODConfig.speed or 90)
            end
        end

        return baseBehaviourTick(self)
    end

    local baseBodyUpdate = class.BodyUpdate
    function class:BodyUpdate()
        if not self.LODDead and CurTime() < (self.LODHitStunUntil or 0) then
            self:FrameAdvance()
            return
        end
        return baseBodyUpdate(self)
    end

    return true
end

installHostilePatch()
hook.Add("OnEntityCreated", "LOD_HitFeedbackInstallBeforeSpawn", function(ent)
    if IsValid(ent) and ent:GetClass() == "lod_hostile" then installHostilePatch() end
end)

concommand.Add("lod_m3_hitfeedback_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local count = 0
    for _, hostile in ipairs(ents.FindByClass("lod_hostile")) do
        if IsValid(hostile) then
            count = count + 1
            local remaining = math.max(0, (hostile.LODHitStunUntil or 0) - CurTime())
            local last = hostile.LODLastHitFeedbackEvent
            local text = string.format("#%d %s hp=%d stunRemaining=%.3f nextStun=%.3f flinch=%s lastSource=%s",
                hostile:EntIndex(), tostring(hostile.LODArchetypeId), hostile:Health(), remaining,
                math.max(0, (hostile.LODNextHitStun or 0) - CurTime()),
                tostring(hostile.LODHitStunHasFlinch == true),
                last and tostring(last.source) or "none")
            print("[LOD:HIT] " .. text)
            if IsValid(ply) then ply:ChatPrint(text) end
        end
    end
    if count == 0 then
        print("[LOD:HIT] no live hostiles")
        if IsValid(ply) then ply:ChatPrint("no live hostiles") end
    end
end)

concommand.Add("lod_m3_hitconfirm_test", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if not IsValid(ply) or not ply:IsAdmin() then return end
    net.Start("LOD_HitConfirm")
    net.Send(ply)
    ply:ChatPrint("[LOD:M3] hit-confirm test cue sent")
end)

concommand.Add("lod_dice_shotgun_stun_probe", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if not IsValid(ply) or not ply:IsAdmin() then return end

    local hostile
    for _, candidate in ipairs(ents.FindByClass("lod_hostile")) do
        if IsValid(candidate) and not candidate.LODDead and candidate:Health() > 1
            and candidate.LODDeadcrabState ~= "latched" then
            hostile = candidate
            break
        end
    end
    if not IsValid(hostile) then
        local text = "no eligible live hostile result=FAIL"
        print("[LOD:DICE-SHOTGUN] " .. text)
        ply:ChatPrint(text)
        return
    end

    hostile.LODHitStunUntil = nil
    hostile.LODNextHitStun = nil
    hostile.LODLastHitFeedbackEvent = nil
    local contract = {created = CurTime()}
    ply.LODActiveShotgunRoll = contract

    local info = DamageInfo()
    info:SetAttacker(ply)
    info:SetInflictor(ply)
    info:SetDamage(1)
    info:SetDamageType(DMG_BULLET)
    HitFeedback:HandleDamageEvent(hostile, info, "shotgun-probe-pellet")
    local pelletSuppressed = not hostile.LODHitStunUntil

    if ply.LODActiveShotgunRoll == contract then ply.LODActiveShotgunRoll = nil end
    local applied = HitFeedback:ApplyShotgunShellStun(hostile)
    local remaining = math.max(0, (hostile.LODHitStunUntil or 0) - CurTime())
    local lockout = math.max(0, (hostile.LODNextHitStun or 0) - CurTime())
    local duplicateRejected = not HitFeedback:ApplyShotgunShellStun(hostile)
    local durationPass = remaining >= 0.58 and remaining <= 0.61
    local lockoutPass = lockout >= 0.64 and lockout <= 0.67
    local passed = pelletSuppressed and applied and duplicateRejected and durationPass and lockoutPass
    local text = string.format(
        "pelletSuppressed=%s shellApplied=%s duplicateRejected=%s duration=%.2f lockout=%.2f result=%s",
        tostring(pelletSuppressed), tostring(applied), tostring(duplicateRejected), remaining,
        lockout, passed and "PASS" or "FAIL")
    print("[LOD:DICE-SHOTGUN] " .. text)
    ply:ChatPrint(text)
end)
