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
end

local function traceFilter(self, owner)
    return function(ent)
        if ent == self or ent == owner then return false end
        if IsValid(ent) and ent.LODHostile then return false end
        return true
    end
end

function ENT:Think()
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
        mins = Vector(-3, -3, -3),
        maxs = Vector(3, 3, 3),
        mask = MASK_SHOT,
        filter = traceFilter(self, owner)
    })

    if tr.Hit then
        if IsValid(tr.Entity) and tr.Entity:IsPlayer() and tr.Entity:Alive() then
            local dmg = DamageInfo()
            dmg:SetDamage(self.LODDamage or 6)
            dmg:SetDamageType(DMG_BULLET)
            dmg:SetAttacker(IsValid(owner) and owner or self)
            dmg:SetInflictor(self)
            dmg:SetDamagePosition(tr.HitPos)
            tr.Entity:TakeDamageInfo(dmg)
        end
        self:Remove()
        return
    end

    self:SetPos(endPos)
    self:NextThink(CurTime())
    return true
end
