AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_NONE)
    self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
    self:SetRenderBounds(Vector(-16, -16, -16), Vector(16, 16, 16))

    self.LODDirection = (self.LODDirection or self:GetForward()):GetNormalized()
    self.LODSpeed = self.LODSpeed or 950
    self.LODDamage = self.LODDamage or 6
    self.LODExpireAt = CurTime() + (self.LODLifetime or 1.35)
    self.LODLastThink = CurTime()
    self.LODLevelSeed = LOD.RunManager and LOD.RunManager.State and LOD.RunManager.State.LevelSeed or nil
end

local function isOwnerAttachment(ent, owner)
    if not IsValid(ent) or not IsValid(owner) then return false end
    if ent:GetParent() == owner then return true end
    if ent:GetOwner() == owner then return true end
    return false
end

local function traceFilter(self, owner)
    return function(ent)
        if ent == self or ent == owner then return false end
        if IsValid(ent) and ent.LODHostile then return false end
        if isOwnerAttachment(ent, owner) then return false end
        return true
    end
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

local function damagePlayer(self, owner, victim, hitPos)
    if not IsValid(victim) or not victim:IsPlayer() or not victim:Alive() then return false end
    if LOD.FactionManager and not LOD.FactionManager:IsValidPlayerTarget(victim) then return false end

    local dmg = DamageInfo()
    dmg:SetDamage(self.LODDamage or 6)
    dmg:SetDamageType(DMG_BULLET)
    dmg:SetAttacker(IsValid(owner) and owner or self)
    dmg:SetInflictor(self)
    dmg:SetDamagePosition(hitPos or victim:WorldSpaceCenter())
    victim:TakeDamageInfo(dmg)
    victim:EmitSound("physics/flesh/flesh_impact_bullet1.wav", 60, 105, 0.55)
    return true
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
    local endPos = startPos + (self.LODDirection or vector_origin) * (self.LODSpeed or 950) * dt
    local tr = util.TraceHull({
        start = startPos,
        endpos = endPos,
        mins = Vector(-4, -4, -4),
        maxs = Vector(4, 4, 4),
        mask = MASK_SHOT,
        filter = traceFilter(self, owner)
    })

    if tr.Hit then
        -- Equipped weapons and other player-owned child entities can be the
        -- first thing a projectile trace touches. Treat those as a hit on the
        -- owning player rather than deleting the bolt harmlessly.
        local victim = playerVictimFromEntity(tr.Entity)
        if victim then damagePlayer(self, owner, victim, tr.HitPos) end
        self:Remove()
        return
    end

    -- Defensive swept-player check. Some Source player/weapon states do not
    -- consistently become the first MASK_SHOT trace entity. FindAlongRay uses
    -- the whole travelled segment, and a clear obstacle trace prevents damage
    -- through cargo-container walls.
    for _, ent in ipairs(ents.FindAlongRay(startPos, endPos, Vector(-6, -6, -6), Vector(6, 6, 6))) do
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
                self:Remove()
                return
            end
        end
    end

    self:SetPos(endPos)
    self:NextThink(CurTime())
    return true
end
