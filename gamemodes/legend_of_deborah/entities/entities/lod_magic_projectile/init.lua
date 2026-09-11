AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local MODELS = {
    bomb = "models/Items/AR2_Grenade.mdl",
    missile = "models/weapons/w_missile_closed.mdl",
    bolt = "models/crossbow_bolt.mdl"
}

local function contentColor(contentId)
    local forms = LOD and LOD.MagicForms
    return forms and forms.ContentColors and forms.ContentColors[contentId or "raw"]
        or Color(210, 235, 255)
end

local function traceFilter(self)
    return function(ent)
        if ent == self or ent == self.LODCaster then return false end
        if IsValid(ent) and ent:IsPlayer() then return false end
        if IsValid(ent) and ent.LODSummonedSeeker then return false end
        local owner = IsValid(ent) and ent:GetOwner() or nil
        if owner == self.LODCaster then return false end
        return true
    end
end

function ENT:Initialize()
    local form = tostring(self.LODFormId or "bolt")
    self:SetModel(MODELS[form] or MODELS.bolt)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_NONE)
    self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
    self:DrawShadow(false)
    self.LODDirection = (self.LODDirection or self:GetForward()):GetNormalized()
    self.LODVelocity = self.LODDirection * math.max(1, tonumber(self.LODSpeed) or 900)
    if form == "bomb" then self.LODVelocity = self.LODVelocity + Vector(0, 0, 240) end
    self.LODTravelled = 0
    self.LODLastThink = CurTime()
    self.LODLevelSeed = LOD.RunManager and LOD.RunManager.State and LOD.RunManager.State.LevelSeed or nil
    local color = contentColor(self.LODContentId)
    self:SetRenderMode(RENDERMODE_TRANSCOLOR)
    self:SetColor(Color(color.r, color.g, color.b, 245))
    if util.SpriteTrail then
        self.LODTrail = util.SpriteTrail(self, 0, color, false, 7, 1, 0.22,
            1 / 8, "trails/laser.vmt")
    end
end

local function steer(self, dt)
    if self.LODFormId ~= "missile" or not IsValid(self.LODCaster) then return end
    local desired = self.LODCaster:GetAimVector():GetNormalized()
    if desired == vector_origin then return end
    local current = self.LODDirection:Angle()
    local wanted = desired:Angle()
    local step = math.max(0, tonumber(self.LODSteeringDegreesPerSecond) or 0) * dt
    current.p = math.ApproachAngle(current.p, wanted.p, step)
    current.y = math.ApproachAngle(current.y, wanted.y, step)
    self.LODDirection = current:Forward():GetNormalized()
    self.LODVelocity = self.LODDirection * math.max(1, tonumber(self.LODSpeed) or 900)
end

function ENT:Think()
    local currentSeed = LOD.RunManager and LOD.RunManager.State and LOD.RunManager.State.LevelSeed or nil
    if self.LODLevelSeed and currentSeed ~= self.LODLevelSeed then self:Remove() return end
    if not IsValid(self.LODCaster) then self:Remove() return end

    local now = CurTime()
    local dt = math.Clamp(now - (self.LODLastThink or now), 0, 0.05)
    self.LODLastThink = now
    if dt <= 0 then self:NextThink(CurTime()) return true end
    steer(self, dt)

    local form = tostring(self.LODFormId or "bolt")
    if form == "bomb" then
        self.LODVelocity = self.LODVelocity + Vector(0, 0, -600) * dt
        local horizontal = Vector(self.LODVelocity.x, self.LODVelocity.y, 0)
        if horizontal:LengthSqr() > 1 then self.LODDirection = horizontal:GetNormalized() end
    end

    local startPos = self:GetPos()
    local delta = self.LODVelocity * dt
    local endPos = startPos + delta
    local tr = util.TraceHull({
        start = startPos,
        endpos = endPos,
        mins = Vector(-3, -3, -3),
        maxs = Vector(3, 3, 3),
        mask = MASK_SHOT,
        filter = traceFilter(self)
    })
    self.LODTravelled = (self.LODTravelled or 0) + delta:Length()
    if tr.Hit or self.LODTravelled >= math.max(1, tonumber(self.LODMaximumTravel) or 1) then
        if not tr.Hit then
            tr = {Hit = true, HitPos = endPos, HitNormal = -self.LODDirection, Entity = NULL}
        end
        if LOD.MagicForms and LOD.MagicForms.ProjectileImpact then
            LOD.MagicForms:ProjectileImpact(self, tr)
        else
            self:Remove()
        end
        return
    end

    self:SetPos(endPos)
    if self.LODVelocity:LengthSqr() > 1 then self:SetAngles(self.LODVelocity:Angle()) end
    self:NextThink(CurTime())
    return true
end

function ENT:OnRemove()
    local forms = LOD and LOD.MagicForms
    if forms and IsValid(self.LODCaster) and forms.ActiveMissiles
        and forms.ActiveMissiles[self.LODCaster] == self then
        forms.ActiveMissiles[self.LODCaster] = nil
    end
end
