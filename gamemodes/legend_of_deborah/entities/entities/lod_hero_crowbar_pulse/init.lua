AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local TRACE_HALF_WIDTH = 12

function ENT:Initialize()
    self:SetModel("models/weapons/w_crowbar.mdl")
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_NONE)
    self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
    self:SetModelScale(1.20, 0)

    self.LODDirection = (self.LODDirection or self:GetForward()):GetNormalized()
    self.LODSpeed = math.max(1, tonumber(self.LODSpeed) or 620)
    self.LODMaxDistance = math.max(1, tonumber(self.LODMaxDistance) or 384)
    self.LODArmDistance = math.max(0, tonumber(self.LODArmDistance) or 0)
    self.LODDistanceTravelled = 0
    self.LODLastThink = CurTime()
    self.LODLevelSeed = LOD.RunManager and LOD.RunManager.State
        and LOD.RunManager.State.LevelSeed or nil
end

local function ownerAttachment(ent, owner, weapon)
    if not IsValid(ent) then return false end
    if ent == owner or ent == weapon then return true end
    if IsValid(owner) and (ent:GetParent() == owner or ent:GetOwner() == owner) then
        return true
    end
    return false
end

local function hostileFromEntity(ent)
    if not IsValid(ent) then return nil end
    if ent.LODHostile then return ent end
    local owner = ent:GetOwner()
    if IsValid(owner) and owner.LODHostile then return owner end
    local parent = ent:GetParent()
    if IsValid(parent) and parent.LODHostile then return parent end
    return nil
end

local function eligibleHostile(ent)
    return IsValid(ent) and ent.LODHostile and not ent.LODDead and ent:Health() > 0
end

local function traceFilter(self, armed)
    local owner, weapon = self.LODOwner, self.LODWeapon
    return function(ent)
        if ent == self or ownerAttachment(ent, owner, weapon) then return false end
        local hostile = hostileFromEntity(ent)
        if hostile then return armed and eligibleHostile(hostile) end
        return true
    end
end

local function impactFX(pos, hitHostile)
    local effect = EffectData()
    effect:SetOrigin(pos)
    effect:SetScale(hitHostile and 1.45 or 0.90)
    util.Effect("cball_bounce", effect, true, true)
    sound.Play(hitHostile and "weapons/stunstick/stunstick_fleshhit1.wav"
        or "weapons/stunstick/stunstick_impact1.wav", pos, 75,
        hitHostile and 125 or 145, 0.62)
end

function ENT:BlockAt(pos)
    local stats = LOD.RPG and LOD.RPG.FeatEffectSystem
        and LOD.RPG.FeatEffectSystem.CrowbarStats
    if stats then
        stats.pulseBlocked = (stats.pulseBlocked or 0) + 1
        stats.lastPulseBlocked = true
    end
    self.LODRemovalReason = "blocked"
    impactFX(pos, false)
    self:Remove()
end

function ENT:HitHostile(hostile, pos)
    if not eligibleHostile(hostile) then return false end
    local effects = LOD.RPG and LOD.RPG.FeatEffectSystem
    if not effects or not effects.ResolveHeroOfLegendHit
        or not effects:ResolveHeroOfLegendHit(self, hostile, pos) then return false end
    self.LODRemovalReason = "hit"
    impactFX(pos, true)
    self:Remove()
    return true
end

local function unobstructedTo(self, startPos, hostile)
    local destination = hostile:WorldSpaceCenter()
    local obstruction = util.TraceLine({
        start = startPos,
        endpos = destination,
        mask = MASK_SHOT,
        filter = function(ent)
            if ent == self or ownerAttachment(ent, self.LODOwner, self.LODWeapon) then
                return false
            end
            local candidate = hostileFromEntity(ent)
            if candidate then return candidate ~= hostile end
            return true
        end
    })
    return not obstruction.Hit or obstruction.Fraction >= 0.995
end

function ENT:Think()
    local currentSeed = LOD.RunManager and LOD.RunManager.State
        and LOD.RunManager.State.LevelSeed or nil
    if self.LODLevelSeed and currentSeed ~= self.LODLevelSeed then
        self.LODRemovalReason = "level-change"
        self:Remove()
        return
    end

    local now = CurTime()
    local dt = math.Clamp(now - (self.LODLastThink or now), 0, 0.05)
    self.LODLastThink = now
    local remaining = math.max(0,
        (self.LODMaxDistance or 0) - (self.LODDistanceTravelled or 0))
    if remaining <= 0 then
        self.LODRemovalReason = "range"
        self:Remove()
        return
    end

    local step = math.min(remaining, (self.LODSpeed or 620) * dt)
    local startPos = self:GetPos()
    local endPos = startPos + (self.LODDirection or vector_origin) * step
    -- Do not let the swept hull retroactively damage a body in the portion of
    -- a frame that began inside melee reach. The next frame arms just beyond
    -- that boundary, tolerating at most one 31-unit step of extra separation.
    local armed = (self.LODDistanceTravelled or 0) >= (self.LODArmDistance or 0)
    local tr = util.TraceHull({
        start = startPos,
        endpos = endPos,
        mins = Vector(-TRACE_HALF_WIDTH, -TRACE_HALF_WIDTH, -TRACE_HALF_WIDTH),
        maxs = Vector(TRACE_HALF_WIDTH, TRACE_HALF_WIDTH, TRACE_HALF_WIDTH),
        mask = MASK_SHOT_HULL,
        filter = traceFilter(self, armed)
    })

    if tr.Hit then
        local hostile = armed and hostileFromEntity(tr.Entity) or nil
        if hostile and self:HitHostile(hostile, tr.HitPos) then return end
        self:BlockAt(tr.HitPos)
        return
    end

    -- NextBots and model attachments are not uniformly represented by Source
    -- traces. A segment fallback catches them, but only after an independent
    -- obstruction test, so the projectile can never damage through geometry.
    if armed then
        for _, ent in ipairs(ents.FindAlongRay(startPos, endPos,
            Vector(-TRACE_HALF_WIDTH, -TRACE_HALF_WIDTH, -TRACE_HALF_WIDTH),
            Vector(TRACE_HALF_WIDTH, TRACE_HALF_WIDTH, TRACE_HALF_WIDTH))) do
            local hostile = hostileFromEntity(ent)
            if eligibleHostile(hostile) and unobstructedTo(self, startPos, hostile)
                and self:HitHostile(hostile, hostile:WorldSpaceCenter()) then return end
        end
    end

    self.LODDistanceTravelled = (self.LODDistanceTravelled or 0) + step
    self:SetPos(endPos)
    if self.LODDistanceTravelled >= (self.LODMaxDistance or 0) then
        self.LODRemovalReason = "range"
        self:Remove()
        return
    end
    self:NextThink(CurTime())
    return true
end

function ENT:OnRemove()
    local effects = LOD.RPG and LOD.RPG.FeatEffectSystem
    if not effects then return end
    if effects.ActiveHeroOfLegendPulse == self then
        effects.ActiveHeroOfLegendPulse = nil
    end
    if self.LODRemovalReason == "range" and effects.CrowbarStats then
        effects.CrowbarStats.pulseExpired =
            (effects.CrowbarStats.pulseExpired or 0) + 1
    end
end
