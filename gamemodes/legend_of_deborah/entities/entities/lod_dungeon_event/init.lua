AddCSLuaFile('shared.lua')
AddCSLuaFile('cl_init.lua')
include('shared.lua')
function ENT:Initialize()
    local archetype=self:GetNW2String('LOD_EventArchetype','slot_machine')
    local definition=LOD.EventRegistry and LOD.EventRegistry.Definitions[archetype]
    local presentation=definition and definition.presentation
    if presentation then self:SetNW2String('LOD_EventName',definition.name or definition.displayName or archetype) end
    local chest=archetype=='locked_chest' or archetype=='treasure_chest'
        or (archetype=='bribe_blockade' and self:GetNW2String('LOD_BribeRole','')=='cache')
    self:SetModel(presentation and presentation.model or archetype=='equipment_quiz' and 'models/monk.mdl'
        or archetype=='warp_hole' and 'models/props_combine/combine_mine01.mdl'
        or archetype=='vending_machine' and 'models/props_interiors/VendingMachineSoda01a.mdl'
        or chest and 'models/Items/item_item_crate.mdl' or 'models/props_lab/reciever01b.mdl')
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_BBOX)
    if presentation then
        -- All expanded incidents are optional and passable. Interaction bounds
        -- remain available to the eye trace without becoming a route obstacle.
        self:SetCollisionBounds(Vector(-18,-18,0),Vector(18,18,presentation.height or 48))
    elseif archetype=='equipment_quiz' then self:SetCollisionBounds(Vector(-18,-18,0),Vector(18,18,74))
    elseif archetype=='warp_hole' then self:SetCollisionBounds(Vector(-20,-20,0),Vector(20,20,16))
    elseif archetype=='vending_machine' then self:SetCollisionBounds(Vector(-24,-20,0),Vector(24,20,80))
    else self:SetCollisionBounds(Vector(-20,-16,0),Vector(20,16,44)) end
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    self:SetUseType(SIMPLE_USE)
    local tint=presentation and presentation.color
    self:SetColor(tint and Color(tint[1] or tint.r or 205,tint[2] or tint.g or 175,tint[3] or tint.b or 75)
        or archetype=='equipment_quiz' and Color(196,60,60) or archetype=='warp_hole' and Color(70,135,155) or Color(205,175,75))
    if presentation and presentation.scale then self:SetModelScale(presentation.scale,0) end
end
function ENT:Use(ply)
    if not LOD.EventDirector then return end
    local ok,reason=LOD.EventDirector:Interact(self,ply)
    if not ok and IsValid(ply) and ply:IsPlayer() and CurTime()>=(self.LODNextNotice or 0) then
        self.LODNextNotice=CurTime()+1
        local archetype=self:GetNW2String('LOD_EventArchetype','slot_machine')
        local definition=LOD.EventRegistry and LOD.EventRegistry.Definitions[archetype]
        local expanded=definition and definition.presentation
        local chest=archetype=='locked_chest' or archetype=='treasure_chest'
        local vending=archetype=='vending_machine'
        local message=reason=='already' and (expanded and 'Your opportunity is spent for this dungeon.' or archetype=='equipment_quiz' and 'Your Game Master attempt is spent for this dungeon.' or vending and 'You already bought your potion in this dungeon.' or chest and 'You already claimed this chest in this dungeon.' or 'You already played this machine in this dungeon.')
            or reason=='storage' and 'Wallet unavailable. Nothing spent; try again.'
            or type(reason)=='string' and reason or 'Machine unavailable.'
        ply:ChatPrint((expanded and string.upper(definition.name or definition.displayName or archetype)..' — ' or archetype=='equipment_quiz' and 'GAME MASTER — ' or archetype=='bribe_blockade' and 'BRIBE BLOCKADE — ' or archetype=='warp_hole' and 'WARP HOLE — ' or vending and 'DEBBIE VENDING — ' or archetype=='treasure_chest' and 'TREASURE CHEST — ' or chest and 'LOCKED CHEST — ' or 'DEBBIE SLOTS — ')..message)
    end
end
