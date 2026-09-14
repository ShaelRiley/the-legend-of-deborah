-- One defender authority; class and feat contributions never roll independently.
local Rules = assert(LOD.RPGAbilityRules)
Rules.DodgeEvents = Rules.DodgeEvents or setmetatable({}, {__mode = "k"})
Rules.DodgeMotion = Rules.DodgeMotion or setmetatable({}, {__mode = "k"})
util.AddNetworkString("LOD_DodgePulse")

function Rules:RogueMovementMultiplier(actor, sprinting)
    local state = self:ProgressionState(actor)
    if not state or state.classId ~= "rogue" then return 1 end
    if sprinting == nil then
        sprinting = actor:IsPlayer() and actor.KeyDown and actor:KeyDown(IN_SPEED)
            or not actor:IsPlayer() and actor.LODOrdinarySprinting == true
    end
    return sprinting and 1.22 or 1.11
end

function Rules:DodgeChance(derived, speed, walkTarget, sprintTarget)
    speed = math.max(0, tonumber(speed) or 0)
    walkTarget, sprintTarget = tonumber(walkTarget) or 0, tonumber(sprintTarget) or 0
    if walkTarget <= 0 or sprintTarget <= 0 or speed < .25 * walkTarget then return 0, "below_minimum" end
    local elevated = speed >= .90 * sprintTarget
    local contribution = math.max(0, tonumber(derived.dodgeChanceContribution) or 0)
    if derived.rogueAllDamageDiceExplode then contribution = contribution + (elevated and .22 or .11) end
    return math.Clamp(contribution, 0, elevated and .66 or .33), elevated and "elevated" or "ordinary"
end

function Rules:DodgeMovement(actor)
    if not IsValid(actor) then return 0, 0, 0 end
    if actor:IsPlayer() then
        local motion = self.DodgeMotion[actor]
        if not motion or motion.identity ~= self:ProgressionState(actor)
            or CurTime() - motion.at > .25 then return 0, 0, 0 end
        return motion.speed, motion.walk, motion.sprint
    end
    -- Generated hostiles use SetPos locomotion, not engine velocity. Only the
    -- graph movement authority's most recent ordinary step is admissible.
    local cfg = actor.LODConfig or {}
    local status = LOD.RPGStatusElements
    local multiplier = status and status:LocomotionMultiplier(actor) or 1
    local walk = (tonumber(cfg.speed) or 90) * multiplier * self:RogueMovementMultiplier(actor, false)
    local sprint = (tonumber(cfg.sprintSpeed) or tonumber(cfg.speed) or 90) * multiplier
        * self:RogueMovementMultiplier(actor, cfg.sprintSpeed ~= nil)
    local speed = CurTime() - (actor.LODMotionLastUpdate or -math.huge) <= .25
        and (actor.LODMotionMode == "ground" or actor.LODMotionMode == "stair")
        and not actor.LODPushbackState and tonumber(actor.LODMotionSpeed) or 0
    return speed or 0, walk, sprint
end

hook.Add("FinishMove", "LOD_RPG_DodgeVoluntaryMotion", function(actor, move)
    if not IsValid(actor) or not actor:Alive() then Rules.DodgeMotion[actor] = nil; return end
    local velocity = move:GetVelocity()
    local base = actor.GetBaseVelocity and actor:GetBaseVelocity() or vector_origin
    local voluntary = velocity - base
    local ordinary = not actor.GetMoveType or actor:GetMoveType() == MOVETYPE_WALK
    local speed = ordinary and voluntary:Length2D() or 0
    local appliedRogue = actor:OnGround() and Rules:RogueMovementMultiplier(actor) or 1
    local multiplier = Rules:MovementMultiplier(actor) / appliedRogue
    local walk = actor:GetWalkSpeed() * multiplier * Rules:RogueMovementMultiplier(actor, false)
    local sprint = actor:GetRunSpeed() * multiplier * Rules:RogueMovementMultiplier(actor, true)
    if actor.LODForcedMovementUntil and CurTime() < actor.LODForcedMovementUntil then speed = 0 end
    Rules.DodgeMotion[actor] = {identity = Rules:ProgressionState(actor), at = CurTime(),
        speed = speed, walk = walk, sprint = sprint}
end)

function Rules:ApplyDodge(target, dmginfo)
    local derived = self:Derived(target)
    if not derived or not dmginfo or dmginfo:GetDamage() <= 0 then return false end
    local status = LOD.RPGStatusElements
    local context = status and status:DamageContext(dmginfo, target) or {}
    local attacker = dmginfo:GetAttacker()
    if not IsValid(attacker) or attacker == target or attacker == game.GetWorld()
        or context.statusDamage or context.wallCrush or context.ignoreDodge or context.ignoreEvasion
        or context.unavoidable or context.scriptedKill or context.environmental
        or dmginfo:IsDamageType(DMG_FALL) or dmginfo:IsDamageType(DMG_CRUSH) then return false end
    if target:IsPlayer() and not target:Alive() or target.LODDead then return false end
    local event = context.attackEvent or dmginfo
    local targets = self.DodgeEvents[event]
    if not targets then targets = setmetatable({}, {__mode = "k"}); self.DodgeEvents[event] = targets end
    local result = targets[target]
    local identity = self:ProgressionState(target)
    local epoch = LOD.RunManager and LOD.RunManager.State and LOD.RunManager.State.Graph
    if not result or result.identity ~= identity or result.epoch ~= epoch then
        local speed, walk, sprint = self:DodgeMovement(target)
        local chance, tier = self:DodgeChance(derived, speed, walk, sprint)
        local rolls = LOD.CombatRolls
        local natural = chance > 0 and rolls:_RNG("dodge:" .. target:EntIndex()):Float(0, 1) or 1
        result = {identity = identity, epoch = epoch, dodged = natural < chance, chance = chance, tier = tier}
        targets[target] = result
        if result.dodged then
            local text = string.format("%s DODGE — 0 HP DAMAGE (%.0f%%; %s)", rolls:EntityDisplayName(target), chance * 100, tier)
            if target:IsPlayer() then
                rolls:_Send(target, 3, text, "resist", {event = "dodge", chance = chance, damage = 0})
                net.Start("LOD_DodgePulse"); net.Send(target)
            end
            if attacker:IsPlayer() and attacker ~= target then
                rolls:_Send(attacker, 3, text, "resist", {event = "dodge", chance = chance, damage = 0})
            end
            target:EmitSound("weapons/iceaxe/iceaxe_swing1.wav", 55, 120, .25)
            self.Stats.dodges = (self.Stats.dodges or 0) + 1
        end
    end
    if not result.dodged then return false end
    dmginfo:SetDamage(0)
    dmginfo:SetDamageForce(vector_origin)
    context.dodged = true
    if status then status:AttachDamageContext(dmginfo, context) end
    return true
end

function Rules:ClearDodge(actor)
    self.DodgeMotion[actor] = nil
    for _, targets in pairs(self.DodgeEvents) do targets[actor] = nil end
end
function Rules:DodgeSnapshot(actor)
    local derived = self:Derived(actor) or {}
    local speed, walk, sprint = self:DodgeMovement(actor)
    local current, tier = self:DodgeChance(derived, speed, walk, sprint)
    -- Projections use the same curve and do not require the actor to be moving
    -- while inspecting the sheet. They never substitute for the actual chance.
    return {current = current, tier = tier,
        ordinary = self:DodgeChance(derived, 50, 100, 100),
        elevated = self:DodgeChance(derived, 100, 100, 100)}
end
