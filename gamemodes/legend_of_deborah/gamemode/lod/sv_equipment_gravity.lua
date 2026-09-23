-- LOD-MOON-BOOTS-001. Source owns gravity, collision, steering and fall damage.
-- This adapter owns only one equipment multiplier on the native player value.
local E,Run=assert(LOD.Equipment),assert(LOD.RunManager)
E.GravitySources=setmetatable({}, {__mode="k"})
local function same(a,b) return math.abs(a-b)<.000001 end

function E:EndEquipmentGravity(ply,expected)
    local record=self.GravitySources[ply]
    if not record or expected and record~=expected then return false end
    self.GravitySources[ply]=nil
    -- Do not overwrite an intervening external gravity change during cleanup.
    if IsValid(ply) and same(ply:GetGravity(),record.applied) then ply:SetGravity(record.baseline) end
    return true
end

function E:EquipmentGravityEligible(ply)
    return self:CanAct(ply) and Run.State.BuildReady and Run.State.Graph~=nil
        and ply:GetMoveType()==MOVETYPE_WALK and not ply:InVehicle()
end

function E:UpdateEquipmentGravity(ply)
    local record=self.GravitySources[ply]
    if not self:EquipmentGravityEligible(ply) then self:EndEquipmentGravity(ply,record);return end
    if record and not self:MoveAttackValid(ply,record) then
        self:EndEquipmentGravity(ply,record);record=nil
    end
    if not record then
        local binding=self:BindMoveSource(ply,self.SpecialMoves.moon_gravity)
        if not binding then return end
        record={moveBinding=binding,baseline=ply:GetGravity()}
        self.GravitySources[ply]=record
    elseif not same(ply:GetGravity(),record.applied) then
        -- Compose a later native writer's new baseline once, never once per tick.
        record.baseline=ply:GetGravity()
    end
    local baseline=record.baseline
    if baseline==0 then baseline=1 end -- Source's default player-gravity sentinel.
    record.applied=baseline*self.SpecialMoves.moon_gravity.gravityMultiplier
    if not same(ply:GetGravity(),record.applied) then ply:SetGravity(record.applied) end
end

local refresh=E.RefreshDerived
function E:RefreshDerived(ply,...)
    self:UpdateEquipmentGravity(ply)
    return refresh(self,ply,...)
end
-- Inventory changes retire a binding immediately, even remove/re-equip within
-- one server tick. No stale callback may restore gravity over the new binding.
for _,method in ipairs({"Unequip","UnequipItem"}) do
    local base=E[method]
    E[method]=function(self,state,...)
        local result=base(self,state,...)
        for ply,record in pairs(self.GravitySources) do
            local binding=record.moveBinding
            if binding.state==state and self:Equipped(state,binding.slot)~=binding.source then
                self:EndEquipmentGravity(ply,record)
            end
        end
        return result
    end
end
hook.Add("PreCleanupMap","LOD_EquipmentGravityCleanup",function()
    for ply,record in pairs(E.GravitySources) do E:EndEquipmentGravity(ply,record) end
end)
