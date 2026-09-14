AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
    local equipment = LOD.Equipment
    local def = equipment.Definitions[self.LODPotionDefinition]
    if not def or not IsValid(self.LODPotionCaster) then self:Remove(); return end
    self:SetModel(def.model)
    self:SetModelScale(0.65, 0)
    self:SetColor(Color(130, 235, 160))
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_NONE)
    self.LODVelocity = self.LODPotionCaster:GetAimVector() * equipment.ThrowSpeed + Vector(0, 0, equipment.ThrowLift)
    self.LODLastThink = CurTime()
    self.LODExpires = CurTime() + equipment.ProjectileLifetime
    util.SpriteTrail(self, 0, Color(130, 235, 160), false, 4, 0, 0.25, 0.1, "trails/laser.vmt")
    self:NextThink(CurTime())
end

function ENT:Think()
    local equipment, run = LOD.Equipment, LOD.RunManager
    local caster = self.LODPotionCaster
    local ps = IsValid(caster) and run:GetPlayerState(caster)
    if CurTime() >= (self.LODCloudUntil or self.LODExpires) or run.State ~= self.LODPotionRun
        or run.State.LevelSeed ~= self.LODPotionLevelSeed or not equipment:CanAct(caster)
        or not ps or ps.equipment ~= self.LODPotionState then self:Remove(); return end
    if self.LODCloudUntil then
        -- One application attempt per target, including a successful CON save.
        for _, target in ipairs(LOD.MagicForms:_AreaTargets(caster,self:GetPos(),96)) do
            if not self.LODCloudTargets[target] then
                self.LODCloudTargets[target]=true
                LOD.RPGStatusElements:Apply(target,"poisoned",caster)
            end
        end
        self:NextThink(CurTime()+0.1)
        return true
    end
    local dt = math.Clamp(CurTime() - self.LODLastThink, 0, 0.1)
    self.LODLastThink = CurTime()
    local start = self:GetPos()
    local finish = start + self.LODVelocity * dt
    local trace = util.TraceHull({start=start, endpos=finish, mins=Vector(-3,-3,-3), maxs=Vector(3,3,3),
        mask=MASK_SHOT, filter={self, caster}})
    self.LODVelocity = self.LODVelocity + Vector(0,0,-GetConVar("sv_gravity"):GetFloat() * dt)
    self:SetPos(trace.HitPos or finish)
    if trace.Hit then
        if not self.LODResolved then
            self.LODResolved = true
            local def = equipment.Definitions[self.LODPotionDefinition]
            if def and def.effect == "heal" and IsValid(trace.Entity) and trace.Entity:IsPlayer() then
                equipment:Heal(caster, trace.Entity, def.amount)
            elseif def and def.effect == "poison_cloud" then
                self.LODCloudUntil=CurTime()+5
                self.LODCloudTargets=setmetatable({}, {__mode="k"})
                self:SetPos(self:GetPos()+(trace.HitNormal or Vector(0,0,1))*4)
                self:SetNW2Float("LOD_CloudUntil",self.LODCloudUntil)
                equipment:Report(caster,"STINK BOMB — poison cloud active", "stink_cloud")
            end
            self:EmitSound("physics/glass/glass_bottle_break1.wav", 62, 110, 0.65)
            local fx = EffectData(); fx:SetOrigin(self:GetPos()); fx:SetScale(0.5)
            util.Effect("GlassImpact", fx, true, true)
        end
        if self.LODCloudUntil then self:NextThink(CurTime()); return true end
        self:Remove(); return
    end
    self:NextThink(CurTime())
    return true
end
