LOD = LOD or {}
LOD.M3HitFeedback = LOD.M3HitFeedback or {}

local HitFeedback = LOD.M3HitFeedback
local STUN_SECONDS = 0.22
local STUN_RETRIGGER_SECONDS = 0.28

util.AddNetworkString("LOD_HitConfirm")

local function bulletDamage(dmginfo)
    return dmginfo and dmginfo:IsDamageType(DMG_BULLET)
end

local function playerShooter(ply)
    return IsValid(ply) and ply:IsPlayer() and ply:Alive()
end

local function playFlinch(hostile)
    if not IsValid(hostile) then return false end

    -- Prefer model-supported activity translation. StartActivity is more robust
    -- on NextBots than manually resetting a sequence which BodyUpdate may then
    -- immediately reinterpret as locomotion.
    local activities = {ACT_BIG_FLINCH, ACT_FLINCH_CHEST, ACT_SMALL_FLINCH, ACT_FLINCH_HEAD}
    for _, activity in ipairs(activities) do
        if isnumber(activity) and hostile.SelectWeightedSequence then
            local sequence = hostile:SelectWeightedSequence(activity)
            if isnumber(sequence) and sequence >= 0 then
                hostile.LODCurrentActivity = nil
                hostile:StartActivity(activity)
                hostile:SetPlaybackRate(1)
                return true
            end
        end
    end

    -- Defensive model-specific fallbacks for Source NPC models whose activity
    -- table does not expose a conventional ACT_FLINCH mapping.
    for _, name in ipairs({"flinch", "flinch_phys_01", "flinch_phys_02", "flinch_phys_03", "flinch_phys_04"}) do
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

function HitFeedback:ApplyHitStun(hostile)
    if not IsValid(hostile) or not hostile.LODHostile or hostile.LODDead then return false end
    if hostile.LODDeadcrabState == "latched" then return false end

    local now = CurTime()
    if now < (hostile.LODNextHitStun or 0) then return false end

    hostile.LODNextHitStun = now + STUN_RETRIGGER_SECONDS
    hostile.LODHitStunUntil = now + STUN_SECONDS

    -- A hit explicitly interrupts telegraphed/committed normal attacks. The
    -- Deadcrab's latched fuse remains the intentional exception.
    if hostile.LODSoldierBurst then
        hostile.LODSoldierBurst = nil
        hostile:SetNW2Bool("LOD_SoldierTelegraph", false)
        hostile.LODNextAttack = math.max(hostile.LODNextAttack or 0, now + STUN_SECONDS + 0.10)
    end

    if hostile.LODBioBlast then
        hostile.LODBioBlast = nil
        hostile.LODNextBioCharge = now + STUN_SECONDS + 0.35
    end

    if hostile.LODArchetypeId == "deadcrab" and hostile.LODDeadcrabState == "leaping" then
        hostile.LODDeadcrabState = nil
        hostile.LODDeadcrabTarget = nil
        hostile.LODDeadcrabNextLeap = now + STUN_SECONDS + 0.35
    end

    if hostile.loco then
        hostile.loco:SetDesiredSpeed(0)
        if hostile.loco.SetVelocity then hostile.loco:SetVelocity(vector_origin) end
    end
    hostile:SetVelocity(vector_origin)

    playFlinch(hostile)
    return true
end

function HitFeedback:HandleHostileInjured(hostile, dmginfo)
    if not IsValid(hostile) or hostile.LODDead or not bulletDamage(dmginfo) then return false end

    local attacker = dmginfo:GetAttacker()
    if not playerShooter(attacker) then return false end

    local incoming = dmginfo:GetDamage() or 0
    if incoming <= 0 then return false end

    sendHitConfirm(attacker)

    -- OnKilled immediately supersedes this state on a lethal impact, so it is
    -- safe to request the flinch for every real bullet injury here rather than
    -- relying on hook-order-sensitive pre-damage health arithmetic.
    self:ApplyHitStun(hostile)
    return true
end

local function installHostilePatch()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class or class.LODHitFeedbackPatched then return false end
    class.LODHitFeedbackPatched = true

    -- NextBot OnInjured is the authoritative hostile damage callback. Driving
    -- confirmation/stun from here fixes the previous reliance on a global
    -- EntityTakeDamage hook which did not consistently produce runtime feedback.
    local baseOnInjured = class.OnInjured
    function class:OnInjured(dmginfo)
        if baseOnInjured then baseOnInjured(self, dmginfo) end
        HitFeedback:HandleHostileInjured(self, dmginfo)
    end

    -- Make hit stun an explicit AI state. No archetype wrapper can resume
    -- routing, melee, Soldier bursts, Deadcrab leaps, or Bio Blaster charging
    -- until this gate expires.
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
            self.LODNextRouteRefresh = 0
            self.LODNextTargetRefresh = 0
            if self.loco and self.LODConfig then
                self.loco:SetDesiredSpeed(self.LODConfig.speed or 90)
            end
        end

        return baseBehaviourTick(self)
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
            local text = string.format("#%d %s hp=%d stunRemaining=%.3f nextStun=%.3f",
                hostile:EntIndex(), tostring(hostile.LODArchetypeId), hostile:Health(), remaining,
                math.max(0, (hostile.LODNextHitStun or 0) - CurTime()))
            print("[LOD:HIT] " .. text)
            if IsValid(ply) then ply:ChatPrint(text) end
        end
    end
    if count == 0 then
        print("[LOD:HIT] no live hostiles")
        if IsValid(ply) then ply:ChatPrint("no live hostiles") end
    end
end)
