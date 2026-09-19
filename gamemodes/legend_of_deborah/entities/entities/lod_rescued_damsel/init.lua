AddCSLuaFile('shared.lua')
AddCSLuaFile('cl_init.lua')
include('shared.lua')
function ENT:Initialize()
    local D=LOD.Damsels;local def=D.Definitions[self.LODDamselLevel or 1]
    self:SetModel(D:Model(def))
    self:SetNW2Int('LOD_DamselLevel',def.level)
    self:SetNW2Int('LOD_DamselSeed',LOD.RunManager.State.CampaignSeed or 1)
    self:SetMoveType(MOVETYPE_NONE);self:SetSolid(SOLID_BBOX)
    self:SetCollisionBounds(Vector(-14,-14,0),Vector(14,14,72))
    self:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
    self:SetNotSolid(true) -- E uses the server aim check; actors never intercept other staging traces.
    self:SetUseType(SIMPLE_USE);self:SetTrigger(true)
    for _,name in ipairs({def.idle,'LineIdle01','idle_subtle','idle'}) do
        local seq=self:LookupSequence(name)
        if seq and seq>=0 then self:ResetSequence(seq);self:SetCycle(def.level/21);self:SetPlaybackRate(.85+(def.level%4)*.06);break end
    end
end
function ENT:OnTakeDamage() return 0 end
function ENT:Use(ply) LOD.Damsels:Use(ply,self) end
function ENT:StartTouch(ply)
    if self.LODDamselLevel==20 and IsValid(ply) and ply:IsPlayer() then LOD.Damsels:Use(ply,self) end
end
function ENT:Think()
    self:FrameAdvance()
    if self:GetCycle()>=.99 then self:SetCycle(0) end
    self:NextThink(CurTime()+.1);return true
end
