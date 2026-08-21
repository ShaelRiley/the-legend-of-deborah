AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_NONE)
    self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)

    self.LODDirection = (self.LODDirection or self:GetForward()):GetNormalized()
    self.LODSpeed = self.LODSpeed or 620
    self.LODDamage = self.LODDamage or 45
    self.LODExpireAt = CurTime() + (self.LODLifetime or 1.8)
    self.LODLastThink = CurTime()
    self.LODLevelSeed = LOD.RunManager and LOD.RunManager.State and LOD.RunManager.State.LevelSeed or nil
end

local function isOwnerAttachment(ent, owner)
    if not IsValid(ent) or not IsValid(owner) then return false end
    if ent:GetParent() == owner then return true end
    if ent:GetOwner() == owner then return true end
    return false
end

local function playerVictimFromEntity(ent)
    if not IsValid(ent) then return nil end
    if ent:IsPlayer() then return ent end

    local owner = ent:GetOwner()
    if IsValid(owner) and owner:IsPlayer() then return owner end

    local parent = ent:GetParent()
    if IsValid(parent) and parent:IsPlayer() then return parent end

    return nil
end

local function traceFilter(self, owner)
    return function(ent)
        if ent == self or ent == owner then return false end
        if IsValid(ent) and ent.LODHostile then return false end
        if isOwnerAttachment(ent, owner) then return false end
        return true
    end
end

local function impact(self, pos)
    local effect = EffectData()
    effect:SetOrigin(pos)
    effect:SetScale(1.35)
    util.Effect("AR2Impact", effect, true, true)
    sound.Play("weapons/physcannon/energy_sing_explosion2.wav", pos, 84, 82, 0.92)
end

local function damagePlayer(self, owner, victim, hitPos)
    if not IsValid(victim) or not victim:IsPlayer() or not victim:Alive() then return false end
    if LOD.FactionManager and not LOD.FactionManager:IsValidPlayerTarget(victim) then return false end

    local dmg = DamageInfo()
    dmg:SetDamage(self.LODDamage or 45)
    dmg:SetDamageType(DMG_ENERGYBEAM)
    dmg:SetAttacker(IsValid(owner) and owner or self)
    dmg:SetInflictor(self)
    dmg:SetDamagePosition(hitPos or victim:WorldSpaceCenter())
    victim:TakeDamageInfo(dmg)
    victim:EmitSound("physics/flesh/flesh_impact_bullet5.wav", 72, 72, 0.80)
    return true
end

local FALLBACK_PLAYER_PROXIMITY_SQR = 160 * 160

local function fallbackPlayerNearby(endPos)
    -- A Soldier bolt can travel at most 47.5 units in one clamped Think step;
    -- Bio bolts travel less. A 160-unit end-point radius comfortably encloses
    -- the active player's collision bounds, equipped attachments, and the
    -- entire preceding segment. Outside it, FindAlongRay cannot produce a
    -- valid fallback victim.
    if not player.Iterator or not LOD or not LOD.FactionManager then return true end
    for _, victim in player.Iterator() do
        if LOD.FactionManager:IsValidPlayerTarget(victim)
            and endPos:DistToSqr(victim:WorldSpaceCenter()) <= FALLBACK_PLAYER_PROXIMITY_SQR
        then
            return true
        end
    end
    return false
end

function ENT:Think()
    local currentSeed = LOD.RunManager and LOD.RunManager.State and LOD.RunManager.State.LevelSeed or nil
    if self.LODLevelSeed and currentSeed ~= self.LODLevelSeed then
        self:Remove()
        return
    end
    if CurTime() >= (self.LODExpireAt or 0) then
        self:Remove()
        return
    end

    local owner = self.LODOwner
    local now = CurTime()
    local dt = math.Clamp(now - (self.LODLastThink or now), 0, 0.05)
    self.LODLastThink = now

    local startPos = self:GetPos()
    local endPos = startPos + (self.LODDirection or vector_origin) * (self.LODSpeed or 620) * dt
    local hull = 12 -- 3x the Soldier bolt's 4-unit collision half-width.
    local tr = util.TraceHull({
        start = startPos,
        endpos = endPos,
        mins = Vector(-hull, -hull, -hull),
        maxs = Vector(hull, hull, hull),
        mask = MASK_SHOT,
        filter = traceFilter(self, owner)
    })

    if tr.Hit then
        local victim = playerVictimFromEntity(tr.Entity)
        if victim then damagePlayer(self, owner, victim, tr.HitPos) end
        impact(self, tr.HitPos)
        self:Remove()
        return
    end

    if fallbackPlayerNearby(endPos) then
        for _, ent in ipairs(ents.FindAlongRay(startPos, endPos, Vector(-14, -14, -14), Vector(14, 14, 14))) do
            local victim = playerVictimFromEntity(ent)
            if victim and LOD.FactionManager:IsValidPlayerTarget(victim) then
                local obstruction = util.TraceLine({
                    start = startPos,
                    endpos = victim:WorldSpaceCenter(),
                    mask = MASK_SHOT,
                    filter = function(hit)
                        if hit == self or hit == owner or hit == victim then return false end
                        if IsValid(hit) and hit.LODHostile then return false end
                        if isOwnerAttachment(hit, owner) then return false end
                        if playerVictimFromEntity(hit) == victim then return false end
                        return true
                    end
                })
                if not obstruction.Hit or obstruction.Fraction >= 0.995 then
                    damagePlayer(self, owner, victim, victim:WorldSpaceCenter())
                    impact(self, victim:WorldSpaceCenter())
                    self:Remove()
                    return
                end
            end
        end
    end

    self:SetPos(endPos)
    self:NextThink(CurTime())
    return true
end
