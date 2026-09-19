AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    local target=self.LODRescueTarget or (LOD.Damsels and LOD.Damsels:Current())
    self:SetNW2Bool("LOD_CashTarget",target and target.type=="cash" or false)
    self:SetNW2Int("LOD_DamselLevel",target and target.definition or 20)
    self:SetNW2Int("LOD_DamselSeed",LOD.RunManager.State.CampaignSeed or 1)
    local def=target and target.definition and LOD.Damsels.Definitions[target.definition]
    self:SetModel(target and target.type=="cash" and LOD.Damsels.CashModel
        or def and LOD.Damsels:Model(def) or LOD.Config.Models.Deborah)
    self:SetUseType(SIMPLE_USE)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBounds(Vector(-18, -18, 0), Vector(18, 18, self:GetNW2Bool("LOD_CashTarget",false) and 30 or 72))
    self:SetTrigger(true)
    self:SetCollisionGroup(COLLISION_GROUP_NONE)
    self:DropToFloor()
    self:DrawShadow(true)

    local sequence = self:LookupSequence("LineIdle01")
    if sequence and sequence >= 0 then
        self:ResetSequence(sequence)
        self:SetPlaybackRate(1)
    end
end

function ENT:StartTouch(ent)
    if IsValid(ent) and ent:IsPlayer() then
        LOD.ProgressionDirector:OnRescueTargetTouched(ent,self)
    end
end


-- Run only the explicitly unlocked celebration; no locomotion or hull changes.
function ENT:Think()
    if self:GetNW2Bool("LOD_RescueCheerSequence",false) then
        self:FrameAdvance()
        if self:GetCycle()>=0.99 then self:SetCycle(0) end
        self:NextThink(CurTime()+0.05)
    else self:NextThink(CurTime()+0.25) end
    return true
end

function ENT:Use(ply)
    LOD.ProgressionDirector:OnRescueTargetTouched(ply,self)
end
function ENT:OnTakeDamage() return 0 end
