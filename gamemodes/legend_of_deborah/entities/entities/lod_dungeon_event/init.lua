AddCSLuaFile('shared.lua')
AddCSLuaFile('cl_init.lua')
include('shared.lua')
function ENT:Initialize()
    local archetype=self:GetNW2String('LOD_EventArchetype','slot_machine')
    local chest=archetype=='locked_chest' or archetype=='treasure_chest'
    self:SetModel(archetype=='warp_hole' and 'models/props_combine/combine_mine01.mdl'
        or archetype=='vending_machine' and 'models/props_interiors/VendingMachineSoda01a.mdl'
        or chest and 'models/Items/item_item_crate.mdl' or 'models/props_lab/reciever01b.mdl')
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_BBOX)
    if archetype=='warp_hole' then self:SetCollisionBounds(Vector(-20,-20,0),Vector(20,20,16))
    elseif archetype=='vending_machine' then self:SetCollisionBounds(Vector(-24,-20,0),Vector(24,20,80))
    else self:SetCollisionBounds(Vector(-20,-16,0),Vector(20,16,44)) end
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    self:SetUseType(SIMPLE_USE)
    self:SetColor(archetype=='warp_hole' and Color(70,135,155) or Color(205,175,75))
end
function ENT:Use(ply)
    if not LOD.EventDirector then return end
    local ok,reason=LOD.EventDirector:Interact(self,ply)
    if not ok and IsValid(ply) and ply:IsPlayer() and CurTime()>=(self.LODNextNotice or 0) then
        self.LODNextNotice=CurTime()+1
        local archetype=self:GetNW2String('LOD_EventArchetype','slot_machine')
        local chest=archetype=='locked_chest' or archetype=='treasure_chest'
        local vending=archetype=='vending_machine'
        local message=reason=='already' and (vending and 'You already bought your potion in this dungeon.' or chest and 'You already claimed this chest in this dungeon.' or 'You already played this machine in this dungeon.')
            or reason=='storage' and 'Wallet unavailable. Nothing spent; try again.'
            or type(reason)=='string' and reason or 'Machine unavailable.'
        ply:ChatPrint((archetype=='warp_hole' and 'WARP HOLE — ' or vending and 'DEBBIE VENDING — ' or archetype=='treasure_chest' and 'TREASURE CHEST — ' or chest and 'LOCKED CHEST — ' or 'DEBBIE SLOTS — ')..message)
    end
end
