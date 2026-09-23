AddCSLuaFile('shared.lua')
AddCSLuaFile('cl_init.lua')
include('shared.lua')
function ENT:Initialize()
    local chest=self:GetNW2String('LOD_EventArchetype','slot_machine')=='locked_chest'
    self:SetModel(chest and 'models/Items/item_item_crate.mdl' or 'models/props_lab/reciever01b.mdl')
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBounds(Vector(-20,-16,0),Vector(20,16,44))
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    self:SetUseType(SIMPLE_USE)
    self:SetColor(Color(205,175,75))
end
function ENT:Use(ply)
    if not LOD.EventDirector then return end
    local ok,reason=LOD.EventDirector:Interact(self,ply)
    if not ok and IsValid(ply) and ply:IsPlayer() and CurTime()>=(self.LODNextNotice or 0) then
        self.LODNextNotice=CurTime()+1
        local chest=self:GetNW2String('LOD_EventArchetype','slot_machine')=='locked_chest'
        local message=reason=='already' and (chest and 'You already claimed this chest in this dungeon.' or 'You already played this machine in this dungeon.')
            or reason=='storage' and 'Wallet unavailable. Nothing spent; try again.'
            or type(reason)=='string' and reason or 'Machine unavailable.'
        ply:ChatPrint((chest and 'LOCKED CHEST — ' or 'DEBBIE SLOTS — ')..message)
    end
end
